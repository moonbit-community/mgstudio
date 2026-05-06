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

// Bevy source: `bevy/crates/bevy_pbr/src/render/mesh_view_bindings.rs`.

///|
pub struct MeshViewBindings3d {
  viewport : (Int, Int, Int, Int)?
  clear_enabled : Bool
  logical_rect : (Float, Float, Float, Float)
  view_matrix : ProjectionMatrix3d
  layout_key : @mesh_view_layout.MeshPipelineViewLayoutKey
}

///|
pub fn MeshViewBindings3d::default() -> MeshViewBindings3d {
  MeshViewBindings3d::{
    viewport: None,
    clear_enabled: true,
    logical_rect: (0.0F, 0.0F, 1.0F, 1.0F),
    view_matrix: ProjectionMatrix3d::from_cols(
      @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
      @math.Vec4::new(0.0F, 0.0F, 0.0F, 1.0F),
    ),
    layout_key: @mesh_view_layout.MeshPipelineViewLayoutKey::default(),
  }
}

///|
pub fn render3d_mesh_view_bindings(
  target_info : RenderTargetComputed3d,
  camera_transform : @transform.Transform,
) -> MeshViewBindings3d {
  let logical_rect = (
    0.0F,
    0.0F,
    Float::from_int(target_info.target_size.x),
    Float::from_int(target_info.target_size.y),
  )
  let viewport = render3d_pass_viewport_for_target(
    target_info.target_id,
    target_info.target_id,
    0,
    0,
    target_info.target_size.x,
    target_info.target_size.y,
  )
  let clear_enabled = render3d_pass_clear_enabled_for_target(
      [],
      target_info.target_id,
      true,
    ) ==
    1
  MeshViewBindings3d::{
    viewport: Some(viewport),
    clear_enabled,
    logical_rect,
    view_matrix: render3d_view_from_world_matrix(camera_transform),
    layout_key: @mesh_view_layout.mesh_view_layout_key_from_msaa(1),
  }
}
