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
/// Port of `bevy/examples/input/mouse_input.rs`.
///
/// Baseline parity:
/// - Left mouse button pressed/just-pressed/just-released semantics are preserved.
/// - Mouse motion delta is reconstructed from current and previous cursor position.
/// - Mouse wheel delta uses host per-frame wheel delta.
let last_mouse_position_ref : Ref[@math.Vec2?] = Ref::new(None)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(mouse_click_system)
  .add_system(mouse_move_system)
  .run()
}

///|
fn mouse_click_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  if @input.mouse_button_pressed(Left) {
    log_line("left mouse currently pressed")
  }
  if @input.mouse_button_just_pressed(Left) {
    log_line("left mouse just pressed")
  }
  if @input.mouse_button_just_released(Left) {
    log_line("left mouse just released")
  }
}

///|
fn mouse_move_system(world : @ecs_world.World) -> Unit {
  world |> ignore

  let current_position_opt = @input.mouse_position()
  if current_position_opt is Some(current_position) {
    if last_mouse_position_ref.val is Some(last_position) {
      let delta = @math.Vec2::sub(current_position, last_position)
      if !is_zero_vec2(delta) {
        log_line("mouse moved \{format_vec2(delta)}")
      }
    }
  }
  last_mouse_position_ref.val = current_position_opt

  if @input.mouse_wheel_delta_opt() is Some(delta) {
    log_line("mouse scrolled \{format_vec2(delta)}")
  }
}

///|
fn is_zero_vec2(v : @math.Vec2) -> Bool {
  v.x == 0.0F && v.y == 0.0F
}

///|
fn format_vec2(v : @math.Vec2) -> String {
  "(\{v.x}, \{v.y})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[mouse_input] " + text)
}
