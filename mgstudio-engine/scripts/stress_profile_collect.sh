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

DEFAULT_CASES=(
  "bevymark"
  "bevymark_3d"
  "many_animated_sprite_meshes"
  "many_animated_sprites"
  "many_buttons"
  "many_cameras_lights"
  "many_components"
  "many_cubes"
  "many_foxes"
  "many_gizmos"
  "many_glyphs"
  "many_gradients"
  "many_lights"
  "many_materials"
  "many_sprite_meshes"
  "many_sprites"
  "many_text2d"
  "text_pipeline"
  "transform_hierarchy"
)

OUT_DIR_DEFAULT="/tmp/mgstudio_stress_profile_$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${1:-${OUT_DIR_DEFAULT}}"
SAMPLE_SECONDS="${MGSTUDIO_STRESS_SAMPLE_SECONDS:-12}"
WARMUP_SECONDS="${MGSTUDIO_STRESS_WARMUP_SECONDS:-3}"
TIMEOUT_SECONDS="${MGSTUDIO_STRESS_TIMEOUT_SECONDS:-$((SAMPLE_SECONDS + WARMUP_SECONDS + 15))}"
BUILD_RELEASE="${MGSTUDIO_STRESS_BUILD_RELEASE:-1}"
FAIL_ON_MISSING_DIAGNOSTIC="${MGSTUDIO_STRESS_FAIL_ON_MISSING_DIAGNOSTIC:-0}"

declare -a CASES=()
if [[ -n "${MGSTUDIO_STRESS_CASES:-}" ]]; then
  IFS=',' read -r -a CASES <<<"${MGSTUDIO_STRESS_CASES}"
else
  CASES=("${DEFAULT_CASES[@]}")
fi

mkdir -p "${OUT_DIR}/logs"
RESULT_TSV="${OUT_DIR}/results.tsv"
SUMMARY_MD="${OUT_DIR}/summary.md"

if [[ "${BUILD_RELEASE}" == "1" ]]; then
  for case_name in "${CASES[@]}"; do
    echo "[stress-collect] build examples/stress_tests/${case_name}"
    moon -C "${ENGINE_DIR}" build --target native --release "examples/stress_tests/${case_name}"
  done
fi

{
  printf "case\tfps_avg\tframe_time_avg_ms\tframe_count\tstatus\tlog\n"
} >"${RESULT_TSV}"

missing_count=0
for case_name in "${CASES[@]}"; do
  pkg="examples/stress_tests/${case_name}"
  exe="${ENGINE_DIR}/_build/native/release/build/examples/stress_tests/${case_name}/${case_name}.exe"
  log="${OUT_DIR}/logs/${case_name}.log"

  if [[ ! -x "${exe}" ]]; then
    printf "%s\t\t\t\tmissing-binary\t%s\n" "${case_name}" "${log}" >>"${RESULT_TSV}"
    missing_count=$((missing_count + 1))
    continue
  fi

  echo "[stress-collect] run ${pkg}"
  (
    cd "${ENGINE_DIR}" &&
      timeout "${TIMEOUT_SECONDS}" stdbuf -oL -eL "${exe}"
  ) >"${log}" 2>&1 || true

  fps_line="$(rg "\\[INFO\\] \\[bevy_diagnostic\\] fps:" "${log}" | tail -n 1 || true)"
  frame_line="$(rg "\\[INFO\\] \\[bevy_diagnostic\\] frame_time:" "${log}" | tail -n 1 || true)"
  count_line="$(rg "\\[INFO\\] \\[bevy_diagnostic\\] frame_count:" "${log}" | tail -n 1 || true)"

  fps_avg="$(echo "${fps_line}" | rg -o "avg [0-9.]+" | awk '{print $2}' || true)"
  frame_time_avg="$(echo "${frame_line}" | rg -o "avg [0-9.]+" | awk '{print $2}' || true)"
  frame_count="$(echo "${count_line}" | rg -o "frame_count: [0-9]+" | awk '{print $2}' || true)"

  status="ok"
  if [[ -z "${fps_avg}" || -z "${frame_time_avg}" ]]; then
    status="no-diagnostic"
    missing_count=$((missing_count + 1))
  fi
  if [[ -z "${frame_count}" ]]; then
    frame_count="0"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
    "${case_name}" "${fps_avg}" "${frame_time_avg}" "${frame_count}" "${status}" "${log}" >>"${RESULT_TSV}"
done

python3 - "${RESULT_TSV}" "${SUMMARY_MD}" "${OUT_DIR}" "${SAMPLE_SECONDS}" "${WARMUP_SECONDS}" "${TIMEOUT_SECONDS}" <<'PY'
import csv
import pathlib
import sys

tsv_path = pathlib.Path(sys.argv[1])
summary_path = pathlib.Path(sys.argv[2])
out_dir = pathlib.Path(sys.argv[3])
sample_s = sys.argv[4]
warmup_s = sys.argv[5]
timeout_s = sys.argv[6]

rows = []
with tsv_path.open("r", encoding="utf-8") as fp:
    reader = csv.DictReader(fp, delimiter="\t")
    rows = list(reader)

lines = [
    "# Stress Profile Summary",
    "",
    f"- out_dir: `{out_dir}`",
    f"- warmup_seconds: `{warmup_s}`",
    f"- sample_seconds: `{sample_s}`",
    f"- timeout_seconds: `{timeout_s}`",
    "",
    "| case | fps_avg | frame_time_avg_ms | frame_count | status |",
    "| --- | ---: | ---: | ---: | --- |",
]
for row in rows:
    lines.append(
        f"| {row['case']} | {row['fps_avg'] or '-'} | "
        f"{row['frame_time_avg_ms'] or '-'} | {row['frame_count'] or '-'} | {row['status']} |"
    )
summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY

cat "${SUMMARY_MD}"
echo "[stress-collect] results: ${RESULT_TSV}"

if [[ "${FAIL_ON_MISSING_DIAGNOSTIC}" == "1" && "${missing_count}" -ne 0 ]]; then
  echo "[stress-collect] missing diagnostics detected: ${missing_count}" >&2
  exit 1
fi
