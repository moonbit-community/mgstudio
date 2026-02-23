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
/// Port of `bevy/examples/input/char_input_events.rs`.
///
/// Baseline parity:
/// - Reads `KeyboardInput` events and logs pressed character keys.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system_param(print_char_event_system)
  .run()
}

///|
fn print_char_event_system(
  keyboard_inputs : @core.MessageReader[@input.KeyboardInput],
) -> Unit {
  for event in keyboard_inputs.read() {
    if !event.state.is_pressed() {
      continue
    }
    if event.logical_key is Character(character) {
      log_line("KeyboardInput: '\{character}'")
    }
  }
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[char_input_events] " + text)
}
