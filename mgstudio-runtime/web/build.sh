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
RUNTIME_DIR="$SCRIPT_DIR"
RUNTIME_BUNDLE="$RUNTIME_DIR/_build/js/release/build/mgstudio-runtime-web.js"
OUT_DIR=${OUT_DIR:-"$SCRIPT_DIR/dist"}
OUT_BUNDLE="$OUT_DIR/mgstudio-runtime-web.js"

moon build --release --target js -C "$RUNTIME_DIR"

if [[ ! -f "$RUNTIME_BUNDLE" ]]; then
  echo "Runtime JS bundle not found at $RUNTIME_BUNDLE" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
cp "$RUNTIME_BUNDLE" "$OUT_BUNDLE"
echo "Copied runtime JS bundle to $OUT_BUNDLE"
