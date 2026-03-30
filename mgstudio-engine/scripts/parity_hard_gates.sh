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

"${SCRIPT_DIR}/gate_no_mgstudio_shader.sh"
"${SCRIPT_DIR}/gate_asset_provenance.sh"
"${SCRIPT_DIR}/gate_visual_runtime.sh"
if [[ "${MGSTUDIO_PARITY_INCLUDE_STRESS:-0}" == "1" ]]; then
  "${SCRIPT_DIR}/gate_stress_performance.sh"
else
  echo "[parity-hard-gates] skip stress gate (set MGSTUDIO_PARITY_INCLUDE_STRESS=1 to enable)"
fi

echo "[parity-hard-gates] pass"
