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
BEVY_DIR="${REPO_DIR}/bevy"
DEST_DIR="${ENGINE_DIR}/assets/shaders"
copied_count=0

if [[ ! -d "${BEVY_DIR}/crates" ]]; then
  echo "[sync-bevy-shaders] missing bevy crates directory: ${BEVY_DIR}/crates" >&2
  exit 2
fi

mkdir -p "${DEST_DIR}"

clear_synced_dirs() {
  while IFS= read -r crate_dir; do
    local crate
    crate="$(basename "${crate_dir}")"
    if [[ -d "${crate_dir}/src" ]] &&
      find "${crate_dir}/src" -type f -name '*.wgsl' | read -r _; then
      rm -rf "${DEST_DIR}/${crate}"
    fi
  done < <(find "${BEVY_DIR}/crates" -mindepth 1 -maxdepth 1 -type d | sort)
  rm -rf "${DEST_DIR}/bevy_feathers"
}

copy_crate_wgsl() {
  local source="$1"
  local trimmed="${source#${BEVY_DIR}/crates/}"
  local crate="${trimmed%%/*}"
  local src_prefix="${crate}/src/"
  if [[ "${trimmed}" != ${src_prefix}* ]]; then
    return 0
  fi
  local rel="${trimmed#${src_prefix}}"
  local target="${DEST_DIR}/${crate}/${rel}"
  mkdir -p "$(dirname "${target}")"
  cp "${source}" "${target}"
  copied_count=$((copied_count + 1))
}

copy_bevy_feathers_assets() {
  local source="$1"
  local rel="${source#${BEVY_DIR}/crates/bevy_feathers/}"
  local target="${DEST_DIR}/bevy_feathers/${rel}"
  mkdir -p "$(dirname "${target}")"
  cp "${source}" "${target}"
  copied_count=$((copied_count + 1))
}

clear_synced_dirs

while IFS= read -r src; do
  copy_crate_wgsl "${src}"
done < <(find "${BEVY_DIR}/crates" -type f -path '*/src/*.wgsl' | sort)

if [[ -d "${BEVY_DIR}/crates/bevy_feathers/assets/shaders" ]]; then
  while IFS= read -r src; do
    copy_bevy_feathers_assets "${src}"
  done < <(find "${BEVY_DIR}/crates/bevy_feathers/assets/shaders" -type f -name '*.wgsl' | sort)
fi

echo "[sync-bevy-shaders] synchronized ${copied_count} files into ${DEST_DIR}"
