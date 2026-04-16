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
pub struct RenderTargetComputed3d {
  target_id : Int
  target_size : @math.IVec2
  scale_factor : Float
}

///|
pub fn render3d_pass_clear_enabled_for_target(
  cleared_targets : Array[Int],
  target_id : Int,
  requested : Bool,
) -> Int {
  if !requested {
    return 0
  }
  for cleared_target_id in cleared_targets {
    if cleared_target_id == target_id {
      return 0
    }
  }
  cleared_targets.push(target_id)
  1
}

///|
pub fn render3d_pass_viewport_for_target(
  pass_target_id : Int,
  camera_target_id : Int,
  camera_viewport_x : Int,
  camera_viewport_y : Int,
  camera_viewport_width : Int,
  camera_viewport_height : Int,
) -> (Int, Int, Int, Int) {
  if pass_target_id == camera_target_id {
    (
      camera_viewport_x, camera_viewport_y, camera_viewport_width, camera_viewport_height,
    )
  } else {
    (0, 0, camera_viewport_width, camera_viewport_height)
  }
}

///|
pub fn render3d_target_info(
  world : @ecs.World,
  target : @sprite.RenderTarget,
) -> RenderTargetComputed3d? {
  match target {
    @sprite.RenderTarget::Screen => {
      let width = @window.window_physical_width_for(
        world,
        @window.WindowRef::Primary,
      )
      let height = @window.window_physical_height_for(
        world,
        @window.WindowRef::Primary,
      )
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(
        world,
        @window.WindowRef::Primary,
      )
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some(RenderTargetComputed3d::{
        target_id: -1,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    @sprite.RenderTarget::Window(window_ref) => {
      guard @window.window_host_window_for_ref(world, window_ref)
        is Some(host_window) else {
        return None
      }
      let surface_target_id = @render_gpu.host_gpu_surface_target_id_for_window(
        host_window,
      )
      if surface_target_id >= 0 {
        return None
      }
      let width = @window.window_physical_width_for(world, window_ref)
      let height = @window.window_physical_height_for(world, window_ref)
      if width <= 0 || height <= 0 {
        return None
      }
      let mut scale_factor = @window.window_scale_factor_for(world, window_ref)
      if scale_factor <= 0.0F {
        scale_factor = 1.0F
      }
      Some(RenderTargetComputed3d::{
        target_id: surface_target_id,
        target_size: @math.IVec2::new(width, height),
        scale_factor,
      })
    }
    @sprite.RenderTarget::Image(handle) => {
      let width = @asset.asset_texture_width(handle)
      let height = @asset.asset_texture_height(handle)
      if width <= 0 || height <= 0 {
        return None
      }
      Some(RenderTargetComputed3d::{
        target_id: handle.id(),
        target_size: @math.IVec2::new(width, height),
        scale_factor: 1.0F,
      })
    }
  }
}

///|
pub fn render3d_clamp_viewport(
  viewport : @sprite.Viewport,
  target_size : @math.IVec2,
) -> @sprite.Viewport {
  viewport.clamp_to_size(target_size)
}
