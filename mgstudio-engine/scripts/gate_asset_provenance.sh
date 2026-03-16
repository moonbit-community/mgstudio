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

forbidden='(bevy/assets|\.\./bevy/assets|/bevy/assets|\.\./third_party|/third_party/|\.mooncakes/)'

set +e
hits="$(rg -n --hidden -e "${forbidden}" "${ENGINE_DIR}/examples" -g '*.mbt' -g '*.moon' -g '*.json' 2>/dev/null)"
rc=$?
set -e

if [[ ${rc} -eq 0 && -n "${hits}" ]]; then
  echo "[asset-provenance-gate] forbidden external asset provenance found in examples:" >&2
  printf '%s\n' "${hits}" >&2
  exit 1
fi

echo "[asset-provenance-gate] pass"
