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
priv struct Render3dCameraViewportState {
  viewport_x : Int
  viewport_y : Int
  viewport_width : Int
  viewport_height : Int
  viewport_depth_min : Float
  viewport_depth_max : Float
  view_width : Int
  view_height : Int
  view_width_logical : Int
  view_height_logical : Int
}

///|
fn render3d_execute_camera_viewport_state(
  camera : Camera3dViewPayload,
) -> Render3dCameraViewportState? {
  let target_width = camera.target_size.x
  let target_height = camera.target_size.y
  if target_width <= 0 || target_height <= 0 {
    return None
  }
  let mut viewport_x = 0
  let mut viewport_y = 0
  let mut viewport_width = target_width
  let mut viewport_height = target_height
  let mut viewport_depth_min = 0.0F
  let mut viewport_depth_max = 1.0F
  let mut view_width = target_width
  let mut view_height = target_height
  if camera.camera.viewport is Some(viewport) {
    viewport_x = viewport.physical_position.x
    viewport_y = viewport.physical_position.y
    viewport_width = viewport.physical_size.x
    viewport_height = viewport.physical_size.y
    if viewport_width <= 0 || viewport_height <= 0 {
      return None
    }
    viewport_depth_min = viewport.depth_min
    viewport_depth_max = viewport.depth_max
    view_width = viewport_width
    view_height = viewport_height
  }
  // Render target textures and viewport dimensions are in physical pixels.
  // Do not divide by window scale factor here; doing so halves render size on
  // high-DPI displays and breaks camera framing/post-process alignment.
  camera.scale_factor |> ignore
  let view_width_logical = view_width
  let view_height_logical = view_height
  if view_width_logical <= 0 || view_height_logical <= 0 {
    return None
  }
  Some(Render3dCameraViewportState::{
    viewport_x,
    viewport_y,
    viewport_width,
    viewport_height,
    viewport_depth_min,
    viewport_depth_max,
    view_width,
    view_height,
    view_width_logical,
    view_height_logical,
  })
}
