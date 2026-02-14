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
/// Port of `bevy/examples/input/touch_input.rs`.
///
/// Baseline parity:
/// - `just_pressed` / `just_released` / `active` logging follows the Bevy flow.
/// - Current runtime has no native touch resource, so left mouse is mapped to a
///   single touch id (`0`) as an adaptation.
/// - Touch cancel events are not available in this runtime path.
let simulated_touch_active_ref : Ref[Bool] = Ref::new(false)

///|
let touch_capability_logged_ref : Ref[Bool] = Ref::new(false)

///|
let last_touch_position_ref : Ref[@math.Vec2?] = Ref::new(None)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(touch_system)
  .run()
}

///|
fn touch_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  if !touch_capability_logged_ref.val {
    touch_capability_logged_ref.val = true
    log_line(
      "touch cancel events are unavailable; using left mouse as touch id 0",
    )
  }

  let just_pressed = @input.mouse_button_just_pressed(Left)
  let just_released = @input.mouse_button_just_released(Left)
  let position_opt = @input.mouse_position()

  if just_pressed {
    simulated_touch_active_ref.val = true
    if position_opt is Some(position) {
      last_touch_position_ref.val = Some(position)
      log_line("just pressed touch with id: 0, at: \{format_vec2(position)}")
    }
  }

  if just_released {
    simulated_touch_active_ref.val = false
    if position_opt is Some(position) {
      last_touch_position_ref.val = Some(position)
      log_line("just released touch with id: 0, at: \{format_vec2(position)}")
    } else {
      log_line("just released touch with id: 0")
    }
  }

  if simulated_touch_active_ref.val {
    if position_opt is Some(position) {
      last_touch_position_ref.val = Some(position)
      log_line(
        "active touch: Touch { id: 0, position: \{format_vec2(position)} }",
      )
      log_line("  just_pressed: \{just_pressed}")
    }
  }
}

///|
fn format_vec2(v : @math.Vec2) -> String {
  "(\{v.x}, \{v.y})"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[touch_input] " + text)
}
