#!/usr/bin/env bash
# Copyright 2026 International Digital Economy Academy
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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"
export REPO_DIR

python3 - <<'PY'
from __future__ import annotations

import hashlib
import os
import sys
from pathlib import Path

repo = Path(os.environ['REPO_DIR'])
bevy = repo / 'bevy'
mirror = repo / 'mgstudio-engine' / 'assets' / 'shaders' / 'bevy'

if not (bevy / 'crates').is_dir():
    print(
        f"[shader-mirror-gate] missing Bevy baseline checkout at {bevy / 'crates'}; "
        "run ./scripts/fetch_bevy.sh first",
        file=sys.stderr,
    )
    sys.exit(2)
if not mirror.is_dir():
    print(f"[shader-mirror-gate] missing mirror dir: {mirror}", file=sys.stderr)
    sys.exit(1)

expected: dict[Path, Path] = {}

for src in sorted((bevy / 'crates').rglob('*.wgsl')):
    parts = src.parts
    try:
        i = parts.index('crates')
    except ValueError:
        continue
    crate = parts[i + 1]
    try:
        j = parts.index('src', i + 2)
    except ValueError:
        continue
    rel = Path(*parts[j + 1 :])
    expected[Path(crate) / rel] = src

for src in sorted((bevy / 'crates' / 'bevy_feathers' / 'assets' / 'shaders').rglob('*.wgsl')):
    rel = src.relative_to(bevy / 'crates' / 'bevy_feathers')
    expected[Path('bevy_feathers') / rel] = src

actual = {
    p.relative_to(mirror): p
    for p in sorted(mirror.rglob('*.wgsl'))
}

expected_keys = set(expected.keys())
actual_keys = set(actual.keys())

allowed_legacy_extra = {
    Path('mgstudio_runtime/mesh3d.wgsl'),
    Path('mgstudio_runtime/3d/motion_vector.wgsl'),
    Path('mgstudio_runtime/ui/box_shadow.wgsl'),
    Path('mgstudio_runtime/ui/ui.wgsl'),
    Path('mgstudio_runtime/ui/ui_texture_slice.wgsl'),
}

missing = sorted(expected_keys - actual_keys)
extra_raw = sorted(actual_keys - expected_keys)
extra = [rel for rel in extra_raw if rel not in allowed_legacy_extra]

if missing:
    print('[shader-mirror-gate] missing mirror files:', file=sys.stderr)
    for rel in missing:
        print(f'  - {rel}', file=sys.stderr)
if extra:
    print('[shader-mirror-gate] unexpected extra files:', file=sys.stderr)
    for rel in extra:
        print(f'  - {rel}', file=sys.stderr)

mismatch: list[Path] = []
for rel in sorted(expected_keys & actual_keys):
    src = expected[rel]
    dst = actual[rel]
    h1 = hashlib.sha256(src.read_bytes()).hexdigest()
    h2 = hashlib.sha256(dst.read_bytes()).hexdigest()
    if h1 != h2:
        mismatch.append(rel)

if mismatch:
    print('[shader-mirror-gate] content mismatches:', file=sys.stderr)
    for rel in mismatch:
        print(f'  - {rel}', file=sys.stderr)

if missing or extra or mismatch:
    sys.exit(1)

legacy_present = [rel for rel in extra_raw if rel in allowed_legacy_extra]
if legacy_present:
    print('[shader-mirror-gate] warning: legacy non-bevy shader still present:')
    for rel in legacy_present:
        print(f'  - {rel}')

print(f"[shader-mirror-gate] pass: {len(expected_keys)} files mirrored exactly")
PY
