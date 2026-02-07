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

echo "Building engine examples..."
while IFS= read -r pkg; do
  pkg_dir=$(dirname "$pkg")
  moon build --release --target "$TARGET" -C "$ENGINE_DIR" "$pkg_dir"
done < <(find "$ENGINE_DIR/examples" -name moon.pkg.json -print | sort)

echo "Building web runtime JS bundle..."
moon build --release --target js -C "$RUNTIME_WEB_DIR"

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

cp "$SCRIPT_DIR/index.html" "$DIST_DIR/index.html"
cp "$RUNTIME_BUNDLE" "$DIST_DIR/mgstudio-runtime-web.js"

echo "Copying examples into page dist..."
rsync -a --delete "$EXAMPLES_DIR/" "$DIST_DIR/examples/"

echo "Copying assets into page dist..."
rsync -a --delete "$ASSETS_DIR/" "$DIST_DIR/assets/"

echo "Built: $DIST_DIR"
