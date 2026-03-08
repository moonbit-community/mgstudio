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
pub(all) enum CursorIcon {
  Default
  EwResize
} derive(Eq, Show)

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
  width~ : Int,
  height~ : Int,
  title~ : String,
) -> HostWindow {
  @native_window.create(width~, height~, title~)
}

///|
pub fn host_window_poll_events(window : HostWindow) -> Unit {
  @native_window.poll_events(window)
}

///|
pub fn host_window_get_width(window : HostWindow) -> Int {
  @native_window.width(window)
}

///|
pub fn host_window_get_height(window : HostWindow) -> Int {
  @native_window.height(window)
}

///|
pub fn host_window_get_scale_factor(window : HostWindow) -> Float {
  @native_window.scale_factor(window)
}

///|
pub fn host_window_get_focused(window : HostWindow) -> Bool {
  @native_window.focused(window)
}

///|
pub fn host_window_should_close(window : HostWindow) -> Bool {
  @native_window.should_close(window)
}

///|
pub fn host_window_request_close(window : HostWindow) -> Unit {
  @native_window.request_close(window)
}

///|
pub fn host_window_run_loop(step : FuncRef[() -> Unit]) -> Unit {
  @native_window.run_loop(step)
}

///|
pub fn host_window_set_title(window : HostWindow, title~ : String) -> Unit {
  @native_window.set_title(window, title~)
}

///|
pub fn host_window_set_size(
  window : HostWindow,
  width~ : Int,
  height~ : Int,
) -> Unit {
  @native_window.set_size(window, width~, height~)
}

///|
pub fn host_window_set_resizable(
  window : HostWindow,
  resizable~ : Bool,
) -> Unit {
  @native_window.set_resizable(window, resizable~)
}

///|
pub fn host_window_set_cursor_visible(
  window : HostWindow,
  visible~ : Bool,
) -> Unit {
  @native_window.set_cursor_visible(window, visible~)
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
) -> Unit {
  @native_window.set_cursor_grab_mode(window, mode~)
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
  @native_window.set_cursor_icon(window, icon~)
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
  @native_window.set_mode(window, mode~)
}

///|
pub fn host_window_set_position(
  window : HostWindow,
  x~ : Int,
  y~ : Int,
) -> Unit {
  @native_window.set_position(window, x~, y~)
}

///|
pub fn host_window_get_position_x(window : HostWindow) -> Int {
  @native_window.position_x(window)
}

///|
pub fn host_window_get_position_y(window : HostWindow) -> Int {
  @native_window.position_y(window)
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
pub type HostGpuDevice = Int

///|
pub type HostGpuQueue = Int

///|
pub type HostGpuSurface = Int

///|
pub type HostGpuFrame = Int

///|
pub fn host_gpu_request_device() -> HostGpuDevice {
  @native_gpu.request_device()
}

///|
pub fn host_gpu_get_queue(device : HostGpuDevice) -> HostGpuQueue {
  @native_gpu.get_queue(device)
}

///|
pub fn host_gpu_create_surface(window : HostWindow) -> HostGpuSurface {
  @native_gpu.create_surface(window)
}

///|
pub fn host_gpu_configure_surface(
  device~ : HostGpuDevice,
  surface~ : HostGpuSurface,
  width~ : Int,
  height~ : Int,
) -> Unit {
  @native_gpu.configure_surface(device~, surface~, width~, height~)
}

///|
pub fn host_gpu_begin_frame(surface : HostGpuSurface) -> HostGpuFrame {
  @native_gpu.begin_frame(surface)
}

///|
pub fn host_gpu_end_frame(frame : HostGpuFrame) -> Unit {
  @native_gpu.end_frame(frame)
}

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
) -> Unit {
  @native_gpu.begin_pass(
    target_id~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_rotation~,
    camera_scale~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    viewport_depth_min~,
    viewport_depth_max~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_begin_pass_3d(
  target_id~ : Int,
  target_layer? : Int = -1,
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
) -> Unit {
  @native_gpu.begin_pass_3d(
    target_id~,
    target_layer~,
    width~,
    height~,
    clear_r~,
    clear_g~,
    clear_b~,
    clear_a~,
    camera_x~,
    camera_y~,
    camera_z~,
    camera_rot_x~,
    camera_rot_y~,
    camera_rot_z~,
    camera_rot_w~,
    camera_fov_y~,
    camera_near~,
    camera_far~,
    viewport_x~,
    viewport_y~,
    viewport_width~,
    viewport_height~,
    ambient_r~,
    ambient_g~,
    ambient_b~,
    ambient_brightness~,
    directional_dir_x~,
    directional_dir_y~,
    directional_dir_z~,
    directional_color_r~,
    directional_color_g~,
    directional_color_b~,
    directional_illuminance~,
    point_pos_x~,
    point_pos_y~,
    point_pos_z~,
    point_color_r~,
    point_color_g~,
    point_color_b~,
    point_intensity~,
    point_range~,
    spot_pos_x~,
    spot_pos_y~,
    spot_pos_z~,
    spot_dir_x~,
    spot_dir_y~,
    spot_dir_z~,
    spot_color_r~,
    spot_color_g~,
    spot_color_b~,
    spot_intensity~,
    spot_range~,
    spot_inner_angle~,
    spot_outer_angle~,
    sub_camera_view_scale_x~,
    sub_camera_view_scale_y~,
    sub_camera_view_bias_x~,
    sub_camera_view_bias_y~,
    previous_camera_x~,
    previous_camera_y~,
    previous_camera_z~,
    previous_camera_rot_x~,
    previous_camera_rot_y~,
    previous_camera_rot_z~,
    previous_camera_rot_w~,
    pass_kind~,
    clear_enabled~,
  )
}

///|
pub fn host_gpu_set_scissor(
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
) -> Unit {
  @native_gpu.set_scissor(x~, y~, width~, height~)
}

///|
pub fn host_gpu_clear_scissor() -> Unit {
  @native_gpu.clear_scissor()
}

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
) -> Unit {
  @native_gpu.draw_sprite(
    texture_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
  )
}

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
) -> Unit {
  @native_gpu.draw_sprite_uv(
    texture_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    uv_min_x~,
    uv_min_y~,
    uv_max_x~,
    uv_max_y~,
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
) -> Unit {
  @native_gpu.draw_ui_rect(
    texture_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    uv_min_x~,
    uv_min_y~,
    uv_max_x~,
    uv_max_y~,
    flags~,
    radius_tl~,
    radius_tr~,
    radius_br~,
    radius_bl~,
    border_left~,
    border_top~,
    border_right~,
    border_bottom~,
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
) -> Unit {
  @native_gpu.draw_ui_box_shadow(
    texture_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    size_x~,
    size_y~,
    radius_tl~,
    radius_tr~,
    radius_br~,
    radius_bl~,
    blur~,
    samples~,
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
) -> Unit {
  @native_gpu.draw_ui_texture_slice(
    texture_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    texture_slice_l~,
    texture_slice_t~,
    texture_slice_r~,
    texture_slice_b~,
    target_slice_l~,
    target_slice_t~,
    target_slice_r~,
    target_slice_b~,
    repeat_side_x~,
    repeat_side_y~,
    repeat_center_x~,
    repeat_center_y~,
    atlas_l~,
    atlas_t~,
    atlas_r~,
    atlas_b~,
  )
}

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
) -> Unit {
  @native_gpu.draw_mesh(
    mesh_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    texture_id~,
    uv_offset_x~,
    uv_offset_y~,
    uv_scale_x~,
    uv_scale_y~,
  )
}

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
  point_shadow_texture_id~ : Int,
  point_shadow_enabled~ : Float,
  point_shadow_depth_bias~ : Float,
  cull_mode~ : Int,
) -> Unit {
  @native_gpu.draw_mesh3d(
    mesh_id~,
    x~,
    y~,
    z~,
    rotation_x~,
    rotation_y~,
    rotation_z~,
    rotation_w~,
    scale_x~,
    scale_y~,
    scale_z~,
    previous_x~,
    previous_y~,
    previous_z~,
    previous_rotation_x~,
    previous_rotation_y~,
    previous_rotation_z~,
    previous_rotation_w~,
    previous_scale_x~,
    previous_scale_y~,
    previous_scale_z~,
    color_r~,
    color_g~,
    color_b~,
    color_a~,
    texture_id~,
    uv_offset_x~,
    uv_offset_y~,
    uv_scale_x~,
    uv_scale_y~,
    normal_texture_id~,
    emissive_texture_id~,
    metallic_roughness_texture_id~,
    occlusion_texture_id~,
    depth_texture_id~,
    emissive_r~,
    emissive_g~,
    emissive_b~,
    unlit~,
    metallic~,
    roughness~,
    reflectance~,
    parallax_depth_scale~,
    max_parallax_layer_count~,
    max_relief_mapping_search_steps~,
    anisotropy_texture_id~,
    anisotropy_strength~,
    anisotropy_rotation~,
    specular_tint_texture_id~,
    specular_tint_r~,
    specular_tint_g~,
    specular_tint_b~,
    diffuse_transmission~,
    specular_transmission~,
    thickness~,
    ior~,
    transmission_source_texture_id~,
    transmission_blur_taps~,
    transmission_steps~,
    point_shadow_texture_id~,
    point_shadow_enabled~,
    point_shadow_depth_bias~,
    cull_mode~,
  )
}

///|
pub fn host_gpu_draw_motion_blur(
  scene_texture_id~ : Int,
  velocity_texture_id~ : Int,
  shutter_angle~ : Float,
  samples~ : Int,
) -> Unit {
  @native_gpu.draw_motion_blur(
    scene_texture_id~,
    velocity_texture_id~,
    shutter_angle~,
    samples~,
  )
}

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
) -> Unit {
  @native_gpu.draw_bloom2d(
    scene_texture_id~,
    enabled~,
    intensity~,
    low_frequency_boost~,
    low_frequency_boost_curvature~,
    high_pass_frequency~,
    threshold~,
    threshold_softness~,
    composite_mode~,
    max_mip_dimension~,
    scale_x~,
    scale_y~,
    tonemapping_mode~,
    deband_dither_enabled~,
    fxaa_enabled~,
    fxaa_edge_threshold~,
    fxaa_edge_threshold_min~,
    chromatic_aberration_intensity~,
    chromatic_aberration_max_samples~,
    vignette_intensity~,
    vignette_radius~,
    vignette_smoothness~,
    vignette_roundness~,
    vignette_center_x~,
    vignette_center_y~,
    vignette_edge_compensation~,
    vignette_color_r~,
    vignette_color_g~,
    vignette_color_b~,
    vignette_color_a~,
    view_width~,
    view_height~,
    agx_lut_texture_id~,
    tony_lut_texture_id~,
    blender_lut_texture_id~,
  )
}

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
) -> Unit {
  @native_gpu.draw_gizmo_line(
    start_x~,
    start_y~,
    start_r~,
    start_g~,
    start_b~,
    start_a~,
    end_x~,
    end_y~,
    end_r~,
    end_g~,
    end_b~,
    end_a~,
    line_width~,
    style_kind~,
    gap_scale~,
    line_scale~,
  )
}

///|
pub fn host_gpu_end_pass() -> Unit {
  @native_gpu.end_pass()
}

///|
pub fn host_gpu_create_render_target(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  @native_gpu.create_render_target(width~, height~, nearest~)
}

///|
pub fn host_gpu_create_render_target_rgba16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  @native_gpu.create_render_target_rgba16f(width~, height~, nearest~)
}

///|
pub fn host_gpu_create_point_light_shadow_target(size~ : Int) -> Int {
  @native_gpu.create_point_light_shadow_target(size~)
}

///|
pub fn host_gpu_create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  @native_gpu.create_mesh_capsule(radius~, half_length~, segments~)
}

///|
pub fn host_gpu_create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  @native_gpu.create_mesh_rectangle(width~, height~)
}

///|
pub fn host_gpu_create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  @native_gpu.create_mesh_triangles(vertices_xy_csv~)
}

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
  @native_gpu.create_mesh3d(vertices_xyzuvrgba_csv~, primitive_topology~)
}

///|
pub fn host_debug_string(value~ : String) -> Unit {
  @native_gpu.debug_string(value~)
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
    let device = host_gpu_request_device()
    let surface = host_gpu_create_surface(window)
    let width = host_window_get_width(window)
    let height = host_window_get_height(window)
    host_gpu_configure_surface(device~, surface~, width~, height~)
    let surface_width_ref : Ref[Int] = Ref::new(width)
    let surface_height_ref : Ref[Int] = Ref::new(height)
    let app_ref : Ref[@app.App[@ecs.World]] = Ref::new(app.run_startup())
    runner_state.val.tick = Some(fn() {
      window_poll_host_events(app_ref.val.world())
      let current_width = window_primary_physical_width(app_ref.val.world())
      let current_height = window_primary_physical_height(app_ref.val.world())
      if current_width > 0 &&
        current_height > 0 &&
        (
          current_width != surface_width_ref.val ||
          current_height != surface_height_ref.val
        ) {
        host_gpu_configure_surface(
          device~,
          surface~,
          width=current_width,
          height=current_height,
        )
        surface_width_ref.val = current_width
        surface_height_ref.val = current_height
      }
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
