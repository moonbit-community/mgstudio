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
} derive(ToJson, FromJson)

///|
pub(all) enum MouseButton {
  Left
  Right
  Middle
} derive(ToJson, FromJson)

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
) -> HostWindow {
  @windowing.create(
    logical_width~,
    logical_height~,
    physical_width~,
    physical_height~,
    use_physical_size_on_create~,
    title~,
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
        EwResize => 1
        Progress => 2
        _ => 0
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
pub fn host_window_set_mode(window : HostWindow, mode~ : WindowMode) -> Unit {
  host_window_set_mode_raw(window~, mode=window_mode_to_int(mode))
}

///|
fn host_window_set_mode_raw(window~ : HostWindow, mode~ : Int) -> Unit {
  @windowing.set_mode(window, mode~)
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
pub fn window_runner_builder(app : @app.App[@ecs.World]) -> @app.RunnerFn {
  fn() {
    guard window_ensure_primary_host(app.world()) is Some(window) else {
      app.run_startup().update() |> ignore
      return
    }
    let device = @render.host_gpu_request_device()
    let surface = @render.host_gpu_create_surface(window)
    let width = host_window_get_width(window)
    let height = host_window_get_height(window)
    @render.host_gpu_configure_surface(device~, surface~, width~, height~)
    let surface_width_ref : Ref[Int] = Ref::new(width)
    let surface_height_ref : Ref[Int] = Ref::new(height)
    let app_ref : Ref[@app.App[@ecs.World]] = Ref::new(app.run_startup())
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
    let debug_screenshot_requested_ref : Ref[Bool] = Ref::new(false)
    let debug_screenshot_saved_ref : Ref[Bool] = Ref::new(false)
    let debug_screenshot_capture_id_ref : Ref[Int] = Ref::new(0)
    let debug_screenshot_render_frame_ref : Ref[Int] = Ref::new(0)
    runner_state.val.tick = Some(fn() {
      window_poll_host_events(app_ref.val.world())
      let current_width = host_window_get_width(window)
      let current_height = host_window_get_height(window)
      if current_width > 0 &&
        current_height > 0 &&
        (
          current_width != surface_width_ref.val ||
          current_height != surface_height_ref.val
        ) {
        @render.host_gpu_configure_surface(
          device~,
          surface~,
          width=current_width,
          height=current_height,
        )
        surface_width_ref.val = current_width
        surface_height_ref.val = current_height
      }
      if @app.app_rendering_enabled() {
        let next_render_frame = debug_screenshot_render_frame_ref.val + 1
        if !debug_screenshot_requested_ref.val &&
          debug_screenshot_path is Some(_) &&
          debug_screenshot_texture_id <= 0 &&
          next_render_frame >= debug_screenshot_frame {
          let capture_id = @render.screenshot_capture_surface_request()
          if capture_id > 0 {
            debug_screenshot_requested_ref.val = true
            debug_screenshot_capture_id_ref.val = capture_id
          }
        }
        let frame = @render.host_gpu_begin_frame(surface)
        app_ref.val = app_ref.val.run_once()
        debug_screenshot_render_frame_ref.val = next_render_frame
        screenshot_queue_capture_requests(app_ref.val.world())
        @render.host_gpu_end_frame(frame)
        screenshot_finalize_capture_requests(app_ref.val.world())
        if !debug_screenshot_saved_ref.val &&
          debug_screenshot_path is Some(path) {
          let capture = if debug_screenshot_texture_id > 0 &&
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
          if capture is Some(capture) {
            @asset.host_asset_save_rgba8_png(
              width=capture.width,
              height=capture.height,
              pixels=capture.pixels,
              path~,
            )
            debug_screenshot_saved_ref.val = true
            if debug_screenshot_exit_on_save {
              host_window_request_close(window)
              runner_state.val.tick = None
              return
            }
          }
        }
      } else {
        app_ref.val = app_ref.val.run_once()
      }
      if app_ref.val.should_exit() is Some(_) {
        host_window_request_close(window)
        runner_state.val.tick = None
        return
      }
      if host_window_should_close(window) {
        host_window_request_close(window)
        // Web runtimes cannot block in `window_run_loop`, so cleanup must happen
        // inside the tick closure (not after `window_run_loop` returns).
        runner_state.val.tick = None
      }
    })
    let tick : FuncRef[() -> Unit] = fn() { runner_tick() }
    host_window_run_loop(tick)
  }
}
