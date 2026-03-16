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
  echo "example: $0 examples/3d/3d_scene .private/parity/artifacts/3d_scene.png" >&2
  exit 2
fi

PACKAGE="$1"
OUTPUT_PNG="$2"
WGPU_LINK_MODE="${MBT_WGPU_LINK_MODE:-static}"
RUN_TIMEOUT_SECONDS="${MGSTUDIO_PARITY_RUN_TIMEOUT_SECONDS:-60}"
SETTLE_SECONDS="${MGSTUDIO_PARITY_SETTLE_SECONDS:-4}"
CAPTURE_DELAY_FRAMES="${MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES:-120}"
CAPTURE_RETRY_DELAY_FRAMES="${MGSTUDIO_PARITY_CAPTURE_RETRY_DELAY_FRAMES:-1}"
CAPTURE_RETRY_TIMEOUT_SECONDS="${MGSTUDIO_PARITY_CAPTURE_RETRY_TIMEOUT_SECONDS:-60}"
CAPTURE_DISABLE_RETRY="${MGSTUDIO_PARITY_CAPTURE_DISABLE_RETRY:-0}"
STOP_GRACE_SECONDS="${MGSTUDIO_PARITY_STOP_GRACE_SECONDS:-3}"
FORCE_KILL_AFTER_GRACE="${MGSTUDIO_PARITY_FORCE_KILL_AFTER_GRACE:-1}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"

mkdir -p "$(dirname "${OUTPUT_PNG}")"
RUN_LOG="${OUTPUT_PNG%.png}.run.log"
META_JSON="${OUTPUT_PNG%.png}.meta.json"
RGBA8_BLOB="${OUTPUT_PNG%.png}.rgba8.blob"

echo "[capture] moon build --target native --release ${PACKAGE}"
MBT_WGPU_LINK_MODE="${WGPU_LINK_MODE}" moon -C "${ENGINE_DIR}" build --target native --release "${PACKAGE}"

rm -f "${OUTPUT_PNG}" "${RGBA8_BLOB}"

APP_PID=""

start_app() {
  local delay_frames="$1"
  rm -f "${RGBA8_BLOB}"
  : >"${RUN_LOG}"
  echo "[capture] moon run --target native --release ${PACKAGE} (delay_frames=${delay_frames})"
  (
    MBT_WGPU_LINK_MODE="${WGPU_LINK_MODE}" \
      MGSTUDIO_PARITY_CAPTURE_RGBA8_BLOB="${RGBA8_BLOB}" \
      MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES="${delay_frames}" \
      moon -C "${ENGINE_DIR}" run --target native --release "${PACKAGE}" >"${RUN_LOG}" 2>&1
  ) &
  APP_PID=$!
}

stop_app() {
  if [[ -z "${APP_PID}" ]]; then
    return
  fi
  if kill -0 "${APP_PID}" >/dev/null 2>&1; then
    kill -TERM "${APP_PID}" >/dev/null 2>&1 || true
    elapsed_ms=0
    grace_ms=$((STOP_GRACE_SECONDS * 1000))
    while [[ "${elapsed_ms}" -lt "${grace_ms}" ]]; do
      if ! kill -0 "${APP_PID}" >/dev/null 2>&1; then
        break
      fi
      sleep 0.1
      elapsed_ms=$((elapsed_ms + 100))
    done
    if kill -0 "${APP_PID}" >/dev/null 2>&1; then
      if [[ "${FORCE_KILL_AFTER_GRACE}" == "1" ]]; then
        echo "[capture] warning: app pid=${APP_PID} still alive after ${STOP_GRACE_SECONDS}s; forcing SIGKILL" >&2
        kill -KILL "${APP_PID}" >/dev/null 2>&1 || true
      else
        echo "[capture] warning: app pid=${APP_PID} still alive after ${STOP_GRACE_SECONDS}s; leaving process running by config" >&2
        APP_PID=""
        return
      fi
    fi
  fi
  wait "${APP_PID}" >/dev/null 2>&1 || true
  APP_PID=""
}

wait_for_blob() {
  local timeout_seconds="$1"
  local elapsed_local=0
  while [[ "${elapsed_local}" -lt "${timeout_seconds}" ]]; do
    if [[ -s "${RGBA8_BLOB}" ]]; then
      return 0
    fi
    if [[ -n "${APP_PID}" ]] && ! kill -0 "${APP_PID}" >/dev/null 2>&1; then
      # The app may exit right after writing the capture blob.
      # Give the filesystem a short grace window before failing.
      local grace_ms=0
      while [[ "${grace_ms}" -lt 1000 ]]; do
        if [[ -s "${RGBA8_BLOB}" ]]; then
          return 0
        fi
        sleep 0.1
        grace_ms=$((grace_ms + 100))
      done
      return 1
    fi
    sleep 1
    elapsed_local=$((elapsed_local + 1))
  done
  return 1
}

cleanup() {
  stop_app
}
trap cleanup EXIT

blob_ready=0
capture_mode="gpu-surface-readback"
capture_source="${RGBA8_BLOB}"
capture_delay_frames_used="${CAPTURE_DELAY_FRAMES}"

start_app "${CAPTURE_DELAY_FRAMES}"
if wait_for_blob "${RUN_TIMEOUT_SECONDS}"; then
  blob_ready=1
fi

if [[ "${blob_ready}" -eq 0 && "${CAPTURE_DELAY_FRAMES}" != "${CAPTURE_RETRY_DELAY_FRAMES}" && "${CAPTURE_DISABLE_RETRY}" != "1" ]]; then
  echo "[capture] gpu blob unavailable within ${RUN_TIMEOUT_SECONDS}s (delay=${CAPTURE_DELAY_FRAMES}); retry in fresh process with delay=${CAPTURE_RETRY_DELAY_FRAMES}" >&2
  stop_app
  rm -f "${OUTPUT_PNG}" "${RGBA8_BLOB}" "${META_JSON}"
  MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES="${CAPTURE_RETRY_DELAY_FRAMES}" \
    MGSTUDIO_PARITY_RUN_TIMEOUT_SECONDS="${CAPTURE_RETRY_TIMEOUT_SECONDS}" \
    MGSTUDIO_PARITY_CAPTURE_DISABLE_RETRY=1 \
    "${BASH_SOURCE[0]}" "${PACKAGE}" "${OUTPUT_PNG}"
  exit $?
fi

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
  sleep "${SETTLE_SECONDS}"
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
  "capture_delay_frames_used": ${capture_delay_frames_used},
  "capture_retry_delay_frames": ${CAPTURE_RETRY_DELAY_FRAMES},
  "capture_retry_timeout_seconds": ${CAPTURE_RETRY_TIMEOUT_SECONDS},
  "capture_mode": "${capture_mode}",
  "capture_source": "${capture_source}",
  "rgba8_blob": "${RGBA8_BLOB}"
}
EOF

echo "[capture] done: ${OUTPUT_PNG}"
