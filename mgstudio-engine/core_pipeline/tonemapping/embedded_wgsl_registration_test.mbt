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
fn tonemapping_wgsl_registered(path : String) -> Bool {
  @shader_source.embedded_shader_source(path) is Some(_)
}

///|
fn tonemapping_wgsl_source(path : String) -> String {
  match @shader_source.embedded_shader_source(path) {
    Some(source) => source
    None => ""
  }
}

///|
test "tonemapping: embedded wgsl sources are registered by tonemapping owner" {
  register_embedded_wgsl_sources()
  debug_inspect(
    tonemapping_wgsl_registered("core_pipeline/tonemapping/tonemapping.wgsl"),
    content="true",
  )
  debug_inspect(
    tonemapping_wgsl_registered(
      "core_pipeline/tonemapping/tonemapping_shared.wgsl",
    ),
    content="true",
  )
  debug_inspect(
    tonemapping_wgsl_registered("core_pipeline/tonemapping/lut_bindings.wgsl"),
    content="true",
  )
  let source = tonemapping_wgsl_source(
    "core_pipeline/tonemapping/tonemapping_shared.wgsl",
  )
  debug_inspect(source.contains("fn tonemapping_luminance("), content="true")
  debug_inspect(
    source.contains("fn sample_tony_mc_mapface_lut("),
    content="true",
  )
  debug_inspect(
    source.contains("#define_import_path bevy_core_pipeline::tonemapping"),
    content="true",
  )
}
