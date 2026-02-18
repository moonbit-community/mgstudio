#!/usr/bin/env python3
# Copyright 2025 International Digital Economy Academy
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import annotations

import argparse
import csv
import datetime as dt
import pathlib
import subprocess
import sys
from dataclasses import dataclass
from typing import Iterable

N_A_CATEGORIES = {"mobile", "no_std"}

ADAPTED_HINTS = (
    "Baseline parity",
    "not available",
    "replacing Bevy",
    "parity scope",
)

OWNER_GROUPS = {
    "core": {
        "app",
        "async_tasks",
        "ecs",
        "math",
        "movement",
        "state",
        "time",
        "transforms",
        "usage",
    },
    "asset_scene": {
        "animation",
        "asset",
        "gltf",
        "scene",
    },
    "render": {
        "2d",
        "3d",
        "camera",
        "games",
        "gizmos",
        "large_scenes",
        "picking",
        "shader",
        "shader_advanced",
        "stress_tests",
        "testbed",
    },
    "ui_text": {
        "ui",
        "a11y",
    },
    "input_window": {
        "input",
        "window",
    },
    "platform_na": {
        "mobile",
        "no_std",
    },
    "ops": {
        "audio",
        "dev_tools",
        "diagnostics",
        "helpers",
        "reflection",
        "remote",
        "tools",
    },
}


@dataclass(frozen=True)
class ExampleRow:
    bevy_path: str
    category: str
    example: str
    mgstudio_path: str
    status: str
    owner: str
    notes: str


def run_git(root: pathlib.Path, *args: str) -> str:
    try:
        completed = subprocess.run(
            ["git", *args],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=True,
        )
        return completed.stdout.strip()
    except subprocess.CalledProcessError:
        return ""


def discover_bevy_examples(root: pathlib.Path) -> list[pathlib.Path]:
    base = root / "bevy" / "examples"
    return sorted(base.glob("**/*.rs"))


def discover_mgstudio_examples(root: pathlib.Path) -> dict[tuple[str, str], str]:
    base = root / "mgstudio-engine" / "examples"
    mapping: dict[tuple[str, str], str] = {}
    if not base.exists():
        return mapping
    for category_dir in sorted(base.iterdir()):
        if not category_dir.is_dir():
            continue
        category = category_dir.name
        for example_dir in sorted(category_dir.iterdir()):
            if not example_dir.is_dir():
                continue
            if not (example_dir / "moon.pkg").exists():
                continue
            mapping[(category, example_dir.name)] = str(
                example_dir.relative_to(root).as_posix()
            )
    return mapping


def detect_adapted_status(root: pathlib.Path, mgstudio_rel: str) -> bool:
    main_path = root / mgstudio_rel / "main.mbt"
    if not main_path.exists():
        return False
    content = main_path.read_text(encoding="utf-8", errors="ignore")
    return any(hint in content for hint in ADAPTED_HINTS)


def owner_for_category(category: str) -> str:
    for owner, categories in OWNER_GROUPS.items():
        if category in categories:
            return f"team-{owner}"
    return "team-parity"


def classify_rows(root: pathlib.Path) -> list[ExampleRow]:
    bevy_examples = discover_bevy_examples(root)
    mgstudio_examples = discover_mgstudio_examples(root)
    rows: list[ExampleRow] = []

    base = root / "bevy" / "examples"

    for path in bevy_examples:
        bevy_rel = path.relative_to(base).as_posix()
        category = bevy_rel.split("/", 1)[0]
        example = path.stem
        key = (category, example)
        mgstudio_path = mgstudio_examples.get(key, "")
        owner = owner_for_category(category)
        notes = ""

        if category in N_A_CATEGORIES:
            status = "N/A"
            notes = "WASM-first policy: platform-incompatible category."
        elif mgstudio_path:
            if detect_adapted_status(root, mgstudio_path):
                status = "Blocked"
                notes = "Fallback implementation exists; blocked until exact parity."
            else:
                status = "Exact"
        else:
            status = "Blocked"

        rows.append(
            ExampleRow(
                bevy_path=f"bevy/examples/{bevy_rel}",
                category=category,
                example=example,
                mgstudio_path=mgstudio_path,
                status=status,
                owner=owner,
                notes=notes,
            )
        )
    return rows


def summarize(rows: Iterable[ExampleRow]) -> dict[str, dict[str, int]]:
    summary: dict[str, dict[str, int]] = {}
    for row in rows:
        category = row.category
        if category not in summary:
            summary[category] = {
                "total": 0,
                "Exact": 0,
                "Blocked": 0,
                "N/A": 0,
            }
        summary[category]["total"] += 1
        summary[category][row.status] += 1
    return dict(sorted(summary.items(), key=lambda item: item[0]))


def render_markdown(
    rows: list[ExampleRow], summary_table: dict[str, dict[str, int]], root: pathlib.Path
) -> str:
    now = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d")
    baseline_commit = run_git(root / "bevy", "rev-parse", "HEAD")
    baseline_describe = run_git(root / "bevy", "describe", "--tags", "--always")

    lines: list[str] = []
    lines.append("# Bevy Example Parity Matrix")
    lines.append("")
    lines.append("Status: Active (SoT)")
    lines.append(f"Last Verified: {now}")
    lines.append("Scope: As-Implemented")
    lines.append("Code References:")
    lines.append("- `bevy/examples/`")
    lines.append("- `mgstudio-engine/examples/`")
    lines.append("- `scripts/generate_bevy_example_parity.py`")
    lines.append("Superseded By: N/A")
    lines.append("Notes:")
    lines.append("- Status vocabulary: `Exact`, `Blocked`, `N/A`.")
    if baseline_commit:
        lines.append(f"- Baseline commit: `{baseline_commit}`.")
    if baseline_describe:
        lines.append(f"- Baseline describe: `{baseline_describe}`.")
    lines.append("")
    lines.append("## Summary by Category")
    lines.append("")
    lines.append("| Category | Total | Exact | Blocked | N/A |")
    lines.append("| --- | ---: | ---: | ---: | ---: |")

    totals = {"total": 0, "Exact": 0, "Blocked": 0, "N/A": 0}
    for category, row in summary_table.items():
        lines.append(
            f"| `{category}` | {row['total']} | {row['Exact']} | {row['Blocked']} | {row['N/A']} |"
        )
        for key in totals:
            totals[key] += row[key]

    lines.append(
        f"| **Total** | **{totals['total']}** | **{totals['Exact']}** | **{totals['Blocked']}** | **{totals['N/A']}** |"
    )

    lines.append("")
    lines.append("## Example Inventory")
    lines.append("")
    lines.append(
        "| Bevy Example | Category | mgstudio Example | Status | Owner | Notes |"
    )
    lines.append("| --- | --- | --- | --- | --- | --- |")

    for row in rows:
        mgstudio_path = f"`{row.mgstudio_path}`" if row.mgstudio_path else ""
        notes = row.notes.replace("|", "\\|")
        lines.append(
            f"| `{row.bevy_path}` | `{row.category}` | {mgstudio_path} | `{row.status}` | `{row.owner}` | {notes} |"
        )

    lines.append("")
    return "\n".join(lines)


def render_csv(rows: list[ExampleRow]) -> str:
    output: list[str] = []
    header = [
        "bevy_path",
        "category",
        "example",
        "mgstudio_path",
        "status",
        "owner",
        "notes",
    ]
    output.append(",".join(header))

    for row in rows:
        fields = [
            row.bevy_path,
            row.category,
            row.example,
            row.mgstudio_path,
            row.status,
            row.owner,
            row.notes,
        ]
        escaped = []
        for field in fields:
            if any(ch in field for ch in [",", '"', "\n"]):
                escaped.append('"' + field.replace('"', '""') + '"')
            else:
                escaped.append(field)
        output.append(",".join(escaped))

    return "\n".join(output) + "\n"


def write_file(path: pathlib.Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def parse_csv(path: pathlib.Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def check_csv_integrity(path: pathlib.Path) -> None:
    rows = parse_csv(path)
    for index, row in enumerate(rows, start=2):
        owner = (row.get("owner") or "").strip()
        if not owner:
            raise RuntimeError(f"missing owner at {path}:{index}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Bevy example parity artifacts.")
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[1],
        help="Repository root.",
    )
    parser.add_argument(
        "--output-md",
        type=pathlib.Path,
        default=pathlib.Path("docs/parity/bevy_example_parity_matrix.md"),
        help="Output markdown path (relative to root if not absolute).",
    )
    parser.add_argument(
        "--output-csv",
        type=pathlib.Path,
        default=pathlib.Path("docs/parity/bevy_example_parity.csv"),
        help="Output CSV path (relative to root if not absolute).",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check mode: validate existing artifacts match generated output.",
    )
    return parser.parse_args()


def resolve_path(root: pathlib.Path, path: pathlib.Path) -> pathlib.Path:
    if path.is_absolute():
        return path
    return root / path


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    output_md = resolve_path(root, args.output_md)
    output_csv = resolve_path(root, args.output_csv)

    rows = classify_rows(root)
    summary_table = summarize(rows)
    md_content = render_markdown(rows, summary_table, root)
    csv_content = render_csv(rows)

    if args.check:
        if not output_md.exists() or not output_csv.exists():
            print("parity artifacts are missing; run generator first", file=sys.stderr)
            return 1

        current_md = output_md.read_text(encoding="utf-8")
        current_csv = output_csv.read_text(encoding="utf-8")

        if current_md != md_content:
            print(f"drift detected: {output_md}", file=sys.stderr)
            return 1
        if current_csv != csv_content:
            print(f"drift detected: {output_csv}", file=sys.stderr)
            return 1

        check_csv_integrity(output_csv)
        print("bevy example parity artifacts are up-to-date")
        return 0

    write_file(output_md, md_content)
    write_file(output_csv, csv_content)
    check_csv_integrity(output_csv)

    print(f"wrote {output_md}")
    print(f"wrote {output_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
