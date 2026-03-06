#!/usr/bin/env python3
"""Bulk migrate mgstudio-engine examples from wasm `game_app` to native `main`."""

from __future__ import annotations

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
EXAMPLES_DIR = REPO_ROOT / "mgstudio-engine" / "examples"


def rewrite_main_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    updated = text
    updated = updated.replace("pub fn game_app(", "fn main(")
    updated = updated.replace("fn game_app(", "fn main(")
    updated = re.sub(r"\bpub\s+fn main\b", "fn main", updated)
    updated = re.sub(r"\bfn main\(\)\s*->\s*Unit\s*\{", "fn main {", updated)
    updated = re.sub(r"\bfn main\(\)\s*\{", "fn main {", updated)
    if updated != text:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


def rewrite_pkg_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    updated = text

    updated = re.sub(
        r"\noptions\(\n\s*link:\s*\{\s*\"wasm\"\s*:\s*\{\s*\"exports\"\s*:\s*\[\s*\"game_app\"\s*\]\s*\}\s*\},\n\)\n",
        "\n",
        updated,
        flags=re.MULTILINE,
    )

    if '"is-main"' not in updated:
        stripped = updated.rstrip() + "\n\n"
        updated = stripped + "options(\n  \"is-main\": true,\n)\n"

    if updated != text:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


def rewrite_mbti_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    updated = text.replace("pub fn game_app() -> Unit", "pub fn main() -> Unit")
    if updated != text:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


def main() -> None:
    changed = 0
    for main_file in EXAMPLES_DIR.rglob("main.mbt"):
        if rewrite_main_file(main_file):
            changed += 1

    for pkg_file in EXAMPLES_DIR.rglob("moon.pkg"):
        if rewrite_pkg_file(pkg_file):
            changed += 1

    for mbti_file in EXAMPLES_DIR.rglob("pkg.generated.mbti"):
        if rewrite_mbti_file(mbti_file):
            changed += 1

    print(f"migrate_examples_to_native_main: changed {changed} files")


if __name__ == "__main__":
    main()
