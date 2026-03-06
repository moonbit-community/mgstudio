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

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <moon-package> <output-png>" >&2
  echo "example: $0 examples/3d/3d_scene docs/parity/artifacts/3d_scene.png" >&2
  exit 2
fi

if ! command -v screencapture >/dev/null 2>&1; then
  echo "[capture] missing 'screencapture' (macOS required for this capture path)" >&2
  exit 3
fi

PACKAGE="$1"
OUTPUT_PNG="$2"
SETTLE_SECONDS="${MGSTUDIO_PARITY_SETTLE_SECONDS:-4}"
RUN_TIMEOUT_SECONDS="${MGSTUDIO_PARITY_RUN_TIMEOUT_SECONDS:-12}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"

mkdir -p "$(dirname "${OUTPUT_PNG}")"
RUN_LOG="${OUTPUT_PNG%.png}.run.log"
META_JSON="${OUTPUT_PNG%.png}.meta.json"

echo "[capture] moon build --target native --release ${PACKAGE}"
moon -C "${ENGINE_DIR}" build --target native --release "${PACKAGE}"

echo "[capture] moon run --target native --release ${PACKAGE}"
(
  moon -C "${ENGINE_DIR}" run --target native --release "${PACKAGE}" >"${RUN_LOG}" 2>&1
) &
APP_PID=$!

cleanup() {
  set +e
  if kill -0 "${APP_PID}" >/dev/null 2>&1; then
    kill "${APP_PID}" >/dev/null 2>&1
    sleep 0.3
    kill -9 "${APP_PID}" >/dev/null 2>&1 || true
    wait "${APP_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

elapsed=0
while [[ "${elapsed}" -lt "${RUN_TIMEOUT_SECONDS}" ]]; do
  if ! kill -0 "${APP_PID}" >/dev/null 2>&1; then
    echo "[capture] process exited before capture window was sampled: ${PACKAGE}" >&2
    exit 4
  fi
  sleep 1
  elapsed=$((elapsed + 1))
  if [[ "${elapsed}" -ge "${SETTLE_SECONDS}" ]]; then
    break
  fi
done

echo "[capture] screencapture -> ${OUTPUT_PNG}"
screencapture -x "${OUTPUT_PNG}"

if [[ ! -s "${OUTPUT_PNG}" ]]; then
  echo "[capture] output image missing or empty: ${OUTPUT_PNG}" >&2
  exit 5
fi

cat >"${META_JSON}" <<EOF
{
  "package": "${PACKAGE}",
  "output_png": "${OUTPUT_PNG}",
  "run_log": "${RUN_LOG}",
  "settle_seconds": ${SETTLE_SECONDS},
  "run_timeout_seconds": ${RUN_TIMEOUT_SECONDS},
  "capture_mode": "fullscreen-snapshot"
}
EOF

echo "[capture] done: ${OUTPUT_PNG}"
