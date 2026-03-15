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
SANITY_SCRIPT="${SCRIPT_DIR}/visual_image_sanity.py"

ARTIFACT_ROOT_DEFAULT="${REPO_DIR}/docs/parity/artifacts/3d_examples_gate/$(date +%Y%m%d_%H%M%S)"
ARTIFACT_DIR="${MGSTUDIO_PARITY_ARTIFACT_DIR:-${ARTIFACT_ROOT_DEFAULT}}"
FILTER_REGEX="${MGSTUDIO_3D_EXAMPLES_FILTER:-}"
MAX_CASES="${MGSTUDIO_3D_EXAMPLES_MAX_CASES:-0}"
BLACK_THRESHOLD="${MGSTUDIO_PARITY_BLACK_THRESHOLD:-8}"
MIN_NON_BLACK_RATIO="${MGSTUDIO_PARITY_MIN_NON_BLACK_RATIO:-0.01}"
MIN_MEAN_LUMA="${MGSTUDIO_PARITY_MIN_MEAN_LUMA:-4.0}"
MIN_CENTER_MEAN_LUMA="${MGSTUDIO_PARITY_MIN_CENTER_MEAN_LUMA:-3.0}"
REQUIRE_SANITY="${MGSTUDIO_PARITY_REQUIRE_SANITY:-0}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[gate-3d] python3 is required" >&2
  exit 2
fi

if [[ ! -x "${CAPTURE_SCRIPT}" ]]; then
  echo "[gate-3d] capture script missing or not executable: ${CAPTURE_SCRIPT}" >&2
  exit 2
fi

if [[ ! -f "${SANITY_SCRIPT}" ]]; then
  echo "[gate-3d] sanity script missing: ${SANITY_SCRIPT}" >&2
  exit 2
fi

sanity_available=1
set +e
python3 - <<'PY' >/dev/null 2>&1
import PIL  # noqa: F401
PY
sanity_import_rc=$?
set -e
if [[ "${sanity_import_rc}" -ne 0 ]]; then
  sanity_available=0
  if [[ "${REQUIRE_SANITY}" == "1" ]]; then
    echo "[gate-3d] Pillow unavailable but sanity is required (MGSTUDIO_PARITY_REQUIRE_SANITY=1)." >&2
    exit 2
  fi
  echo "[gate-3d] warning: Pillow unavailable, image sanity checks will be skipped." >&2
fi

mkdir -p "${ARTIFACT_DIR}"
SUMMARY_MD="${ARTIFACT_DIR}/summary.md"
MANIFEST_JSON="${ARTIFACT_DIR}/manifest.json"
TMP_RESULTS_JSONL="${ARTIFACT_DIR}/results.jsonl"
: >"${TMP_RESULTS_JSONL}"

{
  echo "# 3D Examples Screenshot Gate"
  echo
  echo "- artifact_dir: \`${ARTIFACT_DIR}\`"
  echo "- filter_regex: \`${FILTER_REGEX:-<none>}\`"
  echo "- max_cases: \`${MAX_CASES}\`"
  echo "- black_threshold: \`${BLACK_THRESHOLD}\`"
  echo "- min_non_black_ratio: \`${MIN_NON_BLACK_RATIO}\`"
  echo "- min_mean_luma: \`${MIN_MEAN_LUMA}\`"
  echo "- min_center_mean_luma: \`${MIN_CENTER_MEAN_LUMA}\`"
  echo "- sanity_enabled: \`$([[ ${sanity_available} -eq 1 ]] && echo yes || echo no)\`"
  echo
  echo "| case | package | capture | sanity | runtime log | status |"
  echo "| --- | --- | --- | --- | --- | --- |"
} >"${SUMMARY_MD}"

declare -a CASES=()
for example_dir in "${ENGINE_DIR}/examples/3d"/*; do
  [[ -d "${example_dir}" ]] || continue
  [[ -f "${example_dir}/main.mbt" ]] || continue
  example_name="$(basename "${example_dir}")"
  if [[ -n "${FILTER_REGEX}" ]] && ! [[ "${example_name}" =~ ${FILTER_REGEX} ]]; then
    continue
  fi
  CASES+=("${example_name}")
done

if [[ "${#CASES[@]}" -eq 0 ]]; then
  echo "[gate-3d] no examples selected under examples/3d" >&2
  exit 2
fi

if [[ "${MAX_CASES}" =~ ^[0-9]+$ ]] && [[ "${MAX_CASES}" -gt 0 ]] && [[ "${#CASES[@]}" -gt "${MAX_CASES}" ]]; then
  CASES=("${CASES[@]:0:${MAX_CASES}}")
fi

failures=0
total="${#CASES[@]}"
index=0

for case_name in "${CASES[@]}"; do
  index=$((index + 1))
  package_name="examples/3d/${case_name}"
  png_path="${ARTIFACT_DIR}/${case_name}.png"
  sanity_json="${ARTIFACT_DIR}/${case_name}.sanity.json"
  log_path="${ARTIFACT_DIR}/${case_name}.run.log"
  runtime_issue="no"
  capture_status="ok"
  sanity_status="ok"
  status="pass"

  echo "[gate-3d] (${index}/${total}) ${package_name}"

  set +e
  "${CAPTURE_SCRIPT}" "${package_name}" "${png_path}"
  capture_rc=$?
  set -e

  if [[ "${capture_rc}" -ne 0 ]]; then
    capture_status="fail(${capture_rc})"
    sanity_status="skip"
    runtime_issue="skip"
    status="fail"
    failures=$((failures + 1))
  else
    capture_log_path="${png_path%.png}.run.log"
    if [[ -f "${capture_log_path}" ]]; then
      if [[ "${capture_log_path}" != "${log_path}" ]]; then
        cp "${capture_log_path}" "${log_path}"
      fi
    fi
    if [[ "${sanity_available}" -eq 1 ]]; then
      set +e
      python3 "${SANITY_SCRIPT}" \
        --image "${png_path}" \
        --report "${sanity_json}" \
        --black-threshold "${BLACK_THRESHOLD}" \
        --min-non-black-ratio "${MIN_NON_BLACK_RATIO}" \
        --min-mean-luma "${MIN_MEAN_LUMA}" \
        --min-center-mean-luma "${MIN_CENTER_MEAN_LUMA}" >/dev/null
      sanity_rc=$?
      set -e
      if [[ "${sanity_rc}" -ne 0 ]]; then
        sanity_status="fail(${sanity_rc})"
        status="fail"
        failures=$((failures + 1))
      fi
    else
      sanity_status="skip(no-pillow)"
    fi

    if [[ -f "${log_path}" ]] && rg -n "RUNTIME ERROR|invalid memory access|panic|abort trap|segmentation fault" "${log_path}" >/dev/null; then
      runtime_issue="yes"
      status="fail"
      failures=$((failures + 1))
    fi
  fi

  {
    echo "| ${case_name} | \`${package_name}\` | ${capture_status} | ${sanity_status} | ${runtime_issue} | ${status} |"
  } >>"${SUMMARY_MD}"

  python3 - "$TMP_RESULTS_JSONL" "$case_name" "$package_name" "$capture_status" "$sanity_status" "$runtime_issue" "$status" "$png_path" "$sanity_json" "$log_path" <<'PY'
import json
import pathlib
import sys

out_path = pathlib.Path(sys.argv[1])
record = {
    "case": sys.argv[2],
    "package": sys.argv[3],
    "capture": sys.argv[4],
    "sanity": sys.argv[5],
    "runtime_issue": sys.argv[6],
    "status": sys.argv[7],
    "png": sys.argv[8],
    "sanity_report": sys.argv[9],
    "run_log": sys.argv[10],
}
with out_path.open("a", encoding="utf-8") as fp:
    fp.write(json.dumps(record, ensure_ascii=False) + "\n")
PY
done

python3 - "$TMP_RESULTS_JSONL" "$MANIFEST_JSON" <<'PY'
import json
import pathlib
import sys

jsonl = pathlib.Path(sys.argv[1])
out = pathlib.Path(sys.argv[2])
records = []
if jsonl.is_file():
    for line in jsonl.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        records.append(json.loads(line))
out.write_text(json.dumps({"results": records}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
PY

echo
cat "${SUMMARY_MD}"
echo
echo "[gate-3d] manifest: ${MANIFEST_JSON}"

if [[ "${failures}" -ne 0 ]]; then
  echo "[gate-3d] failed with ${failures} issue(s)." >&2
  exit 1
fi

echo "[gate-3d] all selected 3D examples passed."
