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
pub type NativeWindowHandle = Int

///|
const DEFAULT_FRAME_LIMIT : Int = 0

///|
fn parse_non_negative_int(input : String) -> Int? {
  if input.length() == 0 {
    return None
  }
  let mut value = 0
  for c in input {
    let code = c.to_int()
    if code < 48 || code > 57 {
      return None
    }
    value = value * 10 + (code - 48)
  }
  Some(value)
}

///|
fn run_loop_frame_limit() -> Int {
  if @sys.get_env_var("MGSTUDIO_WINDOW_FRAME_LIMIT") is Some(value) {
    if parse_non_negative_int(value) is Some(parsed) {
      parsed
    } else {
      DEFAULT_FRAME_LIMIT
    }
  } else {
    DEFAULT_FRAME_LIMIT
  }
}

///|
fn encode_utf8_bytes(value : String) -> Bytes {
  @utf8.encode(value[:])
}

///|
pub fn create(
  logical_width~ : Int,
  logical_height~ : Int,
  physical_width~ : Int,
  physical_height~ : Int,
  use_physical_size_on_create~ : Bool,
  title~ : String,
) -> NativeWindowHandle {
  let title_bytes = encode_utf8_bytes(title)
  @windowing_native.create_utf8(
    logical_width,
    logical_height,
    physical_width,
    physical_height,
    use_physical_size_on_create,
    title_bytes,
    title_bytes.length().to_uint64(),
  )
}

///|
pub fn poll_events(window : NativeWindowHandle) -> Unit {
  @windowing_native.poll_events(window)
}

///|
pub fn width(window : NativeWindowHandle) -> Int {
  @windowing_native.width(window)
}

///|
pub fn height(window : NativeWindowHandle) -> Int {
  @windowing_native.height(window)
}

///|
pub fn scale_factor(window : NativeWindowHandle) -> Float {
  @windowing_native.scale_factor(window)
}

///|
pub fn focused(window : NativeWindowHandle) -> Bool {
  @windowing_native.focused(window)
}

///|
pub fn should_close(window : NativeWindowHandle) -> Bool {
  @windowing_native.should_close(window)
}

///|
pub fn request_close(window : NativeWindowHandle) -> Unit {
  @windowing_native.request_close(window)
}

///|
pub fn run_loop(step : FuncRef[() -> Unit]) -> Unit {
  if !@windowing_native.any_window_open() {
    step()
    return
  }
  let frame_limit = run_loop_frame_limit()
  let mut frames = 0
  while @windowing_native.any_window_open() {
    step()
    if frame_limit > 0 {
      frames = frames + 1
      if frames >= frame_limit {
        break
      }
    }
  }
}

///|
pub fn set_title(window : NativeWindowHandle, title~ : String) -> Unit {
  let title_bytes = encode_utf8_bytes(title)
  @windowing_native.set_title_utf8(
    window,
    title_bytes,
    title_bytes.length().to_uint64(),
  )
}

///|
pub fn set_size(
  window : NativeWindowHandle,
  width~ : Int,
  height~ : Int,
) -> Unit {
  @windowing_native.set_size(window, width, height)
}

///|
pub fn set_resizable(window : NativeWindowHandle, resizable~ : Bool) -> Unit {
  @windowing_native.set_resizable(window, resizable)
}

///|
pub fn set_cursor_visible(window : NativeWindowHandle, visible~ : Bool) -> Unit {
  @windowing_native.set_cursor_visible(window, visible)
}

///|
pub fn set_cursor_grab_mode(window : NativeWindowHandle, mode~ : Int) -> Unit {
  @windowing_native.set_cursor_grab_mode(window, mode)
}

///|
pub fn set_cursor_icon(window : NativeWindowHandle, icon~ : Int) -> Unit {
  @windowing_native.set_cursor_icon(window, icon)
}

///|
pub fn set_mode(window : NativeWindowHandle, mode~ : Int) -> Unit {
  @windowing_native.set_mode(window, mode)
}

///|
pub fn set_position(window : NativeWindowHandle, x~ : Int, y~ : Int) -> Unit {
  @windowing_native.set_position(window, x, y)
}

///|
pub fn position_x(window : NativeWindowHandle) -> Int {
  @windowing_native.position_x(window)
}

///|
pub fn position_y(window : NativeWindowHandle) -> Int {
  @windowing_native.position_y(window)
}

///|
pub fn attach_surface_metal_layer(
  window : NativeWindowHandle,
  surface : @wgpu_mbt.Surface,
) -> Unit {
  @windowing_native.attach_metal_layer(window, surface.metal_layer_handle())
}

///|
pub fn native_backend_available() -> Bool {
  @windowing_native.native_backend_available()
}

///|
fn input_key_id(code : String) -> Int {
  match code {
    "KeyA" => 0
    "KeyB" => 1
    "KeyC" => 2
    "KeyD" => 3
    "KeyE" => 4
    "KeyF" => 5
    "KeyG" => 6
    "KeyH" => 7
    "KeyI" => 8
    "KeyJ" => 9
    "KeyK" => 10
    "KeyL" => 11
    "KeyM" => 12
    "KeyN" => 13
    "KeyO" => 14
    "KeyP" => 15
    "KeyQ" => 16
    "KeyR" => 17
    "KeyS" => 18
    "KeyT" => 19
    "KeyU" => 20
    "KeyV" => 21
    "KeyW" => 22
    "KeyX" => 23
    "KeyY" => 24
    "KeyZ" => 25
    "Digit1" => 26
    "Digit2" => 27
    "Digit3" => 28
    "Digit4" => 29
    "Digit5" => 30
    "Digit6" => 31
    "Digit7" => 32
    "Digit8" => 33
    "Digit9" => 34
    "Digit0" => 35
    "Tab" => 36
    "Enter" => 37
    "Backspace" => 38
    "ShiftLeft" => 39
    "ShiftRight" => 40
    "ControlLeft" => 41
    "ControlRight" => 42
    "ArrowUp" => 43
    "ArrowDown" => 44
    "ArrowLeft" => 45
    "ArrowRight" => 46
    "PageUp" => 47
    "PageDown" => 48
    "Space" => 49
    "Escape" => 50
    "Semicolon" => 51
    "Comma" => 52
    "Period" => 53
    "Slash" => 54
    "Minus" => 55
    "Equal" => 56
    "NumpadAdd" => 62
    "NumpadSubtract" => 63
    "BracketLeft" => 57
    "BracketRight" => 58
    "Quote" => 59
    "Backquote" => 60
    "Backslash" => 61
    _ => -1
  }
}

///|
fn input_mouse_button_id(button : String) -> Int {
  match button {
    "Left" => 0
    "Right" => 1
    "Middle" => 2
    _ => -1
  }
}

///|
pub fn input_is_key_down(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    @windowing_native.input_is_key_down(id)
  }
}

///|
pub fn input_is_key_just_pressed(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    @windowing_native.input_is_key_just_pressed(id)
  }
}

///|
pub fn input_is_key_just_released(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    @windowing_native.input_is_key_just_released(id)
  }
}

///|
pub fn input_is_key_repeated(code : String) -> Bool {
  let id = input_key_id(code)
  if id < 0 {
    false
  } else {
    @windowing_native.input_is_key_repeated(id)
  }
}

///|
pub fn input_finish_frame() -> Unit {
  @windowing_native.input_finish_frame()
}

///|
pub fn input_is_mouse_button_down(button : String) -> Bool {
  let id = input_mouse_button_id(button)
  if id < 0 {
    false
  } else {
    @windowing_native.input_is_mouse_button_down(id)
  }
}

///|
pub fn input_is_mouse_button_just_pressed(button : String) -> Bool {
  let id = input_mouse_button_id(button)
  if id < 0 {
    false
  } else {
    @windowing_native.input_is_mouse_button_just_pressed(id)
  }
}

///|
pub fn input_is_mouse_button_just_released(button : String) -> Bool {
  let id = input_mouse_button_id(button)
  if id < 0 {
    false
  } else {
    @windowing_native.input_is_mouse_button_just_released(id)
  }
}

///|
pub fn input_mouse_x() -> Float {
  @windowing_native.input_mouse_x()
}

///|
pub fn input_mouse_y() -> Float {
  @windowing_native.input_mouse_y()
}

///|
pub fn input_has_cursor() -> Bool {
  @windowing_native.input_has_cursor()
}

///|
pub fn input_wheel_x() -> Float {
  @windowing_native.input_wheel_x()
}

///|
pub fn input_wheel_y() -> Float {
  @windowing_native.input_wheel_y()
}

///|
pub fn input_text_event_count() -> Int {
  @windowing_native.input_text_event_count()
}

///|
pub fn input_text_event_len(index~ : Int) -> Int {
  @windowing_native.input_text_event_len(index)
}

///|
pub fn input_text_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  @windowing_native.input_text_event_code_unit(index, offset)
}

///|
pub fn input_touch_event_count() -> Int {
  @windowing_native.input_touch_event_count()
}

///|
pub fn input_touch_event_id(index~ : Int) -> Int {
  @windowing_native.input_touch_event_id(index)
}

///|
pub fn input_touch_event_phase(index~ : Int) -> Int {
  @windowing_native.input_touch_event_phase(index)
}

///|
pub fn input_touch_event_x(index~ : Int) -> Float {
  @windowing_native.input_touch_event_x(index)
}

///|
pub fn input_touch_event_y(index~ : Int) -> Float {
  @windowing_native.input_touch_event_y(index)
}

///|
pub fn input_drag_and_drop_event_count() -> Int {
  @windowing_native.input_drag_and_drop_event_count()
}

///|
pub fn input_drag_and_drop_event_kind(index~ : Int) -> Int {
  @windowing_native.input_drag_and_drop_event_kind(index)
}

///|
pub fn input_drag_and_drop_event_len(index~ : Int) -> Int {
  @windowing_native.input_drag_and_drop_event_len(index)
}

///|
pub fn input_drag_and_drop_event_code_unit(index~ : Int, offset~ : Int) -> Int {
  @windowing_native.input_drag_and_drop_event_code_unit(index, offset)
}
