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
pub(all) enum KeyCode {
  KeyA
  KeyB
  KeyC
  KeyD
  KeyE
  KeyF
  KeyG
  KeyH
  KeyI
  KeyJ
  KeyK
  KeyL
  KeyM
  KeyN
  KeyO
  KeyP
  KeyQ
  KeyR
  KeyS
  KeyT
  KeyU
  KeyV
  KeyW
  KeyX
  KeyY
  KeyZ
  Digit1
  Digit2
  Digit3
  Digit4
  Digit5
  Digit6
  Digit7
  Digit8
  Tab
  Enter
  Backspace
  ShiftLeft
  ShiftRight
  ControlLeft
  ControlRight
  ArrowUp
  ArrowDown
  ArrowLeft
  ArrowRight
  PageUp
  PageDown
  Space
  Escape
  Semicolon
  Comma
  Period
  Slash
  Minus
  Equal
  NumpadAdd
  NumpadSubtract
  BracketLeft
  BracketRight
  Quote
} derive(Eq, Hash, Show, ToJson, FromJson)

///|
pub(all) enum MouseButton {
  Left
  Right
  Middle
} derive(Eq, Hash, Show, ToJson, FromJson)

///|
pub(all) enum CursorGrabMode {
  GrabNone
  GrabConfined
  GrabLocked
} derive(Eq, Show)

///|
pub(all) enum SystemCursorIcon {
  Default
  ContextMenu
  Help
  Pointer
  Progress
  Wait
  Cell
  Crosshair
  Text
  VerticalText
  Alias
  Copy
  Move
  NoDrop
  NotAllowed
  Grab
  Grabbing
  EResize
  NResize
  NeResize
  NwResize
  SResize
  SeResize
  SwResize
  WResize
  EwResize
  NsResize
  NeswResize
  NwseResize
  ColResize
  RowResize
  AllScroll
  ZoomIn
  ZoomOut
} derive(Eq, Show)

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
  System(Default)
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
pub(all) enum WindowLevel {
  AlwaysOnBottom
  Normal
  AlwaysOnTop
} derive(Eq, Show)

///|
pub(all) enum WindowTheme {
  Light
  Dark
} derive(Eq, Show)

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
fn cursor_grab_mode_to_int(mode : CursorGrabMode) -> Int {
  match mode {
    GrabNone => 0
    GrabConfined => 1
    GrabLocked => 2
  }
}

///|
fn cursor_icon_to_int(icon : CursorIcon) -> Int {
  match icon {
    System(system_icon) =>
      match system_icon {
        Default => 0
        ContextMenu => 1
        Help => 2
        Progress => 3
        Wait => 4
        Cell => 5
        VerticalText => 6
        Alias => 7
        Copy => 8
        NoDrop => 9
        Grab => 10
        Grabbing => 11
        EResize => 12
        NResize => 13
        NeResize => 14
        NwResize => 15
        SResize => 16
        SeResize => 17
        SwResize => 18
        WResize => 19
        EwResize => 20
        NsResize => 21
        NeswResize => 22
        NwseResize => 23
        ColResize => 24
        RowResize => 25
        AllScroll => 26
        ZoomIn => 27
        ZoomOut => 28
        Pointer => 29
        Text => 30
        Crosshair => 31
        Move => 32
        NotAllowed => 33
      }
  }
}

///|
pub fn host_window_set_cursor_grab_mode(
  window : HostWindow,
  mode~ : CursorGrabMode,
) -> Unit {
  host_window_set_cursor_grab_mode_raw(
    window~,
    mode=cursor_grab_mode_to_int(mode),
  )
}

///|
fn host_window_set_cursor_grab_mode_raw(
  window~ : HostWindow,
  mode~ : Int,
) -> Unit {
  @windowing.set_cursor_grab_mode(window, mode~)
}

///|
pub fn host_window_set_cursor_icon(
  window : HostWindow,
  icon~ : CursorIcon,
) -> Unit {
  host_window_set_cursor_icon_raw(window~, icon=cursor_icon_to_int(icon))
}

///|
fn host_window_set_cursor_icon_raw(window~ : HostWindow, icon~ : Int) -> Unit {
  @windowing.set_cursor_icon(window, icon~)
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
fn window_level_to_int(level : WindowLevel) -> Int {
  match level {
    Normal => 0
    AlwaysOnTop => 1
    AlwaysOnBottom => 2
  }
}

///|
fn window_theme_to_int(theme : WindowTheme?) -> Int {
  match theme {
    Some(Light) => 1
    Some(Dark) => 2
    None => 0
  }
}

///|
fn compass_octant_to_resize_direction_int(
  direction : @math.CompassOctant,
) -> Int {
  match direction {
    North => 1
    NorthEast => 2
    East => 0
    SouthEast => 5
    South => 4
    SouthWest => 6
    West => 7
    NorthWest => 3
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
  @windowing.set_window_level(window, level=window_level_to_int(level))
}

///|
pub fn host_window_set_theme(
  window : HostWindow,
  theme~ : WindowTheme?,
) -> Unit {
  @windowing.set_theme(window, theme=window_theme_to_int(theme))
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
    direction=compass_octant_to_resize_direction_int(direction),
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
fn window_current_world() -> @ecs.World? {
  @app.current_world()
}

///|
fn env_flag_enabled(key : String) -> Bool {
  match @sys.get_env_var(key) {
    Some("1") => true
    Some("true") => true
    Some("TRUE") => true
    Some("yes") => true
    Some("YES") => true
    _ => false
  }
}

///|
fn env_int_or_default(key : String, default_value : Int) -> Int {
  match @sys.get_env_var(key) {
    Some(value) => {
      let token = value.trim().to_string()
      if token == "" {
        default_value
      } else {
        @strconv.parse_int(token[:], base=10) catch {
          _ => default_value
        }
      }
    }
    None => default_value
  }
}

///|
fn screenshot_pixels_have_non_black_rgb(pixels : Bytes) -> Bool {
  if pixels.length() < 4 {
    return false
  }
  let pixel_count = pixels.length() / 4
  for i in 0..<pixel_count {
    let base = i * 4
    if pixels[base] != (0).to_byte() ||
      pixels[base + 1] != (0).to_byte() ||
      pixels[base + 2] != (0).to_byte() {
      return true
    }
  }
  false
}

///|
fn screenshot_try_non_black_texture_capture(
  texture_id : Int,
) -> @renderer.ScreenshotCaptureResult? {
  guard @render.screenshot_capture_texture_sync(texture_id~) is Some(capture) else {
    return None
  }
  if !screenshot_pixels_have_non_black_rgb(capture.pixels) {
    return None
  }
  Some(capture)
}

///|
fn screenshot_capture_with_texture_fallback(
  capture : @renderer.ScreenshotCaptureResult?,
) -> @renderer.ScreenshotCaptureResult? {
  guard capture is Some(surface_capture) else { return None }
  if screenshot_pixels_have_non_black_rgb(surface_capture.pixels) {
    return Some(surface_capture)
  }
  let texture_refs = @renderer.screenshot_texture_refs()
  if texture_refs.length() == 0 {
    return Some(surface_capture)
  }
  for offset in 0..<texture_refs.length() {
    let texture_ref = texture_refs[texture_refs.length() - 1 - offset]
    if texture_ref.width != surface_capture.width ||
      texture_ref.height != surface_capture.height {
      continue
    }
    guard screenshot_try_non_black_texture_capture(texture_ref.id)
      is Some(texture_capture) else {
      continue
    }
    host_debug_string(
      value="[screenshot] surface capture is black; fallback texture_id=" +
        texture_ref.id.to_string() +
        " (" +
        texture_ref.width.to_string() +
        "x" +
        texture_ref.height.to_string() +
        ")",
    )
    return Some(texture_capture)
  }
  let fallback_upper_bound = @renderer.screenshot_resource_id_upper_bound()
  if fallback_upper_bound > 0 {
    host_debug_string(
      value="[screenshot] surface capture remains black; no non-black same-size texture in resource_id<= " +
        fallback_upper_bound.to_string(),
    )
  }
  Some(surface_capture)
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

///|
priv struct RunnerState {
  mut tick : @app.RunnerFn?
}

///|
let runner_state : Ref[RunnerState] = Ref::new(RunnerState::{ tick: None })

///|
fn runner_tick() -> Unit {
  if runner_state.val.tick is Some(tick) {
    tick()
  }
}

///|
priv struct RunnerSurfaceBinding {
  host_window : HostWindow
  surface : @render.HostGpuSurface
  target_id : Int
  width : Int
  height : Int
}

///|
priv struct RunnerFrameBinding {
  frame : @render.HostGpuFrame
}

///|
fn runner_surface_binding_find(
  bindings : Array[RunnerSurfaceBinding],
  host_window : HostWindow,
) -> RunnerSurfaceBinding? {
  for binding in bindings {
    if binding.host_window == host_window {
      return Some(binding)
    }
  }
  None
}

///|
fn runner_surface_binding_ordered(
  bindings : Array[RunnerSurfaceBinding],
  primary_window : HostWindow,
) -> Array[RunnerSurfaceBinding] {
  let ordered : Array[RunnerSurfaceBinding] = []
  for binding in bindings {
    if binding.host_window == primary_window {
      ordered.push(binding)
    }
  }
  for binding in bindings {
    if binding.host_window != primary_window {
      ordered.push(binding)
    }
  }
  ordered
}

///|
pub fn window_runner_builder(app : @app.App[@ecs.World]) -> @app.RunnerFn {
  fn() {
    guard window_ensure_primary_host(app.world()) is Some(window) else {
      app.run_startup().update() |> ignore
      return
    }
    let device = @render.host_gpu_request_device()
    let app_ref : Ref[@app.App[@ecs.World]] = Ref::new(app.run_startup())
    let runner_surfaces_ref : Ref[Array[RunnerSurfaceBinding]] = Ref::new([])
    let debug_screenshot_path = match
      @sys.get_env_var("MGSTUDIO_SCREENSHOT_PATH") {
      Some(path) if path.trim().to_string() != "" =>
        Some(path.trim().to_string())
      _ => None
    }
    let debug_screenshot_exit_on_save = env_flag_enabled(
      "MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE",
    )
    let debug_screenshot_texture_id = {
      let value = env_int_or_default("MGSTUDIO_SCREENSHOT_TEXTURE_ID", -1)
      if value > 0 {
        value
      } else {
        -1
      }
    }
    let debug_screenshot_frame = if debug_screenshot_path is Some(_) {
      let value = env_int_or_default("MGSTUDIO_SCREENSHOT_FRAME", 1)
      if value <= 0 {
        1
      } else {
        value
      }
    } else {
      1
    }
    let debug_screenshot_surface_index = {
      let value = env_int_or_default("MGSTUDIO_SCREENSHOT_SURFACE_INDEX", 0)
      if value < 0 {
        0
      } else {
        value
      }
    }
    let debug_screenshot_requested_ref : Ref[Bool] = Ref::new(false)
    let debug_screenshot_saved_ref : Ref[Bool] = Ref::new(false)
    let debug_screenshot_capture_id_ref : Ref[Int] = Ref::new(0)
    let debug_screenshot_render_frame_ref : Ref[Int] = Ref::new(0)
    runner_state.val.tick = Some(fn() {
      window_poll_host_events(app_ref.val.world())

      let world = app_ref.val.world()
      let host_entries = window_host_entries(world)
      let next_surfaces : Array[RunnerSurfaceBinding] = []
      let previous_surfaces = runner_surfaces_ref.val
      for entry in host_entries {
        let host_window = entry.host_window
        if runner_surface_binding_find(previous_surfaces, host_window)
          is Some(previous) {
          let width = host_window_get_width(host_window)
          let height = host_window_get_height(host_window)
          if width > 0 &&
            height > 0 &&
            (width != previous.width || height != previous.height) {
            @render.host_gpu_configure_surface(
              device~,
              surface=previous.surface,
              width~,
              height~,
            )
          }
          next_surfaces.push(RunnerSurfaceBinding::{
            host_window,
            surface: previous.surface,
            target_id: previous.target_id,
            width,
            height,
          })
          continue
        }

        let surface = @render.host_gpu_create_surface(host_window)
        let target_id = @render.host_gpu_surface_target_id(surface)
        let width = host_window_get_width(host_window)
        let height = host_window_get_height(host_window)
        if width > 0 && height > 0 {
          @render.host_gpu_configure_surface(device~, surface~, width~, height~)
        }
        next_surfaces.push(RunnerSurfaceBinding::{
          host_window,
          surface,
          target_id,
          width,
          height,
        })
      }
      runner_surfaces_ref.val = next_surfaces

      if @app.app_rendering_enabled() {
        let next_render_frame = debug_screenshot_render_frame_ref.val + 1
        let ordered_surface_bindings = runner_surface_binding_ordered(
          runner_surfaces_ref.val,
          window,
        )
        let capture_surface_index = if ordered_surface_bindings.length() <= 0 {
          0
        } else if debug_screenshot_surface_index >=
          ordered_surface_bindings.length() {
          0
        } else {
          debug_screenshot_surface_index
        }
        let frame_bindings : Array[RunnerFrameBinding] = []
        for i, binding in ordered_surface_bindings {
          if !debug_screenshot_requested_ref.val &&
            debug_screenshot_path is Some(_) &&
            debug_screenshot_texture_id <= 0 &&
            next_render_frame >= debug_screenshot_frame &&
            i == capture_surface_index {
            let capture_id = @render.screenshot_capture_surface_request()
            if capture_id > 0 {
              debug_screenshot_requested_ref.val = true
              debug_screenshot_capture_id_ref.val = capture_id
            }
          }
          if binding.width <= 0 || binding.height <= 0 {
            continue
          }
          @render.host_gpu_set_active_surface_target(binding.target_id)
          let frame = @render.host_gpu_begin_frame(binding.surface)
          if frame > 0 {
            frame_bindings.push(RunnerFrameBinding::{ frame, })
          }
        }
        app_ref.val = app_ref.val.run_once()
        debug_screenshot_render_frame_ref.val = next_render_frame
        screenshot_queue_capture_requests(app_ref.val.world())
        for frame_binding in frame_bindings {
          @render.host_gpu_end_frame(frame_binding.frame)
        }
        screenshot_finalize_capture_requests(app_ref.val.world())
        if !debug_screenshot_saved_ref.val &&
          debug_screenshot_path is Some(path) {
          let capture0 = if debug_screenshot_texture_id > 0 &&
            next_render_frame >= debug_screenshot_frame {
            @render.screenshot_capture_texture_sync(
              texture_id=debug_screenshot_texture_id,
            )
          } else if debug_screenshot_capture_id_ref.val > 0 {
            @render.screenshot_take_capture_result(
              debug_screenshot_capture_id_ref.val,
            )
          } else {
            None
          }
          let capture = if debug_screenshot_texture_id > 0 {
            capture0
          } else {
            screenshot_capture_with_texture_fallback(capture0)
          }
          if capture is Some(capture) {
            @asset.host_asset_save_rgba8_png(
              width=capture.width,
              height=capture.height,
              pixels=capture.pixels,
              path~,
            )
            debug_screenshot_saved_ref.val = true
            if debug_screenshot_exit_on_save {
              window_request_close_all_hosts(app_ref.val.world())
              runner_state.val.tick = None
              return
            }
          }
        }
      } else {
        app_ref.val = app_ref.val.run_once()
      }
      if app_ref.val.should_exit() is Some(_) {
        window_request_close_all_hosts(app_ref.val.world())
        runner_state.val.tick = None
        return
      }
      if host_window_should_close(window) {
        window_request_close_all_hosts(app_ref.val.world())
        // Web runtimes cannot block in `window_run_loop`, so cleanup must happen
        // inside the tick closure (not after `window_run_loop` returns).
        runner_state.val.tick = None
      }
    })
    let tick : FuncRef[() -> Unit] = fn() { runner_tick() }
    host_window_run_loop(tick)
  }
}
