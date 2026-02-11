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
PORT=${PORT:-8099}

if [[ ! -d "$SCRIPT_DIR/dist" ]]; then
  echo "dist/ not found; run ./build.sh first" >&2
  exit 1
fi

echo "Serving $SCRIPT_DIR/dist at http://localhost:$PORT"
python3 - "$PORT" "$SCRIPT_DIR/dist" <<'PY'
import http.server
import pathlib
import socketserver
import sys

port = int(sys.argv[1])
root = pathlib.Path(sys.argv[2]).resolve()

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(root), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()

with socketserver.TCPServer(("", port), Handler) as httpd:
    httpd.serve_forever()
PY
