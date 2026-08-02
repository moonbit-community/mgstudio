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
// Bevy gives `GizmoAsset` the `GizmoBuffer` surface through `Deref`/`DerefMut`;
// MoonBit has no `Deref`, so those methods are written as explicit `GizmoAsset`
// delegates next to the `GizmoBuffer` method they forward to, in the same Bevy
// source owner file.

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
pub fn Gizmo::Gizmo() -> Gizmo {
  {
    handle: @asset.Handle::new(0),
    line_config: GizmoLineConfig(),
    depth_bias: 0.0F,
  }
}

///|
pub fn Gizmo::handle(self : Gizmo) -> @asset.Handle[GizmoAsset] {
  self.handle
}

///|
pub fn Gizmo::line_config(self : Gizmo) -> GizmoLineConfig {
  self.line_config
}

///|
pub fn Gizmo::depth_bias(self : Gizmo) -> Float {
  self.depth_bias
}

///|
pub fn Gizmo::with_handle(
  self : Gizmo,
  handle : @asset.Handle[GizmoAsset],
) -> Gizmo {
  { handle, line_config: self.line_config, depth_bias: self.depth_bias }
}

///|
pub fn Gizmo::with_line_config(
  self : Gizmo,
  line_config : GizmoLineConfig,
) -> Gizmo {
  { handle: self.handle, line_config, depth_bias: self.depth_bias }
}

///|
pub fn Gizmo::with_depth_bias(self : Gizmo, depth_bias : Float) -> Gizmo {
  { handle: self.handle, line_config: self.line_config, depth_bias }
}

///|
pub impl Default for Gizmo with fn default() {
  Gizmo()
}

///|
pub impl @ecs.Component for Gizmo with fn component() {
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
