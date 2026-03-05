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
const MESH3D_VERTEX_SHADER_PATH : String = "shaders/bevy/bevy_pbr/render/mesh.wgsl"

///|
const MESH3D_FRAGMENT_SHADER_PATH : String = "shaders/bevy/bevy_pbr/render/pbr.wgsl"

///|
const MESH3D_SHADOW_SHADER_PATH : String = "shaders/bevy/bevy_pbr/render/mesh.wgsl"

///|
priv struct PendingTexture {
  id : Int
  path : @js.Any
  bytes_id : Int
  nearest : Bool
}

///|
priv struct PassInfo {
  target_id : Int
  width : Double
  height : Double
  cam_x : Double
  cam_y : Double
  cam_rotation : Double
  cam_scale : Double
  cam_z : Double
  cam_rot_x : Double
  cam_rot_y : Double
  cam_rot_z : Double
  cam_rot_w : Double
  cam_fov_y : Double
  cam_near : Double
  cam_far : Double
  sub_camera_view_scale_x : Double
  sub_camera_view_scale_y : Double
  sub_camera_view_bias_x : Double
  sub_camera_view_bias_y : Double
  previous_camera_x : Double
  previous_camera_y : Double
  previous_camera_z : Double
  previous_camera_rot_x : Double
  previous_camera_rot_y : Double
  previous_camera_rot_z : Double
  previous_camera_rot_w : Double
  pass_kind : Double
  viewport_x : Double
  viewport_y : Double
  viewport_width : Double
  viewport_height : Double
  viewport_depth_min : Double
  viewport_depth_max : Double
  ambient_r : Double
  ambient_g : Double
  ambient_b : Double
  ambient_brightness : Double
  directional_dir_x : Double
  directional_dir_y : Double
  directional_dir_z : Double
  directional_color_r : Double
  directional_color_g : Double
  directional_color_b : Double
  directional_illuminance : Double
  point_pos_x : Double
  point_pos_y : Double
  point_pos_z : Double
  point_color_r : Double
  point_color_g : Double
  point_color_b : Double
  point_intensity : Double
  point_range : Double
  spot_pos_x : Double
  spot_pos_y : Double
  spot_pos_z : Double
  spot_dir_x : Double
  spot_dir_y : Double
  spot_dir_z : Double
  spot_color_r : Double
  spot_color_g : Double
  spot_color_b : Double
  spot_intensity : Double
  spot_range : Double
  spot_inner_angle : Double
  spot_outer_angle : Double
}

///|
priv struct SpriteBatch {
  texture_id : Int
  first_instance : Int
  mut instance_count : Int
}

///|
priv struct UiBatch {
  texture_id : Int
  first_instance : Int
  mut instance_count : Int
}

///|
priv struct WindowState {
  canvas : @js.Any
  mut width : Int
  mut height : Int
  mut scale_factor : Double
  mut position_x : Int
  mut position_y : Int
  mut cursor_visible : Bool
  mut cursor_icon : Int
}

///|
priv struct AssetsState {
  pending_textures : Array[PendingTexture]
  missing_texture_reported : @js.Any
  reported_errors : @js.Any
  loading_textures : @js.Any
  texture_paths : @js.Any
  mut texture_sampler_overrides : @js.Any
  shader_sources : @js.Any
  shader_paths : @js.Any
  loading_shaders : @js.Any
  mut shader_module_index : @js.Any
  mut shader_module_index_loaded : Bool
  mut next_shader_id : Int
  mut next_font_id : Int
  fonts : @js.Any
  loading_fonts : @js.Any
  mut next_glyph_id : Int
  glyphs : @js.Any
  mut next_blob_id : Int
  blobs : @js.Any
  mut next_folder_id : Int
  folders : @js.Any
  mut folder_events : Array[Int]
  mut folder_events_pos : Int
}

///|
priv struct GamepadSnapshot {
  id : Int
  name : String
  vendor_id : Int?
  product_id : Int?
  button_values : Array[Double]
  button_pressed : Array[Bool]
  axis_values : Array[Double]
}

///|
priv struct TouchEventSnapshot {
  id : Int
  phase : Int
  x : Double
  y : Double
}

///|
priv struct DragAndDropEventSnapshot {
  kind : Int
  path : String
}

///|
priv struct InputState {
  pressed : @js.Any
  just_pressed : @js.Any
  just_released : @js.Any
  repeated : @js.Any
  text_events : Array[String]
  mouse_buttons : @js.Any
  mouse_just_pressed : @js.Any
  mouse_just_released : @js.Any
  mut mouse_x : Double
  mut mouse_y : Double
  mut wheel_x : Double
  mut wheel_y : Double
  mut has_cursor : Bool
  mut pointer_bound : Bool
  touch_events : Array[TouchEventSnapshot]
  drag_and_drop_events : Array[DragAndDropEventSnapshot]
  mut initialized : Bool
  mut gamepads : Array[GamepadSnapshot]
}

///|
priv struct GpuState {
  mut device : @webgpu.GPUDevice?
  mut queue : @webgpu.GPUQueue?
  mut context : @webgpu.GPUCanvasContext?
  mut surface_format : @webgpu.TextureFormat?
  mut format : @webgpu.TextureFormat?
  mut surface_view_format_enabled : Bool
  mut pipeline_color_format : String
  mut pipeline : @webgpu.GPURenderPipeline?
  mut vertex_count : Int
  mut mesh_pipeline : @webgpu.GPURenderPipeline?
  mut mesh3d_pipeline_cache : @js.Any
  mut mesh3d_shadow_pipeline_cache : @js.Any
  mut motion_vector_pipeline : @webgpu.GPURenderPipeline?
  mut motion_blur_pipeline : @webgpu.GPURenderPipeline?
  mut bloom2d_pipeline : @webgpu.GPURenderPipeline?
  mut mesh3d_dummy_resources : @js.Any?
  mut motion_blur_bind_layout : @webgpu.GPUBindGroupLayout?
  mut motion_blur_settings_buffer : @webgpu.GPUBuffer?
  mut motion_blur_globals_buffer : @webgpu.GPUBuffer?
  mut bloom2d_bind_layout : @webgpu.GPUBindGroupLayout?
  mut bloom2d_settings_buffer : @webgpu.GPUBuffer?
  mut bloom2d_downsample_first_pipeline : @webgpu.GPURenderPipeline?
  mut bloom2d_downsample_first_no_threshold_pipeline : @webgpu.GPURenderPipeline?
  mut bloom2d_downsample_first_uniform_pipeline : @webgpu.GPURenderPipeline?
  mut bloom2d_downsample_first_no_threshold_uniform_pipeline : @webgpu.GPURenderPipeline?
  mut bloom2d_downsample_pipeline : @webgpu.GPURenderPipeline?
  mut bloom2d_downsample_uniform_pipeline : @webgpu.GPURenderPipeline?
  mut bloom2d_upsample_pipeline_energy : @webgpu.GPURenderPipeline?
  mut bloom2d_upsample_pipeline_additive : @webgpu.GPURenderPipeline?
  mut bloom2d_final_pipeline_energy : @webgpu.GPURenderPipeline?
  mut bloom2d_final_pipeline_additive : @webgpu.GPURenderPipeline?
  mut bloom2d_final_pipeline_format : String
  mut bloom2d_sampler : @webgpu.GPUSampler?
  mut bloom2d_mip_texture : @webgpu.GPUTexture?
  bloom2d_mip_views : Array[@webgpu.GPUTextureView]
  mut bloom2d_mip_width : Int
  mut bloom2d_mip_height : Int
  mut bloom2d_mip_count : Int
  mut bloom2d_mip_format : String
  mut depth_texture : @webgpu.GPUTexture?
  mut depth_view : @webgpu.GPUTextureView?
  mut depth_width : Int
  mut depth_height : Int
  mut frame_count : Int
  mut gizmo_pipeline : @webgpu.GPURenderPipeline?
  mut gizmo_vertex_buffer : @webgpu.GPUBuffer?
  mut gizmo_vertex_capacity : Int
  mut gizmo_lines : @js.Any
  mut meshes : @js.Any
  mut next_mesh_id : Int
  mut uniform_buffer : @webgpu.GPUBuffer?
  mut sprite_uniform_buffer : @webgpu.GPUBuffer?
  mut sprite_instance_buffer : @webgpu.GPUBuffer?
  mut sprite_instance_capacity : Int
  mut sprite_globals_bind_group : @webgpu.GPUBindGroup?
  sprite_instance_data : Array[Double]
  sprite_batches : Array[SpriteBatch]
  mut sprite_instance_count : Int
  mut sprite_instance_buffer_write_offset : Int
  mut ui_pipeline : @webgpu.GPURenderPipeline?
  mut ui_instance_buffer : @webgpu.GPUBuffer?
  mut ui_instance_capacity : Int
  mut ui_globals_bind_group : @webgpu.GPUBindGroup?
  ui_instance_data : Array[Double]
  ui_batches : Array[UiBatch]
  mut ui_instance_count : Int
  mut ui_shadow_pipeline : @webgpu.GPURenderPipeline?
  mut ui_shadow_instance_buffer : @webgpu.GPUBuffer?
  mut ui_shadow_instance_capacity : Int
  mut ui_shadow_globals_bind_group : @webgpu.GPUBindGroup?
  ui_shadow_instance_data : Array[Double]
  ui_shadow_batches : Array[UiBatch]
  mut ui_shadow_instance_count : Int
  mut ui_slice_pipeline : @webgpu.GPURenderPipeline?
  mut ui_slice_instance_buffer : @webgpu.GPUBuffer?
  mut ui_slice_instance_capacity : Int
  mut ui_slice_globals_bind_group : @webgpu.GPUBindGroup?
  ui_slice_instance_data : Array[Double]
  ui_slice_batches : Array[UiBatch]
  mut ui_slice_instance_count : Int
  mut encoder : @webgpu.GPUCommandEncoder?
  mut current_texture : @webgpu.GPUTexture?
  mut current_pass : @webgpu.GPURenderPassEncoder?
  mut current_pass_info : PassInfo?
  mut textures : @js.Any
  mut next_texture_id : Int
  mut default_texture_id : Int
  mut sprite_shader_id : Int
  mut ui_shader_id : Int
  mut ui_shadow_shader_id : Int
  mut ui_slice_shader_id : Int
  mut mesh_shader_id : Int
  mut mesh3d_shader_id : Int
  mut mesh3d_fragment_shader_id : Int
  mut mesh3d_shadow_shader_id : Int
  mut motion_vector_shader_id : Int
  mut motion_blur_shader_id : Int
  mut bloom2d_downsample_first_shader_id : Int
  mut bloom2d_downsample_first_no_threshold_shader_id : Int
  mut bloom2d_downsample_first_uniform_shader_id : Int
  mut bloom2d_downsample_first_no_threshold_uniform_shader_id : Int
  mut bloom2d_downsample_shader_id : Int
  mut bloom2d_downsample_uniform_shader_id : Int
  mut bloom2d_shader_id : Int
  mut bloom2d_final_shader_id : Int
  mut gizmo_shader_id : Int
  mut profile_enabled : Bool
  mut profile_last_log_ms : Double
  mut profile_frame_begin_ms : Double
  mut profile_frames_accum : Int
  mut profile_frame_cpu_ms_accum : Double
  mut profile_pass_calls_accum : Int
  mut profile_draw_sprite_uv_calls_accum : Int
  mut profile_api_draw_sprite_uv_ms_accum : Double
  mut profile_api_begin_pass_ms_accum : Double
  mut profile_api_end_pass_ms_accum : Double
  mut profile_api_end_frame_ms_accum : Double
  mut profile_draw_ui_rect_calls_accum : Int
  mut profile_draw_ui_texture_slice_calls_accum : Int
  mut profile_draw_ui_box_shadow_calls_accum : Int
  mut profile_draw_mesh_calls_accum : Int
  mut profile_draw_mesh3d_calls_accum : Int
  mut profile_draw_motion_blur_calls_accum : Int
  mut profile_draw_bloom2d_calls_accum : Int
  mut profile_scissor_set_calls_accum : Int
  mut profile_scissor_clear_calls_accum : Int
  mut profile_sprite_instances_accum : Int
  mut profile_sprite_batches_accum : Int
  mut profile_ui_instances_accum : Int
  mut profile_ui_batches_accum : Int
}

///|
priv struct State {
  mut window : WindowState?
  mut should_close : Bool
  mut app_stdin_line : String?
  assets_source : @rtcore.SourceSpec
  data_source : @rtcore.SourceSpec
  mut data_db : @js.Any?
  strings : @js.Any
  mut next_string_id : Int
  assets : AssetsState
  input : InputState
  gpu : GpuState
  mut a11y_container : @js.Any?
  mut a11y_focused_node : Int
}

///|
fn new_state(
  assets_source : @rtcore.SourceSpec,
  data_source : @rtcore.SourceSpec,
) -> State {
  State::{
    window: None,
    should_close: false,
    app_stdin_line: None,
    assets_source,
    data_source,
    data_db: None,
    strings: new_map(),
    next_string_id: 1,
    assets: AssetsState::{
      pending_textures: [],
      missing_texture_reported: new_set(),
      reported_errors: new_set(),
      loading_textures: new_set(),
      texture_paths: new_map(),
      texture_sampler_overrides: new_map(),
      shader_sources: new_map(),
      shader_paths: new_map(),
      loading_shaders: new_set(),
      shader_module_index: new_map(),
      shader_module_index_loaded: false,
      next_shader_id: 1,
      next_font_id: 1,
      fonts: new_map(),
      loading_fonts: new_set(),
      next_glyph_id: 1,
      glyphs: new_map(),
      next_blob_id: 1,
      blobs: new_map(),
      next_folder_id: 1,
      folders: new_map(),
      folder_events: [],
      folder_events_pos: 0,
    },
    input: InputState::{
      pressed: new_set(),
      just_pressed: new_set(),
      just_released: new_set(),
      repeated: new_set(),
      text_events: [],
      mouse_buttons: new_set(),
      mouse_just_pressed: new_set(),
      mouse_just_released: new_set(),
      mouse_x: 0,
      mouse_y: 0,
      wheel_x: 0,
      wheel_y: 0,
      has_cursor: false,
      pointer_bound: false,
      touch_events: [],
      drag_and_drop_events: [],
      initialized: false,
      gamepads: [],
    },
    gpu: GpuState::{
      device: None,
      queue: None,
      context: None,
      surface_format: None,
      format: None,
      surface_view_format_enabled: false,
      pipeline_color_format: "",
      pipeline: None,
      vertex_count: 0,
      mesh_pipeline: None,
      mesh3d_pipeline_cache: new_map(),
      mesh3d_shadow_pipeline_cache: new_map(),
      motion_vector_pipeline: None,
      motion_blur_pipeline: None,
      bloom2d_pipeline: None,
      mesh3d_dummy_resources: None,
      motion_blur_bind_layout: None,
      motion_blur_settings_buffer: None,
      motion_blur_globals_buffer: None,
      bloom2d_bind_layout: None,
      bloom2d_settings_buffer: None,
      bloom2d_downsample_first_pipeline: None,
      bloom2d_downsample_first_no_threshold_pipeline: None,
      bloom2d_downsample_first_uniform_pipeline: None,
      bloom2d_downsample_first_no_threshold_uniform_pipeline: None,
      bloom2d_downsample_pipeline: None,
      bloom2d_downsample_uniform_pipeline: None,
      bloom2d_upsample_pipeline_energy: None,
      bloom2d_upsample_pipeline_additive: None,
      bloom2d_final_pipeline_energy: None,
      bloom2d_final_pipeline_additive: None,
      bloom2d_final_pipeline_format: "",
      bloom2d_sampler: None,
      bloom2d_mip_texture: None,
      bloom2d_mip_views: [],
      bloom2d_mip_width: 0,
      bloom2d_mip_height: 0,
      bloom2d_mip_count: 0,
      bloom2d_mip_format: "",
      depth_texture: None,
      depth_view: None,
      depth_width: 0,
      depth_height: 0,
      frame_count: 0,
      gizmo_pipeline: None,
      gizmo_vertex_buffer: None,
      gizmo_vertex_capacity: 0,
      gizmo_lines: new_array(),
      meshes: new_map(),
      next_mesh_id: 1,
      uniform_buffer: None,
      sprite_uniform_buffer: None,
      sprite_instance_buffer: None,
      sprite_instance_capacity: 0,
      sprite_globals_bind_group: None,
      sprite_instance_data: [],
      sprite_batches: [],
      sprite_instance_count: 0,
      sprite_instance_buffer_write_offset: 0,
      ui_pipeline: None,
      ui_instance_buffer: None,
      ui_instance_capacity: 0,
      ui_globals_bind_group: None,
      ui_instance_data: [],
      ui_batches: [],
      ui_instance_count: 0,
      ui_shadow_pipeline: None,
      ui_shadow_instance_buffer: None,
      ui_shadow_instance_capacity: 0,
      ui_shadow_globals_bind_group: None,
      ui_shadow_instance_data: [],
      ui_shadow_batches: [],
      ui_shadow_instance_count: 0,
      ui_slice_pipeline: None,
      ui_slice_instance_buffer: None,
      ui_slice_instance_capacity: 0,
      ui_slice_globals_bind_group: None,
      ui_slice_instance_data: [],
      ui_slice_batches: [],
      ui_slice_instance_count: 0,
      encoder: None,
      current_texture: None,
      current_pass: None,
      current_pass_info: None,
      textures: new_map(),
      next_texture_id: 1,
      default_texture_id: 0,
      sprite_shader_id: 0,
      ui_shader_id: 0,
      ui_shadow_shader_id: 0,
      ui_slice_shader_id: 0,
      mesh_shader_id: 0,
      mesh3d_shader_id: 0,
      mesh3d_fragment_shader_id: 0,
      mesh3d_shadow_shader_id: 0,
      motion_vector_shader_id: 0,
      motion_blur_shader_id: 0,
      bloom2d_downsample_first_shader_id: 0,
      bloom2d_downsample_first_no_threshold_shader_id: 0,
      bloom2d_downsample_first_uniform_shader_id: 0,
      bloom2d_downsample_first_no_threshold_uniform_shader_id: 0,
      bloom2d_downsample_shader_id: 0,
      bloom2d_downsample_uniform_shader_id: 0,
      bloom2d_shader_id: 0,
      bloom2d_final_shader_id: 0,
      gizmo_shader_id: 0,
      profile_enabled: false,
      profile_last_log_ms: 0.0,
      profile_frame_begin_ms: 0.0,
      profile_frames_accum: 0,
      profile_frame_cpu_ms_accum: 0.0,
      profile_pass_calls_accum: 0,
      profile_draw_sprite_uv_calls_accum: 0,
      profile_api_draw_sprite_uv_ms_accum: 0.0,
      profile_api_begin_pass_ms_accum: 0.0,
      profile_api_end_pass_ms_accum: 0.0,
      profile_api_end_frame_ms_accum: 0.0,
      profile_draw_ui_rect_calls_accum: 0,
      profile_draw_ui_texture_slice_calls_accum: 0,
      profile_draw_ui_box_shadow_calls_accum: 0,
      profile_draw_mesh_calls_accum: 0,
      profile_draw_mesh3d_calls_accum: 0,
      profile_draw_motion_blur_calls_accum: 0,
      profile_draw_bloom2d_calls_accum: 0,
      profile_scissor_set_calls_accum: 0,
      profile_scissor_clear_calls_accum: 0,
      profile_sprite_instances_accum: 0,
      profile_sprite_batches_accum: 0,
      profile_ui_instances_accum: 0,
      profile_ui_batches_accum: 0,
    },
    a11y_container: None,
    a11y_focused_node: 0,
  }
}

///|
fn to_int(value : Double) -> Int {
  value.to_int()
}

///|
fn string_from_id_optional(state : State, id_any : @js.Any) -> String {
  let id = to_int(number_or(id_any, 0))
  if id <= 0 {
    return ""
  }
  let value = map_get(state.strings, @js.any(id))
  if host_is_nullish(value) {
    ""
  } else {
    any_to_string(value)
  }
}

///|
fn string_from_id_required(
  state : State,
  id_any : @js.Any,
  what : String,
) -> String {
  let id = to_int(number_or(id_any, 0))
  if id <= 0 {
    throw_error(what + ": missing string id")
    return ""
  }
  let value = map_get(state.strings, @js.any(id))
  if host_is_nullish(value) {
    throw_error(what + ": unknown string id " + id.to_string())
    ""
  } else {
    any_to_string(value)
  }
}

///|
fn join_asset_path(base : String, entry : String) -> String {
  if base == "" {
    entry
  } else {
    let normalized = strip_leading_slashes(entry)
    let n = base.length()
    if n > 0 && base.code_unit_at(n - 1).to_int() == 47 { // '/'
      base + normalized
    } else {
      base + "/" + normalized
    }
  }
}

///|
fn next_shader_id(state : State) -> Int {
  let id = state.assets.next_shader_id
  state.assets.next_shader_id = id + 1
  id
}

///|
fn resolve_asset_url(state : State, path : @js.Any) -> String raise {
  let text = coerce_asset_path(path)
  if text.length() == 0 {
    fail("Asset path is empty")
  }
  if is_external_asset_url(text) {
    text
  } else {
    let normalized = strip_leading_slashes(text)
    @rtcore.join_url(state.assets_source.base, normalized)
  }
}

///|
async fn init_data_source(state : State) -> Unit {
  match state.data_source.backend {
    @rtcore.SourceBackend::Idb => {
      let ns = state.data_source.base
      let db = idb_open_kv_db(ns).wait() catch {
        err => {
          console_error(@js.any("IndexedDB init failed: " + err.to_string()))
          js_null()
        }
      }
      if !host_is_nullish(db) {
        state.data_db = Some(db)
      }
    }
    _ => ()
  }
}

///|
fn ensure_canvas(canvas_opt : @dom.Element?) -> @js.Any {
  if canvas_opt is Some(canvas) {
    canvas.as_any()
  } else {
    let target = create_canvas_element()
    append_canvas_to_body(target)
    target
  }
}

///|
fn surface_view_format_from_surface_format(
  format : @webgpu.TextureFormat,
) -> @webgpu.TextureFormat {
  match format {
    Bgra8Unorm => @webgpu.TextureFormat::Other("bgra8unorm-srgb")
    Rgba8Unorm => @webgpu.TextureFormat::Rgba8UnormSrgb
    _ => format
  }
}

///|
extern "js" fn configure_canvas_context_with_view_format_js(
  context : @js.Any,
  config : @js.Any,
  view_format : String,
) -> Bool =
  #| (context, config, viewFormat) => {
  #|   if (!context || !config) return false;
  #|   try {
  #|     context.configure({ ...config, viewFormats: [viewFormat] });
  #|     return true;
  #|   } catch (_err) {
  #|     return false;
  #|   }
  #| }

///|
fn configure_surface_context(state : State, width : Int, height : Int) -> Unit {
  guard state.gpu.context is Some(context) && state.gpu.device is Some(device) else {
    return
  }
  let usage = @webgpu.texture_usage_render_attachment()
  let surface_format = state.gpu.surface_format.unwrap_or(
    state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm),
  )
  let view_format = state.gpu.format.unwrap_or(surface_format)
  let config = @webgpu.surface_configuration(
    device,
    surface_format,
    @webgpu.AlphaMode::Premultiplied,
    usage,
    @webgpu.surface_size(width, height),
  )
  let config_js = config.to_js()
  let use_view_format = state.gpu.surface_view_format_enabled &&
    view_format.to_js_string() != surface_format.to_js_string()
  if use_view_format {
    let configured = configure_canvas_context_with_view_format_js(
      context.as_any(),
      config_js,
      view_format.to_js_string(),
    )
    if configured {
      return
    }
    state.gpu.surface_view_format_enabled = false
    state.gpu.format = Some(surface_format)
    state.gpu.pipeline_color_format = ""
    context.configure(config_js)
    return
  }
  context.configure(config_js)
}

///|
fn update_window_size(state : State) -> Unit {
  if state.window is None {
    return
  }
  if state.window is Some(window_state) {
    let target = window_state.canvas
    let size = get_canvas_pixel_size(target)
    let width : Int = size._get("width").cast()
    let height : Int = size._get("height").cast()
    let scale_factor = get_device_pixel_ratio()
    if width == window_state.width &&
      height == window_state.height &&
      scale_factor == window_state.scale_factor {
      return
    }
    window_state.width = width
    window_state.height = height
    window_state.scale_factor = scale_factor
    target._set("width", @js.any(width)) |> ignore
    target._set("height", @js.any(height)) |> ignore
    configure_surface_context(state, width, height)
  }
}

///|
fn init_input(state : State) -> Unit {
  if state.input.initialized {
    return
  }
  state.input.initialized = true
  state.input.wheel_x = 0.0
  state.input.wheel_y = 0.0
  let win = @dom.window().as_any()
  add_event_listener(
    win,
    "keydown",
    @js.from_fn1(fn(event : @js.Any) {
      if state.window is Some(window_state) &&
        !should_capture_keyboard_event(event, window_state.canvas) {
        return
      }
      let text = keyboard_event_character(event)
      if text != "" {
        state.input.text_events.push(text)
      }
      let repeat_value : Bool = event._get("repeat").cast()
      if repeat_value {
        let code_repeat = any_to_string(event._get("code").cast())
        set_add(state.input.repeated, @js.any(code_repeat))
        prevent_default(event)
        return
      }
      let code = any_to_string(event._get("code").cast())
      if !set_has(state.input.pressed, @js.any(code)) {
        set_add(state.input.pressed, @js.any(code))
        set_add(state.input.just_pressed, @js.any(code))
      }
      prevent_default(event)
    }),
  )
  add_event_listener(
    win,
    "keyup",
    @js.from_fn1(fn(event : @js.Any) {
      if state.window is Some(window_state) &&
        !should_capture_keyboard_event(event, window_state.canvas) {
        return
      }
      let code = any_to_string(event._get("code").cast())
      if set_delete(state.input.pressed, @js.any(code)) {
        set_add(state.input.just_released, @js.any(code))
      }
      prevent_default(event)
    }),
  )
  add_event_listener(
    win,
    "blur",
    @js.from_fn1(fn(_ : @js.Any) {
      set_clear(state.input.pressed)
      set_clear(state.input.just_pressed)
      set_clear(state.input.just_released)
      set_clear(state.input.repeated)
      set_clear(state.input.mouse_buttons)
      set_clear(state.input.mouse_just_pressed)
      set_clear(state.input.mouse_just_released)
      state.input.text_events.clear()
      state.input.touch_events.clear()
      state.input.has_cursor = false
    }),
  )
}

///|
fn poll_gamepads(state : State) -> Unit {
  let raw_gamepads = poll_gamepads_snapshot_js()
  let raw_len = array_len(raw_gamepads)
  let gamepads : Array[GamepadSnapshot] = []
  for i in 0..<raw_len {
    let raw = array_get(raw_gamepads, i)
    if host_is_nullish(raw) {
      continue
    }

    let id = to_int(number_or(raw._get("id"), -1))
    if id < 0 {
      continue
    }

    let raw_button_values = raw._get("button_values")
    let raw_button_values_len = array_len(raw_button_values)
    let button_values : Array[Double] = []
    for j in 0..<raw_button_values_len {
      button_values.push(number_or(array_get(raw_button_values, j), 0.0 / 0.0))
    }

    let raw_button_pressed = raw._get("button_pressed")
    let raw_button_pressed_len = array_len(raw_button_pressed)
    let button_pressed : Array[Bool] = []
    for j in 0..<raw_button_pressed_len {
      let pressed : Bool = array_get(raw_button_pressed, j).cast()
      button_pressed.push(pressed)
    }

    let raw_axis_values = raw._get("axis_values")
    let raw_axis_values_len = array_len(raw_axis_values)
    let axis_values : Array[Double] = []
    for j in 0..<raw_axis_values_len {
      axis_values.push(number_or(array_get(raw_axis_values, j), 0.0 / 0.0))
    }

    let vendor_id = to_int(number_or(raw._get("vendor_id"), -1))
    let product_id = to_int(number_or(raw._get("product_id"), -1))

    gamepads.push(GamepadSnapshot::{
      id,
      name: any_to_string(raw._get("name")),
      vendor_id: if vendor_id >= 0 {
        Some(vendor_id)
      } else {
        None
      },
      product_id: if product_id >= 0 {
        Some(product_id)
      } else {
        None
      },
      button_values,
      button_pressed,
      axis_values,
    })
  }
  state.input.gamepads = gamepads
}

///|
fn mouse_button_name(button : Int) -> String? {
  if button == 0 {
    Some("Left")
  } else if button == 1 {
    Some("Middle")
  } else if button == 2 {
    Some("Right")
  } else {
    None
  }
}

///|
fn update_mouse_position(
  state : State,
  target : @js.Any,
  event : @js.Any,
) -> Unit {
  if pointer_lock_active_for_target(target) {
    let dx = number_or(event._get("movementX"), 0)
    let dy = number_or(event._get("movementY"), 0)
    state.input.mouse_x = state.input.mouse_x + dx
    state.input.mouse_y = state.input.mouse_y + dy
  } else {
    let rect = get_bounding_rect(target)
    let client_x : Double = event._get("clientX").cast()
    let client_y : Double = event._get("clientY").cast()
    let left : Double = rect._get("left").cast()
    let top : Double = rect._get("top").cast()
    state.input.mouse_x = client_x - left
    state.input.mouse_y = client_y - top
  }
  state.input.has_cursor = true
}

///|
const TOUCH_PHASE_STARTED : Int = 0

///|
const TOUCH_PHASE_MOVED : Int = 1

///|
const TOUCH_PHASE_ENDED : Int = 2

///|
const TOUCH_PHASE_CANCELED : Int = 3

///|
const DRAG_AND_DROP_DROPPED_FILE : Int = 0

///|
const DRAG_AND_DROP_HOVERED_FILE : Int = 1

///|
const DRAG_AND_DROP_HOVERED_FILE_CANCELED : Int = 2

///|
fn pointer_is_touch(event : @js.Any) -> Bool {
  any_to_string(event._get("pointerType")) == "touch"
}

///|
fn push_touch_event(
  state : State,
  target : @js.Any,
  event : @js.Any,
  phase : Int,
) -> Unit {
  let id = to_int(number_or(event._get("pointerId"), -1))
  if id < 0 {
    return
  }
  let rect = get_bounding_rect(target)
  let client_x = number_or(event._get("clientX"), 0)
  let client_y = number_or(event._get("clientY"), 0)
  let left = number_or(rect._get("left"), 0)
  let top = number_or(rect._get("top"), 0)
  state.input.touch_events.push(TouchEventSnapshot::{
    id,
    phase,
    x: client_x - left,
    y: client_y - top,
  })
}

///|
fn push_drag_and_drop_event(state : State, kind : Int, path : String) -> Unit {
  state.input.drag_and_drop_events.push(DragAndDropEventSnapshot::{ kind, path })
}

///|
fn push_drag_and_drop_hovered_files(state : State, event : @js.Any) -> Unit {
  let transfer = event._get("dataTransfer")
  if host_is_nullish(transfer) {
    return
  }
  let files = transfer._get("files")
  if host_is_nullish(files) {
    return
  }
  let len = array_len(files)
  for i in 0..<len {
    let file = array_get(files, i)
    if host_is_nullish(file) {
      continue
    }
    let name = any_to_string(file._get("name"))
    if name != "" {
      push_drag_and_drop_event(state, DRAG_AND_DROP_HOVERED_FILE, name)
    }
  }
}

///|
fn push_drag_and_drop_dropped_files(state : State, event : @js.Any) -> Unit {
  let transfer = event._get("dataTransfer")
  if host_is_nullish(transfer) {
    return
  }
  let files = transfer._get("files")
  if host_is_nullish(files) {
    return
  }
  let len = array_len(files)
  for i in 0..<len {
    let file = array_get(files, i)
    if host_is_nullish(file) {
      continue
    }
    let name = any_to_string(file._get("name"))
    if name != "" {
      push_drag_and_drop_event(state, DRAG_AND_DROP_DROPPED_FILE, name)
    }
  }
}

///|
fn bind_pointer_events(state : State, target : @js.Any) -> Unit {
  if state.input.pointer_bound {
    return
  }
  state.input.pointer_bound = true
  add_event_listener(
    target,
    "pointermove",
    @js.from_fn1(fn(event : @js.Any) {
      if pointer_is_touch(event) {
        push_touch_event(state, target, event, TOUCH_PHASE_MOVED)
        prevent_default(event)
        return
      }
      update_mouse_position(state, target, event)
    }),
  )
  add_event_listener(
    target,
    "pointerdown",
    @js.from_fn1(fn(event : @js.Any) {
      if pointer_is_touch(event) {
        push_touch_event(state, target, event, TOUCH_PHASE_STARTED)
        prevent_default(event)
        return
      }
      let button : Int = event._get("button").cast()
      let name = mouse_button_name(button)
      if name is Some(label) {
        if !set_has(state.input.mouse_buttons, @js.any(label)) {
          set_add(state.input.mouse_buttons, @js.any(label))
          set_add(state.input.mouse_just_pressed, @js.any(label))
        }
      }
      pointer_event_set_capture(target, event)
      update_mouse_position(state, target, event)
    }),
  )
  add_event_listener(
    target,
    "pointerup",
    @js.from_fn1(fn(event : @js.Any) {
      if pointer_is_touch(event) {
        push_touch_event(state, target, event, TOUCH_PHASE_ENDED)
        prevent_default(event)
        return
      }
      let button : Int = event._get("button").cast()
      let name = mouse_button_name(button)
      if name is Some(label) {
        if set_delete(state.input.mouse_buttons, @js.any(label)) {
          set_add(state.input.mouse_just_released, @js.any(label))
        }
      }
      pointer_event_release_capture(target, event)
      update_mouse_position(state, target, event)
    }),
  )
  add_event_listener(
    target,
    "pointerleave",
    @js.from_fn1(fn(_ : @js.Any) {
      if !pointer_lock_active_for_target(target) {
        state.input.has_cursor = false
      }
    }),
  )
  add_event_listener(
    target,
    "pointercancel",
    @js.from_fn1(fn(event : @js.Any) {
      if pointer_is_touch(event) {
        push_touch_event(state, target, event, TOUCH_PHASE_CANCELED)
        prevent_default(event)
      } else {
        let button : Int = event._get("button").cast()
        let name = mouse_button_name(button)
        if name is Some(label) {
          if set_delete(state.input.mouse_buttons, @js.any(label)) {
            set_add(state.input.mouse_just_released, @js.any(label))
          }
        }
        pointer_event_release_capture(target, event)
      }
    }),
  )
  add_event_listener(
    target,
    "contextmenu",
    @js.from_fn1(fn(event : @js.Any) { prevent_default(event) }),
  )
  add_event_listener(
    target,
    "dragover",
    @js.from_fn1(fn(event : @js.Any) {
      push_drag_and_drop_hovered_files(state, event)
      prevent_default(event)
    }),
  )
  add_event_listener(
    target,
    "drop",
    @js.from_fn1(fn(event : @js.Any) {
      push_drag_and_drop_dropped_files(state, event)
      prevent_default(event)
    }),
  )
  add_event_listener(
    target,
    "dragleave",
    @js.from_fn1(fn(event : @js.Any) {
      push_drag_and_drop_event(state, DRAG_AND_DROP_HOVERED_FILE_CANCELED, "")
      prevent_default(event)
    }),
  )
  add_event_listener(
    target,
    "wheel",
    @js.from_fn1(fn(event : @js.Any) {
      // Keep wheel deltas in logical units (CSS pixels / lines depending on browser).
      // Consumers should interpret sign and scaling as needed.
      let dx : Double = event._get("deltaX").cast()
      let dy : Double = event._get("deltaY").cast()
      state.input.wheel_x = state.input.wheel_x + dx
      state.input.wheel_y = state.input.wheel_y + dy
      prevent_default(event)
    }),
  )
}

///|
async fn init_webgpu(state : State, target : @js.Any) -> Unit {
  let adapter_any = request_adapter_any().wait()
  if host_is_nullish(adapter_any) {
    fail("WebGPU adapter unavailable")
  }
  let device_any = request_device_any(adapter_any).wait()
  if host_is_nullish(device_any) {
    fail("WebGPU device unavailable")
  }
  let device : @webgpu.GPUDevice = device_any.cast()
  // Surface WebGPU validation/runtime failures in the same overlay used for
  // asset loading errors. Without this, pipeline/shader issues can fail silently.
  bind_uncaptured_error_handler(
    device.as_any(),
    @js.from_fn1(fn(event : @js.Any) {
      let err_any = event._get("error")
      let message = if host_is_nullish(err_any) {
        "WebGPU uncaptured error"
      } else {
        "WebGPU uncaptured error: " + any_to_string(err_any)
      }
      console_error(@js.any(message))
      dispatch_asset_error(message)
    }),
  )
  let context = @webgpu.get_canvas_context(target)
  let surface_format = @webgpu.texture_format_from_string(
    @webgpu.preferred_canvas_format(),
  )
  let format = surface_view_format_from_surface_format(surface_format)
  state.gpu.device = Some(device)
  state.gpu.queue = Some(device.queue())
  state.gpu.context = Some(context)
  state.gpu.surface_format = Some(surface_format)
  state.gpu.format = Some(format)
  state.gpu.surface_view_format_enabled = format.to_js_string() !=
    surface_format.to_js_string()
  state.gpu.pipeline_color_format = ""
  state.gpu.pipeline = None
  state.gpu.vertex_count = 0
  state.gpu.mesh_pipeline = None
  state.gpu.mesh3d_pipeline_cache = new_map()
  state.gpu.mesh3d_shadow_pipeline_cache = new_map()
  state.gpu.motion_vector_pipeline = None
  state.gpu.motion_blur_pipeline = None
  state.gpu.bloom2d_pipeline = None
  state.gpu.mesh3d_dummy_resources = None
  state.gpu.motion_blur_bind_layout = None
  state.gpu.motion_blur_settings_buffer = None
  state.gpu.motion_blur_globals_buffer = None
  state.gpu.bloom2d_bind_layout = None
  state.gpu.bloom2d_settings_buffer = None
  state.gpu.bloom2d_downsample_first_pipeline = None
  state.gpu.bloom2d_downsample_first_no_threshold_pipeline = None
  state.gpu.bloom2d_downsample_first_uniform_pipeline = None
  state.gpu.bloom2d_downsample_first_no_threshold_uniform_pipeline = None
  state.gpu.bloom2d_downsample_pipeline = None
  state.gpu.bloom2d_downsample_uniform_pipeline = None
  state.gpu.bloom2d_upsample_pipeline_energy = None
  state.gpu.bloom2d_upsample_pipeline_additive = None
  state.gpu.bloom2d_final_pipeline_energy = None
  state.gpu.bloom2d_final_pipeline_additive = None
  state.gpu.bloom2d_final_pipeline_format = ""
  state.gpu.bloom2d_sampler = None
  state.gpu.bloom2d_mip_texture = None
  state.gpu.bloom2d_mip_views.clear()
  state.gpu.bloom2d_mip_width = 0
  state.gpu.bloom2d_mip_height = 0
  state.gpu.bloom2d_mip_count = 0
  state.gpu.bloom2d_mip_format = ""
  state.gpu.depth_texture = None
  state.gpu.depth_view = None
  state.gpu.depth_width = 0
  state.gpu.depth_height = 0
  state.gpu.frame_count = 0
  state.gpu.gizmo_pipeline = None
  state.gpu.gizmo_vertex_buffer = None
  state.gpu.gizmo_vertex_capacity = 0
  state.gpu.gizmo_lines = new_array()
  state.gpu.meshes = new_map()
  state.assets.texture_sampler_overrides = new_map()
  state.gpu.next_mesh_id = 1
  state.gpu.uniform_buffer = None
  state.gpu.sprite_uniform_buffer = None
  state.gpu.sprite_instance_buffer = None
  state.gpu.sprite_instance_capacity = 0
  state.gpu.sprite_globals_bind_group = None
  state.gpu.sprite_instance_data.clear()
  state.gpu.sprite_batches.clear()
  state.gpu.sprite_instance_count = 0
  state.gpu.sprite_instance_buffer_write_offset = 0
  state.gpu.ui_pipeline = None
  state.gpu.ui_instance_buffer = None
  state.gpu.ui_instance_capacity = 0
  state.gpu.ui_globals_bind_group = None
  state.gpu.ui_instance_data.clear()
  state.gpu.ui_batches.clear()
  state.gpu.ui_instance_count = 0
  state.gpu.ui_shadow_pipeline = None
  state.gpu.ui_shadow_instance_buffer = None
  state.gpu.ui_shadow_instance_capacity = 0
  state.gpu.ui_shadow_globals_bind_group = None
  state.gpu.ui_shadow_instance_data.clear()
  state.gpu.ui_shadow_batches.clear()
  state.gpu.ui_shadow_instance_count = 0
  state.gpu.ui_slice_pipeline = None
  state.gpu.ui_slice_instance_buffer = None
  state.gpu.ui_slice_instance_capacity = 0
  state.gpu.ui_slice_globals_bind_group = None
  state.gpu.ui_slice_instance_data.clear()
  state.gpu.ui_slice_batches.clear()
  state.gpu.ui_slice_instance_count = 0
  state.gpu.encoder = None
  state.gpu.current_texture = None
  state.gpu.current_pass = None
  state.gpu.current_pass_info = None
  state.gpu.textures = new_map()
  state.gpu.next_texture_id = 1
  state.gpu.default_texture_id = 0
  state.gpu.sprite_shader_id = 0
  state.gpu.ui_shader_id = 0
  state.gpu.ui_shadow_shader_id = 0
  state.gpu.ui_slice_shader_id = 0
  state.gpu.mesh_shader_id = 0
  state.gpu.mesh3d_shader_id = 0
  state.gpu.mesh3d_fragment_shader_id = 0
  state.gpu.mesh3d_shadow_shader_id = 0
  state.gpu.motion_vector_shader_id = 0
  state.gpu.motion_blur_shader_id = 0
  state.gpu.bloom2d_downsample_first_shader_id = 0
  state.gpu.bloom2d_downsample_first_no_threshold_shader_id = 0
  state.gpu.bloom2d_downsample_first_uniform_shader_id = 0
  state.gpu.bloom2d_downsample_first_no_threshold_uniform_shader_id = 0
  state.gpu.bloom2d_downsample_shader_id = 0
  state.gpu.bloom2d_downsample_uniform_shader_id = 0
  state.gpu.bloom2d_shader_id = 0
  state.gpu.bloom2d_final_shader_id = 0
  state.gpu.gizmo_shader_id = 0
  let sprite_id = next_shader_id(state)
  let ui_id = next_shader_id(state)
  let ui_shadow_id = next_shader_id(state)
  let ui_slice_id = next_shader_id(state)
  let mesh_id = next_shader_id(state)
  let mesh3d_id = next_shader_id(state)
  let mesh3d_fragment_id = next_shader_id(state)
  let mesh3d_shadow_id = next_shader_id(state)
  let motion_vector_id = next_shader_id(state)
  let motion_blur_id = next_shader_id(state)
  let bloom2d_downsample_first_id = next_shader_id(state)
  let bloom2d_downsample_first_no_threshold_id = next_shader_id(state)
  let bloom2d_downsample_first_uniform_id = next_shader_id(state)
  let bloom2d_downsample_first_no_threshold_uniform_id = next_shader_id(state)
  let bloom2d_downsample_id = next_shader_id(state)
  let bloom2d_downsample_uniform_id = next_shader_id(state)
  let bloom2d_id = next_shader_id(state)
  let bloom2d_final_id = next_shader_id(state)
  let gizmo_id = next_shader_id(state)
  state.gpu.sprite_shader_id = sprite_id
  state.gpu.ui_shader_id = ui_id
  state.gpu.ui_shadow_shader_id = ui_shadow_id
  state.gpu.ui_slice_shader_id = ui_slice_id
  state.gpu.mesh_shader_id = mesh_id
  state.gpu.mesh3d_shader_id = mesh3d_id
  state.gpu.mesh3d_fragment_shader_id = mesh3d_fragment_id
  state.gpu.mesh3d_shadow_shader_id = mesh3d_shadow_id
  state.gpu.motion_vector_shader_id = motion_vector_id
  state.gpu.motion_blur_shader_id = motion_blur_id
  state.gpu.bloom2d_downsample_first_shader_id = bloom2d_downsample_first_id
  state.gpu.bloom2d_downsample_first_no_threshold_shader_id = bloom2d_downsample_first_no_threshold_id
  state.gpu.bloom2d_downsample_first_uniform_shader_id = bloom2d_downsample_first_uniform_id
  state.gpu.bloom2d_downsample_first_no_threshold_uniform_shader_id = bloom2d_downsample_first_no_threshold_uniform_id
  state.gpu.bloom2d_downsample_shader_id = bloom2d_downsample_id
  state.gpu.bloom2d_downsample_uniform_shader_id = bloom2d_downsample_uniform_id
  state.gpu.bloom2d_shader_id = bloom2d_id
  state.gpu.bloom2d_final_shader_id = bloom2d_final_id
  state.gpu.gizmo_shader_id = gizmo_id
  set_add(state.assets.loading_shaders, @js.any(sprite_id))
  set_add(state.assets.loading_shaders, @js.any(ui_id))
  set_add(state.assets.loading_shaders, @js.any(ui_shadow_id))
  set_add(state.assets.loading_shaders, @js.any(ui_slice_id))
  set_add(state.assets.loading_shaders, @js.any(mesh_id))
  set_add(state.assets.loading_shaders, @js.any(mesh3d_id))
  set_add(state.assets.loading_shaders, @js.any(mesh3d_fragment_id))
  set_add(state.assets.loading_shaders, @js.any(mesh3d_shadow_id))
  set_add(state.assets.loading_shaders, @js.any(motion_vector_id))
  set_add(state.assets.loading_shaders, @js.any(motion_blur_id))
  set_add(state.assets.loading_shaders, @js.any(bloom2d_downsample_first_id))
  set_add(
    state.assets.loading_shaders,
    @js.any(bloom2d_downsample_first_no_threshold_id),
  )
  set_add(
    state.assets.loading_shaders,
    @js.any(bloom2d_downsample_first_uniform_id),
  )
  set_add(
    state.assets.loading_shaders,
    @js.any(bloom2d_downsample_first_no_threshold_uniform_id),
  )
  set_add(state.assets.loading_shaders, @js.any(bloom2d_downsample_id))
  set_add(state.assets.loading_shaders, @js.any(bloom2d_downsample_uniform_id))
  set_add(state.assets.loading_shaders, @js.any(bloom2d_id))
  set_add(state.assets.loading_shaders, @js.any(bloom2d_final_id))
  set_add(state.assets.loading_shaders, @js.any(gizmo_id))
  map_set(
    state.assets.shader_paths,
    @js.any(sprite_id),
    @js.any("shaders/mgstudio/2d/sprite.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(ui_id),
    @js.any("shaders/mgstudio/ui/ui.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(ui_shadow_id),
    @js.any("shaders/mgstudio/ui/box_shadow.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(ui_slice_id),
    @js.any("shaders/mgstudio/ui/ui_texture_slice.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(mesh_id),
    @js.any("shaders/mgstudio/2d/mesh.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(mesh3d_id),
    @js.any(MESH3D_VERTEX_SHADER_PATH),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(mesh3d_fragment_id),
    @js.any(MESH3D_FRAGMENT_SHADER_PATH),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(mesh3d_shadow_id),
    @js.any(MESH3D_SHADOW_SHADER_PATH),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(motion_vector_id),
    @js.any("shaders/mgstudio/3d/motion_vector.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(motion_blur_id),
    @js.any("shaders/mgstudio/3d/motion_blur.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_downsample_first_id),
    @js.any("shaders/mgstudio/2d/bloom.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_downsample_first_no_threshold_id),
    @js.any("shaders/mgstudio/2d/bloom.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_downsample_first_uniform_id),
    @js.any("shaders/mgstudio/2d/bloom.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_downsample_first_no_threshold_uniform_id),
    @js.any("shaders/mgstudio/2d/bloom.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_downsample_id),
    @js.any("shaders/mgstudio/2d/bloom.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_downsample_uniform_id),
    @js.any("shaders/mgstudio/2d/bloom.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_id),
    @js.any("shaders/mgstudio/2d/bloom.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(bloom2d_final_id),
    @js.any("shaders/mgstudio/2d/tonemapping.wgsl"),
  )
  map_set(
    state.assets.shader_paths,
    @js.any(gizmo_id),
    @js.any("shaders/mgstudio/gizmo/lines.wgsl"),
  )
  load_wgsl_from_path(state, sprite_id, "shaders/mgstudio/2d/sprite.wgsl")
  |> ignore
  load_wgsl_from_path(
    state, ui_shadow_id, "shaders/mgstudio/ui/box_shadow.wgsl",
  )
  |> ignore
  load_wgsl_from_path(
    state, ui_slice_id, "shaders/mgstudio/ui/ui_texture_slice.wgsl",
  )
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(ui_shadow_id)) |> ignore
  set_delete(state.assets.loading_shaders, @js.any(ui_slice_id)) |> ignore
  set_delete(state.assets.loading_shaders, @js.any(sprite_id)) |> ignore
  load_wgsl_from_path(state, ui_id, "shaders/mgstudio/ui/ui.wgsl") |> ignore
  set_delete(state.assets.loading_shaders, @js.any(ui_id)) |> ignore
  load_wgsl_from_path(state, mesh_id, "shaders/mgstudio/2d/mesh.wgsl") |> ignore
  set_delete(state.assets.loading_shaders, @js.any(mesh_id)) |> ignore
  let mesh3d_shader_defs = mesh3d_bevy_shader_defs()
  load_wgsl_from_path_with_shader_defs(
    state,
    mesh3d_id,
    MESH3D_VERTEX_SHADER_PATH,
    mesh3d_shader_defs,
  )
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(mesh3d_id)) |> ignore
  load_wgsl_from_path_with_shader_defs(
    state,
    mesh3d_fragment_id,
    MESH3D_FRAGMENT_SHADER_PATH,
    mesh3d_shader_defs,
  )
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(mesh3d_fragment_id))
  |> ignore
  load_wgsl_from_path_with_shader_defs(
    state,
    mesh3d_shadow_id,
    MESH3D_SHADOW_SHADER_PATH,
    mesh3d_shader_defs,
  )
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(mesh3d_shadow_id)) |> ignore
  load_wgsl_from_path(
    state, motion_vector_id, "shaders/mgstudio/3d/motion_vector.wgsl",
  )
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(motion_vector_id)) |> ignore
  load_wgsl_from_path(
    state, motion_blur_id, "shaders/mgstudio/3d/motion_blur.wgsl",
  )
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(motion_blur_id)) |> ignore
  let bloom2d_first_source = load_wgsl_preprocessed(
    state,
    "shaders/mgstudio/2d/bloom.wgsl",
    ["FIRST_DOWNSAMPLE", "USE_THRESHOLD"],
    Ref::new([]),
  )
  map_set(
    state.assets.shader_sources,
    @js.any(bloom2d_downsample_first_id),
    @js.any(bloom2d_first_source),
  )
  set_delete(state.assets.loading_shaders, @js.any(bloom2d_downsample_first_id))
  |> ignore
  let bloom2d_first_no_threshold_source = load_wgsl_preprocessed(
    state,
    "shaders/mgstudio/2d/bloom.wgsl",
    ["FIRST_DOWNSAMPLE"],
    Ref::new([]),
  )
  map_set(
    state.assets.shader_sources,
    @js.any(bloom2d_downsample_first_no_threshold_id),
    @js.any(bloom2d_first_no_threshold_source),
  )
  set_delete(
    state.assets.loading_shaders,
    @js.any(bloom2d_downsample_first_no_threshold_id),
  )
  |> ignore
  let bloom2d_first_uniform_source = load_wgsl_preprocessed(
    state,
    "shaders/mgstudio/2d/bloom.wgsl",
    ["FIRST_DOWNSAMPLE", "USE_THRESHOLD", "UNIFORM_SCALE"],
    Ref::new([]),
  )
  map_set(
    state.assets.shader_sources,
    @js.any(bloom2d_downsample_first_uniform_id),
    @js.any(bloom2d_first_uniform_source),
  )
  set_delete(
    state.assets.loading_shaders,
    @js.any(bloom2d_downsample_first_uniform_id),
  )
  |> ignore
  let bloom2d_first_no_threshold_uniform_source = load_wgsl_preprocessed(
    state,
    "shaders/mgstudio/2d/bloom.wgsl",
    ["FIRST_DOWNSAMPLE", "UNIFORM_SCALE"],
    Ref::new([]),
  )
  map_set(
    state.assets.shader_sources,
    @js.any(bloom2d_downsample_first_no_threshold_uniform_id),
    @js.any(bloom2d_first_no_threshold_uniform_source),
  )
  set_delete(
    state.assets.loading_shaders,
    @js.any(bloom2d_downsample_first_no_threshold_uniform_id),
  )
  |> ignore
  let bloom2d_downsample_source = load_wgsl_preprocessed(
    state,
    "shaders/mgstudio/2d/bloom.wgsl",
    [],
    Ref::new([]),
  )
  map_set(
    state.assets.shader_sources,
    @js.any(bloom2d_downsample_id),
    @js.any(bloom2d_downsample_source),
  )
  set_delete(state.assets.loading_shaders, @js.any(bloom2d_downsample_id))
  |> ignore
  let bloom2d_downsample_uniform_source = load_wgsl_preprocessed(
    state,
    "shaders/mgstudio/2d/bloom.wgsl",
    ["UNIFORM_SCALE"],
    Ref::new([]),
  )
  map_set(
    state.assets.shader_sources,
    @js.any(bloom2d_downsample_uniform_id),
    @js.any(bloom2d_downsample_uniform_source),
  )
  set_delete(
    state.assets.loading_shaders,
    @js.any(bloom2d_downsample_uniform_id),
  )
  |> ignore
  load_wgsl_from_path(state, bloom2d_id, "shaders/mgstudio/2d/bloom.wgsl")
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(bloom2d_id)) |> ignore
  load_wgsl_from_path(
    state, bloom2d_final_id, "shaders/mgstudio/2d/tonemapping.wgsl",
  )
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(bloom2d_final_id)) |> ignore
  load_wgsl_from_path(state, gizmo_id, "shaders/mgstudio/gizmo/lines.wgsl")
  |> ignore
  set_delete(state.assets.loading_shaders, @js.any(gizmo_id)) |> ignore
  if state.assets.pending_textures.length() > 0 {
    let pending : Array[PendingTexture] = []
    for item in state.assets.pending_textures {
      pending.push(item)
    }
    state.assets.pending_textures.clear()
    for entry in pending {
      @js.run_async(async fn() noraise {
        if entry.bytes_id > 0 {
          let result = load_texture_from_blob_id(
            state,
            entry.id,
            entry.bytes_id,
            entry.nearest,
          ) catch {
            err => {
              let message = "Texture load error: " + err.to_string()
              console_error(@js.any(message))
              dispatch_asset_error(message)
              set_delete(state.assets.loading_textures, @js.any(entry.id))
              |> ignore
            }
          }
          result |> ignore
        } else {
          let result = load_texture_from_path(
            state,
            entry.id,
            entry.path,
            entry.nearest,
          ) catch {
            err => {
              let message = "Texture load error: " + err.to_string()
              console_error(@js.any(message))
              dispatch_asset_error(message)
              set_delete(state.assets.loading_textures, @js.any(entry.id))
              |> ignore
            }
          }
          result |> ignore
        }
      })
    }
  }
}

///|
