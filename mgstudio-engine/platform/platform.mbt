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
/// Runtime implementation lives in `Milky2018/mgstudio/platform`.
/// `ensure_primary_host_window` still depends on `Milky2018/mgstudio/window`
/// runtime ECS ownership.

///|
pub type HostWindow = @windowing.NativeWindowHandle

///|
pub type HostEvent = @window.HostEvent

///|
pub(all) enum CursorGrabMode {
  GrabNone
  GrabConfined
  GrabLocked
} derive(Eq, Show)

///|
pub type SystemCursorIcon = @window_core.CursorIcon

///|
pub(all) enum CursorIcon {
  System(SystemCursorIcon)
} derive(Eq, Show)

///|
pub fn CursorIcon::from(icon : SystemCursorIcon) -> CursorIcon {
  System(icon)
}

///|
pub fn CursorIcon::as_system(self : CursorIcon) -> SystemCursorIcon? {
  match self {
    System(icon) => Some(icon)
  }
}

///|
pub impl Default for CursorIcon with default() {
  System(@window_core.CursorIcon::Default)
}

///|
pub(all) enum WindowMode {
  Windowed
  BorderlessFullscreen
  Fullscreen
} derive(Eq, Show)

///|
fn cursor_grab_mode_to_native(
  mode : CursorGrabMode,
) -> @window_core.CursorGrabMode {
  match mode {
    GrabNone => @window_core.CursorGrabMode::None
    GrabConfined => @window_core.CursorGrabMode::Confined
    GrabLocked => @window_core.CursorGrabMode::Locked
  }
}

///|
fn cursor_icon_to_native(icon : CursorIcon) -> @window_core.CursorIcon {
  match icon {
    System(system_icon) => system_icon
  }
}

///|
fn window_mode_to_fullscreen(mode : WindowMode) -> @window_core.Fullscreen? {
  match mode {
    Windowed => None
    BorderlessFullscreen => Some(@window_core.Fullscreen::Borderless(None))
    Fullscreen =>
      match @windowing.primary_monitor() {
        Some(monitor) =>
          match monitor.current_video_mode() {
            Some(video_mode) =>
              Some(@window_core.Fullscreen::Exclusive(monitor, video_mode))
            None => None
          }
        None => None
      }
  }
}

///|
pub fn debug_log(message~ : String) -> Unit {
  println(message)
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
  @windowing.create(
    logical_width~,
    logical_height~,
    physical_width~,
    physical_height~,
    use_physical_size_on_create~,
    title~,
    visible=true,
    resizable=true,
    decorations=true,
    panel=false,
  )
}

///|
pub fn poll_events(window : HostWindow) -> Unit {
  @windowing.poll_events(window)
}

///|
pub fn should_close(window : HostWindow) -> Bool {
  @windowing.should_close(window)
}

///|
pub fn request_close(window : HostWindow) -> Unit {
  @windowing.request_close(window)
}

///|
pub fn width(window : HostWindow) -> Int {
  @windowing.width(window)
}

///|
pub fn height(window : HostWindow) -> Int {
  @windowing.height(window)
}

///|
pub fn position_x(window : HostWindow) -> Int {
  @windowing.position_x(window)
}

///|
pub fn position_y(window : HostWindow) -> Int {
  @windowing.position_y(window)
}

///|
pub fn scale_factor(window : HostWindow) -> Float {
  @windowing.scale_factor(window)
}

///|
pub fn is_focused(window : HostWindow) -> Bool {
  @windowing.focused(window)
}

///|
pub fn set_title(window : HostWindow, title~ : String) -> Unit {
  @windowing.set_title(window, title~)
}

///|
pub fn set_size(window : HostWindow, width~ : Int, height~ : Int) -> Unit {
  @windowing.set_size(window, width~, height~)
}

///|
pub fn set_position(window : HostWindow, x~ : Int, y~ : Int) -> Unit {
  @windowing.set_position(window, x~, y~)
}

///|
pub fn set_mode(window : HostWindow, mode~ : WindowMode) -> Unit {
  @windowing.set_fullscreen(window, fullscreen=window_mode_to_fullscreen(mode))
}

///|
pub fn set_resizable(window : HostWindow, resizable~ : Bool) -> Unit {
  @windowing.set_resizable(window, resizable~)
}

///|
pub fn set_cursor_icon(window : HostWindow, icon~ : CursorIcon) -> Unit {
  @windowing.set_cursor_icon(window, icon=cursor_icon_to_native(icon))
}

///|
pub fn set_cursor_visible(window : HostWindow, visible~ : Bool) -> Unit {
  @windowing.set_cursor_visible(window, visible~)
}

///|
pub fn set_cursor_grab_mode(
  window : HostWindow,
  mode~ : CursorGrabMode,
) -> Unit {
  @windowing.set_cursor_grab_mode(window, mode=cursor_grab_mode_to_native(mode))
}

///|
pub fn ensure_primary_host_window(world : @ecs.World) -> HostWindow? {
  @window.window_ensure_primary_host(world)
}
