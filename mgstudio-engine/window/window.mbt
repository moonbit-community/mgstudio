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
pub type HostWindow = Int

///|
pub type KeyCode = @input_events.KeyCode

///|
pub type MouseButton = @input_events.MouseButton

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
pub(all) enum PresentMode {
  AutoVsync
  AutoNoVsync
  Fifo
  FifoRelaxed
  Immediate
  Mailbox
} derive(Eq, Show)

///|
pub type WindowLevel = @window_core.WindowLevel

///|
pub type WindowTheme = @window_core.Theme

///|
pub(all) struct EnabledButtons {
  mut minimize : Bool
  mut maximize : Bool
  mut close : Bool
} derive(Eq, Show)

///|
pub fn EnabledButtons::default() -> EnabledButtons {
  EnabledButtons::{ minimize: true, maximize: true, close: true }
}

///|
pub(all) enum HostEvent {
  KeyDown(KeyCode)
  KeyUp(KeyCode)
  MouseMove(Int, Int)
  MouseDown(MouseButton)
  MouseUp(MouseButton)
  MouseWheel(Int, Int)
  WindowResized(Int, Int)
  WindowCloseRequested
}

///|
pub(all) struct WindowResized {
  window : @core.Entity
  width : Float
  height : Float
} derive(Eq)

///|
pub let ecs_key_window_resized : @ecs.MessageKey[WindowResized] = @ecs.register_message(
  debug_name="bevy_window::WindowResized",
)

///|
pub impl @ecs.Message for WindowResized with message() {
  ecs_key_window_resized
}

///|
pub fn host_window_create(
  logical_width~ : Int,
  logical_height~ : Int,
  physical_width~ : Int,
  physical_height~ : Int,
  use_physical_size_on_create~ : Bool,
  title~ : String,
  visible? : Bool = true,
  resizable? : Bool = true,
  decorations? : Bool = true,
  panel? : Bool = false,
) -> HostWindow {
  @windowing.create(
    logical_width~,
    logical_height~,
    physical_width~,
    physical_height~,
    use_physical_size_on_create~,
    title~,
    visible~,
    resizable~,
    decorations~,
    panel~,
  )
}

///|
pub fn host_window_poll_events(window : HostWindow) -> Unit {
  @windowing.poll_events(window)
}

///|
pub fn host_window_get_width(window : HostWindow) -> Int {
  @windowing.width(window)
}

///|
pub fn host_window_get_height(window : HostWindow) -> Int {
  @windowing.height(window)
}

///|
pub fn host_window_get_scale_factor(window : HostWindow) -> Float {
  @windowing.scale_factor(window)
}

///|
pub fn host_window_get_focused(window : HostWindow) -> Bool {
  @windowing.focused(window)
}

///|
pub fn host_window_should_close(window : HostWindow) -> Bool {
  @windowing.should_close(window)
}

///|
pub fn host_window_request_close(window : HostWindow) -> Unit {
  @windowing.request_close(window)
}

///|
pub fn host_window_run_loop(step : FuncRef[() -> Unit]) -> Unit {
  @windowing.run_loop(step)
}

///|
pub fn host_window_set_title(window : HostWindow, title~ : String) -> Unit {
  @windowing.set_title(window, title~)
}

///|
pub fn host_window_set_size(
  window : HostWindow,
  width~ : Int,
  height~ : Int,
) -> Unit {
  @windowing.set_size(window, width~, height~)
}

///|
pub fn host_window_set_resizable(
  window : HostWindow,
  resizable~ : Bool,
) -> Unit {
  @windowing.set_resizable(window, resizable~)
}

///|
pub fn host_window_set_cursor_visible(
  window : HostWindow,
  visible~ : Bool,
) -> Unit {
  @windowing.set_cursor_visible(window, visible~)
}

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
pub fn host_window_set_cursor_grab_mode(
  window : HostWindow,
  mode~ : CursorGrabMode,
) -> Unit {
  @windowing.set_cursor_grab_mode(window, mode=cursor_grab_mode_to_native(mode))
}

///|
pub fn host_window_set_cursor_icon(
  window : HostWindow,
  icon~ : CursorIcon,
) -> Unit {
  @windowing.set_cursor_icon(window, icon=cursor_icon_to_native(icon))
}

///|
fn window_mode_to_int(mode : WindowMode) -> Int {
  match mode {
    Windowed => 0
    BorderlessFullscreen => 1
    Fullscreen => 2
  }
}

///|
fn compass_octant_to_resize_direction(
  direction : @math.CompassOctant,
) -> @window_core.ResizeDirection {
  match direction {
    North => @window_core.ResizeDirection::North
    NorthEast => @window_core.ResizeDirection::NorthEast
    East => @window_core.ResizeDirection::East
    SouthEast => @window_core.ResizeDirection::SouthEast
    South => @window_core.ResizeDirection::South
    SouthWest => @window_core.ResizeDirection::SouthWest
    West => @window_core.ResizeDirection::West
    NorthWest => @window_core.ResizeDirection::NorthWest
  }
}

///|
pub fn host_window_set_mode(window : HostWindow, mode~ : WindowMode) -> Unit {
  host_window_set_mode_raw(window~, mode=window_mode_to_int(mode))
}

///|
fn host_window_set_mode_raw(window~ : HostWindow, mode~ : Int) -> Unit {
  @windowing.set_mode(window, mode~)
}

///|
pub fn host_window_set_visible(window : HostWindow, visible~ : Bool) -> Unit {
  @windowing.set_visible(window, visible~)
}

///|
pub fn host_window_set_decorations(
  window : HostWindow,
  decorations~ : Bool,
) -> Unit {
  @windowing.set_decorations(window, decorations~)
}

///|
pub fn host_window_set_transparent(
  window : HostWindow,
  transparent~ : Bool,
) -> Unit {
  @windowing.set_transparent(window, transparent~)
}

///|
pub fn host_window_set_window_level(
  window : HostWindow,
  level~ : WindowLevel,
) -> Unit {
  @windowing.set_window_level(window, level~)
}

///|
pub fn host_window_set_theme(
  window : HostWindow,
  theme~ : WindowTheme?,
) -> Unit {
  @windowing.set_theme(window, theme~)
}

///|
pub fn host_window_set_ime_allowed(
  window : HostWindow,
  allowed~ : Bool,
) -> Unit {
  @windowing.set_ime_allowed(window, allowed~)
}

///|
pub fn host_window_set_ime_cursor_area(
  window : HostWindow,
  x~ : Int,
  y~ : Int,
  width? : Int = 1,
  height? : Int = 1,
) -> Unit {
  @windowing.set_ime_cursor_area(window, x~, y~, width~, height~)
}

///|
pub fn host_window_set_enabled_buttons(
  window : HostWindow,
  buttons : EnabledButtons,
) -> Unit {
  @windowing.set_enabled_buttons(
    window,
    close=buttons.close,
    minimize=buttons.minimize,
    maximize=buttons.maximize,
  )
}

///|
pub fn host_window_drag_move(window : HostWindow) -> Bool {
  @windowing.drag_window(window)
}

///|
pub fn host_window_drag_resize(
  window : HostWindow,
  direction : @math.CompassOctant,
) -> Bool {
  @windowing.drag_resize_window(
    window,
    direction=compass_octant_to_resize_direction(direction),
  )
}

///|
pub fn host_window_set_position(
  window : HostWindow,
  x~ : Int,
  y~ : Int,
) -> Unit {
  @windowing.set_position(window, x~, y~)
}

///|
pub fn host_window_get_position_x(window : HostWindow) -> Int {
  @windowing.position_x(window)
}

///|
pub fn host_window_get_position_y(window : HostWindow) -> Int {
  @windowing.position_y(window)
}

///|
pub fn host_window_theme_event_count() -> Int {
  @windowing.input_window_theme_event_count()
}

///|
pub fn host_window_theme_event_window(index~ : Int) -> Int {
  @windowing.input_window_theme_event_window(index~)
}

///|
pub fn host_window_theme_event_theme(index~ : Int) -> Int {
  @windowing.input_window_theme_event_theme(index~)
}

///|
pub fn host_window_occluded_event_count() -> Int {
  @windowing.input_window_occluded_event_count()
}

///|
pub fn host_window_occluded_event_window(index~ : Int) -> Int {
  @windowing.input_window_occluded_event_window(index~)
}

///|
pub fn host_window_occluded_event_occluded(index~ : Int) -> Bool {
  @windowing.input_window_occluded_event_occluded(index~)
}

///|
pub fn host_app_lifecycle_event_count() -> Int {
  @windowing.input_app_lifecycle_event_count()
}

///|
pub fn host_app_lifecycle_event_kind(index~ : Int) -> Int {
  @windowing.input_app_lifecycle_event_kind(index~)
}

///|
fn window_current_world() -> @ecs.World? {
  @app.current_world()
}

///|
pub fn window_width() -> Int {
  guard window_current_world() is Some(world) else { return 0 }
  window_primary_physical_width(world)
}

///|
pub fn window_height() -> Int {
  guard window_current_world() is Some(world) else { return 0 }
  window_primary_physical_height(world)
}

///|
pub fn window_scale_factor() -> Float {
  guard window_current_world() is Some(world) else { return 1.0F }
  window_primary_scale_factor(world)
}

///|
pub fn window_set_title(title~ : String) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.title = title
      next
    }),
  )
}

///|
pub fn window_set_size(width~ : Int, height~ : Int) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      let resolution = next.resolution
      resolution.set_physical_resolution(width, height)
      next.resolution = resolution
      next
    }),
  )
}

///|
pub fn window_set_resizable(resizable~ : Bool) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.resizable = resizable
      next
    }),
  )
}

///|
pub fn window_set_visible(visible~ : Bool) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.visible = visible
      next
    }),
  )
}

///|
pub fn window_set_decorations(decorations~ : Bool) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.decorations = decorations
      next
    }),
  )
}

///|
pub fn window_set_transparent(transparent~ : Bool) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.transparent = transparent
      next
    }),
  )
}

///|
pub fn window_set_window_level(level~ : WindowLevel) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.window_level = level
      next
    }),
  )
}

///|
pub fn window_set_theme(theme~ : WindowTheme?) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.window_theme = theme
      next
    }),
  )
}

///|
pub fn window_set_cursor_visible(visible~ : Bool) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  let cursor_options = window_current_cursor_options(world, entity)
  cursor_options.visible = visible
  window_set_cursor_options_component(world, entity, cursor_options)
}

///|
pub fn window_set_cursor_grab_mode(mode~ : CursorGrabMode) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  let cursor_options = window_current_cursor_options(world, entity)
  cursor_options.grab_mode = mode
  window_set_cursor_options_component(world, entity, cursor_options)
}

///|
pub fn window_set_cursor_icon(icon~ : CursorIcon) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  window_set_cursor_icon_component(world, entity, icon)
}

///|
pub fn window_set_mode(mode~ : WindowMode) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.mode = mode
      next
    }),
  )
}

///|
pub fn window_set_present_mode(mode~ : PresentMode) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.present_mode = mode
      next
    }),
  )
}

///|
pub fn window_set_enabled_buttons(
  minimize~ : Bool,
  maximize~ : Bool,
  close~ : Bool,
) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.enabled_buttons.minimize = minimize
      next.enabled_buttons.maximize = maximize
      next.enabled_buttons.close = close
      next
    }),
  )
}

///|
pub fn window_set_position(x~ : Int, y~ : Int) -> Unit {
  guard window_current_world() is Some(world) else { return }
  guard window_primary_entity(world) is Some(entity) else { return }
  ignore(
    window_update_component(world, entity, fn(window) {
      let next : Window = window
      next.position = WindowPosition::new(x, y)
      next
    }),
  )
}

///|
pub fn window_position_x() -> Int {
  guard window_current_world() is Some(world) else { return 0 }
  window_primary_position_x(world)
}

///|
pub fn window_position_y() -> Int {
  guard window_current_world() is Some(world) else { return 0 }
  window_primary_position_y(world)
}

///|
pub fn host_debug_string(value~ : String) -> Unit {
  @render.host_debug_string(value~)
}
