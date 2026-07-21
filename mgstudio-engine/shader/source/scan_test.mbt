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
test "shader source: 0.17 filesystem adapter preserves scan behavior" {
  let files = try! scan_shader_source_files("shader/source", {
    ..ShaderSourceScanOptions::default(),
    recursive: false,
    extensions: ["mbt"],
  })
  let paths = files.map(fn(file) { file.rel_path })
  assert_true(paths.contains("lib.mbt"))
  assert_true(paths.contains("scan.mbt"))
}
