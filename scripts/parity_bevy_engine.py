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
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path

EXCLUDED_DIR_NAMES = {
    ".git",
    ".mooncakes",
    ".private",
    "_build",
    "target",
}


@dataclass
class BevyCrate:
    name: str
    base_name: str
    root: Path
    modules: set[str]
    leaf_modules: set[str]


@dataclass
class EnginePackage:
    rel_path: str
    display_name: str
    normalized_name: str
    root: Path
    modules: set[str]
    leaf_modules: set[str]


def is_example_package(rel_path: str) -> bool:
    return rel_path == "examples" or rel_path.startswith("examples/")


@dataclass
class CrateCoverage:
    crate: BevyCrate
    packages: list[EnginePackage]
    bevy_module_count: int
    engine_module_count: int
    strict_overlap_count: int
    leaf_overlap_count: int
    strict_coverage: float
    missing_modules: list[str]
    extra_modules: list[str]


def normalize_identifier(value: str) -> str:
    lowered = value.strip().lower()
    lowered = re.sub(r"[^a-z0-9]+", "_", lowered)
    lowered = re.sub(r"_+", "_", lowered)
    return lowered.strip("_")


def module_leaf(module_key: str) -> str:
    if "/" in module_key:
        return module_key.rsplit("/", 1)[1]
    return module_key


def rust_module_key(relative_path: Path) -> str:
    parts = list(relative_path.parts)
    filename = parts[-1]
    stem = filename[:-3]
    if stem in {"lib", "main", "mod"}:
        parts = parts[:-1]
    else:
        parts = parts[:-1] + [stem]
    if not parts:
        return "__root__"
    return "/".join(parts)


def moon_module_key(relative_path: Path) -> str:
    return relative_path.as_posix()[:-4]


def should_skip_dirname(name: str) -> bool:
    if name in EXCLUDED_DIR_NAMES:
        return True
    if name.startswith(".") and name not in {".", ".."}:
        return True
    return False


def discover_bevy_crates(bevy_crates_root: Path) -> list[BevyCrate]:
    crates: list[BevyCrate] = []
    for crate_dir in sorted(bevy_crates_root.iterdir()):
        if not crate_dir.is_dir():
            continue
        src_dir = crate_dir / "src"
        if not src_dir.exists():
            continue
        modules: set[str] = set()
        for root, dirnames, filenames in os.walk(src_dir):
            dirnames[:] = [d for d in dirnames if not should_skip_dirname(d)]
            for filename in filenames:
                if not filename.endswith(".rs"):
                    continue
                full_path = Path(root) / filename
                rel = full_path.relative_to(src_dir)
                modules.add(rust_module_key(rel))
        if not modules:
            continue
        crate_name = crate_dir.name
        if crate_name.startswith("bevy_"):
            base_name = normalize_identifier(crate_name[len("bevy_") :])
        else:
            base_name = normalize_identifier(crate_name)
        crates.append(
            BevyCrate(
                name=crate_name,
                base_name=base_name,
                root=crate_dir,
                modules=modules,
                leaf_modules={module_leaf(module) for module in modules},
            )
        )
    return crates


def discover_engine_package_roots(engine_root: Path) -> list[Path]:
    roots: set[Path] = set()
    for root, dirnames, filenames in os.walk(engine_root):
        dirnames[:] = [d for d in dirnames if not should_skip_dirname(d)]
        if "moon.pkg" in filenames or "moon.pkg.json" in filenames:
            roots.add(Path(root))
    return sorted(roots, key=lambda p: (len(p.parts), p.as_posix()))


def collect_package_modules(package_root: Path, package_root_set: set[Path]) -> set[str]:
    modules: set[str] = set()
    for root, dirnames, filenames in os.walk(package_root):
        current = Path(root)
        filtered_dirs: list[str] = []
        for dirname in dirnames:
            if should_skip_dirname(dirname):
                continue
            child = current / dirname
            if child in package_root_set and child != package_root:
                continue
            filtered_dirs.append(dirname)
        dirnames[:] = filtered_dirs
        for filename in filenames:
            if not filename.endswith(".mbt"):
                continue
            full_path = current / filename
            rel = full_path.relative_to(package_root)
            modules.add(moon_module_key(rel))
    return modules


def discover_engine_packages(engine_root: Path, include_examples: bool) -> list[EnginePackage]:
    package_roots = discover_engine_package_roots(engine_root)
    package_root_set = set(package_roots)
    packages: list[EnginePackage] = []
    for package_root in package_roots:
        rel_path = package_root.relative_to(engine_root).as_posix()
        if not include_examples and is_example_package(rel_path):
            continue
        modules = collect_package_modules(package_root, package_root_set)
        if not modules:
            continue
        display_name = rel_path if rel_path != "." else "<root>"
        normalized_name = normalize_identifier(package_root.name)
        packages.append(
            EnginePackage(
                rel_path=rel_path,
                display_name=display_name,
                normalized_name=normalized_name,
                root=package_root,
                modules=modules,
                leaf_modules={module_leaf(module) for module in modules},
            )
        )
    return packages


def is_name_related(crate: BevyCrate, package: EnginePackage) -> bool:
    crate_name = crate.base_name
    package_name = package.normalized_name
    if not crate_name or not package_name:
        return False
    if crate_name == package_name:
        return True
    if package_name.startswith(crate_name) or crate_name.startswith(package_name):
        return True
    if len(crate_name) >= 4 and crate_name in package_name:
        return True
    if len(package_name) >= 4 and package_name in crate_name:
        return True
    return False


def package_score(crate: BevyCrate, package: EnginePackage) -> tuple[float, int]:
    score = 0.0
    if crate.base_name == package.normalized_name:
        score += 100.0
    elif is_name_related(crate, package):
        score += 60.0
    leaf_overlap = len(crate.leaf_modules & package.leaf_modules)
    if leaf_overlap > 0:
        score += float(leaf_overlap) * 2.0
        union_size = len(crate.leaf_modules | package.leaf_modules)
        if union_size > 0:
            score += (leaf_overlap / union_size) * 30.0
    return score, leaf_overlap


def package_priority(package: EnginePackage) -> int:
    """Lower value means better default candidate for crate mapping."""
    rel = package.rel_path
    if rel == ".":
        return 0
    if rel.startswith("examples/"):
        return 4
    if rel.startswith("runtime_native/"):
        return 3
    depth = rel.count("/")
    if depth == 0:
        return 0
    if depth == 1:
        return 1
    return 2


def select_packages_for_crate(
    crate: BevyCrate,
    packages: list[EnginePackage],
) -> list[EnginePackage]:
    exact = [package for package in packages if crate.base_name == package.normalized_name]
    if exact:
        return sorted(exact, key=lambda package: package.display_name)

    name_related = [package for package in packages if is_name_related(crate, package)]
    if name_related:
        best_priority = min(package_priority(package) for package in name_related)
        filtered = [package for package in name_related if package_priority(package) == best_priority]
        return sorted(filtered, key=lambda package: package.display_name)

    scored: list[tuple[int, float, int, EnginePackage]] = []
    for package in packages:
        score, leaf_overlap = package_score(crate, package)
        scored.append((package_priority(package), score, leaf_overlap, package))
    scored.sort(key=lambda item: (item[0], -item[1], -item[2], item[3].display_name))
    if not scored:
        return []
    _best_priority, best_score, best_leaf_overlap, best_package = scored[0]
    if best_leaf_overlap <= 0:
        return []
    if best_score < 10.0:
        return []
    return [best_package]


def compute_coverage(
    crates: list[BevyCrate],
    packages: list[EnginePackage],
    only_crates: set[str],
) -> list[CrateCoverage]:
    rows: list[CrateCoverage] = []
    for crate in crates:
        if only_crates and crate.name not in only_crates:
            continue
        mapped_packages = select_packages_for_crate(crate, packages)
        mapped_modules: set[str] = set()
        mapped_leaf_modules: set[str] = set()
        for package in mapped_packages:
            mapped_modules.update(package.modules)
            mapped_leaf_modules.update(package.leaf_modules)
        strict_overlap = crate.modules & mapped_modules
        leaf_overlap = crate.leaf_modules & mapped_leaf_modules
        bevy_count = len(crate.modules)
        strict_coverage = (len(strict_overlap) / bevy_count) if bevy_count > 0 else 0.0
        rows.append(
            CrateCoverage(
                crate=crate,
                packages=mapped_packages,
                bevy_module_count=bevy_count,
                engine_module_count=len(mapped_modules),
                strict_overlap_count=len(strict_overlap),
                leaf_overlap_count=len(leaf_overlap),
                strict_coverage=strict_coverage,
                missing_modules=sorted(crate.modules - mapped_modules),
                extra_modules=sorted(mapped_modules - crate.modules),
            )
        )
    return rows


def format_percent(value: float) -> str:
    return f"{value * 100.0:.1f}%"


def render_report(
    repo_root: Path,
    bevy_crates_root: Path,
    engine_root: Path,
    rows: list[CrateCoverage],
    packages: list[EnginePackage],
    max_module_report: int,
    show_all_packages: bool,
    show_unmatched_packages: bool,
) -> str:
    package_to_crates: dict[str, list[str]] = {package.display_name: [] for package in packages}
    mapped_crates = 0
    for row in rows:
        if row.packages:
            mapped_crates += 1
        for package in row.packages:
            package_to_crates[package.display_name].append(row.crate.name)

    total_bevy_modules = sum(row.bevy_module_count for row in rows)
    total_engine_modules_mapped = sum(row.engine_module_count for row in rows)
    total_missing = sum(len(row.missing_modules) for row in rows)
    total_extra = sum(len(row.extra_modules) for row in rows)
    unmatched_crates = sorted([row.crate.name for row in rows if not row.packages])
    unmatched_packages = sorted(
        [package_name for package_name, crate_names in package_to_crates.items() if not crate_names]
    )

    lines: list[str] = []
    lines.append("Bevy ↔ mgstudio-engine Structure Parity Report")
    lines.append("")
    lines.append(f"Repository root: {repo_root.as_posix()}")
    lines.append(f"Bevy crates root: {bevy_crates_root.as_posix()}")
    lines.append(f"Engine root: {engine_root.as_posix()}")
    lines.append("")
    lines.append("Summary")
    lines.append(f"- Bevy crates scanned: {len(rows)}")
    lines.append(f"- Engine packages scanned: {len(packages)}")
    lines.append(f"- Mapped crates: {mapped_crates}")
    lines.append(f"- Unmatched crates: {len(unmatched_crates)}")
    lines.append(f"- Unmatched packages: {len(unmatched_packages)}")
    lines.append(f"- Total bevy modules: {total_bevy_modules}")
    lines.append(f"- Total mapped engine modules (crate union count): {total_engine_modules_mapped}")
    lines.append(f"- Total missing modules (crate perspective): {total_missing}")
    lines.append(f"- Total extra modules (crate perspective): {total_extra}")
    lines.append("")
    lines.append("Crate Coverage")
    lines.append("crate | mapped_packages | bevy_modules | engine_modules | strict_overlap | leaf_overlap | strict_coverage")
    lines.append("--- | --- | ---: | ---: | ---: | ---: | ---:")
    for row in sorted(rows, key=lambda item: item.crate.name):
        mapped_names = ",".join(package.display_name for package in row.packages) if row.packages else "-"
        lines.append(
            f"{row.crate.name} | {mapped_names} | {row.bevy_module_count} | "
            f"{row.engine_module_count} | {row.strict_overlap_count} | "
            f"{row.leaf_overlap_count} | {format_percent(row.strict_coverage)}"
        )
    lines.append("")
    lines.append("Package Coverage")
    lines.append("package | mapped_crates | module_count")
    lines.append("--- | --- | ---:")
    package_rows = sorted(packages, key=lambda item: item.display_name)
    if not show_all_packages:
        package_rows = [
            package
            for package in package_rows
            if package_to_crates[package.display_name]
        ]
    if package_rows:
        for package in package_rows:
            mapped = package_to_crates[package.display_name]
            crate_names = ",".join(sorted(mapped)) if mapped else "-"
            lines.append(f"{package.display_name} | {crate_names} | {len(package.modules)}")
    else:
        lines.append("- | - | -")

    if unmatched_crates:
        lines.append("")
        lines.append("Unmatched Bevy Crates")
        for crate_name in unmatched_crates:
            lines.append(f"- {crate_name}")

    if show_unmatched_packages and unmatched_packages:
        lines.append("")
        lines.append("Unmatched Engine Packages")
        for package_name in unmatched_packages:
            lines.append(f"- {package_name}")

    lines.append("")
    lines.append("Missing/Extra Module Report")
    lines.append(
        f"(Showing up to {max_module_report} entries per list. Module keys are path-like identifiers without file extensions.)"
    )
    detailed_rows = sorted(
        rows,
        key=lambda item: (
            -(len(item.missing_modules) + len(item.extra_modules)),
            item.crate.name,
        ),
    )
    for row in detailed_rows:
        if not row.missing_modules and not row.extra_modules:
            continue
        mapped_names = ",".join(package.display_name for package in row.packages) if row.packages else "-"
        lines.append("")
        lines.append(f"[{row.crate.name} -> {mapped_names}]")
        lines.append(f"- missing_modules: {len(row.missing_modules)}")
        for module in row.missing_modules[:max_module_report]:
            lines.append(f"  - {module}")
        if len(row.missing_modules) > max_module_report:
            remaining = len(row.missing_modules) - max_module_report
            lines.append(f"  - ... ({remaining} more)")
        lines.append(f"- extra_modules: {len(row.extra_modules)}")
        for module in row.extra_modules[:max_module_report]:
            lines.append(f"  - {module}")
        if len(row.extra_modules) > max_module_report:
            remaining = len(row.extra_modules) - max_module_report
            lines.append(f"  - ... ({remaining} more)")

    if all(not row.missing_modules and not row.extra_modules for row in rows):
        lines.append("- No missing/extra modules found for mapped crate/package pairs.")

    return "\n".join(lines)


def build_json_payload(
    repo_root: Path,
    bevy_crates_root: Path,
    engine_root: Path,
    rows: list[CrateCoverage],
    packages: list[EnginePackage],
) -> dict:
    package_to_crates: dict[str, list[str]] = {package.display_name: [] for package in packages}
    for row in rows:
        for package in row.packages:
            package_to_crates[package.display_name].append(row.crate.name)
    return {
        "repo_root": repo_root.as_posix(),
        "bevy_crates_root": bevy_crates_root.as_posix(),
        "engine_root": engine_root.as_posix(),
        "summary": {
            "bevy_crates_scanned": len(rows),
            "engine_packages_scanned": len(packages),
            "mapped_crates": sum(1 for row in rows if row.packages),
            "unmatched_crates": sum(1 for row in rows if not row.packages),
            "unmatched_packages": sum(
                1 for package_name, crate_names in package_to_crates.items() if not crate_names
            ),
            "total_bevy_modules": sum(row.bevy_module_count for row in rows),
            "total_mapped_engine_modules": sum(row.engine_module_count for row in rows),
            "total_missing_modules": sum(len(row.missing_modules) for row in rows),
            "total_extra_modules": sum(len(row.extra_modules) for row in rows),
        },
        "crate_coverage": [
            {
                "crate": row.crate.name,
                "mapped_packages": [package.display_name for package in row.packages],
                "bevy_modules": row.bevy_module_count,
                "engine_modules": row.engine_module_count,
                "strict_overlap": row.strict_overlap_count,
                "leaf_overlap": row.leaf_overlap_count,
                "strict_coverage": row.strict_coverage,
                "missing_modules": row.missing_modules,
                "extra_modules": row.extra_modules,
            }
            for row in sorted(rows, key=lambda item: item.crate.name)
        ],
        "package_coverage": [
            {
                "package": package.display_name,
                "module_count": len(package.modules),
                "mapped_crates": sorted(package_to_crates[package.display_name]),
            }
            for package in sorted(packages, key=lambda item: item.display_name)
        ],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Audit structural parity between Bevy crates (bevy/crates/*/src/**) "
            "and MoonBit engine packages (mgstudio-engine/**)."
        ),
        epilog=(
            "Default usage expects to be run from repository root. "
            "Example: scripts/parity_bevy_engine.py --max-module-report 25"
        ),
    )
    parser.add_argument(
        "--repo-root",
        default=".",
        help="Repository root path (default: current directory).",
    )
    parser.add_argument(
        "--bevy-crates",
        default="bevy/crates",
        help="Path to Bevy crates root, relative to --repo-root.",
    )
    parser.add_argument(
        "--engine-root",
        default="mgstudio-engine",
        help="Path to engine root, relative to --repo-root.",
    )
    parser.add_argument(
        "--only-crate",
        action="append",
        default=[],
        help="Restrict report to specific crate names. Repeatable.",
    )
    parser.add_argument(
        "--max-module-report",
        type=int,
        default=20,
        help="Maximum missing/extra modules printed per crate (default: 20).",
    )
    parser.add_argument(
        "--json-out",
        default="",
        help="Optional path to write JSON output.",
    )
    parser.add_argument(
        "--include-examples",
        action="store_true",
        help="Include mgstudio-engine/examples/** packages in package discovery.",
    )
    parser.add_argument(
        "--show-all-packages",
        action="store_true",
        help="Show all scanned engine packages in package coverage table.",
    )
    parser.add_argument(
        "--show-unmatched-packages",
        action="store_true",
        help="Print full unmatched engine package list.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(args.repo_root).resolve()
    bevy_crates_root = (repo_root / args.bevy_crates).resolve()
    engine_root = (repo_root / args.engine_root).resolve()

    if not bevy_crates_root.exists():
        print(f"error: bevy crates root not found: {bevy_crates_root}", file=sys.stderr)
        return 2
    if not engine_root.exists():
        print(f"error: engine root not found: {engine_root}", file=sys.stderr)
        return 2

    crates = discover_bevy_crates(bevy_crates_root)
    packages = discover_engine_packages(
        engine_root,
        include_examples=args.include_examples,
    )
    only_crates = set(args.only_crate)
    rows = compute_coverage(crates, packages, only_crates)

    report = render_report(
        repo_root=repo_root,
        bevy_crates_root=bevy_crates_root,
        engine_root=engine_root,
        rows=rows,
        packages=packages,
        max_module_report=max(0, args.max_module_report),
        show_all_packages=args.show_all_packages,
        show_unmatched_packages=args.show_unmatched_packages,
    )
    print(report)

    if args.json_out:
        payload = build_json_payload(
            repo_root=repo_root,
            bevy_crates_root=bevy_crates_root,
            engine_root=engine_root,
            rows=rows,
            packages=packages,
        )
        output_path = Path(args.json_out)
        if not output_path.is_absolute():
            output_path = repo_root / output_path
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
        print(f"\nJSON report written to: {output_path.as_posix()}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
