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
fn picking_window_position_or_origin(position : @math.Vec2?) -> @math.Vec2 {
  match position {
    Some(v) => v
    None => @math.Vec2::new(0.0F, 0.0F)
  }
}
