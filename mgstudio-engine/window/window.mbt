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
) -> HostWindow = "mgstudio_host" "window_create"

///|
pub fn host_window_poll_events(window : HostWindow) -> Unit = "mgstudio_host" "window_poll_events"

///|
pub fn host_window_get_width(window : HostWindow) -> Int = "mgstudio_host" "window_get_width"

///|
pub fn host_window_get_height(window : HostWindow) -> Int = "mgstudio_host" "window_get_height"

///|
pub fn host_window_should_close(window : HostWindow) -> Bool = "mgstudio_host" "window_should_close"

///|
pub fn host_window_request_close(window : HostWindow) -> Unit = "mgstudio_host" "window_request_close"

///|
pub fn host_window_run_loop(step : () -> Unit) -> Unit = "mgstudio_host" "window_run_loop"

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
pub fn host_gpu_set_draw_enabled(enabled : Bool) -> Unit = "mgstudio_host" "gpu_set_draw_enabled"

///|
pub fn host_gpu_set_sprite_transform(
  x : Float,
  y : Float,
  rotation : Float,
) -> Unit = "mgstudio_host" "gpu_set_sprite_transform"

///|
pub fn window_runner_builder(app : @app.App) -> @app.RunnerFn {
  fn() {
    let mut app = app.run_startup()
    let window = host_window_create(800, 600, "Moon Game Studio")
    let device = host_gpu_request_device()
    let surface = host_gpu_create_surface(window)
    let width = host_window_get_width(window)
    let height = host_window_get_height(window)
    host_gpu_configure_surface(device, surface, width, height)
    host_window_run_loop(fn() {
      host_window_poll_events(window)
      app = app.run_once()
      let frame = host_gpu_begin_frame(surface)
      host_gpu_end_frame(frame)
      if host_window_should_close(window) {
        host_window_request_close(window)
      }
    })
  }
}

///|
pub fn window_plugin(app : @app.App) -> @app.App {
  @app.App::set_runner(app, window_runner_builder)
}
