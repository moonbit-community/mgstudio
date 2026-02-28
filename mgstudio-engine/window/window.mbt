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
  mut last_width : Int
  mut last_height : Int
  mut has_last_size : Bool
}

///|
let window_state : Ref[WindowState] = @ref.new(WindowState::{
  window: None,
  last_width: 0,
  last_height: 0,
  has_last_size: false,
})

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
  BracketLeft
  BracketRight
  Quote
}

///|
pub(all) enum MouseButton {
  Left
  Right
  Middle
}

///|
pub(all) enum CursorGrabMode {
  GrabNone
  GrabConfined
  GrabLocked
}

///|
pub(all) enum CursorIcon {
  Default
  EwResize
}

///|
pub(all) enum WindowMode {
  Windowed
  BorderlessFullscreen
  Fullscreen
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
pub struct WindowResized {
  width : Int
  height : Int
}

///|
let window_resized_events_ref : Ref[@core.Messages[WindowResized]] = Ref::new(
  @core.Messages::new(),
)

///|
pub fn host_window_create(
  width~ : Int,
  height~ : Int,
  title~ : String,
) -> HostWindow {
  @core.with_host_string_id(title, fn(title_id) {
    host_window_create_id(width~, height~, title_id~)
  })
}

///|
fn host_window_create_id(
  width~ : Int,
  height~ : Int,
  title_id~ : Int,
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
pub fn host_window_set_title(window : HostWindow, title~ : String) -> Unit {
  @core.with_host_string_id(title, fn(title_id) {
    host_window_set_title_id(window, title_id~)
  })
}

///|
fn host_window_set_title_id(window : HostWindow, title_id~ : Int) -> Unit = "mgstudio_host" "window_set_title"

///|
pub fn host_window_set_size(
  window : HostWindow,
  width~ : Int,
  height~ : Int,
) -> Unit = "mgstudio_host" "window_set_size"

///|
pub fn host_window_set_resizable(
  window : HostWindow,
  resizable~ : Bool,
) -> Unit = "mgstudio_host" "window_set_resizable"

///|
pub fn host_window_set_cursor_visible(
  window : HostWindow,
  visible~ : Bool,
) -> Unit = "mgstudio_host" "window_set_cursor_visible"

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
    Default => 0
    EwResize => 1
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
) -> Unit = "mgstudio_host" "window_set_cursor_grab_mode"

///|
pub fn host_window_set_cursor_icon(
  window : HostWindow,
  icon~ : CursorIcon,
) -> Unit {
  host_window_set_cursor_icon_raw(window~, icon=cursor_icon_to_int(icon))
}

///|
fn host_window_set_cursor_icon_raw(window~ : HostWindow, icon~ : Int) -> Unit = "mgstudio_host" "window_set_cursor_icon"

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
fn host_window_set_mode_raw(window~ : HostWindow, mode~ : Int) -> Unit = "mgstudio_host" "window_set_mode"

///|
pub fn host_window_set_position(
  window : HostWindow,
  x~ : Int,
  y~ : Int,
) -> Unit = "mgstudio_host" "window_set_position"

///|
pub fn host_window_get_position_x(window : HostWindow) -> Int = "mgstudio_host" "window_get_position_x"

///|
pub fn host_window_get_position_y(window : HostWindow) -> Int = "mgstudio_host" "window_get_position_y"

///|
pub fn window_set_handle(window : HostWindow) -> Unit {
  window_state.val.window = Some(window)
  window_state.val.has_last_size = false
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
pub fn window_set_title(title~ : String) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_title(window, title~)
  }
}

///|
pub fn window_set_size(width~ : Int, height~ : Int) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_size(window, width~, height~)
  }
}

///|
pub fn window_set_resizable(resizable~ : Bool) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_resizable(window, resizable~)
  }
}

///|
pub fn window_set_cursor_visible(visible~ : Bool) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_cursor_visible(window, visible~)
  }
}

///|
pub fn window_set_cursor_grab_mode(mode~ : CursorGrabMode) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_cursor_grab_mode(window, mode~)
  }
}

///|
pub fn window_set_cursor_icon(icon~ : CursorIcon) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_cursor_icon(window, icon~)
  }
}

///|
pub fn window_set_mode(mode~ : WindowMode) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_mode(window, mode~)
  }
}

///|
pub fn window_set_position(x~ : Int, y~ : Int) -> Unit {
  if window_state.val.window is Some(window) {
    host_window_set_position(window, x~, y~)
  }
}

///|
fn[W : @core.SystemContextWorld] window_world_system_ticks(
  world : W,
) -> @core.SystemTicks {
  world.get_system_context().ticks()
}

///|
fn window_resized_events_reader(
  ticks : @core.SystemTicks,
) -> @core.MessageReader[WindowResized] {
  window_resized_events_ref.val.reader(ticks)
}

///|
fn window_resized_events_writer(
  tick : @core.Tick,
) -> @core.MessageWriter[WindowResized] {
  window_resized_events_ref.val.writer(tick)
}

///|
pub fn[W : @core.SystemContextWorld] window_resized_events(
  world : W,
) -> @core.MessageReader[WindowResized] {
  window_resized_events_reader(window_world_system_ticks(world))
}

///|
pub impl @core.Message for WindowResized with reader(ticks) {
  window_resized_events_reader(ticks)
}

///|
pub impl @core.Message for WindowResized with writer(tick) {
  window_resized_events_writer(tick)
}

///|
pub fn[W : @core.ChangeTickWorld] window_poll_resize_system(world : W) -> Unit {
  guard window_state.val.window is Some(window) else { return }
  let width = host_window_get_width(window)
  let height = host_window_get_height(window)
  if !window_state.val.has_last_size {
    window_state.val.last_width = width
    window_state.val.last_height = height
    window_state.val.has_last_size = true
    return
  }
  if width == window_state.val.last_width &&
    height == window_state.val.last_height {
    return
  }
  let tick = world.read_change_tick()
  window_resized_events_ref.val.send(tick, WindowResized::{ width, height })
  window_state.val.last_width = width
  window_state.val.last_height = height
}

///|
pub fn window_position_x() -> Int {
  if window_state.val.window is Some(window) {
    host_window_get_position_x(window)
  } else {
    0
  }
}

///|
pub fn window_position_y() -> Int {
  if window_state.val.window is Some(window) {
    host_window_get_position_y(window)
  } else {
    0
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
  device~ : HostGpuDevice,
  surface~ : HostGpuSurface,
  width~ : Int,
  height~ : Int,
) -> Unit = "mgstudio_host" "gpu_configure_surface"

///|
pub fn host_gpu_begin_frame(surface : HostGpuSurface) -> HostGpuFrame = "mgstudio_host" "gpu_begin_frame"

///|
pub fn host_gpu_end_frame(frame : HostGpuFrame) -> Unit = "mgstudio_host" "gpu_end_frame"

///|
pub fn host_gpu_begin_pass(
  target_id~ : Int,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_rotation~ : Float,
  camera_scale~ : Float,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  viewport_depth_min~ : Float,
  viewport_depth_max~ : Float,
  clear_enabled~ : Int,
) -> Unit = "mgstudio_host" "gpu_begin_pass"

///|
pub fn host_gpu_begin_pass_3d(
  target_id~ : Int,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_z~ : Float,
  camera_rot_x~ : Float,
  camera_rot_y~ : Float,
  camera_rot_z~ : Float,
  camera_rot_w~ : Float,
  camera_fov_y~ : Float,
  camera_near~ : Float,
  camera_far~ : Float,
  viewport_x~ : Int,
  viewport_y~ : Int,
  viewport_width~ : Int,
  viewport_height~ : Int,
  ambient_r~ : Float,
  ambient_g~ : Float,
  ambient_b~ : Float,
  ambient_brightness~ : Float,
  directional_dir_x~ : Float,
  directional_dir_y~ : Float,
  directional_dir_z~ : Float,
  directional_color_r~ : Float,
  directional_color_g~ : Float,
  directional_color_b~ : Float,
  directional_illuminance~ : Float,
  point_pos_x~ : Float,
  point_pos_y~ : Float,
  point_pos_z~ : Float,
  point_color_r~ : Float,
  point_color_g~ : Float,
  point_color_b~ : Float,
  point_intensity~ : Float,
  point_range~ : Float,
  spot_pos_x~ : Float,
  spot_pos_y~ : Float,
  spot_pos_z~ : Float,
  spot_dir_x~ : Float,
  spot_dir_y~ : Float,
  spot_dir_z~ : Float,
  spot_color_r~ : Float,
  spot_color_g~ : Float,
  spot_color_b~ : Float,
  spot_intensity~ : Float,
  spot_range~ : Float,
  spot_inner_angle~ : Float,
  spot_outer_angle~ : Float,
  sub_camera_view_scale_x~ : Float,
  sub_camera_view_scale_y~ : Float,
  sub_camera_view_bias_x~ : Float,
  sub_camera_view_bias_y~ : Float,
  previous_camera_x~ : Float,
  previous_camera_y~ : Float,
  previous_camera_z~ : Float,
  previous_camera_rot_x~ : Float,
  previous_camera_rot_y~ : Float,
  previous_camera_rot_z~ : Float,
  previous_camera_rot_w~ : Float,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit = "mgstudio_host" "gpu_begin_pass_3d"

///|
pub fn host_gpu_set_scissor(
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
) -> Unit = "mgstudio_host" "gpu_set_scissor"

///|
pub fn host_gpu_clear_scissor() -> Unit = "mgstudio_host" "gpu_clear_scissor"

///|
pub fn host_gpu_draw_sprite(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
) -> Unit = "mgstudio_host" "gpu_draw_sprite"

///|
pub fn host_gpu_draw_sprite_uv(
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  uv_min_x~ : Float,
  uv_min_y~ : Float,
  uv_max_x~ : Float,
  uv_max_y~ : Float,
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
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  uv_min_x~ : Float,
  uv_min_y~ : Float,
  uv_max_x~ : Float,
  uv_max_y~ : Float,
  flags~ : Int,
  radius_tl~ : Float,
  radius_tr~ : Float,
  radius_br~ : Float,
  radius_bl~ : Float,
  border_left~ : Float,
  border_top~ : Float,
  border_right~ : Float,
  border_bottom~ : Float,
) -> Unit = "mgstudio_host" "gpu_draw_ui_rect"

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
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  size_x~ : Float,
  size_y~ : Float,
  radius_tl~ : Float,
  radius_tr~ : Float,
  radius_br~ : Float,
  radius_bl~ : Float,
  blur~ : Float,
  samples~ : Int,
) -> Unit = "mgstudio_host" "gpu_draw_ui_box_shadow"

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
  texture_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_slice_l~ : Float,
  texture_slice_t~ : Float,
  texture_slice_r~ : Float,
  texture_slice_b~ : Float,
  target_slice_l~ : Float,
  target_slice_t~ : Float,
  target_slice_r~ : Float,
  target_slice_b~ : Float,
  repeat_side_x~ : Float,
  repeat_side_y~ : Float,
  repeat_center_x~ : Float,
  repeat_center_y~ : Float,
  atlas_l~ : Float,
  atlas_t~ : Float,
  atlas_r~ : Float,
  atlas_b~ : Float,
) -> Unit = "mgstudio_host" "gpu_draw_ui_texture_slice"

///|
pub fn host_gpu_draw_mesh(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_id~ : Int,
  uv_offset_x~ : Float,
  uv_offset_y~ : Float,
  uv_scale_x~ : Float,
  uv_scale_y~ : Float,
) -> Unit = "mgstudio_host" "gpu_draw_mesh"

///|
pub fn host_gpu_draw_mesh3d(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  z~ : Float,
  rotation_x~ : Float,
  rotation_y~ : Float,
  rotation_z~ : Float,
  rotation_w~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  scale_z~ : Float,
  previous_x~ : Float,
  previous_y~ : Float,
  previous_z~ : Float,
  previous_rotation_x~ : Float,
  previous_rotation_y~ : Float,
  previous_rotation_z~ : Float,
  previous_rotation_w~ : Float,
  previous_scale_x~ : Float,
  previous_scale_y~ : Float,
  previous_scale_z~ : Float,
  color_r~ : Float,
  color_g~ : Float,
  color_b~ : Float,
  color_a~ : Float,
  texture_id~ : Int,
  uv_offset_x~ : Float,
  uv_offset_y~ : Float,
  uv_scale_x~ : Float,
  uv_scale_y~ : Float,
  normal_texture_id~ : Int,
  emissive_texture_id~ : Int,
  metallic_roughness_texture_id~ : Int,
  occlusion_texture_id~ : Int,
  depth_texture_id~ : Int,
  emissive_r~ : Float,
  emissive_g~ : Float,
  emissive_b~ : Float,
  unlit~ : Float,
  metallic~ : Float,
  roughness~ : Float,
  reflectance~ : Float,
  parallax_depth_scale~ : Float,
  max_parallax_layer_count~ : Float,
  max_relief_mapping_search_steps~ : Float,
  anisotropy_texture_id~ : Int,
  anisotropy_strength~ : Float,
  anisotropy_rotation~ : Float,
  specular_tint_texture_id~ : Int,
  specular_tint_r~ : Float,
  specular_tint_g~ : Float,
  specular_tint_b~ : Float,
  diffuse_transmission~ : Float,
  specular_transmission~ : Float,
  thickness~ : Float,
  ior~ : Float,
  transmission_source_texture_id~ : Int,
  transmission_blur_taps~ : Float,
  transmission_steps~ : Float,
  cull_mode~ : Int,
) -> Unit = "mgstudio_host" "gpu_draw_mesh3d"

///|
pub fn host_gpu_draw_motion_blur(
  scene_texture_id~ : Int,
  velocity_texture_id~ : Int,
  shutter_angle~ : Float,
  samples~ : Int,
) -> Unit = "mgstudio_host" "gpu_draw_motion_blur"

///|
pub fn host_gpu_draw_bloom2d(
  scene_texture_id~ : Int,
  enabled~ : Int,
  intensity~ : Float,
  low_frequency_boost~ : Float,
  low_frequency_boost_curvature~ : Float,
  high_pass_frequency~ : Float,
  threshold~ : Float,
  threshold_softness~ : Float,
  composite_mode~ : Int,
  max_mip_dimension~ : Int,
  scale_x~ : Float,
  scale_y~ : Float,
  tonemapping_mode~ : Int,
  deband_dither_enabled~ : Int,
  fxaa_enabled~ : Int,
  fxaa_edge_threshold~ : Float,
  fxaa_edge_threshold_min~ : Float,
  chromatic_aberration_intensity~ : Float,
  chromatic_aberration_max_samples~ : Int,
  vignette_intensity~ : Float,
  vignette_radius~ : Float,
  vignette_smoothness~ : Float,
  vignette_roundness~ : Float,
  vignette_center_x~ : Float,
  vignette_center_y~ : Float,
  vignette_edge_compensation~ : Float,
  vignette_color_r~ : Float,
  vignette_color_g~ : Float,
  vignette_color_b~ : Float,
  vignette_color_a~ : Float,
  view_width~ : Int,
  view_height~ : Int,
  agx_lut_texture_id~ : Int,
  tony_lut_texture_id~ : Int,
  blender_lut_texture_id~ : Int,
) -> Unit = "mgstudio_host" "gpu_draw_bloom2d"

///|
pub fn host_gpu_draw_gizmo_line(
  start_x~ : Float,
  start_y~ : Float,
  start_r~ : Float,
  start_g~ : Float,
  start_b~ : Float,
  start_a~ : Float,
  end_x~ : Float,
  end_y~ : Float,
  end_r~ : Float,
  end_g~ : Float,
  end_b~ : Float,
  end_a~ : Float,
  line_width~ : Float,
  style_kind~ : Int,
  gap_scale~ : Float,
  line_scale~ : Float,
) -> Unit = "mgstudio_host" "gpu_draw_gizmo_line"

///|
pub fn host_gpu_end_pass() -> Unit = "mgstudio_host" "gpu_end_pass"

///|
pub fn host_gpu_create_render_target(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int = "mgstudio_host" "gpu_create_render_target"

///|
pub fn host_gpu_create_render_target_rgba16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int = "mgstudio_host" "gpu_create_render_target_rgba16f"

///|
pub fn host_gpu_create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int = "mgstudio_host" "gpu_create_mesh_capsule"

///|
pub fn host_gpu_create_mesh_rectangle(width~ : Float, height~ : Float) -> Int = "mgstudio_host" "gpu_create_mesh_rectangle"

///|
pub fn host_gpu_create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  @core.with_host_string_id(vertices_xy_csv, fn(text_id) {
    host_gpu_create_mesh_triangles_id(text_id)
  })
}

///|
fn host_gpu_create_mesh_triangles_id(vertices_xy_csv_id : Int) -> Int = "mgstudio_host" "gpu_create_mesh_triangles"

///|
pub fn host_gpu_create_mesh_triangles3d(
  vertices_xyzuvrgba_csv~ : String,
) -> Int {
  host_gpu_create_mesh3d(vertices_xyzuvrgba_csv~, primitive_topology=0)
}

///|
pub fn host_gpu_create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  @core.with_host_string_id(vertices_xyzuvrgba_csv, fn(text_id) {
    host_gpu_create_mesh3d_id(text_id, primitive_topology~)
  })
}

///|
fn host_gpu_create_mesh3d_id(
  vertices_xyzuvrgba_csv_id : Int,
  primitive_topology~ : Int,
) -> Int = "mgstudio_host" "gpu_create_mesh3d"

///|
pub fn host_debug_string(value~ : String) -> Unit {
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
    let window = host_window_create(
      width=800,
      height=600,
      title="Moon Game Studio",
    )
    window_set_handle(window)
    let device = host_gpu_request_device()
    let surface = host_gpu_create_surface(window)
    let width = host_window_get_width(window)
    let height = host_window_get_height(window)
    host_gpu_configure_surface(device~, surface~, width~, height~)
    let app_ref : Ref[@app.App[W]] = Ref::new(app.run_startup())
    runner_state.val.tick = Some(fn() {
      host_window_poll_events(window)
      if @app.app_rendering_enabled() {
        let frame = host_gpu_begin_frame(surface)
        app_ref.val = app_ref.val.run_once()
        host_gpu_end_frame(frame)
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

///|
pub fn[W : @core.ChangeTickWorld + @core.SystemContextWorld] window_plugin(
  app : @app.App[W],
) -> @app.App[W] {
  app
  .set_runner(window_runner_builder)
  .add_pre_update_system(window_poll_resize_system)
}
