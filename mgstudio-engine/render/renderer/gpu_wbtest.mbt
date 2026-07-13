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
fn gpu_wbtest_pass_state(
  mesh3d_lights_uniform_bytes? : Bytes? = None,
) -> GpuPassState {
  GpuPassState::{
    target_id: -1,
    target_layer: -1,
    secondary_target_id: -1,
    prepass_depth_texture_id: -1,
    prepass_normal_texture_id: -1,
    prepass_motion_vector_texture_id: -1,
    prepass_deferred_texture_id: -1,
    prepass_deferred_lighting_pass_id_texture_id: -1,
    view_depth_texture_id: -1,
    view_depth_view: None,
    screen_space_reflections: false,
    msaa_sample_count: 1,
    width_logical: 128.0F,
    height_logical: 128.0F,
    is_3d: true,
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
    clip_from_world: gpu_clip_matrix_identity(),
    unjittered_clip_from_world: gpu_clip_matrix_identity(),
    world_from_clip: gpu_clip_matrix_identity(),
    world_from_view: gpu_clip_matrix_identity(),
    view_from_world: gpu_clip_matrix_identity(),
    clip_from_view: gpu_clip_matrix_identity(),
    view_from_clip: gpu_clip_matrix_identity(),
    previous_clip_from_world: gpu_clip_matrix_identity(),
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
    environment_diffuse_texture_ids: [],
    environment_specular_texture_ids: [],
    irradiance_volume_texture_ids: [],
    mesh3d_light_probes_uniform_bytes: None,
    light_probes_uniform_offset: 0U,
    point_shadow_near: 0.0F,
    directional_shadow_texture_id: -1,
    directional_shadow_enabled: 0.0F,
    directional_shadow_depth_bias: 0.0F,
    directional_shadow_normal_bias: 0.0F,
    directional_shadow_soft_size: 0.0F,
    directional_shadow_cascade_count: 0,
    directional_shadow_cascade_overlap: 0.0F,
    directional_shadow_cascade_data: [],
    mesh3d_lights_uniform_bytes,
    tonemap_in_shader: false,
    tonemapping_mode: 0,
    tonemapping_agx_lut_texture_id: -1,
    tonemapping_tony_lut_texture_id: -1,
    tonemapping_blender_lut_texture_id: -1,
    pbr_blue_noise_texture_id: -1,
    pbr_area_light_luts_texture_id: -1,
    pbr_dfg_lut_texture_id: -1,
    deband_dither_enabled: false,
  }
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
test "renderer: wgpu wrapper is a transparent native wrapper" {
  let wrapper = WgpuWrapper::new(7)
  debug_inspect(wrapper.get(), content="7")
  wrapper.set(9)
  debug_inspect(wrapper.into_inner(), content="9")
}

///|
test "renderer: pending command buffers default to empty bevy resource state" {
  let pending = PendingCommandBuffers::PendingCommandBuffers()
  debug_inspect(pending.is_empty(), content="true")
  debug_inspect(pending.len(), content="0")
  pending.push([])
  debug_inspect(pending.take().length(), content="0")
  debug_inspect(pending.is_empty(), content="true")
}

///|
fn pending_submit_test_u32le_at(bytes : Bytes, offset : Int) -> UInt {
  bytes[offset].to_uint() |
  (bytes[offset + 1].to_uint() << 8) |
  (bytes[offset + 2].to_uint() << 16) |
  (bytes[offset + 3].to_uint() << 24)
}

///|
test "renderer: pending command buffers submit map-read callbacks" {
  let instance = @wgpu.Instance::create()
  let adapter = instance.request_adapter_sync()
  let device = adapter.request_device_sync(instance)
  let render_device = RenderDevice::from_wgpu(device)
  let render_queue = render_device.queue()
  let render_instance = RenderInstance::from_wgpu(instance)
  let src = device.create_buffer(
    size=8UL,
    usage=bu(@wgpu.BUFFER_USAGE_COPY_SRC | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  let staging = device.create_buffer(
    size=8UL,
    usage=bu(@wgpu.BUFFER_USAGE_MAP_READ | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  render_queue
  .wgpu_queue()
  .write_buffer(src, 0UL, u32le_pack([0xAABBCCDDU, 0x11223344U]))
  let encoder = render_device.create_command_encoder()
  encoder.copy_buffer_to_buffer(src, 0UL, staging, 0UL, 8UL)
  let completed = @ref.new(false)
  let first_word = @ref.new(0U)
  let pending = PendingCommandBuffers::PendingCommandBuffers()
  pending.push_encoder_map_read(encoder, staging, 0UL, 8UL, fn(
    status,
    bytes,
    _buffer,
  ) {
    completed.val = status == @wgpu.MAP_ASYNC_STATUS_SUCCESS
    if completed.val {
      first_word.val = pending_submit_test_u32le_at(bytes, 0)
    }
  })
  let first_submit = @ref.new(true)
  for _ in 0..<4000 {
    if !completed.val {
      pending.submit(
        render_queue,
        render_device=Some(render_device),
        render_instance=Some(render_instance),
      )
      if first_submit.val {
        first_submit.val = false
        ignore(device.poll(wait=true))
      }
    }
  }
  debug_inspect(completed.val, content="true")
  debug_inspect(first_word.val, content="2864434397")
  debug_inspect(pending.is_empty(), content="true")
  src.release()
  staging.release()
  device.release()
  adapter.release()
  instance.release()
}

///|
test "renderer: surface frame present follows Bevy view target intent" {
  debug_inspect(
    frame_binding_should_present_state(false, false),
    content="false",
  )
  debug_inspect(frame_binding_should_present_state(true, false), content="true")
  debug_inspect(frame_binding_should_present_state(false, true), content="true")
}

///|
fn wbtest_bind_group_layout_has_binding(
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  binding : Int,
) -> Bool {
  for entry in descriptor.entries() {
    if entry.binding() == binding {
      return true
    }
  }
  false
}

///|
fn wbtest_bind_group_layout_binding_count(
  descriptor : @render_resource.BindGroupLayoutDescriptor,
  binding : Int,
) -> Int {
  for entry in descriptor.entries() {
    if entry.binding() == binding {
      return entry.count()
    }
  }
  -1
}

///|
test "renderer: default mesh view layout can include clustered decal bindings" {
  let layout = mesh3d_default_mesh_view_layout(clustered_decals_usable=true)
  let binding_arrays = layout.binding_array_bind_group_layout_descriptor()
  debug_inspect(
    wbtest_bind_group_layout_has_binding(binding_arrays, 5),
    content="true",
  )
  debug_inspect(
    wbtest_bind_group_layout_has_binding(binding_arrays, 6),
    content="true",
  )
  debug_inspect(
    wbtest_bind_group_layout_has_binding(binding_arrays, 7),
    content="true",
  )
}

///|
test "renderer: environment-map layout uses binding arrays when light probes do" {
  let key = @mesh_view_layout.mesh_view_layout_key(
    false,
    false,
    false,
    false,
    true,
    false,
    false,
    false,
    environment_map=true,
  )
  let layout = @mesh_view_layout.render3d_mesh_pipeline_view_layout(
    true,
    true,
    key,
    multiple_light_probes_in_array=true,
    clustered_decals_usable=false,
    irradiance_volumes_usable=false,
    oit_supported=false,
  )
  let binding_arrays = layout.binding_array_bind_group_layout_descriptor()
  debug_inspect(
    wbtest_bind_group_layout_binding_count(binding_arrays, 0),
    content="8",
  )
  debug_inspect(
    wbtest_bind_group_layout_binding_count(binding_arrays, 1),
    content="8",
  )
  debug_inspect(
    wbtest_bind_group_layout_binding_count(binding_arrays, 2),
    content="0",
  )
}

///|
test "renderer: render context state starts empty and finish clears state" {
  let state = RenderContextState::RenderContextState()
  debug_inspect(state.is_empty(), content="true")
  debug_inspect(state.finish().length(), content="0")
  debug_inspect(state.is_empty(), content="true")
}

///|
fn wbtest_mesh3d_preprocess_payload() -> HostMesh3dPreprocessCameraPayload {
  HostMesh3dPreprocessCameraPayload::{
    output_count: 1,
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
  let mesh_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let vertex_layout = mesh2d_material_vertex_buffer_layout(mesh_layout).unwrap()
  let key = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    false,
    false,
    false,
    false,
    false,
    "0:uniform;1:texture;2:sampler",
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/custom_material_2d.wgsl"),
    None,
  )
  debug_inspect(
    key.material_layout_key,
    content="\"0:uniform;1:texture;2:sampler\"",
  )
  debug_inspect(
    key.vertex_shader_path,
    content="\"sprite_render/mesh2d/mesh2d.wgsl\"",
  )
  debug_inspect(
    key.fragment_shader_path,
    content="\"shaders/custom_material_2d.wgsl\"",
  )
}

///|
test "renderer: mesh2d wireframe pipeline key stays distinct from fill pipeline" {
  let mesh_layout = mesh2d_default_mesh_vertex_buffer_layout()
  let vertex_layout = mesh2d_material_vertex_buffer_layout(mesh_layout).unwrap()
  let fill = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    false,
    false,
    false,
    false,
    false,
    "0:uniform",
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("sprite_render/mesh2d/wireframe2d.wgsl"),
    None,
  )
  let wireframe = mesh2d_pipeline_key_for_format(
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
    mesh_layout,
    vertex_layout,
    false,
    false,
    false,
    false,
    false,
    true,
    "0:uniform",
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("sprite_render/mesh2d/wireframe2d.wgsl"),
    None,
  )
  let ok = !fill.wireframe &&
    wireframe.wireframe &&
    mesh2d_pipeline_cache_key(fill) != mesh2d_pipeline_cache_key(wireframe)
  debug_inspect(ok, content="true")
}

///|
fn wbtest_shader_defs_contains(
  shader_defs : Array[String],
  shader_def : String,
) -> Bool {
  mesh3d_shader_defs_to_bool_map(shader_defs).get(shader_def).unwrap_or(false)
}

///|
test "renderer: mesh3d preprocess shader defines match bevy specialization keys" {
  let direct = Mesh3dPreprocessPipelineKey::direct().shader_defs()
  debug_inspect(direct.length(), content="1")
  debug_inspect(
    wbtest_shader_defs_contains(direct, "WRITE_INDIRECT_PARAMETERS_METADATA"),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(direct, "INDIRECT"),
    content="false",
  )
  let early_key = Mesh3dPreprocessPipelineKey::early_occlusion_culling()
  let early = early_key.shader_defs()
  debug_inspect(wbtest_shader_defs_contains(early, "INDIRECT"), content="true")
  debug_inspect(
    wbtest_shader_defs_contains(early, "FRUSTUM_CULLING"),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(early, "OCCLUSION_CULLING"),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(early, "EARLY_PHASE"),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(early, "LATE_PHASE"),
    content="false",
  )
}

///|
test "renderer: depth downsample pipeline keys select Bevy MSAA variants" {
  let standard_first = mesh3d_downsample_depth_pipeline_key(false, false)
  let multisampled_first = mesh3d_downsample_depth_pipeline_key(true, false)
  let multisampled_second = mesh3d_downsample_depth_pipeline_key(true, true)
  debug_inspect(
    wbtest_shader_defs_contains(standard_first.shader_defs(), "MULTISAMPLE"),
    content="false",
  )
  debug_inspect(
    wbtest_shader_defs_contains(multisampled_first.shader_defs(), "MULTISAMPLE"),
    content="true",
  )
  debug_inspect(
    multisampled_first.entry_point(),
    content="\"downsample_depth_first\"",
  )
  debug_inspect(
    multisampled_second.entry_point(),
    content="\"downsample_depth_second\"",
  )
}

///|
test "renderer: depth downsample storage bindings start at pyramid mip zero" {
  debug_inspect(mesh3d_downsample_depth_mip_index_for_binding(1), content="0")
  debug_inspect(mesh3d_downsample_depth_mip_index_for_binding(12), content="11")
}

///|
test "renderer: mesh3d build indirect shader defines match bevy specialization keys" {
  let indexed_main = Mesh3dBuildIndirectParametersPipelineKey::main_occlusion_culling(
    true, true,
  ).shader_defs()
  debug_inspect(
    wbtest_shader_defs_contains(indexed_main, "INDEXED"),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(
      indexed_main, "MULTI_DRAW_INDIRECT_COUNT_SUPPORTED",
    ),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(indexed_main, "OCCLUSION_CULLING"),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(indexed_main, "MAIN_PHASE"),
    content="true",
  )
  debug_inspect(
    wbtest_shader_defs_contains(indexed_main, "EARLY_PHASE"),
    content="false",
  )
  debug_inspect(
    wbtest_shader_defs_contains(indexed_main, "LATE_PHASE"),
    content="false",
  )
  let non_indexed_late = Mesh3dBuildIndirectParametersPipelineKey::late_occlusion_culling(
    false, false,
  ).shader_defs()
  debug_inspect(
    wbtest_shader_defs_contains(non_indexed_late, "INDEXED"),
    content="false",
  )
  debug_inspect(
    wbtest_shader_defs_contains(
      non_indexed_late, "MULTI_DRAW_INDIRECT_COUNT_SUPPORTED",
    ),
    content="false",
  )
  debug_inspect(
    wbtest_shader_defs_contains(non_indexed_late, "LATE_PHASE"),
    content="true",
  )
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
test "renderer: backend requests texture binding arrays when adapter supports it" {
  let backend = GpuBackend::new(assets_base="assets")
  let adapter_supports = backend.adapter.has_feature_native_u32(
    @wgpu.NATIVE_FEATURE_TEXTURE_BINDING_ARRAY,
  )
  let device_supports = backend.device.has_feature_native_u32(
    @wgpu.NATIVE_FEATURE_TEXTURE_BINDING_ARRAY,
  )
  debug_inspect(!adapter_supports || device_supports, content="true")
}

///|
test "renderer: backend requests buffer binding arrays when adapter supports it" {
  let backend = GpuBackend::new(assets_base="assets")
  let adapter_supports = backend.adapter.has_feature_native_u32(
    @wgpu.NATIVE_FEATURE_BUFFER_BINDING_ARRAY,
  )
  let device_supports = backend.device.has_feature_native_u32(
    @wgpu.NATIVE_FEATURE_BUFFER_BINDING_ARRAY,
  )
  debug_inspect(!adapter_supports || device_supports, content="true")
}

///|
test "renderer: backend requests storage resource binding arrays when adapter supports it" {
  let backend = GpuBackend::new(assets_base="assets")
  let adapter_supports = backend.adapter.has_feature_native_u32(
    @wgpu.NATIVE_FEATURE_STORAGE_RESOURCE_BINDING_ARRAY,
  )
  let device_supports = backend.device.has_feature_native_u32(
    @wgpu.NATIVE_FEATURE_STORAGE_RESOURCE_BINDING_ARRAY,
  )
  debug_inspect(!adapter_supports || device_supports, content="true")
}

///|
test "renderer: backend requests sampled texture non-uniform indexing when adapter supports it" {
  let backend = GpuBackend::new(assets_base="assets")
  let feature = @wgpu.NATIVE_FEATURE_SAMPLED_TEXTURE_AND_STORAGE_BUFFER_ARRAY_NON_UNIFORM_INDEXING
  let adapter_supports = backend.adapter.has_feature_native_u32(feature)
  let device_supports = backend.device.has_feature_native_u32(feature)
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
test "renderer: mesh3d preprocess upload state is isolated by render phase" {
  let backend = GpuBackend::new(assets_base="assets")
  let payload = wbtest_mesh3d_preprocess_payload()
  backend.upload_mesh3d_preprocess_camera_payload(7, 9, payload)
  backend.upload_mesh3d_preprocess_camera_payload(
    7,
    9,
    payload,
    phase_id="mgstudio_pbr::Wireframe3d",
  )
  debug_inspect(
    backend.mesh3d_preprocess_camera_upload_states.length(),
    content="2",
  )
  debug_inspect(
    mesh3d_preprocess_camera_upload_state_index(backend, 7, 9),
    content="Some(0)",
  )
  debug_inspect(
    mesh3d_preprocess_camera_upload_state_index(
      backend,
      7,
      9,
      phase_id="mgstudio_pbr::Wireframe3d",
    ),
    content="Some(1)",
  )
}

///|
test "renderer: deleting old preprocess states releases native handles" {
  let backend = GpuBackend::new(assets_base="assets")
  let payload = wbtest_mesh3d_preprocess_payload()
  backend.upload_mesh3d_preprocess_camera_payload(7, 9, payload)
  backend.upload_mesh3d_preprocess_camera_payload(11, 13, payload)
  let before = backend.instance.generate_report()
  let buffers_before = before.hub_buffers_num_kept_from_user()
  let textures_before = before.hub_textures_num_kept_from_user()
  before.release()
  backend.delete_old_mesh3d_preprocess_work_item_buffers([
    mesh3d_preprocess_camera_key(7, 9),
  ])
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let released = backend.mesh3d_preprocess_camera_upload_states.length() == 1 &&
    after.hub_buffers_num_kept_from_user() < buffers_before &&
    after.hub_textures_num_kept_from_user() < textures_before
  after.release()
  backend.shutdown()
  debug_inspect(released, content="true")
}

///|
test "renderer: backend shutdown releases preprocessing owners" {
  let backend = GpuBackend::new(assets_base="assets")
  let observer = backend.instance.add_ref()
  backend.upload_mesh3d_preprocess_camera_payload(
    7,
    9,
    wbtest_mesh3d_preprocess_payload(),
  )
  let bgl = backend.device.create_bind_group_layout_empty()
  let layout = backend.device.create_pipeline_layout_1(bgl)
  let shader = backend.device.create_shader_module_wgsl(
    "@compute @workgroup_size(1) fn cs_main() {}",
  )
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "cs_main",
  )
  shader.release()
  backend.mesh3d_preprocess_reset_batch_sets_bgl = Some(bgl)
  backend.mesh3d_preprocess_reset_batch_sets_pipeline_layout = Some(layout)
  backend.mesh3d_preprocess_reset_batch_sets_pipeline = Some(pipeline)
  let texture = backend.device.create_texture_rgba8_2d(1U, 1U)
  backend.mesh3d_preprocess_depth_pyramid_dummy_view = Some(
    texture.create_view(),
  )
  backend.mesh3d_preprocess_depth_pyramid_dummy_texture = Some(texture)
  backend.mesh3d_preprocess_depth_pyramid_sampler = Some(
    backend.device.create_sampler_linear_clamp(),
  )
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_textures_num_kept_from_user() == 0UL &&
    after.hub_texture_views_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_compute_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: clearing stale meshlet views releases native handles" {
  let backend = GpuBackend::new()
  backend.prepare_meshlet_view_visibility_buffer(
    view_entity_bits=1UL,
    view_width=4,
    view_height=4,
    not_shadow_view=true,
  )
  backend.prepare_meshlet_view_visibility_buffer(
    view_entity_bits=2UL,
    view_width=4,
    view_height=4,
    not_shadow_view=true,
  )
  let before = backend.instance.generate_report()
  let buffers_before = before.hub_buffers_num_kept_from_user()
  let textures_before = before.hub_textures_num_kept_from_user()
  before.release()
  backend.clear_stale_meshlet_view_visibility_buffers([1UL])
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let released = backend.meshlet_view_visibility_buffers.length() == 1 &&
    after.hub_buffers_num_kept_from_user() < buffers_before &&
    after.hub_textures_num_kept_from_user() < textures_before
  after.release()
  backend.shutdown()
  debug_inspect(released, content="true")
}

///|
test "renderer: backend shutdown releases meshlet owners" {
  let backend = GpuBackend::new()
  let observer = backend.instance.add_ref()
  backend.prepare_meshlet_view_visibility_buffer(
    view_entity_bits=1UL,
    view_width=4,
    view_height=4,
    not_shadow_view=true,
  )
  backend.meshlet_vertex_positions_buf = Some(
    backend.device.create_buffer(
      size=16UL,
      usage=bu(@wgpu.BUFFER_USAGE_STORAGE),
    ),
  )
  let bgl = backend.device.create_bind_group_layout_empty()
  let layout = backend.device.create_pipeline_layout_1(bgl)
  let shader_source =
    #|@compute @workgroup_size(1) fn cs_main() {}
    #|struct VsOut { @builtin(position) position: vec4<f32> };
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) index: u32) -> VsOut {
    #|  var out: VsOut;
    #|  out.position = vec4<f32>(f32(index), 0.0, 0.0, 1.0);
    #|  return out;
    #|}
    #|@fragment fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let shader = backend.device.create_shader_module_wgsl(shader_source)
  backend.meshlet_clear_visibility_buffer_bgl = Some(bgl)
  backend.meshlet_clear_visibility_buffer_pipeline_layout = Some(layout)
  backend.meshlet_clear_visibility_buffer_pipeline = Some(
    backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "cs_main",
    ),
  )
  backend.meshlet_visibility_buffer_hardware_raster_pipeline = Some(
    backend.device.create_render_pipeline_rgba8(shader),
  )
  shader.release()
  let texture = backend.device.create_texture_rgba8_2d(1U, 1U)
  backend.meshlet_downsample_depth_dummy_view = Some(texture.create_view())
  backend.meshlet_downsample_depth_dummy_texture = Some(texture)
  backend.meshlet_downsample_depth_sampler = Some(
    backend.device.create_sampler_linear_clamp(),
  )
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_textures_num_kept_from_user() == 0UL &&
    after.hub_texture_views_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_compute_pipelines_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: backend shutdown releases motion vector owners" {
  let backend = GpuBackend::new()
  let observer = backend.instance.add_ref()
  let view_bgl = backend.device.create_bind_group_layout_empty()
  let empty_bgl = backend.device.create_bind_group_layout_empty()
  let mesh_bgl = backend.device.create_bind_group_layout_empty()
  let layout = create_pipeline_layout_4(
    backend.device,
    view_bgl,
    empty_bgl,
    mesh_bgl,
    mesh_bgl,
  )
  let shader_source =
    #|struct VsOut { @builtin(position) position: vec4<f32> };
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) index: u32) -> VsOut {
    #|  var out: VsOut;
    #|  out.position = vec4<f32>(f32(index), 0.0, 0.0, 1.0);
    #|  return out;
    #|}
    #|@fragment fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let shader = backend.device.create_shader_module_wgsl(shader_source)
  backend.mesh3d_motion_vector_pipeline = Some(
    backend.device.create_render_pipeline_rgba8(shader),
  )
  shader.release()
  backend.mesh3d_motion_vector_bgl_view = Some(view_bgl)
  backend.mesh3d_motion_vector_bgl_empty = Some(empty_bgl)
  backend.mesh3d_motion_vector_bgl_mesh = Some(mesh_bgl)
  backend.mesh3d_motion_vector_pipeline_layout = Some(layout)
  backend.mesh3d_motion_vector_view_bg = Some(
    mesh3d_create_empty_bind_group(
      backend, view_bgl, "test_motion_vector_view_bg",
    ),
  )
  backend.mesh3d_motion_vector_empty_bg = Some(
    mesh3d_create_empty_bind_group(
      backend, empty_bgl, "test_motion_vector_empty_bg",
    ),
  )
  let slot_buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_STORAGE),
  )
  let slot_bg = mesh3d_create_empty_bind_group(
    backend, mesh_bgl, "test_motion_vector_slot_bg",
  )
  backend.mesh3d_motion_vector_mesh_slots.push(GpuStorageSlot::{
    buffer: slot_buffer,
    bind_group: slot_bg,
  })
  backend.mesh3d_motion_vector_instance_mesh_buf = Some(
    backend.device.create_buffer(
      size=16UL,
      usage=bu(@wgpu.BUFFER_USAGE_STORAGE),
    ),
  )
  backend.mesh3d_motion_vector_instance_mesh_bg = Some(
    mesh3d_create_empty_bind_group(
      backend, mesh_bgl, "test_motion_vector_instance_bg",
    ),
  )
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_bind_groups_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: backend shutdown releases general postprocess owners" {
  let backend = GpuBackend::new()
  let observer = backend.instance.add_ref()
  let bgl = backend.device.create_bind_group_layout_empty()
  let layout = backend.device.create_pipeline_layout_1(bgl)
  let shader_source =
    #|struct VsOut { @builtin(position) position: vec4<f32> };
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) index: u32) -> VsOut {
    #|  var out: VsOut;
    #|  out.position = vec4<f32>(f32(index), 0.0, 0.0, 1.0);
    #|  return out;
    #|}
    #|@fragment fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let shader = backend.device.create_shader_module_wgsl(shader_source)
  let pipeline = backend.device.create_render_pipeline_rgba8(shader)
  shader.release()
  pipeline.add_ref_raw()
  backend.effect_stack_bgl = Some(bgl)
  backend.effect_stack_pipeline_layout = Some(layout)
  backend.effect_stack_pipeline = Some(pipeline)
  backend.effect_stack_sampler = Some(
    backend.device.create_sampler_linear_clamp(),
  )
  backend.effect_stack_chromatic_settings_buf = Some(
    backend.device.create_buffer(
      size=16UL,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
    ),
  )
  backend.custom_postprocess3d_pipeline_cache.push(CustomPostProcessPipelineCacheEntry::{
    shader_path: "test",
    fragment_entry: "fs_main",
    surface_format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    pipeline,
  })
  let prepared_buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
  )
  let prepared_bg = mesh3d_create_empty_bind_group(
    backend, bgl, "test_postprocess_prepared_bg",
  )
  backend.skybox_prepared_bind_groups.push(SkyboxPreparedBindGroupEntry::{
    id: 1,
    bind_group: prepared_bg,
    uniform_buffer: prepared_buffer,
  })
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_bind_groups_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: backend shutdown releases temporal exposure owners" {
  let backend = GpuBackend::new()
  let observer = backend.instance.add_ref()
  let bgl = backend.device.create_bind_group_layout_empty()
  let layout = backend.device.create_pipeline_layout_1(bgl)
  let shader_source =
    #|@compute @workgroup_size(1) fn cs_main() {}
    #|struct VsOut { @builtin(position) position: vec4<f32> };
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) index: u32) -> VsOut {
    #|  var out: VsOut;
    #|  out.position = vec4<f32>(f32(index), 0.0, 0.0, 1.0);
    #|  return out;
    #|}
    #|@fragment fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let shader = backend.device.create_shader_module_wgsl(shader_source)
  let render_pipeline = backend.device.create_render_pipeline_rgba8(shader)
  let compute_pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "cs_main",
  )
  shader.release()
  let history_texture_0 = backend.device.create_texture_rgba8_2d(1U, 1U)
  let history_view_0 = history_texture_0.create_view()
  let history_texture_1 = backend.device.create_texture_rgba8_2d(1U, 1U)
  let history_view_1 = history_texture_1.create_view()
  backend.taa_history_textures.push(GpuTaaHistoryTextures::{
    camera_key_hi: 1,
    camera_key_lo: 2,
    width: 1,
    height: 1,
    format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    texture_0: history_texture_0,
    view_0: history_view_0,
    texture_1: history_texture_1,
    view_1: history_view_1,
    next_write_index: 0,
  })
  backend.taa_pipeline_cache.push(GpuTaaPipelineCacheEntry::{
    format: tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    tonemap: false,
    reset: false,
    pipeline: render_pipeline,
  })
  backend.taa_bgl = Some(bgl)
  backend.taa_pipeline_layout = Some(layout)
  backend.bloom_sampler = Some(backend.device.create_sampler_linear_clamp())
  backend.bloom_settings_buf = Some(
    backend.device.create_buffer(
      size=16UL,
      usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
    ),
  )
  let bloom_texture = backend.device.create_texture_rgba8_2d(1U, 1U)
  backend.bloom_mip_views.push(bloom_texture.create_view())
  backend.bloom_mip_texture = Some(bloom_texture)
  let curve_texture = backend.device.create_texture_rgba8_2d(1U, 1U)
  backend.auto_exposure_curve_view = Some(curve_texture.create_view())
  backend.auto_exposure_curve_texture = Some(curve_texture)
  backend.auto_exposure_histogram_pipeline = Some(compute_pipeline)
  let state_buf = backend.device.create_buffer(
    size=4UL,
    usage=bu(@wgpu.BUFFER_USAGE_STORAGE),
  )
  backend.auto_exposure_view_states.push(GpuAutoExposureViewState::{
    key_hi: 1,
    key_lo: 2,
    state_buf,
  })
  backend.auto_exposure_active_state_buf = Some(state_buf)
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_textures_num_kept_from_user() == 0UL &&
    after.hub_texture_views_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_compute_pipelines_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: backend shutdown releases advanced pbr feature owners" {
  let backend = GpuBackend::new()
  let observer = backend.instance.add_ref()
  let bgl = backend.device.create_bind_group_layout_empty()
  let layout = backend.device.create_pipeline_layout_1(bgl)
  let shader_source =
    #|@compute @workgroup_size(1) fn cs_main() {}
    #|struct VsOut { @builtin(position) position: vec4<f32> };
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) index: u32) -> VsOut {
    #|  var out: VsOut;
    #|  out.position = vec4<f32>(f32(index), 0.0, 0.0, 1.0);
    #|  return out;
    #|}
    #|@fragment fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let shader = backend.device.create_shader_module_wgsl(shader_source)
  backend.mesh3d_ssao_pipeline_cache.push(GpuSsaoPipelineCacheEntry::{
    quality_level: 0,
    slice_count: 1,
    samples_per_slice_side: 1,
    temporal_jitter: false,
    pipeline: backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "cs_main",
    ),
  })
  backend.mesh3d_copy_deferred_lighting_id_pipeline = Some(
    backend.device.create_render_pipeline_rgba8(shader),
  )
  shader.release()
  backend.mesh3d_ssr_bind_group_layout = Some(bgl)
  backend.mesh3d_copy_deferred_lighting_id_pipeline_layout = Some(layout)
  backend.mesh3d_ssr_color_sampler = Some(
    backend.device.create_sampler_linear_clamp(),
  )
  let intermediate_texture = backend.device.create_texture_rgba8_2d(1U, 1U)
  backend.light_probe_environment_intermediate = Some(GpuLightProbeIntermediateTexture::{
    source_texture_id: 1,
    base_size: 1,
    mip_count: 1,
    texture: intermediate_texture,
    view: intermediate_texture.create_view(),
  })
  let deferred_texture = backend.device.create_texture_rgba8_2d(1U, 1U)
  backend.mesh3d_deferred_lighting_id_depth_texture = Some(GpuDeferredLightingIdDepthTexture::{
    width: 1,
    height: 1,
    texture: deferred_texture,
    view: deferred_texture.create_view(),
  })
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_textures_num_kept_from_user() == 0UL &&
    after.hub_texture_views_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_compute_pipelines_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: complete backend shutdown releases every report category" {
  let backend = GpuBackend::new()
  let observer = backend.instance.add_ref()
  ignore(ensure_default_texture(backend))
  ignore(
    backend.create_depth_prepass_target(1, 1, IMAGE_USAGE_RENDER_ATTACHMENT_BIT),
  )
  ignore(backend.create_mesh_rectangle(1.0F, 1.0F))
  backend.sampler_cache.set(
    "shutdown-test",
    backend.device.create_sampler_nearest_clamp(),
  )
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_textures_num_kept_from_user() == 0UL &&
    after.hub_texture_views_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_bind_groups_num_kept_from_user() == 0UL &&
    after.hub_compute_pipelines_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL &&
    after.hub_devices_num_kept_from_user() == 0UL &&
    after.hub_queues_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: motion vector prepass buffers match bevy struct sizes" {
  let pass_state = GpuPassState::{
    target_id: -1,
    target_layer: -1,
    secondary_target_id: -1,
    prepass_depth_texture_id: -1,
    prepass_normal_texture_id: -1,
    prepass_motion_vector_texture_id: -1,
    prepass_deferred_texture_id: -1,
    prepass_deferred_lighting_pass_id_texture_id: -1,
    view_depth_texture_id: 17,
    view_depth_view: None,
    screen_space_reflections: false,
    msaa_sample_count: 1,
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
    world_from_clip: gpu_clip_matrix_identity(),
    world_from_view: gpu_clip_matrix_identity(),
    view_from_world: gpu_clip_matrix_identity(),
    clip_from_view: gpu_clip_matrix_identity(),
    view_from_clip: gpu_clip_matrix_identity(),
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
    environment_diffuse_texture_ids: [],
    environment_specular_texture_ids: [],
    irradiance_volume_texture_ids: [],
    mesh3d_light_probes_uniform_bytes: None,
    light_probes_uniform_offset: 0U,
    point_shadow_near: 0.0F,
    directional_shadow_texture_id: -1,
    directional_shadow_enabled: 0.0F,
    directional_shadow_depth_bias: 0.0F,
    directional_shadow_normal_bias: 0.0F,
    directional_shadow_soft_size: 0.0F,
    directional_shadow_cascade_count: 0,
    directional_shadow_cascade_overlap: 0.0F,
    directional_shadow_cascade_data: [],
    mesh3d_lights_uniform_bytes: None,
    tonemap_in_shader: false,
    tonemapping_mode: 0,
    tonemapping_agx_lut_texture_id: -1,
    tonemapping_tony_lut_texture_id: -1,
    tonemapping_blender_lut_texture_id: -1,
    pbr_blue_noise_texture_id: -1,
    pbr_area_light_luts_texture_id: -1,
    pbr_dfg_lut_texture_id: -1,
    deband_dither_enabled: false,
  }
  let mesh_bytes = mesh3d_motion_vector_mesh_bytes(
    None,
    None,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    -1,
    0U,
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
test "renderer: pass state records active view depth texture identity" {
  let pass_state = GpuPassState::{
    target_id: 3,
    target_layer: -1,
    secondary_target_id: -1,
    prepass_depth_texture_id: 11,
    prepass_normal_texture_id: -1,
    prepass_motion_vector_texture_id: -1,
    prepass_deferred_texture_id: -1,
    prepass_deferred_lighting_pass_id_texture_id: -1,
    view_depth_texture_id: 29,
    view_depth_view: None,
    screen_space_reflections: false,
    msaa_sample_count: 1,
    width_logical: 128.0F,
    height_logical: 128.0F,
    is_3d: true,
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
    clip_from_world: gpu_clip_matrix_identity(),
    unjittered_clip_from_world: gpu_clip_matrix_identity(),
    world_from_clip: gpu_clip_matrix_identity(),
    world_from_view: gpu_clip_matrix_identity(),
    view_from_world: gpu_clip_matrix_identity(),
    clip_from_view: gpu_clip_matrix_identity(),
    view_from_clip: gpu_clip_matrix_identity(),
    previous_clip_from_world: gpu_clip_matrix_identity(),
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
    environment_diffuse_texture_ids: [],
    environment_specular_texture_ids: [],
    irradiance_volume_texture_ids: [],
    mesh3d_light_probes_uniform_bytes: None,
    light_probes_uniform_offset: 0U,
    point_shadow_near: 0.0F,
    directional_shadow_texture_id: -1,
    directional_shadow_enabled: 0.0F,
    directional_shadow_depth_bias: 0.0F,
    directional_shadow_normal_bias: 0.0F,
    directional_shadow_soft_size: 0.0F,
    directional_shadow_cascade_count: 0,
    directional_shadow_cascade_overlap: 0.0F,
    directional_shadow_cascade_data: [],
    mesh3d_lights_uniform_bytes: None,
    tonemap_in_shader: false,
    tonemapping_mode: 0,
    tonemapping_agx_lut_texture_id: -1,
    tonemapping_tony_lut_texture_id: -1,
    tonemapping_blender_lut_texture_id: -1,
    pbr_blue_noise_texture_id: -1,
    pbr_area_light_luts_texture_id: -1,
    pbr_dfg_lut_texture_id: -1,
    deband_dither_enabled: false,
  }
  inspect(pass_state.view_depth_texture_id(), content="29")
}

///|
test "renderer: motion-vector-only prepass uses Bevy sparse color target count" {
  inspect(
    render_pass_sparse_prepass_attachment_count(
      PASS_KIND_BASE_MOTION_VECTOR,
      false,
      true,
      false,
      false,
    ),
    content="2",
  )
  inspect(
    render_pass_sparse_prepass_attachment_count(
      PASS_KIND_BASE_MOTION_VECTOR,
      false,
      false,
      false,
      false,
    ),
    content="0",
  )
  inspect(
    render_pass_sparse_prepass_attachment_count(0, true, false, false, false),
    content="0",
  )
  inspect(
    render_pass_sparse_prepass_attachment_count(0, false, false, true, false),
    content="4",
  )
}

///|
test "renderer: large mesh3d upload switches to u32 index buffers" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices : Array[Float] = []
  let indices : Array[Int] = []
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
    indices.push(i)
  }
  let mesh_id = backend.create_mesh3d_xyznuvrgba_indexed(vertices, indices, 0)
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
test "renderer: mesh3d allocator metadata exposes packed slab ranges" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices : Array[Float] = [
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F,
    0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 1.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F,
  ]
  let indices : Array[Int] = [0, 1, 2]
  ignore(indices)
  let first_mesh_id = backend.create_mesh3d_xyznuvrgba(vertices, 0)
  let second_mesh_id = backend.create_mesh3d_xyznuvrgba(vertices, 0)
  let ok = first_mesh_id > 0 &&
    second_mesh_id > first_mesh_id &&
    backend.meshes.length() == 2 &&
    backend.meshes[0].vertex_start == 0U &&
    backend.meshes[0].index_start == 0U &&
    backend.meshes[1].vertex_start == 3U &&
    backend.meshes[1].index_start == 0U &&
    backend.meshes[0].vertex_slab_id == backend.meshes[1].vertex_slab_id &&
    backend.meshes[0].index_slab_id == -1 &&
    backend.meshes[1].index_slab_id == -1 &&
    backend.meshes[1].vertex_count == 3U &&
    backend.meshes[1].index_count == 0U
  debug_inspect(ok, content="true")
}

///|
test "renderer: indexed mesh3d allocator metadata exposes index slab ranges" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices : Array[Float] = [
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F,
    0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 1.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F,
  ]
  let indices : Array[Int] = [0, 1, 2]
  let first_mesh_id = backend.create_mesh3d_xyznuvrgba_indexed(
    vertices, indices, 0,
  )
  let second_mesh_id = backend.create_mesh3d_xyznuvrgba_indexed(
    vertices, indices, 0,
  )
  let ok = first_mesh_id > 0 &&
    second_mesh_id > first_mesh_id &&
    backend.meshes.length() == 2 &&
    backend.meshes[0].vertex_start == 0U &&
    backend.meshes[0].index_start == 0U &&
    backend.meshes[1].vertex_start == 3U &&
    backend.meshes[1].index_start == 4U &&
    backend.meshes[0].vertex_slab_id == backend.meshes[1].vertex_slab_id &&
    backend.meshes[0].index_slab_id == backend.meshes[1].index_slab_id &&
    backend.meshes[1].vertex_count == 3U &&
    backend.meshes[1].index_count == 3U
  debug_inspect(ok, content="true")
}

///|
test "renderer: prepared render assets replace legacy buffers with allocator slabs" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let mesh_vertex_layout = @mesh.MeshVertexBufferLayout::new(
    attribute_ids=[@mesh.MeshVertexAttribute::position().id()],
    layout=@mesh.VertexBufferLayout::new(
      array_stride=12,
      step_mode=@mesh.MeshVertexStepMode::Vertex,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
      ],
    ),
  )
  let vertex_bytes = Bytes::from_array(Array::make(36, b'\x00'))
  let indices : Array[Int] = [0, 1, 2]
  let first_mesh_id = backend.create_mesh2d_vertex_buffer(
    vertex_bytes, 3, indices, 0, mesh_vertex_layout,
  )
  let second_mesh_id = backend.create_mesh2d_vertex_buffer(
    vertex_bytes, 3, indices, 0, mesh_vertex_layout,
  )
  let allocator = @render_mesh.MeshAllocator::MeshAllocator()
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=3,
    indexed=true,
    index_count=3,
    index_format=@render_mesh.RenderMeshIndexFormat::Uint16,
  )
  let first_plan = allocator.allocate_render_mesh(101, render_mesh, 12)
  let first_vertex_slice = allocator.mesh_vertex_slice(101).unwrap()
  let first_index_slice = allocator.mesh_index_slice(101).unwrap()
  let first_prepared = backend.prepare_mesh3d_allocator_asset(
    first_mesh_id,
    first_plan,
    vertex_bytes,
    3,
    indices,
    false,
    0,
    mesh_vertex_layout,
    first_vertex_slice.start(),
    first_index_slice.start(),
    extra_buffer_usages=@wgpu.BUFFER_USAGE_STORAGE,
  )
  let second_plan = allocator.allocate_render_mesh(102, render_mesh, 12)
  let second_vertex_slice = allocator.mesh_vertex_slice(102).unwrap()
  let second_index_slice = allocator.mesh_index_slice(102).unwrap()
  let second_prepared = backend.prepare_mesh3d_allocator_asset(
    second_mesh_id,
    second_plan,
    vertex_bytes,
    3,
    indices,
    false,
    0,
    mesh_vertex_layout,
    second_vertex_slice.start(),
    second_index_slice.start(),
    extra_buffer_usages=@wgpu.BUFFER_USAGE_STORAGE,
  )
  let first = backend.meshes[0]
  let second = backend.meshes[1]
  let ok = first_prepared &&
    second_prepared &&
    first.vertex_start == 0U &&
    first.index_start == 0U &&
    second.vertex_start == 3U &&
    second.index_start == 4U &&
    first.vertex_slab_id == second.vertex_slab_id &&
    first.index_slab_id == second.index_slab_id &&
    first.vertex_stride_bytes == 12UL &&
    first.index_stride_bytes == 2UL &&
    !first.uses_u32_indices &&
    (first.vertex_buf.usage_u64().raw & @wgpu.BUFFER_USAGE_STORAGE) != 0UL &&
    (first.index_buf.usage_u64().raw & @wgpu.BUFFER_USAGE_STORAGE) != 0UL &&
    backend.mesh_allocator_buffers.length() == 2
  debug_inspect(ok, content="true")
}

///|
test "renderer: wide wireframe bind groups prepare before surface frame activation" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let mesh_vertex_layout = @mesh.MeshVertexBufferLayout::new(
    attribute_ids=[@mesh.MeshVertexAttribute::position().id()],
    layout=@mesh.VertexBufferLayout::new(
      array_stride=12,
      step_mode=@mesh.MeshVertexStepMode::Vertex,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=@mesh.MeshVertexFormat::Float32x3,
          shader_location=0,
        ),
      ],
    ),
  )
  let vertex_bytes = Bytes::from_array(Array::make(36, b'\x00'))
  let indices : Array[Int] = [0, 1, 2]
  let mesh_id = backend.create_mesh2d_vertex_buffer(
    vertex_bytes, 3, indices, 0, mesh_vertex_layout,
  )
  let allocator = @render_mesh.MeshAllocator::MeshAllocator()
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=3,
    indexed=true,
    index_count=3,
    index_format=@render_mesh.RenderMeshIndexFormat::Uint32,
  )
  let plan = allocator.allocate_render_mesh(101, render_mesh, 12)
  let prepared = backend.prepare_mesh3d_allocator_asset(
    mesh_id,
    plan,
    vertex_bytes,
    3,
    indices,
    true,
    0,
    mesh_vertex_layout,
    allocator.mesh_vertex_slice(101).unwrap().start(),
    allocator.mesh_index_slice(101).unwrap().start(),
    extra_buffer_usages=@wgpu.BUFFER_USAGE_STORAGE,
  )
  let wide_prepared = backend.prepare_wireframe_3d_wide_bind_groups([mesh_id], [
    0U, 3U, 0U,
  ])
  debug_inspect(backend.frame is None, content="true")
  debug_inspect(prepared, content="true")
  debug_inspect(wide_prepared, content="true")
  debug_inspect(backend.wireframe_3d_wide_bind_groups.length(), content="1")
}

///|
test "renderer: deleting mesh3d frees allocator slabs after last resident mesh" {
  let backend = GpuBackend::new()
  backend.meshes.clear()
  let vertices : Array[Float] = [
    0.0F, 0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 1.0F,
    0.0F, 0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F, 0.0F, 1.0F,
    0.0F, 0.0F, 0.0F, 1.0F, 0.0F, 0.0F, 1.0F, 1.0F, 1.0F, 1.0F,
  ]
  let first_mesh_id = backend.create_mesh3d_xyznuvrgba(vertices, 0)
  let second_mesh_id = backend.create_mesh3d_xyznuvrgba(vertices, 0)
  let initial_ok = backend.meshes.length() == 2 &&
    backend.mesh_allocator.slab_count() == 1 &&
    backend.mesh_allocator_buffers.length() == 1
  let first_delete_ok = backend.delete_mesh(first_mesh_id) &&
    backend.meshes.length() == 1 &&
    backend.mesh_allocator.slab_count() == 1 &&
    backend.mesh_allocator_buffers.length() == 1
  let second_delete_ok = backend.delete_mesh(second_mesh_id) &&
    backend.meshes.length() == 0 &&
    backend.mesh_allocator.slab_count() == 0 &&
    backend.mesh_allocator_buffers.length() == 0
  debug_inspect(
    initial_ok && first_delete_ok && second_delete_ok,
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
  debug_inspect(ok, content="true")
}

///|
test "renderer: mesh3d normal map fallback texture is flat normal blue" {
  let backend = GpuBackend::new()
  render_context_set_backend_for_test(Some(backend))
  let fallback_texture = ensure_normal_map_fallback_texture(backend)
  debug_inspect(
    fallback_texture.format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
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
  render_context_set_backend_for_test(None)
}

///|
test "renderer: replacing a cube texture keeps native handle counts bounded" {
  let backend = GpuBackend::new()
  let level = Bytes::makei(24, _ => (255).to_byte())
  let texture_id = backend.create_texture_cube_with_format(
    1,
    1,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    [level],
    false,
  )
  let before = backend.instance.generate_report()
  let kept_textures = before.hub_textures_num_kept_from_user()
  let kept_views = before.hub_texture_views_num_kept_from_user()
  let kept_samplers = before.hub_samplers_num_kept_from_user()
  let kept_bind_groups = before.hub_bind_groups_num_kept_from_user()
  before.release()
  let replaced_id = backend.create_texture_cube_with_format(
    1,
    1,
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    [level],
    false,
    replace_texture_id=texture_id,
  )
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let bounded = replaced_id == texture_id &&
    after.hub_textures_num_kept_from_user() == kept_textures &&
    after.hub_texture_views_num_kept_from_user() == kept_views &&
    after.hub_samplers_num_kept_from_user() == kept_samplers &&
    after.hub_bind_groups_num_kept_from_user() == kept_bind_groups
  after.release()
  debug_inspect(bounded, content="true")
}

///|
test "renderer: replacing SSAO resources keeps native handle counts bounded" {
  let backend = GpuBackend::new(assets_base="assets")
  let depth_format = tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT)
  backend.replace_mesh3d_ssao_resources(8, 8, depth_format, 0.25F)
  let before = backend.instance.generate_report()
  let kept_buffers = before.hub_buffers_num_kept_from_user()
  let kept_textures = before.hub_textures_num_kept_from_user()
  let kept_views = before.hub_texture_views_num_kept_from_user()
  before.release()
  backend.replace_mesh3d_ssao_resources(16, 16, depth_format, 0.5F)
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let bounded = after.hub_buffers_num_kept_from_user() == kept_buffers &&
    after.hub_textures_num_kept_from_user() == kept_textures &&
    after.hub_texture_views_num_kept_from_user() == kept_views
  after.release()
  debug_inspect(bounded, content="true")
}

///|
test "renderer: releasing atmosphere resources returns native handles" {
  let backend = GpuBackend::new()
  let before = backend.instance.generate_report()
  let kept_buffers = before.hub_buffers_num_kept_from_user()
  let kept_textures = before.hub_textures_num_kept_from_user()
  let kept_views = before.hub_texture_views_num_kept_from_user()
  let kept_samplers = before.hub_samplers_num_kept_from_user()
  let kept_bgls = before.hub_bind_group_layouts_num_kept_from_user()
  let kept_layouts = before.hub_pipeline_layouts_num_kept_from_user()
  let kept_compute = before.hub_compute_pipelines_num_kept_from_user()
  let kept_render = before.hub_render_pipelines_num_kept_from_user()
  before.release()
  let texture = backend.device.create_texture_rgba8_2d(1U, 1U)
  texture.add_ref_raw()
  texture.add_ref_raw()
  texture.add_ref_raw()
  let view = texture.create_view()
  view.add_ref_raw()
  view.add_ref_raw()
  view.add_ref_raw()
  let sampler = backend.device.create_sampler_linear_clamp()
  let buffer = backend.device.create_buffer(
    size=4UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
  )
  buffer.add_ref_raw()
  buffer.add_ref_raw()
  let bgl = backend.device.create_bind_group_layout_empty()
  for _ in 0..<6 {
    bgl.add_ref_raw()
  }
  let layout = backend.device.create_pipeline_layout_1(bgl)
  for _ in 0..<5 {
    layout.add_ref_raw()
  }
  let shader_source =
    #|@compute @workgroup_size(1)
    #|fn cs_main() {}
    #|
    #|struct VsOut { @builtin(position) position: vec4<f32> };
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) index: u32) -> VsOut {
    #|  var out: VsOut;
    #|  out.position = vec4<f32>(f32(index), 0.0, 0.0, 1.0);
    #|  return out;
    #|}
    #|@fragment
    #|fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let shader = backend.device.create_shader_module_wgsl(shader_source)
  let compute = backend.device.create_compute_pipeline_with_layout_entry(
    layout, shader, "cs_main",
  )
  for _ in 0..<4 {
    compute.add_ref_raw()
  }
  let render = backend.device.create_render_pipeline_rgba8(shader)
  render.add_ref_raw()
  shader.release()
  let resources = GpuAtmosphereResources::{
    transmittance_texture: texture,
    transmittance_view: view,
    multiscattering_texture: texture,
    multiscattering_view: view,
    sky_view_texture: texture,
    sky_view_view: view,
    aerial_view_texture: texture,
    aerial_view_view: view,
    sampler,
    atmosphere_buffer: buffer,
    settings_buffer: buffer,
    transform_buffer: buffer,
    transmittance_lut_bgl: bgl,
    transmittance_lut_pipeline_layout: layout,
    transmittance_lut_pipeline: compute,
    multiscattering_lut_bgl: bgl,
    multiscattering_lut_pipeline_layout: layout,
    multiscattering_lut_pipeline: compute,
    sky_view_lut_bgl: bgl,
    sky_view_lut_pipeline_layout: layout,
    sky_view_lut_pipeline: compute,
    aerial_view_lut_bgl: bgl,
    aerial_view_lut_pipeline_layout: layout,
    aerial_view_lut_pipeline: compute,
    environment_bgl: bgl,
    environment_pipeline: compute,
    render_sky_bgl: bgl,
    render_sky_pipeline_layout: layout,
    render_sky_pipeline: render,
    render_sky_msaa_bgl: bgl,
    render_sky_msaa_pipeline_layout: layout,
    render_sky_msaa_pipeline: Some(render),
    render_sky_msaa_sample_count: 4,
    transmittance_width: 1,
    transmittance_height: 1,
    multiscattering_width: 1,
    multiscattering_height: 1,
    sky_view_width: 1,
    sky_view_height: 1,
    aerial_view_width: 1,
    aerial_view_height: 1,
    aerial_view_depth: 1,
    revision: 1,
  }
  resources.release()
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == kept_buffers &&
    after.hub_textures_num_kept_from_user() == kept_textures &&
    after.hub_texture_views_num_kept_from_user() == kept_views &&
    after.hub_samplers_num_kept_from_user() == kept_samplers &&
    after.hub_bind_group_layouts_num_kept_from_user() == kept_bgls &&
    after.hub_pipeline_layouts_num_kept_from_user() == kept_layouts &&
    after.hub_compute_pipelines_num_kept_from_user() == kept_compute &&
    after.hub_render_pipelines_num_kept_from_user() == kept_render
  after.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: replacing scattering medium keeps native handles bounded" {
  let backend = GpuBackend::new()
  backend.mesh3d_prepare_scattering_medium_resources(
    density_width=1,
    density_height=1,
    density_bytes=Bytes::make(16, (0).to_byte()),
    scattering_width=1,
    scattering_height=1,
    scattering_bytes=Bytes::make(16, (0).to_byte()),
  )
  let before = backend.instance.generate_report()
  let kept_textures = before.hub_textures_num_kept_from_user()
  let kept_views = before.hub_texture_views_num_kept_from_user()
  let kept_samplers = before.hub_samplers_num_kept_from_user()
  before.release()
  backend.mesh3d_prepare_scattering_medium_resources(
    density_width=2,
    density_height=1,
    density_bytes=Bytes::make(32, (0).to_byte()),
    scattering_width=2,
    scattering_height=1,
    scattering_bytes=Bytes::make(32, (0).to_byte()),
  )
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let bounded = after.hub_textures_num_kept_from_user() == kept_textures &&
    after.hub_texture_views_num_kept_from_user() == kept_views &&
    after.hub_samplers_num_kept_from_user() == kept_samplers
  after.release()
  debug_inspect(bounded, content="true")
}

///|
test "renderer: backend shutdown is idempotent" {
  let backend = GpuBackend::new()
  let observer = backend.instance.add_ref()
  backend.shutdown()
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = backend.shutdown_complete &&
    after.hub_devices_num_kept_from_user() == 0UL &&
    after.hub_queues_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: replacing global backend shuts down previous owner" {
  render_context_set_backend_for_test(None)
  let first = GpuBackend::new()
  let second = GpuBackend::new()
  render_context_set_backend_for_test(Some(first))
  render_context_set_backend_for_test(Some(second))
  let first_released = first.shutdown_complete
  render_context_set_backend_for_test(None)
  debug_inspect(first_released && second.shutdown_complete, content="true")
}

///|
test "renderer: backend initialization rolls back acquired native handles" {
  let mut rolled_back = true
  for fail_stage in 1..<=3 {
    let instance = @wgpu.Instance::create()
    let observer = instance.add_ref()
    let failed = try {
      ignore(gpu_backend_new_from_instance(instance, "", fail_stage~))
      false
    } catch {
      _ => true
    }
    observer.process_events()
    let after = observer.generate_report()
    rolled_back = rolled_back &&
      failed &&
      after.hub_devices_num_kept_from_user() == 0UL &&
      after.hub_queues_num_kept_from_user() == 0UL
    after.release()
    observer.release()
  }
  debug_inspect(rolled_back, content="true")
}

///|
test "renderer: backend shutdown releases 2d and ui resource owners" {
  let backend = GpuBackend::new(assets_base="assets")
  let observer = backend.instance.add_ref()
  ensure_sprite_resources(backend)
  ensure_ui_resources(backend)
  ensure_ui_shadow_resources(backend)
  ensure_ui_slice_resources(backend)
  ensure_mesh2d_resources(backend)
  let shader_source =
    #|struct VsOut { @builtin(position) position: vec4<f32> };
    #|@vertex
    #|fn vs_main(@builtin(vertex_index) index: u32) -> VsOut {
    #|  var out: VsOut;
    #|  out.position = vec4<f32>(f32(index), 0.0, 0.0, 1.0);
    #|  return out;
    #|}
    #|@fragment
    #|fn fs_main() -> @location(0) vec4<f32> {
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let shader = backend.device.create_shader_module_wgsl(shader_source)
  backend.ui_pipeline = Some(
    backend.device.create_render_pipeline_rgba8(shader),
  )
  shader.release()
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_textures_num_kept_from_user() == 0UL &&
    after.hub_texture_views_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_bind_groups_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: backend shutdown releases mesh3d pbr resource owners" {
  let backend = GpuBackend::new(assets_base="assets")
  let observer = backend.instance.add_ref()
  ensure_mesh3d_pipeline_layout_resources(backend)
  ensure_mesh3d_shadow_pipeline_layout_resources(backend)
  backend.shutdown()
  observer.process_events()
  let after = observer.generate_report()
  let released = after.hub_buffers_num_kept_from_user() == 0UL &&
    after.hub_samplers_num_kept_from_user() == 0UL &&
    after.hub_bind_group_layouts_num_kept_from_user() == 0UL &&
    after.hub_pipeline_layouts_num_kept_from_user() == 0UL &&
    after.hub_bind_groups_num_kept_from_user() == 0UL &&
    after.hub_render_pipelines_num_kept_from_user() == 0UL
  after.release()
  observer.release()
  debug_inspect(released, content="true")
}

///|
test "renderer: clearing mesh3d frame caches preserves transient owners" {
  let backend = GpuBackend::new()
  let layout = mesh3d_create_empty_bind_group_layout(
    backend, "test_mesh3d_frame_uniform_layout",
  )
  let pass_bind_group = mesh3d_create_empty_bind_group(
    backend, layout, "test_mesh3d_frame_uniform_bind_group",
  )
  let frame_bind_group = mesh3d_create_empty_bind_group(
    backend, layout, "test_mesh3d_frame_view_bind_group",
  )
  let binding_arrays_bind_group = mesh3d_create_empty_bind_group(
    backend, layout, "test_mesh3d_frame_binding_arrays_bind_group",
  )
  let view_buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
  )
  let lights_buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM),
  )
  backend.mesh3d_pass_uniform_states.push(Mesh3dPassUniformState::{
    frame_count: 0U,
    camera_key_hi: 0,
    camera_key_lo: 0,
    pass_kind: 0,
    view_buffer,
    lights_buffer,
    shadow_view_bind_group: Some(pass_bind_group),
  })
  backend.mesh3d_frame_view_bg_cache.push(Mesh3dFrameViewBindGroupCacheEntry::{
    material_pipeline_id: 0UL,
    view_layout_key_bits: 0U,
    tonemap_in_shader: false,
    frame_count: 0U,
    camera_key_hi: 0,
    camera_key_lo: 0,
    pass_kind: 0,
    transmission_source_texture_id: -1,
    point_shadow_texture_id: -1,
    directional_shadow_texture_id: -1,
    environment_diffuse_texture_id: -1,
    environment_specular_texture_id: -1,
    environment_texture_ids_signature: "",
    irradiance_volume_texture_ids_signature: "",
    prepass_depth_texture_id: -1,
    prepass_normal_texture_id: -1,
    prepass_motion_vector_texture_id: -1,
    prepass_deferred_texture_id: -1,
    tonemapping_lut_texture_id: -1,
    pbr_blue_noise_texture_id: -1,
    pbr_area_light_luts_texture_id: -1,
    pbr_dfg_lut_texture_id: -1,
    atmosphere_resource_revision: 0,
    ssao_resource_revision: 0,
    clustered_decals_revision: 0,
    bind_group: frame_bind_group,
    main_offsets: [],
    binding_arrays_bind_group,
  })
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let before = backend.instance.generate_report()
  let before_buffers = before.hub_buffers_num_kept_from_user()
  let before_bind_groups = before.hub_bind_groups_num_kept_from_user()
  before.release()
  mesh3d_pass_uniform_states_clear(backend)
  mesh3d_frame_view_bind_group_cache_clear(backend)
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let transient_owners_preserved = after.hub_buffers_num_kept_from_user() ==
    before_buffers &&
    after.hub_bind_groups_num_kept_from_user() == before_bind_groups
  after.release()
  if transient_owners_preserved {
    pass_bind_group.release()
    frame_bind_group.release()
    binding_arrays_bind_group.release()
    view_buffer.release()
    lights_buffer.release()
  }
  layout.release()
  backend.shutdown()
  debug_inspect(transient_owners_preserved, content="true")
}

///|
test "renderer: replacing mesh3d cluster buffers keeps handles bounded" {
  let backend = GpuBackend::new()
  ensure_mesh3d_pipeline_layout_resources(backend)
  let usage = bu(@wgpu.BUFFER_USAGE_STORAGE)
  let first_a = backend.device.create_buffer(size=16UL, usage~)
  let first_b = backend.device.create_buffer(size=16UL, usage~)
  let first_c = backend.device.create_buffer(size=16UL, usage~)
  backend.use_mesh3d_cluster_buffers(
    first_a, 16UL, first_b, 16UL, first_c, 16UL,
  )
  first_a.release()
  first_b.release()
  first_c.release()
  let before = backend.instance.generate_report()
  let kept_buffers = before.hub_buffers_num_kept_from_user()
  before.release()
  let second_a = backend.device.create_buffer(size=32UL, usage~)
  let second_b = backend.device.create_buffer(size=32UL, usage~)
  let second_c = backend.device.create_buffer(size=32UL, usage~)
  backend.use_mesh3d_cluster_buffers(
    second_a, 32UL, second_b, 32UL, second_c, 32UL,
  )
  second_a.release()
  second_b.release()
  second_c.release()
  backend.instance.process_events()
  ignore(backend.device.poll(wait=true))
  let after = backend.instance.generate_report()
  let bounded = after.hub_buffers_num_kept_from_user() == kept_buffers
  after.release()
  backend.shutdown()
  debug_inspect(bounded, content="true")
}

///|
test "renderer: mesh3d runtime flags infer two-component normal map format" {
  let backend = GpuBackend::new()
  let fallback_texture = ensure_normal_map_fallback_texture(backend)
  let two_component_texture = GpuTextureInfo::{
    ..fallback_texture,
    id: 42,
    format: tf(@wgpu.TEXTURE_FORMAT_RG8_UNORM),
  }
  let flags = mesh3d_runtime_material_flags(0U, 42, two_component_texture)
  debug_inspect((flags & (1U << 6)) != 0U, content="true")
}

///|
test "renderer: mesh uniform stores caller supplied mesh flags" {
  let flags = 0xA000_FFFFU
  let words = mesh3d_mesh_uniform_words(
    None,
    None,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0xFFFF_FFFFU,
    flags,
    0,
    -1,
    0,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0U,
    0U,
  )
  debug_inspect(words[33], content="2684420095")
}

///|
test "renderer: mesh uniform preserves caller supplied affine transform" {
  let world_from_local : Array[Float] = [
    -2.0F,
    0.5F,
    0.0F,
    4.0F,
    0.0F,
    3.0F,
    0.25F,
    5.0F,
    0.0F,
    0.0F,
    4.0F,
    6.0F,
  ]
  let previous_world_from_local : Array[Float] = [
    -1.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    2.0F,
    0.0F,
    2.0F,
    0.0F,
    0.0F,
    3.0F,
    3.0F,
  ]
  let flags = 0xA000_FFFFU
  let words = mesh3d_mesh_uniform_words(
    Some(world_from_local),
    Some(previous_world_from_local),
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0xFFFF_FFFFU,
    flags,
    0,
    -1,
    0,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0U,
    0U,
  )
  debug_inspect(words[0], content="3221225472")
  debug_inspect(words[3], content="1082130432")
  debug_inspect(words[12], content="3212836864")
  debug_inspect(words[15], content="1065353216")
  debug_inspect(words[24], content="3204448256")
  debug_inspect(words[33], content="2684420095")
}

///|
test "renderer: mesh uniform packs lightmap uv rect and slot" {
  let words = mesh3d_mesh_uniform_words(
    None,
    None,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0xFFFF_FFFFU,
    0U,
    0,
    7,
    0,
    0.25F,
    0.5F,
    0.75F,
    1.0F,
    13U,
    0U,
  )
  debug_inspect(words[34], content="2147500032")
  debug_inspect(words[35], content="4294950911")
  debug_inspect(words[36], content="13")
  debug_inspect(words[38], content="0")
}

///|
test "renderer: mesh uniform marks absent lightmap with max slot" {
  let words = mesh3d_mesh_uniform_words(
    None,
    None,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0xFFFF_FFFFU,
    0U,
    0,
    -1,
    0,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0U,
    0U,
  )
  debug_inspect(words[34], content="0")
  debug_inspect(words[35], content="0")
  debug_inspect(words[38], content="4294901760")
}

///|
test "renderer: mesh uniform packs material and lightmap bind group slots" {
  let no_lightmap_words = mesh3d_mesh_uniform_words(
    None,
    None,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0xFFFF_FFFFU,
    0U,
    7,
    -1,
    0,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0U,
    0U,
  )
  let lightmapped_words = mesh3d_mesh_uniform_words(
    None,
    None,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    1.0F,
    1.0F,
    0xFFFF_FFFFU,
    0U,
    7,
    9,
    3,
    0.0F,
    0.0F,
    0.0F,
    0.0F,
    0U,
    0U,
  )
  debug_inspect(no_lightmap_words[38], content="4294901767")
  debug_inspect(lightmapped_words[38], content="196615")
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
test "renderer: material descriptor exact layout preserves empty prepass group" {
  let view_layout = @render_resource.BindGroupLayoutDescriptor::new("view", [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      @wgpu.SHADER_STAGE_VERTEX.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        0UL,
      ),
    ),
  ])
  let empty_layout = @render_resource.BindGroupLayoutDescriptor::new(
    "prepass_empty",
    [],
  )
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor().with_layout([
      view_layout, empty_layout,
    ],
  )
  debug_inspect(
    mesh3d_descriptor_bind_group_layout_exact(Some(descriptor), 1) is Some(_),
    content="true",
  )
  debug_inspect(
    mesh3d_descriptor_bind_group_layout(Some(descriptor), 1) is None,
    content="true",
  )
}

///|
test "renderer: default mesh3d draw descriptor matches storage plus skin layout" {
  let descriptor = mesh3d_default_draw_bind_group_layout_descriptor()
  inspect(descriptor.label(), content="mesh_layout")
  inspect(descriptor.entries().length(), content="2")
  let draw_entry = descriptor.entries()[0]
  inspect(draw_entry.binding(), content="0")
  match draw_entry.kind() {
    @render_resource.BindingType::BufferBinding(
      @render_resource.BufferBindingType::Storage(true),
      false,
      size
    ) => inspect(size, content="176")
    _ => fail("expected draw storage buffer binding")
  }
  let skin_entry = descriptor.entries()[1]
  inspect(skin_entry.binding(), content="1")
  match skin_entry.kind() {
    @render_resource.BindingType::BufferBinding(
      @render_resource.BufferBindingType::Storage(true),
      false,
      size
    ) => inspect(size, content="16384")
    _ => fail("expected skin storage buffer binding")
  }
}

///|
test "renderer: lightmapped mesh3d draw descriptor matches Bevy mesh layout" {
  let descriptor = mesh3d_default_draw_bind_group_layout_descriptor(
    lightmapped=true,
  )
  inspect(descriptor.label(), content="lightmapped_mesh_layout")
  inspect(descriptor.entries().length(), content="4")
  debug_inspect(
    wbtest_bind_group_layout_has_binding(descriptor, 4),
    content="true",
  )
  debug_inspect(
    wbtest_bind_group_layout_has_binding(descriptor, 5),
    content="true",
  )
  match descriptor.entries()[2].kind() {
    @render_resource.BindingType::TextureBinding(
      @render_resource.TextureSampleType::Float(true),
      @render_resource.TextureViewDimension::D2,
      false
    ) => ()
    _ => fail("expected lightmap texture binding")
  }
  match descriptor.entries()[3].kind() {
    @render_resource.BindingType::SamplerBinding(
      @render_resource.SamplerBindingType::Filtering
    ) => ()
    _ => fail("expected lightmap sampler binding")
  }
}

///|
test "renderer: lightmapped default forward shader defines LIGHTMAP" {
  let defines = mesh3d_forward_shader_defines(
    false,
    false,
    0,
    false,
    0,
    lightmapped=true,
  )
  debug_inspect(defines.get("LIGHTMAP"), content="Some(true)")
}

///|
test "renderer: mesh3d draw dynamic offsets follow morph binding order" {
  let descriptor = @render_resource.BindGroupLayoutDescriptor::new("mesh", [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      @wgpu.SHADER_STAGE_VERTEX.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(true),
        false,
        176UL,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      2,
      @wgpu.SHADER_STAGE_VERTEX.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        true,
        256UL,
      ),
    ),
    @render_resource.BindGroupLayoutEntry::new(
      7,
      @wgpu.SHADER_STAGE_VERTEX.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        true,
        256UL,
      ),
    ),
  ])
  let offsets = mesh3d_draw_bind_group_dynamic_offsets(descriptor, 256, -1)
  inspect(offsets.length(), content="2")
  inspect(offsets[0], content="256")
  inspect(offsets[1], content="0")
}

///|
test "renderer: shadow shader defs extend descriptor defs with shadow projection state" {
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
    .with_vertex(
      @render_resource.VertexState::new(
        Some("pbr/prepass/prepass.wgsl"),
        [@render_resource.ShaderDefVal::Flag("PREPASS_PIPELINE")],
        None,
        [],
      ),
    )
    .with_fragment(
      Some(
        @render_resource.FragmentState::new(
          Some("pbr/render/pbr_prepass.wgsl"),
          [@render_resource.ShaderDefVal::Flag("DEPTH_PREPASS")],
          None,
          [],
        ),
      ),
    )
  let defines = mesh3d_shadow_shader_defines_from_descriptor(
    Some(descriptor),
    true,
    true,
    true,
    true,
  )
  debug_inspect(defines.get("PREPASS_PIPELINE"), content="Some(true)")
  debug_inspect(defines.get("DEPTH_PREPASS"), content="Some(true)")
  debug_inspect(
    defines.get("VIEW_PROJECTION_ORTHOGRAPHIC"),
    content="Some(true)",
  )
  debug_inspect(defines.get("SKINNED"), content="Some(true)")
  debug_inspect(defines.get("MAY_DISCARD"), content="Some(true)")
  debug_inspect(defines.get("PREPASS_FRAGMENT"), content="Some(true)")
}

///|
test "renderer: shadow depth keeps non-default material pipeline id for mesh layout" {
  inspect(
    mesh3d_shadow_pipeline_material_id(42UL, false, false).to_string(),
    content="42",
  )
  debug_inspect(
    mesh3d_shadow_pipeline_material_id(
      MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
      false,
      false,
    ) ==
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    content="true",
  )
}

///|
test "renderer: volumetric fog uses default mesh view bind group owner" {
  debug_inspect(
    mesh3d_volumetric_fog_view_material_pipeline_id() ==
    MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    content="true",
  )
  debug_inspect(
    mesh3d_volumetric_fog_view_material_pipeline_id() == 0UL,
    content="false",
  )
}

///|
test "renderer: volumetric fog group zero dynamic offsets mirror Bevy mesh view order" {
  let descriptor = mesh3d_default_mesh_view_layout().main_bind_group_layout_descriptor()
  let offsets = mesh3d_bind_group_layout_descriptor_view_dynamic_offsets(
    descriptor,
    light_probes_uniform_offset=640U,
  )
  inspect(offsets.length(), content="3")
  inspect(offsets[0], content="0")
  inspect(offsets[1], content="0")
  inspect(offsets[2], content="640")
}

///|
test "renderer: volumetric fog group zero layout exposes Bevy mesh view shadow slots" {
  let descriptor = mesh3d_default_mesh_view_layout().main_bind_group_layout_descriptor()
  debug_inspect(
    wbtest_bind_group_layout_has_binding(descriptor, 0),
    content="true",
  )
  debug_inspect(
    wbtest_bind_group_layout_has_binding(descriptor, 1),
    content="true",
  )
  debug_inspect(
    wbtest_bind_group_layout_has_binding(descriptor, 5),
    content="true",
  )
  debug_inspect(
    wbtest_bind_group_layout_has_binding(descriptor, 6),
    content="true",
  )
  debug_inspect(
    wbtest_bind_group_layout_has_binding(descriptor, 12),
    content="true",
  )
}

///|
test "renderer: volumetric fog resolves explicit view shadow texture identities" {
  inspect(
    mesh3d_volumetric_fog_resolved_point_shadow_texture_id(-1, 11),
    content="11",
  )
  inspect(
    mesh3d_volumetric_fog_resolved_directional_shadow_texture_id(-1, 22),
    content="22",
  )
  inspect(
    mesh3d_volumetric_fog_resolved_point_shadow_texture_id(55, 11),
    content="55",
  )
  inspect(
    mesh3d_volumetric_fog_resolved_directional_shadow_texture_id(77, 22),
    content="77",
  )
}

///|
test "renderer: volumetric fog bind group layout index mirrors Bevy flags" {
  inspect(mesh3d_volumetric_fog_bind_group_layout_index(1, false), content="0")
  inspect(mesh3d_volumetric_fog_bind_group_layout_index(4, false), content="1")
  inspect(mesh3d_volumetric_fog_bind_group_layout_index(1, true), content="2")
  inspect(mesh3d_volumetric_fog_bind_group_layout_index(4, true), content="3")
}

///|
test "renderer: volumetric fog MSAA shader key keeps single-sample color pipeline" {
  inspect(mesh3d_volumetric_fog_bind_group_layout_index(4, false), content="1")
  inspect(mesh3d_volumetric_fog_pipeline_render_sample_count(4), content="1")
}

///|
test "renderer: mesh3d lights uniform prefers bevy-shaped pbr bytes" {
  let sentinel = Bytes::from_array([
    (0xDE).to_byte(),
    (0xAD).to_byte(),
    (0xBE).to_byte(),
    (0xEF).to_byte(),
    (0x34).to_byte(),
    (0x12).to_byte(),
  ])
  let pass_state = gpu_wbtest_pass_state(
    mesh3d_lights_uniform_bytes=Some(sentinel),
  )
  let bytes = mesh3d_lights_uniform_bytes(pass_state)
  inspect(bytes.length(), content="6")
  inspect(bytes[0].to_uint(), content="222")
  inspect(bytes[1].to_uint(), content="173")
  inspect(bytes[2].to_uint(), content="190")
  inspect(bytes[3].to_uint(), content="239")
  inspect(bytes[4].to_uint(), content="52")
  inspect(bytes[5].to_uint(), content="18")
}

///|
test "renderer: volumetric fog pipeline cache key includes full hull vertex layout" {
  let layout_a = @mesh.VertexBufferLayout::new(
    array_stride=32,
    step_mode=@mesh.MeshVertexStepMode::Vertex,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=0,
        format=@mesh.MeshVertexFormat::Float32x3,
        shader_location=0,
      ),
    ],
  )
  let layout_b = @mesh.VertexBufferLayout::new(
    array_stride=32,
    step_mode=@mesh.MeshVertexStepMode::Vertex,
    attributes=[
      @mesh.VertexAttribute::new(
        offset=16,
        format=@mesh.MeshVertexFormat::Float32x3,
        shader_location=0,
      ),
    ],
  )
  let entry = Mesh3dVolumetricFogPipelineCacheEntry::{
    pipeline_id: 1,
    color_format: @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    msaa_sample_count: 1,
    has_density_texture: false,
    atmosphere: false,
    view_layout_key_bits: 0U,
    vertex_buffer_layout: layout_a,
    pipeline_layout: None,
    state: RenderPipelineErr("not materialized"),
  }
  inspect(
    entry.matches(
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      1,
      false,
      false,
      0U,
      layout_a,
    ),
    content="true",
  )
  inspect(
    entry.matches(
      @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      1,
      false,
      false,
      0U,
      layout_b,
    ),
    content="false",
  )
}

///|
test "renderer: volumetric fog volume selects Bevy hull mesh and dynamic uniform offset" {
  let interior = HostMesh3dVolumetricFogVolume::HostMesh3dVolumetricFogVolume(
    density_texture_id=-1,
    uniform_buffer_offset=32U,
    exterior=false,
  )
  let exterior = HostMesh3dVolumetricFogVolume::HostMesh3dVolumetricFogVolume(
    density_texture_id=7,
    uniform_buffer_offset=96U,
    exterior=true,
  )
  inspect(mesh3d_volumetric_fog_hull_mesh_id(interior, 11, 22), content="11")
  inspect(mesh3d_volumetric_fog_hull_mesh_id(exterior, 11, 22), content="22")
  let interior_offsets = mesh3d_volumetric_fog_dynamic_offsets(interior)
  let exterior_offsets = mesh3d_volumetric_fog_dynamic_offsets(exterior)
  inspect(interior_offsets.length(), content="1")
  inspect(interior_offsets[0], content="32")
  inspect(exterior_offsets.length(), content="1")
  inspect(exterior_offsets[0], content="96")
}

///|
test "renderer: volumetric fog density texture lookup follows Bevy render asset absence" {
  let backend = GpuBackend::new(assets_base="assets")
  inspect(
    mesh3d_volumetric_fog_resolved_texture(backend, -1) is None,
    content="true",
  )
  inspect(
    mesh3d_volumetric_fog_resolved_texture(backend, 123456) is None,
    content="true",
  )
  let texture_id = backend.create_texture_3d_with_format(
    4,
    4,
    4,
    @wgpu.TextureFormat::from_u32(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
    [Bytes::make(4 * 4 * 4 * 4, (0).to_byte())],
  )
  inspect(
    mesh3d_volumetric_fog_resolved_texture(backend, texture_id) is Some(_),
    content="true",
  )
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
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let value_defines = default_wgsl_value_defines()
  let preprocessed = load_wgsl_preprocessed(
    "", "sprite_render/mesh2d/mesh2d.wgsl", defines, value_defines,
  )
  debug_inspect(preprocessed.contains("const PI_2"), content="true")
  debug_inspect(preprocessed.contains("fn twice_pi"), content="true")
  debug_inspect(preprocessed.contains("mesh_functions::"), content="false")
  debug_inspect(preprocessed.contains("#import"), content="false")
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: mesh2d material preprocessing resolves quoted file imports" {
  clear_registered_wgsl_source_registry()
  let mesh_source =
    #|#import bevy_sprite::{
    #|  mesh2d_vertex_output::VertexOutput,
    #|}
    #|
    #|@fragment
    #|fn fragment(in: VertexOutput) -> @location(0) vec4<f32> {
    #|  _ = in;
    #|  return vec4<f32>(1.0);
    #|}
    #|
  let material_source =
    #|#import bevy_sprite::mesh2d_vertex_output::VertexOutput
    #|#import "shaders/custom_material_import.wgsl"::COLOR_MULTIPLIER
    #|
    #|@fragment
    #|fn fragment(mesh: VertexOutput) -> @location(0) vec4<f32> {
    #|  _ = mesh;
    #|  return COLOR_MULTIPLIER;
    #|}
    #|
  register_wgsl_source(
    "shaders/custom_material_import.wgsl", "const COLOR_MULTIPLIER: vec4<f32> = vec4<f32>(1.0, 1.0, 1.0, 0.5);\n",
  )
  register_wgsl_source("sprite_render/mesh2d/mesh2d.wgsl", mesh_source)
  register_wgsl_source(
    "sprite_render/mesh2d/mesh2d_vertex_output.wgsl", "#define_import_path bevy_sprite::mesh2d_vertex_output\nstruct VertexOutput { @builtin(position) position: vec4<f32>, @location(0) uv: vec2<f32>, }\n",
  )
  register_wgsl_source("shaders/custom_material_2d.wgsl", material_source)
  let preprocessed = load_wgsl_with_defines_required_mesh2d_material(
    Some("sprite_render/mesh2d/mesh2d.wgsl"),
    Some("shaders/custom_material_2d.wgsl"),
    [],
  )
  debug_inspect(preprocessed.contains("COLOR_MULTIPLIER"), content="true")
  debug_inspect(preprocessed.contains("#import"), content="false")
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: custom mesh2d pipeline preprocessing uses per-object uniform layout" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "sprite_render/mesh2d/mesh2d_types.wgsl", "#define_import_path bevy_sprite::mesh2d_types\nstruct Mesh2d { tag: u32, }\n",
  )
  let bindings_source =
    #|#define_import_path bevy_sprite::mesh2d_bindings
    #|#import bevy_sprite::mesh2d_types::Mesh2d
    #|
    #|#ifdef PER_OBJECT_BUFFER_BATCH_SIZE
    #|@group(1) @binding(0) var<uniform> mesh: array<Mesh2d, #{PER_OBJECT_BUFFER_BATCH_SIZE}u>;
    #|#else
    #|@group(1) @binding(0) var<storage> mesh: array<Mesh2d>;
    #|#endif
    #|
  register_wgsl_source(
    "sprite_render/mesh2d/mesh2d_bindings.wgsl", bindings_source,
  )
  let functions_source =
    #|#define_import_path bevy_sprite::mesh2d_functions
    #|#import bevy_sprite::mesh2d_bindings::mesh
    #|
    #|fn get_tag(instance_index: u32) -> u32 {
    #|    return mesh[instance_index].tag;
    #|}
    #|
  register_wgsl_source(
    "sprite_render/mesh2d/mesh2d_functions.wgsl", functions_source,
  )
  let shader_source =
    #|#import bevy_sprite::mesh2d_functions
    #|
    #|@vertex
    #|fn vertex(@builtin(instance_index) instance_index: u32) -> @builtin(position) vec4<f32> {
    #|    _ = mesh2d_functions::get_tag(instance_index);
    #|    return vec4<f32>(0.0);
    #|}
    #|
    #|@fragment
    #|fn fragment() -> @location(0) vec4<f32> {
    #|    return vec4<f32>(1.0);
    #|}
    #|
  register_wgsl_source(
    "examples/2d/mesh2d_manual/colored_mesh2d.wgsl", shader_source,
  )
  let preprocessed = load_wgsl_preprocessed(
    "",
    "examples/2d/mesh2d_manual/colored_mesh2d.wgsl",
    @hashmap.HashMap([]),
    mesh2d_pipeline_value_defines(),
  )
  debug_inspect(preprocessed.contains("var<uniform>"), content="true")
  debug_inspect(preprocessed.contains("var<storage>"), content="false")
  debug_inspect(preprocessed.contains("#import"), content="false")
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: registered wgsl sources resolve nested alias imports" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "test/types.wgsl", "#define_import_path test::types\nstruct Lights {\n  value: f32,\n}\n",
  )
  register_wgsl_source(
    "test/bindings.wgsl", "#define_import_path test::bindings\n#import test::types as types\nvar<private> lights: types::Lights;\n",
  )
  register_wgsl_source(
    "test/main.wgsl", "#import test::bindings::lights\nfn demo() -> f32 {\n  return lights.value;\n}\n",
  )
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let value_defines = default_wgsl_value_defines()
  let preprocessed = load_wgsl_preprocessed(
    "", "test/main.wgsl", defines, value_defines,
  )
  debug_inspect(preprocessed.contains("types::Lights"), content="false")
  debug_inspect(preprocessed.contains("struct Lights"), content="true")
  debug_inspect(preprocessed.contains("var<private> lights"), content="true")
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: registered wgsl sources resolve nested alias imports through module alias" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "test/types.wgsl", "#define_import_path test::types\nstruct Lights {\n  value: f32,\n}\n",
  )
  register_wgsl_source(
    "test/bindings.wgsl", "#define_import_path test::bindings\n#import test::types as types\nvar<private> lights: types::Lights;\n",
  )
  register_wgsl_source(
    "test/main.wgsl", "#import test::bindings\nfn demo() -> f32 {\n  return bindings::lights.value;\n}\n",
  )
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let value_defines = default_wgsl_value_defines()
  let preprocessed = load_wgsl_preprocessed(
    "", "test/main.wgsl", defines, value_defines,
  )
  debug_inspect(preprocessed.contains("types::Lights"), content="false")
  debug_inspect(preprocessed.contains("struct Lights"), content="true")
  debug_inspect(preprocessed.contains("var<private> lights"), content="true")
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: registered wgsl sources resolve nested alias imports through grouped alias" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "test/types.wgsl", "#define_import_path test::types\nstruct Lights {\n  value: f32,\n}\n",
  )
  register_wgsl_source(
    "test/bindings.wgsl", "#define_import_path test::bindings\n#import test::types as types\n#import test::atmosphere::types as atmosphere\n#import test::{ view::View, globals::Globals }\n@group(0) @binding(0) var<uniform> view: View;\n@group(0) @binding(1) var<uniform> lights: types::Lights;\n@group(0) @binding(11) var<uniform> globals: Globals;\n",
  )
  register_wgsl_source(
    "test/atmosphere/types.wgsl", "#define_import_path test::atmosphere::types\nstruct Atmosphere {\n  value: f32,\n}\n",
  )
  register_wgsl_source(
    "test/view.wgsl", "#define_import_path test::view\nstruct View {\n  value: f32,\n}\n",
  )
  register_wgsl_source(
    "test/globals.wgsl", "#define_import_path test::globals\nstruct Globals {\n  value: f32,\n}\n",
  )
  register_wgsl_source(
    "test/main.wgsl", "#import test::{ bindings as view_bindings, types }\n#import test::bindings::globals\nfn demo() -> f32 {\n  return view_bindings::lights.value + globals.value;\n}\n",
  )
  let defines : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let value_defines = default_wgsl_value_defines()
  let preprocessed = load_wgsl_preprocessed(
    "", "test/main.wgsl", defines, value_defines,
  )
  debug_inspect(preprocessed.contains("types::Lights"), content="false")
  debug_inspect(preprocessed.contains("struct Lights"), content="true")
  debug_inspect(preprocessed.contains("struct Globals"), content="true")
  debug_inspect(preprocessed.contains("var<uniform> lights"), content="true")
  debug_inspect(preprocessed.contains("var<uniform> globals"), content="true")
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: rg16f render target preserves Bevy motion-vector texture format" {
  let backend = GpuBackend::new(assets_base="assets")
  let target_id = backend.create_render_target_rg16f(128, 128, false)
  let ok = match find_texture(backend, target_id) {
    Some(texture) => texture.format == tf(@wgpu.TEXTURE_FORMAT_RG16_FLOAT)
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
    tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM),
    Some(tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB)),
  )
  let ok = match find_texture(backend, target_id) {
    Some(texture) =>
      texture.format == tf(@wgpu.TEXTURE_FORMAT_RGBA8_UNORM) &&
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
test "renderer: rgb9e5 3d texture upload preserves 3d dimension" {
  let backend = GpuBackend::new(assets_base="assets")
  let bytes = Bytes::makei(4 * 4 * 4 * 4, _ => (0).to_byte())
  let texture_id = backend.create_texture_3d_with_format(
    4,
    4,
    4,
    tf(@wgpu.TEXTURE_FORMAT_RGB9_E5_UFLOAT),
    [bytes],
  )
  let ok = match find_texture(backend, texture_id) {
    Some(texture) =>
      texture.texture.dimension_u32().raw == @wgpu.TEXTURE_DIMENSION_3D
    None => false
  }
  debug_inspect(ok, content="true")
}

///|
test "renderer: rgb9e5 stacked 2d texture upload preserves 2d-array dimension" {
  let backend = GpuBackend::new(assets_base="assets")
  let bytes = Bytes::makei(4 * 4 * 4, _ => (0).to_byte())
  let texture_id = backend.create_texture_stacked_2d_with_format(
    4,
    4,
    1,
    tf(@wgpu.TEXTURE_FORMAT_RGB9_E5_UFLOAT),
    [bytes],
    false,
    usage_bits=IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
  )
  let ok = match find_texture(backend, texture_id) {
    Some(texture) =>
      texture.texture.dimension_u32().raw == @wgpu.TEXTURE_DIMENSION_2D
    None => false
  }
  debug_inspect(ok, content="true")
}

///|
test "renderer: rgb9e5 cube texture upload creates a cubemap sample view" {
  let backend = GpuBackend::new(assets_base="assets")
  let level0 = Bytes::makei(4 * 4 * 4 * 6, _ => (0).to_byte())
  let texture_id = backend.create_texture_cube_with_format(
    4,
    4,
    tf(@wgpu.TEXTURE_FORMAT_RGB9_E5_UFLOAT),
    [level0],
    false,
    usage_bits=IMAGE_USAGE_DEFAULT_SAMPLED_BITS,
  )
  let ok = match find_texture(backend, texture_id) {
    Some(texture) =>
      texture.width == 4 &&
      texture.height == 4 &&
      texture.mip_level_count == 1 &&
      texture.texture.dimension_u32().raw == @wgpu.TEXTURE_DIMENSION_2D &&
      texture.sample_view is Some(_)
    None => false
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
test "renderer: texture usage bits map storage binding to WebGPU usage" {
  let usage = texture_usage_bits_to_wgpu(
    IMAGE_USAGE_TEXTURE_BINDING_BIT |
    IMAGE_USAGE_COPY_DST_BIT |
    IMAGE_USAGE_COPY_SRC_BIT |
    IMAGE_USAGE_STORAGE_BINDING_BIT,
  )
  debug_inspect(
    (usage & @wgpu.TEXTURE_USAGE_TEXTURE_BINDING) != 0UL,
    content="true",
  )
  debug_inspect((usage & @wgpu.TEXTURE_USAGE_COPY_DST) != 0UL, content="true")
  debug_inspect((usage & @wgpu.TEXTURE_USAGE_COPY_SRC) != 0UL, content="true")
  debug_inspect(
    (usage & @wgpu.TEXTURE_USAGE_STORAGE_BINDING) != 0UL,
    content="true",
  )
  debug_inspect(
    (usage & @wgpu.TEXTURE_USAGE_RENDER_ATTACHMENT) != 0UL,
    content="false",
  )
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
        ShaderNotReady(message) => message
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
  render_context_set_backend_for_test(None)
}

///|
test "renderer: surface acquire status follows Bevy window prepare semantics" {
  debug_inspect(
    surface_texture_status_is_success(
      @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_SUCCESS_OPTIMAL,
    ),
    content="true",
  )
  debug_inspect(
    surface_texture_status_is_success(
      @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_SUCCESS_SUBOPTIMAL,
    ),
    content="true",
  )
  debug_inspect(
    surface_texture_status_is_success(
      @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_OCCLUDED,
    ),
    content="false",
  )
  debug_inspect(
    surface_texture_status_name(
      @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_OCCLUDED,
    ),
    content="\"Occluded\"",
  )
  debug_inspect(
    surface_texture_status_name(
      @wgpu.SURFACE_GET_CURRENT_TEXTURE_STATUS_OUTDATED,
    ),
    content="\"Outdated\"",
  )
}

///|
test "renderer: motion-vector mesh layout uses storage morph descriptors" {
  let descriptor = mesh3d_motion_vector_mesh_layout_descriptor(
    true, true, true, true,
  )
  let bindings : Array[Int] = []
  for entry in descriptor.entries() {
    bindings.push(entry.binding())
  }
  debug_inspect(bindings, content="[0, 1, 2, 3, 8, 6, 7]")
  debug_inspect(
    mesh3d_draw_bind_group_dynamic_offsets(descriptor, 256, 512),
    content="[]",
  )
}

///|
test "renderer: mesh3d pipeline honors descriptor cull mode" {
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor().with_primitive(
    @render_resource.PrimitiveState::PrimitiveState().with_cull_mode(
      Some(@wgpu.CULL_MODE_FRONT),
    ),
  )
  let fallback = MESH3D_DRAW_FLAG_DECAL | 2
  debug_inspect(
    mesh3d_effective_pipeline_cull_mode(Some(descriptor), fallback),
    content="257",
  )
  debug_inspect(
    mesh3d_effective_pipeline_cull_mode(None, fallback),
    content="258",
  )
}

///|
test "renderer: material pipeline draw treats unregistered cached ids as pending" {
  let backend = GpuBackend::new(assets_base="assets")
  debug_inspect(
    mesh3d_material_render_pipeline_for_draw(
      backend,
      MESH3D_DEFAULT_MATERIAL_PIPELINE_ID,
    )
    is None,
    content="true",
  )
  debug_inspect(
    mesh3d_material_render_pipeline_for_draw(backend, 42UL) is None,
    content="true",
  )
}

///|
test "renderer: shadow depth pipeline keeps Bevy reverse-Z depth state" {
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor().with_depth_stencil(
    Some(
      @render_resource.DepthStencilState::new(
        @wgpu.TEXTURE_FORMAT_DEPTH24_PLUS,
        true,
        @wgpu.COMPARE_FUNCTION_LESS_EQUAL,
      ),
    ),
  )
  debug_inspect(
    mesh3d_shadow_depth_format(Some(descriptor)) ==
    @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    content="true",
  )
  debug_inspect(
    mesh3d_shadow_depth_compare(Some(descriptor)) ==
    @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    content="true",
  )
}

///|
test "renderer: shadow draw treats unregistered cached material pipelines as pending" {
  let backend = GpuBackend::new(assets_base="assets")
  debug_inspect(
    mesh3d_shadow_depth_pipeline_for_draw(
      backend,
      @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      42UL,
      2,
      false,
      false,
      false,
    )
    is None,
    content="true",
  )
}

///|
test "renderer: motion-vector draw treats unregistered cached material pipelines as pending" {
  let backend = GpuBackend::new(assets_base="assets")
  debug_inspect(
    mesh3d_motion_vector_pipeline_entry_for_draw(
      backend,
      @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
      1,
      42UL,
      None,
      2,
      false,
      false,
      false,
      false,
    )
    is None,
    content="true",
  )
}

///|
test "renderer: mesh3d shader value defines match Bevy native light limits" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "test/mesh_view_types.wgsl", "#define_import_path test::mesh_view_types\nstruct DirectionalLight { value: u32, }\nstruct RectLight { value: u32, }\nstruct Lights {\n  directional_lights: array<DirectionalLight, #{MAX_DIRECTIONAL_LIGHTS}u>,\n  cascades: array<u32, #{MAX_CASCADES_PER_LIGHT}u>,\n  rect_lights: array<RectLight, #{MAX_RECT_LIGHTS}u>,\n}\n",
  )
  register_wgsl_source(
    "test/main.wgsl", "#import test::mesh_view_types::Lights\nvar<private> lights: Lights;\nfn use_lights() -> u32 { return lights.directional_lights[0u].value; }\n",
  )
  let preprocessed = load_wgsl_preprocessed(
    "",
    "test/main.wgsl",
    @hashmap.HashMap([]),
    default_wgsl_value_defines(),
  ) catch {
    _ => abort("failed to preprocess mesh3d value define probe")
  }
  debug_inspect(
    preprocessed.contains("array<DirectionalLight, 10u>") ||
    preprocessed.contains(", 10>"),
    content="true",
  )
  debug_inspect(
    preprocessed.contains("array<u32, 4u>") ||
    preprocessed.contains("array<u32, 4>"),
    content="true",
  )
  debug_inspect(
    preprocessed.contains("array<RectLight, 8u>") ||
    preprocessed.contains(", 8>"),
    content="true",
  )
  clear_registered_wgsl_source_registry()
}

///|
test "renderer: mesh3d custom material pipeline preprocesses Bevy PBR vertex shader" {
  clear_registered_wgsl_source_registry()
  register_wgsl_source(
    "test/custom_mesh.wgsl", "#ifdef VERTEX_POSITIONS\nfn position_path() -> f32 { return 1.0; }\n#endif\n#ifdef VERTEX_NORMALS\nfn normal_path() -> f32 { return 2.0; }\n#endif\n@vertex\nfn vertex() -> @builtin(position) vec4<f32> {\n  return vec4<f32>(position_path(), 0.0, 0.0, 1.0);\n}\n",
  )
  register_wgsl_source(
    "test/line_material.wgsl", "@group(#{MATERIAL_BIND_GROUP}) @binding(0) var<uniform> color: vec4<f32>;\n@fragment\nfn fragment() -> @location(0) vec4<f32> { return color; }\n",
  )
  let descriptor = @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor()
    .with_vertex(
      @render_resource.VertexState::new(
        Some("test/custom_mesh.wgsl"),
        [
          @render_resource.ShaderDefVal::Flag("VERTEX_POSITIONS"),
          @render_resource.ShaderDefVal::Flag("VERTEX_OUTPUT_INSTANCE_INDEX"),
          @render_resource.ShaderDefVal::UInt("MATERIAL_BIND_GROUP", 3U),
        ],
        Some("vertex"),
        [],
      ),
    )
    .with_fragment(
      Some(
        @render_resource.FragmentState::new(
          Some("test/line_material.wgsl"),
          [@render_resource.ShaderDefVal::UInt("MATERIAL_BIND_GROUP", 3U)],
          Some("fragment"),
          [],
        ),
      ),
    )
  let vertex_source = load_wgsl_required_mesh3d_custom_pipeline(
    "assets",
    Some(descriptor),
    false,
    false,
    0,
    false,
    1,
    "test/custom_mesh.wgsl",
  ) catch {
    Fatal(message) =>
      abort(
        "failed to preprocess custom material mesh vertex shader: \{message}",
      )
    ShaderNotReady(message) =>
      abort("custom material mesh vertex shader not ready: \{message}")
  }
  let fragment_source = load_wgsl_required_mesh3d_custom_pipeline(
    "assets",
    Some(descriptor),
    false,
    false,
    0,
    false,
    1,
    "test/line_material.wgsl",
  ) catch {
    Fatal(message) =>
      abort("failed to preprocess line material fragment shader: \{message}")
    ShaderNotReady(message) =>
      abort("line material fragment shader not ready: \{message}")
  }
  debug_inspect(vertex_source.contains("#ifdef"), content="false")
  debug_inspect(vertex_source.contains("#define"), content="false")
  debug_inspect(vertex_source.contains("normal_path"), content="false")
  debug_inspect(
    fragment_source.contains("#{MATERIAL_BIND_GROUP}"),
    content="false",
  )
  debug_inspect(fragment_source.contains("@group(3)"), content="true")
  clear_registered_wgsl_source_registry()
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
