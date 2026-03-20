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
pub(all) struct RequestRedraw {} derive(Eq)

///|
pub(all) struct WindowResized {
  window : @core.Entity
  width : Float
  height : Float
} derive(Eq)

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
pub(all) struct WindowDestroyed {
  window : @core.Entity
} derive(Eq)

///|
pub(all) struct CursorMoved {
  window : @core.Entity
  position : @math.Vec2
  delta : @math.Vec2?
}

///|
pub(all) struct CursorEntered {
  window : @core.Entity
} derive(Eq)

///|
pub(all) struct CursorLeft {
  window : @core.Entity
} derive(Eq)

///|
pub(all) enum FileDragAndDrop {
  DroppedFile(@core.Entity, String)
  HoveredFile(@core.Entity, String)
  HoveredFileCanceled(@core.Entity)
} derive(Eq)

///|
pub(all) struct WindowMoved {
  window : @core.Entity
  x : Int
  y : Int
} derive(Eq)

///|
pub(all) struct WindowScaleFactorChanged {
  window : @core.Entity
  scale_factor : Float
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
pub(all) struct WindowOccluded {
  window : @core.Entity
  occluded : Bool
} derive(Eq)

///|
pub(all) struct WindowThemeChanged {
  window : @core.Entity
  theme : WindowTheme
} derive(Eq)

///|
pub(all) enum AppLifecycle {
  Idle
  Running
  WillSuspend
  Suspended
  WillResume
} derive(Eq, Show)

///|
pub fn AppLifecycle::is_active(self : AppLifecycle) -> Bool {
  match self {
    Idle | Suspended => false
    Running | WillSuspend | WillResume => true
  }
}

///|
pub(all) struct ImeCursorRange {
  start : Int
  end : Int
} derive(Eq, Show)

///|
pub fn ImeCursorRange::new(start : Int, end : Int) -> ImeCursorRange {
  ImeCursorRange::{ start, end }
}

///|
pub(all) enum Ime {
  Enabled(@core.Entity)
  Preedit(@core.Entity, String, ImeCursorRange?)
  Commit(@core.Entity, String)
  Disabled(@core.Entity)
  DeleteSurrounding(@core.Entity, Int, Int)
} derive(Eq)

///|
pub type ButtonState = @input_events.ButtonState

///|
pub type Key = @input_events.Key

///|
pub type MouseScrollUnit = @input_events.MouseScrollUnit

///|
pub type TouchPhase = @input_events.TouchPhase

///|
pub type KeyboardInput = @input_events.KeyboardInput

///|
pub type KeyboardFocusLost = @input_events.KeyboardFocusLost

///|
pub type MouseButtonInput = @input_events.MouseButtonInput

///|
pub type MouseMotion = @input_events.MouseMotion

///|
pub type MouseWheel = @input_events.MouseWheel

///|
pub type PinchGesture = @input_events.PinchGesture

///|
pub type RotationGesture = @input_events.RotationGesture

///|
pub type DoubleTapGesture = @input_events.DoubleTapGesture

///|
pub type PanGesture = @input_events.PanGesture

///|
pub type TouchInput = @input_events.TouchInput

///|
pub(all) enum WindowEvent {
  AppLifecycle(AppLifecycle)
  CursorEntered(CursorEntered)
  CursorLeft(CursorLeft)
  CursorMoved(CursorMoved)
  FileDragAndDrop(FileDragAndDrop)
  Ime(Ime)
  RequestRedraw(RequestRedraw)
  WindowBackendScaleFactorChanged(WindowBackendScaleFactorChanged)
  WindowCloseRequested(WindowCloseRequested)
  WindowCreated(WindowCreated)
  WindowDestroyed(WindowDestroyed)
  WindowFocused(WindowFocused)
  WindowMoved(WindowMoved)
  WindowOccluded(WindowOccluded)
  WindowResized(WindowResized)
  WindowScaleFactorChanged(WindowScaleFactorChanged)
  WindowThemeChanged(WindowThemeChanged)
  MouseButtonInput(MouseButtonInput)
  MouseMotion(MouseMotion)
  MouseWheel(MouseWheel)
  PinchGesture(PinchGesture)
  RotationGesture(RotationGesture)
  DoubleTapGesture(DoubleTapGesture)
  PanGesture(PanGesture)
  TouchInput(TouchInput)
  KeyboardInput(KeyboardInput)
  KeyboardFocusLost(KeyboardFocusLost)
}

///|
pub let ecs_key_window_created : @ecs.MessageKey[WindowCreated] = @ecs.register_message(
  debug_name="bevy_window::WindowCreated",
)

///|
pub let ecs_key_window_resized : @ecs.MessageKey[WindowResized] = @ecs.register_message(
  debug_name="bevy_window::WindowResized",
)

///|
pub let ecs_key_request_redraw : @ecs.MessageKey[RequestRedraw] = @ecs.register_message(
  debug_name="bevy_window::RequestRedraw",
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
pub let ecs_key_window_destroyed : @ecs.MessageKey[WindowDestroyed] = @ecs.register_message(
  debug_name="bevy_window::WindowDestroyed",
)

///|
pub let ecs_key_cursor_moved : @ecs.MessageKey[CursorMoved] = @ecs.register_message(
  debug_name="bevy_window::CursorMoved",
)

///|
pub let ecs_key_cursor_entered : @ecs.MessageKey[CursorEntered] = @ecs.register_message(
  debug_name="bevy_window::CursorEntered",
)

///|
pub let ecs_key_cursor_left : @ecs.MessageKey[CursorLeft] = @ecs.register_message(
  debug_name="bevy_window::CursorLeft",
)

///|
pub let ecs_key_file_drag_and_drop : @ecs.MessageKey[FileDragAndDrop] = @ecs.register_message(
  debug_name="bevy_window::FileDragAndDrop",
)

///|
pub let ecs_key_window_event : @ecs.MessageKey[WindowEvent] = @ecs.register_message(
  debug_name="bevy_window::WindowEvent",
)

///|
pub let ecs_key_window_moved : @ecs.MessageKey[WindowMoved] = @ecs.register_message(
  debug_name="bevy_window::WindowMoved",
)

///|
pub let ecs_key_window_scale_factor_changed : @ecs.MessageKey[
  WindowScaleFactorChanged,
] = @ecs.register_message(debug_name="bevy_window::WindowScaleFactorChanged")

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
pub let ecs_key_window_occluded : @ecs.MessageKey[WindowOccluded] = @ecs.register_message(
  debug_name="bevy_window::WindowOccluded",
)

///|
pub let ecs_key_window_theme_changed : @ecs.MessageKey[WindowThemeChanged] = @ecs.register_message(
  debug_name="bevy_window::WindowThemeChanged",
)

///|
pub let ecs_key_app_lifecycle : @ecs.MessageKey[AppLifecycle] = @ecs.register_message(
  debug_name="bevy_window::AppLifecycle",
)

///|
pub let ecs_key_ime : @ecs.MessageKey[Ime] = @ecs.register_message(
  debug_name="bevy_window::Ime",
)

///|
pub let ecs_key_keyboard_input : @ecs.MessageKey[KeyboardInput] = @input_events.ecs_key_keyboard_input

///|
pub let ecs_key_keyboard_focus_lost : @ecs.MessageKey[KeyboardFocusLost] = @input_events.ecs_key_keyboard_focus_lost

///|
pub let ecs_key_mouse_button_input : @ecs.MessageKey[MouseButtonInput] = @input_events.ecs_key_mouse_button_input

///|
pub let ecs_key_mouse_motion : @ecs.MessageKey[MouseMotion] = @input_events.ecs_key_mouse_motion

///|
pub let ecs_key_mouse_wheel : @ecs.MessageKey[MouseWheel] = @input_events.ecs_key_mouse_wheel

///|
pub let ecs_key_pinch_gesture : @ecs.MessageKey[PinchGesture] = @input_events.ecs_key_pinch_gesture

///|
pub let ecs_key_rotation_gesture : @ecs.MessageKey[RotationGesture] = @input_events.ecs_key_rotation_gesture

///|
pub let ecs_key_double_tap_gesture : @ecs.MessageKey[DoubleTapGesture] = @input_events.ecs_key_double_tap_gesture

///|
pub let ecs_key_pan_gesture : @ecs.MessageKey[PanGesture] = @input_events.ecs_key_pan_gesture

///|
pub let ecs_key_touch_input : @ecs.MessageKey[TouchInput] = @input_events.ecs_key_touch_input

///|
pub impl @ecs.Message for WindowCreated with message() {
  ecs_key_window_created
}

///|
pub impl @ecs.Message for WindowResized with message() {
  ecs_key_window_resized
}

///|
pub impl @ecs.Message for RequestRedraw with message() {
  ecs_key_request_redraw
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
pub impl @ecs.Message for WindowDestroyed with message() {
  ecs_key_window_destroyed
}

///|
pub impl @ecs.Message for CursorMoved with message() {
  ecs_key_cursor_moved
}

///|
pub impl @ecs.Message for CursorEntered with message() {
  ecs_key_cursor_entered
}

///|
pub impl @ecs.Message for CursorLeft with message() {
  ecs_key_cursor_left
}

///|
pub impl @ecs.Message for FileDragAndDrop with message() {
  ecs_key_file_drag_and_drop
}

///|
pub impl @ecs.Message for WindowEvent with message() {
  ecs_key_window_event
}

///|
pub impl @ecs.Message for WindowMoved with message() {
  ecs_key_window_moved
}

///|
pub impl @ecs.Message for WindowScaleFactorChanged with message() {
  ecs_key_window_scale_factor_changed
}

///|
pub impl @ecs.Message for WindowBackendScaleFactorChanged with message() {
  ecs_key_window_backend_scale_factor_changed
}

///|
pub impl @ecs.Message for WindowFocused with message() {
  ecs_key_window_focused
}

///|
pub impl @ecs.Message for WindowOccluded with message() {
  ecs_key_window_occluded
}

///|
pub impl @ecs.Message for WindowThemeChanged with message() {
  ecs_key_window_theme_changed
}

///|
pub impl @ecs.Message for AppLifecycle with message() {
  ecs_key_app_lifecycle
}

///|
pub impl @ecs.Message for Ime with message() {
  ecs_key_ime
}
