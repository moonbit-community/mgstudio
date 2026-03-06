#!/usr/bin/env bash
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

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENGINE_DIR="${REPO_DIR}/mgstudio-engine"

# Native-only representative set.
EXAMPLE_PACKAGES=(
  "examples/2d/sprite"
  "examples/2d/2d_shapes"
  "examples/3d/pbr"
  "examples/3d/3d_shapes"
  "examples/3d/3d_scene"
  "examples/ui/button"
  "examples/input/gamepad_input_events"
)

run_runtime_smoke="${MGSTUDIO_SMOKE_RUNTIME:-0}"

echo "[smoke] native build for representative examples"
for pkg in "${EXAMPLE_PACKAGES[@]}"; do
  if [[ ! -d "${ENGINE_DIR}/${pkg}" ]]; then
    echo "[smoke] skip missing package: ${pkg}"
    continue
  fi
  echo "[smoke] moon build --target native ${pkg}"
  moon -C "${ENGINE_DIR}" build --release --target native "${pkg}"
done

if [[ "${run_runtime_smoke}" != "1" ]]; then
  echo "[smoke] runtime smoke disabled (set MGSTUDIO_SMOKE_RUNTIME=1 to enable)."
  exit 0
fi

if ! command -v timeout >/dev/null 2>&1; then
  echo "[smoke] timeout command not found; skip runtime smoke."
  exit 0
fi

echo "[smoke] native runtime smoke (time-boxed)"
for pkg in "${EXAMPLE_PACKAGES[@]}"; do
  if [[ ! -d "${ENGINE_DIR}/${pkg}" ]]; then
    continue
  fi
  echo "[smoke] timeout 10s moon run --target native ${pkg}"
  set +e
  timeout 10s moon -C "${ENGINE_DIR}" run --target native --release "${pkg}"
  rc=$?
  set -e

  if [[ "${rc}" -eq 124 ]]; then
    echo "[smoke] timeout reached (treated as pass): ${pkg}"
    continue
  fi
  if [[ "${rc}" -ne 0 ]]; then
    echo "[smoke] runtime smoke failed: ${pkg} (exit=${rc})"
    exit "${rc}"
  fi
done
