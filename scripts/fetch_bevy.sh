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
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BEVY_DIR="${REPO_DIR}/bevy"
BEVY_REMOTE_URL="https://github.com/bevyengine/bevy.git"
BEVY_BASELINE_COMMIT="48ec375a3a3cdc904476ef1d13f9d71c9f2820d3"

if [[ -e "${BEVY_DIR}" ]] && [[ ! -d "${BEVY_DIR}/.git" ]]; then
  echo "[fetch-bevy] existing path is not a git checkout: ${BEVY_DIR}" >&2
  exit 1
fi

mkdir -p "${BEVY_DIR}"

if [[ ! -d "${BEVY_DIR}/.git" ]]; then
  git init "${BEVY_DIR}" >/dev/null
fi

if git -C "${BEVY_DIR}" remote get-url origin >/dev/null 2>&1; then
  git -C "${BEVY_DIR}" remote set-url origin "${BEVY_REMOTE_URL}"
else
  git -C "${BEVY_DIR}" remote add origin "${BEVY_REMOTE_URL}"
fi

if git -C "${BEVY_DIR}" rev-parse --verify HEAD >/dev/null 2>&1; then
  current_commit="$(git -C "${BEVY_DIR}" rev-parse HEAD)"
  if [[ "${current_commit}" == "${BEVY_BASELINE_COMMIT}" ]]; then
    echo "[fetch-bevy] bevy already at baseline ${BEVY_BASELINE_COMMIT}"
    exit 0
  fi

  if [[ -n "$(git -C "${BEVY_DIR}" status --short)" ]]; then
    echo "[fetch-bevy] local bevy checkout is dirty; refusing to reset ${BEVY_DIR}" >&2
    exit 1
  fi
fi

git -C "${BEVY_DIR}" fetch --depth 1 origin "${BEVY_BASELINE_COMMIT}"
git -C "${BEVY_DIR}" checkout --detach FETCH_HEAD >/dev/null

resolved_commit="$(git -C "${BEVY_DIR}" rev-parse HEAD)"
if [[ "${resolved_commit}" != "${BEVY_BASELINE_COMMIT}" ]]; then
  echo "[fetch-bevy] expected ${BEVY_BASELINE_COMMIT}, got ${resolved_commit}" >&2
  exit 1
fi

echo "[fetch-bevy] ready: ${resolved_commit}"
