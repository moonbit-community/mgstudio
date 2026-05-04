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
fn effect_stack_wgsl_registered(path : String) -> Bool {
  @shader_source.embedded_shader_source(path) is Some(_)
}

///|
fn effect_stack_wgsl_source(path : String) -> String {
  match @shader_source.embedded_shader_source(path) {
    Some(source) => source
    None => ""
  }
}

///|
test "effect_stack: embedded wgsl sources are registered by effect stack owner" {
  register_embedded_wgsl_sources()
  debug_inspect(
    effect_stack_wgsl_registered(
      "post_process/effect_stack/chromatic_aberration.wgsl",
    ),
    content="true",
  )
  debug_inspect(
    effect_stack_wgsl_registered("post_process/effect_stack/post_process.wgsl"),
    content="true",
  )
  debug_inspect(
    effect_stack_wgsl_registered("post_process/effect_stack/vignette.wgsl"),
    content="true",
  )
  let chromatic = effect_stack_wgsl_source(
    "post_process/effect_stack/chromatic_aberration.wgsl",
  )
  debug_inspect(chromatic.contains("fn chromatic_aberration("), content="true")
  let vignette = effect_stack_wgsl_source(
    "post_process/effect_stack/vignette.wgsl",
  )
  debug_inspect(vignette.contains("fn vignette("), content="true")
  let stack = effect_stack_wgsl_source(
    "post_process/effect_stack/post_process.wgsl",
  )
  debug_inspect(
    stack.contains(
      "#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput",
    ),
    content="true",
  )
}
