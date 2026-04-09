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

// Bevy-aligned render module anchor.

///|
pub struct MeshViewBindings3d {
  viewport : @render.HostMesh3dViewport?
  clear_enabled : Bool
  logical_rect : @math.Vec4
  view_matrix : @math.Mat4
}

///|
pub fn MeshViewBindings3d::default() -> MeshViewBindings3d {
  MeshViewBindings3d::{
    viewport: None,
    clear_enabled: true,
    logical_rect: @math.Vec4::new(0.0F, 0.0F, 1.0F, 1.0F),
    view_matrix: @math.Mat4::identity(),
  }
}

///|
pub fn render3d_mesh_view_bindings(
  target_info : RenderTargetInfo3d,
  camera_transform : @transform.Transform,
) -> MeshViewBindings3d {
  let logical_rect = match render3d_camera_viewport_rect_logical(target_info) {
    Some(value) => value
    None =>
      @math.Vec4::new(
        0.0F,
        0.0F,
        target_info.width.to_float(),
        target_info.height.to_float(),
      )
  }
  MeshViewBindings3d::{
    viewport: render3d_pass_viewport_for_target(target_info),
    clear_enabled: render3d_pass_clear_enabled_for_target(target_info),
    logical_rect,
    view_matrix: render3d_view_from_world_matrix(
      camera_transform.compute_matrix(),
    ),
  }
}
