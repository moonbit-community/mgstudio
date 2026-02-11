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

TARGET=${TARGET:-js}

ENGINE_DIR="$REPO_DIR/mgstudio-engine"
WEB_PLATFORM_DIR="${MGSTUDIO_PLATFORM_WEB_MODULE:-$REPO_DIR/mgstudio-platform-web}"
LAUNCHER_ROOT="$SCRIPT_DIR/.tmp/page-launcher"

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

  while IFS= read -r game_rel; do
    found=1
    local path_no_prefix="${game_rel#examples/}"
    local group="${path_no_prefix%%/*}"
    local example_name
    example_name="$(basename "$game_rel" .js)"
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

    printf '        <button type="button" data-game="./%s">%s</button>\n' \
      "$game_rel" \
      "$example_label" >> "$menu_html"
  done < <(find "$dist_dir/examples" -name '*.js' -print | sed "s|$dist_dir/||" | sort)

  if [[ "$found" -eq 0 ]]; then
    echo "No built js examples found under $dist_dir/examples" >&2
    exit 1
  fi

  printf '%s\n' "      </div>" "    </section>" >> "$menu_html"
}

write_launcher_module() {
  rm -rf "$LAUNCHER_ROOT"
  mkdir -p "$LAUNCHER_ROOT/launchers"
  cat > "$LAUNCHER_ROOT/moon.mod.json" <<EOF
{
  "name": "mgstudio/page-launchers",
  "version": "0.1.0",
  "deps": {
    "Milky2018/mgstudio": { "path": "$ENGINE_DIR" },
    "Milky2018/mgstudio-platform-web": { "path": "$WEB_PLATFORM_DIR" }
  },
  "readme": "README.mbt.md",
  "license": "Apache-2.0",
  "keywords": [],
  "description": "",
  "preferred-target": "js"
}
EOF
  cat > "$LAUNCHER_ROOT/README.mbt.md" <<EOF
# mgstudio page launchers
EOF
}

launcher_name_for_pkg() {
  local pkg_rel="$1"
  printf '%s' "$pkg_rel" | tr '/.-' '___'
}

build_example_launcher() {
  local pkg_rel="$1"
  local entry_import="Milky2018/mgstudio/$pkg_rel"
  local launcher_name
  launcher_name="$(launcher_name_for_pkg "$pkg_rel")"
  local launcher_pkg_dir="$LAUNCHER_ROOT/launchers/$launcher_name"
  mkdir -p "$launcher_pkg_dir"
  cat > "$launcher_pkg_dir/moon.pkg" <<EOF
import {
  "$entry_import" @game,
  "Milky2018/mgstudio/platform" @platform,
}

options(
  "is-main": true,
  overrides: [ "Milky2018/mgstudio-platform-web/platform_web" ],
)
EOF
  cat > "$launcher_pkg_dir/main.mbt" <<EOF
fn main {
  @platform.run_after_ready(fn() {
    @game.game_main()
  })
}
EOF

  moon -C "$LAUNCHER_ROOT" build --release --target "$TARGET" "launchers/$launcher_name"
  local built_js="$LAUNCHER_ROOT/_build/$TARGET/release/build/launchers/$launcher_name/$launcher_name.js"
  if [[ ! -f "$built_js" ]]; then
    echo "Built launcher output not found: $built_js" >&2
    exit 1
  fi
  local dst_js="$DIST_DIR/examples/${pkg_rel}.js"
  mkdir -p "$(dirname "$dst_js")"
  cp "$built_js" "$dst_js"
}

if [[ "$TARGET" != "js" ]]; then
  echo "mgstudio-page/build.sh supports TARGET=js only (got: $TARGET)" >&2
  exit 1
fi

if [[ ! -f "$WEB_PLATFORM_DIR/moon.mod.json" ]]; then
  echo "Web platform module not found: $WEB_PLATFORM_DIR/moon.mod.json" >&2
  exit 1
fi

ASSETS_DIR="$ENGINE_DIR/assets"
if [[ ! -d "$ASSETS_DIR" ]]; then
  echo "Engine assets directory not found at $ASSETS_DIR" >&2
  exit 1
fi

echo "Building engine examples (web launchers)..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/examples"
write_launcher_module
while IFS= read -r pkg; do
  pkg_dir=$(dirname "$pkg")
  pkg_rel="${pkg_dir#"$ENGINE_DIR/"}"
  build_example_launcher "$pkg_rel"
done < <(find "$ENGINE_DIR/examples" -name moon.pkg -print | sort)

rm -rf "$LAUNCHER_ROOT"
rmdir "$SCRIPT_DIR/.tmp" 2>/dev/null || true

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
