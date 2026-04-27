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

OUT_DIR_DEFAULT="/tmp/mgstudio_many_foxes_profile_$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${1:-${MGSTUDIO_MANY_FOXES_PROFILE_OUT_DIR:-${OUT_DIR_DEFAULT}}}"
RUN_SECONDS="${MGSTUDIO_MANY_FOXES_PROFILE_SECONDS:-35}"
START_TIMEOUT_SECONDS="${MGSTUDIO_MANY_FOXES_START_TIMEOUT_SECONDS:-180}"
TRACE_FLUSH_FRAMES="${MGSTUDIO_MANY_FOXES_TRACE_FLUSH_FRAMES:-120}"
TRACE_CATEGORIES="${MGSTUDIO_MANY_FOXES_TRACE_CATEGORIES:-stage,system,render_queue,render_pass}"
STARTUP_FRAMES="${MGSTUDIO_MANY_FOXES_STARTUP_FRAMES:-10}"
SPIKE_MS="${MGSTUDIO_MANY_FOXES_SPIKE_MS:-200}"
TOP_N="${MGSTUDIO_MANY_FOXES_TOP_N:-30}"
EXTRA_ARGS="${MGSTUDIO_MANY_FOXES_ARGS:-}"

mkdir -p "${OUT_DIR}"

TRACE="${OUT_DIR}/many_foxes.trace.json"
LOG="${OUT_DIR}/many_foxes.log"
REPORT="${OUT_DIR}/frametime_breakdown.md"
CSV="${OUT_DIR}/frametime_breakdown.csv"

echo "[many-foxes-profile] out_dir: ${OUT_DIR}"
echo "[many-foxes-profile] build examples/stress_tests/many_foxes"
moon -C "${ENGINE_DIR}" build --target native --release examples/stress_tests/many_foxes

rm -f "${TRACE}" "${LOG}"
preexisting_pids="$(pgrep -x many_foxes.exe || true)"
echo "[many-foxes-profile] run moon run examples/stress_tests/many_foxes --release"
(
  cd "${ENGINE_DIR}"
  # Use moon run, not the built binary, so the command path matches normal example
  # execution and cannot accidentally profile a stale executable.
  env \
    MGSTUDIO_TIMELINE_TRACE=1 \
    MGSTUDIO_TIMELINE_TRACE_OUTPUT="${TRACE}" \
    MGSTUDIO_TIMELINE_TRACE_FLUSH_FRAMES="${TRACE_FLUSH_FRAMES}" \
    MGSTUDIO_TIMELINE_TRACE_CATEGORIES="${TRACE_CATEGORIES}" \
    moon run examples/stress_tests/many_foxes --release ${EXTRA_ARGS}
) >"${LOG}" 2>&1 &
runner_pid="$!"

example_pid=""
start_deadline=$((SECONDS + START_TIMEOUT_SECONDS))
while [[ "${SECONDS}" -lt "${start_deadline}" ]]; do
  while read -r candidate_pid; do
    if [[ -z "${candidate_pid}" ]]; then
      continue
    fi
    if ! grep -qx "${candidate_pid}" <<<"${preexisting_pids}"; then
      example_pid="${candidate_pid}"
      break
    fi
  done < <(pgrep -x many_foxes.exe || true)
  if [[ -n "${example_pid}" ]]; then
    break
  fi
  if ! kill -0 "${runner_pid}" 2>/dev/null; then
    break
  fi
  sleep 0.5
done

if [[ -z "${example_pid}" ]]; then
  wait "${runner_pid}" || true
  echo "[many-foxes-profile] example process did not start within ${START_TIMEOUT_SECONDS}s" >&2
  echo "[many-foxes-profile] log: ${LOG}" >&2
  exit 1
fi

echo "[many-foxes-profile] example pid: ${example_pid}; sampling for ${RUN_SECONDS}s"
sleep "${RUN_SECONDS}"
while read -r pid; do
  if [[ -n "${pid}" ]]; then
    kill "${pid}" 2>/dev/null || true
  fi
done < <(pgrep -x many_foxes.exe || true)
wait "${runner_pid}" || true

if [[ ! -f "${TRACE}" ]]; then
  echo "[many-foxes-profile] trace not produced: ${TRACE}" >&2
  echo "[many-foxes-profile] log: ${LOG}" >&2
  exit 1
fi

python3 "${SCRIPT_DIR}/analyze_timeline_trace.py" \
  "${TRACE}" \
  --log "${LOG}" \
  --out-md "${REPORT}" \
  --out-csv "${CSV}" \
  --startup-frames "${STARTUP_FRAMES}" \
  --spike-ms "${SPIKE_MS}" \
  --top "${TOP_N}" \
  --title "many_foxes Frame Time Breakdown"

cat "${REPORT}"
echo "[many-foxes-profile] report: ${REPORT}"
echo "[many-foxes-profile] csv: ${CSV}"
echo "[many-foxes-profile] log: ${LOG}"
echo "[many-foxes-profile] trace: ${TRACE}"
