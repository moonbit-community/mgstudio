// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/fullscreen_vertex_shader/mod.rs`.
// Fullscreen shader descriptor owner.

///|
pub const FULLSCREEN_SHADER_PATH : String = "core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl"

///|
pub const FULLSCREEN_SHADER_ENTRY_POINT : String = "vertex"

///|
pub struct FullscreenShader {
  path : String
  entry_point : String
}

///|
pub fn FullscreenShader::default() -> FullscreenShader {
  FullscreenShader::{
    path: FULLSCREEN_SHADER_PATH,
    entry_point: FULLSCREEN_SHADER_ENTRY_POINT,
  }
}

///|
pub fn FullscreenShader::new(
  path? : String = FULLSCREEN_SHADER_PATH,
  entry_point? : String = FULLSCREEN_SHADER_ENTRY_POINT,
) -> FullscreenShader {
  FullscreenShader::{ path, entry_point }
}

///|
pub let ecs_key_fullscreen_shader : @ecs.ResourceKey[FullscreenShader] = @ecs.register_resource(
  debug_name="mgstudio_core_pipeline::fullscreen_vertex_shader::FullscreenShader",
)

///|
pub impl @app.Resource for FullscreenShader with resource() {
  ecs_key_fullscreen_shader
}
