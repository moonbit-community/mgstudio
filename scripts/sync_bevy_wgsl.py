#!/usr/bin/env python3
"""Mirror upstream Bevy WGSL files into mgstudio-engine.

This script intentionally copies WGSL files byte-for-byte. It only rewrites the
destination path:

  bevy/crates/bevy_pbr/src/render/pbr.wgsl
    -> mgstudio-engine/pbr/render/pbr.wgsl

  bevy/assets/shaders/custom_material.wgsl
    -> mgstudio-engine/assets/shaders/custom_material.wgsl

The contents stay unchanged so Bevy remains the long-term source of truth.
"""

from __future__ import annotations

import argparse
import filecmp
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class CopyPlan:
    source: Path
    destination: Path


def repository_root() -> Path:
    return Path(__file__).resolve().parents[1]


def destination_for(source: Path, bevy_root: Path, mgstudio_root: Path) -> Path | None:
    try:
        rel = source.relative_to(bevy_root / "crates")
    except ValueError:
        rel = None

    if rel is not None:
        parts = rel.parts
        if len(parts) >= 3 and parts[0].startswith("bevy_") and parts[1] == "src":
            package = parts[0][len("bevy_") :]
            return mgstudio_root / package / Path(*parts[2:])
        return None

    try:
        rel = source.relative_to(bevy_root / "assets")
    except ValueError:
        return None
    return mgstudio_root / "assets" / rel


def collect_copy_plan(bevy_root: Path, mgstudio_root: Path) -> list[CopyPlan]:
    plans: list[CopyPlan] = []
    for source in sorted(bevy_root.rglob("*.wgsl")):
        destination = destination_for(source, bevy_root, mgstudio_root)
        if destination is not None:
            plans.append(CopyPlan(source=source, destination=destination))
    return plans


def collect_extra_asset_shaders(bevy_root: Path, mgstudio_root: Path) -> list[Path]:
    bevy_asset_shader_root = bevy_root / "assets" / "shaders"
    mgstudio_asset_shader_root = mgstudio_root / "assets" / "shaders"
    if not mgstudio_asset_shader_root.exists():
        return []
    bevy_shader_names = {
        source.relative_to(bevy_asset_shader_root)
        for source in bevy_asset_shader_root.rglob("*.wgsl")
    }
    extras: list[Path] = []
    for candidate in sorted(mgstudio_asset_shader_root.rglob("*.wgsl")):
        rel = candidate.relative_to(mgstudio_asset_shader_root)
        if rel not in bevy_shader_names:
            extras.append(candidate)
    return extras


def copy_plan_is_current(plan: CopyPlan) -> bool:
    return plan.destination.exists() and filecmp.cmp(
        plan.source, plan.destination, shallow=False
    )


def run(check: bool) -> int:
    root = repository_root()
    bevy_root = root / "bevy"
    mgstudio_root = root / "mgstudio-engine"

    if not bevy_root.exists():
        print(f"missing Bevy checkout: {bevy_root}", file=sys.stderr)
        return 2
    if not mgstudio_root.exists():
        print(f"missing mgstudio engine root: {mgstudio_root}", file=sys.stderr)
        return 2

    plans = collect_copy_plan(bevy_root, mgstudio_root)
    extra_asset_shaders = collect_extra_asset_shaders(bevy_root, mgstudio_root)
    changed: list[CopyPlan] = []
    for plan in plans:
        if copy_plan_is_current(plan):
            continue
        changed.append(plan)
        if not check:
            plan.destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(plan.source, plan.destination)

    if check and (changed or extra_asset_shaders):
        print("WGSL mirror is out of date:")
        for plan in changed:
            print(f"  {plan.source.relative_to(root)} -> {plan.destination.relative_to(root)}")
        for extra in extra_asset_shaders:
            print(f"  extra asset shader: {extra.relative_to(root)}")
        return 1

    if not check:
        for extra in extra_asset_shaders:
            extra.unlink()

    action = "checked" if check else "copied"
    print(
        f"{action} {len(plans)} Bevy WGSL files"
        f" ({len(changed)} {'out of date' if check else 'updated'})"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Copy all Bevy WGSL files into mgstudio-engine matching paths."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="only verify that mirrored files are byte-for-byte identical",
    )
    args = parser.parse_args()
    return run(check=args.check)


if __name__ == "__main__":
    raise SystemExit(main())
