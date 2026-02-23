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
/// Port of `bevy/examples/input/keyboard_input.rs`.
///
/// Baseline parity:
/// - Uses Bevy-style `ButtonInput<KeyCode>` and `ButtonInput<Key>` resources.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(@app.system_param2(keyboard_input_system))
  .run()
}

///|
fn keyboard_input_system(
  keyboard_input : @input.ButtonInput[@window.KeyCode],
  key_input : @input.ButtonInput[@input.Key],
) -> Unit {
  let keyboard = keyboard_input
  if keyboard.pressed(KeyA) {
    log_line("'A' currently pressed")
  }
  if keyboard.just_pressed(KeyA) {
    log_line("'A' just pressed")
  }
  if keyboard.just_released(KeyA) {
    log_line("'A' just released")
  }

  let key_input = key_input
  let key = @input.Key::Character("?")
  if key_input.pressed(key) {
    log_line("'?' currently pressed")
  }
  if key_input.just_pressed(key) {
    log_line("'?' just pressed")
  }
  if key_input.just_released(key) {
    log_line("'?' just released")
  }
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[keyboard_input] " + text)
}
