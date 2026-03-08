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
pub type NativeWindow = Int

///|
pub fn create(width~ : Int, height~ : Int, title~ : String) -> NativeWindow {
  @windowing.create(width~, height~, title~)
}

///|
pub fn poll_events(window : NativeWindow) -> Unit {
  @windowing.poll_events(window)
}

///|
pub fn width(window : NativeWindow) -> Int {
  @windowing.width(window)
}

///|
pub fn height(window : NativeWindow) -> Int {
  @windowing.height(window)
}

///|
pub fn scale_factor(window : NativeWindow) -> Float {
  @windowing.scale_factor(window)
}

///|
pub fn focused(window : NativeWindow) -> Bool {
  @windowing.focused(window)
}

///|
pub fn should_close(window : NativeWindow) -> Bool {
  @windowing.should_close(window)
}

///|
pub fn request_close(window : NativeWindow) -> Unit {
  @windowing.request_close(window)
}

///|
pub fn run_loop(step : FuncRef[() -> Unit]) -> Unit {
  @windowing.run_loop(step)
}

///|
pub fn set_title(window : NativeWindow, title~ : String) -> Unit {
  @windowing.set_title(window, title~)
}

///|
pub fn set_size(window : NativeWindow, width~ : Int, height~ : Int) -> Unit {
  @windowing.set_size(window, width~, height~)
}

///|
pub fn set_resizable(window : NativeWindow, resizable~ : Bool) -> Unit {
  @windowing.set_resizable(window, resizable~)
}

///|
pub fn set_cursor_visible(window : NativeWindow, visible~ : Bool) -> Unit {
  @windowing.set_cursor_visible(window, visible~)
}

///|
pub fn set_cursor_grab_mode(window : NativeWindow, mode~ : Int) -> Unit {
  @windowing.set_cursor_grab_mode(window, mode~)
}

///|
pub fn set_cursor_icon(window : NativeWindow, icon~ : Int) -> Unit {
  @windowing.set_cursor_icon(window, icon~)
}

///|
pub fn set_mode(window : NativeWindow, mode~ : Int) -> Unit {
  @windowing.set_mode(window, mode~)
}

///|
pub fn set_position(window : NativeWindow, x~ : Int, y~ : Int) -> Unit {
  @windowing.set_position(window, x~, y~)
}

///|
pub fn position_x(window : NativeWindow) -> Int {
  @windowing.position_x(window)
}

///|
pub fn position_y(window : NativeWindow) -> Int {
  @windowing.position_y(window)
}
