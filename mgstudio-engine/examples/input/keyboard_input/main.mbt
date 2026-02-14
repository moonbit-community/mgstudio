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
/// - KeyCode path (`KeyA`) is preserved.
/// - Bevy `ButtonInput<Key>` logical-key API is not available yet.
/// - `Key::Character("?")` is adapted to `KeyCode::Period` as a temporary proxy.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(keyboard_input_system)
  .run()
}

///|
fn keyboard_input_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  log_key_activity("A", KeyA)
  log_key_activity("? (mapped to Period)", Period)
}

///|
fn log_key_activity(label : String, key_code : @window.KeyCode) -> Unit {
  if @input.key_pressed(key_code) {
    log_line("'\{label}' currently pressed")
  }
  if @input.key_just_pressed(key_code) {
    log_line("'\{label}' just pressed")
  }
  if @input.key_just_released(key_code) {
    log_line("'\{label}' just released")
  }
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[keyboard_input] " + text)
}
