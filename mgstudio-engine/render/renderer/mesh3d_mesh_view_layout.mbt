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

// Bevy source: `bevy/crates/bevy_pbr/src/render/mesh_view_bindings.rs`.

///|
fn mesh3d_default_mesh_view_layout_key(
  tonemap_in_shader? : Bool = false,
) -> @mesh_view_layout.MeshPipelineViewLayoutKey {
  @mesh_view_layout.mesh_view_layout_key(
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    tonemap_in_shader~,
  )
}

///|
fn mesh3d_clustered_decals_are_usable() -> Bool {
  mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=0U,
  )
}

///|
const MESH3D_STANDARD_MATERIAL_FRAGMENT_SHADER_MIN_TEXTURE_BINDINGS : UInt = 16U

///|
const MESH3D_MAX_VIEW_LIGHT_PROBES : UInt = 8U

///|
fn mesh3d_bluenoise_texture_feature_enabled() -> Bool {
  false
}

///|
fn mesh3d_area_light_luts_feature_enabled() -> Bool {
  false
}

///|
fn mesh3d_dfg_lut_feature_enabled() -> Bool {
  false
}

///|
fn mesh3d_light_probe_binding_arrays_are_usable() -> Bool {
  // Bevy source: `bevy/crates/bevy_pbr/src/light_probe/mod.rs::binding_arrays_are_usable`.
  mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=MESH3D_STANDARD_MATERIAL_FRAGMENT_SHADER_MIN_TEXTURE_BINDINGS +
      MESH3D_MAX_VIEW_LIGHT_PROBES,
  )
}

///|
fn mesh3d_default_mesh_view_layout(
  tonemap_in_shader? : Bool = false,
  clustered_decals_usable? : Bool = mesh3d_clustered_decals_are_usable(),
) -> @mesh_view_layout.MeshPipelineViewLayout {
  @mesh_view_layout.render3d_mesh_pipeline_view_layout(
    true,
    true,
    mesh3d_default_mesh_view_layout_key(tonemap_in_shader~),
    multiple_light_probes_in_array=mesh3d_light_probe_binding_arrays_are_usable(),
    clustered_decals_usable~,
    irradiance_volumes_usable=false,
    oit_supported=false,
  )
}

///|
fn mesh3d_pass_mesh_view_layout_key(
  pass_state : GpuPassState,
  atmosphere? : Bool = false,
) -> @mesh_view_layout.MeshPipelineViewLayoutKey {
  @mesh_view_layout.mesh_view_layout_key(
    pass_state.msaa_sample_count > 1,
    pass_state.prepass_depth_texture_id >= 0,
    pass_state.prepass_normal_texture_id >= 0,
    pass_state.prepass_motion_vector_texture_id >= 0,
    pass_state.prepass_deferred_texture_id >= 0,
    false,
    atmosphere,
    mesh3d_bluenoise_texture_feature_enabled(),
    tonemap_in_shader=pass_state.tonemap_in_shader,
    environment_map=pass_state.environment_map_intensity > 0.0F,
    irradiance_volume=mesh3d_irradiance_volume_texture_ids_have_loaded_texture(
      pass_state.irradiance_volume_texture_ids,
    ),
    screen_space_reflections=pass_state.screen_space_reflections,
    area_light_luts=mesh3d_area_light_luts_feature_enabled(),
    dfg_lut=mesh3d_dfg_lut_feature_enabled(),
  )
}

///|
fn mesh3d_mesh_view_stage(
  stage : @mesh_view_layout.MeshViewBindGroupLayoutEntryStage,
) -> @wgpu.ShaderStage {
  match stage {
    Vertex => ss(@wgpu.SHADER_STAGE_VERTEX)
    Fragment => ss(@wgpu.SHADER_STAGE_FRAGMENT)
    VertexFragment =>
      ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
  }
}

///|
fn mesh3d_mesh_view_texture_sample_type(
  sample_type : @mesh_view_layout.MeshViewTextureSampleType,
) -> UInt {
  match sample_type {
    FloatFilterable => @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT
    FloatNonFilterable => @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT
    Depth => @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH
    UInt => @wgpu.TEXTURE_SAMPLE_TYPE_UINT
  }
}

///|
fn mesh3d_mesh_view_texture_dimension(
  dimension : @mesh_view_layout.MeshViewTextureDimension,
) -> UInt {
  match dimension {
    D2 => @wgpu.TEXTURE_VIEW_DIMENSION_2D
    D2Array => @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY
    D3 => @wgpu.TEXTURE_VIEW_DIMENSION_3D
    Cube => @wgpu.TEXTURE_VIEW_DIMENSION_CUBE
    CubeArray => @wgpu.TEXTURE_VIEW_DIMENSION_CUBE_ARRAY
  }
}

///|
fn mesh3d_mesh_view_sampler_binding_type(
  sampler_type : @mesh_view_layout.MeshViewSamplerBindingType,
) -> UInt {
  match sampler_type {
    Filtering => @wgpu.SAMPLER_BINDING_TYPE_FILTERING
    Comparison => @wgpu.SAMPLER_BINDING_TYPE_COMPARISON
  }
}

///|
fn mesh3d_mesh_view_buffer_binding_type(read_only : Bool) -> UInt {
  if read_only {
    @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE
  } else {
    @wgpu.BUFFER_BINDING_TYPE_STORAGE
  }
}

///|
fn mesh3d_mesh_view_min_binding_size(binding : Int) -> UInt64 {
  match binding {
    8 => 80UL
    9 => 4UL
    10 => 32UL
    11 => MESH3D_GLOBALS_BUFFER_SIZE
    12 => MESH3D_LIGHT_PROBES_BUFFER_SIZE
    13 => MESH3D_FOG_BUFFER_SIZE
    14 => MESH3D_VISIBILITY_RANGES_BUFFER_SIZE
    15 => MESH3D_SSR_SETTINGS_BUFFER_SIZE
    16 => MESH3D_CONTACT_SHADOWS_SETTINGS_BUFFER_SIZE
    33 => MESH3D_ATMOSPHERE_BUFFER_SIZE
    _ => 0UL
  }
}

///|
fn mesh3d_mesh_view_binding_count(array_count : Int) -> UInt {
  if array_count <= 0 {
    1U
  } else {
    array_count.reinterpret_as_uint()
  }
}

///|
fn mesh3d_add_mesh_view_layout_entry(
  builder : @wgpu.BindGroupLayoutBuilder,
  entry : @mesh_view_layout.MeshViewBindGroupLayoutEntry,
) -> Bool {
  let binding = entry.binding.reinterpret_as_uint()
  let visibility = mesh3d_mesh_view_stage(entry.stage)
  match entry.entry_type {
    UniformBuffer =>
      builder.add_buffer(
        binding,
        visibility,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        has_dynamic_offset=entry.has_dynamic_offset,
        min_binding_size=mesh3d_mesh_view_min_binding_size(entry.binding),
      )
    StorageBuffer(read_only) =>
      builder.add_buffer(
        binding,
        visibility,
        mesh3d_mesh_view_buffer_binding_type(read_only),
        has_dynamic_offset=entry.has_dynamic_offset,
        min_binding_size=mesh3d_mesh_view_min_binding_size(entry.binding),
      )
    Texture(sample_type, dimension, multisampled, array_count) =>
      builder.add_texture(
        binding,
        visibility,
        mesh3d_mesh_view_texture_sample_type(sample_type),
        mesh3d_mesh_view_texture_dimension(dimension),
        multisampled~,
        count=mesh3d_mesh_view_binding_count(array_count),
      )
    Sampler(sampler_type) =>
      builder.add_sampler(
        binding,
        visibility,
        mesh3d_mesh_view_sampler_binding_type(sampler_type),
      )
  }
}

///|
fn mesh3d_add_mesh_view_layout_entries(
  builder : @wgpu.BindGroupLayoutBuilder,
  entries : Array[@mesh_view_layout.MeshViewBindGroupLayoutEntry],
) -> Bool {
  let mut ok = true
  for entry in entries {
    if ok {
      ok = mesh3d_add_mesh_view_layout_entry(builder, entry)
    }
  }
  ok
}
