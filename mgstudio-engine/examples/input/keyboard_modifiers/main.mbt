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
/// Port of `bevy/examples/input/keyboard_modifiers.rs`.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(@app.system_param(keyboard_input_system))
  .run()
}

///|
/// Prints when `Ctrl + Shift + A` is pressed.
fn keyboard_input_system(input : @input.ButtonInput[@window.KeyCode]) -> Unit {
  let shift = input.any_pressed([ShiftLeft, ShiftRight])
  let ctrl = input.any_pressed([ControlLeft, ControlRight])

  if ctrl && shift && input.just_pressed(KeyA) {
    log_line("Just pressed Ctrl + Shift + A!")
  }
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[keyboard_modifiers] " + text)
}
