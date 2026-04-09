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
// Bevy source: `bevy/crates/bevy_picking/src/window.rs`.
/// Window-coordinate conversion helpers shared by picking backends and events.

///|
fn picking_rotate_vec2(v : @math.Vec2, radians : Float) -> @math.Vec2 {
  let cosv = @math.cos(radians)
  let sinv = @math.sin(radians)
  @math.Vec2::new(v.x * cosv - v.y * sinv, v.x * sinv + v.y * cosv)
}

///|
fn picking_camera_target_size(
  camera : @sprite.Camera,
  window_width : Int,
  window_height : Int,
) -> @math.IVec2 {
  match camera.physical_target_size() {
    Some(size) =>
      if size.x > 0 && size.y > 0 {
        size
      } else {
        @math.IVec2::new(window_width, window_height)
      }
    None => @math.IVec2::new(window_width, window_height)
  }
}

///|
fn picking_window_position_in_ui_viewport(
  pointer_window_pos : @math.Vec2,
  ctx : @ui.UiContext,
) -> @math.Vec2? {
  @ui.ui_pointer_pos_in_viewport(
    pointer_window_pos,
    ctx.viewport_origin,
    ctx.viewport_size,
  )
}

///|
fn picking_window_to_sprite_world(
  pointer_window_pos : @math.Vec2,
  ctx : @ui.UiContext,
) -> @math.Vec2? {
  match picking_window_position_in_ui_viewport(pointer_window_pos, ctx) {
    Some(pointer_view_pos) => {
      let cam_translation = @math.Vec2::new(
        ctx.camera_transform.translation.x,
        ctx.camera_transform.translation.y,
      )
      let cam_rotation = ctx.camera_transform.rotation_z()
      let cam_scale = if ctx.camera_scale <= 0.0F {
        1.0F
      } else {
        ctx.camera_scale
      }
      let centered = @math.Vec2::new(
        pointer_view_pos.x - ctx.viewport_size.x / 2.0F,
        ctx.viewport_size.y / 2.0F - pointer_view_pos.y,
      )
      let view_pos = @math.Vec2::new(
        centered.x * cam_scale,
        centered.y * cam_scale,
      )
      let world_offset = picking_rotate_vec2(view_pos, -cam_rotation)
      Some(
        @math.Vec2::new(
          cam_translation.x + world_offset.x,
          cam_translation.y + world_offset.y,
        ),
      )
    }
    None => None
  }
}

///|
fn picking_window_position_or_origin(position : @math.Vec2?) -> @math.Vec2 {
  match position {
    Some(v) => v
    None => @math.Vec2::new(0.0F, 0.0F)
  }
}
