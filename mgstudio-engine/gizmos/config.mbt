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
// Bevy source: `bevy/crates/bevy_gizmos/src/config.rs`.

///|
pub fn default_gizmo_config() -> @sprite.GizmoConfig {
  @sprite.GizmoConfig::default()
}

///|
pub fn default_gizmo_line_config() -> @sprite.GizmoLineConfig {
  @sprite.GizmoLineConfig::default()
}

///|
pub fn default_gizmo_config_group() -> @sprite.DefaultGizmoConfigGroup {
  @sprite.DefaultGizmoConfigGroup::default()
}

///|
pub fn[G : @sprite.GizmoConfigGroup] gizmo_config_store_config(
  store : @sprite.GizmoConfigStore,
  group : G,
) -> (@sprite.GizmoConfig, G) {
  store.config(group)
}

///|
pub fn[G : @sprite.GizmoConfigGroup] gizmo_config_store_get_config(
  store : @sprite.GizmoConfigStore,
  group : G,
) -> (@sprite.GizmoConfig, G)? {
  store.get_config(group)
}

///|
pub fn[G : @sprite.GizmoConfigGroup] gizmo_config_store_config_mut(
  store : @sprite.GizmoConfigStore,
  group : G,
) -> (Ref[@sprite.GizmoConfig], Ref[G]) {
  store.config_mut(group)
}

///|
pub fn[G : @sprite.GizmoConfigGroup] gizmo_config_store_get_config_mut(
  store : @sprite.GizmoConfigStore,
  group : G,
) -> (Ref[@sprite.GizmoConfig], Ref[G])? {
  store.get_config_mut(group)
}

///|
pub struct GizmoMeshConfig {
  line_perspective : Bool
  line_style : @sprite.GizmoLineStyle
  line_joints : @sprite.GizmoLineJoint
  render_layers : @sprite.RenderLayers
  handle : @asset.Handle[GizmoAsset]
}

///|
pub fn GizmoMeshConfig::new(
  line_perspective~ : Bool,
  line_style~ : @sprite.GizmoLineStyle,
  line_joints~ : @sprite.GizmoLineJoint,
  render_layers~ : @sprite.RenderLayers,
  handle~ : @asset.Handle[GizmoAsset],
) -> GizmoMeshConfig {
  GizmoMeshConfig::{
    line_perspective,
    line_style,
    line_joints,
    render_layers,
    handle,
  }
}

///|
pub fn GizmoMeshConfig::line_perspective(self : GizmoMeshConfig) -> Bool {
  self.line_perspective
}

///|
pub fn GizmoMeshConfig::line_style(
  self : GizmoMeshConfig,
) -> @sprite.GizmoLineStyle {
  self.line_style
}

///|
pub fn GizmoMeshConfig::line_joints(
  self : GizmoMeshConfig,
) -> @sprite.GizmoLineJoint {
  self.line_joints
}

///|
pub fn GizmoMeshConfig::render_layers(
  self : GizmoMeshConfig,
) -> @sprite.RenderLayers {
  self.render_layers
}

///|
pub fn GizmoMeshConfig::handle(
  self : GizmoMeshConfig,
) -> @asset.Handle[GizmoAsset] {
  self.handle
}

///|
pub let ecs_key_gizmo_mesh_config : @ecs.ComponentKey[GizmoMeshConfig] = @ecs.register_component(
  debug_name="mgstudio_gizmos::GizmoMeshConfig",
)

///|
pub impl @ecs.Component for GizmoMeshConfig with component() {
  ecs_key_gizmo_mesh_config
}
