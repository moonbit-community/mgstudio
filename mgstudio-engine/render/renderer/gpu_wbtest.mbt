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
  inspect(gpu_float_approx_eq(matrix.x_axis_x, 0.0025F), content="true")
  inspect(gpu_float_approx_eq(matrix.y_axis_y, 0.0033333334F), content="true")
  inspect(gpu_float_approx_eq(matrix.w_axis_x, 0.0F), content="true")
  inspect(gpu_float_approx_eq(matrix.w_axis_y, 0.0F), content="true")
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
  inspect(ok, content="true")
}

///|
test "renderer: mesh2d resources initialize expected bind groups" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh2d_resources(backend)
  let ok = backend.mesh2d_view_bg is Some(_) &&
    backend.mesh2d_instance_bg is Some(_) &&
    backend.mesh2d_material_bgl is Some(_) &&
    backend.mesh2d_instance_capacity >= MESH2D_UNIFORM_DYNAMIC_STRIDE_BYTES
  inspect(ok, content="true")
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
  inspect(ok, content="true")
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
  inspect(bytes.length(), content="80")
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
    "0:uniform;3:uniform",
    Some("shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/custom/mesh2d_checker_material.wgsl"),
  )
  inspect(key.material_layout_key, content="0:uniform;3:uniform")
  inspect(
    key.vertex_shader_path,
    content="shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl",
  )
  inspect(
    key.fragment_shader_path,
    content="shaders/custom/mesh2d_checker_material.wgsl",
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
    "0:uniform",
    Some("shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/bevy_sprite_render/mesh2d/wireframe2d.wgsl"),
  )
  let wireframe = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    false,
    false,
    false,
    false,
    true,
    "0:uniform",
    Some("shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/bevy_sprite_render/mesh2d/wireframe2d.wgsl"),
  )
  let ok = !fill.wireframe &&
    wireframe.wireframe &&
    mesh2d_pipeline_cache_key(fill) != mesh2d_pipeline_cache_key(wireframe)
  inspect(ok, content="true")
}

///|
test "renderer: mesh2d wireframe shader loads dedicated uniform material" {
  register_renderer_test_shaders()
  let wgsl = load_wgsl_with_defines_required_mesh2d_material(
    Some("shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/bevy_sprite_render/mesh2d/wireframe2d.wgsl"),
    ["VERTEX_POSITIONS", "VERTEX_UVS", "VERTEX_COLORS"],
  )
  inspect(
    wgsl.contains(
      "@group(2) @binding(0) var<uniform> material: Wireframe2dMaterial;",
    ),
    content="true",
  )
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: mesh2d material loader appends custom fragment shader" {
  register_renderer_test_shaders()
  register_renderer_test_shader_source(
    "shaders/custom/mesh2d_checker_material.wgsl",
  )
  let wgsl = load_wgsl_with_defines_required_mesh2d_material(
    Some("shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/custom/mesh2d_checker_material.wgsl"),
    ["VERTEX_POSITIONS", "VERTEX_UVS", "VERTEX_COLORS"],
  )
  inspect(wgsl.contains("fn checker_value("), content="true")
  inspect(
    wgsl.contains(
      "@group(2) @binding(0) var<uniform> material: CheckerMaterial;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(2) @binding(3) var<uniform> settings: CheckerSettings;",
    ),
    content="true",
  )
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: mesh3d draw slot pool grows per draw slot" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh3d_pipeline_rgba8(backend, MESH3D_TOPOLOGY_TRIANGLE_LIST, 0)
  let ok = ensure_mesh3d_draw_slot(backend, 0) is Some(_) &&
    ensure_mesh3d_draw_slot(backend, 1) is Some(_) &&
    backend.mesh3d_bgl_view is Some(_) &&
    backend.mesh3d_view_buf is Some(_) &&
    backend.mesh3d_bgl_draw is Some(_) &&
    backend.mesh3d_draw_slots.length() == 2
  inspect(ok, content="true")
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
        flags: 0U,
        first_vertex_index: 0,
        first_index_index: 4,
        index_count: 36,
        tag: 9,
      },
    ],
  )
  inspect(current_bytes.length(), content="96")
  inspect(previous_bytes.length(), content="96")
}

///|
test "renderer: mesh3d preprocess indirect resources initialize canonical compute pipelines" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh3d_preprocess_indirect_resources(backend)
  let ok = backend.mesh3d_preprocess_direct_bgl is Some(_) &&
    backend.mesh3d_preprocess_direct_pipeline is Some(_) &&
    backend.mesh3d_preprocess_indirect_bgl is Some(_) &&
    backend.mesh3d_preprocess_indirect_pipeline is Some(_) &&
    backend.mesh3d_preprocess_reset_batch_sets_bgl is Some(_) &&
    backend.mesh3d_preprocess_reset_batch_sets_pipeline is Some(_) &&
    backend.mesh3d_preprocess_build_indexed_indirect_bgl is Some(_) &&
    backend.mesh3d_preprocess_build_indexed_indirect_pipeline is Some(_) &&
    backend.mesh3d_preprocess_build_non_indexed_indirect_bgl is Some(_) &&
    backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline is Some(_)
  inspect(ok, content="true")
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
  inspect(!adapter_supports || device_supports, content="true")
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
    state.mesh_input_count == 1 &&
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
    state.indexed_indirect_parameters_count == 1 &&
    state.late_indexed_dispatch_indirect_buffer is Some(_) &&
    state.late_non_indexed_dispatch_indirect_buffer is Some(_) &&
    state.depth_pyramid_texture is Some(_) &&
    state.depth_pyramid_mips.length() >= 1
  inspect(ok, content="true")
}

///|
test "renderer: indexed indirect builder shader keeps gpu metadata read-only" {
  let wgsl = load_wgsl_required_mesh3d_build_indexed_indirect_params("assets")
  inspect(
    wgsl.contains(
      "@group(0) @binding(2) var<storage> indirect_parameters_gpu_metadata:",
    ),
    content="true",
  )
  inspect(
    !wgsl.contains(
      "@group(0) @binding(2) var<storage, read_write> indirect_parameters_gpu_metadata:",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(3) var<storage, read_write> indirect_batch_sets:",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(4) var<storage, read_write> indirect_parameters:",
    ),
    content="true",
  )
}

///|
test "renderer: motion vector resources initialize prepass-style bind groups" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh3d_motion_vector_pipeline(backend)
  let has_mesh_slot = ensure_mesh3d_motion_vector_mesh_slot(backend, 0)
    is Some(_)
  let ok = backend.mesh3d_motion_vector_bgl_view is Some(_) &&
    backend.mesh3d_motion_vector_bgl_empty is Some(_) &&
    backend.mesh3d_motion_vector_bgl_mesh is Some(_) &&
    backend.mesh3d_motion_vector_view_buf is Some(_) &&
    backend.mesh3d_motion_vector_globals_buf is Some(_) &&
    backend.mesh3d_motion_vector_previous_view_buf is Some(_) &&
    backend.mesh3d_motion_vector_visibility_ranges_buf is Some(_) &&
    backend.mesh3d_motion_vector_view_bg is Some(_) &&
    has_mesh_slot &&
    backend.mesh3d_motion_vector_mesh_slots.length() == 1
  inspect(ok, content="true")
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
    point_shadow_near: 0.0F,
  }
  let mesh_bytes = mesh3d_motion_vector_mesh_bytes(
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 0.0F, 0.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F,
  )
  inspect(
    mesh3d_motion_vector_view_uniform_bytes(pass_state).length(),
    content="1024",
  )
  inspect(
    mesh3d_motion_vector_previous_view_uniform_bytes(pass_state).length(),
    content="320",
  )
  inspect(mesh_bytes.length(), content="176")
}

///|
test "renderer: motion vector shader reads canonical Bevy prepass bindings" {
  let wgsl = load_wgsl_required_mesh3d_motion_vector_prepass("assets")
  inspect(
    wgsl.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(2) var<uniform> previous_view_uniforms: PreviousViewUniforms;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(14) var<storage> visibility_ranges: array<vec4<f32>>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("@group(2) @binding(0) var<storage> mesh: array<Mesh>;"),
    content="true",
  )
  inspect(wgsl.contains("fn vertex(vertex_no_morph: Vertex)"), content="true")
  inspect(wgsl.contains("fn fragment(in: VertexOutput)"), content="true")
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
  inspect(ok, content="true")
}

///|
test "renderer: custom mesh3d forward shader consumes normal-aware vertex layout" {
  let wgsl = load_wgsl_from_assets_base_required(
    "assets", "shaders/custom/mesh3d_forward.wgsl",
  )
  inspect(wgsl.contains("struct Mesh3dViewUniform {"), content="true")
  inspect(wgsl.contains("struct Mesh3dLightsUniform {"), content="true")
  inspect(wgsl.contains("struct Mesh3dViewBindings {"), content="true")
  inspect(wgsl.contains("struct LightContribution {"), content="true")
  inspect(wgsl.contains("struct Mesh3dTransformUniform {"), content="true")
  inspect(wgsl.contains("struct Mesh3dMaterialUniform {"), content="true")
  inspect(
    wgsl.contains(
      "@group(0) @binding(0) var<uniform> u_view : Mesh3dViewBindings;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(0) @binding(1) var u_transmission_source_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(2) @binding(0) var<storage, read> u_draws : Mesh3dDrawUniformBuffer;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("@builtin(instance_index) instance_index : u32,"),
    content="true",
  )
  inspect(
    wgsl.contains("@location(4) @interpolate(flat) draw_index : u32,"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(1) var u_base_color_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("@group(1) @binding(2) var u_base_color_sampler : sampler;"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(9) var u_normal_map_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("@group(1) @binding(10) var u_normal_map_sampler : sampler;"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(29) var u_specular_tint_texture : texture_2d<f32>;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "@group(1) @binding(30) var u_specular_tint_sampler : sampler;",
    ),
    content="true",
  )
  inspect(wgsl.contains("uv_transform : mat3x3<f32>,"), content="true")
  inspect(wgsl.contains("reflectance : vec3<f32>,"), content="true")
  inspect(wgsl.contains("flags : u32,"), content="true")
  inspect(wgsl.contains("uv_transform_mode : f32,"), content="true")
  inspect(wgsl.contains("world_position : vec4<f32>,"), content="true")
  inspect(wgsl.contains("ambient_color : vec4<f32>,"), content="true")
  inspect(
    wgsl.contains("directional_light_direction_to_light : vec4<f32>,"),
    content="true",
  )
  inspect(
    wgsl.contains("point_light_color_inverse_square_range : vec4<f32>,"),
    content="true",
  )
  inspect(
    wgsl.contains("point_light_shadow_params : vec4<f32>,"),
    content="true",
  )
  inspect(
    wgsl.contains("spot_light_color_inverse_square_range : vec4<f32>,"),
    content="true",
  )
  inspect(wgsl.contains("spot_light_custom_data : vec4<f32>,"), content="true")
  inspect(wgsl.contains("fn specular_light("), content="true")
  inspect(wgsl.contains("fn directional_light("), content="true")
  inspect(wgsl.contains("fn point_light_shadow("), content="true")
  inspect(wgsl.contains("fn point_light("), content="true")
  inspect(wgsl.contains("fn spot_light("), content="true")
  inspect(wgsl.contains("fn direct_diffuse_light("), content="true")
  inspect(wgsl.contains("fn indirect_diffuse_light("), content="true")
  inspect(wgsl.contains("fn direct_specular_light("), content="true")
  inspect(
    wgsl.contains("fn direct_diffuse_transmissive_light("),
    content="true",
  )
  inspect(
    wgsl.contains("fn indirect_diffuse_transmissive_light("),
    content="true",
  )
  inspect(
    wgsl.contains("fn specular_transmissive_incident_light("),
    content="true",
  )
  inspect(wgsl.contains("fn specular_transmissive_light("), content="true")
  inspect(wgsl.contains("fn transmitted_light("), content="true")
  inspect(wgsl.contains("fn transmission_source_uv("), content="true")
  inspect(wgsl.contains("let directional = directional_light("), content="true")
  inspect(wgsl.contains("let point = point_light("), content="true")
  inspect(wgsl.contains("let spot = spot_light("), content="true")
  inspect(
    wgsl.contains(
      "let direct_light = diffuse_color * direct_diffuse + direct_specular;",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("let indirect_light = diffuse_color * indirect_diffuse;"),
    content="true",
  )
  inspect(
    wgsl.contains(
      "let transmission_blur_taps = i32(max(u_view.lights.spot_light_custom_data.z, 0.0));",
    ),
    content="true",
  )
  inspect(
    wgsl.contains(
      "let transmission_steps = max(u_view.lights.spot_light_custom_data.w, 0.0);",
    ),
    content="true",
  )
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT"),
    content="true",
  )
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK"),
    content="true",
  )
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_TWO_COMPONENT_NORMAL_MAP"),
    content="true",
  )
  inspect(
    wgsl.contains("STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y"),
    content="true",
  )
  inspect(wgsl.contains("material_flag_enabled("), content="true")
  inspect(wgsl.contains("apply_normal_mapping("), content="true")
  inspect(wgsl.contains("discard;"), content="true")
  inspect(!wgsl.contains("has_normal_map ="), content="true")
  inspect(!wgsl.contains("let directional_term ="), content="true")
  inspect(!wgsl.contains("let point_term ="), content="true")
  inspect(!wgsl.contains("let spot_term ="), content="true")
  inspect(!wgsl.contains("point_color_intensity"), content="true")
  inspect(!wgsl.contains("spot_color_intensity"), content="true")
  inspect(!wgsl.contains("emissive_params"), content="true")
  inspect(!wgsl.contains("material_params"), content="true")
  inspect(!wgsl.contains("parallax_params"), content="true")
  inspect(!wgsl.contains("anisotropy_params"), content="true")
  inspect(!wgsl.contains("transmission_params"), content="true")
  inspect(!wgsl.contains("let diffuse_lighting ="), content="true")
  inspect(!wgsl.contains("let specular_lighting ="), content="true")
  inspect(wgsl.contains("@location(1) normal : vec3<f32>"), content="true")
  inspect(wgsl.contains("@location(2) uv : vec2<f32>"), content="true")
  inspect(wgsl.contains("@location(3) color : vec4<f32>"), content="true")
  inspect(
    wgsl.contains("@location(3) world_normal : vec3<f32>"),
    content="true",
  )
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
  inspect(ok, content="true")
}

///|
test "renderer: mesh3d normal map fallback texture is flat normal blue" {
  let backend = GpuBackend::new()
  let previous_backend = backend_ref.val
  backend_ref.val = Some(backend)
  let fallback_texture = ensure_normal_map_fallback_texture(backend)
  inspect(
    fallback_texture.format_raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    content="true",
  )
  let capture = screenshot_capture_texture_sync(texture_id=fallback_texture.id)
  inspect(capture is Some(_), content="true")
  inspect(
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
  backend_ref.val = previous_backend
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
  inspect((flags & (1U << 6)) != 0U, content="true")
}

///|
test "renderer: present mode fallbacks align with bevy auto-vsync policy" {
  let candidates = surface_present_mode_candidates(
    SURFACE_PRESENT_MODE_AUTO_VSYNC,
  )
  let ok = candidates.length() == 2 &&
    candidates[0] == @wgpu.PRESENT_MODE_FIFO_RELAXED &&
    candidates[1] == @wgpu.PRESENT_MODE_FIFO
  inspect(ok, content="true")
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
  inspect(ok, content="true")
}

///|
test "renderer: present mode mailbox fallback keeps bevy ordering" {
  let candidates = surface_present_mode_candidates(SURFACE_PRESENT_MODE_MAILBOX)
  let ok = candidates.length() == 3 &&
    candidates[0] == @wgpu.PRESENT_MODE_MAILBOX &&
    candidates[1] == @wgpu.PRESENT_MODE_IMMEDIATE &&
    candidates[2] == @wgpu.PRESENT_MODE_FIFO
  inspect(ok, content="true")
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
  inspect(ok, content="true")
}

///|
test "renderer: grouped wgsl imports resolve Bevy module files" {
  let assets_base = "assets"
  let modules = build_wgsl_import_module_paths(assets_base)
  let targets : Array[@naga_oil.WgslImportTarget] = []
  @naga_oil.collect_wgsl_import_targets(
    "bevy_render::{\n  color_operations::{hsv_to_rgb, rgb_to_hsv},\n  maths::{PI_2, powsafe},\n}",
    "", targets,
  )
  inspect(targets.length(), content="4")
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[0].raw_path,
      modules,
    ),
    content="bevy_render::color_operations",
  )
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[1].raw_path,
      modules,
    ),
    content="bevy_render::color_operations",
  )
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[2].raw_path,
      modules,
    ),
    content="bevy_render::maths",
  )
  inspect(
    resolve_wgsl_import_module_path_for_test(
      assets_base,
      targets[3].raw_path,
      modules,
    ),
    content="bevy_render::maths",
  )
}

///|
test "renderer: preprocess_wgsl_source supports multiline grouped imports" {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths("assets")
  let preprocessed = preprocess_wgsl_source(
    "assets", "#import bevy_render::{\n  color_operations::{hsv_to_rgb, rgb_to_hsv},\n  maths::{PI_2, powsafe},\n}\nfn demo(color: vec3<f32>) -> vec3<f32> {\n  let h = rgb_to_hsv(color);\n  return hsv_to_rgb(vec3<f32>(h.x + PI_2, h.y, powsafe(h.z, 1.0)));\n}\n",
    defines, value_defines, visited, modules,
  )
  inspect(preprocessed.contains("fn rgb_to_hsv"), content="true")
  inspect(preprocessed.contains("fn hsv_to_rgb"), content="true")
  inspect(preprocessed.contains("const PI_2"), content="true")
  inspect(preprocessed.contains("bevy_render::"), content="false")
}

///|
test "renderer: preprocess_wgsl_source strips module aliases" {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths("assets")
  let preprocessed = preprocess_wgsl_source(
    "assets", "#import bevy_render::maths as maths\nfn demo() -> f32 {\n  return maths::PI_2;\n}\n",
    defines, value_defines, visited, modules,
  )
  inspect(preprocessed.contains("return PI_2;"), content="true")
  inspect(preprocessed.contains("maths::PI_2"), content="false")
}

///|
test "renderer: canonical prepass import preprocessing keeps motion-vector bindings narrow" {
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  defines.set("PREPASS_FRAGMENT", true)
  defines.set("MOTION_VECTOR_PREPASS", true)
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = build_wgsl_import_module_paths("assets")
  let preprocessed = load_wgsl_preprocessed(
    "assets", "shaders/bevy_pbr/prepass/prepass.wgsl", defines, value_defines, visited,
    modules,
  )
  inspect(
    preprocessed.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(
    preprocessed.contains(
      "@group(0) @binding(2) var<uniform> previous_view_uniforms: PreviousViewUniforms;",
    ),
    content="true",
  )
  inspect(preprocessed.contains("point_shadow_textures"), content="false")
  inspect(preprocessed.contains("environment_map_sampler"), content="false")
}

///|
test "renderer: mesh preprocess indirect import preprocessing keeps view bindings narrow" {
  let preprocessed = load_wgsl_required_mesh3d_preprocess_indirect("assets")
  inspect(
    preprocessed.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(
    preprocessed.contains(
      "@group(0) @binding(7) var<storage> indirect_parameters_cpu_metadata:",
    ),
    content="true",
  )
  inspect(
    preprocessed.contains(
      "@group(0) @binding(8) var<storage, read_write> indirect_parameters_gpu_metadata:",
    ),
    content="true",
  )
  inspect(
    preprocessed.contains(
      "@group(0) @binding(9) var<storage> mesh_culling_data: array<MeshCullingData>;",
    ),
    content="true",
  )
  inspect(preprocessed.contains("previous_view_uniforms"), content="false")
  inspect(
    preprocessed.contains(
      "@group(0) @binding(2) var<uniform> previous_view_uniforms:",
    ),
    content="false",
  )
  inspect(preprocessed.contains("point_shadow_textures"), content="false")
  inspect(preprocessed.contains("environment_map_sampler"), content="false")
  inspect(
    preprocessed.contains(
      "@group(1) @binding(0) var diffuse_environment_map: texture_cube<f32>;",
    ),
    content="false",
  )
}

///|
test "renderer: view item imports keep dependent ColorGrading declarations" {
  register_renderer_test_shaders()
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let modules = copy_registered_wgsl_import_module_paths()

  let sprite_visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let sprite_preprocessed = load_wgsl_preprocessed(
    "", "shaders/bevy_sprite_render/render/sprite_view_bindings.wgsl", defines, value_defines,
    sprite_visited, modules,
  )
  inspect(sprite_preprocessed.contains("struct ColorGrading"), content="true")
  inspect(sprite_preprocessed.contains("struct View"), content="true")
  inspect(
    sprite_preprocessed.contains(
      "@group(0) @binding(0) var<uniform> view: View;",
    ),
    content="true",
  )

  let mesh2d_visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let mesh2d_preprocessed = load_wgsl_preprocessed(
    "", "shaders/bevy_sprite_render/mesh2d/mesh2d_view_bindings.wgsl", defines, value_defines,
    mesh2d_visited, modules,
  )
  inspect(mesh2d_preprocessed.contains("struct ColorGrading"), content="true")
  inspect(mesh2d_preprocessed.contains("struct View"), content="true")
  inspect(
    mesh2d_preprocessed.contains(
      "@group(0) @binding(0) var<uniform> view: View;",
    ),
    content="true",
  )
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: registered wgsl sources satisfy strict mesh2d preprocessing" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "shaders/bevy_render/maths.wgsl", "#define_import_path bevy_render::maths\nconst PI_2: f32 = 6.28318;\n",
  )
  register_wgsl_source(
    "shaders/bevy_sprite_render/mesh2d/mesh2d_functions.wgsl", "#define_import_path bevy_sprite::mesh2d_functions\n#import bevy_render::maths::PI_2\nfn twice_pi() -> f32 {\n  return PI_2;\n}\n",
  )
  register_wgsl_source(
    "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl", "#import bevy_sprite::mesh2d_functions as mesh_functions\nfn demo() -> f32 {\n  return mesh_functions::twice_pi();\n}\n",
  )
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let value_defines = default_wgsl_value_defines()
  let visited : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  let modules = copy_registered_wgsl_import_module_paths()
  let preprocessed = load_wgsl_preprocessed(
    "", "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl", defines, value_defines,
    visited, modules,
  )
  inspect(preprocessed.contains("const PI_2"), content="true")
  inspect(preprocessed.contains("return twice_pi();"), content="true")
  inspect(preprocessed.contains("mesh_functions::"), content="false")
  clear_registered_wgsl_source_registry()
}

///|
fn resolve_wgsl_import_module_path_for_test(
  assets_base : String,
  import_path : String,
  modules : @hashmap.HashMap[String, String],
) -> String {
  guard @naga_oil.resolve_wgsl_import_module(assets_base, import_path, modules)
    is Some(resolved_module) else {
    return ""
  }
  resolved_module.module_path
}

///|
fn register_renderer_test_shader_source(path : String) -> Unit {
  let full_path = @path.Path::join("assets", path).normalize().to_string()
  let source = @fs.read_file_to_string(full_path) catch {
    _ => abort("failed to load renderer test shader source: " + path)
  }
  register_wgsl_source(path, source)
}

///|
fn register_renderer_test_shaders() -> Unit {
  clear_registered_wgsl_source_registry()
  let paths = [
    "shaders/bevy_sprite_render/render/sprite.wgsl", "shaders/bevy_sprite_render/render/sprite_view_bindings.wgsl",
    "shaders/bevy_sprite_render/mesh2d/color_material.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d.wgsl",
    "shaders/bevy_sprite_render/mesh2d/wireframe2d.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d_bindings.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_functions.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d_types.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_vertex_output.wgsl", "shaders/bevy_sprite_render/mesh2d/mesh2d_view_bindings.wgsl",
    "shaders/bevy_sprite_render/mesh2d/mesh2d_view_types.wgsl", "shaders/bevy_post_process/bloom/bloom.wgsl",
    "shaders/bevy_core_pipeline/fullscreen_vertex_shader/fullscreen.wgsl", "shaders/bevy_core_pipeline/blit/blit.wgsl",
    "shaders/bevy_core_pipeline/tonemapping/tonemapping.wgsl", "shaders/bevy_core_pipeline/tonemapping/lut_bindings.wgsl",
    "shaders/bevy_core_pipeline/tonemapping/tonemapping_shared.wgsl", "shaders/bevy_render/color_operations.wgsl",
    "shaders/bevy_render/globals.wgsl", "shaders/bevy_render/maths.wgsl", "shaders/bevy_render/view/view.wgsl",
    "shaders/bevy_ui_render/ui.wgsl", "shaders/bevy_ui_render/ui_texture_slice.wgsl",
    "shaders/bevy_ui_render/box_shadow.wgsl",
  ]
  for path in paths {
    register_renderer_test_shader_source(path)
  }
}

///|
fn gpu_test_pass_state(target_id : Int) -> GpuPassState {
  GpuPassState::{
    target_id,
    target_layer: -1,
    secondary_target_id: -1,
    width_logical: 128.0F,
    height_logical: 128.0F,
    is_3d: false,
    camera_x: 0.0F,
    camera_y: 0.0F,
    camera_rot: 0.0F,
    camera_scale: 1.0F,
    camera_z: 0.0F,
    camera_exposure: 1.0F,
    camera_rot_x: 0.0F,
    camera_rot_y: 0.0F,
    camera_rot_z: 0.0F,
    camera_rot_w: 1.0F,
    clip_from_world: GpuClipMatrix::{
      x_axis_x: 1.0F,
      x_axis_y: 0.0F,
      x_axis_z: 0.0F,
      x_axis_w: 0.0F,
      y_axis_x: 0.0F,
      y_axis_y: 1.0F,
      y_axis_z: 0.0F,
      y_axis_w: 0.0F,
      z_axis_x: 0.0F,
      z_axis_y: 0.0F,
      z_axis_z: 1.0F,
      z_axis_w: 0.0F,
      w_axis_x: 0.0F,
      w_axis_y: 0.0F,
      w_axis_z: 0.0F,
      w_axis_w: 1.0F,
    },
    unjittered_clip_from_world: GpuClipMatrix::{
      x_axis_x: 1.0F,
      x_axis_y: 0.0F,
      x_axis_z: 0.0F,
      x_axis_w: 0.0F,
      y_axis_x: 0.0F,
      y_axis_y: 1.0F,
      y_axis_z: 0.0F,
      y_axis_w: 0.0F,
      z_axis_x: 0.0F,
      z_axis_y: 0.0F,
      z_axis_z: 1.0F,
      z_axis_w: 0.0F,
      w_axis_x: 0.0F,
      w_axis_y: 0.0F,
      w_axis_z: 0.0F,
      w_axis_w: 1.0F,
    },
    previous_clip_from_world: GpuClipMatrix::{
      x_axis_x: 1.0F,
      x_axis_y: 0.0F,
      x_axis_z: 0.0F,
      x_axis_w: 0.0F,
      y_axis_x: 0.0F,
      y_axis_y: 1.0F,
      y_axis_z: 0.0F,
      y_axis_w: 0.0F,
      z_axis_x: 0.0F,
      z_axis_y: 0.0F,
      z_axis_z: 1.0F,
      z_axis_w: 0.0F,
      w_axis_x: 0.0F,
      w_axis_y: 0.0F,
      w_axis_z: 0.0F,
      w_axis_w: 1.0F,
    },
    pass_kind: 0,
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
    directional_dir_z: 0.0F,
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
    spot_dir_z: 0.0F,
    spot_color_r: 0.0F,
    spot_color_g: 0.0F,
    spot_color_b: 0.0F,
    spot_intensity: 0.0F,
    spot_range: 0.0F,
    spot_inner_angle: 0.0F,
    spot_outer_angle: 0.0F,
    point_shadow_near: 0.1F,
  }
}

///|
test "renderer: sprite pipeline specializes to hdr render target format" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  sprite_pipeline_for_current_pass(backend) |> ignore
  let ok = match backend.sprite_pipeline_surface_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: rg16f render target preserves Bevy motion-vector texture format" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rg16f(128, 128, false)
  let ok = match find_texture(backend, target_id) {
    Some(texture) => texture.format_raw == @wgpu.TEXTURE_FORMAT_RG16_FLOAT
    None => false
  }
  inspect(ok, content="true")
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
  inspect(ok, content="true")
}

///|
test "renderer: ui node shader loads canonical bevy ui module with anti alias define" {
  register_renderer_test_shaders()
  let with_anti_alias = load_ui_node_wgsl(true)
  let without_anti_alias = load_ui_node_wgsl(false)
  inspect(
    with_anti_alias.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(with_anti_alias.contains("bevy_ui::"), content="false")
  inspect(
    with_anti_alias.contains("antialias(border_distance)"),
    content="true",
  )
  inspect(
    without_anti_alias.contains("let t = 1.0 - step(0.0, border_distance);"),
    content="true",
  )
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
  inspect(backend.ui_vertex_count.reinterpret_as_int(), content="12")
  inspect(backend.ui_vertex_data.length(), content="264")
  inspect(backend.ui_batches.length(), content="2")
  inspect(
    backend.ui_batches[0].instance_count.reinterpret_as_int(),
    content="6",
  )
  inspect(backend.ui_batches[0].anti_alias, content="true")
  inspect(
    backend.ui_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
  inspect(backend.ui_batches[1].anti_alias, content="false")
}

///|
test "renderer: ui texture slice shader loads canonical bevy ui texture slice module" {
  register_renderer_test_shaders()
  let wgsl = load_ui_texture_slice_wgsl()
  inspect(
    wgsl.contains("@group(0) @binding(0)\nvar<uniform> view: View;"),
    content="true",
  )
  inspect(
    wgsl.contains("@group(0) @binding(1)\nvar<uniform> globals: Globals;"),
    content="true",
  )
  inspect(
    wgsl.contains("@group(1) @binding(0) var sprite_texture: texture_2d<f32>;"),
    content="true",
  )
  inspect(wgsl.contains("bevy_render::"), content="false")
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
  inspect(backend.ui_slice_view_bg is Some(_), content="true")
  inspect(backend.ui_slice_vertex_count.reinterpret_as_int(), content="18")
  inspect(backend.ui_slice_vertex_data.length(), content="450")
  inspect(backend.ui_slice_batches.length(), content="2")
  inspect(
    backend.ui_slice_batches[0].instance_count.reinterpret_as_int(),
    content="12",
  )
  inspect(
    backend.ui_slice_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
}

///|
test "renderer: ui box shadow shader loads canonical bevy ui box shadow module" {
  register_renderer_test_shaders()
  let wgsl = load_ui_box_shadow_wgsl(16)
  inspect(wgsl.contains("const SAMPLES: i32 = "), content="true")
  inspect(load_ui_box_shadow_wgsl(8) == wgsl, content="false")
  inspect(
    wgsl.contains("@group(0) @binding(0) var<uniform> view: View;"),
    content="true",
  )
  inspect(wgsl.contains("bevy_render::"), content="false")
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
  inspect(backend.ui_shadow_view_bg is Some(_), content="true")
  inspect(backend.ui_shadow_vertex_count.reinterpret_as_int(), content="18")
  inspect(backend.ui_shadow_vertex_data.length(), content="324")
  inspect(backend.ui_shadow_batches.length(), content="2")
  inspect(backend.ui_shadow_batches[0].samples, content="16")
  inspect(
    backend.ui_shadow_batches[0].instance_count.reinterpret_as_int(),
    content="12",
  )
  inspect(backend.ui_shadow_batches[1].samples, content="8")
  inspect(
    backend.ui_shadow_batches[1].instance_count.reinterpret_as_int(),
    content="6",
  )
}

///|
test "renderer: ui box shadow pipeline specializes by sample count" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  let ok = ui_shadow_pipeline_for_current_pass(backend, 16) is Some(_) &&
    ui_shadow_pipeline_for_current_pass(backend, 8) is Some(_) &&
    backend.ui_shadow_pipeline_cache.length() == 2
  inspect(ok, content="true")
}

///|
test "renderer: mesh pipeline specializes to hdr render target format" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  ensure_mesh2d_resources(backend)
  let format = match current_pass_color_format(backend) {
    Some(v) => v
    None => tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)
  }
  guard backend.mesh_pipeline_layout is Some(layout) else {
    abort("expected default mesh2d pipeline layout")
  }
  mesh2d_get_or_create_pipeline(
    backend,
    mesh2d_pipeline_key_for_format(
      format,
      @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      true,
      false,
      false,
      false,
      false,
      MESH2D_DEFAULT_MATERIAL_LAYOUT_KEY,
      None,
      None,
    ),
    layout,
  )
  |> ignore
  let ok = match backend.mesh_pipeline_surface_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: bloom final composite uses hdr scene target format even from rgba8 final pass" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let final_target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let scene_texture_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(final_target_id))
  bloom_final_composite_pipeline_for_scene_texture(backend, scene_texture_id, 0)
  |> ignore
  let ok = match backend.bloom_upsample_final_pipeline_format {
    Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: bloom runtime resources initialize before first apply path" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let final_target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  let scene_texture_id = backend.create_render_target_rgba16f(128, 128, false)
  backend.pass_state = Some(gpu_test_pass_state(final_target_id))
  let ok = match bloom_prepare_runtime_resources(backend, scene_texture_id, 0) {
    Some((_, _, _, _)) => {
      let final_pipeline_ok = match
        backend.bloom_upsample_final_pipeline_format {
        Some(format) => format == tf(@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT)
        None => false
      }
      backend.bloom_intermediate_bgl is Some(_) &&
      backend.bloom_settings_buf is Some(_) &&
      backend.bloom_sampler is Some(_) &&
      final_pipeline_ok
    }
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: bloom uniforms match canonical bevy struct size" {
  let bytes = bloom_uniform_bytes(
    1920.0F, 1080.0F, 0.0F, 0.0F, 1920.0F, 1080.0F, 1.0F, 0.25F, 1.0F, 1.0F,
  )
  inspect(bytes.length(), content="48")
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
  inspect(ok, content="true")
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
  inspect(ok, content="true")
}

///|
test "renderer: fullscreen tonemapping loads canonical grouped imports from assets tree" {
  clear_registered_wgsl_source_registry()
  let backend = GpuBackend::new(assets_base="assets")
  let source = load_fullscreen_tonemapping_wgsl_with_defines_required(backend, [
    tonemapping_method_define(6),
  ])
  inspect(source.contains("fn hsv_to_rgb"), content="true")
  inspect(source.contains("fn rgb_to_hsv"), content="true")
  inspect(
    source.contains("fn tonemapping_luminance(v: vec3<f32>) -> f32 {"),
    content="true",
  )
  inspect(
    source.contains(
      "fn saturation(color: vec3<f32>, saturationAmount: f32) -> vec3<f32> {",
    ),
    content="true",
  )
  inspect(source.contains("fn sample_tony_mc_mapface_lut("), content="true")
  inspect(source.contains("#define TONEMAPPING_PASS"), content="false")
  inspect(
    source.contains("bevy_render::color_operations::hsv_to_rgb"),
    content="false",
  )
}

///|
test "renderer: fxaa manual source merges fullscreen shader directly" {
  let backend = GpuBackend::new(assets_base="assets")
  let source = load_fxaa_wgsl_with_defines_required(backend, [
    "EDGE_THRESH_HIGH", "EDGE_THRESH_MIN_LOW",
  ])
  inspect(source.contains("struct FullscreenVertexOutput"), content="true")
  inspect(source.contains("fn fullscreen_vertex_shader("), content="true")
  inspect(
    source.contains(
      "bevy_core_pipeline::fullscreen_vertex_shader::FullscreenVertexOutput",
    ),
    content="false",
  )
}

///|
test "renderer: effect stack manual source merges chromatic and vignette helpers" {
  let backend = GpuBackend::new(assets_base="assets")
  let source = load_effect_stack_wgsl_required(backend)
  inspect(source.contains("fn chromatic_aberration("), content="true")
  inspect(source.contains("fn vignette("), content="true")
  inspect(
    source.contains(
      "bevy_post_process::effect_stack::chromatic_aberration::chromatic_aberration",
    ),
    content="false",
  )
}

///|
test "renderer: tonemapping final pipeline specializes to current final target without bloom composite" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  let ok = match
    tonemapping_pipeline_for_format(
      backend,
      tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
      0,
      false,
    ) {
    Some(_) =>
      backend.tonemapping_pipeline_cache.length() == 1 &&
      backend.bloom_upsample_final_pipeline_format is None
    None => false
  }
  inspect(ok, content="true")
}

///|
test "renderer: blit pipeline specializes to current final target for bloom-only resolve" {
  register_renderer_test_shaders()
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_with_format(
    128,
    128,
    false,
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
  )
  backend.pass_state = Some(gpu_test_pass_state(target_id))
  let ok = match
    blit_pipeline_for_format(backend, tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM)) {
    Some(_) =>
      backend.blit_pipeline is Some(_) &&
      backend.blit_pipeline_format is Some(format) &&
      format.raw == @wgpu.TEXTURE_FORMAT_RGBA8_UNORM
    None => false
  }
  inspect(ok, content="true")
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
  inspect(key0 == key1, content="false")
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
  inspect(result.contains("ImageSamplerBorderColor is blocked"), content="true")
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
  inspect(
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
  let previous_backend = backend_ref.val
  backend_ref.val = Some(backend)
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
  inspect(capture is Some(_), content="true")
  inspect(capture.map(fn(value) { value.width }), content="Some(1)")
  inspect(capture.map(fn(value) { value.height }), content="Some(1)")
  inspect(
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
  backend_ref.val = previous_backend
}

///|
test "renderer: sprite uv axis metrics preserves flipped spans" {
  let (signed_scale, region_extent) = sprite_uv_axis_metrics(1.0F, 0.0F, 128)
  let ok = signed_scale == -1.0F && region_extent == 128.0F
  inspect(ok, content="true")
}

///|
test "renderer: sprite uv axis metrics keeps zero span safe" {
  let (signed_scale, region_extent) = sprite_uv_axis_metrics(0.5F, 0.5F, 128)
  let ok = signed_scale == 1.0F && region_extent == 128.0F
  inspect(ok, content="true")
}
