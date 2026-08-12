#!/usr/bin/env python3
"""Генератор иконок ELS: favicon (PNG + SVG), PWA, Android, iOS.

Знак строится геометрией (моно-линейные буквы + два треугольника), а не
масштабируется из растра, поэтому остаётся чётким на любом размере и DPI.
Геометрия считается один раз в `layout()` и рисуется двумя способами —
Pillow (PNG) и SVG, — так что растр и вектор гарантированно совпадают.

Запуск:  python3 scripts/gen_brand_icons.py    (нужен Pillow)
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

BLACK = "#17181C"
GREEN = "#0FB14C"
RED = "#F2261E"
WHITE = "#FFFFFF"

SS = 8  # супер-сэмплинг для растра
ROOT = Path(__file__).resolve().parent.parent
FRONT = ROOT / "frontend"


# --- геометрия -------------------------------------------------------------


def layout(s: float, scale: float = 1.0, mode: str = "full") -> dict:
    """Координаты знака внутри квадрата стороной s.

    mode="full"     — треугольники + слово (иконки приложения, 64 px и больше);
    mode="wordmark" — только слово покрупнее (favicon: в 16–32 px стрелки
                      превращаются в кашу, а слово ещё читается).
    """
    if mode == "wordmark":
        content = s * 0.90 * scale
        h = content / 2.52
        lw, gap = h * 0.72, h * 0.18
        x0 = (s - content) / 2
        return {
            "h": h, "lw": lw, "t": h * 0.185, "up": None, "down": None,
            "letters": [x0 + i * (lw + gap) for i in range(3)], "ly": (s - h) / 2,
        }

    content = s * 0.86 * scale
    h = content / 2.52  # высота букв
    lw = h * 0.72  # ширина буквы
    gap = h * 0.18  # межбуквенный просвет
    t = h * 0.175  # толщина линии

    tw = content * 0.32  # ширина треугольника
    th = tw * 0.58
    vgap = h * 0.19  # просвет между треугольником и буквами
    total = 2 * (th + vgap) + h

    cx = s / 2
    top = (s - total) / 2
    x0 = cx - content / 2
    ly = top + th + vgap
    by = top + total

    return {
        "h": h, "lw": lw, "t": t, "tw": tw, "th": th, "r": tw * 0.13,
        "up": [(cx, top), (cx - tw / 2, top + th), (cx + tw / 2, top + th)],
        "down": [(cx, by), (cx + tw / 2, by - th), (cx - tw / 2, by - th)],
        "letters": [x0 + i * (lw + gap) for i in range(3)],
        "ly": ly,
    }


def inset_triangle(pts, r: float):
    """Гомотетия относительно инцентра: отступ на r внутрь под скругление."""
    (ax, ay), (bx, by), (cx, cy) = pts
    la, lb, lc = (
        math.dist((bx, by), (cx, cy)),
        math.dist((ax, ay), (cx, cy)),
        math.dist((ax, ay), (bx, by)),
    )
    per = la + lb + lc
    ix = (la * ax + lb * bx + lc * cx) / per
    iy = (la * ay + lb * by + lc * cy) / per
    inr = 2 * (abs((bx - ax) * (cy - ay) - (cx - ax) * (by - ay)) / 2) / per
    k = max(0.0, (inr - r) / inr)
    return [(ix + (x - ix) * k, iy + (y - iy) * k) for x, y in pts]


def s_arcs(x: float, y: float, h: float, lw: float, t: float):
    """Две дуги буквы S: (bbox, угол_от, угол_до) в градусах, 0° — 3 часа."""
    top = (x + t / 2, y + t / 2, x + lw - t / 2, y + h / 2)
    bot = (x + t / 2, y + h / 2, x + lw - t / 2, y + h - t / 2)
    return [(top, 375, 90), (bot, 270, 555)]


def e_paths(x, y, h, lw, t):
    return [
        [(x + t / 2, y + t / 2), (x + t / 2, y + h - t / 2)],
        [(x + t / 2, y + t / 2), (x + lw - t / 2, y + t / 2)],
        [(x + t / 2, y + h / 2), (x + lw * 0.80, y + h / 2)],
        [(x + t / 2, y + h - t / 2), (x + lw - t / 2, y + h - t / 2)],
    ]


def l_paths(x, y, h, lw, t):
    return [
        [
            (x + t / 2, y + t / 2),
            (x + t / 2, y + h - t / 2),
            (x + lw - t / 2, y + h - t / 2),
        ]
    ]


def arc_point(bbox, deg: float):
    x0, y0, x1, y1 = bbox
    a = math.radians(deg)
    return (
        (x0 + x1) / 2 + (x1 - x0) / 2 * math.cos(a),
        (y0 + y1) / 2 + (y1 - y0) / 2 * math.sin(a),
    )


# --- растр -----------------------------------------------------------------


def _stroke(d, pts, w, color):
    r = w / 2
    for p, q in zip(pts, pts[1:]):
        d.line((*p, *q), fill=color, width=max(1, int(round(w))))
    for x, y in pts:
        d.ellipse((x - r, y - r, x + r, y + r), fill=color)


def draw_mark(
    size: int, scale: float = 1.0, radius: float = 0.0, mode: str = "full", bg=WHITE
) -> Image.Image:
    """Квадратная иконка. scale<1 — знак меньше (safe zone), radius — доля от стороны."""
    ss = max(2, min(SS, 2048 // max(size, 1)))
    s = size * ss
    img = Image.new("RGBA", (s, s), bg or (255, 255, 255, 0))
    d = ImageDraw.Draw(img)

    g = layout(s, scale, mode)
    if g["up"]:
        for pts, color in ((g["up"], GREEN), (g["down"], RED)):
            inset = inset_triangle(pts, g["r"])
            d.polygon(inset, fill=color)
            _stroke(d, inset + [inset[0]], 2 * g["r"], color)

    xe, xl, xs = g["letters"]
    for path in e_paths(xe, g["ly"], g["h"], g["lw"], g["t"]):
        _stroke(d, path, g["t"], BLACK)
    for path in l_paths(xl, g["ly"], g["h"], g["lw"], g["t"]):
        _stroke(d, path, g["t"], GREEN)
    for bbox, a0, a1 in s_arcs(xs, g["ly"], g["h"], g["lw"], g["t"]):
        steps = 72
        _stroke(d, [arc_point(bbox, a0 + (a1 - a0) * i / steps) for i in range(steps + 1)],
                g["t"], BLACK)

    out = img.resize((size, size), Image.LANCZOS)
    if radius:
        # Скругление отдельной маской: если рисовать его до ресайза, прозрачный
        # чёрный подмешивается в белый фон и по углам появляется грязь.
        mask = Image.new("L", (s, s), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, s - 1, s - 1), radius=s * radius, fill=255)
        out.putalpha(mask.resize((size, size), Image.LANCZOS))
    return out


# --- вектор ----------------------------------------------------------------


def svg_mark(size: int = 512, radius: float = 0.0, mode: str = "full") -> str:
    g = layout(size, mode=mode)
    n = lambda v: f"{v:.2f}"  # noqa: E731
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}">',
        f'<rect width="{size}" height="{size}" rx="{n(size * radius)}" fill="{WHITE}"/>',
    ]

    for pts, color in (((g["up"], GREEN), (g["down"], RED)) if g["up"] else ()):
        p = " ".join(f"{n(x)},{n(y)}" for x, y in inset_triangle(pts, g["r"]))
        out.append(
            f'<polygon points="{p}" fill="{color}" stroke="{color}" '
            f'stroke-width="{n(2 * g["r"])}" stroke-linejoin="round"/>'
        )

    stroke = (
        f'fill="none" stroke-width="{n(g["t"])}" '
        'stroke-linecap="round" stroke-linejoin="round"'
    )
    xe, xl, xs = g["letters"]
    for paths, color in (
        (e_paths(xe, g["ly"], g["h"], g["lw"], g["t"]), BLACK),
        (l_paths(xl, g["ly"], g["h"], g["lw"], g["t"]), GREEN),
    ):
        for path in paths:
            dd = " ".join(
                ("M" if i == 0 else "L") + f"{n(x)} {n(y)}" for i, (x, y) in enumerate(path)
            )
            out.append(f'<path d="{dd}" stroke="{color}" {stroke}/>')

    seg = []
    for bbox, a0, a1 in s_arcs(xs, g["ly"], g["h"], g["lw"], g["t"]):
        rx, ry = (bbox[2] - bbox[0]) / 2, (bbox[3] - bbox[1]) / 2
        sx, sy = arc_point(bbox, a0)
        ex, ey = arc_point(bbox, a1)
        sweep = 1 if a1 > a0 else 0
        large = 1 if abs(a1 - a0) > 180 else 0
        if not seg:
            seg.append(f"M{n(sx)} {n(sy)}")
        seg.append(f"A{n(rx)} {n(ry)} 0 {large} {sweep} {n(ex)} {n(ey)}")
    out.append(f'<path d="{" ".join(seg)}" stroke="{BLACK}" {stroke}/>')

    out.append("</svg>")
    return "\n".join(out) + "\n"


# --- вывод -----------------------------------------------------------------


def save(img: Image.Image, path: Path, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    (img.convert("RGB") if opaque else img).save(path, "PNG", optimize=True)
    print(f"  {path.relative_to(ROOT)}  {img.width}x{img.height}")


def main() -> None:
    print("web:")
    (FRONT / "web/favicon.svg").write_text(svg_mark(512, radius=0.18, mode="wordmark"))
    print("  frontend/web/favicon.svg")
    for n in (16, 32, 48):
        name = "favicon.png" if n == 32 else f"favicon-{n}.png"
        save(draw_mark(n, radius=0.18, mode="wordmark"), FRONT / "web" / name)
    save(draw_mark(180), FRONT / "web/icons/Icon-180.png")  # apple-touch-icon
    for n in (192, 512):
        save(draw_mark(n), FRONT / f"web/icons/Icon-{n}.png")
        save(draw_mark(n, scale=0.66), FRONT / f"web/icons/Icon-maskable-{n}.png")

    print("android:")
    res = FRONT / "android/app/src/main/res"
    # 48 dp — легаси-иконка (до Android 8), 108 dp — foreground адаптивной иконки:
    # система сама обрежет её под круг/сквиркл, знак держим в safe zone 72/108.
    for dens, k in (("mdpi", 1), ("hdpi", 1.5), ("xhdpi", 2), ("xxhdpi", 3), ("xxxhdpi", 4)):
        save(draw_mark(int(48 * k)), res / f"mipmap-{dens}/ic_launcher.png")
        save(
            draw_mark(int(108 * k), scale=0.60, bg=None),
            res / f"mipmap-{dens}/ic_launcher_foreground.png",
        )
    (res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n"
    )
    (res / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">{WHITE}</color>\n'
        "</resources>\n"
    )
    print("  mipmap-anydpi-v26/ic_launcher.xml + values/ic_launcher_background.xml")

    print("ios:")  # без альфа-канала — требование App Store
    ios = FRONT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for base, scales in (
        ("20x20", (1, 2, 3)),
        ("29x29", (1, 2, 3)),
        ("40x40", (1, 2, 3)),
        ("60x60", (2, 3)),
        ("76x76", (1, 2)),
        ("83.5x83.5", (2,)),
        ("1024x1024", (1,)),
    ):
        pt = float(base.split("x")[0])
        for sc in scales:
            save(draw_mark(int(round(pt * sc))), ios / f"Icon-App-{base}@{sc}x.png", opaque=True)


if __name__ == "__main__":
    main()
