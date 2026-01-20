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
ROOT_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)

moon build --release --target wasm-gc -C "$ROOT_DIR" examples/runner

WASM_PATH="$ROOT_DIR/_build/wasm-gc/release/build/examples/runner/runner.wasm"
if [[ ! -f "$WASM_PATH" ]]; then
  echo "runner.wasm not found at $WASM_PATH" >&2
  exit 1
fi

cp "$WASM_PATH" "$SCRIPT_DIR/runner.wasm"
echo "Copied runner.wasm to $SCRIPT_DIR/runner.wasm"

ASSETS_DIR="$ROOT_DIR/assets"
if [[ -d "$ASSETS_DIR" ]]; then
  rm -rf "$SCRIPT_DIR/assets"
  cp -R "$ASSETS_DIR" "$SCRIPT_DIR/"
  echo "Copied assets to $SCRIPT_DIR/assets"
fi
