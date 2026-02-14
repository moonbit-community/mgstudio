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
/// Port of `bevy/examples/input/mouse_input_events.rs`.
///
/// Baseline parity:
/// - Mouse button, movement and wheel logs are emitted in an event-like format.
/// - Bevy MessageReader-based mouse/gesture events are not available in mgstudio yet.
/// - Pinch/rotation/double-tap gestures are not available in this runtime path.
let last_mouse_position_ref : Ref[@math.Vec2?] = Ref::new(None)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(print_mouse_events_system)
  .run()
}

///|
fn print_mouse_events_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  log_mouse_button_input_events()
  log_mouse_motion_and_cursor_events()
  log_mouse_wheel_events()
}

///|
fn log_mouse_button_input_events() -> Unit {
  let buttons : Array[@window.MouseButton] = [Left, Middle, Right]
  for button in buttons {
    if @input.mouse_button_just_pressed(button) {
      log_line(
        "MouseButtonInput { button: \{format_mouse_button(button)}, state: Pressed }",
      )
    }
    if @input.mouse_button_just_released(button) {
      log_line(
        "MouseButtonInput { button: \{format_mouse_button(button)}, state: Released }",
      )
    }
  }
}

///|
fn log_mouse_motion_and_cursor_events() -> Unit {
  let current_position_opt = @input.mouse_position()
  if current_position_opt is Some(current_position) {
    let delta_opt = match last_mouse_position_ref.val {
      Some(last_position) => {
        let delta = @math.Vec2::sub(current_position, last_position)
        if is_zero_vec2(delta) {
          None
        } else {
          Some(delta)
        }
      }
      None => None
    }
    if delta_opt is Some(delta) {
      log_line("MouseMotion { delta: \{format_vec2(delta)} }")
      log_line(
        "CursorMoved { position: \{format_vec2(current_position)}, delta: Some(\{format_vec2(delta)}) }",
      )
    }
  }
  last_mouse_position_ref.val = current_position_opt
}

///|
fn log_mouse_wheel_events() -> Unit {
  if @input.mouse_wheel_delta_opt() is Some(delta) {
    log_line("MouseWheel { unit: Line, x: \{delta.x}, y: \{delta.y} }")
  }
}

///|
fn format_mouse_button(button : @window.MouseButton) -> String {
  match button {
    Left => "Left"
    Middle => "Middle"
    Right => "Right"
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
  @window.host_debug_string(value="[mouse_input_events] " + text)
}
