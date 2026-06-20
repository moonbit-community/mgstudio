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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/lib.rs`.
// Mirrors `embedded_asset!(app, "lines.wgsl")` and
// `embedded_asset!(app, "line_joints.wgsl")`.

///|
pub fn register_embedded_wgsl_sources() -> Unit {
  @shader_source.load_embedded_shader_source(
    "gizmos_render/lines.wgsl", line_gizmo_lines_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "gizmos_render/lines.wgsl",
    @asset.asset_text_to_bytes(line_gizmo_lines_wgsl_source),
  )
  @shader_source.load_embedded_shader_source(
    "gizmos_render/line_joints.wgsl", line_gizmo_joints_wgsl_source,
  )
  @asset.register_embedded_asset_virtual_bytes(
    "gizmos_render/line_joints.wgsl",
    @asset.asset_text_to_bytes(line_gizmo_joints_wgsl_source),
  )
}
