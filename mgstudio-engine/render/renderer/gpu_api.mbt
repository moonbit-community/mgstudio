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
/// Global native GPU entry points.
///
/// This file is split from gpu.mbt to keep module boundaries closer to Bevy:
/// the backend implementation lives on `GpuBackend`, while runtime-facing entry points
/// (surface/frame lifecycle, asset upload helpers, diagnostics snapshot) live here.
pub type NativeGpuDevice = Int

///|
pub type NativeGpuQueue = Int

///|
pub type NativeGpuSurface = Int

///|
pub type NativeGpuFrame = Int

///|
pub const SURFACE_PRESENT_MODE_AUTO_VSYNC : Int = 0

///|
pub const SURFACE_PRESENT_MODE_AUTO_NO_VSYNC : Int = 1

///|
pub const SURFACE_PRESENT_MODE_FIFO : Int = 2

///|
pub const SURFACE_PRESENT_MODE_FIFO_RELAXED : Int = 3

///|
pub const SURFACE_PRESENT_MODE_IMMEDIATE : Int = 4

///|
pub const SURFACE_PRESENT_MODE_MAILBOX : Int = 5

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_AUTO : Int = 0

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_OPAQUE : Int = 1

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_PRE_MULTIPLIED : Int = 2

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_POST_MULTIPLIED : Int = 3

///|
pub const SURFACE_COMPOSITE_ALPHA_MODE_INHERIT : Int = 4

///|
pub const SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY : Int = 2

///|
pub struct RenderDiagnosticsSnapshot {
  mesh2d_draw_calls : Int
  mesh2d_executed_draw_calls : Int
  mesh3d_draw_calls : Int
  mesh3d_executed_draw_calls : Int
  pass_total_count : Int
  pass_2d_count : Int
  pass_3d_main_count : Int
  pass_3d_motion_vector_count : Int
  pass_3d_point_shadow_count : Int
  pass_total_cpu_ms : Float
  pass_2d_cpu_ms : Float
  pass_3d_main_cpu_ms : Float
  pass_3d_motion_vector_cpu_ms : Float
  pass_3d_point_shadow_cpu_ms : Float
}

///|
pub fn RenderDiagnosticsSnapshot::default() -> RenderDiagnosticsSnapshot {
  RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls: 0,
    mesh2d_executed_draw_calls: 0,
    mesh3d_draw_calls: 0,
    mesh3d_executed_draw_calls: 0,
    pass_total_count: 0,
    pass_2d_count: 0,
    pass_3d_main_count: 0,
    pass_3d_motion_vector_count: 0,
    pass_3d_point_shadow_count: 0,
    pass_total_cpu_ms: 0.0F,
    pass_2d_cpu_ms: 0.0F,
    pass_3d_main_cpu_ms: 0.0F,
    pass_3d_motion_vector_cpu_ms: 0.0F,
    pass_3d_point_shadow_cpu_ms: 0.0F,
  }
}

///|
pub fn RenderDiagnosticsSnapshot::new(
  mesh2d_draw_calls : Int,
  mesh2d_executed_draw_calls : Int,
  mesh3d_draw_calls : Int,
  mesh3d_executed_draw_calls : Int,
) -> RenderDiagnosticsSnapshot {
  RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls,
    mesh2d_executed_draw_calls,
    mesh3d_draw_calls,
    mesh3d_executed_draw_calls,
    pass_total_count: 0,
    pass_2d_count: 0,
    pass_3d_main_count: 0,
    pass_3d_motion_vector_count: 0,
    pass_3d_point_shadow_count: 0,
    pass_total_cpu_ms: 0.0F,
    pass_2d_cpu_ms: 0.0F,
    pass_3d_main_cpu_ms: 0.0F,
    pass_3d_motion_vector_cpu_ms: 0.0F,
    pass_3d_point_shadow_cpu_ms: 0.0F,
  }
}

///|
const RENDER_PASS_PHASE_NONE : Int = 0

///|
const RENDER_PASS_PHASE_2D : Int = 1

///|
const RENDER_PASS_PHASE_3D_MAIN : Int = 2

///|
const RENDER_PASS_PHASE_3D_MOTION_VECTOR : Int = 3

///|
const RENDER_PASS_PHASE_3D_POINT_SHADOW : Int = 4

///|
fn host_material2d_u32le_pack(xs : Array[UInt]) -> Bytes {
  let len = xs.length()
  Bytes::makei(len * 4, i => {
    let word = xs[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn host_material2d_f32le_pack(xs : Array[Float]) -> Bytes {
  host_material2d_u32le_pack(xs.map(f32_bits))
}

///|
pub(all) enum HostMaterial2dBindingValue {
  Uniform(Bytes)
  Texture(Int)
  Sampler(Int)
}

///|
pub(all) struct HostMaterial2dBinding {
  binding : UInt
  value : HostMaterial2dBindingValue
}

///|
pub fn HostMaterial2dBinding::uniform(
  binding : UInt,
  bytes : Bytes,
) -> HostMaterial2dBinding {
  HostMaterial2dBinding::{ binding, value: Uniform(bytes) }
}

///|
pub fn HostMaterial2dBinding::texture(
  binding : UInt,
  texture_id : Int,
) -> HostMaterial2dBinding {
  HostMaterial2dBinding::{ binding, value: Texture(texture_id) }
}

///|
pub fn HostMaterial2dBinding::sampler(
  binding : UInt,
  texture_id : Int,
) -> HostMaterial2dBinding {
  HostMaterial2dBinding::{ binding, value: Sampler(texture_id) }
}

///|
pub struct HostMaterial2dBindGroup {
  bindings : Array[HostMaterial2dBinding]
}

///|
pub fn HostMaterial2dBindGroup::new(
  bindings : Array[HostMaterial2dBinding],
) -> HostMaterial2dBindGroup {
  let normalized = bindings.copy()
  normalized.sort_by(fn(a, b) {
    if a.binding < b.binding {
      -1
    } else if a.binding > b.binding {
      1
    } else {
      0
    }
  })
  for i in 1..<normalized.length() {
    if normalized[i - 1].binding == normalized[i].binding {
      abort(
        "duplicate HostMaterial2d bind-group binding " +
        normalized[i].binding.to_string(),
      )
    }
  }
  HostMaterial2dBindGroup::{ bindings: normalized }
}

///|
pub fn HostMaterial2dBindGroup::default() -> HostMaterial2dBindGroup {
  HostMaterial2dBindGroup::new([])
}

///|
fn host_material2d_color_material_bind_group(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
) -> HostMaterial2dBindGroup {
  let flags = (if texture_id >= 0 { 1U } else { 0U }) |
    alpha_mode_kind.reinterpret_as_uint()
  let bindings : Array[HostMaterial2dBinding] = [
    HostMaterial2dBinding::uniform(
      0U,
      host_material2d_f32le_pack([
        color_r,
        color_g,
        color_b,
        color_a,
        uv_scale_x,
        0.0F,
        0.0F,
        0.0F,
        0.0F,
        uv_scale_y,
        0.0F,
        0.0F,
        uv_offset_x,
        uv_offset_y,
        1.0F,
        0.0F,
        Float::from_int(flags.reinterpret_as_int()),
        alpha_cutoff,
        0.0F,
        0.0F,
      ]),
    ),
    HostMaterial2dBinding::texture(1U, texture_id),
    HostMaterial2dBinding::sampler(2U, texture_id),
  ]
  HostMaterial2dBindGroup::new(bindings)
}

///|
fn host_material2d_wireframe_bind_group(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
) -> HostMaterial2dBindGroup {
  HostMaterial2dBindGroup::new([
    HostMaterial2dBinding::uniform(
      0U,
      host_material2d_f32le_pack([color_r, color_g, color_b, color_a]),
    ),
  ])
}

///|
pub(all) struct HostMesh3dPreprocessShaderWorkItem {
  input_index : Int
  output_or_indirect_parameters_index : Int
}

///|
pub(all) struct HostMesh3dPreprocessMeshInput {
  translation_x : Float
  translation_y : Float
  translation_z : Float
  rotation_x : Float
  rotation_y : Float
  rotation_z : Float
  rotation_w : Float
  scale_x : Float
  scale_y : Float
  scale_z : Float
  previous_translation_x : Float
  previous_translation_y : Float
  previous_translation_z : Float
  previous_rotation_x : Float
  previous_rotation_y : Float
  previous_rotation_z : Float
  previous_rotation_w : Float
  previous_scale_x : Float
  previous_scale_y : Float
  previous_scale_z : Float
  flags : UInt
  first_vertex_index : Int
  first_index_index : Int
  index_count : Int
  tag : Int
}

///|
pub(all) struct HostMesh3dPreprocessFrustumPlane {
  normal_x : Float
  normal_y : Float
  normal_z : Float
  distance : Float
}

///|
pub(all) struct HostMesh3dPreprocessView {
  clip_from_world : GpuClipMatrix
  unjittered_clip_from_world : GpuClipMatrix
  world_from_clip : GpuClipMatrix
  world_from_view : GpuClipMatrix
  view_from_world : GpuClipMatrix
  clip_from_view : GpuClipMatrix
  view_from_clip : GpuClipMatrix
  world_position_x : Float
  world_position_y : Float
  world_position_z : Float
  exposure : Float
  viewport_x : Float
  viewport_y : Float
  viewport_width : Float
  viewport_height : Float
  main_pass_viewport_x : Float
  main_pass_viewport_y : Float
  main_pass_viewport_width : Float
  main_pass_viewport_height : Float
  frustum_planes : Array[HostMesh3dPreprocessFrustumPlane]
  mip_bias : Float
}

///|
pub(all) struct HostMesh3dPreprocessPreviousView {
  view_from_world : GpuClipMatrix
  clip_from_world : GpuClipMatrix
  clip_from_view : GpuClipMatrix
  world_from_clip : GpuClipMatrix
  view_from_clip : GpuClipMatrix
}

///|
pub(all) struct HostMesh3dPreprocessMeshCullingData {
  aabb_center_x : Float
  aabb_center_y : Float
  aabb_center_z : Float
  aabb_half_extents_x : Float
  aabb_half_extents_y : Float
  aabb_half_extents_z : Float
}

///|
pub(all) struct HostMesh3dPreprocessIndirectParametersCpuMetadata {
  base_output_index : Int
  batch_set_index : Int
}

///|
pub(all) struct HostMesh3dPreprocessIndirectParametersGpuMetadata {
  mesh_index : Int
  early_instance_count : Int
  late_instance_count : Int
}

///|
pub(all) struct HostMesh3dPreprocessIndirectBatchSet {
  indirect_parameters_count : Int
  indirect_parameters_base : Int
}

///|
pub(all) struct HostMesh3dPreprocessDispatchMetadata {
  direct_workgroup_count : Int
  indexed_workgroup_count : Int
  non_indexed_workgroup_count : Int
  late_indexed_workgroup_count : Int
  late_non_indexed_workgroup_count : Int
}

///|
pub(all) struct HostMesh3dPreprocessCameraPayload {
  view : HostMesh3dPreprocessView
  previous_view : HostMesh3dPreprocessPreviousView
  mesh_culling_data : Array[HostMesh3dPreprocessMeshCullingData]
  mesh_inputs : Array[HostMesh3dPreprocessMeshInput]
  direct_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  non_indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  late_indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  late_non_indexed_work_items : Array[HostMesh3dPreprocessShaderWorkItem]
  indexed_cpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ]
  indexed_gpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ]
  indexed_batch_sets : Array[HostMesh3dPreprocessIndirectBatchSet]
  non_indexed_cpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersCpuMetadata,
  ]
  non_indexed_gpu_metadata : Array[
    HostMesh3dPreprocessIndirectParametersGpuMetadata,
  ]
  non_indexed_batch_sets : Array[HostMesh3dPreprocessIndirectBatchSet]
  dispatch_metadata : HostMesh3dPreprocessDispatchMetadata
}

///|
pub const MESH3D_PREPROCESS_PHASE_MAIN : Int = 0

///|
pub const MESH3D_PREPROCESS_PHASE_EARLY_OCCLUSION : Int = 1

///|
pub const MESH3D_PREPROCESS_PHASE_LATE_OCCLUSION : Int = 2

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_MAIN : Int = 0

///|
pub const MESH3D_BUILD_INDIRECT_PHASE_EARLY : Int = 1

///|
priv struct SurfaceBinding {
  surface_id : NativeGpuSurface
  window : Int
  target_id : Int
}

///|
priv struct FrameBinding {
  frame_id : NativeGpuFrame
  surface_id : NativeGpuSurface
}

///|
const PRIMARY_DEVICE_ID : NativeGpuDevice = 1

///|
const PRIMARY_QUEUE_ID : NativeGpuQueue = 2

///|
const DEFAULT_ASSETS_DIR : String = "./assets"

///|
let backend_ref : Ref[GpuBackend?] = Ref::new(None)

///|
let surfaces_ref : Ref[Array[SurfaceBinding]] = Ref::new([])

///|
let next_surface_id_ref : Ref[Int] = Ref::new(1)

///|
let next_frame_id_ref : Ref[Int] = Ref::new(1)

///|
let frames_ref : Ref[Array[FrameBinding]] = Ref::new([])

///|

///|
let gizmo_line_mesh_id_ref : Ref[Int] = Ref::new(0)

///|
let debug_frame_counter_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_invalid_id_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_invalid_id_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh3d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh2d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh2d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh3d_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_mesh3d_executed_draw_calls_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_pass_total_count_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_pass_2d_count_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_pass_3d_main_count_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_pass_3d_motion_vector_count_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_pass_3d_point_shadow_count_ref : Ref[Int] = Ref::new(0)

///|
let current_frame_pass_total_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
let current_frame_pass_2d_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
let current_frame_pass_3d_main_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
let current_frame_pass_3d_motion_vector_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
let current_frame_pass_3d_point_shadow_cpu_ms_ref : Ref[Float] = Ref::new(0.0F)

///|
let active_pass_phase_ref : Ref[Int] = Ref::new(RENDER_PASS_PHASE_NONE)

///|
let active_pass_start_time_ref : Ref[Float?] = Ref::new(None)

///|
let last_frame_render_diagnostics_snapshot_ref : Ref[RenderDiagnosticsSnapshot] = Ref::new(
  RenderDiagnosticsSnapshot::default(),
)

///|
let debug_mesh2d_drop_no_frame_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pass_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pass_state_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_missing_mesh_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_bad_stride_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_pipeline_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_uniform_buf_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_uniform_bg_ref : Ref[Int] = Ref::new(0)

///|
let debug_mesh2d_drop_no_texture_ref : Ref[Int] = Ref::new(0)

///|
fn render_diagnostics_reset_pass_counters() -> Unit {
  current_frame_pass_total_count_ref.val = 0
  current_frame_pass_2d_count_ref.val = 0
  current_frame_pass_3d_main_count_ref.val = 0
  current_frame_pass_3d_motion_vector_count_ref.val = 0
  current_frame_pass_3d_point_shadow_count_ref.val = 0
  current_frame_pass_total_cpu_ms_ref.val = 0.0F
  current_frame_pass_2d_cpu_ms_ref.val = 0.0F
  current_frame_pass_3d_main_cpu_ms_ref.val = 0.0F
  current_frame_pass_3d_motion_vector_cpu_ms_ref.val = 0.0F
  current_frame_pass_3d_point_shadow_cpu_ms_ref.val = 0.0F
}

///|
fn render_diagnostics_pass_phase_from_3d_pass_kind(pass_kind : Int) -> Int {
  match pass_kind_base_kind(pass_kind) {
    PASS_KIND_BASE_MOTION_VECTOR => RENDER_PASS_PHASE_3D_MOTION_VECTOR
    PASS_KIND_BASE_POINT_SHADOW => RENDER_PASS_PHASE_3D_POINT_SHADOW
    _ => RENDER_PASS_PHASE_3D_MAIN
  }
}

///|
fn render_diagnostics_end_active_pass_timing() -> Unit {
  if active_pass_start_time_ref.val is Some(start_time) {
    let elapsed_ms = (@time.host_time_now() - start_time) * 1000.0F
    current_frame_pass_total_count_ref.val = current_frame_pass_total_count_ref.val +
      1
    current_frame_pass_total_cpu_ms_ref.val = current_frame_pass_total_cpu_ms_ref.val +
      elapsed_ms
    match active_pass_phase_ref.val {
      RENDER_PASS_PHASE_2D => {
        current_frame_pass_2d_count_ref.val = current_frame_pass_2d_count_ref.val +
          1
        current_frame_pass_2d_cpu_ms_ref.val = current_frame_pass_2d_cpu_ms_ref.val +
          elapsed_ms
      }
      RENDER_PASS_PHASE_3D_MOTION_VECTOR => {
        current_frame_pass_3d_motion_vector_count_ref.val = current_frame_pass_3d_motion_vector_count_ref.val +
          1
        current_frame_pass_3d_motion_vector_cpu_ms_ref.val = current_frame_pass_3d_motion_vector_cpu_ms_ref.val +
          elapsed_ms
      }
      RENDER_PASS_PHASE_3D_POINT_SHADOW => {
        current_frame_pass_3d_point_shadow_count_ref.val = current_frame_pass_3d_point_shadow_count_ref.val +
          1
        current_frame_pass_3d_point_shadow_cpu_ms_ref.val = current_frame_pass_3d_point_shadow_cpu_ms_ref.val +
          elapsed_ms
      }
      RENDER_PASS_PHASE_3D_MAIN => {
        current_frame_pass_3d_main_count_ref.val = current_frame_pass_3d_main_count_ref.val +
          1
        current_frame_pass_3d_main_cpu_ms_ref.val = current_frame_pass_3d_main_cpu_ms_ref.val +
          elapsed_ms
      }
      _ => ()
    }
  }
  active_pass_start_time_ref.val = None
  active_pass_phase_ref.val = RENDER_PASS_PHASE_NONE
}

///|
fn render_diagnostics_begin_active_pass_timing(phase : Int) -> Unit {
  active_pass_phase_ref.val = phase
  active_pass_start_time_ref.val = Some(@time.host_time_now())
}

///|
fn next_surface_id() -> NativeGpuSurface {
  let id = next_surface_id_ref.val
  next_surface_id_ref.val = next_surface_id_ref.val + 1
  id
}

///|
fn next_frame_id() -> NativeGpuFrame {
  let id = next_frame_id_ref.val
  next_frame_id_ref.val = next_frame_id_ref.val + 1
  id
}

///|
fn surface_target_id_from_surface_id(surface_id : NativeGpuSurface) -> Int {
  -surface_id
}

///|
fn find_surface_binding(surface_id : NativeGpuSurface) -> SurfaceBinding? {
  for binding in surfaces_ref.val {
    if binding.surface_id == surface_id {
      return Some(binding)
    }
  }
  None
}

///|
fn find_surface_binding_by_window(window : Int) -> SurfaceBinding? {
  for binding in surfaces_ref.val {
    if binding.window == window {
      return Some(binding)
    }
  }
  None
}

///|
fn remove_frame_binding(frame_id : NativeGpuFrame) -> NativeGpuSurface? {
  let next : Array[FrameBinding] = []
  let found : Ref[NativeGpuSurface?] = Ref::new(None)
  for binding in frames_ref.val {
    if binding.frame_id == frame_id {
      found.val = Some(binding.surface_id)
    } else {
      next.push(binding)
    }
  }
  frames_ref.val = next
  found.val
}

///|

///|
fn env_or_default(key : String, default_value : String) -> String {
  match @sys.get_env_var(key) {
    Some(value) if value != "" => value
    _ => default_value
  }
}

///|
pub fn mesh3d_preprocess_disabled_by_env() -> Bool {
  match @sys.get_env_var("MGSTUDIO_RENDER3D_DISABLE_GPU_PREPROCESS") {
    Some(flag) => flag == "1"
    None => false
  }
}

///|
fn debug_runtime_error(context : String, err : Error) -> Unit {
  @debug.debug("[renderer] " + context + ": " + err.to_string())
}

///|
fn ensure_backend() -> GpuBackend? {
  if backend_ref.val is Some(backend) {
    return Some(backend)
  }
  let assets_base = env_or_default("MGSTUDIO_ASSETS_DIR", DEFAULT_ASSETS_DIR)
  let backend = GpuBackend::new(assets_base~) catch { _ => return None }
  backend_ref.val = Some(backend)
  Some(backend)
}

///|
fn parse_f32_csv(csv : String) -> Array[Float]? {
  let trimmed = csv.trim().to_string()
  if trimmed == "" {
    return Some([])
  }
  let values : Array[Float] = []
  for part in csv.split(",") {
    let token = part.to_string().trim().to_string()
    if token == "" {
      continue
    }
    let parsed = @strconv.parse_double(token) catch { _ => return None }
    values.push(Float::from_double(parsed))
  }
  Some(values)
}

///|
pub fn request_device() -> NativeGpuDevice {
  if ensure_backend() is Some(_) {
    PRIMARY_DEVICE_ID
  } else {
    0
  }
}

///|
pub fn get_queue(device : NativeGpuDevice) -> NativeGpuQueue {
  if device == PRIMARY_DEVICE_ID && ensure_backend() is Some(_) {
    PRIMARY_QUEUE_ID
  } else {
    0
  }
}

///|
pub fn create_surface(window : Int) -> NativeGpuSurface {
  let surface_id = next_surface_id()
  let target_id = surface_target_id_from_surface_id(surface_id)
  surfaces_ref.val.push(SurfaceBinding::{ surface_id, window, target_id })
  if ensure_backend() is Some(backend) {
    backend.create_surface_binding(surface_id, target_id, window)
  }
  surface_id
}

///|
pub fn surface_target_id(surface : NativeGpuSurface) -> Int {
  match find_surface_binding(surface) {
    Some(binding) => binding.target_id
    None => 0
  }
}

///|
pub fn surface_target_id_for_window(window : Int) -> Int {
  match find_surface_binding_by_window(window) {
    Some(binding) => binding.target_id
    None => 0
  }
}

///|
pub fn set_active_surface_target(target_id : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_active_surface_target(target_id)
  }
}

///|
pub fn set_mesh3d_gpu_instance_builder_enabled(enabled : Bool) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.mesh3d_gpu_instance_builder_enabled = enabled
  }
}

///|
pub fn mesh3d_indirect_first_instance_supported() -> Bool {
  if ensure_backend() is Some(backend) {
    return backend.device.supported_features_contains_u32(
      @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
    )
  }
  false
}

///|
pub fn upload_mesh3d_preprocess_camera_payload(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  payload~ : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.upload_mesh3d_preprocess_camera_payload(
      camera_key_hi, camera_key_lo, payload,
    )
  }
}

///|
pub fn build_mesh3d_indirect_parameters(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_BUILD_INDIRECT_PHASE_MAIN,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.build_mesh3d_indirect_parameters(
      camera_key_hi, camera_key_lo, phase_kind,
    ) catch {
      err => debug_runtime_error("build_mesh3d_indirect_parameters", err)
    }
  }
}

///|
pub fn preprocess_mesh3d(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_PREPROCESS_PHASE_MAIN,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.preprocess_mesh3d(camera_key_hi, camera_key_lo, phase_kind) catch {
      err => debug_runtime_error("preprocess_mesh3d", err)
    }
  }
}

///|
pub fn downsample_mesh3d_depth_pyramid(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.downsample_mesh3d_depth_pyramid(camera_key_hi, camera_key_lo) catch {
      err => debug_runtime_error("downsample_mesh3d_depth_pyramid", err)
    }
  }
}

///|
pub fn configure_surface(
  device~ : NativeGpuDevice,
  surface~ : NativeGpuSurface,
  width~ : Int,
  height~ : Int,
  present_mode_kind? : Int = SURFACE_PRESENT_MODE_AUTO_VSYNC,
  composite_alpha_mode_kind? : Int = SURFACE_COMPOSITE_ALPHA_MODE_AUTO,
  desired_maximum_frame_latency? : Int = SURFACE_DEFAULT_DESIRED_MAXIMUM_FRAME_LATENCY,
) -> Unit {
  device |> ignore
  if surface <= 0 {
    return
  }
  if ensure_backend() is Some(backend) {
    backend.configure_surface_binding(
      surface, width, height, present_mode_kind, composite_alpha_mode_kind, desired_maximum_frame_latency,
    )
  }
}

///|
pub fn begin_frame(surface : NativeGpuSurface) -> NativeGpuFrame {
  if surface <= 0 {
    return 0
  }
  active_pass_phase_ref.val = RENDER_PASS_PHASE_NONE
  active_pass_start_time_ref.val = None
  current_frame_mesh2d_draw_calls_ref.val = 0
  current_frame_mesh2d_executed_draw_calls_ref.val = 0
  current_frame_mesh3d_draw_calls_ref.val = 0
  current_frame_mesh3d_executed_draw_calls_ref.val = 0
  render_diagnostics_reset_pass_counters()
  if ensure_backend() is Some(backend) {
    backend.begin_frame_binding(surface)
    let frame_id = next_frame_id()
    frames_ref.val.push(FrameBinding::{ frame_id, surface_id: surface })
    return frame_id
  }
  0
}

///|
pub fn end_frame(frame : NativeGpuFrame) -> Unit {
  guard remove_frame_binding(frame) is Some(surface_id) else { return }
  if ensure_backend() is Some(backend) {
    backend.end_frame_binding(surface_id) catch {
      err => debug_runtime_error("end_frame", err)
    }
  }
  render_diagnostics_end_active_pass_timing()
  last_frame_render_diagnostics_snapshot_ref.val = RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls: current_frame_mesh2d_draw_calls_ref.val,
    mesh2d_executed_draw_calls: current_frame_mesh2d_executed_draw_calls_ref.val,
    mesh3d_draw_calls: current_frame_mesh3d_draw_calls_ref.val,
    mesh3d_executed_draw_calls: current_frame_mesh3d_executed_draw_calls_ref.val,
    pass_total_count: current_frame_pass_total_count_ref.val,
    pass_2d_count: current_frame_pass_2d_count_ref.val,
    pass_3d_main_count: current_frame_pass_3d_main_count_ref.val,
    pass_3d_motion_vector_count: current_frame_pass_3d_motion_vector_count_ref.val,
    pass_3d_point_shadow_count: current_frame_pass_3d_point_shadow_count_ref.val,
    pass_total_cpu_ms: current_frame_pass_total_cpu_ms_ref.val,
    pass_2d_cpu_ms: current_frame_pass_2d_cpu_ms_ref.val,
    pass_3d_main_cpu_ms: current_frame_pass_3d_main_cpu_ms_ref.val,
    pass_3d_motion_vector_cpu_ms: current_frame_pass_3d_motion_vector_cpu_ms_ref.val,
    pass_3d_point_shadow_cpu_ms: current_frame_pass_3d_point_shadow_cpu_ms_ref.val,
  }
  debug_frame_counter_ref.val = debug_frame_counter_ref.val + 1
  if debug_frame_counter_ref.val % 60 == 0 {
    @debug.debug(
      "[renderer] draw stats(60f): mesh2d=" +
      debug_mesh2d_draw_calls_ref.val.to_string() +
      ", mesh2d_invalid_id=" +
      debug_mesh2d_invalid_id_calls_ref.val.to_string() +
      ", mesh2d_executed=" +
      debug_mesh2d_executed_draw_calls_ref.val.to_string() +
      ", mesh2d_drop(no_frame/no_pass/no_state/missing/stride/pipeline/ubo/bg/tex)=" +
      debug_mesh2d_drop_no_frame_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_pass_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_pass_state_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_missing_mesh_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_bad_stride_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_pipeline_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_uniform_buf_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_uniform_bg_ref.val.to_string() +
      "/" +
      debug_mesh2d_drop_no_texture_ref.val.to_string() +
      ", mesh3d=" +
      debug_mesh3d_draw_calls_ref.val.to_string() +
      ", mesh3d_invalid_id=" +
      debug_mesh3d_invalid_id_calls_ref.val.to_string() +
      ", mesh3d_executed=" +
      debug_mesh3d_executed_draw_calls_ref.val.to_string(),
    )
    debug_mesh2d_draw_calls_ref.val = 0
    debug_mesh3d_draw_calls_ref.val = 0
    debug_mesh2d_invalid_id_calls_ref.val = 0
    debug_mesh3d_invalid_id_calls_ref.val = 0
    debug_mesh2d_executed_draw_calls_ref.val = 0
    debug_mesh3d_executed_draw_calls_ref.val = 0
    debug_mesh2d_drop_no_frame_ref.val = 0
    debug_mesh2d_drop_no_pass_ref.val = 0
    debug_mesh2d_drop_no_pass_state_ref.val = 0
    debug_mesh2d_drop_missing_mesh_ref.val = 0
    debug_mesh2d_drop_bad_stride_ref.val = 0
    debug_mesh2d_drop_no_pipeline_ref.val = 0
    debug_mesh2d_drop_no_uniform_buf_ref.val = 0
    debug_mesh2d_drop_no_uniform_bg_ref.val = 0
    debug_mesh2d_drop_no_texture_ref.val = 0
  }
}

///|
pub fn begin_pass(
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
  if ensure_backend() is Some(backend) {
    backend.begin_pass(
      target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
      camera_rotation, camera_scale, viewport_x, viewport_y, viewport_width, viewport_height,
      viewport_depth_min, viewport_depth_max, clear_enabled,
    ) catch {
      err => debug_runtime_error("begin_pass", err)
    }
  }
}

///|
pub fn begin_pass_with_depth(
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
  if ensure_backend() is Some(backend) {
    backend.begin_pass_with_depth(
      target_id, width, height, clear_r, clear_g, clear_b, clear_a, camera_x, camera_y,
      camera_rotation, camera_scale, viewport_x, viewport_y, viewport_width, viewport_height,
      viewport_depth_min, viewport_depth_max, clear_enabled,
    ) catch {
      err => debug_runtime_error("begin_pass_with_depth", err)
    }
  }
}

///|
pub fn begin_pass_3d(
  target_id~ : Int,
  target_layer? : Int = -1,
  secondary_target_id? : Int = -1,
  width~ : Int,
  height~ : Int,
  clear_r~ : Float,
  clear_g~ : Float,
  clear_b~ : Float,
  clear_a~ : Float,
  camera_x~ : Float,
  camera_y~ : Float,
  camera_z~ : Float,
  camera_exposure~ : Float,
  camera_rot_x~ : Float,
  camera_rot_y~ : Float,
  camera_rot_z~ : Float,
  camera_rot_w~ : Float,
  clip_from_world_x_axis_x~ : Float,
  clip_from_world_x_axis_y~ : Float,
  clip_from_world_x_axis_z~ : Float,
  clip_from_world_x_axis_w~ : Float,
  clip_from_world_y_axis_x~ : Float,
  clip_from_world_y_axis_y~ : Float,
  clip_from_world_y_axis_z~ : Float,
  clip_from_world_y_axis_w~ : Float,
  clip_from_world_z_axis_x~ : Float,
  clip_from_world_z_axis_y~ : Float,
  clip_from_world_z_axis_z~ : Float,
  clip_from_world_z_axis_w~ : Float,
  clip_from_world_w_axis_x~ : Float,
  clip_from_world_w_axis_y~ : Float,
  clip_from_world_w_axis_z~ : Float,
  clip_from_world_w_axis_w~ : Float,
  unjittered_clip_from_world_x_axis_x~ : Float,
  unjittered_clip_from_world_x_axis_y~ : Float,
  unjittered_clip_from_world_x_axis_z~ : Float,
  unjittered_clip_from_world_x_axis_w~ : Float,
  unjittered_clip_from_world_y_axis_x~ : Float,
  unjittered_clip_from_world_y_axis_y~ : Float,
  unjittered_clip_from_world_y_axis_z~ : Float,
  unjittered_clip_from_world_y_axis_w~ : Float,
  unjittered_clip_from_world_z_axis_x~ : Float,
  unjittered_clip_from_world_z_axis_y~ : Float,
  unjittered_clip_from_world_z_axis_z~ : Float,
  unjittered_clip_from_world_z_axis_w~ : Float,
  unjittered_clip_from_world_w_axis_x~ : Float,
  unjittered_clip_from_world_w_axis_y~ : Float,
  unjittered_clip_from_world_w_axis_z~ : Float,
  unjittered_clip_from_world_w_axis_w~ : Float,
  previous_clip_from_world_x_axis_x~ : Float,
  previous_clip_from_world_x_axis_y~ : Float,
  previous_clip_from_world_x_axis_z~ : Float,
  previous_clip_from_world_x_axis_w~ : Float,
  previous_clip_from_world_y_axis_x~ : Float,
  previous_clip_from_world_y_axis_y~ : Float,
  previous_clip_from_world_y_axis_z~ : Float,
  previous_clip_from_world_y_axis_w~ : Float,
  previous_clip_from_world_z_axis_x~ : Float,
  previous_clip_from_world_z_axis_y~ : Float,
  previous_clip_from_world_z_axis_z~ : Float,
  previous_clip_from_world_z_axis_w~ : Float,
  previous_clip_from_world_w_axis_x~ : Float,
  previous_clip_from_world_w_axis_y~ : Float,
  previous_clip_from_world_w_axis_z~ : Float,
  previous_clip_from_world_w_axis_w~ : Float,
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
  point_shadow_near~ : Float,
  pass_kind~ : Int,
  clear_enabled~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.begin_pass_3d(
      target_id, target_layer, secondary_target_id, width, height, clear_r, clear_g,
      clear_b, clear_a, camera_x, camera_y, camera_z, camera_exposure, camera_rot_x,
      camera_rot_y, camera_rot_z, camera_rot_w, clip_from_world_x_axis_x, clip_from_world_x_axis_y,
      clip_from_world_x_axis_z, clip_from_world_x_axis_w, clip_from_world_y_axis_x,
      clip_from_world_y_axis_y, clip_from_world_y_axis_z, clip_from_world_y_axis_w,
      clip_from_world_z_axis_x, clip_from_world_z_axis_y, clip_from_world_z_axis_z,
      clip_from_world_z_axis_w, clip_from_world_w_axis_x, clip_from_world_w_axis_y,
      clip_from_world_w_axis_z, clip_from_world_w_axis_w, unjittered_clip_from_world_x_axis_x,
      unjittered_clip_from_world_x_axis_y, unjittered_clip_from_world_x_axis_z, unjittered_clip_from_world_x_axis_w,
      unjittered_clip_from_world_y_axis_x, unjittered_clip_from_world_y_axis_y, unjittered_clip_from_world_y_axis_z,
      unjittered_clip_from_world_y_axis_w, unjittered_clip_from_world_z_axis_x, unjittered_clip_from_world_z_axis_y,
      unjittered_clip_from_world_z_axis_z, unjittered_clip_from_world_z_axis_w, unjittered_clip_from_world_w_axis_x,
      unjittered_clip_from_world_w_axis_y, unjittered_clip_from_world_w_axis_z, unjittered_clip_from_world_w_axis_w,
      previous_clip_from_world_x_axis_x, previous_clip_from_world_x_axis_y, previous_clip_from_world_x_axis_z,
      previous_clip_from_world_x_axis_w, previous_clip_from_world_y_axis_x, previous_clip_from_world_y_axis_y,
      previous_clip_from_world_y_axis_z, previous_clip_from_world_y_axis_w, previous_clip_from_world_z_axis_x,
      previous_clip_from_world_z_axis_y, previous_clip_from_world_z_axis_z, previous_clip_from_world_z_axis_w,
      previous_clip_from_world_w_axis_x, previous_clip_from_world_w_axis_y, previous_clip_from_world_w_axis_z,
      previous_clip_from_world_w_axis_w, viewport_x, viewport_y, viewport_width,
      viewport_height, ambient_r, ambient_g, ambient_b, ambient_brightness, directional_dir_x,
      directional_dir_y, directional_dir_z, directional_color_r, directional_color_g,
      directional_color_b, directional_illuminance, point_pos_x, point_pos_y, point_pos_z,
      point_color_r, point_color_g, point_color_b, point_intensity, point_range,
      spot_pos_x, spot_pos_y, spot_pos_z, spot_dir_x, spot_dir_y, spot_dir_z, spot_color_r,
      spot_color_g, spot_color_b, spot_intensity, spot_range, spot_inner_angle, spot_outer_angle,
      point_shadow_near, pass_kind, clear_enabled,
    ) catch {
      err => debug_runtime_error("begin_pass_3d", err)
    }
  }
}

///|
pub fn set_scissor(x~ : Int, y~ : Int, width~ : Int, height~ : Int) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_scissor(x, y, width, height) catch {
      _ => ()
    }
  }
}

///|
pub fn clear_scissor() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.clear_scissor() catch {
      _ => ()
    }
  }
}

///|
pub fn draw_sprite(
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
  draw_sprite_uv(
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
    uv_min_x=0.0F,
    uv_min_y=0.0F,
    uv_max_x=1.0F,
    uv_max_y=1.0F,
  )
}

///|
pub fn draw_sprite_uv(
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
  if ensure_backend() is Some(backend) {
    backend.draw_sprite_uv(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      uv_min_x, uv_min_y, uv_max_x, uv_max_y,
    ) catch {
      err => debug_runtime_error("draw_sprite_uv", err)
    }
  }
}

///|
pub fn draw_ui_rect(
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
  if ensure_backend() is Some(backend) {
    backend.draw_ui_rect(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      uv_min_x, uv_min_y, uv_max_x, uv_max_y, flags, radius_tl, radius_tr, radius_br,
      radius_bl, border_left, border_top, border_right, border_bottom,
    ) catch {
      err => debug_runtime_error("draw_ui_rect", err)
    }
  }
}

///|
pub fn draw_ui_box_shadow(
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
  if ensure_backend() is Some(backend) {
    backend.draw_ui_box_shadow(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      size_x, size_y, radius_tl, radius_tr, radius_br, radius_bl, blur, samples,
    ) catch {
      err => debug_runtime_error("draw_ui_box_shadow", err)
    }
  }
}

///|
pub fn draw_ui_texture_slice(
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
  if ensure_backend() is Some(backend) {
    backend.draw_ui_texture_slice(
      texture_id, x, y, rotation, scale_x, scale_y, color_r, color_g, color_b, color_a,
      texture_slice_l, texture_slice_t, texture_slice_r, texture_slice_b, target_slice_l,
      target_slice_t, target_slice_r, target_slice_b, repeat_side_x, repeat_side_y,
      repeat_center_x, repeat_center_y, atlas_l, atlas_t, atlas_r, atlas_b,
    ) catch {
      err => debug_runtime_error("draw_ui_texture_slice", err)
    }
  }
}

///|
pub fn draw_mesh(
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
  alpha_mode_kind~ : Int,
  alpha_cutoff~ : Float,
  texture_id~ : Int,
  uv_offset_x~ : Float,
  uv_offset_y~ : Float,
  uv_scale_x~ : Float,
  uv_scale_y~ : Float,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit {
  let material_bind_group = host_material2d_color_material_bind_group(
    color_r, color_g, color_b, color_a, alpha_mode_kind, alpha_cutoff, texture_id,
    uv_offset_x, uv_offset_y, uv_scale_x, uv_scale_y,
  )
  draw_mesh_material(
    mesh_id~,
    x~,
    y~,
    rotation~,
    scale_x~,
    scale_y~,
    alpha_mode_kind~,
    material_bind_group~,
    vertex_shader_path~,
    fragment_shader_path~,
  )
}

///|
pub fn draw_mesh_wireframe(
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
) -> Unit {
  debug_mesh2d_draw_calls_ref.val = debug_mesh2d_draw_calls_ref.val + 1
  current_frame_mesh2d_draw_calls_ref.val = current_frame_mesh2d_draw_calls_ref.val +
    1
  if mesh_id <= 0 {
    debug_mesh2d_invalid_id_calls_ref.val = debug_mesh2d_invalid_id_calls_ref.val +
      1
  }
  if ensure_backend() is Some(backend) {
    let alpha_mode_kind = if color_a < 1.0F {
      MESH2D_ALPHA_MODE_KIND_BLEND
    } else {
      MESH2D_ALPHA_MODE_KIND_OPAQUE
    }
    let material_bind_group = host_material2d_wireframe_bind_group(
      color_r, color_g, color_b, color_a,
    )
    backend.draw_mesh_material_with_options(
      mesh_id,
      x,
      y,
      rotation,
      scale_x,
      scale_y,
      alpha_mode_kind,
      material_bind_group,
      vertex_shader_path=None,
      fragment_shader_path=Some(MESH2D_WIREFRAME_SHADER_PATH),
      wireframe=true,
    ) catch {
      err => debug_runtime_error("draw_mesh_wireframe", err)
    }
  }
}

///|
pub fn draw_mesh_material(
  mesh_id~ : Int,
  x~ : Float,
  y~ : Float,
  rotation~ : Float,
  scale_x~ : Float,
  scale_y~ : Float,
  alpha_mode_kind~ : Int,
  material_bind_group~ : HostMaterial2dBindGroup,
  vertex_shader_path? : String? = None,
  fragment_shader_path? : String? = None,
) -> Unit {
  debug_mesh2d_draw_calls_ref.val = debug_mesh2d_draw_calls_ref.val + 1
  current_frame_mesh2d_draw_calls_ref.val = current_frame_mesh2d_draw_calls_ref.val +
    1
  if mesh_id <= 0 {
    debug_mesh2d_invalid_id_calls_ref.val = debug_mesh2d_invalid_id_calls_ref.val +
      1
  }
  if ensure_backend() is Some(backend) {
    backend.draw_mesh_material(
      mesh_id,
      x,
      y,
      rotation,
      scale_x,
      scale_y,
      alpha_mode_kind,
      material_bind_group,
      vertex_shader_path~,
      fragment_shader_path~,
    ) catch {
      err => debug_runtime_error("draw_mesh_material", err)
    }
  }
}

///|
pub fn draw_mesh3d(
  mesh_id~ : Int,
  preprocess_camera_key_hi? : Int = 0,
  preprocess_camera_key_lo? : Int = 0,
  draw_storage_index? : Int = -1,
  indirect_kind? : Int = 0,
  indirect_parameters_index? : Int = -1,
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
  uv_transform_a~ : Float,
  uv_transform_b~ : Float,
  uv_transform_c~ : Float,
  uv_transform_d~ : Float,
  uv_transform_tx~ : Float,
  uv_transform_ty~ : Float,
  uv_transform_mode~ : Float,
  normal_texture_id~ : Int,
  emissive_texture_id~ : Int,
  metallic_roughness_texture_id~ : Int,
  occlusion_texture_id~ : Int,
  depth_texture_id~ : Int,
  emissive_r~ : Float,
  emissive_g~ : Float,
  emissive_b~ : Float,
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
  alpha_cutoff~ : Float,
  material_flags~ : UInt,
  transmission_source_texture_id~ : Int,
  transmission_blur_taps~ : Float,
  transmission_steps~ : Float,
  point_shadow_texture_id~ : Int,
  point_shadow_enabled~ : Float,
  point_shadow_depth_bias~ : Float,
  cull_mode~ : Int,
  shader_path? : String? = None,
  skinning_matrices? : Array[Float]? = None,
) -> Unit {
  debug_mesh3d_draw_calls_ref.val = debug_mesh3d_draw_calls_ref.val + 1
  current_frame_mesh3d_draw_calls_ref.val = current_frame_mesh3d_draw_calls_ref.val +
    1
  if mesh_id <= 0 {
    debug_mesh3d_invalid_id_calls_ref.val = debug_mesh3d_invalid_id_calls_ref.val +
      1
  }
  if ensure_backend() is Some(backend) {
    backend.draw_mesh3d(
      mesh_id, preprocess_camera_key_hi, preprocess_camera_key_lo, draw_storage_index,
      indirect_kind, indirect_parameters_index, x, y, z, rotation_x, rotation_y,
      rotation_z, rotation_w, scale_x, scale_y, scale_z, previous_x, previous_y,
      previous_z, previous_rotation_x, previous_rotation_y, previous_rotation_z,
      previous_rotation_w, previous_scale_x, previous_scale_y, previous_scale_z,
      color_r, color_g, color_b, color_a, texture_id, uv_transform_a, uv_transform_b,
      uv_transform_c, uv_transform_d, uv_transform_tx, uv_transform_ty, uv_transform_mode,
      normal_texture_id, emissive_texture_id, metallic_roughness_texture_id, occlusion_texture_id,
      depth_texture_id, emissive_r, emissive_g, emissive_b, metallic, roughness,
      reflectance, parallax_depth_scale, max_parallax_layer_count, max_relief_mapping_search_steps,
      anisotropy_texture_id, anisotropy_strength, anisotropy_rotation, specular_tint_texture_id,
      specular_tint_r, specular_tint_g, specular_tint_b, diffuse_transmission, specular_transmission,
      thickness, ior, alpha_cutoff, material_flags, transmission_source_texture_id,
      transmission_blur_taps, transmission_steps, point_shadow_texture_id, point_shadow_enabled,
      point_shadow_depth_bias, cull_mode, shader_path, skinning_matrices~,
    ) catch {
      err => debug_runtime_error("draw_mesh3d", err)
    }
  }
}

///|
pub fn draw_motion_blur(
  scene_texture_id~ : Int,
  velocity_texture_id~ : Int,
  shutter_angle~ : Float,
  samples~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.draw_motion_blur(
      scene_texture_id, velocity_texture_id, shutter_angle, samples,
    ) catch {
      err => debug_runtime_error("draw_motion_blur", err)
    }
  }
}

///|
pub fn render_diagnostics_snapshot() -> RenderDiagnosticsSnapshot {
  last_frame_render_diagnostics_snapshot_ref.val
}

///|
pub fn render_diagnostics_commit_current_frame_snapshot() -> Unit {
  render_diagnostics_end_active_pass_timing()
  last_frame_render_diagnostics_snapshot_ref.val = RenderDiagnosticsSnapshot::{
    mesh2d_draw_calls: current_frame_mesh2d_draw_calls_ref.val,
    mesh2d_executed_draw_calls: current_frame_mesh2d_executed_draw_calls_ref.val,
    mesh3d_draw_calls: current_frame_mesh3d_draw_calls_ref.val,
    mesh3d_executed_draw_calls: current_frame_mesh3d_executed_draw_calls_ref.val,
    pass_total_count: current_frame_pass_total_count_ref.val,
    pass_2d_count: current_frame_pass_2d_count_ref.val,
    pass_3d_main_count: current_frame_pass_3d_main_count_ref.val,
    pass_3d_motion_vector_count: current_frame_pass_3d_motion_vector_count_ref.val,
    pass_3d_point_shadow_count: current_frame_pass_3d_point_shadow_count_ref.val,
    pass_total_cpu_ms: current_frame_pass_total_cpu_ms_ref.val,
    pass_2d_cpu_ms: current_frame_pass_2d_cpu_ms_ref.val,
    pass_3d_main_cpu_ms: current_frame_pass_3d_main_cpu_ms_ref.val,
    pass_3d_motion_vector_cpu_ms: current_frame_pass_3d_motion_vector_cpu_ms_ref.val,
    pass_3d_point_shadow_cpu_ms: current_frame_pass_3d_point_shadow_cpu_ms_ref.val,
  }
}

///|
pub fn render_diagnostics_reset_current_frame_counters() -> Unit {
  active_pass_phase_ref.val = RENDER_PASS_PHASE_NONE
  active_pass_start_time_ref.val = None
  current_frame_mesh2d_draw_calls_ref.val = 0
  current_frame_mesh2d_executed_draw_calls_ref.val = 0
  current_frame_mesh3d_draw_calls_ref.val = 0
  current_frame_mesh3d_executed_draw_calls_ref.val = 0
  render_diagnostics_reset_pass_counters()
  last_frame_render_diagnostics_snapshot_ref.val = RenderDiagnosticsSnapshot::default()
}

///|

///|
pub fn draw_gizmo_line(
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
  let line_width_value = if line_width < 1.0F { 1.0F } else { line_width }
  style_kind |> ignore
  gap_scale |> ignore
  line_scale |> ignore
  let dx = end_x - start_x
  let dy = end_y - start_y
  let length = Float::sqrt(dx * dx + dy * dy)
  if length <= 0.0F {
    return
  }
  let center_x = (start_x + end_x) * 0.5F
  let center_y = (start_y + end_y) * 0.5F
  let rotation = atan2f(dy, dx)
  let color_r = (start_r + end_r) * 0.5F
  let color_g = (start_g + end_g) * 0.5F
  let color_b = (start_b + end_b) * 0.5F
  let color_a = (start_a + end_a) * 0.5F
  if ensure_backend() is Some(backend) {
    try {
      let mesh_id = if gizmo_line_mesh_id_ref.val > 0 {
        gizmo_line_mesh_id_ref.val
      } else {
        let created = backend.create_mesh_rectangle(1.0F, 1.0F)
        if created > 0 {
          gizmo_line_mesh_id_ref.val = created
        }
        created
      }
      if mesh_id > 0 {
        let alpha_mode_kind = if color_a < 1.0F {
          MESH2D_ALPHA_MODE_KIND_BLEND
        } else {
          MESH2D_ALPHA_MODE_KIND_OPAQUE
        }
        backend.draw_mesh(
          mesh_id, center_x, center_y, rotation, length, line_width_value, color_r,
          color_g, color_b, color_a, alpha_mode_kind, 0.5F, -1, 0.0F, 0.0F, 1.0F,
          1.0F,
        )
      }
    } catch {
      err => debug_runtime_error("draw_gizmo_line", err)
    }
  }
}

///|
pub fn end_pass() -> Unit {
  if ensure_backend() is Some(backend) {
    backend.end_pass() catch {
      err => debug_runtime_error("end_pass", err)
    }
  }
}

///|
pub fn create_render_target(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target(width, height, nearest)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_render_target_rgba16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target_rgba16f(width, height, nearest)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_render_target_rg16f(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_render_target_rg16f(width, height, nearest)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_render_target_with_formats(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  format_raw~ : Int,
  sample_format_raw~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      let sample_format = if sample_format_raw < 0 {
        None
      } else {
        Some(sample_format_raw.reinterpret_as_uint())
      }
      return backend.create_render_target_with_formats(
        width,
        height,
        nearest,
        format_raw.reinterpret_as_uint(),
        sample_format,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn create_point_light_shadow_target(size~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_point_light_shadow_target(size)
    } catch {
      _ => ()
    }
  }
  0
}

///|
fn mip_dim(base : Int, level : Int) -> Int {
  let shifted = base >> level
  if shifted <= 0 {
    1
  } else {
    shifted
  }
}

///|
pub fn asset_create_texture_empty(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let safe_mips = if mip_level_count <= 0 { 1 } else { mip_level_count }
  if ensure_backend() is Some(backend) {
    try {
      if safe_mips == 1 {
        let bytes = Bytes::makei(safe_width * safe_height * 4, _ => {
          (0).to_byte()
        })
        return backend.create_texture_rgba8(
          safe_width, safe_height, bytes, nearest,
        )
      }
      let levels : Array[Bytes] = []
      for level in 0..<safe_mips {
        let level_width = mip_dim(safe_width, level)
        let level_height = mip_dim(safe_height, level)
        levels.push(
          Bytes::makei(level_width * level_height * 4, _ => (0).to_byte()),
        )
      }
      return backend.create_texture_stacked_2d_with_format(
        safe_width,
        safe_height,
        1,
        @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
        levels,
        nearest,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_create_texture_3d_with_format(
  width~ : Int,
  height~ : Int,
  depth~ : Int,
  format_raw~ : Int,
  pixels~ : Bytes,
) -> Int {
  let safe_width = if width <= 0 { 1 } else { width }
  let safe_height = if height <= 0 { 1 } else { height }
  let safe_depth = if depth <= 0 { 1 } else { depth }
  if ensure_backend() is Some(backend) {
    try {
      let levels = [pixels]
      return backend.create_texture_3d_with_format(
        safe_width,
        safe_height,
        safe_depth,
        format_raw.reinterpret_as_uint(),
        levels,
      )
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_write_texture_region_rgba8(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.write_texture_region_rgba8(
      texture_id, x, y, width, height, pixels_rgba8,
    )
  }
}

///|
pub fn asset_write_texture_region_rgba8_mip(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  mip_level~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.write_texture_region_rgba8_mip(
      texture_id, x, y, width, height, mip_level, pixels_rgba8,
    )
  }
}

///|
pub fn asset_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    try {
      return backend.create_texture_mip_view(texture_id, mip_level)
    } catch {
      _ => ()
    }
  }
  0
}

///|
pub fn asset_texture_width(texture_id~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    backend.texture_width(texture_id)
  } else {
    0
  }
}

///|
pub fn asset_texture_height(texture_id~ : Int) -> Int {
  if ensure_backend() is Some(backend) {
    backend.texture_height(texture_id)
  } else {
    0
  }
}

///|
pub fn asset_is_texture_loaded(texture_id~ : Int) -> Bool {
  if ensure_backend() is Some(backend) {
    backend.is_texture_loaded(texture_id)
  } else {
    false
  }
}

///|
pub fn asset_supported_compressed_image_formats() -> Int {
  if ensure_backend() is Some(backend) {
    backend.supported_compressed_image_formats_mask()
  } else {
    0
  }
}

///|
pub fn asset_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.copy_texture_to_texture(
      dst_texture_id, dst_x, dst_y, src_texture_id,
    )
  }
}

///|
pub fn asset_set_texture_sampler(
  texture_id~ : Int,
  address_mode_u~ : Int,
  address_mode_v~ : Int,
  address_mode_w~ : Int,
  mag_filter~ : Int,
  min_filter~ : Int,
  mipmap_filter~ : Int,
  lod_min_clamp~ : Float,
  lod_max_clamp~ : Float,
  compare~ : Int,
  anisotropy_clamp~ : Int,
  border_color~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.set_texture_sampler(
      texture_id, address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter,
      mipmap_filter, lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
    ) catch {
      err => {
        let error_message = match err {
          Fatal(message) => message
        }
        abort(
          "wgpu: failed to set texture sampler for texture " +
          texture_id.to_string() +
          ": " +
          error_message,
        )
      }
    }
  }
}

///|
pub fn create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_mesh_capsule(radius, half_length, segments)
  }
  0
}

///|
pub fn create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_mesh_rectangle(width, height)
  }
  0
}

///|
pub fn create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xy_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      let mesh_id = backend.create_mesh_triangles_xy(vertices)
      if mesh_id <= 0 {
        @debug.debug(
          "[renderer] create_mesh_triangles failed: parsed_values=" +
          vertices.length().to_string(),
        )
      }
      return mesh_id
    }
  } else {
    @debug.debug(
      "[renderer] create_mesh_triangles parse failed: csv_len=" +
      vertices_xy_csv.length().to_string(),
    )
  }
  0
}

///|
pub fn create_mesh_triangles_xyuvrgba(vertices_xyuvrgba_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xyuvrgba_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      let mesh_id = backend.create_mesh_triangles_xyuvrgba(vertices)
      if mesh_id <= 0 {
        @debug.debug(
          "[renderer] create_mesh_triangles_xyuvrgba failed: parsed_values=" +
          vertices.length().to_string(),
        )
      }
      return mesh_id
    }
  } else {
    @debug.debug(
      "[renderer] create_mesh_triangles_xyuvrgba parse failed: csv_len=" +
      vertices_xyuvrgba_csv.length().to_string(),
    )
  }
  0
}

///|
pub fn create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  if parse_f32_csv(vertices_xyzuvrgba_csv) is Some(vertices) {
    return create_mesh3d_xyznuvrgba(
      vertices_xyznuvrgba=vertices,
      primitive_topology~,
    )
  } else {
    @debug.debug(
      "[renderer] create_mesh3d parse failed: csv_len=" +
      vertices_xyzuvrgba_csv.length().to_string() +
      ", topology=" +
      primitive_topology.to_string(),
    )
  }
  0
}

///|
pub fn create_mesh3d_xyznuvrgba(
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    let mesh_id = backend.create_mesh3d_xyznuvrgba(
      vertices_xyznuvrgba, primitive_topology,
    )
    if mesh_id <= 0 {
      @debug.debug(
        "[renderer] create_mesh3d_xyznuvrgba failed: values=" +
        vertices_xyznuvrgba.length().to_string() +
        ", topology=" +
        primitive_topology.to_string(),
      )
    }
    return mesh_id
  }
  0
}

///|
pub fn update_mesh3d_xyznuvrgba(
  mesh_id~ : Int,
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Bool {
  if ensure_backend() is Some(backend) {
    return backend.update_mesh3d_xyznuvrgba(
      mesh_id, vertices_xyznuvrgba, primitive_topology,
    )
  }
  false
}

///|
pub fn debug_string(value~ : String) -> Unit {
  @debug.debug(value)
}
