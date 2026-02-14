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
/// Port of `bevy/examples/input/gamepad_input.rs`.
///
/// Baseline parity:
/// - South button press/release checks are preserved.
/// - RightTrigger2 and LeftStickX threshold logging is preserved.
/// - Bevy ECS `(Entity, &Gamepad)` query is adapted to runtime `input.gamepads()`.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(gamepad_system)
  .run()
}

///|
fn gamepad_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  for gamepad in @input.gamepads() {
    let gamepad_id = gamepad.id()
    if gamepad.just_pressed(South) {
      log_line("\{gamepad_id} just pressed South")
    } else if gamepad.just_released(South) {
      log_line("\{gamepad_id} just released South")
    }

    if gamepad.get(Button(RightTrigger2)) is Some(right_trigger) {
      if abs_over_threshold(right_trigger, 0.01F) {
        log_line("\{gamepad_id} RightTrigger2 value is \{right_trigger}")
      }
    }

    if gamepad.get(Axis(LeftStickX)) is Some(left_stick_x) {
      if abs_over_threshold(left_stick_x, 0.01F) {
        log_line("\{gamepad_id} LeftStickX value is \{left_stick_x}")
      }
    }
  }
}

///|
fn abs_over_threshold(value : Float, threshold : Float) -> Bool {
  value > threshold || value < -threshold
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[gamepad_input] " + text)
}
