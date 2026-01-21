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
fn main {
  run_sprite()
}

///|
pub fn run_sprite() -> Unit {
  @examples2d.sprite_run()
}

///|
pub fn run_move_sprite() -> Unit {
  @examples2d.move_sprite_run()
}

///|
pub fn run_rotation() -> Unit {
  @examples2d.rotation_run()
}

///|
pub fn run_rotate_to_cursor() -> Unit {
  @examples2d.rotate_to_cursor_run()
}

///|
pub fn run_2d_viewport_to_world() -> Unit {
  @examples2d.viewport_to_world_2d_run()
}

///|
pub fn run_pixel_grid_snap() -> Unit {
  @examples2d.pixel_grid_snap_run()
}

///|
pub fn run_mesh2d() -> Unit {
  @examples2d.mesh2d_run()
}

///|
pub fn run_sprite_scale() -> Unit {
  @examples2d.sprite_scale_run()
}

///|
pub fn run_sprite_flipping() -> Unit {
  @examples2d.sprite_flipping_run()
}
