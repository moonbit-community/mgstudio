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
/// Port of `bevy/examples/input/text_input.rs`.
///
/// Baseline parity:
/// - Enter creates a committed bubble line and Backspace removes one character.
/// - Mouse left click toggles an IME-enabled flag.
/// - Bevy UI/IME event surfaces are not available in mgstudio runtime yet.
let ime_enabled_ref : Ref[Bool] = Ref::new(false)

///|
let edit_buffer_ref : Ref[Array[String]] = Ref::new([])

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins_ecs()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_system(@app.system_param(toggle_ime_system))
  .add_system_param(listen_keyboard_input_events_system)
  .add_system_param(listen_character_input_events_system)
  .run()
}

///|
fn toggle_ime_system(mouse : @input.ButtonInput[@window.MouseButton]) -> Unit {
  if mouse.just_pressed(Left) {
    ime_enabled_ref.val = !ime_enabled_ref.val
    log_line("IME Enabled: \{ime_enabled_ref.val}")
  }
}

///|
fn listen_keyboard_input_events_system(
  keyboard_inputs : @core.MessageReader[@input.KeyboardInput],
) -> Unit {
  for keyboard_input in keyboard_inputs.read() {
    if keyboard_input.state is Released {
      continue
    }
    match keyboard_input.logical_key {
      @input.Key::Enter => commit_text_line()
      @input.Key::Backspace => remove_last_character()
      _ => ()
    }
  }
}

///|
fn listen_character_input_events_system(
  keyboard_characters : @core.MessageReader[@input.KeyboardCharacter],
) -> Unit {
  for keyboard_character in keyboard_characters.read() {
    if is_printable_text(keyboard_character.character) {
      edit_buffer_ref.val.push(keyboard_character.character)
      log_line("Edit text: \{buffer_to_text()}")
    }
  }
}

///|
fn is_printable_text(text : String) -> Bool {
  if text.length() == 0 {
    return false
  }
  for ch in text {
    let code_point = ch.to_int()
    if code_point < 0x20 || code_point == 0x7F {
      return false
    }
  }
  true
}

///|
fn commit_text_line() -> Unit {
  if edit_buffer_ref.val.length() == 0 {
    return
  }
  let committed = buffer_to_text()
  log_line("Bubble committed: \{committed}")
  edit_buffer_ref.val.clear()
  log_line("Edit text: ")
}

///|
fn remove_last_character() -> Unit {
  if edit_buffer_ref.val.length() == 0 {
    return
  }
  let text = buffer_to_text()
  let chars : Array[Char] = []
  for ch in text {
    chars.push(ch)
  }
  if chars.length() == 0 {
    return
  }
  chars.pop() |> ignore
  edit_buffer_ref.val.clear()
  if chars.length() > 0 {
    edit_buffer_ref.val.push(String::from_array(chars))
  }
  log_line("Edit text: \{buffer_to_text()}")
}

///|
fn buffer_to_text() -> String {
  let mut text = ""
  for chunk in edit_buffer_ref.val {
    text = text + chunk
  }
  text
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[text_input] " + text)
}
