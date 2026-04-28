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
test "blit: embedded wgsl source is registered by blit owner" {
  register_embedded_wgsl_sources()
  let source = match
    @wgsl.registered_wgsl_source("core_pipeline/blit/blit.wgsl") {
    Some(source) => source
    None => ""
  }
  debug_inspect(source != "", content="true")
  debug_inspect(
    source.contains(
      "#import bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput",
    ),
    content="true",
  )
  debug_inspect(
    source.contains("fn fs_main(in: FullscreenVertexOutput)"),
    content="true",
  )
}
