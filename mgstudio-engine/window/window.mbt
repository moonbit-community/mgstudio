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
) -> HostWindow {
  @platform.window_create(width, height, title_id)
}

///|
pub fn host_window_poll_events(window : HostWindow) -> Unit {
  @platform.window_poll_events(window)
}

///|
pub fn host_window_get_width(window : HostWindow) -> Int {
  @platform.window_get_width(window)
}

///|
pub fn host_window_get_height(window : HostWindow) -> Int {
  @platform.window_get_height(window)
}

///|
pub fn host_window_get_scale_factor(window : HostWindow) -> Float {
  @platform.window_get_scale_factor(window)
}

///|
pub fn host_window_should_close(window : HostWindow) -> Bool {
  @platform.window_should_close(window)
}

///|
pub fn host_window_request_close(window : HostWindow) -> Unit {
  @platform.window_request_close(window)
}

///|
pub fn host_window_run_loop(step : FuncRef[() -> Unit]) -> Unit {
  @platform.window_run_loop(step)
}

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
pub type HostGpuDevice = Int

///|
pub type HostGpuQueue = Int

///|
pub type HostGpuSurface = Int

///|
pub type HostGpuFrame = Int

///|
pub fn host_gpu_request_device() -> HostGpuDevice {
  @platform.gpu_request_device()
}

///|
pub fn host_gpu_get_queue(device : HostGpuDevice) -> HostGpuQueue {
  @platform.gpu_get_queue(device)
}

///|
pub fn host_gpu_create_surface(window : HostWindow) -> HostGpuSurface {
  @platform.gpu_create_surface(window)
}

///|
pub fn host_gpu_configure_surface(
  device : HostGpuDevice,
  surface : HostGpuSurface,
  width : Int,
  height : Int,
) -> Unit {
  @platform.gpu_configure_surface(device, surface, width, height)
}

///|
pub fn host_gpu_begin_frame(surface : HostGpuSurface) -> HostGpuFrame {
  @platform.gpu_begin_frame(surface)
}

///|
pub fn host_gpu_end_frame(frame : HostGpuFrame) -> Unit {
  @platform.gpu_end_frame(frame)
}

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
) -> Unit {
  @platform.gpu_begin_pass(
    target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
    camera_rotation, camera_scale, viewport_x, viewport_y, viewport_width, viewport_height,
  )
}

///|
pub fn host_gpu_begin_pass_3d(
  target_id : Int,
  width : Int,
  height : Int,
  clear_r : Float,
  clear_g : Float,
  clear_b : Float,
  clear_a : Float,
  camera_x : Float,
  camera_y : Float,
  camera_z : Float,
  camera_rot_x : Float,
  camera_rot_y : Float,
  camera_rot_z : Float,
  camera_rot_w : Float,
  camera_fov_y : Float,
  camera_near : Float,
  camera_far : Float,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  ambient_r : Float,
  ambient_g : Float,
  ambient_b : Float,
  ambient_brightness : Float,
  directional_dir_x : Float,
  directional_dir_y : Float,
  directional_dir_z : Float,
  directional_color_r : Float,
  directional_color_g : Float,
  directional_color_b : Float,
  directional_illuminance : Float,
  point_pos_x : Float,
  point_pos_y : Float,
  point_pos_z : Float,
  point_color_r : Float,
  point_color_g : Float,
  point_color_b : Float,
  point_intensity : Float,
  point_range : Float,
  spot_pos_x : Float,
  spot_pos_y : Float,
  spot_pos_z : Float,
  spot_dir_x : Float,
  spot_dir_y : Float,
  spot_dir_z : Float,
  spot_color_r : Float,
  spot_color_g : Float,
  spot_color_b : Float,
  spot_intensity : Float,
  spot_range : Float,
  spot_inner_angle : Float,
  spot_outer_angle : Float,
) -> Unit {
  @platform.gpu_begin_pass_3d(
    target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
    camera_z, camera_rot_x, camera_rot_y, camera_rot_z, camera_rot_w, camera_fov_y,
    camera_near, camera_far, viewport_x, viewport_y, viewport_width, viewport_height,
    ambient_r, ambient_g, ambient_b, ambient_brightness, directional_dir_x, directional_dir_y,
    directional_dir_z, directional_color_r, directional_color_g, directional_color_b,
    directional_illuminance, point_pos_x, point_pos_y, point_pos_z, point_color_r,
    point_color_g, point_color_b, point_intensity, point_range, spot_pos_x, spot_pos_y,
    spot_pos_z, spot_dir_x, spot_dir_y, spot_dir_z, spot_color_r, spot_color_g, spot_color_b,
    spot_intensity, spot_range, spot_inner_angle, spot_outer_angle,
  )
}

///|
pub fn host_gpu_set_scissor(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> Unit {
  @platform.gpu_set_scissor(x, y, width, height)
}

///|
pub fn host_gpu_clear_scissor() -> Unit {
  @platform.gpu_clear_scissor()
}

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
) -> Unit {
  @platform.gpu_draw_sprite(
    texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
  )
}

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
) -> Unit {
  @platform.gpu_draw_sprite_uv(
    texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
    uv_min_x, uv_min_y, uv_max_x, uv_max_y,
  )
}

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
) -> Unit {
  @platform.gpu_draw_ui_rect(
    texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
    uv_min_x, uv_min_y, uv_max_x, uv_max_y, flags, radius_tl, radius_tr, radius_br,
    radius_bl, border_left, border_top, border_right, border_bottom,
  )
}

///|
/// Draw a UI box shadow using a dedicated pipeline adapted from Bevy's `box_shadow.wgsl`.
///
/// Parameters:
/// - `x/y/rotation`: world-space transform for the shadow quad (centered).
/// - `scale_x/scale_y`: quad bounds (shadow size + 6*blur) in world units.
/// - `size_x/size_y`: inner shadow size (node size + spread) in world units.
/// - `radius_*`: corner radii (top-left, top-right, bottom-right, bottom-left) in world units.
/// - `blur`: blur radius in world units.
/// - `samples`: integration steps for the gaussian approximation (>= 1 recommended).
pub fn host_gpu_draw_ui_box_shadow(
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
  size_x : Float,
  size_y : Float,
  radius_tl : Float,
  radius_tr : Float,
  radius_br : Float,
  radius_bl : Float,
  blur : Float,
  samples : Int,
) -> Unit {
  @platform.gpu_draw_ui_box_shadow(
    texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
    size_x, size_y, radius_tl, radius_tr, radius_br, radius_bl, blur, samples,
  )
}

///|
/// Draw a UI texture slice (9-slice / tiled) using the Bevy-aligned texture
/// slicing shader.
///
/// Parameters:
/// - `scale_x/scale_y`: quad bounds in world units.
/// - `texture_slices`: normalized texture slice dividing lines (left, top, right, bottom).
/// - `target_slices`: normalized target slice dividing lines (left, top, right, bottom).
/// - `repeat`: repeat factors (side_x, side_y, center_x, center_y).
/// - `atlas_rect`: normalized atlas rect (left, top, right, bottom).
pub fn host_gpu_draw_ui_texture_slice(
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
  texture_slice_l : Float,
  texture_slice_t : Float,
  texture_slice_r : Float,
  texture_slice_b : Float,
  target_slice_l : Float,
  target_slice_t : Float,
  target_slice_r : Float,
  target_slice_b : Float,
  repeat_side_x : Float,
  repeat_side_y : Float,
  repeat_center_x : Float,
  repeat_center_y : Float,
  atlas_l : Float,
  atlas_t : Float,
  atlas_r : Float,
  atlas_b : Float,
) -> Unit {
  @platform.gpu_draw_ui_texture_slice(
    texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
    texture_slice_l, texture_slice_t, texture_slice_r, texture_slice_b, target_slice_l,
    target_slice_t, target_slice_r, target_slice_b, repeat_side_x, repeat_side_y,
    repeat_center_x, repeat_center_y, atlas_l, atlas_t, atlas_r, atlas_b,
  )
}

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
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
) -> Unit {
  @platform.gpu_draw_mesh(
    mesh_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
    texture_id, uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y,
  )
}

///|
pub fn host_gpu_draw_mesh3d(
  mesh_id : Int,
  x : Float,
  y : Float,
  z : Float,
  rotation_x : Float,
  rotation_y : Float,
  rotation_z : Float,
  rotation_w : Float,
  scale_x : Float,
  scale_y : Float,
  scale_z : Float,
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  emissive_r : Float,
  emissive_g : Float,
  emissive_b : Float,
  unlit : Float,
  metallic : Float,
  roughness : Float,
  reflectance : Float,
) -> Unit {
  @platform.gpu_draw_mesh3d(
    mesh_id, x, y, z, rotation_x, rotation_y, rotation_z, rotation_w, scale_x, scale_y,
    scale_z, color_r, color_g, color_b, color_a, texture_id, uv_offset_x, uv_offset_y,
    uv_scale_x, uv_scale_y, normal_texture_id, emissive_texture_id, metallic_roughness_texture_id,
    occlusion_texture_id, emissive_r, emissive_g, emissive_b, unlit, metallic, roughness,
    reflectance,
  )
}

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
) -> Unit {
  @platform.gpu_draw_gizmo_line(
    start_x, start_y, start_r, start_g, start_b, start_a, end_x, end_y, end_r, end_g,
    end_b, end_a, line_width, style_kind, gap_scale, line_scale,
  )
}

///|
pub fn host_gpu_end_pass() -> Unit {
  @platform.gpu_end_pass()
}

///|
pub fn host_gpu_create_render_target(
  width : Int,
  height : Int,
  nearest : Bool,
) -> Int {
  @platform.gpu_create_render_target(width, height, nearest)
}

///|
pub fn host_gpu_create_mesh_capsule(
  radius : Float,
  half_length : Float,
  segments : Int,
) -> Int {
  @platform.gpu_create_mesh_capsule(radius, half_length, segments)
}

///|
pub fn host_gpu_create_mesh_rectangle(width : Float, height : Float) -> Int {
  @platform.gpu_create_mesh_rectangle(width, height)
}

///|
pub fn host_gpu_create_mesh_triangles(vertices_xy_csv : String) -> Int {
  @core.with_host_string_id(vertices_xy_csv, fn(text_id) {
    host_gpu_create_mesh_triangles_id(text_id)
  })
}

///|
fn host_gpu_create_mesh_triangles_id(vertices_xy_csv_id : Int) -> Int {
  @platform.gpu_create_mesh_triangles(vertices_xy_csv_id)
}

///|
pub fn host_gpu_create_mesh_triangles3d(vertices_xyzuvrgba_csv : String) -> Int {
  @core.with_host_string_id(vertices_xyzuvrgba_csv, fn(text_id) {
    host_gpu_create_mesh_triangles3d_id(text_id)
  })
}

///|
fn host_gpu_create_mesh_triangles3d_id(vertices_xyzuvrgba_csv_id : Int) -> Int {
  @platform.gpu_create_mesh_triangles3d(vertices_xyzuvrgba_csv_id)
}

///|
pub fn host_debug_string(value : String) -> Unit {
  @core.with_host_string_id(value, fn(text_id) { host_debug_string_id(text_id) })
}

///|
fn host_debug_string_id(value_id : Int) -> Unit {
  @platform.debug_string(value_id)
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
