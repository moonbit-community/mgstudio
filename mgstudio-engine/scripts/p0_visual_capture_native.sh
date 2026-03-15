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

PACKAGE="$1"
OUTPUT_PNG="$2"
RUN_TIMEOUT_SECONDS="${MGSTUDIO_PARITY_RUN_TIMEOUT_SECONDS:-60}"
SETTLE_SECONDS="${MGSTUDIO_PARITY_SETTLE_SECONDS:-4}"
CAPTURE_DELAY_FRAMES="${MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES:-1}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"

mkdir -p "$(dirname "${OUTPUT_PNG}")"
RUN_LOG="${OUTPUT_PNG%.png}.run.log"
META_JSON="${OUTPUT_PNG%.png}.meta.json"
RGBA8_BLOB="${OUTPUT_PNG%.png}.rgba8.blob"

echo "[capture] moon build --target native --release ${PACKAGE}"
moon -C "${ENGINE_DIR}" build --target native --release "${PACKAGE}"

rm -f "${OUTPUT_PNG}" "${RGBA8_BLOB}"

echo "[capture] moon run --target native --release ${PACKAGE}"
(
  MGSTUDIO_PARITY_CAPTURE_RGBA8_BLOB="${RGBA8_BLOB}" \
    MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES="${CAPTURE_DELAY_FRAMES}" \
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
blob_ready=0
capture_mode="gpu-surface-readback"
capture_source="${RGBA8_BLOB}"
while [[ "${elapsed}" -lt "${RUN_TIMEOUT_SECONDS}" ]]; do
  if [[ -s "${RGBA8_BLOB}" ]]; then
    blob_ready=1
    break
  fi
  if ! kill -0 "${APP_PID}" >/dev/null 2>&1; then
    break
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

if [[ "${blob_ready}" -eq 1 ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "[capture] python3 missing; falling back to screencapture path" >&2
    blob_ready=0
  else
    echo "[capture] decode rgba8 blob -> ${OUTPUT_PNG}"
    set +e
    python3 - "${RGBA8_BLOB}" "${OUTPUT_PNG}" <<'PY'
import pathlib
import struct
import sys
import zlib

blob_path = pathlib.Path(sys.argv[1])
png_path = pathlib.Path(sys.argv[2])
blob = blob_path.read_bytes()
if len(blob) < 8:
    raise SystemExit("blob payload too short")
width, height = struct.unpack("<II", blob[:8])
if width <= 0 or height <= 0:
    raise SystemExit("invalid image dimensions")
pixels = blob[8:]
expected = width * height * 4
if len(pixels) != expected:
    raise SystemExit(f"invalid pixel payload length: got={len(pixels)} expected={expected}")
scanlines = bytearray()
row_len = width * 4
for y in range(height):
    scanlines.append(0)
    row_start = y * row_len
    scanlines.extend(pixels[row_start:row_start + row_len])
compressed = zlib.compress(bytes(scanlines), level=6)

def chunk(kind: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + kind
        + payload
        + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)
    )

png = bytearray(b"\x89PNG\r\n\x1a\n")
png.extend(chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)))
png.extend(chunk(b"IDAT", compressed))
png.extend(chunk(b"IEND", b""))
png_path.write_bytes(bytes(png))
PY
    convert_rc=$?
    set -e
    if [[ "${convert_rc}" -ne 0 || ! -s "${OUTPUT_PNG}" ]]; then
      echo "[capture] failed to decode rgba8 blob; falling back to screencapture path" >&2
      blob_ready=0
      rm -f "${OUTPUT_PNG}"
    fi
  fi
fi

if [[ "${blob_ready}" -eq 0 ]]; then
  capture_mode="fullscreen-snapshot"
  capture_source="screen"
  if ! command -v screencapture >/dev/null 2>&1; then
    echo "[capture] missing 'screencapture' for fallback capture path" >&2
    exit 3
  fi
  if ! kill -0 "${APP_PID}" >/dev/null 2>&1; then
    echo "[capture] process exited before screenshot capture: ${PACKAGE}" >&2
    exit 4
  fi
  if [[ "${elapsed}" -lt "${SETTLE_SECONDS}" ]]; then
    sleep "$((SETTLE_SECONDS - elapsed))"
  fi
  echo "[capture] screencapture -> ${OUTPUT_PNG}"
  screencapture -x "${OUTPUT_PNG}"
fi

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
  "capture_delay_frames": ${CAPTURE_DELAY_FRAMES},
  "capture_mode": "${capture_mode}",
  "capture_source": "${capture_source}",
  "rgba8_blob": "${RGBA8_BLOB}"
}
EOF

echo "[capture] done: ${OUTPUT_PNG}"
