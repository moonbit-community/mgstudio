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
// Bevy source: `bevy/crates/bevy_gizmos/src/retained.rs`.

///|
pub struct GizmoAsset {
  buffer : @sprite.GizmoState
  config_type_name : String
}

///|
fn empty_gizmo_state() -> @sprite.GizmoState {
  @sprite.GizmoState::{
    lines: [],
    lines_3d: [],
    pending_ellipses: [],
    pending_arcs: [],
    pending_rounded_rects: [],
    pending_arrows: [],
    pending_grids: [],
    mesh_handle_3d: None,
  }
}

///|
pub fn GizmoAsset::new() -> GizmoAsset {
  GizmoAsset::{
    buffer: empty_gizmo_state(),
    config_type_name: @any.of(@sprite.DefaultGizmoConfigGroup::default()).type_name(),
  }
}

///|
pub fn GizmoAsset::buffer(self : GizmoAsset) -> @sprite.GizmoState {
  self.buffer
}

///|
pub fn GizmoAsset::config_type_name(self : GizmoAsset) -> String {
  self.config_type_name
}

///|
pub impl Default for GizmoAsset with default() {
  GizmoAsset::new()
}

///|
let ecs_key_gizmo : @ecs.ComponentKey[Gizmo] = @ecs.register_component(
  debug_name="mgstudio_gizmos::Gizmo",
)

///|
pub struct Gizmo {
  handle : @asset.Handle[GizmoAsset]
  line_config : GizmoLineConfig
  depth_bias : Float
}

///|
pub fn Gizmo::default() -> Gizmo {
  Gizmo::{
    handle: @asset.Handle::new(0),
    line_config: GizmoLineConfig::default(),
    depth_bias: 0.0F,
  }
}

///|
pub impl Default for Gizmo with default() {
  Gizmo::default()
}

///|
pub impl @ecs.Component for Gizmo with component() {
  ecs_key_gizmo
}

///|
pub fn install_retained_gizmo_required_components(world : @ecs.World) -> Unit {
  world.register_required_components(
    ecs_key_gizmo,
    @transform.Transform::component(),
  ) catch {
    _ => ()
  }
}
