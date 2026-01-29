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
REPO_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
ENGINE_DIR="$REPO_DIR/mgstudio-engine"
TARGET=${TARGET:-wasm-gc}
RUNTIME_DIR="$SCRIPT_DIR"
RUNTIME_BUNDLE="$RUNTIME_DIR/_build/js/release/build/mgstudio-runtime-web.js"
WEB_BUNDLE="$SCRIPT_DIR/mgstudio-runtime-web.js"

# Build engine examples (each example is its own package / wasm).
for pkg in "$ENGINE_DIR/examples/2d"/*; do
  if [[ -f "$pkg/moon.pkg.json" ]]; then
    moon build --release --target "$TARGET" -C "$ENGINE_DIR" "$pkg"
  fi
done
moon build --release --target js -C "$RUNTIME_DIR"

if [[ ! -f "$RUNTIME_BUNDLE" ]]; then
  echo "Runtime JS bundle not found at $RUNTIME_BUNDLE" >&2
  exit 1
fi

cp "$RUNTIME_BUNDLE" "$WEB_BUNDLE"
echo "Copied runtime JS bundle to $WEB_BUNDLE"

echo "Engine examples built under: $ENGINE_DIR/_build/$TARGET/release/build/examples"

ASSETS_DIR="$ENGINE_DIR/assets"
if [[ -d "$ASSETS_DIR" ]]; then
  mkdir -p "$SCRIPT_DIR/assets"
  # Keep runtime-specific assets (e.g. web shaders, folder manifests) intact.
  # Sync engine assets into the web assets folder, but do not overwrite shaders.
  rsync -a --exclude "shaders/" "$ASSETS_DIR/" "$SCRIPT_DIR/assets/"
  echo "Synced engine assets to $SCRIPT_DIR/assets (excluding shaders)"
fi
