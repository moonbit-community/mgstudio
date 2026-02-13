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

REAL_CC="${MOON_REAL_CC:-${CC:-cc}}"
OS="$(uname -s 2>/dev/null || echo unknown)"

if [[ "$OS" == "Darwin" ]]; then
  exec "$REAL_CC" "$@"
fi

filtered=()
skip_next=0
for arg in "$@"; do
  if [[ $skip_next -eq 1 ]]; then
    skip_next=0
    continue
  fi

  if [[ "$arg" == "-framework" ]]; then
    skip_next=1
    continue
  fi
  if [[ "$arg" == -Wl,-framework,* ]]; then
    continue
  fi

  filtered+=("$arg")
done

exec "$REAL_CC" "${filtered[@]}"
