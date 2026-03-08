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
const DEFAULT_WINDOW_TITLE : String = "App"

///|
pub(all) struct PrimaryWindow {} derive(Eq, Show)

///|
pub(all) struct ClosingWindow {} derive(Eq, Show)

///|
pub(all) enum WindowRef {
  Primary
  Entity(@core.Entity)
} derive(Eq, ToJson, FromJson)

///|
pub(all) enum WindowPosition {
  Automatic
  At(Int, Int)
} derive(Eq, Show)

///|
pub fn WindowPosition::new(x : Int, y : Int) -> WindowPosition {
  At(x, y)
}

///|
pub(all) struct WindowResolution {
  mut physical_width : Int
  mut physical_height : Int
  mut scale_factor_override : Float?
  mut scale_factor : Float
} derive(Eq, Show)

///|
pub fn WindowResolution::default() -> WindowResolution {
  WindowResolution::{
    physical_width: 1280,
    physical_height: 720,
    scale_factor_override: None,
    scale_factor: 1.0F,
  }
}

///|
pub fn WindowResolution::new(
  physical_width : Int,
  physical_height : Int,
) -> WindowResolution {
  let resolution = WindowResolution::default()
  resolution.physical_width = if physical_width <= 0 {
    1
  } else {
    physical_width
  }
  resolution.physical_height = if physical_height <= 0 {
    1
  } else {
    physical_height
  }
  resolution
}

///|
pub fn WindowResolution::with_scale_factor_override(
  self : WindowResolution,
  scale_factor_override : Float,
) -> WindowResolution {
  let next = self
  next.set_scale_factor_override(Some(scale_factor_override))
  next
}

///|
pub fn WindowResolution::width(self : WindowResolution) -> Float {
  Float::from_int(self.physical_width()) / self.scale_factor()
}

///|
pub fn WindowResolution::height(self : WindowResolution) -> Float {
  Float::from_int(self.physical_height()) / self.scale_factor()
}

///|
pub fn WindowResolution::physical_width(self : WindowResolution) -> Int {
  self.physical_width
}

///|
pub fn WindowResolution::physical_height(self : WindowResolution) -> Int {
  self.physical_height
}

///|
pub fn WindowResolution::scale_factor(self : WindowResolution) -> Float {
  match self.scale_factor_override {
    Some(scale_factor_override) =>
      if scale_factor_override <= 0.0F {
        1.0F
      } else {
        scale_factor_override
      }
    None => self.base_scale_factor()
  }
}

///|
pub fn WindowResolution::base_scale_factor(self : WindowResolution) -> Float {
  if self.scale_factor <= 0.0F {
    1.0F
  } else {
    self.scale_factor
  }
}

///|
pub fn WindowResolution::scale_factor_override(
  self : WindowResolution,
) -> Float? {
  self.scale_factor_override
}

///|
pub fn WindowResolution::set(
  self : WindowResolution,
  width : Float,
  height : Float,
) -> Unit {
  self.set_physical_resolution(
    (width * self.scale_factor()).to_int(),
    (height * self.scale_factor()).to_int(),
  )
}

///|
pub fn WindowResolution::set_physical_resolution(
  self : WindowResolution,
  width : Int,
  height : Int,
) -> Unit {
  self.physical_width = if width <= 0 { 1 } else { width }
  self.physical_height = if height <= 0 { 1 } else { height }
}

///|
pub fn WindowResolution::set_scale_factor(
  self : WindowResolution,
  scale_factor : Float,
) -> Unit {
  self.scale_factor = if scale_factor <= 0.0F { 1.0F } else { scale_factor }
}

///|
pub fn WindowResolution::set_scale_factor_override(
  self : WindowResolution,
  scale_factor_override : Float?,
) -> Unit {
  self.scale_factor_override = scale_factor_override
}

///|
pub(all) struct CursorOptions {
  mut visible : Bool
  mut grab_mode : CursorGrabMode
  hit_test : Bool
} derive(Eq, Show)

///|
pub fn CursorOptions::default() -> CursorOptions {
  CursorOptions::{ visible: true, grab_mode: GrabNone, hit_test: true }
}

///|
pub(all) struct Window {
  mut title : String
  mut resolution : WindowResolution
  mut position : WindowPosition
  mut mode : WindowMode
  mut resizable : Bool
  mut focused : Bool
} derive(Eq, Show)

///|
pub fn Window::default() -> Window {
  Window::{
    title: DEFAULT_WINDOW_TITLE,
    resolution: WindowResolution::default(),
    position: Automatic,
    mode: Windowed,
    resizable: true,
    focused: true,
  }
}

///|
pub fn Window::width(self : Window) -> Float {
  self.resolution.width()
}

///|
pub fn Window::height(self : Window) -> Float {
  self.resolution.height()
}

///|
pub fn Window::physical_width(self : Window) -> Int {
  self.resolution.physical_width()
}

///|
pub fn Window::physical_height(self : Window) -> Int {
  self.resolution.physical_height()
}

///|
pub fn Window::scale_factor(self : Window) -> Float {
  self.resolution.scale_factor()
}

///|
pub(all) enum ExitCondition {
  OnPrimaryClosed
  OnAllClosed
  DontExit
} derive(Eq, Show)

///|
pub(all) struct WindowPlugin {
  primary_window : Window?
  primary_cursor_options : CursorOptions?
  exit_condition : ExitCondition
  close_when_requested : Bool
}

///|
pub const WINDOW_PLUGIN_ID : String = "bevy_window::WindowPlugin"

///|
pub fn WindowPlugin::default() -> WindowPlugin {
  WindowPlugin::{
    primary_window: Some(Window::default()),
    primary_cursor_options: Some(CursorOptions::default()),
    exit_condition: OnAllClosed,
    close_when_requested: true,
  }
}

///|
pub let ecs_key_window : @ecs.ComponentKey[Window] = @ecs.register_component(
  debug_name="bevy_window::Window",
)

///|
pub let ecs_key_primary_window : @ecs.ComponentKey[PrimaryWindow] = @ecs.register_component(
  debug_name="bevy_window::PrimaryWindow",
)

///|
pub let ecs_key_closing_window : @ecs.ComponentKey[ClosingWindow] = @ecs.register_component(
  debug_name="bevy_window::ClosingWindow",
)

///|
pub let ecs_key_cursor_options : @ecs.ComponentKey[CursorOptions] = @ecs.register_component(
  debug_name="bevy_window::CursorOptions",
)

///|
pub let ecs_key_cursor_icon : @ecs.ComponentKey[CursorIcon] = @ecs.register_component(
  debug_name="bevy_window::CursorIcon",
)

///|
pub impl @ecs.Component for Window with component() {
  ecs_key_window
}

///|
pub impl @ecs.Component for PrimaryWindow with component() {
  ecs_key_primary_window
}

///|
pub impl @ecs.Component for ClosingWindow with component() {
  ecs_key_closing_window
}

///|
pub impl @ecs.Component for CursorOptions with component() {
  ecs_key_cursor_options
}

///|
pub impl @ecs.Component for CursorIcon with component() {
  ecs_key_cursor_icon
}

///|
pub(all) struct WindowCreated {
  window : @core.Entity
} derive(Eq)

///|
pub(all) struct WindowCloseRequested {
  window : @core.Entity
} derive(Eq)

///|
pub(all) struct WindowClosing {
  window : @core.Entity
} derive(Eq)

///|
pub(all) struct WindowClosed {
  window : @core.Entity
} derive(Eq)

///|
pub(all) struct WindowMoved {
  window : @core.Entity
  x : Int
  y : Int
} derive(Eq)

///|
pub(all) struct WindowBackendScaleFactorChanged {
  window : @core.Entity
  scale_factor : Float
} derive(Eq)

///|
pub(all) struct WindowFocused {
  window : @core.Entity
  focused : Bool
} derive(Eq)

///|
pub let ecs_key_window_created : @ecs.MessageKey[WindowCreated] = @ecs.register_message(
  debug_name="bevy_window::WindowCreated",
)

///|
pub let ecs_key_window_close_requested : @ecs.MessageKey[WindowCloseRequested] = @ecs.register_message(
  debug_name="bevy_window::WindowCloseRequested",
)

///|
pub let ecs_key_window_closing : @ecs.MessageKey[WindowClosing] = @ecs.register_message(
  debug_name="bevy_window::WindowClosing",
)

///|
pub let ecs_key_window_closed : @ecs.MessageKey[WindowClosed] = @ecs.register_message(
  debug_name="bevy_window::WindowClosed",
)

///|
pub let ecs_key_window_moved : @ecs.MessageKey[WindowMoved] = @ecs.register_message(
  debug_name="bevy_window::WindowMoved",
)

///|
pub let ecs_key_window_backend_scale_factor_changed : @ecs.MessageKey[
  WindowBackendScaleFactorChanged,
] = @ecs.register_message(
  debug_name="bevy_window::WindowBackendScaleFactorChanged",
)

///|
pub let ecs_key_window_focused : @ecs.MessageKey[WindowFocused] = @ecs.register_message(
  debug_name="bevy_window::WindowFocused",
)

///|
pub impl @ecs.Message for WindowCreated with message() {
  ecs_key_window_created
}

///|
pub impl @ecs.Message for WindowCloseRequested with message() {
  ecs_key_window_close_requested
}

///|
pub impl @ecs.Message for WindowClosing with message() {
  ecs_key_window_closing
}

///|
pub impl @ecs.Message for WindowClosed with message() {
  ecs_key_window_closed
}

///|
pub impl @ecs.Message for WindowMoved with message() {
  ecs_key_window_moved
}

///|
pub impl @ecs.Message for WindowBackendScaleFactorChanged with message() {
  ecs_key_window_backend_scale_factor_changed
}

///|
pub impl @ecs.Message for WindowFocused with message() {
  ecs_key_window_focused
}
