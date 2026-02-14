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
/// - Reads keyboard input events per frame and logs pressed character events.
/// - Bevy `logical_key: Key::Character` is not available in mgstudio.
/// - Character output is synthesized from current `KeyCode` mapping.
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
    if event.state is Released {
      continue
    }
    if keycode_to_character(event.key_code) is Some(character) {
      log_line(
        "KeyboardInput { key_code: \{format_keycode(event.key_code)}, state: Pressed, repeat: \{event.repeat} }: '\{character}'",
      )
    }
  }
}

///|
fn keycode_to_character(code : @window.KeyCode) -> String? {
  match code {
    KeyA => Some("a")
    KeyB => Some("b")
    KeyC => Some("c")
    KeyD => Some("d")
    KeyE => Some("e")
    KeyF => Some("f")
    KeyG => Some("g")
    KeyH => Some("h")
    KeyI => Some("i")
    KeyJ => Some("j")
    KeyK => Some("k")
    KeyL => Some("l")
    KeyM => Some("m")
    KeyN => Some("n")
    KeyO => Some("o")
    KeyP => Some("p")
    KeyQ => Some("q")
    KeyR => Some("r")
    KeyS => Some("s")
    KeyT => Some("t")
    KeyU => Some("u")
    KeyV => Some("v")
    KeyW => Some("w")
    KeyX => Some("x")
    KeyY => Some("y")
    KeyZ => Some("z")
    Digit1 => Some("1")
    Digit2 => Some("2")
    Digit3 => Some("3")
    Digit4 => Some("4")
    Digit5 => Some("5")
    Digit6 => Some("6")
    Space => Some(" ")
    Comma => Some(",")
    Period => Some(".")
    _ => None
  }
}

///|
fn format_keycode(code : @window.KeyCode) -> String {
  match code {
    KeyA => "KeyA"
    KeyB => "KeyB"
    KeyC => "KeyC"
    KeyD => "KeyD"
    KeyE => "KeyE"
    KeyF => "KeyF"
    KeyG => "KeyG"
    KeyH => "KeyH"
    KeyI => "KeyI"
    KeyJ => "KeyJ"
    KeyK => "KeyK"
    KeyL => "KeyL"
    KeyM => "KeyM"
    KeyN => "KeyN"
    KeyO => "KeyO"
    KeyP => "KeyP"
    KeyQ => "KeyQ"
    KeyR => "KeyR"
    KeyS => "KeyS"
    KeyT => "KeyT"
    KeyU => "KeyU"
    KeyV => "KeyV"
    KeyW => "KeyW"
    KeyX => "KeyX"
    KeyY => "KeyY"
    KeyZ => "KeyZ"
    Digit1 => "Digit1"
    Digit2 => "Digit2"
    Digit3 => "Digit3"
    Digit4 => "Digit4"
    Digit5 => "Digit5"
    Digit6 => "Digit6"
    Tab => "Tab"
    Enter => "Enter"
    Backspace => "Backspace"
    ShiftLeft => "ShiftLeft"
    ShiftRight => "ShiftRight"
    ControlLeft => "ControlLeft"
    ControlRight => "ControlRight"
    ArrowUp => "ArrowUp"
    ArrowDown => "ArrowDown"
    ArrowLeft => "ArrowLeft"
    ArrowRight => "ArrowRight"
    Space => "Space"
    Escape => "Escape"
    Comma => "Comma"
    Period => "Period"
  }
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[char_input_events] " + text)
}
