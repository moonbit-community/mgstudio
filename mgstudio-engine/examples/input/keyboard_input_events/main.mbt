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
/// Port of `bevy/examples/input/keyboard_input_events.rs`.
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() { @mgstudio.DefaultPlugins::build() })
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(print_keyboard_event_system)),
  )
  .run()
}

///|
fn print_keyboard_event_system(
  keyboard_inputs : @ecs.MessageReader[@input.KeyboardInput],
) -> Unit {
  for keyboard_input in (try! keyboard_inputs.read()) {
    log_line(format_keyboard_input(keyboard_input))
  }
}

///|
fn format_keyboard_input(event : @input.KeyboardInput) -> String {
  "KeyboardInput { key_code: \{format_keycode(event.key_code)}, logical_key: \{format_logical_key(event.logical_key)}, state: \{format_button_state(event.state)}, repeat: \{event.repeat} }"
}

///|
fn format_logical_key(key : @input.Key) -> String {
  match key {
    Character(text) => "Character(\"\{text}\")"
    Enter => "Enter"
    Backspace => "Backspace"
    Tab => "Tab"
    Shift => "Shift"
    Control => "Control"
    ArrowUp => "ArrowUp"
    ArrowDown => "ArrowDown"
    ArrowLeft => "ArrowLeft"
    ArrowRight => "ArrowRight"
    PageUp => "PageUp"
    PageDown => "PageDown"
    Space => "Space"
    Escape => "Escape"
  }
}

///|
fn format_button_state(state : @input.ButtonState) -> String {
  match state {
    Pressed => "Pressed"
    Released => "Released"
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
    Digit7 => "Digit7"
    Digit8 => "Digit8"
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
    PageUp => "PageUp"
    PageDown => "PageDown"
    Space => "Space"
    Escape => "Escape"
    Semicolon => "Semicolon"
    Comma => "Comma"
    Period => "Period"
    Slash => "Slash"
    Minus => "Minus"
    Equal => "Equal"
    BracketLeft => "BracketLeft"
    BracketRight => "BracketRight"
    Quote => "Quote"
  }
}

///|
fn log_line(text : String) -> Unit {
  @window.host_debug_string(value="[keyboard_input_events] " + text)
}
