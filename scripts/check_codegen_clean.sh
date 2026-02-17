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
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENGINE_DIR="${REPO_DIR}/mgstudio-engine"
CLI_BIN="${REPO_DIR}/mgstudio-cli/_build/native/release/build/main/main.exe"

build_log="$(mktemp)"
check_log="$(mktemp)"
cleanup() {
  rm -f "${build_log}" "${check_log}"
}
trap cleanup EXIT

if ! moon -C "${REPO_DIR}/mgstudio-cli" build --release >"${build_log}" 2>&1; then
  cat "${build_log}"
  echo "[codegen-check] failed to build mgstudio-cli." >&2
  exit 1
fi

pushd "${ENGINE_DIR}" >/dev/null
if ! "${CLI_BIN}" gen --check >"${check_log}" 2>&1; then
  popd >/dev/null
  cat "${check_log}"
  echo "[codegen-check] mgstudio gen --check failed." >&2
  exit 1
fi
popd >/dev/null

if [[ -s "${check_log}" ]]; then
  cat "${check_log}"
  echo "[codegen-check] mgstudio gen --check must be silent when repository is up to date." >&2
  exit 1
fi
