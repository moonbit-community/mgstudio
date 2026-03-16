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
ENGINE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"

CAPTURE_SCRIPT="${SCRIPT_DIR}/p0_visual_capture_native.sh"
COMPARE_SCRIPT="${SCRIPT_DIR}/p0_visual_compare.py"

BASELINE_DIR="${MGSTUDIO_PARITY_BASELINE_DIR:-${REPO_DIR}/.private/parity/baselines/bevy_p0_blockers}"
ARTIFACT_ROOT_DEFAULT="${REPO_DIR}/.private/parity/artifacts/p0_visual_gate/$(date +%Y%m%d_%H%M%S)"
ARTIFACT_DIR="${MGSTUDIO_PARITY_ARTIFACT_DIR:-${ARTIFACT_ROOT_DEFAULT}}"
MAX_MEAN_ABS="${MGSTUDIO_PARITY_MAX_MEAN_ABS:-6.0}"
MAX_CHANGED_RATIO="${MGSTUDIO_PARITY_MAX_CHANGED_RATIO:-0.08}"
PIXEL_DELTA="${MGSTUDIO_PARITY_PIXEL_DELTA:-10}"

mkdir -p "${ARTIFACT_DIR}"

declare -a CASES=(
  "3d_scene:examples/3d/3d_scene"
  "3d_shapes:examples/3d/3d_shapes"
)

failures=0
SUMMARY_MD="${ARTIFACT_DIR}/summary.md"
{
  echo "# P0 Visual Gate Summary"
  echo
  echo "- baseline_dir: \`${BASELINE_DIR}\`"
  echo "- artifact_dir: \`${ARTIFACT_DIR}\`"
  echo "- max_mean_abs: \`${MAX_MEAN_ABS}\`"
  echo "- max_changed_ratio: \`${MAX_CHANGED_RATIO}\`"
  echo "- pixel_delta: \`${PIXEL_DELTA}\`"
  echo
  echo "| case | package | status | report |"
  echo "| --- | --- | --- | --- |"
} >"${SUMMARY_MD}"

for entry in "${CASES[@]}"; do
  case_name="${entry%%:*}"
  package_name="${entry#*:}"
  baseline_png="${BASELINE_DIR}/${case_name}.png"
  actual_png="${ARTIFACT_DIR}/${case_name}.png"
  report_json="${ARTIFACT_DIR}/${case_name}.json"

  if [[ ! -f "${baseline_png}" ]]; then
    echo "[gate] missing baseline: ${baseline_png}" >&2
    echo "| ${case_name} | \`${package_name}\` | ❌ missing-baseline | n/a |" >>"${SUMMARY_MD}"
    failures=$((failures + 1))
    continue
  fi

  set +e
  "${CAPTURE_SCRIPT}" "${package_name}" "${actual_png}"
  capture_rc=$?
  set -e
  if [[ "${capture_rc}" -ne 0 ]]; then
    echo "[gate] capture failed for ${case_name} (rc=${capture_rc})" >&2
    echo "| ${case_name} | \`${package_name}\` | ❌ capture-failed(${capture_rc}) | n/a |" >>"${SUMMARY_MD}"
    failures=$((failures + 1))
    continue
  fi

  set +e
  python3 "${COMPARE_SCRIPT}" \
    --baseline "${baseline_png}" \
    --actual "${actual_png}" \
    --report "${report_json}" \
    --pixel-delta-threshold "${PIXEL_DELTA}" \
    --max-mean-abs "${MAX_MEAN_ABS}" \
    --max-changed-ratio "${MAX_CHANGED_RATIO}"
  compare_rc=$?
  set -e

  if [[ "${compare_rc}" -eq 0 ]]; then
    echo "| ${case_name} | \`${package_name}\` | ✅ pass | \`${report_json}\` |" >>"${SUMMARY_MD}"
  else
    echo "[gate] compare failed for ${case_name} (rc=${compare_rc})" >&2
    echo "| ${case_name} | \`${package_name}\` | ❌ compare-failed(${compare_rc}) | \`${report_json}\` |" >>"${SUMMARY_MD}"
    failures=$((failures + 1))
  fi
done

echo
cat "${SUMMARY_MD}"

if [[ "${failures}" -ne 0 ]]; then
  echo "[gate] failed with ${failures} case(s)." >&2
  exit 1
fi

echo "[gate] all cases passed."
