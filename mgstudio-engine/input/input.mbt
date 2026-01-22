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
fn keycode_to_string(code : @window.KeyCode) -> String {
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
pub fn host_input_is_key_down(code : String) -> Bool = "mgstudio_host" "input_is_key_down"

///|
pub fn host_input_is_key_just_pressed(code : String) -> Bool = "mgstudio_host" "input_is_key_just_pressed"

///|
pub fn host_input_is_key_just_released(code : String) -> Bool = "mgstudio_host" "input_is_key_just_released"

///|
pub fn host_input_finish_frame() -> Unit = "mgstudio_host" "input_finish_frame"

///|
pub fn host_input_is_mouse_button_down(button : String) -> Bool = "mgstudio_host" "input_is_mouse_button_down"

///|
pub fn host_input_is_mouse_button_just_pressed(button : String) -> Bool = "mgstudio_host" "input_is_mouse_button_just_pressed"

///|
pub fn host_input_is_mouse_button_just_released(button : String) -> Bool = "mgstudio_host" "input_is_mouse_button_just_released"

///|
pub fn host_input_mouse_x() -> Float = "mgstudio_host" "input_mouse_x"

///|
pub fn host_input_mouse_y() -> Float = "mgstudio_host" "input_mouse_y"

///|
pub fn host_input_has_cursor() -> Bool = "mgstudio_host" "input_has_cursor"

///|
pub fn key_pressed(code : @window.KeyCode) -> Bool {
  host_input_is_key_down(keycode_to_string(code))
}

///|
pub fn key_just_pressed(code : @window.KeyCode) -> Bool {
  host_input_is_key_just_pressed(keycode_to_string(code))
}

///|
pub fn key_just_released(code : @window.KeyCode) -> Bool {
  host_input_is_key_just_released(keycode_to_string(code))
}

///|
fn mouse_button_to_string(button : @window.MouseButton) -> String {
  match button {
    Left => "Left"
    Right => "Right"
    Middle => "Middle"
  }
}

///|
pub fn mouse_button_pressed(button : @window.MouseButton) -> Bool {
  host_input_is_mouse_button_down(mouse_button_to_string(button))
}

///|
pub fn mouse_button_just_pressed(button : @window.MouseButton) -> Bool {
  host_input_is_mouse_button_just_pressed(mouse_button_to_string(button))
}

///|
pub fn mouse_button_just_released(button : @window.MouseButton) -> Bool {
  host_input_is_mouse_button_just_released(mouse_button_to_string(button))
}

///|
pub fn mouse_position() -> @math.Vec2? {
  if host_input_has_cursor() {
    Some(@math.Vec2::new(host_input_mouse_x(), host_input_mouse_y()))
  } else {
    None
  }
}

///|
pub fn input_finish_system() -> Unit {
  host_input_finish_frame()
}

///|
pub fn input_plugin(app : @app.App) -> @app.App {
  app.add_post_update_system(input_finish_system)
}
