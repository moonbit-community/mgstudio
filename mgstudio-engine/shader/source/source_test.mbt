// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
test "embedded shader source is read from embedded asset bytes" {
  clear_embedded_shader_sources()
  load_embedded_shader_source("shader/source/test.wgsl", "fn old() {}")
  @embedded_asset.register_embedded_asset_virtual_bytes(
    "shader/source/test.wgsl",
    @embedded_asset.asset_text_to_bytes("fn new() {}"),
  )

  debug_inspect(
    embedded_shader_source_required("shader/source/test.wgsl"),
    content="\"fn new() {}\"",
  )
  let files = embedded_shader_source_files()
  debug_inspect(files.length(), content="1")
  debug_inspect(files[0].source, content="\"fn new() {}\"")
}

///|
test "embedded shader source clear removes only persistent source handles" {
  clear_embedded_shader_sources()
  load_embedded_shader_source("shader/source/clear.wgsl", "fn keep_asset() {}")
  clear_embedded_shader_sources()

  debug_inspect(embedded_shader_source_files().length(), content="0")
  debug_inspect(
    embedded_shader_source("shader/source/clear.wgsl"),
    content="Some(\"fn keep_asset() {}\")",
  )
}
