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

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

INCLUDE_TARGET="${INCLUDE_TARGET:-0}"
INCLUDE_NON_GOAL="${INCLUDE_NON_GOAL:-0}"
INCLUDE_EXCLUDED="${INCLUDE_EXCLUDED:-0}"

ARGS=(
  --scope=all
  --examples-strict
  --sync
  --json
)

if [[ "$INCLUDE_TARGET" == "1" ]]; then
  ARGS+=(--include-target)
fi

if [[ "$INCLUDE_NON_GOAL" == "1" ]]; then
  ARGS+=(--include-non-goal)
fi

if [[ "$INCLUDE_EXCLUDED" == "1" ]]; then
  ARGS+=(--include-excluded)
fi

node scripts/bevy_rs_to_mbt_paths.mjs "${ARGS[@]}"
