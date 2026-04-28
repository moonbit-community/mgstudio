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
fn gpu_float_approx_eq(a : Float, b : Float) -> Bool {
  (a - b).abs() < 0.0001F
}

///|
test "gpu: 2d clip matrix maps logical viewport coordinates to clip space" {
  let matrix = gpu_clip_matrix_2d(800.0F, 600.0F, 0.0F, 0.0F, 0.0F, 1.0F)
  debug_inspect(gpu_float_approx_eq(matrix.x_axis_x, 0.0025F), content="true")
  debug_inspect(
    gpu_float_approx_eq(matrix.y_axis_y, 0.0033333334F),
    content="true",
  )
  debug_inspect(gpu_float_approx_eq(matrix.w_axis_x, 0.0F), content="true")
  debug_inspect(gpu_float_approx_eq(matrix.w_axis_y, 0.0F), content="true")
}

///|
fn wbtest_mesh3d_preprocess_payload() -> HostMesh3dPreprocessCameraPayload {
  HostMesh3dPreprocessCameraPayload::{
    view: HostMesh3dPreprocessView::{
      clip_from_world: gpu_clip_matrix_identity(),
      unjittered_clip_from_world: gpu_clip_matrix_identity(),
      world_from_clip: gpu_clip_matrix_identity(),
      world_from_view: gpu_clip_matrix_identity(),
      view_from_world: gpu_clip_matrix_identity(),
      clip_from_view: gpu_clip_matrix_identity(),
      view_from_clip: gpu_clip_matrix_identity(),
      world_position_x: 0.0F,
      world_position_y: 0.0F,
      world_position_z: 0.0F,
      exposure: 1.0F,
      viewport_x: 0.0F,
      viewport_y: 0.0F,
      viewport_width: 128.0F,
      viewport_height: 128.0F,
      main_pass_viewport_x: 0.0F,
      main_pass_viewport_y: 0.0F,
      main_pass_viewport_width: 128.0F,
      main_pass_viewport_height: 128.0F,
      frustum_planes: [],
      mip_bias: 0.0F,
    },
    previous_view: HostMesh3dPreprocessPreviousView::{
      view_from_world: gpu_clip_matrix_identity(),
      clip_from_world: gpu_clip_matrix_identity(),
      clip_from_view: gpu_clip_matrix_identity(),
      world_from_clip: gpu_clip_matrix_identity(),
      view_from_clip: gpu_clip_matrix_identity(),
    },
    mesh_culling_data: [
      HostMesh3dPreprocessMeshCullingData::{
        aabb_center_x: 0.0F,
        aabb_center_y: 0.0F,
        aabb_center_z: 0.0F,
        aabb_half_extents_x: 1.0F,
        aabb_half_extents_y: 1.0F,
        aabb_half_extents_z: 1.0F,
      },
    ],
    mesh_inputs: [
      HostMesh3dPreprocessMeshInput::{
        translation_x: 0.0F,
        translation_y: 0.0F,
        translation_z: 0.0F,
        rotation_x: 0.0F,
        rotation_y: 0.0F,
        rotation_z: 0.0F,
        rotation_w: 1.0F,
        scale_x: 1.0F,
        scale_y: 1.0F,
        scale_z: 1.0F,
        previous_translation_x: 0.0F,
        previous_translation_y: 0.0F,
        previous_translation_z: 0.0F,
        previous_rotation_x: 0.0F,
        previous_rotation_y: 0.0F,
        previous_rotation_z: 0.0F,
        previous_rotation_w: 1.0F,
        previous_scale_x: 1.0F,
        previous_scale_y: 1.0F,
        previous_scale_z: 1.0F,
        world_from_local_x_axis_x: 1.0F,
        world_from_local_x_axis_y: 0.0F,
        world_from_local_x_axis_z: 0.0F,
        world_from_local_y_axis_x: 0.0F,
        world_from_local_y_axis_y: 1.0F,
        world_from_local_y_axis_z: 0.0F,
        world_from_local_z_axis_x: 0.0F,
        world_from_local_z_axis_y: 0.0F,
        world_from_local_z_axis_z: 1.0F,
        world_from_local_translation_x: 0.0F,
        world_from_local_translation_y: 0.0F,
        world_from_local_translation_z: 0.0F,
        previous_world_from_local_x_axis_x: 1.0F,
        previous_world_from_local_x_axis_y: 0.0F,
        previous_world_from_local_x_axis_z: 0.0F,
        previous_world_from_local_y_axis_x: 0.0F,
        previous_world_from_local_y_axis_y: 1.0F,
        previous_world_from_local_y_axis_z: 0.0F,
        previous_world_from_local_z_axis_x: 0.0F,
        previous_world_from_local_z_axis_y: 0.0F,
        previous_world_from_local_z_axis_z: 1.0F,
        previous_world_from_local_translation_x: 0.0F,
        previous_world_from_local_translation_y: 0.0F,
        previous_world_from_local_translation_z: 0.0F,
        flags: 0U,
        first_vertex_index: 0,
        first_index_index: 0,
        index_count: 36,
        tag: 0,
      },
    ],
    direct_work_items: [],
    indexed_work_items: [
      HostMesh3dPreprocessShaderWorkItem::{
        input_index: 0,
        output_or_indirect_parameters_index: 0,
      },
    ],
    non_indexed_work_items: [],
    late_indexed_work_items: [],
    late_non_indexed_work_items: [],
    indexed_cpu_metadata: [
      HostMesh3dPreprocessIndirectParametersCpuMetadata::{
        base_output_index: 0,
        batch_set_index: -1,
      },
    ],
    indexed_gpu_metadata: [
      HostMesh3dPreprocessIndirectParametersGpuMetadata::{
        mesh_index: 0,
        early_instance_count: 0,
        late_instance_count: 0,
      },
    ],
    indexed_batch_sets: [
      HostMesh3dPreprocessIndirectBatchSet::{
        indirect_parameters_count: 0,
        indirect_parameters_base: 0,
      },
    ],
    non_indexed_cpu_metadata: [],
    non_indexed_gpu_metadata: [],
    non_indexed_batch_sets: [],
    dispatch_metadata: HostMesh3dPreprocessDispatchMetadata::{
      direct_workgroup_count: 0,
      indexed_workgroup_count: 1,
      non_indexed_workgroup_count: 0,
      late_indexed_workgroup_count: 0,
      late_non_indexed_workgroup_count: 0,
    },
  }
}

///|
test "renderer: interleaved 2d mesh csv keeps original vertex count" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices = [
    -1.0F,
    -1.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    -1.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    1.0F,
    0.0F,
    1.0F,
    0.5F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
  ]
  let mesh_id = backend.create_mesh_triangles_xyuvrgba(vertices)
  let ok = mesh_id > 0 &&
    backend.meshes.length() == 1 &&
    backend.meshes[0].id == mesh_id &&
    backend.meshes[0].vertex_count.reinterpret_as_int() == 3 &&
    backend.meshes[0].vertex_stride_bytes == MESH2D_VERTEX_STRIDE_BYTES
  debug_inspect(ok, content="true")
}

///|
test "renderer: mesh2d resources initialize expected bind groups" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh2d_resources(backend)
  let ok = backend.mesh2d_view_bg is Some(_) &&
    backend.mesh2d_instance_bg is Some(_) &&
    backend.mesh2d_material_bgl is Some(_) &&
    backend.mesh2d_instance_capacity >= MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES
  debug_inspect(ok, content="true")
}

///|
test "renderer: mesh2d dynamic uniform pool grows by required capacity" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh2d_resources(backend)
  let grow_required = backend.mesh2d_instance_capacity +
    MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES
  let ok = ensure_mesh2d_instance_uniform_binding(
      backend,
      MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES,
    )
    is Some(_) &&
    ensure_mesh2d_instance_uniform_binding(backend, grow_required) is Some(_) &&
    backend.mesh2d_instance_capacity >= grow_required
  debug_inspect(ok, content="true")
}

///|
const WBTEST_COLOR_MATERIAL_FLAGS_TEXTURE : UInt = 1U

///|
const WBTEST_COLOR_MATERIAL_FLAGS_ALPHA_MODE_MASK : UInt = 0x40000000U

///|
const WBTEST_COLOR_MATERIAL_FLAGS_ALPHA_MODE_BLEND : UInt = 0x80000000U

///|
fn wbtest_mesh2d_color_material_flags(
  texture_id : Int,
  alpha_mode_kind : Int,
) -> UInt {
  let mut flags = 0U
  if texture_id >= 0 {
    flags = flags | WBTEST_COLOR_MATERIAL_FLAGS_TEXTURE
  }
  if alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_MASK {
    flags = flags | WBTEST_COLOR_MATERIAL_FLAGS_ALPHA_MODE_MASK
  } else if alpha_mode_kind == MESH2D_ALPHA_MODE_KIND_BLEND {
    flags = flags | WBTEST_COLOR_MATERIAL_FLAGS_ALPHA_MODE_BLEND
  }
  flags
}

///|
fn wbtest_mesh2d_color_material_uniform_bytes(
  color_r : Float,
  color_g : Float,
  color_b : Float,
  color_a : Float,
  texture_id : Int,
  uv_offset_x : Float,
  uv_offset_y : Float,
  uv_scale_x : Float,
  uv_scale_y : Float,
  alpha_mode_kind : Int,
  alpha_cutoff : Float,
) -> Bytes {
  let flags = wbtest_mesh2d_color_material_flags(texture_id, alpha_mode_kind)
  let words : Array[UInt] = [
    f32_bits(color_r),
    f32_bits(color_g),
    f32_bits(color_b),
    f32_bits(color_a),
    f32_bits(uv_scale_x),
    f32_bits(0.0F),
    f32_bits(0.0F),
    0U,
    f32_bits(0.0F),
    f32_bits(uv_scale_y),
    f32_bits(0.0F),
    0U,
    f32_bits(uv_offset_x),
    f32_bits(uv_offset_y),
    f32_bits(1.0F),
    0U,
    flags,
    f32_bits(alpha_cutoff),
    0U,
    0U,
  ]
  u32le_pack(words)
}

///|
test "renderer: mesh2d color material uniform bytes match Bevy size" {
  let bytes = wbtest_mesh2d_color_material_uniform_bytes(
    1.0F,
    0.5F,
    0.25F,
    0.75F,
    9,
    0.1F,
    0.2F,
    2.0F,
    3.0F,
    MESH2D_ALPHA_MODE_KIND_MASK,
    0.33F,
  )
  debug_inspect(bytes.length(), content="80")
}

///|
test "renderer: mesh2d pipeline key records custom material shader paths" {
  let key = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    false,
    false,
    false,
    false,
    false,
    false,
    "0:uniform;3:uniform",
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/mesh2d_checker_material.wgsl"),
  )
  debug_inspect(key.material_layout_key, content="\"0:uniform;3:uniform\"")
  debug_inspect(
    key.vertex_shader_path,
    content="\"sprite_render/mesh2d/mesh2d.wgsl\"",
  )
  debug_inspect(
    key.fragment_shader_path,
    content="\"shaders/mesh2d_checker_material.wgsl\"",
  )
}

///|
test "renderer: mesh2d wireframe pipeline key stays distinct from fill pipeline" {
  let fill = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    false,
    false,
    false,
    false,
    false,
    false,
    "0:uniform",
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("sprite_render/mesh2d/wireframe2d.wgsl"),
  )
  let wireframe = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    false,
    false,
    false,
    false,
    false,
    true,
    "0:uniform",
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("sprite_render/mesh2d/wireframe2d.wgsl"),
  )
  let ok = !fill.wireframe &&
    wireframe.wireframe &&
    mesh2d_pipeline_cache_key(fill) != mesh2d_pipeline_cache_key(wireframe)
  debug_inspect(ok, content="true")
}

///|
test "renderer: mesh3d preprocess mesh input bytes match bevy struct size" {
  let (current_bytes, previous_bytes) = mesh3d_preprocess_mesh_inputs_bytes(
    17U,
    [
      HostMesh3dPreprocessMeshInput::{
        translation_x: 1.0F,
        translation_y: 2.0F,
        translation_z: 3.0F,
        rotation_x: 0.0F,
        rotation_y: 0.0F,
        rotation_z: 0.0F,
        rotation_w: 1.0F,
        scale_x: 1.0F,
        scale_y: 2.0F,
        scale_z: 3.0F,
        previous_translation_x: 4.0F,
        previous_translation_y: 5.0F,
        previous_translation_z: 6.0F,
        previous_rotation_x: 0.0F,
        previous_rotation_y: 0.0F,
        previous_rotation_z: 0.0F,
        previous_rotation_w: 1.0F,
        previous_scale_x: 3.0F,
        previous_scale_y: 2.0F,
        previous_scale_z: 1.0F,
        world_from_local_x_axis_x: 1.0F,
        world_from_local_x_axis_y: 0.0F,
        world_from_local_x_axis_z: 0.0F,
        world_from_local_y_axis_x: 0.0F,
        world_from_local_y_axis_y: 2.0F,
        world_from_local_y_axis_z: 0.0F,
        world_from_local_z_axis_x: 0.0F,
        world_from_local_z_axis_y: 0.0F,
        world_from_local_z_axis_z: 3.0F,
        world_from_local_translation_x: 1.0F,
        world_from_local_translation_y: 2.0F,
        world_from_local_translation_z: 3.0F,
        previous_world_from_local_x_axis_x: 3.0F,
        previous_world_from_local_x_axis_y: 0.0F,
        previous_world_from_local_x_axis_z: 0.0F,
        previous_world_from_local_y_axis_x: 0.0F,
        previous_world_from_local_y_axis_y: 2.0F,
        previous_world_from_local_y_axis_z: 0.0F,
        previous_world_from_local_z_axis_x: 0.0F,
        previous_world_from_local_z_axis_y: 0.0F,
        previous_world_from_local_z_axis_z: 1.0F,
        previous_world_from_local_translation_x: 4.0F,
        previous_world_from_local_translation_y: 5.0F,
        previous_world_from_local_translation_z: 6.0F,
        flags: 0U,
        first_vertex_index: 0,
        first_index_index: 4,
        index_count: 36,
        tag: 9,
      },
    ],
  )
  debug_inspect(current_bytes.length(), content="96")
  debug_inspect(previous_bytes.length(), content="96")
}

///|
test "renderer: backend requests indirect-first-instance when adapter supports it" {
  let backend = GpuBackend::new(assets_base="assets")
  let adapter_supports = backend.adapter.supported_features_contains_u32(
    @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
  )
  let device_supports = backend.device.supported_features_contains_u32(
    @wgpu.FEATURE_NAME_INDIRECT_FIRST_INSTANCE,
  )
  debug_inspect(!adapter_supports || device_supports, content="true")
}

///|
test "renderer: mesh3d preprocess upload allocates mesh inputs and indirect parameter buffers" {
  let backend = GpuBackend::new(assets_base="assets")
  backend.upload_mesh3d_preprocess_camera_payload(
    7,
    9,
    wbtest_mesh3d_preprocess_payload(),
  )
  let state = backend.mesh3d_preprocess_camera_upload_states[0]
  let ok = backend.mesh3d_preprocess_camera_upload_states.length() == 1 &&
    state.mesh_input_buffer is Some(_) &&
    state.previous_mesh_input_buffer is Some(_) &&
    state.output_buffer is Some(_) &&
    state.output_count == 1 &&
    state.preprocess_view_buffer is Some(_) &&
    state.previous_view_buffer is Some(_) &&
    state.mesh_culling_data_buffer is Some(_) &&
    state.indexed_gpu_metadata_buffer is Some(_) &&
    state.indexed_gpu_metadata_count == 1 &&
    state.indexed_batch_set_buffer is Some(_) &&
    state.indexed_batch_set_count == 1 &&
    state.indexed_indirect_parameters_buffer is Some(_) &&
    state.indexed_indirect_parameters_capacity > 0UL &&
    state.late_indexed_dispatch_indirect_buffer is Some(_) &&
    state.late_non_indexed_dispatch_indirect_buffer is Some(_) &&
    state.depth_pyramid_texture is Some(_) &&
    state.depth_pyramid_mips.length() >= 1
  debug_inspect(ok, content="true")
}

///|
test "renderer: motion vector prepass buffers match bevy struct sizes" {
  let pass_state = GpuPassState::{
    target_id: -1,
    target_layer: -1,
    secondary_target_id: -1,
    width_logical: 128.0F,
    height_logical: 128.0F,
    is_3d: true,
    camera_x: 1.0F,
    camera_y: 2.0F,
    camera_rot: 0.0F,
    camera_scale: 1.0F,
    camera_z: 3.0F,
    camera_exposure: 1.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    clip_from_world: gpu_clip_matrix_identity(),
    unjittered_clip_from_world: gpu_clip_matrix_identity(),
    previous_clip_from_world: gpu_clip_matrix_identity(),
    pass_kind: PASS_KIND_BASE_MOTION_VECTOR,
    viewport_x: 0U,
    viewport_y: 0U,
    viewport_w: 128U,
    viewport_h: 128U,
    viewport_depth_min: 0.0F,
    viewport_depth_max: 1.0F,
    ambient_r: 0.0F,
    ambient_g: 0.0F,
    ambient_b: 0.0F,
    ambient_brightness: 0.0F,
    directional_dir_x: 0.0F,
    directional_dir_y: 0.0F,
    directional_dir_z: -1.0F,
    directional_color_r: 0.0F,
    directional_color_g: 0.0F,
    directional_color_b: 0.0F,
    directional_illuminance: 0.0F,
    point_pos_x: 0.0F,
    point_pos_y: 0.0F,
    point_pos_z: 0.0F,
    point_color_r: 0.0F,
    point_color_g: 0.0F,
    point_color_b: 0.0F,
    point_intensity: 0.0F,
    point_range: 0.0F,
    spot_pos_x: 0.0F,
    spot_pos_y: 0.0F,
    spot_pos_z: 0.0F,
    spot_dir_x: 0.0F,
    spot_dir_y: 0.0F,
    spot_dir_z: -1.0F,
    spot_color_r: 0.0F,
    spot_color_g: 0.0F,
    spot_color_b: 0.0F,
    spot_intensity: 0.0F,
    spot_range: 0.0F,
    spot_inner_angle: 0.0F,
    spot_outer_angle: 0.0F,
    transmission_blur_taps: 0.0F,
    transmission_steps: 0.0F,
    point_shadow_texture_id: -1,
    point_shadow_enabled: 0.0F,
    point_shadow_depth_bias: 0.0F,
    transmission_source_texture_id: -1,
    environment_diffuse_texture_id: -1,
    environment_specular_texture_id: -1,
    environment_map_intensity: 0.0F,
    environment_map_rotation_x: 0.0F,
    environment_map_rotation_y: 0.0F,
    environment_map_rotation_z: 0.0F,
    environment_map_rotation_w: 1.0F,
    point_shadow_near: 0.0F,
  }
  let mesh_bytes = mesh3d_motion_vector_mesh_bytes(
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, -1,
  )
  debug_inspect(
    mesh3d_motion_vector_view_uniform_bytes(pass_state).length(),
    content="1024",
  )
  debug_inspect(
    mesh3d_motion_vector_previous_view_uniform_bytes(pass_state).length(),
    content="320",
  )
  debug_inspect(mesh_bytes.length(), content="176")
}

///|
test "renderer: large mesh3d upload switches to u32 index buffers" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices : Array[Float] = []
  for i in 0..<65538 {
    let x = Float::from_int(i % 3)
    let y = Float::from_int(i / 3 % 3)
    vertices.push(x)
    vertices.push(y)
    vertices.push(0.0F)
    vertices.push(0.0F)
    vertices.push(0.0F)
    vertices.push(1.0F)
    vertices.push(0.0F)
    vertices.push(0.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
    vertices.push(1.0F)
  }
  let mesh_id = backend.create_mesh3d_xyznuvrgba(vertices, 0)
  let ok = mesh_id > 0 &&
    backend.meshes.length() == 1 &&
    backend.meshes[0].id == mesh_id &&
    backend.meshes[0].vertex_count == 65538U &&
    backend.meshes[0].index_count == 65538U &&
    backend.meshes[0].vertex_stride_bytes == MESH3D_VERTEX_STRIDE_BYTES &&
    backend.meshes[0].index_stride_bytes == 4UL &&
    backend.meshes[0].uses_u32_indices
  debug_inspect(ok, content="true")
}

///|
test "renderer: mesh3d light scalar helpers align with Bevy-style scalar contract" {
  let inverse_square_range = mesh3d_inverse_square_range(10.0F)
  let (spot_scale, spot_offset) = mesh3d_spot_scale_offset(0.25F, 0.5F)
  let inner_cos = Float::from_double(@coremath.cos(0.25F.to_double()))
  let outer_cos = Float::from_double(@coremath.cos(0.5F.to_double()))
  let ok = gpu_float_approx_eq(inverse_square_range, 0.01F) &&
    gpu_float_approx_eq(spot_scale, 1.0F / (inner_cos - outer_cos)) &&
    gpu_float_approx_eq(spot_offset, -outer_cos * spot_scale)
  debug_inspect(ok, content="true")
}

///|
test "renderer: mesh3d normal map fallback texture is flat normal blue" {
  let backend = GpuBackend::new()
  let previous_backend = render_context_backend_for_test()
  render_context_set_backend_for_test(Some(backend))
  let fallback_texture = ensure_normal_map_fallback_texture(backend)
  debug_inspect(
    fallback_texture.format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    content="true",
  )
  let capture = screenshot_capture_texture_sync(texture_id=fallback_texture.id)
  debug_inspect(capture is Some(_), content="true")
  debug_inspect(
    capture.map(fn(value) {
      [
        value.pixels[0].to_uint(),
        value.pixels[1].to_uint(),
        value.pixels[2].to_uint(),
        value.pixels[3].to_uint(),
      ]
    }),
    content="Some([128, 128, 255, 255])",
  )
  render_context_set_backend_for_test(previous_backend)
}

///|
test "renderer: mesh3d runtime flags infer two-component normal map format" {
  let backend = GpuBackend::new()
  let fallback_texture = ensure_normal_map_fallback_texture(backend)
  let two_component_texture = GpuTextureInfo::{
    ..fallback_texture,
    id: 42,
    format_raw: @wgpu.TEXTURE_FORMAT_RG8_UNORM,
  }
  let flags = mesh3d_runtime_material_flags(0U, 42, two_component_texture)
  debug_inspect((flags & (1U << 6)) != 0U, content="true")
}

///|
test "renderer: present mode fallbacks align with bevy auto-vsync policy" {
  let candidates = surface_present_mode_candidates(
    SURFACE_PRESENT_MODE_AUTO_VSYNC,
  )
  let ok = candidates.length() == 2 &&
    candidates[0] == @wgpu.PRESENT_MODE_FIFO_RELAXED &&
    candidates[1] == @wgpu.PRESENT_MODE_FIFO
  debug_inspect(ok, content="true")
}

///|
test "renderer: present mode fallbacks align with bevy auto-no-vsync policy" {
  let candidates = surface_present_mode_candidates(
    SURFACE_PRESENT_MODE_AUTO_NO_VSYNC,
  )
  let ok = candidates.length() == 3 &&
    candidates[0] == @wgpu.PRESENT_MODE_IMMEDIATE &&
    candidates[1] == @wgpu.PRESENT_MODE_MAILBOX &&
    candidates[2] == @wgpu.PRESENT_MODE_FIFO
  debug_inspect(ok, content="true")
}

///|
test "renderer: present mode mailbox fallback keeps bevy ordering" {
  let candidates = surface_present_mode_candidates(SURFACE_PRESENT_MODE_MAILBOX)
  let ok = candidates.length() == 3 &&
    candidates[0] == @wgpu.PRESENT_MODE_MAILBOX &&
    candidates[1] == @wgpu.PRESENT_MODE_IMMEDIATE &&
    candidates[2] == @wgpu.PRESENT_MODE_FIFO
  debug_inspect(ok, content="true")
}

///|
test "renderer: composite alpha mode mapping matches wgpu native constants" {
  let ok = surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_AUTO) ==
    @wgpu.COMPOSITE_ALPHA_MODE_AUTO &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_OPAQUE) ==
    @wgpu.COMPOSITE_ALPHA_MODE_OPAQUE &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_PRE_MULTIPLIED) ==
    @wgpu.COMPOSITE_ALPHA_MODE_PREMULTIPLIED &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_POST_MULTIPLIED) ==
    @wgpu.COMPOSITE_ALPHA_MODE_UNPREMULTIPLIED &&
    surface_alpha_mode_resolve(SURFACE_COMPOSITE_ALPHA_MODE_INHERIT) ==
    @wgpu.COMPOSITE_ALPHA_MODE_INHERIT
  debug_inspect(ok, content="true")
}

///|
test "renderer: registered wgsl sources satisfy strict mesh2d preprocessing" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "render/maths.wgsl", "#define_import_path bevy_render::maths\nconst PI_2: f32 = 6.28318;\n",
  )
  register_wgsl_source(
    "sprite_render/mesh2d/mesh2d_functions.wgsl", "#define_import_path bevy_sprite::mesh2d_functions\n#import bevy_render::maths::PI_2\nfn twice_pi() -> f32 {\n  return PI_2;\n}\n",
  )
  register_wgsl_source(
    "sprite_render/mesh2d/mesh2d.wgsl", "#import bevy_sprite::mesh2d_functions as mesh_functions\nfn demo() -> f32 {\n  return mesh_functions::twice_pi();\n}\n",
  )
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = copy_registered_wgsl_import_module_paths()
  let preprocessed = load_wgsl_preprocessed(
    "", "sprite_render/mesh2d/mesh2d.wgsl", defines, value_defines, visited, modules,
  )
  debug_inspect(preprocessed.contains("const PI_2"), content="true")
  debug_inspect(preprocessed.contains("return twice_pi();"), content="true")
  debug_inspect(preprocessed.contains("mesh_functions::"), content="false")
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: rg16f render target preserves Bevy motion-vector texture format" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rg16f(128, 128, false)
  let ok = match find_texture(backend, target_id) {
    Some(texture) => texture.format_raw == @wgpu.TEXTURE_FORMAT_RG16_FLOAT
    None => false
  }
  debug_inspect(ok, content="true")
}

///|
test "renderer: render target keeps an sRGB sampled view distinct from attachment format" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_with_formats(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    Some(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB),
  )
  let ok = match find_texture(backend, target_id) {
    Some(texture) =>
      texture.format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM &&
      texture.sample_view is Some(_)
    None => false
  }
  debug_inspect(ok, content="true")
}

///|
test "renderer: ui node batching expands rects to vertices and splits anti alias batches" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_ui_resources(backend)
  let texture_id = backend.create_texture_rgba8(
    1,
    1,
    Bytes::makei(4, _ => (255).to_byte()),
    false,
  )
  ui_enqueue_rect(
    backend,
    texture_id,
    0.0F,
    0.0F,
    0.0F,
    20.0F,
    10.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1 | 4,
    2.0F,
    2.0F,
    2.0F,
    2.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
  )
  ui_enqueue_rect(
    backend, texture_id, 8.0F, 4.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F,
    0.0F, 0.0F, 1.0F, 1.0F, 1, 2.0F, 2.0F, 2.0F, 2.0F, 0.0F, 0.0F, 0.0F, 0.0F,
  )
  debug_inspect(backend.ui_vertex_count.reinterpret_as_int(), content="12")
  debug_inspect(backend.ui_vertex_data.length(), content="264")
  debug_inspect(backend.ui_batches.length(), content="2")
  debug_inspect(
    backend.ui_batches[0].instance_count.reinterpret_as_int(),
    content="6",
  )
  debug_inspect(backend.ui_batches[0].anti_alias, content="true")
  debug_inspect(
    backend.ui_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
  debug_inspect(backend.ui_batches[1].anti_alias, content="false")
}

///|
test "renderer: ui texture slice batching expands rects to vertices and merges by texture" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_ui_slice_resources(backend)
  let texture_a = backend.create_texture_rgba8(
    1,
    1,
    Bytes::makei(4, _ => (255).to_byte()),
    false,
  )
  let texture_b = backend.create_texture_rgba8(
    1,
    1,
    Bytes::makei(4, _ => (127).to_byte()),
    false,
  )
  ui_enqueue_texture_slice(
    backend, texture_a, 0.0F, 0.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.1F,
    0.1F, 0.9F, 0.9F, 0.1F, 0.1F, 0.9F, 0.9F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F,
    1.0F, 1.0F,
  )
  ui_enqueue_texture_slice(
    backend, texture_a, 8.0F, 4.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.1F,
    0.1F, 0.9F, 0.9F, 0.1F, 0.1F, 0.9F, 0.9F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F,
    1.0F, 1.0F,
  )
  ui_enqueue_texture_slice(
    backend, texture_b, 16.0F, 8.0F, 0.0F, 20.0F, 10.0F, 1.0F, 1.0F, 1.0F, 1.0F,
    0.1F, 0.1F, 0.9F, 0.9F, 0.1F, 0.1F, 0.9F, 0.9F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F,
    0.0F, 1.0F, 1.0F,
  )
  debug_inspect(backend.ui_slice_view_bg is Some(_), content="true")
  debug_inspect(
    backend.ui_slice_vertex_count.reinterpret_as_int(),
    content="18",
  )
  debug_inspect(backend.ui_slice_vertex_data.length(), content="450")
  debug_inspect(backend.ui_slice_batches.length(), content="2")
  debug_inspect(
    backend.ui_slice_batches[0].instance_count.reinterpret_as_int(),
    content="12",
  )
  debug_inspect(
    backend.ui_slice_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
}

///|
test "renderer: ui box shadow batching expands rects to vertices and merges by samples" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_ui_shadow_resources(backend)
  ui_enqueue_box_shadow(
    backend, 0.0F, 0.0F, 0.0F, 24.0F, 16.0F, 1.0F, 1.0F, 1.0F, 0.5F, 18.0F, 10.0F,
    2.0F, 2.0F, 2.0F, 2.0F, 4.0F, 16,
  )
  ui_enqueue_box_shadow(
    backend, 8.0F, 4.0F, 0.0F, 24.0F, 16.0F, 1.0F, 1.0F, 1.0F, 0.5F, 18.0F, 10.0F,
    2.0F, 2.0F, 2.0F, 2.0F, 4.0F, 16,
  )
  ui_enqueue_box_shadow(
    backend, 16.0F, 8.0F, 0.0F, 24.0F, 16.0F, 1.0F, 1.0F, 1.0F, 0.5F, 18.0F, 10.0F,
    2.0F, 2.0F, 2.0F, 2.0F, 4.0F, 8,
  )
  debug_inspect(backend.ui_shadow_view_bg is Some(_), content="true")
  debug_inspect(
    backend.ui_shadow_vertex_count.reinterpret_as_int(),
    content="18",
  )
  debug_inspect(backend.ui_shadow_vertex_data.length(), content="324")
  debug_inspect(backend.ui_shadow_batches.length(), content="2")
  debug_inspect(backend.ui_shadow_batches[0].samples, content="16")
  debug_inspect(
    backend.ui_shadow_batches[0].instance_count.reinterpret_as_int(),
    content="12",
  )
  debug_inspect(backend.ui_shadow_batches[1].samples, content="8")
  debug_inspect(
    backend.ui_shadow_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
}

///|
test "renderer: bloom uniforms match canonical bevy struct size" {
  let bytes = bloom_uniform_bytes(
    1920.0F, 1080.0F, 0.0F, 0.0F, 1920.0F, 1080.0F, 1.0F, 0.25F, 1.0F, 1.0F,
  )
  debug_inspect(bytes.length(), content="48")
}

///|
test "renderer: bloom intermediate format prefers canonical rg11b10 when renderable" {
  let backend = GpuBackend::new(assets_base="assets")
  let format = bloom_intermediate_texture_format(backend)
  let ok = if backend.device.supported_features_contains_u32(
      @wgpu.FEATURE_NAME_RG11_B10_UFLOAT_RENDERABLE,
    ) {
    format == tf(@wgpu.TEXTURE_FORMAT_RG11_B10_UFLOAT)
  } else {
    format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
  }
  debug_inspect(ok, content="true")
}

///|
test "renderer: bloom mip texture allocates requested mip count" {
  let backend = GpuBackend::new(assets_base="assets")
  let ok = try {
    ensure_bloom_mip_texture(backend, 4, 128, 128)
    match backend.bloom_mip_texture {
      Some(texture) =>
        texture.mip_level_count_u32() == 4U &&
        backend.bloom_mip_views.length() == 4
      None => false
    }
  } catch {
    _ => false
  }
  debug_inspect(ok, content="true")
}

///|
test "renderer: sampler cache key includes compare anisotropy and lod" {
  let key0 = image_sampler_cache_key(
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    0.0F,
    32.0F,
    IMAGE_SAMPLER_COMPARE_UNDEFINED,
    1,
    IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED,
  )
  let key1 = image_sampler_cache_key(
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_ADDRESS_MODE_REPEAT,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    IMAGE_SAMPLER_FILTER_MODE_LINEAR,
    0.0F,
    32.0F,
    IMAGE_SAMPLER_COMPARE_ALWAYS,
    4,
    IMAGE_SAMPLER_BORDER_COLOR_UNDEFINED,
  )
  debug_inspect(key0 == key1, content="false")
}

///|
test "renderer: unsupported border color validation raises exact blocker" {
  let result = try {
    image_sampler_border_color_validate(IMAGE_SAMPLER_BORDER_COLOR_OPAQUE_WHITE)
    "ok"
  } catch {
    err =>
      match err {
        Fatal(message) => message
      }
  }
  debug_inspect(
    result.contains("ImageSamplerBorderColor is blocked"),
    content="true",
  )
}

///|
test "renderer: screenshot capture swizzles bgra8 into rgba8" {
  let pixels = Bytes::from_array([
    (3).to_byte(),
    (2).to_byte(),
    (1).to_byte(),
    (255).to_byte(),
  ])
  let converted = screenshot_capture_pixels_rgba8(
    @wgpu.TEXTURE_FORMAT_BGRA8_UNORM,
    1,
    1,
    pixels,
  )
  debug_inspect(
    converted.map(fn(value) {
      [
        value[0].to_uint(),
        value[1].to_uint(),
        value[2].to_uint(),
        value[3].to_uint(),
      ]
    }),
    content="Some([1, 2, 3, 255])",
  )
}

///|
test "renderer: screenshot capture reads rgba8 texture bytes" {
  let backend = GpuBackend::new()
  let previous_backend = render_context_backend_for_test()
  render_context_set_backend_for_test(Some(backend))
  let texture_id = backend.create_texture_rgba8(
    1,
    1,
    Bytes::from_array([
      (9).to_byte(),
      (8).to_byte(),
      (7).to_byte(),
      (255).to_byte(),
    ]),
    true,
  )
  let capture = screenshot_capture_texture_sync(texture_id~)
  debug_inspect(capture is Some(_), content="true")
  debug_inspect(capture.map(fn(value) { value.width }), content="Some(1)")
  debug_inspect(capture.map(fn(value) { value.height }), content="Some(1)")
  debug_inspect(
    capture.map(fn(value) {
      [
        value.pixels[0].to_uint(),
        value.pixels[1].to_uint(),
        value.pixels[2].to_uint(),
        value.pixels[3].to_uint(),
      ]
    }),
    content="Some([9, 8, 7, 255])",
  )
  render_context_set_backend_for_test(previous_backend)
}

///|
test "renderer: sprite uv axis metrics preserves flipped spans" {
  let (signed_scale, region_extent) = sprite_uv_axis_metrics(1.0F, 0.0F, 128)
  let ok = signed_scale == -1.0F && region_extent == 128.0F
  debug_inspect(ok, content="true")
}

///|
test "renderer: sprite uv axis metrics keeps zero span safe" {
  let (signed_scale, region_extent) = sprite_uv_axis_metrics(0.5F, 0.5F, 128)
  let ok = signed_scale == 1.0F && region_extent == 128.0F
  debug_inspect(ok, content="true")
}
