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
// Bevy source: `bevy/crates/bevy_pbr/src/lib.rs::PbrPlugin::build`.

///|
const PBR_DUMMY_MESHLET_VISIBILITY_BUFFER_RESOLVE_SHADER_PATH : String = "pbr/meshlet/dummy_visibility_buffer_resolve.wgsl"

///|
fn pbr_plugin_register_dummy_meshlet_visibility_buffer_resolve_shader() -> Unit {
  @shader_source.load_embedded_shader_source(
    PBR_DUMMY_MESHLET_VISIBILITY_BUFFER_RESOLVE_SHADER_PATH,
    pbr_dummy_meshlet_visibility_buffer_resolve_wgsl_source,
  )
}
