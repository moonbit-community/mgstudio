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
    Digit1 => "Digit1"
    Digit2 => "Digit2"
    Digit3 => "Digit3"
    Digit4 => "Digit4"
    Digit5 => "Digit5"
    Digit6 => "Digit6"
    Tab => "Tab"
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
let keyboard_event_keycodes : Array[@window.KeyCode] = [
  KeyA,
  KeyB,
  KeyC,
  KeyD,
  KeyE,
  KeyF,
  KeyG,
  KeyH,
  KeyI,
  KeyJ,
  KeyK,
  KeyL,
  KeyM,
  KeyN,
  KeyO,
  KeyP,
  KeyQ,
  KeyR,
  KeyS,
  KeyT,
  KeyU,
  KeyV,
  KeyW,
  KeyX,
  KeyY,
  KeyZ,
  Digit1,
  Digit2,
  Digit3,
  Digit4,
  Digit5,
  Digit6,
  Tab,
  ArrowUp,
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  Space,
  Escape,
  Comma,
  Period,
]

///|
pub(all) enum ButtonState {
  Pressed
  Released
}

///|
pub struct KeyboardInput {
  key_code : @window.KeyCode
  state : ButtonState
  repeat : Bool
}

///|
let keyboard_input_events_ref : Ref[@core.Messages[KeyboardInput]] = Ref::new(
  @core.Messages::new(),
)

///|
fn host_input_is_key_down_id(code_id : Int) -> Bool = "mgstudio_host" "input_is_key_down"

///|
fn host_input_is_key_just_pressed_id(code_id : Int) -> Bool = "mgstudio_host" "input_is_key_just_pressed"

///|
fn host_input_is_key_just_released_id(code_id : Int) -> Bool = "mgstudio_host" "input_is_key_just_released"

///|
pub fn host_input_finish_frame() -> Unit = "mgstudio_host" "input_finish_frame"

///|
fn host_input_is_mouse_button_down_id(button_id : Int) -> Bool = "mgstudio_host" "input_is_mouse_button_down"

///|
fn host_input_is_mouse_button_just_pressed_id(button_id : Int) -> Bool = "mgstudio_host" "input_is_mouse_button_just_pressed"

///|
fn host_input_is_mouse_button_just_released_id(button_id : Int) -> Bool = "mgstudio_host" "input_is_mouse_button_just_released"

///|
pub fn host_input_mouse_x() -> Float = "mgstudio_host" "input_mouse_x"

///|
pub fn host_input_mouse_y() -> Float = "mgstudio_host" "input_mouse_y"

///|
pub fn host_input_has_cursor() -> Bool = "mgstudio_host" "input_has_cursor"

///|
pub fn host_input_wheel_x() -> Float = "mgstudio_host" "input_wheel_x"

///|
pub fn host_input_wheel_y() -> Float = "mgstudio_host" "input_wheel_y"

///|
pub fn key_pressed(code : @window.KeyCode) -> Bool {
  @core.with_host_string_id(keycode_to_string(code), fn(code_id) {
    host_input_is_key_down_id(code_id)
  })
}

///|
pub fn key_just_pressed(code : @window.KeyCode) -> Bool {
  @core.with_host_string_id(keycode_to_string(code), fn(code_id) {
    host_input_is_key_just_pressed_id(code_id)
  })
}

///|
pub fn key_just_released(code : @window.KeyCode) -> Bool {
  @core.with_host_string_id(keycode_to_string(code), fn(code_id) {
    host_input_is_key_just_released_id(code_id)
  })
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
  @core.with_host_string_id(mouse_button_to_string(button), fn(button_id) {
    host_input_is_mouse_button_down_id(button_id)
  })
}

///|
pub fn mouse_button_just_pressed(button : @window.MouseButton) -> Bool {
  @core.with_host_string_id(mouse_button_to_string(button), fn(button_id) {
    host_input_is_mouse_button_just_pressed_id(button_id)
  })
}

///|
pub fn mouse_button_just_released(button : @window.MouseButton) -> Bool {
  @core.with_host_string_id(mouse_button_to_string(button), fn(button_id) {
    host_input_is_mouse_button_just_released_id(button_id)
  })
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
/// Mouse wheel delta since last `host_input_finish_frame()`.
pub fn mouse_wheel_delta() -> @math.Vec2 {
  @math.Vec2::new(host_input_wheel_x(), host_input_wheel_y())
}

///|
/// Mouse wheel delta, or `None` if both components are zero.
pub fn mouse_wheel_delta_opt() -> @math.Vec2? {
  let v = mouse_wheel_delta()
  if v.x == 0.0F && v.y == 0.0F {
    None
  } else {
    Some(v)
  }
}

///|
pub fn[W : @core.ChangeTickWorld] input_poll_keyboard_system(world : W) -> Unit {
  let tick = world.read_change_tick()
  for code in keyboard_event_keycodes {
    if key_just_pressed(code) {
      keyboard_input_events_ref.val.send(tick, KeyboardInput::{
        key_code: code,
        state: ButtonState::Pressed,
        repeat: false,
      })
    }
    if key_just_released(code) {
      keyboard_input_events_ref.val.send(tick, KeyboardInput::{
        key_code: code,
        state: ButtonState::Released,
        repeat: false,
      })
    }
  }
}

///|
fn[W : @core.SystemContextWorld] input_world_system_ticks(
  world : W,
) -> @core.SystemTicks {
  world.get_system_context().ticks()
}

///|
fn keyboard_input_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[KeyboardInput] {
  keyboard_input_events_ref.val.reader(ticks)
}

///|
pub fn[W : @core.SystemContextWorld] keyboard_input_events(
  world : W,
) -> @core.MessageReader[KeyboardInput] {
  keyboard_input_events_reader(input_world_system_ticks(world))
}

///|
pub impl @core.Message for KeyboardInput with reader(ticks) {
  keyboard_input_events_reader(ticks)
}

///|
pub fn[W] input_finish_system(_world : W) -> Unit {
  input_gamepad_finish_frame()
  host_input_finish_frame()
}

///|
pub fn[W : @core.ChangeTickWorld] input_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .add_pre_update_system(input_poll_keyboard_system)
  .add_pre_update_system(input_poll_gamepad_system)
  .add_post_update_system(input_finish_system)
}
