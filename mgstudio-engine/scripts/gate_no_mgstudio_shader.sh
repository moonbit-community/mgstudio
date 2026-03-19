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
REPO_DIR="$(cd "${ENGINE_DIR}/.." && pwd)"

MGSTUDIO_SHADER_DIR="${ENGINE_DIR}/assets/shaders/mgstudio"
if [[ -d "${MGSTUDIO_SHADER_DIR}" ]]; then
  count="$(find "${MGSTUDIO_SHADER_DIR}" -type f -name '*.wgsl' | wc -l | tr -d ' ')"
  if [[ "${count}" != "0" ]]; then
    echo "[no-mgstudio-shader-gate] forbidden shader directory still exists: ${MGSTUDIO_SHADER_DIR} (${count} files)" >&2
    find "${MGSTUDIO_SHADER_DIR}" -type f -name '*.wgsl' | sort >&2
    exit 1
  fi
fi

MGSTUDIO_RUNTIME_SHADER_DIR="${ENGINE_DIR}/assets/shaders/mgstudio_runtime"
if [[ -d "${MGSTUDIO_RUNTIME_SHADER_DIR}" ]]; then
  count="$(find "${MGSTUDIO_RUNTIME_SHADER_DIR}" -type f -name '*.wgsl' | wc -l | tr -d ' ')"
  if [[ "${count}" != "0" ]]; then
    echo "[no-mgstudio-shader-gate] forbidden transitional shader directory still exists: ${MGSTUDIO_RUNTIME_SHADER_DIR} (${count} files)" >&2
    find "${MGSTUDIO_RUNTIME_SHADER_DIR}" -type f -name '*.wgsl' | sort >&2
    exit 1
  fi
fi

set +e
refs="$(rg -n --hidden --glob '!**/_build/**' --glob '!**/.mooncakes/**' --glob '!**/scripts/gate_no_mgstudio_shader.sh' 'shaders/mgstudio/|shaders/mgstudio_runtime/' "${ENGINE_DIR}" "${REPO_DIR}/.github" 2>/dev/null)"
rc=$?
set -e

if [[ ${rc} -eq 0 && -n "${refs}" ]]; then
  echo "[no-mgstudio-shader-gate] forbidden reference(s) to legacy mgstudio shader paths found:" >&2
  printf '%s\n' "${refs}" >&2
  exit 1
fi

echo "[no-mgstudio-shader-gate] pass"
