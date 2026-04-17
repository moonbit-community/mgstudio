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
pub fn host_gpu_request_device() -> Int {
  request_device()
}

///|
pub fn host_gpu_get_queue(device : Int) -> Int {
  get_queue(device)
}

///|
pub fn host_gpu_register_wgsl_source(
  rel_path : String,
  source : String,
) -> Unit {
  register_wgsl_source(rel_path, source)
}

///|
pub fn host_gpu_clear_registered_wgsl_source_registry() -> Unit {
  clear_registered_wgsl_source_registry()
}

///|
pub fn host_gpu_clip_matrix(
  x_axis_x : Float,
  x_axis_y : Float,
  x_axis_z : Float,
  x_axis_w : Float,
  y_axis_x : Float,
  y_axis_y : Float,
  y_axis_z : Float,
  y_axis_w : Float,
  z_axis_x : Float,
  z_axis_y : Float,
  z_axis_z : Float,
  z_axis_w : Float,
  w_axis_x : Float,
  w_axis_y : Float,
  w_axis_z : Float,
  w_axis_w : Float,
) -> GpuClipMatrix {
  gpu_clip_matrix(
    x_axis_x, x_axis_y, x_axis_z, x_axis_w, y_axis_x, y_axis_y, y_axis_z, y_axis_w,
    z_axis_x, z_axis_y, z_axis_z, z_axis_w, w_axis_x, w_axis_y, w_axis_z, w_axis_w,
  )
}

///|
pub fn host_gpu_upload_mesh3d_preprocess_camera_payload(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  payload~ : HostMesh3dPreprocessCameraPayload,
) -> Unit {
  upload_mesh3d_preprocess_camera_payload(
    camera_key_hi~,
    camera_key_lo~,
    payload~,
  )
}

///|
pub fn host_gpu_delete_old_mesh3d_preprocess_work_item_buffers(
  retained_camera_keys~ : Array[UInt64],
) -> Unit {
  delete_old_mesh3d_preprocess_work_item_buffers(retained_camera_keys~)
}

///|
pub fn host_gpu_build_mesh3d_indirect_parameters(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_BUILD_INDIRECT_PHASE_MAIN,
) -> Unit {
  build_mesh3d_indirect_parameters(camera_key_hi~, camera_key_lo~, phase_kind~)
}

///|
pub fn host_gpu_preprocess_mesh3d(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
  phase_kind? : Int = MESH3D_PREPROCESS_PHASE_MAIN,
) -> Unit {
  preprocess_mesh3d(camera_key_hi~, camera_key_lo~, phase_kind~)
}

///|
pub fn host_gpu_downsample_mesh3d_depth_pyramid(
  camera_key_hi~ : Int,
  camera_key_lo~ : Int,
) -> Unit {
  downsample_mesh3d_depth_pyramid(camera_key_hi~, camera_key_lo~)
}

///|
pub fn host_gpu_prewarm_mesh3d_pipeline_variants(
  mesh_topology_kind~ : Int,
  cull_mode~ : Int,
  shader_path~ : String?,
  forward_decal~ : Bool,
) -> Unit {
  prewarm_mesh3d_pipeline_variants(
    mesh_topology_kind~,
    cull_mode~,
    shader_path~,
    forward_decal~,
  )
}

///|
pub fn host_debug_string(value~ : String) -> Unit {
  debug_string(value~)
}
