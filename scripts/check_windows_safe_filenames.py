#!/usr/bin/env python3
from __future__ import annotations

import os
import sys
from pathlib import Path


WINDOWS_FORBIDDEN_CHARS = set('<>:"/\\|?*')


def iter_paths(root: Path) -> list[Path]:
    paths: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        base = Path(dirpath)
        for name in dirnames + filenames:
            paths.append(base / name)
    return paths


def is_windows_safe_name(name: str) -> tuple[bool, str]:
    if any(ch in name for ch in WINDOWS_FORBIDDEN_CHARS):
        bad = "".join(sorted(set(ch for ch in name if ch in WINDOWS_FORBIDDEN_CHARS)))
        return False, f"contains forbidden char(s): {bad!r}"
    if name.endswith(" ") or name.endswith("."):
        return False, "ends with space or dot"
    return True, ""


def main(argv: list[str]) -> int:
    root = Path(argv[1] if len(argv) > 1 else ".").resolve()
    if not root.exists():
        print(f"ERROR: path does not exist: {root}", file=sys.stderr)
        return 2

    bad: list[tuple[Path, str]] = []
    for path in iter_paths(root):
        ok, reason = is_windows_safe_name(path.name)
        if not ok:
            bad.append((path, reason))

    if not bad:
        print(f"OK: filenames are Windows-safe under {root}")
        return 0

    print("ERROR: found Windows-unsafe filenames:", file=sys.stderr)
    for path, reason in sorted(bad, key=lambda x: str(x[0])):
        print(f"- {path}: {reason}", file=sys.stderr)
    print("\nFix: rename files to remove <>:\"/\\|?* and trailing space/dot.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

