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
#external
pub type HostWindow

///|
priv struct WindowState {
  mut window : HostWindow?
}

///|
let window_state : Ref[WindowState] = @ref.new(WindowState::{ window: None })

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
  ArrowUp
  ArrowDown
  ArrowLeft
  ArrowRight
  Space
  Escape
  Comma
  Period
}

///|
pub(all) enum MouseButton {
  Left
  Right
  Middle
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
pub fn host_window_create(
  width : Int,
  height : Int,
  title : String,
) -> HostWindow {
  @core.with_host_string_id(title, fn(title_id) {
    host_window_create_id(width, height, title_id)
  })
}

///|
fn host_window_create_id(
  width : Int,
  height : Int,
  title_id : Int,
) -> HostWindow = "mgstudio_host" "window_create"

///|
pub fn host_window_poll_events(window : HostWindow) -> Unit = "mgstudio_host" "window_poll_events"

///|
pub fn host_window_get_width(window : HostWindow) -> Int = "mgstudio_host" "window_get_width"

///|
pub fn host_window_get_height(window : HostWindow) -> Int = "mgstudio_host" "window_get_height"

///|
pub fn host_window_get_scale_factor(window : HostWindow) -> Float = "mgstudio_host" "window_get_scale_factor"

///|
pub fn host_window_should_close(window : HostWindow) -> Bool = "mgstudio_host" "window_should_close"

///|
pub fn host_window_request_close(window : HostWindow) -> Unit = "mgstudio_host" "window_request_close"

///|
pub fn host_window_run_loop(step : FuncRef[() -> Unit]) -> Unit = "mgstudio_host" "window_run_loop"

///|
pub fn window_set_handle(window : HostWindow) -> Unit {
  window_state.val.window = Some(window)
}

///|
pub fn window_width() -> Int {
  if window_state.val.window is Some(window) {
    host_window_get_width(window)
  } else {
    0
  }
}

///|
pub fn window_height() -> Int {
  if window_state.val.window is Some(window) {
    host_window_get_height(window)
  } else {
    0
  }
}

///|
pub fn window_scale_factor() -> Float {
  if window_state.val.window is Some(window) {
    host_window_get_scale_factor(window)
  } else {
    1.0F
  }
}

///|
#external
pub type HostGpuDevice

///|
#external
pub type HostGpuQueue

///|
#external
pub type HostGpuSurface

///|
#external
pub type HostGpuFrame

///|
pub fn host_gpu_request_device() -> HostGpuDevice = "mgstudio_host" "gpu_request_device"

///|
pub fn host_gpu_get_queue(device : HostGpuDevice) -> HostGpuQueue = "mgstudio_host" "gpu_get_queue"

///|
pub fn host_gpu_create_surface(window : HostWindow) -> HostGpuSurface = "mgstudio_host" "gpu_create_surface"

///|
pub fn host_gpu_configure_surface(
  device : HostGpuDevice,
  surface : HostGpuSurface,
  width : Int,
  height : Int,
) -> Unit = "mgstudio_host" "gpu_configure_surface"

///|
pub fn host_gpu_begin_frame(surface : HostGpuSurface) -> HostGpuFrame = "mgstudio_host" "gpu_begin_frame"

///|
pub fn host_gpu_end_frame(frame : HostGpuFrame) -> Unit = "mgstudio_host" "gpu_end_frame"

///|
pub fn host_gpu_begin_pass(
  target_id : Int,
  width : Int,
  height : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_rotation : Float,
  camera_scale : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
) -> Unit = "mgstudio_host" "gpu_begin_pass"

///|
pub fn host_gpu_set_scissor(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit = "mgstudio_host" "gpu_set_scissor"

///|
pub fn host_gpu_clear_scissor() -> Unit = "mgstudio_host" "gpu_clear_scissor"

///|
pub fn host_gpu_draw_sprite(
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
) -> Unit = "mgstudio_host" "gpu_draw_sprite"

///|
pub fn host_gpu_draw_sprite_uv(
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
) -> Unit = "mgstudio_host" "gpu_draw_sprite_uv"

///|
/// Draw a UI rectangle (background or border) using the dedicated UI pipeline.
///
/// Parameters intentionally mirror `gpu_draw_sprite_uv` plus UI-specific fields:
/// - `flags`: bitset (TEXTURED/BORDER/ANTI_ALIAS) defined by the engine-side UI
///   extraction.
/// - `radius_*`: corner radii in logical pixels (top-left, top-right, bottom-right, bottom-left).
/// - `border_*`: border thickness in logical pixels (left, top, right, bottom).
pub fn host_gpu_draw_ui_rect(
  texture_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  uv_min_x : Float,
  uv_min_y : Float,
  uv_max_x : Float,
  uv_max_y : Float,
  flags : Int,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  border_left : Float,
  border_top : Float,
  border_right : Float,
  border_bottom : Float,
) -> Unit = "mgstudio_host" "gpu_draw_ui_rect"

///|
pub fn host_gpu_draw_mesh(
  mesh_id : Int,
  x : Float,
  y : Float,
  rotation : Float,
  scale_x : Float,
  scale_y : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
) -> Unit = "mgstudio_host" "gpu_draw_mesh"

///|
pub fn host_gpu_draw_gizmo_line(
  start_x : Float,
  start_y : Float,
  start_r : Float,
  start_g : Float,
  start_b : Float,
  start_a : Float,
  end_x : Float,
  end_y : Float,
  end_r : Float,
  end_g : Float,
  end_b : Float,
  end_a : Float,
  line_width : Float,
  style_kind : Int,
  gap_scale : Float,
  line_scale : Float,
) -> Unit = "mgstudio_host" "gpu_draw_gizmo_line"

///|
pub fn host_gpu_end_pass() -> Unit = "mgstudio_host" "gpu_end_pass"

///|
pub fn host_gpu_create_render_target(
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int = "mgstudio_host" "gpu_create_render_target"

///|
pub fn host_gpu_create_mesh_capsule(
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Int = "mgstudio_host" "gpu_create_mesh_capsule"

///|
pub fn host_gpu_create_mesh_rectangle(width : Float, height : Float) -> Int = "mgstudio_host" "gpu_create_mesh_rectangle"

///|
pub fn host_gpu_create_mesh_triangles(vertices_xy_csv : String) -> Int {
  @core.with_host_string_id(vertices_xy_csv, fn(text_id) {
    host_gpu_create_mesh_triangles_id(text_id)
  })
}

///|
fn host_gpu_create_mesh_triangles_id(vertices_xy_csv_id : Int) -> Int = "mgstudio_host" "gpu_create_mesh_triangles"

///|
pub fn host_debug_string(value : String) -> Unit {
  @core.with_host_string_id(value, fn(text_id) { host_debug_string_id(text_id) })
}

///|
fn host_debug_string_id(value_id : Int) -> Unit = "mgstudio_host" "debug_string"

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
pub fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] window_runner_builder(
  app : @app.App[W],
) -> @app.RunnerFn {
  fn() {
    let window = host_window_create(800, 600, "Moon Game Studio")
    window_set_handle(window)
    let device = host_gpu_request_device()
    let surface = host_gpu_create_surface(window)
    let width = host_window_get_width(window)
    let height = host_window_get_height(window)
    host_gpu_configure_surface(device, surface, width, height)
    let app_ref : Ref[@app.App[W]] = Ref::new(app.run_startup())
    runner_state.val.tick = Some(fn() {
      host_window_poll_events(window)
      let frame = host_gpu_begin_frame(surface)
      app_ref.val = app_ref.val.run_once()
      host_gpu_end_frame(frame)
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

///|
pub fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] window_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  @app.App::set_runner(app, window_runner_builder)
}
