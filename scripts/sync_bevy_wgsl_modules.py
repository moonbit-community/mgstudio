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
import pathlib
import re
import sys
from dataclasses import dataclass

DEFINE_IMPORT_PATH_RE = re.compile(r"^\s*#define_import_path\s+([A-Za-z0-9_:]+)", re.MULTILINE)

# Bevy intentionally contains two sources for this import path.
# Prefer the functional implementation over the dummy fallback.
PREFERRED_SOURCE_BY_IMPORT_PATH = {
    "bevy_pbr::meshlet_visibility_buffer_resolve": "bevy/crates/bevy_pbr/src/meshlet/visibility_buffer_resolve.wgsl",
}

# Local overlay shaders under `assets/shaders/bevy/` that are intentionally
# maintained by mgstudio and should not be removed by bevy sync/check.
LOCAL_OVERLAY_PREFIXES = ("mgstudio_runtime/",)


@dataclass(frozen=True)
class ModuleCandidate:
    import_path: str
    source_rel: str
    strategy: str

    @property
    def is_dummy(self) -> bool:
        return "dummy" in pathlib.PurePosixPath(self.source_rel).name

    @property
    def shader_rel_path(self) -> str:
        return f"bevy/{self.import_path.replace('::', '/')}.wgsl"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync Bevy WGSL modules into mgstudio-engine/assets/shaders/bevy."
    )
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=pathlib.Path(__file__).resolve().parents[1],
        help="Repository root path.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check mode: fail if synced shaders/index drift from generated output.",
    )
    return parser.parse_args()


def parse_define_import_path(content: str) -> str | None:
    match = DEFINE_IMPORT_PATH_RE.search(content)
    if match is None:
        return None
    return match.group(1)


def fallback_import_path(source_rel: pathlib.PurePosixPath) -> str:
    parts = source_rel.parts
    if len(parts) < 5 or parts[0] != "bevy" or parts[1] != "crates":
        raise RuntimeError(f"unexpected Bevy shader path for fallback mapping: {source_rel}")

    crate_name = parts[2]
    within_crate = list(parts[3:])

    if within_crate and within_crate[0] == "src":
        within_crate = within_crate[1:]
    elif len(within_crate) >= 2 and within_crate[0] == "assets" and within_crate[1] == "shaders":
        within_crate = within_crate[2:]

    if not within_crate:
        raise RuntimeError(f"unable to build fallback import path: {source_rel}")

    file_stem = pathlib.PurePosixPath(within_crate[-1]).stem
    module_parts = [crate_name, *within_crate[:-1], file_stem]
    return "::".join(module_parts)


def discover_candidates(root: pathlib.Path) -> list[ModuleCandidate]:
    bevy_crates = root / "bevy" / "crates"
    if not bevy_crates.exists():
        raise RuntimeError(f"missing vendored Bevy crates directory: {bevy_crates}")

    candidates: list[ModuleCandidate] = []
    for shader_path in sorted(bevy_crates.glob("**/*.wgsl")):
        source_rel = pathlib.PurePosixPath(shader_path.relative_to(root).as_posix())
        content = shader_path.read_text(encoding="utf-8", errors="ignore")
        defined = parse_define_import_path(content)
        if defined is not None:
            candidates.append(
                ModuleCandidate(
                    import_path=defined,
                    source_rel=source_rel.as_posix(),
                    strategy="define_import_path",
                )
            )
            continue

        candidates.append(
            ModuleCandidate(
                import_path=fallback_import_path(source_rel),
                source_rel=source_rel.as_posix(),
                strategy="fallback_path",
            )
        )

    return candidates


def choose_preferred(existing: ModuleCandidate, incoming: ModuleCandidate) -> ModuleCandidate:
    preferred_source = PREFERRED_SOURCE_BY_IMPORT_PATH.get(existing.import_path)
    if preferred_source is not None:
        if incoming.source_rel == preferred_source:
            return incoming
        if existing.source_rel == preferred_source:
            return existing

    if existing.strategy != incoming.strategy:
        if existing.strategy == "define_import_path":
            return existing
        return incoming

    if existing.is_dummy != incoming.is_dummy:
        if existing.is_dummy:
            return incoming
        return existing

    if incoming.source_rel < existing.source_rel:
        return incoming
    return existing


def resolve_modules(candidates: list[ModuleCandidate]) -> tuple[dict[str, ModuleCandidate], list[str]]:
    by_import_path: dict[str, ModuleCandidate] = {}
    collisions: list[str] = []

    for candidate in candidates:
        previous = by_import_path.get(candidate.import_path)
        if previous is None:
            by_import_path[candidate.import_path] = candidate
            continue

        chosen = choose_preferred(previous, candidate)
        rejected = candidate if chosen is previous else previous
        by_import_path[candidate.import_path] = chosen
        collisions.append(
            f"{candidate.import_path}: keep {chosen.source_rel} ({chosen.strategy}), "
            f"drop {rejected.source_rel} ({rejected.strategy})"
        )

    return by_import_path, collisions


def render_module_index(modules: dict[str, ModuleCandidate]) -> str:
    mapping = {
        import_path: modules[import_path].shader_rel_path
        for import_path in sorted(modules.keys())
    }
    return json.dumps(mapping, indent=2, sort_keys=True) + "\n"


def build_expected_outputs(root: pathlib.Path, modules: dict[str, ModuleCandidate]) -> dict[pathlib.Path, bytes]:
    shaders_root = root / "mgstudio-engine" / "assets" / "shaders"
    expected: dict[pathlib.Path, bytes] = {}

    for import_path in sorted(modules.keys()):
        module = modules[import_path]
        source_abs = root / module.source_rel
        target_abs = shaders_root / module.shader_rel_path
        expected[target_abs] = source_abs.read_bytes()

    index_abs = shaders_root / "bevy" / "module_index.json"
    expected[index_abs] = render_module_index(modules).encode("utf-8")
    return expected


def prune_empty_dirs(base_dir: pathlib.Path) -> None:
    if not base_dir.exists():
        return
    for path in sorted(base_dir.glob("**/*"), reverse=True):
        if path.is_dir():
            try:
                path.rmdir()
            except OSError:
                continue


def check_drift(expected: dict[pathlib.Path, bytes], root: pathlib.Path) -> int:
    bevy_shader_dir = root / "mgstudio-engine" / "assets" / "shaders" / "bevy"
    expected_files = set(expected.keys())
    expected_wgsl = {path for path in expected_files if path.suffix == ".wgsl"}

    actual_wgsl = set()
    if bevy_shader_dir.exists():
        for path in bevy_shader_dir.glob("**/*.wgsl"):
            rel_inside_bevy = path.relative_to(bevy_shader_dir).as_posix()
            if rel_inside_bevy.startswith(LOCAL_OVERLAY_PREFIXES):
                continue
            actual_wgsl.add(path)
    extra_wgsl = sorted(str(path.relative_to(root).as_posix()) for path in (actual_wgsl - expected_wgsl))
    missing_files = sorted(
        str(path.relative_to(root).as_posix()) for path in expected_files if not path.exists()
    )

    changed_files: list[str] = []
    for path in sorted(expected_files):
        if not path.exists():
            continue
        if path.read_bytes() != expected[path]:
            changed_files.append(path.relative_to(root).as_posix())

    if not extra_wgsl and not missing_files and not changed_files:
        print("bevy WGSL modules are up-to-date")
        return 0

    if missing_files:
        print("missing files:", file=sys.stderr)
        for rel in missing_files:
            print(f"  - {rel}", file=sys.stderr)

    if changed_files:
        print("changed files:", file=sys.stderr)
        for rel in changed_files:
            print(f"  - {rel}", file=sys.stderr)

    if extra_wgsl:
        print("extra synced WGSL files:", file=sys.stderr)
        for rel in extra_wgsl:
            print(f"  - {rel}", file=sys.stderr)

    print("drift detected: run `python3 scripts/sync_bevy_wgsl_modules.py`", file=sys.stderr)
    return 1


def sync_outputs(expected: dict[pathlib.Path, bytes], root: pathlib.Path) -> None:
    bevy_shader_dir = root / "mgstudio-engine" / "assets" / "shaders" / "bevy"
    expected_wgsl = {path for path in expected if path.suffix == ".wgsl"}
    existing_wgsl = set(bevy_shader_dir.glob("**/*.wgsl")) if bevy_shader_dir.exists() else set()

    removed = 0
    for stale_file in sorted(existing_wgsl - expected_wgsl):
        rel_inside_bevy = stale_file.relative_to(bevy_shader_dir).as_posix()
        if rel_inside_bevy.startswith(LOCAL_OVERLAY_PREFIXES):
            continue
        stale_file.unlink()
        removed += 1

    prune_empty_dirs(bevy_shader_dir)

    written = 0
    unchanged = 0
    for path in sorted(expected.keys()):
        path.parent.mkdir(parents=True, exist_ok=True)
        content = expected[path]
        if path.exists() and path.read_bytes() == content:
            unchanged += 1
            continue
        path.write_bytes(content)
        written += 1

    print(f"sync complete: {written} written, {unchanged} unchanged, {removed} removed")


def main() -> int:
    args = parse_args()
    root = args.root.resolve()

    candidates = discover_candidates(root)
    modules, collisions = resolve_modules(candidates)
    expected = build_expected_outputs(root, modules)

    if collisions:
        print("resolved import path collisions:")
        for line in collisions:
            print(f"  - {line}")

    if args.check:
        return check_drift(expected, root)

    sync_outputs(expected, root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
