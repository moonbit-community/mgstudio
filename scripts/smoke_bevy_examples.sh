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
MGSTUDIO_CMD="${MGSTUDIO_CMD:-${REPO_DIR}/mgstudio-dev}"
MGSTUDIO_RUNNER="${MGSTUDIO_RUNNER:-}"

# Representative cross-domain smoke set for current port coverage.
# - 2d: sprite
# - 3d: pbr
# - ui: button
# - input: gamepad_input_events
# - window/camera behavior: camera_sub_view
# - asset usage: texture_atlas
EXAMPLE_PACKAGES=(
  "examples/2d/sprite"
  "examples/3d/pbr"
  "examples/ui/button"
  "examples/input/gamepad_input_events"
  "examples/3d/camera_sub_view"
  "examples/2d/texture_atlas"
)

run_runtime_smoke="${MGSTUDIO_SMOKE_RUNTIME:-0}"

RUNNER_PREFIX=()
if [[ -n "${MGSTUDIO_RUNNER}" ]]; then
  # shellcheck disable=SC2206
  RUNNER_PREFIX=( ${MGSTUDIO_RUNNER} )
fi

echo "[smoke] Building all mgstudio-engine packages in release mode"
moon -C "${ENGINE_DIR}" build --release

echo "[smoke] Build-only execution for representative examples"
for pkg in "${EXAMPLE_PACKAGES[@]}"; do
  if [[ ! -d "${ENGINE_DIR}/${pkg}" ]]; then
    echo "[smoke] skip missing package: ${pkg}"
    continue
  fi
  echo "[smoke] moon build --target wasm ${pkg}"
  moon -C "${ENGINE_DIR}" build --release --target wasm "${pkg}"
done

if [[ "${run_runtime_smoke}" != "1" ]]; then
  echo "[smoke] Runtime smoke disabled (set MGSTUDIO_SMOKE_RUNTIME=1 to enable)."
  exit 0
fi

if [[ ! -x "${MGSTUDIO_CMD}" ]]; then
  if command -v mgstudio >/dev/null 2>&1; then
    MGSTUDIO_CMD="$(command -v mgstudio)"
  else
    echo "[smoke] mgstudio CLI not found; skip runtime smoke."
    exit 0
  fi
fi

if ! command -v timeout >/dev/null 2>&1; then
  echo "[smoke] timeout command not found; skip runtime smoke."
  exit 0
fi

RUNTIME_EXAMPLES=(
  "examples/2d/sprite"
  "examples/2d/2d_shapes"
  "examples/3d/pbr"
  "examples/ui/button"
  "examples/input/gamepad_input_events"
)

echo "[smoke] Runtime smoke (time-boxed)"
runtime_smoke_executed=0
for pkg in "${RUNTIME_EXAMPLES[@]}"; do
  game_json="${ENGINE_DIR}/${pkg}/moon.game.json"
  if [[ ! -f "${game_json}" ]]; then
    echo "[smoke] skip missing game config: ${game_json}"
    continue
  fi

  echo "[smoke] timeout 10s ${MGSTUDIO_RUNNER:+${MGSTUDIO_RUNNER} }${MGSTUDIO_CMD} run --game ${game_json}"
  runtime_smoke_executed=$((runtime_smoke_executed + 1))
  rc=0
  if [[ ${#RUNNER_PREFIX[@]} -gt 0 ]]; then
    set +e
    timeout 10s "${RUNNER_PREFIX[@]}" "${MGSTUDIO_CMD}" run --game "${game_json}"
    rc=$?
    set -e
  else
    set +e
    timeout 10s "${MGSTUDIO_CMD}" run --game "${game_json}"
    rc=$?
    set -e
  fi

  if [[ "${rc}" -eq 124 ]]; then
    echo "[smoke] timeout reached (treated as pass): ${pkg}"
    continue
  fi
  if [[ "${rc}" -ne 0 ]]; then
    echo "[smoke] runtime smoke failed: ${pkg} (exit=${rc})"
    exit "${rc}"
  fi
done

if [[ "${runtime_smoke_executed}" -eq 0 ]]; then
  echo "[smoke] runtime smoke failed: no runnable runtime examples were found." >&2
  exit 1
fi
