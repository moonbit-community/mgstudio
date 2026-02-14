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
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_system(toggle_ime_system)
  .add_system_param(listen_keyboard_input_events_system)
  .run()
}

///|
fn toggle_ime_system(world : @ecs_world.World) -> Unit {
  world |> ignore
  if @input.mouse_button_just_pressed(Left) {
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
    match keyboard_input.key_code {
      Enter => commit_text_line()
      Backspace => remove_last_character()
      _ => append_text_by_keycode(keyboard_input.key_code)
    }
  }
}

///|
fn append_text_by_keycode(key_code : @window.KeyCode) -> Unit {
  let shift_pressed = @input.key_pressed(ShiftLeft) ||
    @input.key_pressed(ShiftRight)
  if keycode_to_insert_text(key_code, shift_pressed) is Some(inserted_text) {
    edit_buffer_ref.val.push(inserted_text)
    log_line("Edit text: \{buffer_to_text()}")
  }
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
  edit_buffer_ref.val.pop() |> ignore
  log_line("Edit text: \{buffer_to_text()}")
}

///|
fn keycode_to_insert_text(
  code : @window.KeyCode,
  shift_pressed : Bool,
) -> String? {
  match code {
    KeyA => Some(if shift_pressed { "A" } else { "a" })
    KeyB => Some(if shift_pressed { "B" } else { "b" })
    KeyC => Some(if shift_pressed { "C" } else { "c" })
    KeyD => Some(if shift_pressed { "D" } else { "d" })
    KeyE => Some(if shift_pressed { "E" } else { "e" })
    KeyF => Some(if shift_pressed { "F" } else { "f" })
    KeyG => Some(if shift_pressed { "G" } else { "g" })
    KeyH => Some(if shift_pressed { "H" } else { "h" })
    KeyI => Some(if shift_pressed { "I" } else { "i" })
    KeyJ => Some(if shift_pressed { "J" } else { "j" })
    KeyK => Some(if shift_pressed { "K" } else { "k" })
    KeyL => Some(if shift_pressed { "L" } else { "l" })
    KeyM => Some(if shift_pressed { "M" } else { "m" })
    KeyN => Some(if shift_pressed { "N" } else { "n" })
    KeyO => Some(if shift_pressed { "O" } else { "o" })
    KeyP => Some(if shift_pressed { "P" } else { "p" })
    KeyQ => Some(if shift_pressed { "Q" } else { "q" })
    KeyR => Some(if shift_pressed { "R" } else { "r" })
    KeyS => Some(if shift_pressed { "S" } else { "s" })
    KeyT => Some(if shift_pressed { "T" } else { "t" })
    KeyU => Some(if shift_pressed { "U" } else { "u" })
    KeyV => Some(if shift_pressed { "V" } else { "v" })
    KeyW => Some(if shift_pressed { "W" } else { "w" })
    KeyX => Some(if shift_pressed { "X" } else { "x" })
    KeyY => Some(if shift_pressed { "Y" } else { "y" })
    KeyZ => Some(if shift_pressed { "Z" } else { "z" })
    Digit1 => Some("1")
    Digit2 => Some("2")
    Digit3 => Some("3")
    Digit4 => Some("4")
    Digit5 => Some("5")
    Digit6 => Some("6")
    Space => Some(" ")
    Comma => Some(if shift_pressed { "<" } else { "," })
    Period => Some(if shift_pressed { ">" } else { "." })
    _ => None
  }
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
