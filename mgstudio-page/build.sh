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

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

TARGET=${TARGET:-wasm}

ENGINE_DIR="$REPO_DIR/mgstudio-engine"
RUNTIME_WEB_DIR="$REPO_DIR/mgstudio-runtime/web"

DIST_DIR="$SCRIPT_DIR/dist"

fn_title_case() {
  printf '%s' "$1" | tr '_' ' ' | awk '{
    for (i = 1; i <= NF; i++) {
      $i = toupper(substr($i, 1, 1)) substr($i, 2)
    }
    print
  }'
}

generate_examples_menu() {
  local dist_dir="$1"
  local menu_html="$2"
  local current_group=""
  local found=0

  while IFS= read -r wasm_rel; do
    found=1
    local path_no_prefix="${wasm_rel#examples/}"
    local group="${path_no_prefix%%/*}"
    local example_name
    example_name="$(basename "$wasm_rel" .wasm)"
    local group_label
    group_label="$(fn_title_case "$group")"
    local example_label
    example_label="$(fn_title_case "$example_name")"

    if [[ "$group" != "$current_group" ]]; then
      if [[ -n "$current_group" ]]; then
        printf '%s\n' "      </div>" "    </section>" >> "$menu_html"
      fi
      printf '%s\n' \
        "    <section class=\"example-group\">" \
        "      <h2>${group_label}</h2>" \
        "      <div class=\"example-buttons\">" >> "$menu_html"
      current_group="$group"
    fi

    printf '        <button type="button" data-wasm="./%s">%s</button>\n' \
      "$wasm_rel" \
      "$example_label" >> "$menu_html"
  done < <(find "$dist_dir/examples" -name '*.wasm' -print | sed "s|$dist_dir/||" | sort)

  if [[ "$found" -eq 0 ]]; then
    echo "No built wasm examples found under $dist_dir/examples" >&2
    exit 1
  fi

  printf '%s\n' "      </div>" "    </section>" >> "$menu_html"
  printf '%s\n' \
    "    <section class=\"example-group\">" \
    "      <h2>Actions</h2>" \
    "      <div class=\"example-buttons\">" \
    "        <button type=\"button\" data-action=\"reload\">Reload</button>" \
    "      </div>" \
    "    </section>" >> "$menu_html"
}

echo "Building engine examples..."
while IFS= read -r pkg; do
  pkg_dir=$(dirname "$pkg")
  moon -C "$ENGINE_DIR" build --release --target "$TARGET" "$pkg_dir"
done < <(find "$ENGINE_DIR/examples" -name moon.pkg -print | sort)

echo "Building web runtime JS bundle..."
moon -C "$RUNTIME_WEB_DIR" build --release --target js

RUNTIME_BUNDLE="$RUNTIME_WEB_DIR/_build/js/release/build/mgstudio-runtime-web.js"
if [[ ! -f "$RUNTIME_BUNDLE" ]]; then
  echo "Runtime JS bundle not found at $RUNTIME_BUNDLE" >&2
  exit 1
fi

EXAMPLES_DIR="$ENGINE_DIR/_build/$TARGET/release/build/examples"
if [[ ! -d "$EXAMPLES_DIR" ]]; then
  echo "Examples output directory not found at $EXAMPLES_DIR" >&2
  exit 1
fi

ASSETS_DIR="$ENGINE_DIR/assets"
if [[ ! -d "$ASSETS_DIR" ]]; then
  echo "Engine assets directory not found at $ASSETS_DIR" >&2
  exit 1
fi

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

cp "$RUNTIME_BUNDLE" "$DIST_DIR/mgstudio-runtime-web.js"

echo "Copying examples into page dist..."
rsync -a --delete "$EXAMPLES_DIR/" "$DIST_DIR/examples/"

echo "Copying assets into page dist..."
rsync -a --delete "$ASSETS_DIR/" "$DIST_DIR/assets/"

echo "Generating examples menu..."
MENU_HTML=$(mktemp)
INDEX_OUT=$(mktemp)
generate_examples_menu "$DIST_DIR" "$MENU_HTML"
awk -v menu_file="$MENU_HTML" '
  /__EXAMPLE_GROUPS__/ {
    while ((getline line < menu_file) > 0) {
      print line
    }
    close(menu_file)
    next
  }
  { print }
' "$SCRIPT_DIR/index.html" > "$INDEX_OUT"
mv "$INDEX_OUT" "$DIST_DIR/index.html"
rm -f "$MENU_HTML"

echo "Built: $DIST_DIR"
