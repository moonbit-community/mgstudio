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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() { @mgstudio.DefaultPlugins::build() })
  .add_systems(@app.Update, @app.system(@app.system_param(gamepad_system)))
  .run()
}

///|
fn gamepad_system(gamepads : @ecs.Query1[@input.Gamepad]) -> Unit {
  try! gamepads.view(fn(entity, gamepad) {
    let gamepad_id = entity_text(entity)
    if gamepad.just_pressed(@input.GamepadButton::South) {
      log_line("\{gamepad_id} just pressed South")
    } else if gamepad.just_released(@input.GamepadButton::South) {
      log_line("\{gamepad_id} just released South")
    }

    if gamepad.get(@input.GamepadButton::RightTrigger2) is Some(right_trigger) {
      if abs_over_threshold(right_trigger, 0.01F) {
        log_line("\{gamepad_id} RightTrigger2 value is \{right_trigger}")
      }
    }

    if gamepad.get(@input.GamepadAxis::LeftStickX) is Some(left_stick_x) {
      if abs_over_threshold(left_stick_x, 0.01F) {
        log_line("\{gamepad_id} LeftStickX value is \{left_stick_x}")
      }
    }
  })
}

///|
fn abs_over_threshold(value : Float, threshold : Float) -> Bool {
  value > threshold || value < -threshold
}

///|
fn entity_text(entity : @core.Entity) -> String {
  "Entity(" + entity.id.to_string() + ", " + entity.generation.to_string() + ")"
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[gamepad_input] " + text)
}
