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
priv struct RunnerSurfaceBinding {
  host_window : @window.HostWindow
  surface : @render.HostGpuSurface
  target_id : Int
  width : Int
  height : Int
  present_mode : @render.HostGpuPresentMode
  composite_alpha_mode : @render.HostGpuCompositeAlphaMode
  desired_maximum_frame_latency : Int
}

///|
priv struct RunnerFrameBinding {
  frame : @render.HostGpuFrame
}

///|
fn runner_surface_binding_find(
  bindings : Array[RunnerSurfaceBinding],
  host_window : @window.HostWindow,
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
  primary_window : @window.HostWindow,
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
fn runner_surface_present_mode(
  window : @window.Window?,
) -> @render.HostGpuPresentMode {
  match window {
    Some(value) =>
      match value.present_mode {
        @window.PresentMode::AutoVsync => @render.HostGpuPresentMode::AutoVsync
        @window.PresentMode::AutoNoVsync =>
          @render.HostGpuPresentMode::AutoNoVsync
        @window.PresentMode::Fifo => @render.HostGpuPresentMode::Fifo
        @window.PresentMode::FifoRelaxed =>
          @render.HostGpuPresentMode::FifoRelaxed
        @window.PresentMode::Immediate => @render.HostGpuPresentMode::Immediate
        @window.PresentMode::Mailbox => @render.HostGpuPresentMode::Mailbox
      }
    None => @render.HostGpuPresentMode::Fifo
  }
}

///|
fn runner_surface_composite_alpha_mode(
  window : @window.Window?,
) -> @render.HostGpuCompositeAlphaMode {
  match window {
    Some(value) =>
      match value.composite_alpha_mode {
        @window.CompositeAlphaMode::Auto =>
          @render.HostGpuCompositeAlphaMode::Auto
        @window.CompositeAlphaMode::Opaque =>
          @render.HostGpuCompositeAlphaMode::Opaque
        @window.CompositeAlphaMode::PreMultiplied =>
          @render.HostGpuCompositeAlphaMode::PreMultiplied
        @window.CompositeAlphaMode::PostMultiplied =>
          @render.HostGpuCompositeAlphaMode::PostMultiplied
        @window.CompositeAlphaMode::Inherit =>
          @render.HostGpuCompositeAlphaMode::Inherit
      }
    None => @render.HostGpuCompositeAlphaMode::default()
  }
}

///|
fn runner_surface_desired_maximum_frame_latency(
  window : @window.Window?,
) -> Int {
  let desired = match window {
    Some(value) =>
      match value.desired_maximum_frame_latency {
        Some(latency) => latency
        None => @render.HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
      }
    None => @render.HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  }
  if desired >= 1 {
    desired
  } else {
    @render.HOST_GPU_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY
  }
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
        @string.parse_int(token[:], base=10) catch {
          _ => default_value
        }
      }
    }
    None => default_value
  }
}

///|
fn runner_frame_limit() -> Int {
  let value = env_int_or_default("MGSTUDIO_WINDOW_FRAME_LIMIT", 0)
  if value > 0 {
    value
  } else {
    0
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
priv struct WinitAppRunnerState {
  device : @render.HostGpuDevice
  primary_window : @window.HostWindow
  app_ref : Ref[@app.App[@ecs.World]]
  runner_surfaces_ref : Ref[Array[RunnerSurfaceBinding]]
  debug_screenshot_path : String?
  debug_screenshot_exit_on_save : Bool
  debug_screenshot_texture_id : Int
  debug_screenshot_frame : Int
  debug_screenshot_surface_index : Int
  debug_screenshot_requested_ref : Ref[Bool]
  debug_screenshot_saved_ref : Ref[Bool]
  debug_screenshot_capture_id_ref : Ref[Int]
  debug_screenshot_render_frame_ref : Ref[Int]
  frame_limit : Int
  frame_count_ref : Ref[Int]
}

///|
fn WinitAppRunnerState::run_tick(self : WinitAppRunnerState) -> Unit {
  let world = self.app_ref.val.world()
  let host_entries = @window.window_host_entries(world)
  let next_surfaces : Array[RunnerSurfaceBinding] = []
  let previous_surfaces = self.runner_surfaces_ref.val
  for entry in host_entries {
    let host_window = entry.host_window
    let window_component = try! world.get_by_key(
      entry.entity,
      @window.Window::component(),
    )
    let present_mode = runner_surface_present_mode(window_component)
    let composite_alpha_mode = runner_surface_composite_alpha_mode(
      window_component,
    )
    let desired_maximum_frame_latency = runner_surface_desired_maximum_frame_latency(
      window_component,
    )
    if runner_surface_binding_find(previous_surfaces, host_window)
      is Some(previous) {
      let width = @window.host_window_get_width(host_window)
      let height = @window.host_window_get_height(host_window)
      if width > 0 &&
        height > 0 &&
        (
          width != previous.width ||
          height != previous.height ||
          present_mode != previous.present_mode ||
          composite_alpha_mode != previous.composite_alpha_mode ||
          desired_maximum_frame_latency !=
          previous.desired_maximum_frame_latency
        ) {
        @render.host_gpu_configure_surface(
          device=self.device,
          surface=previous.surface,
          width~,
          height~,
          present_mode~,
          composite_alpha_mode~,
          desired_maximum_frame_latency~,
        )
      }
      next_surfaces.push(RunnerSurfaceBinding::{
        host_window,
        surface: previous.surface,
        target_id: previous.target_id,
        width,
        height,
        present_mode,
        composite_alpha_mode,
        desired_maximum_frame_latency,
      })
      continue
    }

    let surface = @render.host_gpu_create_surface(host_window)
    let target_id = @render.host_gpu_surface_target_id(surface)
    let width = @window.host_window_get_width(host_window)
    let height = @window.host_window_get_height(host_window)
    if width > 0 && height > 0 {
      @render.host_gpu_configure_surface(
        device=self.device,
        surface~,
        width~,
        height~,
        present_mode~,
        composite_alpha_mode~,
        desired_maximum_frame_latency~,
      )
    }
    next_surfaces.push(RunnerSurfaceBinding::{
      host_window,
      surface,
      target_id,
      width,
      height,
      present_mode,
      composite_alpha_mode,
      desired_maximum_frame_latency,
    })
  }
  self.runner_surfaces_ref.val = next_surfaces

  if @app.app_rendering_enabled() {
    let next_render_frame = self.debug_screenshot_render_frame_ref.val + 1
    let ordered_surface_bindings = runner_surface_binding_ordered(
      self.runner_surfaces_ref.val,
      self.primary_window,
    )
    let capture_surface_index = if ordered_surface_bindings.length() <= 0 {
      0
    } else if self.debug_screenshot_surface_index >=
      ordered_surface_bindings.length() {
      0
    } else {
      self.debug_screenshot_surface_index
    }
    let frame_bindings : Array[RunnerFrameBinding] = []
    for i, binding in ordered_surface_bindings {
      if !self.debug_screenshot_requested_ref.val &&
        self.debug_screenshot_path is Some(_) &&
        self.debug_screenshot_texture_id <= 0 &&
        next_render_frame >= self.debug_screenshot_frame &&
        i == capture_surface_index {
        let capture_id = @render.screenshot_capture_surface_request()
        if capture_id > 0 {
          self.debug_screenshot_requested_ref.val = true
          self.debug_screenshot_capture_id_ref.val = capture_id
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
    self.app_ref.val = self.app_ref.val.run_once()
    self.debug_screenshot_render_frame_ref.val = next_render_frame
    @window.screenshot_queue_capture_requests(self.app_ref.val.world())
    for frame_binding in frame_bindings {
      @render.host_gpu_end_frame(frame_binding.frame)
    }
    @window.screenshot_finalize_capture_requests(self.app_ref.val.world())
    if !self.debug_screenshot_saved_ref.val &&
      self.debug_screenshot_path is Some(path) {
      let capture0 = if self.debug_screenshot_texture_id > 0 &&
        next_render_frame >= self.debug_screenshot_frame {
        @render.screenshot_capture_texture_sync(
          texture_id=self.debug_screenshot_texture_id,
        )
      } else if self.debug_screenshot_capture_id_ref.val > 0 {
        @render.screenshot_take_capture_result(
          self.debug_screenshot_capture_id_ref.val,
        )
      } else {
        None
      }
      let capture = if self.debug_screenshot_texture_id > 0 {
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
        self.debug_screenshot_saved_ref.val = true
        if self.debug_screenshot_exit_on_save {
          @window.window_request_close_all_hosts(self.app_ref.val.world())
          return
        }
      }
    }
  } else {
    self.app_ref.val = self.app_ref.val.run_once()
  }
  if self.app_ref.val.should_exit() is Some(_) {
    @window.window_request_close_all_hosts(self.app_ref.val.world())
    return
  }
  if @window.host_window_should_close(self.primary_window) {
    @window.window_request_close_all_hosts(self.app_ref.val.world())
  }
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with window_event(
  _self,
  _event_loop,
  window_id,
  event,
) {
  @windowing.runner_process_window_event(window_id.into_raw(), event)
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with resumed(
  _self,
  _event_loop,
) {
  @windowing.runner_handle_resumed()
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with suspended(
  _self,
  _event_loop,
) {
  @windowing.runner_handle_suspended()
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with about_to_wait(
  self,
  event_loop,
) {
  event_loop.set_control_flow(@window_core.ControlFlow::Poll)
  self.run_tick()
  if self.frame_limit > 0 {
    self.frame_count_ref.val = self.frame_count_ref.val + 1
    if self.frame_count_ref.val >= self.frame_limit {
      @window.window_request_close_all_hosts(self.app_ref.val.world())
    }
  }
  if !@windowing.any_window_open() {
    event_loop.exit()
  }
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
    @window.host_debug_string(
      value="[screenshot] surface capture is black; fallback texture_id=\{texture_ref.id.to_string()} (\{texture_ref.width.to_string()}x\{texture_ref.height.to_string()})",
    )
    return Some(texture_capture)
  }
  let fallback_upper_bound = @renderer.screenshot_resource_id_upper_bound()
  if fallback_upper_bound > 0 {
    @window.host_debug_string(
      value="[screenshot] surface capture remains black; no non-black same-size texture in resource_id<= \{fallback_upper_bound.to_string()}",
    )
  }
  Some(surface_capture)
}

///|
pub fn winit_runner(app : @app.App[@ecs.World]) -> @app.RunnerFn {
  fn() {
    guard @window.window_ensure_primary_host(app.world())
      is Some(primary_window) else {
      app.run_startup().update() |> ignore
      return
    }
    let device = @render.host_gpu_request_device()
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
    let runner_state = WinitAppRunnerState::{
      device,
      primary_window,
      app_ref,
      runner_surfaces_ref: Ref::new([]),
      debug_screenshot_path,
      debug_screenshot_exit_on_save,
      debug_screenshot_texture_id,
      debug_screenshot_frame,
      debug_screenshot_surface_index,
      debug_screenshot_requested_ref,
      debug_screenshot_saved_ref,
      debug_screenshot_capture_id_ref,
      debug_screenshot_render_frame_ref,
      frame_limit: runner_frame_limit(),
      frame_count_ref: Ref::new(0),
    }
    @windowing.native_event_loop().run_app(runner_state)
  }
}
