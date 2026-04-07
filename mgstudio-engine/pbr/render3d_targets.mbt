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
type RenderTargetComputed3d = @pbr_render.RenderTargetComputed3d

///|
fn render3d_pass_clear_enabled_for_target(
  cleared_targets : Array[Int],
  target_id : Int,
  requested : Bool,
) -> Int {
  @pbr_render.render3d_pass_clear_enabled_for_target(
    cleared_targets, target_id, requested,
  )
}

///|
fn render3d_pass_viewport_for_target(
  pass_target_id : Int,
  camera_target_id : Int,
  camera_viewport_x : Int,
  camera_viewport_y : Int,
  camera_viewport_width : Int,
  camera_viewport_height : Int,
) -> (Int, Int, Int, Int) {
  @pbr_render.render3d_pass_viewport_for_target(
    pass_target_id, camera_target_id, camera_viewport_x, camera_viewport_y, camera_viewport_width,
    camera_viewport_height,
  )
}

///|
fn render3d_target_info(
  world : @ecs.World,
  target : @sprite.RenderTarget,
) -> RenderTargetComputed3d? {
  @pbr_render.render3d_target_info(world, target)
}

///|
fn render3d_clamp_viewport(
  viewport : @sprite.Viewport,
  target_size : @math.IVec2,
) -> @sprite.Viewport {
  @pbr_render.render3d_clamp_viewport(viewport, target_size)
}
