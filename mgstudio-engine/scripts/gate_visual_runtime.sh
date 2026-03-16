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

if [[ "${MGSTUDIO_PARITY_SKIP_VISUAL:-0}" == "1" ]]; then
  echo "[visual-runtime-gate] skipped by MGSTUDIO_PARITY_SKIP_VISUAL=1"
  exit 0
fi

export MGSTUDIO_3D_EXAMPLES_FILTER="${MGSTUDIO_3D_EXAMPLES_FILTER:-^(3d_shapes|pbr|3d_scene)$}"
export MGSTUDIO_3D_EXAMPLES_MAX_CASES="${MGSTUDIO_3D_EXAMPLES_MAX_CASES:-3}"
export MGSTUDIO_WINDOW_FRAME_LIMIT="${MGSTUDIO_WINDOW_FRAME_LIMIT:-120}"

"${SCRIPT_DIR}/gate_3d_examples_screenshots.sh"
