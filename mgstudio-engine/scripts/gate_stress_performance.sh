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

BASELINE_TSV="${MGSTUDIO_STRESS_BASELINE_TSV:-${SCRIPT_DIR}/stress_perf_baseline.tsv}"
OUT_DIR_DEFAULT="/tmp/mgstudio_stress_gate_$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${MGSTUDIO_STRESS_GATE_OUT_DIR:-${OUT_DIR_DEFAULT}}"
RESULT_TSV="${OUT_DIR}/results.tsv"
REPORT_MD="${OUT_DIR}/report.md"

if [[ ! -f "${BASELINE_TSV}" ]]; then
  echo "[stress-gate] baseline file not found: ${BASELINE_TSV}" >&2
  exit 2
fi

mkdir -p "${OUT_DIR}"

if [[ ! -f "${RESULT_TSV}" ]]; then
  CASES="$(tail -n +2 "${BASELINE_TSV}" | awk -F'\t' '{print $1}' | paste -sd, -)"
  MGSTUDIO_STRESS_CASES="${CASES}" \
    MGSTUDIO_STRESS_FAIL_ON_MISSING_DIAGNOSTIC=1 \
    "${SCRIPT_DIR}/stress_profile_collect.sh" "${OUT_DIR}"
fi

python3 - "${BASELINE_TSV}" "${RESULT_TSV}" "${REPORT_MD}" <<'PY'
import csv
import pathlib
import sys

baseline_path = pathlib.Path(sys.argv[1])
result_path = pathlib.Path(sys.argv[2])
report_path = pathlib.Path(sys.argv[3])

baseline = {}
with baseline_path.open("r", encoding="utf-8") as fp:
    reader = csv.DictReader(fp, delimiter="\t")
    for row in reader:
        baseline[row["case"]] = row

results = {}
with result_path.open("r", encoding="utf-8") as fp:
    reader = csv.DictReader(fp, delimiter="\t")
    for row in reader:
        results[row["case"]] = row

failed = []
lines = [
    "# Stress Performance Gate Report",
    "",
    f"- baseline: `{baseline_path}`",
    f"- results: `{result_path}`",
    "",
    "| case | status | fps_avg | min_fps_avg | frame_time_avg_ms | max_frame_time_avg_ms |",
    "| --- | --- | ---: | ---: | ---: | ---: |",
]

for case_name, base in baseline.items():
    row = results.get(case_name)
    if row is None:
        failed.append((case_name, "missing-result"))
        lines.append(
            f"| {case_name} | missing-result | - | {base['min_fps_avg']} | - | {base['max_frame_time_avg_ms']} |"
        )
        continue

    status = row.get("status", "")
    fps_text = row.get("fps_avg", "")
    ft_text = row.get("frame_time_avg_ms", "")
    min_fps = float(base["min_fps_avg"])
    max_ft = float(base["max_frame_time_avg_ms"])
    ok = status == "ok"
    fps_val = None
    ft_val = None
    try:
        fps_val = float(fps_text) if fps_text else None
    except Exception:
        fps_val = None
    try:
        ft_val = float(ft_text) if ft_text else None
    except Exception:
        ft_val = None
    if fps_val is None or fps_val < min_fps:
        ok = False
    if ft_val is None or ft_val > max_ft:
        ok = False
    verdict = "pass" if ok else "fail"
    if not ok:
        failed.append((case_name, f"status={status},fps={fps_text},ft={ft_text}"))
    lines.append(
        f"| {case_name} | {verdict} | {fps_text or '-'} | {min_fps:.2f} | {ft_text or '-'} | {max_ft:.2f} |"
    )

report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(report_path)
if failed:
    print("FAILED_CASES")
    for case_name, reason in failed:
        print(f"{case_name}\t{reason}")
    raise SystemExit(1)
PY

cat "${REPORT_MD}"
echo "[stress-gate] pass"
