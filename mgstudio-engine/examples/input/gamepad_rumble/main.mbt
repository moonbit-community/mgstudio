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
/// Port of `bevy/examples/input/gamepad_rumble.rs`.
///
/// Baseline parity:
/// - Gamepad button trigger flow is preserved (North/East/South/West/Start).
/// - Bevy `GamepadRumbleRequest` message writer is not available in mgstudio.
/// - This example logs equivalent rumble requests without host force-feedback.
let rumble_capability_logged_ref : Ref[Bool] = Ref::new(false)

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(gamepad_rumble_system)
  .run()
}

///|
fn gamepad_rumble_system(world : @ecs.World) -> Unit {
  world |> ignore
  for gamepad in @input.gamepads() {
    let gamepad_id = gamepad.id()
    if gamepad.just_pressed(North) {
      log_add_rumble_request(
        gamepad_id, "North face button: strong (low-frequency) low intensity for 5 seconds.",
      )
    }
    if gamepad.just_pressed(East) {
      log_add_rumble_request(
        gamepad_id, "East face button: maximum rumble on both motors for 5 seconds.",
      )
    }
    if gamepad.just_pressed(South) {
      log_add_rumble_request(
        gamepad_id, "South face button: low-intensity weak motor rumble for 0.5 seconds.",
      )
    }
    if gamepad.just_pressed(West) {
      log_add_rumble_request(
        gamepad_id, "West face button: custom rumble intensity for 5 seconds.",
      )
    }
    if gamepad.just_pressed(Start) {
      log_stop_rumble_request(gamepad_id)
    }
  }
}

///|
fn log_add_rumble_request(gamepad_id : Int, summary : String) -> Unit {
  log_rumble_capability_once()
  log_line("[gamepad=\{gamepad_id}] Add rumble request: \{summary}")
}

///|
fn log_stop_rumble_request(gamepad_id : Int) -> Unit {
  log_rumble_capability_once()
  log_line("[gamepad=\{gamepad_id}] Stop rumble request.")
}

///|
fn log_rumble_capability_once() -> Unit {
  if rumble_capability_logged_ref.val {
    return
  }
  rumble_capability_logged_ref.val = true
  log_line(
    "Force-feedback output is not implemented in the current runtime path.",
  )
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[gamepad_rumble] " + text)
}
