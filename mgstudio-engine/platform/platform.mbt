// Copyright 2026 International Digital Economy Academy
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
/// Platform-facing host window API boundary aligned with Bevy-style platform responsibilities.
/// Runtime implementation currently lives in `Milky2018/mgstudio/window`.

///|
pub type HostWindow = @window.HostWindow

///|
pub type HostEvent = @window.HostEvent

///|
pub type CursorGrabMode = @window.CursorGrabMode

///|
pub type CursorIcon = @window.CursorIcon

///|
pub type WindowMode = @window.WindowMode

///|
pub fn debug_log(message~ : String) -> Unit {
  @window.host_debug_string(value=message)
}

///|
pub fn create_window(
  logical_width~ : Int,
  logical_height~ : Int,
  physical_width~ : Int,
  physical_height~ : Int,
  use_physical_size_on_create~ : Bool,
  title~ : String,
) -> HostWindow {
  @window.host_window_create(
    logical_width~,
    logical_height~,
    physical_width~,
    physical_height~,
    use_physical_size_on_create~,
    title~,
  )
}

///|
pub fn run_loop(callback : FuncRef[() -> Unit]) -> Unit {
  @window.host_window_run_loop(callback)
}

///|
pub fn poll_events(window : HostWindow) -> Unit {
  @window.host_window_poll_events(window)
}

///|
pub fn should_close(window : HostWindow) -> Bool {
  @window.host_window_should_close(window)
}

///|
pub fn request_close(window : HostWindow) -> Unit {
  @window.host_window_request_close(window)
}

///|
pub fn width(window : HostWindow) -> Int {
  @window.host_window_get_width(window)
}

///|
pub fn height(window : HostWindow) -> Int {
  @window.host_window_get_height(window)
}

///|
pub fn position_x(window : HostWindow) -> Int {
  @window.host_window_get_position_x(window)
}

///|
pub fn position_y(window : HostWindow) -> Int {
  @window.host_window_get_position_y(window)
}

///|
pub fn scale_factor(window : HostWindow) -> Float {
  @window.host_window_get_scale_factor(window)
}

///|
pub fn is_focused(window : HostWindow) -> Bool {
  @window.host_window_get_focused(window)
}

///|
pub fn set_title(window : HostWindow, title~ : String) -> Unit {
  @window.host_window_set_title(window, title~)
}

///|
pub fn set_size(window : HostWindow, width~ : Int, height~ : Int) -> Unit {
  @window.host_window_set_size(window, width~, height~)
}

///|
pub fn set_position(window : HostWindow, x~ : Int, y~ : Int) -> Unit {
  @window.host_window_set_position(window, x~, y~)
}

///|
pub fn set_mode(window : HostWindow, mode~ : WindowMode) -> Unit {
  @window.host_window_set_mode(window, mode~)
}

///|
pub fn set_resizable(window : HostWindow, resizable~ : Bool) -> Unit {
  @window.host_window_set_resizable(window, resizable~)
}

///|
pub fn set_cursor_icon(window : HostWindow, icon~ : CursorIcon) -> Unit {
  @window.host_window_set_cursor_icon(window, icon~)
}

///|
pub fn set_cursor_visible(window : HostWindow, visible~ : Bool) -> Unit {
  @window.host_window_set_cursor_visible(window, visible~)
}

///|
pub fn set_cursor_grab_mode(
  window : HostWindow,
  mode~ : CursorGrabMode,
) -> Unit {
  @window.host_window_set_cursor_grab_mode(window, mode~)
}

///|
pub fn ensure_primary_host_window(world : @ecs.World) -> HostWindow? {
  @window.window_ensure_primary_host(world)
}
