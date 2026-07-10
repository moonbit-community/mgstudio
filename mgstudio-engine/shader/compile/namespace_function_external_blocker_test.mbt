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
test "compile external blocker: fully qualified module function call fails IR lowering" {
  clear_registered_shader_sources()
  register_shader_source(
    "shader/compile/fog_blocker.wgsl", "#define_import_path test::fog\nfn linear_fog(value: f32) -> f32 { return value; }\n",
  )
  register_shader_source(
    "shader/compile/fog_blocker_root.wgsl", "#define_import_path test::root\nfn fragment() -> f32 { return test::fog::linear_fog(1.0); }\n",
  )
  let message = try
    load_preprocessed_wgsl(
      "",
      "shader/compile/fog_blocker_root.wgsl",
      @hashmap.HashMap([]),
      default_shader_value_defines(),
    )
  catch {
    err => err.message()
  } noraise {
    _ => ""
  }
  debug_inspect(
    message,
    content="\"invalid WGSL IR pipeline: IR lowering failed: unsupported WGSL type: test::fog::linear_fog\"",
  )
}
