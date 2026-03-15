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
  host_window : @window.HostWindow
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
    @window.host_debug_string(
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
    @window.host_debug_string(
      value="[screenshot] surface capture remains black; no non-black same-size texture in resource_id<= " +
        fallback_upper_bound.to_string(),
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
      @window.window_poll_host_events(app_ref.val.world())

      let world = app_ref.val.world()
      let host_entries = @window.window_host_entries(world)
      let next_surfaces : Array[RunnerSurfaceBinding] = []
      let previous_surfaces = runner_surfaces_ref.val
      for entry in host_entries {
        let host_window = entry.host_window
        if runner_surface_binding_find(previous_surfaces, host_window)
          is Some(previous) {
          let width = @window.host_window_get_width(host_window)
          let height = @window.host_window_get_height(host_window)
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
        let width = @window.host_window_get_width(host_window)
        let height = @window.host_window_get_height(host_window)
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
          primary_window,
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
        @window.screenshot_queue_capture_requests(app_ref.val.world())
        for frame_binding in frame_bindings {
          @render.host_gpu_end_frame(frame_binding.frame)
        }
        @window.screenshot_finalize_capture_requests(app_ref.val.world())
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
              @window.window_request_close_all_hosts(app_ref.val.world())
              runner_state.val.tick = None
              return
            }
          }
        }
      } else {
        app_ref.val = app_ref.val.run_once()
      }
      if app_ref.val.should_exit() is Some(_) {
        @window.window_request_close_all_hosts(app_ref.val.world())
        runner_state.val.tick = None
        return
      }
      if @window.host_window_should_close(primary_window) {
        @window.window_request_close_all_hosts(app_ref.val.world())
        // Web runtimes cannot block in `window_run_loop`, so cleanup must happen
        // inside the tick closure (not after `window_run_loop` returns).
        runner_state.val.tick = None
      }
    })
    let tick : FuncRef[() -> Unit] = fn() { runner_tick() }
    @window.host_window_run_loop(tick)
  }
}
