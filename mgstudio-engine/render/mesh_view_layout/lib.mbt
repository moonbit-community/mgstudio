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
const MESH_VIEW_LAYOUT_MULTISAMPLED : UInt = 1U << 0

///|
const MESH_VIEW_LAYOUT_DEPTH_PREPASS : UInt = 1U << 1

///|
const MESH_VIEW_LAYOUT_NORMAL_PREPASS : UInt = 1U << 2

///|
const MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS : UInt = 1U << 3

///|
const MESH_VIEW_LAYOUT_DEFERRED_PREPASS : UInt = 1U << 4

///|
const MESH_VIEW_LAYOUT_OIT_ENABLED : UInt = 1U << 5

///|
const MESH_VIEW_LAYOUT_ATMOSPHERE : UInt = 1U << 6

///|
const MESH_VIEW_LAYOUT_STBN : UInt = 1U << 7

///|
pub const MESH_PIPELINE_VIEW_LAYOUT_KEY_COUNT : Int = 256

///|
pub struct MeshPipelineViewLayoutKey {
  bits : UInt
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MeshPipelineViewLayoutKey::default() -> MeshPipelineViewLayoutKey {
  MeshPipelineViewLayoutKey::{ bits: 0U }
}

///|
pub fn MeshPipelineViewLayoutKey::bits(
  self : MeshPipelineViewLayoutKey,
) -> UInt {
  self.bits
}

///|
pub fn mesh_view_layout_key_from_bits_truncate(
  bits : UInt,
) -> MeshPipelineViewLayoutKey {
  MeshPipelineViewLayoutKey::{ bits: bits & 0xFFU }
}

///|
fn mesh_view_layout_flag(enabled : Bool, flag : UInt) -> UInt {
  if enabled {
    flag
  } else {
    0U
  }
}

///|
pub fn mesh_view_layout_key(
  multisampled : Bool,
  depth_prepass : Bool,
  normal_prepass : Bool,
  motion_vector_prepass : Bool,
  deferred_prepass : Bool,
  oit_enabled : Bool,
  atmosphere : Bool,
  stbn : Bool,
) -> MeshPipelineViewLayoutKey {
  MeshPipelineViewLayoutKey::{
    bits: mesh_view_layout_flag(multisampled, MESH_VIEW_LAYOUT_MULTISAMPLED) |
    mesh_view_layout_flag(depth_prepass, MESH_VIEW_LAYOUT_DEPTH_PREPASS) |
    mesh_view_layout_flag(normal_prepass, MESH_VIEW_LAYOUT_NORMAL_PREPASS) |
    mesh_view_layout_flag(
      motion_vector_prepass,
      MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS,
    ) |
    mesh_view_layout_flag(deferred_prepass, MESH_VIEW_LAYOUT_DEFERRED_PREPASS) |
    mesh_view_layout_flag(oit_enabled, MESH_VIEW_LAYOUT_OIT_ENABLED) |
    mesh_view_layout_flag(atmosphere, MESH_VIEW_LAYOUT_ATMOSPHERE) |
    mesh_view_layout_flag(stbn, MESH_VIEW_LAYOUT_STBN),
  }
}

///|
pub fn mesh_view_layout_key_from_msaa(
  msaa_samples : Int,
) -> MeshPipelineViewLayoutKey {
  mesh_view_layout_key(
    msaa_samples > 1,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  )
}

///|
pub fn MeshPipelineViewLayoutKey::contains(
  self : MeshPipelineViewLayoutKey,
  flag : UInt,
) -> Bool {
  (self.bits & flag) != 0U
}

///|
pub fn MeshPipelineViewLayoutKey::label(
  self : MeshPipelineViewLayoutKey,
) -> String {
  let mut label = "mesh_view_layout"
  if self.contains(MESH_VIEW_LAYOUT_MULTISAMPLED) {
    label = "\{label}_multisampled"
  }
  if self.contains(MESH_VIEW_LAYOUT_DEPTH_PREPASS) {
    label = "\{label}_depth"
  }
  if self.contains(MESH_VIEW_LAYOUT_NORMAL_PREPASS) {
    label = "\{label}_normal"
  }
  if self.contains(MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS) {
    label = "\{label}_motion"
  }
  if self.contains(MESH_VIEW_LAYOUT_DEFERRED_PREPASS) {
    label = "\{label}_deferred"
  }
  if self.contains(MESH_VIEW_LAYOUT_OIT_ENABLED) {
    label = "\{label}_oit"
  }
  if self.contains(MESH_VIEW_LAYOUT_ATMOSPHERE) {
    label = "\{label}_atmosphere"
  }
  if self.contains(MESH_VIEW_LAYOUT_STBN) {
    label = "\{label}_stbn"
  }
  label
}

///|
pub struct MeshPipelineViewLayout {
  main_layout_label : String
  binding_array_layout_label : String
  empty_layout_label : String
  main_entries : Array[MeshViewBindGroupLayoutEntry]
  binding_array_entries : Array[MeshViewBindGroupLayoutEntry]
  texture_count : Int
}

///|
pub struct MeshPipelineViewLayouts {
  layouts : Array[MeshPipelineViewLayout]
}

///|
pub fn MeshPipelineViewLayouts::get_view_layout(
  self : MeshPipelineViewLayouts,
  layout_key : MeshPipelineViewLayoutKey,
) -> MeshPipelineViewLayout {
  let index = layout_key.bits().reinterpret_as_int()
  if index >= 0 && index < self.layouts.length() {
    self.layouts[index]
  } else {
    self.layouts[0]
  }
}

///|
pub struct MeshViewBindGroupLayoutEntry {
  binding : Int
  name : String
  entry_type : MeshViewBindGroupLayoutEntryType
  stage : MeshViewBindGroupLayoutEntryStage
  has_dynamic_offset : Bool
}

///|
pub enum MeshViewBindGroupLayoutEntryStage {
  Vertex
  Fragment
  VertexFragment
}

///|
pub enum MeshViewBindGroupLayoutEntryType {
  UniformBuffer
  StorageBuffer(Bool)
  Texture(MeshViewTextureSampleType, MeshViewTextureDimension, Bool, Int)
  Sampler(MeshViewSamplerBindingType)
}

///|
pub enum MeshViewTextureSampleType {
  FloatFilterable
  FloatNonFilterable
  Depth
  UInt
}

///|
pub enum MeshViewTextureDimension {
  D2
  D2Array
  D3
  Cube
  CubeArray
}

///|
pub enum MeshViewSamplerBindingType {
  Filtering
  Comparison
}

///|
fn mesh_view_layout_texture_count(
  main_entries : Array[MeshViewBindGroupLayoutEntry],
  binding_array_entries : Array[MeshViewBindGroupLayoutEntry],
) -> Int {
  let mut count = 0
  for entry in main_entries {
    if entry.entry_type is MeshViewBindGroupLayoutEntryType::Texture(_, _, _, _) {
      count = count + 1
    }
  }
  for entry in binding_array_entries {
    if entry.entry_type is MeshViewBindGroupLayoutEntryType::Texture(_, _, _, _) {
      count = count + 1
    }
  }
  count
}

///|
pub fn render3d_mesh_pipeline_view_layout(
  clustered_forward_buffer_read_only : Bool,
  visibility_ranges_buffer_read_only : Bool,
  layout_key : MeshPipelineViewLayoutKey,
  multiple_light_probes_in_array? : Bool = false,
  clustered_decals_usable? : Bool = true,
  irradiance_volumes_usable? : Bool = true,
  oit_supported? : Bool = true,
) -> MeshPipelineViewLayout {
  let (main_entries, binding_array_entries) = render3d_mesh_view_layout_entries(
    clustered_forward_buffer_read_only,
    visibility_ranges_buffer_read_only,
    layout_key,
    multiple_light_probes_in_array~,
    clustered_decals_usable~,
    irradiance_volumes_usable~,
    oit_supported~,
  )
  let label = layout_key.label()
  MeshPipelineViewLayout::{
    main_layout_label: label,
    binding_array_layout_label: "\{label}_binding_array",
    empty_layout_label: "\{label}_empty",
    main_entries,
    binding_array_entries,
    texture_count: mesh_view_layout_texture_count(
      main_entries, binding_array_entries,
    ),
  }
}

///|
pub fn render3d_mesh_pipeline_view_layouts(
  clustered_forward_buffer_read_only : Bool,
  visibility_ranges_buffer_read_only : Bool,
  multiple_light_probes_in_array? : Bool = false,
  clustered_decals_usable? : Bool = true,
  irradiance_volumes_usable? : Bool = true,
  oit_supported? : Bool = true,
) -> MeshPipelineViewLayouts {
  let layouts : Array[MeshPipelineViewLayout] = []
  for i in 0..<MESH_PIPELINE_VIEW_LAYOUT_KEY_COUNT {
    let layout_key = mesh_view_layout_key_from_bits_truncate(
      i.reinterpret_as_uint(),
    )
    layouts.push(
      render3d_mesh_pipeline_view_layout(
        clustered_forward_buffer_read_only,
        visibility_ranges_buffer_read_only,
        layout_key,
        multiple_light_probes_in_array~,
        clustered_decals_usable~,
        irradiance_volumes_usable~,
        oit_supported~,
      ),
    )
  }
  MeshPipelineViewLayouts::{ layouts, }
}

///|
fn mesh_view_uniform_buffer_entry(
  binding : Int,
  name : String,
  stage? : MeshViewBindGroupLayoutEntryStage = MeshViewBindGroupLayoutEntryStage::Fragment,
  has_dynamic_offset? : Bool = false,
) -> MeshViewBindGroupLayoutEntry {
  MeshViewBindGroupLayoutEntry::{
    binding,
    name,
    entry_type: MeshViewBindGroupLayoutEntryType::UniformBuffer,
    stage,
    has_dynamic_offset,
  }
}

///|
fn mesh_view_storage_buffer_entry(
  binding : Int,
  name : String,
  read_only : Bool,
  stage? : MeshViewBindGroupLayoutEntryStage = MeshViewBindGroupLayoutEntryStage::Fragment,
  has_dynamic_offset? : Bool = false,
) -> MeshViewBindGroupLayoutEntry {
  MeshViewBindGroupLayoutEntry::{
    binding,
    name,
    entry_type: MeshViewBindGroupLayoutEntryType::StorageBuffer(read_only),
    stage,
    has_dynamic_offset,
  }
}

///|
fn mesh_view_texture_entry(
  binding : Int,
  name : String,
  sample_type : MeshViewTextureSampleType,
  dimension : MeshViewTextureDimension,
  stage? : MeshViewBindGroupLayoutEntryStage = MeshViewBindGroupLayoutEntryStage::Fragment,
  multisampled? : Bool = false,
  array_count? : Int = 0,
) -> MeshViewBindGroupLayoutEntry {
  MeshViewBindGroupLayoutEntry::{
    binding,
    name,
    entry_type: MeshViewBindGroupLayoutEntryType::Texture(
      sample_type, dimension, multisampled, array_count,
    ),
    stage,
    has_dynamic_offset: false,
  }
}

///|
fn mesh_view_sampler_entry(
  binding : Int,
  name : String,
  sampler_type : MeshViewSamplerBindingType,
  stage? : MeshViewBindGroupLayoutEntryStage = MeshViewBindGroupLayoutEntryStage::Fragment,
) -> MeshViewBindGroupLayoutEntry {
  MeshViewBindGroupLayoutEntry::{
    binding,
    name,
    entry_type: MeshViewBindGroupLayoutEntryType::Sampler(sampler_type),
    stage,
    has_dynamic_offset: false,
  }
}

///|
pub fn render3d_mesh_view_layout_entries(
  clustered_forward_buffer_read_only : Bool,
  visibility_ranges_buffer_read_only : Bool,
  layout_key : MeshPipelineViewLayoutKey,
  multiple_light_probes_in_array? : Bool = false,
  clustered_decals_usable? : Bool = true,
  irradiance_volumes_usable? : Bool = true,
  oit_supported? : Bool = true,
) -> (Array[MeshViewBindGroupLayoutEntry], Array[MeshViewBindGroupLayoutEntry]) {
  // Bevy source: `bevy_pbr/src/render/mesh_view_bindings.rs::layout_entries`.
  let main_entries : Array[MeshViewBindGroupLayoutEntry] = [
    mesh_view_uniform_buffer_entry(
      0,
      "view",
      stage=MeshViewBindGroupLayoutEntryStage::VertexFragment,
      has_dynamic_offset=true,
    ),
    mesh_view_uniform_buffer_entry(1, "lights", has_dynamic_offset=true),
    mesh_view_texture_entry(
      2,
      "point_shadow_textures",
      MeshViewTextureSampleType::Depth,
      MeshViewTextureDimension::CubeArray,
    ),
    mesh_view_sampler_entry(
      3,
      "point_shadow_textures_comparison_sampler",
      MeshViewSamplerBindingType::Comparison,
    ),
    mesh_view_texture_entry(
      5,
      "directional_shadow_textures",
      MeshViewTextureSampleType::Depth,
      MeshViewTextureDimension::D2Array,
    ),
    mesh_view_sampler_entry(
      6,
      "directional_shadow_textures_comparison_sampler",
      MeshViewSamplerBindingType::Comparison,
    ),
    mesh_view_storage_buffer_entry(
      8, "clustered_lights", clustered_forward_buffer_read_only,
    ),
    mesh_view_storage_buffer_entry(
      9, "clusterable_object_index_lists", clustered_forward_buffer_read_only,
    ),
    mesh_view_storage_buffer_entry(
      10, "cluster_offsets_and_counts", clustered_forward_buffer_read_only,
    ),
    mesh_view_uniform_buffer_entry(
      11,
      "globals",
      stage=MeshViewBindGroupLayoutEntryStage::VertexFragment,
    ),
    mesh_view_uniform_buffer_entry(12, "fog", has_dynamic_offset=true),
    mesh_view_uniform_buffer_entry(13, "light_probes", has_dynamic_offset=true),
    mesh_view_storage_buffer_entry(
      14,
      "visibility_ranges",
      visibility_ranges_buffer_read_only,
      stage=MeshViewBindGroupLayoutEntryStage::Vertex,
    ),
    mesh_view_uniform_buffer_entry(15, "ssr_settings", has_dynamic_offset=true),
    mesh_view_uniform_buffer_entry(
      16,
      "contact_shadows_settings",
      has_dynamic_offset=true,
    ),
    mesh_view_texture_entry(
      17,
      "screen_space_ambient_occlusion_texture",
      MeshViewTextureSampleType::FloatNonFilterable,
      MeshViewTextureDimension::D2,
    ),
    mesh_view_uniform_buffer_entry(
      18,
      "environment_map_uniform",
      has_dynamic_offset=true,
    ),
    mesh_view_texture_entry(
      19,
      "dt_lut_texture",
      MeshViewTextureSampleType::FloatFilterable,
      MeshViewTextureDimension::D3,
    ),
    mesh_view_sampler_entry(
      20,
      "dt_lut_sampler",
      MeshViewSamplerBindingType::Filtering,
    ),
    mesh_view_texture_entry(
      25,
      "view_transmission_texture",
      MeshViewTextureSampleType::FloatFilterable,
      MeshViewTextureDimension::D2,
    ),
    mesh_view_sampler_entry(
      26,
      "view_transmission_sampler",
      MeshViewSamplerBindingType::Filtering,
    ),
  ]
  if layout_key.contains(MESH_VIEW_LAYOUT_DEPTH_PREPASS) {
    main_entries.push(
      mesh_view_texture_entry(
        21,
        "depth_prepass_texture",
        MeshViewTextureSampleType::Depth,
        MeshViewTextureDimension::D2,
        multisampled=layout_key.contains(MESH_VIEW_LAYOUT_MULTISAMPLED),
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_NORMAL_PREPASS) {
    main_entries.push(
      mesh_view_texture_entry(
        22,
        "normal_prepass_texture",
        MeshViewTextureSampleType::FloatNonFilterable,
        MeshViewTextureDimension::D2,
        multisampled=layout_key.contains(MESH_VIEW_LAYOUT_MULTISAMPLED),
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS) {
    main_entries.push(
      mesh_view_texture_entry(
        23,
        "motion_vector_prepass_texture",
        MeshViewTextureSampleType::FloatNonFilterable,
        MeshViewTextureDimension::D2,
        multisampled=layout_key.contains(MESH_VIEW_LAYOUT_MULTISAMPLED),
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_DEFERRED_PREPASS) {
    main_entries.push(
      mesh_view_texture_entry(
        24,
        "deferred_prepass_texture",
        MeshViewTextureSampleType::UInt,
        MeshViewTextureDimension::D2,
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_OIT_ENABLED) && oit_supported {
    main_entries.push(
      mesh_view_uniform_buffer_entry(
        27,
        "oit_settings",
        has_dynamic_offset=true,
      ),
    )
    main_entries.push(mesh_view_uniform_buffer_entry(28, "oit_nodes_capacity"))
    main_entries.push(mesh_view_storage_buffer_entry(29, "oit_nodes", false))
    main_entries.push(mesh_view_storage_buffer_entry(30, "oit_heads", false))
    main_entries.push(
      mesh_view_storage_buffer_entry(31, "oit_atomic_counter", false),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_ATMOSPHERE) {
    main_entries.push(
      mesh_view_texture_entry(
        32,
        "atmosphere_transmittance_texture",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::D2,
      ),
    )
    main_entries.push(
      mesh_view_sampler_entry(
        33,
        "atmosphere_transmittance_sampler",
        MeshViewSamplerBindingType::Filtering,
      ),
    )
    main_entries.push(
      mesh_view_storage_buffer_entry(34, "atmosphere_data", true),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_STBN) {
    main_entries.push(
      mesh_view_texture_entry(
        35,
        "blue_noise_texture",
        MeshViewTextureSampleType::FloatNonFilterable,
        MeshViewTextureDimension::D2Array,
      ),
    )
  }
  let binding_array_entries : Array[MeshViewBindGroupLayoutEntry] = [
    mesh_view_texture_entry(
      0,
      "diffuse_environment_maps",
      MeshViewTextureSampleType::FloatFilterable,
      MeshViewTextureDimension::Cube,
      array_count=if multiple_light_probes_in_array { 8 } else { 0 },
    ),
    mesh_view_texture_entry(
      1,
      "specular_environment_maps",
      MeshViewTextureSampleType::FloatFilterable,
      MeshViewTextureDimension::Cube,
      array_count=if multiple_light_probes_in_array { 8 } else { 0 },
    ),
    mesh_view_sampler_entry(
      2,
      "environment_map_sampler",
      MeshViewSamplerBindingType::Filtering,
    ),
  ]
  if irradiance_volumes_usable {
    binding_array_entries.push(
      mesh_view_texture_entry(
        3,
        "irradiance_volumes",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::D3,
        array_count=8,
      ),
    )
    binding_array_entries.push(
      mesh_view_sampler_entry(
        4,
        "irradiance_volume_sampler",
        MeshViewSamplerBindingType::Filtering,
      ),
    )
  }
  if clustered_decals_usable {
    binding_array_entries.push(
      mesh_view_storage_buffer_entry(5, "clustered_decals", true),
    )
    binding_array_entries.push(
      mesh_view_texture_entry(
        6,
        "clustered_decal_textures",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::D2,
        array_count=8,
      ),
    )
    binding_array_entries.push(
      mesh_view_sampler_entry(
        7,
        "clustered_decal_sampler",
        MeshViewSamplerBindingType::Filtering,
      ),
    )
  }
  (main_entries, binding_array_entries)
}
