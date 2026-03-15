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
pub(all) struct VideoMode {
  physical_size : @math.UVec2
  bit_depth : Int
  refresh_rate_millihertz : Int
}

///|
pub fn VideoMode::new(
  physical_size : @math.UVec2,
  bit_depth : Int,
  refresh_rate_millihertz : Int,
) -> VideoMode {
  VideoMode::{ physical_size, bit_depth, refresh_rate_millihertz }
}

///|
pub(all) struct Monitor {
  name : String?
  physical_height : Int
  physical_width : Int
  physical_position : @math.IVec2
  refresh_rate_millihertz : Int?
  scale_factor : Double
  video_modes : Array[VideoMode]
}

///|
pub fn Monitor::physical_size(self : Monitor) -> @math.UVec2 {
  let width = if self.physical_width < 0 { 0 } else { self.physical_width }
  let height = if self.physical_height < 0 { 0 } else { self.physical_height }
  @math.UVec2::new(width, height)
}

///|
pub(all) struct PrimaryMonitor {} derive(Eq, Show)

///|
pub(all) enum WindowRef {
  Primary
  Entity(@core.Entity)
} derive(Eq, ToJson, FromJson)

///|
pub(all) enum WindowPosition {
  Automatic
  Centered(MonitorSelection)
  At(Int, Int)
} derive(Eq)

///|
pub fn WindowPosition::new(x : Int, y : Int) -> WindowPosition {
  At(x, y)
}

///|
pub fn WindowPosition::set(
  _self : WindowPosition,
  x : Int,
  y : Int,
) -> WindowPosition {
  WindowPosition::new(x, y)
}

///|
pub fn WindowPosition::center(
  _self : WindowPosition,
  monitor : MonitorSelection,
) -> WindowPosition {
  Centered(monitor)
}

///|
pub(all) struct WindowResizeConstraints {
  min_width : Float
  min_height : Float
  max_width : Float
  max_height : Float
} derive(Eq, Show)

///|
pub fn WindowResizeConstraints::default() -> WindowResizeConstraints {
  WindowResizeConstraints::{
    min_width: 180.0F,
    min_height: 120.0F,
    max_width: @float.infinity,
    max_height: @float.infinity,
  }
}

///|
pub fn WindowResizeConstraints::check_constraints(
  self : WindowResizeConstraints,
) -> WindowResizeConstraints {
  let min_width = if self.min_width < 1.0F { 1.0F } else { self.min_width }
  let min_height = if self.min_height < 1.0F { 1.0F } else { self.min_height }
  let max_width = if self.max_width < min_width {
    min_width
  } else {
    self.max_width
  }
  let max_height = if self.max_height < min_height {
    min_height
  } else {
    self.max_height
  }
  WindowResizeConstraints::{ min_width, min_height, max_width, max_height }
}

///|
pub(all) enum CompositeAlphaMode {
  Auto
  Opaque
  PreMultiplied
  PostMultiplied
  Inherit
} derive(Eq, Show)

///|
pub fn CompositeAlphaMode::default() -> CompositeAlphaMode {
  CompositeAlphaMode::Auto
}

///|
pub(all) enum ScreenEdge {
  None
  Top
  Left
  Bottom
  Right
  All
} derive(Eq, Show)

///|
pub fn ScreenEdge::default() -> ScreenEdge {
  ScreenEdge::None
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
  mut name : String?
  mut composite_alpha_mode : CompositeAlphaMode
  mut resize_constraints : WindowResizeConstraints
  mut canvas : String?
  mut resolution : WindowResolution
  mut present_mode : PresentMode
  mut position : WindowPosition
  mut mode : WindowMode
  mut resizable : Bool
  mut enabled_buttons : EnabledButtons
  mut decorations : Bool
  mut transparent : Bool
  mut focused : Bool
  mut window_level : WindowLevel
  mut fit_canvas_to_parent : Bool
  mut prevent_default_event_handling : Bool
  mut window_theme : WindowTheme?
  mut visible : Bool
  mut skip_taskbar : Bool
  mut clip_children : Bool
  mut desired_maximum_frame_latency : Int?
  mut recognize_pinch_gesture : Bool
  mut recognize_rotation_gesture : Bool
  mut recognize_doubletap_gesture : Bool
  mut recognize_pan_gesture : (Int, Int)?
  mut movable_by_window_background : Bool
  mut fullsize_content_view : Bool
  mut has_shadow : Bool
  mut titlebar_shown : Bool
  mut titlebar_transparent : Bool
  mut titlebar_show_title : Bool
  mut titlebar_show_buttons : Bool
  mut borderless_game : Bool
  mut prefers_home_indicator_hidden : Bool
  mut prefers_status_bar_hidden : Bool
  mut preferred_screen_edges_deferring_system_gestures : ScreenEdge
  mut ime_enabled : Bool
  mut ime_position : @math.Vec2
  mut maximize_request : Bool?
  mut minimize_request : Bool?
  mut drag_move_request : Bool
  mut drag_resize_request : @math.CompassOctant?
}

///|
pub fn Window::default() -> Window {
  Window::{
    title: DEFAULT_WINDOW_TITLE,
    name: None,
    composite_alpha_mode: CompositeAlphaMode::default(),
    resize_constraints: WindowResizeConstraints::default(),
    canvas: None,
    resolution: WindowResolution::default(),
    present_mode: PresentMode::Fifo,
    position: Automatic,
    mode: Windowed,
    resizable: true,
    enabled_buttons: EnabledButtons::default(),
    decorations: true,
    transparent: false,
    focused: true,
    window_level: WindowLevel::Normal,
    fit_canvas_to_parent: false,
    prevent_default_event_handling: true,
    window_theme: None,
    visible: true,
    skip_taskbar: false,
    clip_children: true,
    desired_maximum_frame_latency: None,
    recognize_pinch_gesture: false,
    recognize_rotation_gesture: false,
    recognize_doubletap_gesture: false,
    recognize_pan_gesture: None,
    movable_by_window_background: false,
    fullsize_content_view: false,
    has_shadow: true,
    titlebar_shown: true,
    titlebar_transparent: false,
    titlebar_show_title: true,
    titlebar_show_buttons: true,
    borderless_game: true,
    prefers_home_indicator_hidden: false,
    prefers_status_bar_hidden: false,
    preferred_screen_edges_deferring_system_gestures: ScreenEdge::default(),
    ime_enabled: false,
    ime_position: @math.Vec2::new(0.0F, 0.0F),
    maximize_request: None,
    minimize_request: None,
    drag_move_request: false,
    drag_resize_request: None,
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
pub fn Window::start_drag_move(self : Window) -> Unit {
  self.drag_move_request = true
}

///|
pub fn Window::start_drag_resize(
  self : Window,
  direction : @math.CompassOctant,
) -> Unit {
  self.drag_resize_request = Some(direction)
}

///|
pub fn Window::set_maximized(self : Window, maximized : Bool) -> Unit {
  self.maximize_request = Some(maximized)
}

///|
pub fn Window::set_minimized(self : Window, minimized : Bool) -> Unit {
  self.minimize_request = Some(minimized)
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
pub let ecs_key_monitor : @ecs.ComponentKey[Monitor] = @ecs.register_component(
  debug_name="bevy_window::Monitor",
)

///|
pub let ecs_key_primary_monitor : @ecs.ComponentKey[PrimaryMonitor] = @ecs.register_component(
  debug_name="bevy_window::PrimaryMonitor",
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
pub impl @ecs.Component for Monitor with component() {
  ecs_key_monitor
}

///|
pub impl @ecs.Component for PrimaryMonitor with component() {
  ecs_key_primary_monitor
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
pub(all) struct RequestRedraw {} derive(Eq)

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
