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
DIST_DIR="${SCRIPT_DIR}/dist"

fn_title_case() {
  printf '%s' "$1" | tr '_' ' ' | awk '{
    for (i = 1; i <= NF; i++) {
      $i = toupper(substr($i, 1, 1)) substr($i, 2)
    }
    print
  }'
}

generate_example_cards() {
  local engine_dir="$1"
  local out_file="$2"

  find "${engine_dir}/examples" -mindepth 2 -maxdepth 2 -type d | sort | while read -r dir; do
    local pkg_rel="${dir#${engine_dir}/}"
    local group name title group_label
    group="$(basename "$(dirname "${pkg_rel}")")"
    name="$(basename "${pkg_rel}")"
    title="$(fn_title_case "${name}")"
    group_label="$(fn_title_case "${group}")"

    {
      echo '        <article class="example-card">'
      echo "          <h3>${title}</h3>"
      echo "          <p class=\"example-meta\">group: ${group_label}</p>"
      echo "          <code>moon -C mgstudio-engine run --target native ${pkg_rel}</code>"
      echo '        </article>'
    } >> "${out_file}"
  done
}

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

CARDS_HTML="$(mktemp)"
INDEX_OUT="$(mktemp)"

generate_example_cards "${ENGINE_DIR}" "${CARDS_HTML}"

awk -v cards_file="${CARDS_HTML}" '
  /__EXAMPLE_CARDS__/ {
    while ((getline line < cards_file) > 0) {
      print line
    }
    close(cards_file)
    next
  }
  { print }
' "${SCRIPT_DIR}/index.html" > "${INDEX_OUT}"

cp "${INDEX_OUT}" "${DIST_DIR}/index.html"
rm -f "${CARDS_HTML}" "${INDEX_OUT}"

echo "Built docs-only page: ${DIST_DIR}"
