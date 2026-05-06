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
fn mesh3d_default_mesh_view_layout() -> @mesh_view_layout.MeshPipelineViewLayout {
  @mesh_view_layout.render3d_mesh_pipeline_view_layout(
    true,
    true,
    @mesh_view_layout.MeshPipelineViewLayoutKey::default(),
    clustered_decals_usable=false,
    irradiance_volumes_usable=false,
    oit_supported=false,
  )
}

///|
fn mesh3d_mesh_view_stage(
  stage : @mesh_view_layout.MeshViewBindGroupLayoutEntryStage,
) -> @wgpu.ShaderStage {
  match stage {
    @mesh_view_layout.MeshViewBindGroupLayoutEntryStage::Vertex =>
      ss(@wgpu.SHADER_STAGE_VERTEX)
    @mesh_view_layout.MeshViewBindGroupLayoutEntryStage::Fragment =>
      ss(@wgpu.SHADER_STAGE_FRAGMENT)
    @mesh_view_layout.MeshViewBindGroupLayoutEntryStage::VertexFragment =>
      ss(@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT)
  }
}

///|
fn mesh3d_mesh_view_texture_sample_type(
  sample_type : @mesh_view_layout.MeshViewTextureSampleType,
) -> UInt {
  match sample_type {
    @mesh_view_layout.MeshViewTextureSampleType::FloatFilterable =>
      @wgpu.TEXTURE_SAMPLE_TYPE_FLOAT
    @mesh_view_layout.MeshViewTextureSampleType::FloatNonFilterable =>
      @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT
    @mesh_view_layout.MeshViewTextureSampleType::Depth =>
      @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH
    @mesh_view_layout.MeshViewTextureSampleType::UInt =>
      @wgpu.TEXTURE_SAMPLE_TYPE_UINT
  }
}

///|
fn mesh3d_mesh_view_texture_dimension(
  dimension : @mesh_view_layout.MeshViewTextureDimension,
) -> UInt {
  match dimension {
    @mesh_view_layout.MeshViewTextureDimension::D2 =>
      @wgpu.TEXTURE_VIEW_DIMENSION_2D
    @mesh_view_layout.MeshViewTextureDimension::D2Array =>
      @wgpu.TEXTURE_VIEW_DIMENSION_2D_ARRAY
    @mesh_view_layout.MeshViewTextureDimension::D3 =>
      @wgpu.TEXTURE_VIEW_DIMENSION_3D
    @mesh_view_layout.MeshViewTextureDimension::Cube =>
      @wgpu.TEXTURE_VIEW_DIMENSION_CUBE
    @mesh_view_layout.MeshViewTextureDimension::CubeArray =>
      @wgpu.TEXTURE_VIEW_DIMENSION_CUBE_ARRAY
  }
}

///|
fn mesh3d_mesh_view_sampler_binding_type(
  sampler_type : @mesh_view_layout.MeshViewSamplerBindingType,
) -> UInt {
  match sampler_type {
    @mesh_view_layout.MeshViewSamplerBindingType::Filtering =>
      @wgpu.SAMPLER_BINDING_TYPE_FILTERING
    @mesh_view_layout.MeshViewSamplerBindingType::Comparison =>
      @wgpu.SAMPLER_BINDING_TYPE_COMPARISON
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
    8 => MESH3D_CLUSTERED_LIGHTS_BUFFER_SIZE
    9 => MESH3D_CLUSTERABLE_OBJECT_INDEX_LISTS_BUFFER_SIZE
    10 => MESH3D_CLUSTER_OFFSETS_AND_COUNTS_BUFFER_SIZE
    11 => MESH3D_GLOBALS_BUFFER_SIZE
    12 => MESH3D_FOG_BUFFER_SIZE
    13 => MESH3D_LIGHT_PROBES_BUFFER_SIZE
    14 => MESH3D_VISIBILITY_RANGES_BUFFER_SIZE
    15 => MESH3D_SSR_SETTINGS_BUFFER_SIZE
    16 => MESH3D_CONTACT_SHADOWS_SETTINGS_BUFFER_SIZE
    18 => MESH3D_ENVIRONMENT_MAP_UNIFORM_BUFFER_SIZE
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
    @mesh_view_layout.MeshViewBindGroupLayoutEntryType::UniformBuffer =>
      builder.add_buffer(
        binding,
        visibility,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        has_dynamic_offset=false,
        min_binding_size=mesh3d_mesh_view_min_binding_size(entry.binding),
      )
    @mesh_view_layout.MeshViewBindGroupLayoutEntryType::StorageBuffer(read_only) =>
      builder.add_buffer(
        binding,
        visibility,
        mesh3d_mesh_view_buffer_binding_type(read_only),
        has_dynamic_offset=false,
        min_binding_size=mesh3d_mesh_view_min_binding_size(entry.binding),
      )
    @mesh_view_layout.MeshViewBindGroupLayoutEntryType::Texture(
      sample_type,
      dimension,
      multisampled,
      array_count
    ) =>
      builder.add_texture(
        binding,
        visibility,
        mesh3d_mesh_view_texture_sample_type(sample_type),
        mesh3d_mesh_view_texture_dimension(dimension),
        multisampled~,
        count=mesh3d_mesh_view_binding_count(array_count),
      )
    @mesh_view_layout.MeshViewBindGroupLayoutEntryType::Sampler(sampler_type) =>
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
