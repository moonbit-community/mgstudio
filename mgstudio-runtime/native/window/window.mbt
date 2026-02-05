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
/// Lightweight native window helper.
///
/// Currently implemented for macOS via a small C stub that drives Cocoa through
/// libobjc message sending (similar to wgpu-mbt's CAMetalLayer helper).
///
/// This package intentionally keeps the API minimal: create a window, pump its
/// event queue, query size/scale, and attach a CAMetalLayer.

///|
pub struct Window {
  raw : @wgpu_c.OpaquePtr
}

///|
pub fn Window::is_null(self : Window) -> Bool {
  c_window_is_null(self.raw)
}

///|
pub fn Window::create(width : Int, height : Int, title : String) -> Window {
  let title_cstr = string_to_utf8_cstr(title)
  Window::{ raw: c_window_create(width, height, title_cstr) }
}

///|
pub fn Window::poll_events(self : Window) -> Unit {
  c_window_poll_events(self.raw)
}

///|
pub fn Window::width(self : Window) -> Int {
  c_window_width(self.raw)
}

///|
pub fn Window::height(self : Window) -> Int {
  c_window_height(self.raw)
}

///|
pub fn Window::scale_factor(self : Window) -> Float {
  c_window_scale_factor(self.raw)
}

///|
pub fn Window::should_close(self : Window) -> Bool {
  c_window_should_close(self.raw)
}

///|
pub fn Window::request_close(self : Window) -> Unit {
  c_window_request_close(self.raw)
}

///|
pub fn Window::attach_metal_layer(
  self : Window,
  layer : @wgpu_c.OpaquePtr,
) -> Unit {
  c_window_attach_metal_layer(self.raw, layer)
}

///|
pub fn Window::destroy(self : Window) -> Unit {
  c_window_destroy(self.raw)
}

///|
/// Input: clear "just pressed/released" states for the next frame.
pub fn Window::input_finish_frame(self : Window) -> Unit {
  c_input_finish_frame(self.raw)
}

///|
pub fn Window::input_has_cursor(self : Window) -> Bool {
  c_input_has_cursor(self.raw)
}

///|
pub fn Window::input_mouse_x(self : Window) -> Float {
  c_input_mouse_x(self.raw)
}

///|
pub fn Window::input_mouse_y(self : Window) -> Float {
  c_input_mouse_y(self.raw)
}

///|
pub fn Window::input_wheel_x(self : Window) -> Float {
  c_input_wheel_x(self.raw)
}

///|
pub fn Window::input_wheel_y(self : Window) -> Float {
  c_input_wheel_y(self.raw)
}

///|
pub fn Window::input_is_key_down(self : Window, code : Int) -> Bool {
  c_input_is_key_down(self.raw, code)
}

///|
pub fn Window::input_is_key_just_pressed(self : Window, code : Int) -> Bool {
  c_input_is_key_just_pressed(self.raw, code)
}

///|
pub fn Window::input_is_key_just_released(self : Window, code : Int) -> Bool {
  c_input_is_key_just_released(self.raw, code)
}

///|
pub fn Window::input_is_mouse_button_down(self : Window, button : Int) -> Bool {
  c_input_is_mouse_button_down(self.raw, button)
}

///|
pub fn Window::input_is_mouse_button_just_pressed(
  self : Window,
  button : Int,
) -> Bool {
  c_input_is_mouse_button_just_pressed(self.raw, button)
}

///|
pub fn Window::input_is_mouse_button_just_released(
  self : Window,
  button : Int,
) -> Bool {
  c_input_is_mouse_button_just_released(self.raw, button)
}

///|
/// A11y: Begin an accessibility tree update.
pub fn Window::a11y_begin_update(self : Window, root_id : Int) -> Unit {
  c_a11y_begin_update(self.raw, root_id)
}

///|
/// A11y: Push one node (flat list with a parent id) to the host bridge.
pub fn Window::a11y_push_node(
  self : Window,
  node_id : Int,
  parent_id : Int,
  role_id : Int,
  x : Float,
  y : Float,
  width : Float,
  height : Float,
  name : String,
  actions_mask : Int,
) -> Unit {
  let name_cstr = string_to_utf8_cstr(name)
  c_a11y_push_node(
    self.raw,
    node_id,
    parent_id,
    role_id,
    x,
    y,
    width,
    height,
    name_cstr,
    actions_mask,
  )
}

///|
/// A11y: Finish a full-tree update.
pub fn Window::a11y_end_update(self : Window) -> Unit {
  c_a11y_end_update(self.raw)
}

///|
pub fn Window::a11y_actions_len(self : Window) -> Int {
  self |> ignore
  c_a11y_actions_len()
}

///|
pub fn Window::a11y_action_target(self : Window, index : Int) -> Int {
  self |> ignore
  c_a11y_action_target(index)
}

///|
pub fn Window::a11y_action_kind(self : Window, index : Int) -> Int {
  self |> ignore
  c_a11y_action_kind(index)
}

///|
pub fn Window::a11y_actions_clear(self : Window) -> Unit {
  self |> ignore
  c_a11y_actions_clear()
}

///|
#borrow(_title)
extern "C" fn c_window_create(
  width : Int,
  height : Int,
  _title : Bytes,
) -> @wgpu_c.OpaquePtr = "mgw_window_create"

///|
extern "C" fn c_window_is_null(win : @wgpu_c.OpaquePtr) -> Bool = "mgw_window_is_null"

///|
extern "C" fn c_window_destroy(win : @wgpu_c.OpaquePtr) -> Unit = "mgw_window_destroy"

///|
extern "C" fn c_window_poll_events(win : @wgpu_c.OpaquePtr) -> Unit = "mgw_window_poll_events"

///|
extern "C" fn c_window_width(win : @wgpu_c.OpaquePtr) -> Int = "mgw_window_width"

///|
extern "C" fn c_window_height(win : @wgpu_c.OpaquePtr) -> Int = "mgw_window_height"

///|
extern "C" fn c_window_scale_factor(win : @wgpu_c.OpaquePtr) -> Float = "mgw_window_scale_factor"

///|
extern "C" fn c_window_should_close(win : @wgpu_c.OpaquePtr) -> Bool = "mgw_window_should_close"

///|
extern "C" fn c_window_request_close(win : @wgpu_c.OpaquePtr) -> Unit = "mgw_window_request_close"

///|
extern "C" fn c_window_attach_metal_layer(
  win : @wgpu_c.OpaquePtr,
  layer : @wgpu_c.OpaquePtr,
) -> Unit = "mgw_window_attach_metal_layer"

///|
extern "C" fn c_input_finish_frame(win : @wgpu_c.OpaquePtr) -> Unit = "mgw_input_finish_frame"

///|
extern "C" fn c_input_has_cursor(win : @wgpu_c.OpaquePtr) -> Bool = "mgw_input_has_cursor"

///|
extern "C" fn c_input_mouse_x(win : @wgpu_c.OpaquePtr) -> Float = "mgw_input_mouse_x"

///|
extern "C" fn c_input_mouse_y(win : @wgpu_c.OpaquePtr) -> Float = "mgw_input_mouse_y"

///|
extern "C" fn c_input_wheel_x(win : @wgpu_c.OpaquePtr) -> Float = "mgw_input_wheel_x"

///|
extern "C" fn c_input_wheel_y(win : @wgpu_c.OpaquePtr) -> Float = "mgw_input_wheel_y"

///|
extern "C" fn c_input_is_key_down(win : @wgpu_c.OpaquePtr, code : Int) -> Bool = "mgw_input_is_key_down"

///|
extern "C" fn c_input_is_key_just_pressed(
  win : @wgpu_c.OpaquePtr,
  code : Int,
) -> Bool = "mgw_input_is_key_just_pressed"

///|
extern "C" fn c_input_is_key_just_released(
  win : @wgpu_c.OpaquePtr,
  code : Int,
) -> Bool = "mgw_input_is_key_just_released"

///|
extern "C" fn c_input_is_mouse_button_down(
  win : @wgpu_c.OpaquePtr,
  button : Int,
) -> Bool = "mgw_input_is_mouse_button_down"

///|
extern "C" fn c_input_is_mouse_button_just_pressed(
  win : @wgpu_c.OpaquePtr,
  button : Int,
) -> Bool = "mgw_input_is_mouse_button_just_pressed"

///|
extern "C" fn c_input_is_mouse_button_just_released(
  win : @wgpu_c.OpaquePtr,
  button : Int,
) -> Bool = "mgw_input_is_mouse_button_just_released"

///|
extern "C" fn c_a11y_begin_update(
  win : @wgpu_c.OpaquePtr,
  root_id : Int,
) -> Unit = "mgw_a11y_begin_update"

///|
#borrow(_name)
extern "C" fn c_a11y_push_node(
  win : @wgpu_c.OpaquePtr,
  node_id : Int,
  parent_id : Int,
  role_id : Int,
  x : Float,
  y : Float,
  width : Float,
  height : Float,
  _name : Bytes,
  actions_mask : Int,
) -> Unit = "mgw_a11y_push_node"

///|
extern "C" fn c_a11y_end_update(win : @wgpu_c.OpaquePtr) -> Unit = "mgw_a11y_end_update"

///|
extern "C" fn c_a11y_actions_len() -> Int = "mgw_a11y_actions_len"

///|
extern "C" fn c_a11y_action_target(index : Int) -> Int = "mgw_a11y_action_target"

///|
extern "C" fn c_a11y_action_kind(index : Int) -> Int = "mgw_a11y_action_kind"

///|
extern "C" fn c_a11y_actions_clear() -> Unit = "mgw_a11y_actions_clear"

///|
/// Encode a MoonBit `String` to a UTF-8 byte buffer terminated with `\0`.
///
/// This is intentionally self-contained because `moonbitlang/x/internal/*`
/// packages are not importable from non-internal modules.
fn string_to_utf8_cstr(str : String) -> Bytes {
  let out : Array[Byte] = []
  let len = str.length()
  let mut i = 0
  while i < len {
    let mut c = str.code_unit_at(i).to_int()
    if 0xD800 <= c && c <= 0xDBFF {
      c -= 0xD800
      i = i + 1
      let l = str.code_unit_at(i).to_int() - 0xDC00
      c = (c << 10) + l + 0x10000
    }
    if c < 0x80 {
      out.push(c.to_byte())
    } else if c < 0x800 {
      out.push((0xC0 + (c >> 6)).to_byte())
      out.push((0x80 + (c & 0x3F)).to_byte())
    } else if c < 0x10000 {
      out.push((0xE0 + (c >> 12)).to_byte())
      out.push((0x80 + ((c >> 6) & 0x3F)).to_byte())
      out.push((0x80 + (c & 0x3F)).to_byte())
    } else {
      out.push((0xF0 + (c >> 18)).to_byte())
      out.push((0x80 + ((c >> 12) & 0x3F)).to_byte())
      out.push((0x80 + ((c >> 6) & 0x3F)).to_byte())
      out.push((0x80 + (c & 0x3F)).to_byte())
    }
    i = i + 1
  }
  out.push((0).to_byte())
  Bytes::from_array(out)
}
