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

///|
/// Push UTF-16 code units of a MoonBit `String` to the host.
///
/// Web runtimes that do not expose the JS `WebAssembly.Array` GC API still
/// receive wasm-gc references as opaque objects. This helper lets the host
/// reconstruct a JS string by calling back into this export.
fn string_sink_push(code_unit : Int) -> Unit = "mgstudio_host" "string_sink_push"

///|
pub fn mgstudio_host_string_to_js(text : String) -> Unit {
  let n = text.length()
  for i in 0..<n {
    string_sink_push(text.code_unit_at(i).to_int())
  }
}
