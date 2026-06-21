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
fn runner_surface_physical_width(window : @window.Window?) -> Int {
  match window {
    Some(value) => value.physical_width()
    None => 0
  }
}

///|
fn runner_surface_physical_height(window : @window.Window?) -> Int {
  match window {
    Some(value) => value.physical_height()
    None => 0
  }
}

///|
fn runner_now_millis() -> Int64 {
  @core.Instant::now().as_millis()
}

///|
fn winit_runner_trace_span(name : String, run : () -> Unit) -> Unit {
  let trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    name,
  )
  run()
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    name,
    trace_start_us,
  )
}

///|
fn runner_update_mode_for_world(world : @ecs.World) -> UpdateMode {
  let settings = match world.get_resource(WinitSettings::resource()) {
    Some(value) => value
    None => WinitSettings::WinitSettings()
  }
  let mut focused = false
  for entry in @window.window_host_entries(world) {
    match (try! world.get_by_key(entry.entity, @window.Window::component())) {
      Some(window) => if window.focused { focused = true }
      None => ()
    }
  }
  settings.update_mode(focused)
}

///|
fn runner_all_windows_invisible(world : @ecs.World) -> Bool {
  let entries = @window.window_host_entries(world)
  if entries.length() == 0 {
    return true
  }
  for entry in entries {
    match (try! world.get_by_key(entry.entity, @window.Window::component())) {
      Some(window) => if window.visible { return false }
      None => ()
    }
  }
  true
}

///|
fn runner_has_logical_windows(world : @ecs.World) -> Bool {
  let found = Ref(false)
  try! world
  .query_entities_filtered(@ecs.With::new(@window.ecs_key_window))
  .view(fn(_query_entity, _entity) { found.val = true })
  found.val
}

///|
fn runner_wait_elapsed_from_start_cause(
  cause : @window_core.StartCause,
) -> Bool {
  match cause {
    WaitCancelled(_, requested_resume) =>
      match requested_resume {
        Some(resume_time_ms) => resume_time_ms <= runner_now_millis()
        None => false
      }
    _ => true
  }
}

///|
fn runner_should_update(
  mode : UpdateMode,
  wait_elapsed : Bool,
  window_event_received : Bool,
  device_event_received : Bool,
  user_event_received : Bool,
) -> Bool {
  match mode {
    Continuous =>
      wait_elapsed ||
      user_event_received ||
      window_event_received ||
      device_event_received
    Reactive(
      _,
      react_to_device_events,
      react_to_user_events,
      react_to_window_events
    ) =>
      wait_elapsed ||
      (react_to_device_events && device_event_received) ||
      (react_to_user_events && user_event_received) ||
      (react_to_window_events && window_event_received)
  }
}

///|
fn runner_next_reactive_control_flow(
  start_time_ms : Int64,
  wait : @core.Duration,
) -> @window_core.ControlFlow {
  let wait_ms64 = wait.as_millis()
  let wait_ms = if wait_ms64 > 2147483647L {
    2147483647
  } else {
    wait_ms64.to_int()
  }
  @window_core.ControlFlow::wait_duration(start_time_ms, wait_ms)
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
      let token = value.trim().to_owned()
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
  mut primary_window : @window.HostWindow
  app_ref : Ref[@app.App[@ecs.World]]
  mut runner_surfaces : Array[RunnerSurfaceBinding]
  debug_screenshot_path : String?
  debug_screenshot_exit_on_save : Bool
  debug_screenshot_texture_id : Int
  debug_screenshot_frame : Int
  debug_screenshot_surface_index : Int
  mut debug_screenshot_requested : Bool
  mut debug_screenshot_saved : Bool
  mut debug_screenshot_capture_id : Int
  mut debug_screenshot_render_frame : Int
  frame_limit : Int
  frame_count_ref : Ref[Int]
  mut update_mode : UpdateMode
  mut window_event_received : Bool
  mut device_event_received : Bool
  mut user_event_received : Bool
  mut redraw_requested : Bool
  mut ran_update_since_last_redraw : Bool
  mut wait_elapsed : Bool
  mut startup_forced_updates : Int
  mut scheduled_tick_start_ms : Int64?
  request_redraw_cursor : @ecs.MessageCursor[@window.RequestRedraw]
}

///|
fn WinitAppRunnerState::reset_on_update(self : WinitAppRunnerState) -> Unit {
  self.window_event_received = false
  self.device_event_received = false
  self.user_event_received = false
}

///|
fn WinitAppRunnerState::request_redraw_for_windows(
  self : WinitAppRunnerState,
) -> Unit {
  let world = self.app_ref.val.world()
  let entries = @window.window_host_entries(world)
  if entries.length() == 0 && self.primary_window > 0 {
    @window.host_window_request_redraw(self.primary_window)
    return
  }
  for entry in entries {
    @window.host_window_request_redraw(entry.host_window)
  }
}

///|
fn WinitAppRunnerState::read_app_redraw_requests(
  self : WinitAppRunnerState,
) -> Bool {
  let world = self.app_ref.val.world()
  if !world.contains_message(@window.RequestRedraw::message()) {
    return false
  }
  let reader = world.message_reader(
    @window.RequestRedraw::message(),
    cursor=self.request_redraw_cursor,
  )
  reader.read().length() > 0
}

///|
fn WinitAppRunnerState::mark_app_update_complete(
  self : WinitAppRunnerState,
) -> Unit {
  if self.frame_limit > 0 {
    self.frame_count_ref.val = self.frame_count_ref.val + 1
    if self.frame_count_ref.val >= self.frame_limit {
      @window.window_request_close_all_hosts(self.app_ref.val.world())
    }
  }
}

///|
fn WinitAppRunnerState::run_tick(self : WinitAppRunnerState) -> Unit {
  self.reset_on_update()
  let world = self.app_ref.val.world()
  if self.primary_window <= 0 {
    match @window.window_ensure_primary_host(world) {
      Some(primary_window) => self.primary_window = primary_window
      None => ()
    }
  }
  winit_runner_trace_span("mgstudio_winit::runner.backend_sync", fn() {
    winit_window_backend_sync_system(world)
  })
  let surface_bindings_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::runner.surface_bindings",
  )
  let host_entries = @window.window_host_entries(world)
  @app.timeline_trace_emit_counter_int(
    "winit.runner.host_windows",
    host_entries.length(),
  )
  let next_surfaces : Array[RunnerSurfaceBinding] = []
  let previous_surfaces = self.runner_surfaces
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
    let width = runner_surface_physical_width(window_component)
    let height = runner_surface_physical_height(window_component)
    if runner_surface_binding_find(previous_surfaces, host_window)
      is Some(previous) {
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
  self.runner_surfaces = next_surfaces
  @app.timeline_trace_emit_counter_int(
    "winit.runner.surface_bindings",
    self.runner_surfaces.length(),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::runner.surface_bindings",
    surface_bindings_trace_start_us,
  )

  let next_render_frame = self.debug_screenshot_render_frame + 1
  let ordered_surface_bindings = runner_surface_binding_ordered(
    self.runner_surfaces,
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
  let screenshot_queue_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::runner.screenshot_capture_requests",
  )
  for i in 0..<ordered_surface_bindings.length() {
    if !self.debug_screenshot_requested &&
      self.debug_screenshot_path is Some(_) &&
      self.debug_screenshot_texture_id <= 0 &&
      next_render_frame >= self.debug_screenshot_frame &&
      i == capture_surface_index {
      let capture_id = @render.screenshot_capture_surface_request()
      if capture_id > 0 {
        self.debug_screenshot_requested = true
        self.debug_screenshot_capture_id = capture_id
      }
    }
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::runner.screenshot_capture_requests",
    screenshot_queue_trace_start_us,
  )
  winit_runner_trace_span("mgstudio_winit::runner.app_run_once", fn() {
    self.app_ref.val = self.app_ref.val.run_once()
  })
  self.debug_screenshot_render_frame = next_render_frame
  if !self.debug_screenshot_saved && self.debug_screenshot_path is Some(path) {
    let capture0 = if self.debug_screenshot_texture_id > 0 &&
      next_render_frame >= self.debug_screenshot_frame {
      @render.screenshot_capture_texture_sync(
        texture_id=self.debug_screenshot_texture_id,
      )
    } else if self.debug_screenshot_capture_id > 0 {
      @render.screenshot_take_capture_result(self.debug_screenshot_capture_id)
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
      self.debug_screenshot_saved = true
      if self.debug_screenshot_exit_on_save {
        @window.window_request_close_all_hosts(self.app_ref.val.world())
        return
      }
    }
  }
  if @render.screenshot_parity_capture_completed() {
    @window.window_request_close_all_hosts(self.app_ref.val.world())
    return
  }
  if self.app_ref.val.should_exit() is Some(_) {
    @window.window_request_close_all_hosts(self.app_ref.val.world())
    return
  }
  if self.primary_window > 0 &&
    @window.host_window_should_close(self.primary_window) {
    @window.window_request_close_all_hosts(self.app_ref.val.world())
  }
}

///|
fn WinitAppRunnerState::redraw_requested(
  self : WinitAppRunnerState,
  event_loop : @window_macos.ActiveEventLoop,
) -> Unit {
  let redraw_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::redraw_requested",
  )
  let begin_frame_ms = runner_now_millis()
  let mode = runner_update_mode_for_world(self.app_ref.val.world())
  let mut should_update = runner_should_update(
    mode,
    self.wait_elapsed,
    self.window_event_received,
    self.device_event_received,
    self.user_event_received,
  )
  if self.startup_forced_updates > 0 {
    self.startup_forced_updates = self.startup_forced_updates - 1
    should_update = true
  }
  @app.timeline_trace_emit_counter_int(
    "winit.redraw.should_update",
    if should_update {
      1
    } else {
      0
    },
  )
  if should_update {
    if !self.ran_update_since_last_redraw ||
      runner_all_windows_invisible(self.app_ref.val.world()) {
      winit_runner_trace_span("mgstudio_winit::redraw.run_tick", fn() {
        self.run_tick()
      })
      self.mark_app_update_complete()
      self.ran_update_since_last_redraw = true
    } else {
      self.redraw_requested = true
    }
    if self.read_app_redraw_requests() {
      self.redraw_requested = true
    }
  }

  if mode != self.update_mode {
    self.redraw_requested = true
    self.wait_elapsed = true
    self.scheduled_tick_start_ms = None
    self.update_mode = mode
  }

  let control_flow_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::redraw.control_flow",
  )
  match mode {
    Continuous => {
      event_loop.set_control_flow(@window_core.ControlFlow::Wait)
      self.redraw_requested = true
    }
    Reactive(wait, _, _, _) =>
      if self.wait_elapsed {
        self.redraw_requested = true
        let start_time_ms = match self.scheduled_tick_start_ms {
          Some(value) => value
          None => begin_frame_ms
        }
        let control_flow = runner_next_reactive_control_flow(
          start_time_ms, wait,
        )
        match control_flow {
          @window_core.ControlFlow::WaitUntil(next_ms) =>
            self.scheduled_tick_start_ms = Some(next_ms)
          _ => self.scheduled_tick_start_ms = Some(begin_frame_ms)
        }
        event_loop.set_control_flow(control_flow)
      }
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::redraw.control_flow",
    control_flow_trace_start_us,
  )

  if self.redraw_requested {
    @app.timeline_trace_emit_counter_int("winit.redraw.requested", 1)
    winit_runner_trace_span("mgstudio_winit::redraw.request_redraw", fn() {
      self.request_redraw_for_windows()
    })
    self.redraw_requested = false
  } else {
    @app.timeline_trace_emit_counter_int("winit.redraw.requested", 0)
  }

  if self.app_ref.val.should_exit() is Some(_) {
    @window.window_request_close_all_hosts(self.app_ref.val.world())
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::System,
      "mgstudio_winit::redraw_requested",
      redraw_trace_start_us,
    )
    event_loop.exit()
    return
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::System,
    "mgstudio_winit::redraw_requested",
    redraw_trace_start_us,
  )
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with fn new_events(
  self,
  _event_loop,
  cause,
) {
  self.wait_elapsed = runner_wait_elapsed_from_start_cause(cause)
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with fn window_event(
  self,
  event_loop,
  window_id,
  event,
) {
  self.window_event_received = true
  winit_runner_trace_span("mgstudio_winit::window_event.dispatch", fn() {
    @windowing.runner_process_window_event(window_id.into_raw(), event)
  })
  match event {
    RedrawRequested => {
      @app.timeline_trace_emit_counter_int(
        "winit.window_event.redraw_requested", 1,
      )
      self.ran_update_since_last_redraw = false
      winit_runner_trace_span("mgstudio_winit::window_event.redraw_requested", fn() {
        self.redraw_requested(event_loop)
      })
    }
    _ =>
      @app.timeline_trace_emit_counter_int(
        "winit.window_event.redraw_requested", 0,
      )
  }
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with fn device_event(
  self,
  _event_loop,
  _device_id,
  _event,
) {
  self.device_event_received = true
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with fn resumed(
  _self,
  _event_loop,
) {
  @windowing.runner_handle_resumed()
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with fn can_create_surfaces(
  self,
  _event_loop,
) {
  match @window.window_ensure_primary_host(self.app_ref.val.world()) {
    Some(primary_window) => self.primary_window = primary_window
    None => ()
  }
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with fn suspended(
  _self,
  _event_loop,
) {
  @windowing.runner_handle_suspended()
}

///|
impl @window_macos.ApplicationHandler for WinitAppRunnerState with fn about_to_wait(
  self,
  event_loop,
) {
  winit_runner_trace_span("mgstudio_winit::about_to_wait.redraw_requested", fn() {
    self.redraw_requested(event_loop)
  })
  if !@windowing.any_window_open() &&
    !runner_has_logical_windows(self.app_ref.val.world()) {
    event_loop.exit()
  } else if !@windowing.any_window_open() {
    event_loop.set_control_flow(@window_core.ControlFlow::Poll)
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
    let device = @render.host_gpu_request_device()
    let app_ref : Ref[@app.App[@ecs.World]] = Ref(app.run_startup())
    let debug_screenshot_path = match
      @sys.get_env_var("MGSTUDIO_SCREENSHOT_PATH") {
      Some(path) if path.trim().to_owned() != "" => Some(path.trim().to_owned())
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
    let runner_state = WinitAppRunnerState::{
      device,
      primary_window: 0,
      app_ref,
      runner_surfaces: [],
      debug_screenshot_path,
      debug_screenshot_exit_on_save,
      debug_screenshot_texture_id,
      debug_screenshot_frame,
      debug_screenshot_surface_index,
      debug_screenshot_requested: false,
      debug_screenshot_saved: false,
      debug_screenshot_capture_id: 0,
      debug_screenshot_render_frame: 0,
      frame_limit: runner_frame_limit(),
      frame_count_ref: Ref(0),
      update_mode: UpdateMode::Continuous,
      window_event_received: false,
      device_event_received: false,
      user_event_received: false,
      redraw_requested: false,
      ran_update_since_last_redraw: false,
      wait_elapsed: false,
      startup_forced_updates: 5,
      scheduled_tick_start_ms: None,
      request_redraw_cursor: @ecs.MessageCursor::MessageCursor(),
    }
    @windowing.native_event_loop().run_app(runner_state)
  }
}
