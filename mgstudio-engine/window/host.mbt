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
pub type HostWindow = Int

///|
pub type KeyCode = @input_events.KeyCode

///|
pub type MouseButton = @input_events.MouseButton

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
pub fn host_window_create(
  logical_width~ : Int,
  logical_height~ : Int,
  physical_width~ : Int,
  physical_height~ : Int,
  use_physical_size_on_create~ : Bool,
  title~ : String,
  name? : String? = None,
  visible? : Bool = true,
  resizable? : Bool = true,
  decorations? : Bool = true,
  transparent? : Bool = false,
  panel? : Bool = false,
  focused? : Bool = true,
  close_button_enabled? : Bool = true,
  minimize_button_enabled? : Bool = true,
  maximize_button_enabled? : Bool = true,
  min_inner_width? : Float = 180.0F,
  min_inner_height? : Float = 120.0F,
  max_inner_width? : Float? = None,
  max_inner_height? : Float? = None,
  movable_by_window_background? : Bool = false,
  fullsize_content_view? : Bool = false,
  has_shadow? : Bool = true,
  titlebar_shown? : Bool = true,
  titlebar_transparent? : Bool = false,
  titlebar_show_title? : Bool = true,
  titlebar_show_buttons? : Bool = true,
  borderless_game? : Bool = true,
  skip_taskbar? : Bool = false,
  clip_children? : Bool = true,
) -> HostWindow {
  @windowing.create(
    logical_width~,
    logical_height~,
    physical_width~,
    physical_height~,
    use_physical_size_on_create~,
    title~,
    name~,
    visible~,
    resizable~,
    decorations~,
    transparent~,
    panel~,
    focused~,
    close_button_enabled~,
    minimize_button_enabled~,
    maximize_button_enabled~,
    min_inner_width~,
    min_inner_height~,
    max_inner_width~,
    max_inner_height~,
    movable_by_window_background~,
    fullsize_content_view~,
    has_shadow~,
    titlebar_shown~,
    titlebar_transparent~,
    titlebar_show_title~,
    titlebar_show_buttons~,
    borderless_game~,
    skip_taskbar~,
    clip_children~,
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
pub fn host_window_set_resize_constraints(
  window : HostWindow,
  constraints : WindowResizeConstraints,
) -> Unit {
  let checked = constraints.check_constraints()
  @windowing.set_min_inner_size(
    window,
    width=checked.min_width,
    height=checked.min_height,
  )
  if checked.max_width < @float.infinity && checked.max_height < @float.infinity {
    @windowing.set_max_inner_size(
      window,
      width=Some(checked.max_width),
      height=Some(checked.max_height),
    )
  } else {
    @windowing.set_max_inner_size(window, width=None, height=None)
  }
}

///|
pub fn host_window_set_maximized(
  window : HostWindow,
  maximized~ : Bool,
) -> Unit {
  @windowing.set_maximized(window, maximized~)
}

///|
pub fn host_window_set_minimized(
  window : HostWindow,
  minimized~ : Bool,
) -> Unit {
  @windowing.set_minimized(window, minimized~)
}

///|
pub fn host_window_focus(window : HostWindow) -> Unit {
  @windowing.focus_window(window)
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
fn monitor_selection_to_native(
  window : HostWindow,
  selection : MonitorSelection,
) -> @window_core.MonitorHandle? {
  match selection {
    Current => @windowing.current_monitor(window)
    Primary => @windowing.primary_monitor()
    Index(n) => {
      let monitors = @windowing.available_monitors()
      if n < 0 || n >= monitors.length() {
        None
      } else {
        Some(monitors[n])
      }
    }
    Entity(_) => None
  }
}

///|
fn video_mode_selection_to_native(
  monitor : @window_core.MonitorHandle,
  selection : VideoModeSelection,
) -> @window_core.VideoMode? {
  match selection {
    Current => monitor.current_video_mode()
    Specific(video_mode) => {
      for candidate in monitor.video_modes() {
        if candidate == video_mode {
          return Some(candidate)
        }
      }
      None
    }
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
  match mode {
    Windowed => @windowing.set_fullscreen(window, fullscreen=None)
    BorderlessFullscreen(monitor_selection) =>
      @windowing.set_fullscreen(
        window,
        fullscreen=Some(
          @window_core.Fullscreen::Borderless(
            monitor_selection_to_native(window, monitor_selection),
          ),
        ),
      )
    Fullscreen(monitor_selection, video_mode_selection) =>
      match monitor_selection_to_native(window, monitor_selection) {
        Some(monitor) =>
          match video_mode_selection_to_native(monitor, video_mode_selection) {
            Some(video_mode) =>
              @windowing.set_fullscreen(
                window,
                fullscreen=Some(
                  @window_core.Fullscreen::Exclusive(monitor, video_mode),
                ),
              )
            None =>
              host_debug_string(
                value="bevy_winit: could not find valid fullscreen video mode",
              )
          }
        None =>
          host_debug_string(
            value="bevy_winit: could not find monitor for fullscreen selection",
          )
      }
  }
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
pub fn host_window_set_prefers_home_indicator_hidden(
  window : HostWindow,
  hidden~ : Bool,
) -> Unit {
  @windowing.set_prefers_home_indicator_hidden(window, hidden~)
}

///|
pub fn host_window_set_prefers_status_bar_hidden(
  window : HostWindow,
  hidden~ : Bool,
) -> Unit {
  @windowing.set_prefers_status_bar_hidden(window, hidden~)
}

///|
fn screen_edge_to_native(edge : ScreenEdge) -> @window_core.ScreenEdge {
  match edge {
    ScreenEdge::None => @window_core.ScreenEdge::none()
    ScreenEdge::Top => @window_core.ScreenEdge::top()
    ScreenEdge::Left => @window_core.ScreenEdge::left()
    ScreenEdge::Bottom => @window_core.ScreenEdge::bottom()
    ScreenEdge::Right => @window_core.ScreenEdge::right()
    ScreenEdge::All => @window_core.ScreenEdge::all()
  }
}

///|
pub fn host_window_set_preferred_screen_edges_deferring_system_gestures(
  window : HostWindow,
  edges~ : ScreenEdge,
) -> Unit {
  @windowing.set_preferred_screen_edges_deferring_system_gestures(
    window,
    edges=screen_edge_to_native(edges),
  )
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
pub fn host_window_set_position_from(
  window : HostWindow,
  position : WindowPosition,
  resolution : WindowResolution,
) -> Unit {
  match position {
    Automatic => ()
    Centered(selection) =>
      match monitor_selection_to_native(window, selection) {
        Some(monitor) => {
          let surface_size = monitor.surface_size()
          let monitor_position = monitor.position()
          let resolution_scale = if resolution.scale_factor() <= 0.0F {
            1.0F
          } else {
            resolution.scale_factor()
          }
          let scale_factor = match resolution.scale_factor_override() {
            Some(scale_factor_override) =>
              if scale_factor_override <= 0.0F {
                1.0F
              } else {
                scale_factor_override
              }
            None => Float::from_double(monitor.scale_factor())
          }
          let width = (Float::from_int(resolution.physical_width()) /
          resolution_scale *
          scale_factor).to_int()
          let height = (Float::from_int(resolution.physical_height()) /
          resolution_scale *
          scale_factor).to_int()
          let centered_x = (Float::from_int(surface_size.width() - width) / 2.0F).to_int() +
            monitor_position.x()
          let centered_y = (Float::from_int(surface_size.height() - height) /
            2.0F).to_int() +
            monitor_position.y()
          host_window_set_position(window, x=centered_x, y=centered_y)
        }
        None =>
          host_debug_string(
            value="bevy_winit: could not resolve monitor for centered window position",
          )
      }
    At(x, y) => host_window_set_position(window, x~, y~)
  }
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
