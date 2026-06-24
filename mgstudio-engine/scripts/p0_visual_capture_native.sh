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
FINAL_OUTPUT_PNG="$2"
PACKAGE_BASENAME="$(basename "${PACKAGE}")"
CALLER_DIR="$(pwd)"
RUN_TIMEOUT_SECONDS="${MGSTUDIO_PARITY_RUN_TIMEOUT_SECONDS:-60}"
CAPTURE_DELAY_FRAMES="${MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES:-120}"
CAPTURE_RETRY_DELAY_FRAMES="${MGSTUDIO_PARITY_CAPTURE_RETRY_DELAY_FRAMES:-1}"
CAPTURE_RETRY_TIMEOUT_SECONDS="${MGSTUDIO_PARITY_CAPTURE_RETRY_TIMEOUT_SECONDS:-60}"
CAPTURE_DISABLE_RETRY="${MGSTUDIO_PARITY_CAPTURE_DISABLE_RETRY:-0}"
DISABLE_GPU_PREPROCESS="${MGSTUDIO_PARITY_DISABLE_GPU_PREPROCESS:-1}"
STOP_GRACE_SECONDS="${MGSTUDIO_PARITY_STOP_GRACE_SECONDS:-3}"
FORCE_KILL_AFTER_GRACE="${MGSTUDIO_PARITY_FORCE_KILL_AFTER_GRACE:-1}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENGINE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"
APP_EXE="${ENGINE_DIR}/_build/native/release/build/${PACKAGE}/${PACKAGE_BASENAME}.exe"

case "${FINAL_OUTPUT_PNG}" in
  /*) ;;
  *) FINAL_OUTPUT_PNG="${CALLER_DIR}/${FINAL_OUTPUT_PNG}" ;;
esac

mkdir -p "$(dirname "${FINAL_OUTPUT_PNG}")"
OUTPUT_PNG="${FINAL_OUTPUT_PNG%.png}.tmp.$$.png"
RUN_LOG="${FINAL_OUTPUT_PNG%.png}.run.log"
META_JSON="${FINAL_OUTPUT_PNG%.png}.meta.json"
RGBA8_BLOB="${FINAL_OUTPUT_PNG%.png}.rgba8.blob"

echo "[capture] moon run --build-only --target native --release ${PACKAGE}"
moon -C "${ENGINE_DIR}" run --build-only --target native --release "${PACKAGE}"
if [[ ! -x "${APP_EXE}" ]]; then
  echo "[capture] built executable missing: ${APP_EXE}" >&2
  exit 6
fi

rm -f "${OUTPUT_PNG}" "${RGBA8_BLOB}"

APP_PID=""
capture_png_ready=0

start_app() {
  local delay_frames="$1"
  local screenshot_frame="$delay_frames"
  if [[ "${screenshot_frame}" -le 0 ]]; then
    screenshot_frame=1
  fi
  rm -f "${RGBA8_BLOB}"
  : >"${RUN_LOG}"
  echo "[capture] native exe ${PACKAGE} (delay_frames=${delay_frames})"
  (
    cd "${ENGINE_DIR}"
    export MGSTUDIO_PARITY_CAPTURE_RGBA8_BLOB="${RGBA8_BLOB}"
    export MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES="${delay_frames}"
    export MGSTUDIO_SCREENSHOT_PATH="${OUTPUT_PNG}"
    export MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE=1
    export MGSTUDIO_SCREENSHOT_FRAME="${screenshot_frame}"
    export MGSTUDIO_RENDER3D_DISABLE_GPU_PREPROCESS="${DISABLE_GPU_PREPROCESS}"
    exec "${APP_EXE}" >"${RUN_LOG}" 2>&1
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

wait_for_capture() {
  local timeout_seconds="$1"
  local elapsed_local=0
  while [[ "${elapsed_local}" -lt "${timeout_seconds}" ]]; do
    if [[ -s "${RGBA8_BLOB}" ]]; then
      return 0
    fi
    if [[ -s "${OUTPUT_PNG}" ]]; then
      capture_png_ready=1
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
        if [[ -s "${OUTPUT_PNG}" ]]; then
          capture_png_ready=1
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
  rm -f "${OUTPUT_PNG}"
}
trap cleanup EXIT

blob_ready=0
capture_mode="gpu-surface-readback"
capture_source="${RGBA8_BLOB}"
capture_delay_frames_used="${CAPTURE_DELAY_FRAMES}"

start_app "${CAPTURE_DELAY_FRAMES}"
if wait_for_capture "${RUN_TIMEOUT_SECONDS}"; then
  blob_ready=1
fi

if [[ "${blob_ready}" -eq 0 && "${CAPTURE_DELAY_FRAMES}" != "${CAPTURE_RETRY_DELAY_FRAMES}" && "${CAPTURE_DISABLE_RETRY}" != "1" ]]; then
  echo "[capture] gpu blob unavailable within ${RUN_TIMEOUT_SECONDS}s (delay=${CAPTURE_DELAY_FRAMES}); retry in fresh process with delay=${CAPTURE_RETRY_DELAY_FRAMES}" >&2
  stop_app
  rm -f "${OUTPUT_PNG}" "${RGBA8_BLOB}" "${META_JSON}"
  MGSTUDIO_PARITY_CAPTURE_DELAY_FRAMES="${CAPTURE_RETRY_DELAY_FRAMES}" \
    MGSTUDIO_PARITY_RUN_TIMEOUT_SECONDS="${CAPTURE_RETRY_TIMEOUT_SECONDS}" \
    MGSTUDIO_PARITY_CAPTURE_DISABLE_RETRY=1 \
    "${BASH_SOURCE[0]}" "${PACKAGE}" "${FINAL_OUTPUT_PNG}"
  exit $?
fi

if [[ "${blob_ready}" -eq 1 ]]; then
  if [[ "${capture_png_ready}" -eq 1 && ! -s "${RGBA8_BLOB}" ]]; then
    capture_mode="window-screenshot-png"
    capture_source="${FINAL_OUTPUT_PNG}"
  elif ! command -v python3 >/dev/null 2>&1; then
    echo "[capture] python3 missing; cannot decode engine-native rgba8 blob" >&2
    exit 3
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
png.extend(chunk(b"sRGB", b"\x00"))
png.extend(chunk(b"IDAT", compressed))
png.extend(chunk(b"IEND", b""))
png_path.write_bytes(bytes(png))
PY
    convert_rc=$?
    set -e
    if [[ "${convert_rc}" -ne 0 || ! -s "${OUTPUT_PNG}" ]]; then
      echo "[capture] failed to decode engine-native rgba8 blob" >&2
      rm -f "${OUTPUT_PNG}"
      exit 4
    fi
  fi
fi

if [[ "${blob_ready}" -eq 0 ]]; then
  echo "[capture] engine-native rgba8 blob unavailable for ${PACKAGE}" >&2
  echo "[capture] run log: ${RUN_LOG}" >&2
  exit 5
fi

if [[ ! -s "${OUTPUT_PNG}" ]]; then
  echo "[capture] output image missing or empty: ${FINAL_OUTPUT_PNG}" >&2
  exit 5
fi

mv -f "${OUTPUT_PNG}" "${FINAL_OUTPUT_PNG}"

cat >"${META_JSON}" <<EOF
{
  "package": "${PACKAGE}",
  "output_png": "${FINAL_OUTPUT_PNG}",
  "run_log": "${RUN_LOG}",
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

echo "[capture] done: ${FINAL_OUTPUT_PNG}"
