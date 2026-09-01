#!/usr/bin/env python3
"""Скачать кадр Figma: PNG в ~/els-figma/ и структуру узла рядом в .json.

Токен берётся из FIGMA_TOKEN или из ~/.config/figma-token. В репозиторий он
не попадает и в вывод не печатается.

    python3 scripts/figma_frame.py 1182:232 окно-график-объекта
"""
import json
import os
import pathlib
import sys
import time
import urllib.error
import urllib.request

FILE_KEY = "bsgJW2RZLQlZbYUq3peqbD"  # «КПЭК»
OUT = pathlib.Path.home() / "els-figma"


def token() -> str:
    value = os.environ.get("FIGMA_TOKEN")
    if not value:
        path = pathlib.Path.home() / ".config" / "figma-token"
        if not path.exists():
            sys.exit("нет токена: положите его в ~/.config/figma-token")
        value = path.read_text(encoding="utf-8").strip()
    if not value:
        sys.exit("файл ~/.config/figma-token пуст")
    return value


def get(url: str, tries: int = 4) -> dict:
    """Запрос с ожиданием: files-ручки Figma душат лимитом чаще прочих."""
    for attempt in range(tries):
        request = urllib.request.Request(url, headers={"X-Figma-Token": token()})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if error.code != 429 or attempt == tries - 1:
                if error.code == 429:
                    sys.exit(
                        "Figma держит лимит на чтение файла. Подождать и "
                        "повторить — токен при этом рабочий."
                    )
                sys.exit(f"Figma ответила {error.code}: {error.reason}")
            pause = int(error.headers.get("Retry-After") or 0) or 15 * (attempt + 1)
            print(f"лимит Figma, жду {pause} с…", flush=True)
            time.sleep(pause)
    raise AssertionError("недостижимо")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    node = sys.argv[1].replace("-", ":")
    name = sys.argv[2] if len(sys.argv) > 2 else node.replace(":", "-")
    OUT.mkdir(parents=True, exist_ok=True)

    nodes = get(f"https://api.figma.com/v1/files/{FILE_KEY}/nodes?ids={node}")
    payload = nodes.get("nodes", {}).get(node)
    if not payload:
        sys.exit(f"кадр {node} в файле не найден")
    structure = OUT / f"{name}_{node.replace(':', '-')}.json"
    structure.write_text(
        json.dumps(payload["document"], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    images = get(
        f"https://api.figma.com/v1/images/{FILE_KEY}"
        f"?ids={node}&format=png&scale=2"
    )
    link = images.get("images", {}).get(node)
    if not link:
        sys.exit(f"Figma не отдала картинку кадра {node}: {images.get('err')}")
    picture = OUT / f"{name}_{node.replace(':', '-')}.png"
    with urllib.request.urlopen(link, timeout=120) as response:
        picture.write_bytes(response.read())

    print(f"кадр «{payload['document'].get('name', name)}»")
    print(f"  {picture}")
    print(f"  {structure}")


if __name__ == "__main__":
    main()
