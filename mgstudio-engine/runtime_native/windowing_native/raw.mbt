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
#borrow(title)
pub extern "C" fn create_utf8(
  width : Int,
  height : Int,
  title : Bytes,
  title_len : UInt64,
) -> Int = "mgw_window_create_utf8"

///|
pub extern "C" fn poll_events(window : Int) -> Unit = "mgw_window_poll_events"

///|
pub extern "C" fn width(window : Int) -> Int = "mgw_window_width"

///|
pub extern "C" fn height(window : Int) -> Int = "mgw_window_height"

///|
pub extern "C" fn scale_factor(window : Int) -> Float = "mgw_window_scale_factor"

///|
pub extern "C" fn should_close(window : Int) -> Bool = "mgw_window_should_close"

///|
pub extern "C" fn request_close(window : Int) -> Unit = "mgw_window_request_close"

///|
pub extern "C" fn any_window_open() -> Bool = "mgw_window_any_open"

///|
#borrow(title)
pub extern "C" fn set_title_utf8(
  window : Int,
  title : Bytes,
  title_len : UInt64,
) -> Unit = "mgw_window_set_title_utf8"

///|
pub extern "C" fn set_size(window : Int, width : Int, height : Int) -> Unit = "mgw_window_set_size"

///|
pub extern "C" fn set_resizable(window : Int, resizable : Bool) -> Unit = "mgw_window_set_resizable"

///|
pub extern "C" fn set_cursor_visible(window : Int, visible : Bool) -> Unit = "mgw_window_set_cursor_visible"

///|
pub extern "C" fn set_cursor_grab_mode(window : Int, mode : Int) -> Unit = "mgw_window_set_cursor_grab_mode"

///|
pub extern "C" fn set_cursor_icon(window : Int, icon : Int) -> Unit = "mgw_window_set_cursor_icon"

///|
pub extern "C" fn set_mode(window : Int, mode : Int) -> Unit = "mgw_window_set_mode"

///|
pub extern "C" fn set_position(window : Int, x : Int, y : Int) -> Unit = "mgw_window_set_position"

///|
pub extern "C" fn position_x(window : Int) -> Int = "mgw_window_position_x"

///|
pub extern "C" fn position_y(window : Int) -> Int = "mgw_window_position_y"

///|
pub extern "C" fn attach_metal_layer(
  window : Int,
  layer : @wgpu_c.OpaquePtr,
) -> Unit = "mgw_window_attach_metal_layer"

///|
pub extern "C" fn native_backend_available() -> Bool = "mgw_window_native_backend_available"

///|
pub extern "C" fn input_finish_frame() -> Unit = "mgw_input_finish_frame"

///|
pub extern "C" fn input_has_cursor() -> Bool = "mgw_input_has_cursor"

///|
pub extern "C" fn input_mouse_x() -> Float = "mgw_input_mouse_x"

///|
pub extern "C" fn input_mouse_y() -> Float = "mgw_input_mouse_y"

///|
pub extern "C" fn input_wheel_x() -> Float = "mgw_input_wheel_x"

///|
pub extern "C" fn input_wheel_y() -> Float = "mgw_input_wheel_y"

///|
pub extern "C" fn input_is_key_down(key_id : Int) -> Bool = "mgw_input_is_key_down"

///|
pub extern "C" fn input_is_key_just_pressed(key_id : Int) -> Bool = "mgw_input_is_key_just_pressed"

///|
pub extern "C" fn input_is_key_just_released(key_id : Int) -> Bool = "mgw_input_is_key_just_released"

///|
pub extern "C" fn input_is_key_repeated(key_id : Int) -> Bool = "mgw_input_is_key_repeated"

///|
pub extern "C" fn input_is_mouse_button_down(button_id : Int) -> Bool = "mgw_input_is_mouse_button_down"

///|
pub extern "C" fn input_is_mouse_button_just_pressed(button_id : Int) -> Bool = "mgw_input_is_mouse_button_just_pressed"

///|
pub extern "C" fn input_is_mouse_button_just_released(button_id : Int) -> Bool = "mgw_input_is_mouse_button_just_released"

///|
pub extern "C" fn input_text_event_count() -> Int = "mgw_input_text_event_count"

///|
pub extern "C" fn input_text_event_len(index : Int) -> Int = "mgw_input_text_event_len"

///|
pub extern "C" fn input_text_event_code_unit(index : Int, offset : Int) -> Int = "mgw_input_text_event_code_unit"

///|
pub extern "C" fn input_touch_event_count() -> Int = "mgw_input_touch_event_count"

///|
pub extern "C" fn input_touch_event_id(index : Int) -> Int = "mgw_input_touch_event_id"

///|
pub extern "C" fn input_touch_event_phase(index : Int) -> Int = "mgw_input_touch_event_phase"

///|
pub extern "C" fn input_touch_event_x(index : Int) -> Float = "mgw_input_touch_event_x"

///|
pub extern "C" fn input_touch_event_y(index : Int) -> Float = "mgw_input_touch_event_y"

///|
pub extern "C" fn input_drag_and_drop_event_count() -> Int = "mgw_input_drag_and_drop_event_count"

///|
pub extern "C" fn input_drag_and_drop_event_kind(index : Int) -> Int = "mgw_input_drag_and_drop_event_kind"

///|
pub extern "C" fn input_drag_and_drop_event_len(index : Int) -> Int = "mgw_input_drag_and_drop_event_len"

///|
pub extern "C" fn input_drag_and_drop_event_code_unit(
  index : Int,
  offset : Int,
) -> Int = "mgw_input_drag_and_drop_event_code_unit"
