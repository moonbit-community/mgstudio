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
pub const MESH_VIEW_LAYOUT_TONEMAP_IN_SHADER : UInt = 1U << 8

///|
pub const MESH_VIEW_LAYOUT_ENVIRONMENT_MAP : UInt = 1U << 9

///|
pub const MESH_VIEW_LAYOUT_SCREEN_SPACE_AMBIENT_OCCLUSION : UInt = 1U << 10

///|
pub const MESH_VIEW_LAYOUT_IRRADIANCE_VOLUME : UInt = 1U << 11

///|
pub const MESH_VIEW_LAYOUT_SCREEN_SPACE_REFLECTIONS : UInt = 1U << 12

///|
pub const MESH_VIEW_LAYOUT_CONTACT_SHADOWS : UInt = 1U << 13

///|
pub const MESH_VIEW_LAYOUT_DISTANCE_FOG : UInt = 1U << 14

///|
pub const MESH_VIEW_LAYOUT_AREA_LIGHT_LUTS : UInt = 1U << 15

///|
const MESH_PIPELINE_VIEW_LAYOUT_KEY_MASK : UInt = 0xFFFFU

///|
pub const MESH_PIPELINE_VIEW_LAYOUT_KEY_COUNT : Int = 65536

///|
pub struct MeshPipelineViewLayoutKey {
  bits : UInt
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MeshPipelineViewLayoutKey::MeshPipelineViewLayoutKey() -> MeshPipelineViewLayoutKey {
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
  MeshPipelineViewLayoutKey::{ bits: bits & MESH_PIPELINE_VIEW_LAYOUT_KEY_MASK }
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
  tonemap_in_shader? : Bool = false,
  environment_map? : Bool = false,
  screen_space_ambient_occlusion? : Bool = false,
  irradiance_volume? : Bool = false,
  screen_space_reflections? : Bool = false,
  contact_shadows? : Bool = false,
  distance_fog? : Bool = false,
  area_light_luts? : Bool = false,
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
    mesh_view_layout_flag(stbn, MESH_VIEW_LAYOUT_STBN) |
    mesh_view_layout_flag(tonemap_in_shader, MESH_VIEW_LAYOUT_TONEMAP_IN_SHADER) |
    mesh_view_layout_flag(environment_map, MESH_VIEW_LAYOUT_ENVIRONMENT_MAP) |
    mesh_view_layout_flag(
      screen_space_ambient_occlusion,
      MESH_VIEW_LAYOUT_SCREEN_SPACE_AMBIENT_OCCLUSION,
    ) |
    mesh_view_layout_flag(irradiance_volume, MESH_VIEW_LAYOUT_IRRADIANCE_VOLUME) |
    mesh_view_layout_flag(
      screen_space_reflections,
      MESH_VIEW_LAYOUT_SCREEN_SPACE_REFLECTIONS,
    ) |
    mesh_view_layout_flag(contact_shadows, MESH_VIEW_LAYOUT_CONTACT_SHADOWS) |
    mesh_view_layout_flag(distance_fog, MESH_VIEW_LAYOUT_DISTANCE_FOG) |
    mesh_view_layout_flag(area_light_luts, MESH_VIEW_LAYOUT_AREA_LIGHT_LUTS),
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
  let parts : Array[String] = []
  if self.contains(MESH_VIEW_LAYOUT_MULTISAMPLED) {
    parts.push("multisampled")
  }
  if self.contains(MESH_VIEW_LAYOUT_DEPTH_PREPASS) {
    parts.push("depth_prepass")
  }
  if self.contains(MESH_VIEW_LAYOUT_NORMAL_PREPASS) {
    parts.push("normal_prepass")
  }
  if self.contains(MESH_VIEW_LAYOUT_MOTION_VECTOR_PREPASS) {
    parts.push("motion_vector_prepass")
  }
  if self.contains(MESH_VIEW_LAYOUT_DEFERRED_PREPASS) {
    parts.push("deferred_prepass")
  }
  if self.contains(MESH_VIEW_LAYOUT_OIT_ENABLED) {
    parts.push("oit_enabled")
  }
  if self.contains(MESH_VIEW_LAYOUT_ATMOSPHERE) {
    parts.push("atmosphere")
  }
  if self.contains(MESH_VIEW_LAYOUT_STBN) {
    parts.push("stbn")
  }
  if self.contains(MESH_VIEW_LAYOUT_TONEMAP_IN_SHADER) {
    parts.push("tonemap_in_shader")
  }
  if self.contains(MESH_VIEW_LAYOUT_ENVIRONMENT_MAP) {
    parts.push("environment_map")
  }
  if self.contains(MESH_VIEW_LAYOUT_SCREEN_SPACE_AMBIENT_OCCLUSION) {
    parts.push("screen_space_ambient_occlusion")
  }
  if self.contains(MESH_VIEW_LAYOUT_IRRADIANCE_VOLUME) {
    parts.push("irradiance_volume")
  }
  if self.contains(MESH_VIEW_LAYOUT_SCREEN_SPACE_REFLECTIONS) {
    parts.push("screen_space_reflections")
  }
  if self.contains(MESH_VIEW_LAYOUT_CONTACT_SHADOWS) {
    parts.push("contact_shadows")
  }
  if self.contains(MESH_VIEW_LAYOUT_DISTANCE_FOG) {
    parts.push("distance_fog")
  }
  if self.contains(MESH_VIEW_LAYOUT_AREA_LIGHT_LUTS) {
    parts.push("area_light_luts")
  }
  let mut label = "mesh_view_layout:"
  for index in 0..<parts.length() {
    if index > 0 {
      label = label + ","
    }
    label = label + parts[index]
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
  clustered_forward_buffer_read_only : Bool
  visibility_ranges_buffer_read_only : Bool
  multiple_light_probes_in_array : Bool
  clustered_decals_usable : Bool
  irradiance_volumes_usable : Bool
  oit_supported : Bool
}

///|
pub fn MeshPipelineViewLayouts::get_view_layout(
  self : MeshPipelineViewLayouts,
  layout_key : MeshPipelineViewLayoutKey,
) -> MeshPipelineViewLayout {
  render3d_mesh_pipeline_view_layout(
    self.clustered_forward_buffer_read_only,
    self.visibility_ranges_buffer_read_only,
    layout_key,
    multiple_light_probes_in_array=self.multiple_light_probes_in_array,
    clustered_decals_usable=self.clustered_decals_usable,
    irradiance_volumes_usable=self.irradiance_volumes_usable,
    oit_supported=self.oit_supported,
  )
}

///|
fn mesh_view_layout_stage_visibility(
  stage : MeshViewBindGroupLayoutEntryStage,
) -> UInt {
  match stage {
    Vertex => 1U
    Fragment => 2U
    VertexFragment => 3U
  }
}

///|
fn mesh_view_layout_texture_sample_type(
  sample_type : MeshViewTextureSampleType,
) -> @render_resource.TextureSampleType {
  match sample_type {
    FloatFilterable => @render_resource.TextureSampleType::Float(true)
    FloatNonFilterable => @render_resource.TextureSampleType::Float(false)
    Depth => @render_resource.TextureSampleType::Depth
    UInt => @render_resource.TextureSampleType::UInt
  }
}

///|
fn mesh_view_layout_texture_dimension(
  dimension : MeshViewTextureDimension,
) -> @render_resource.TextureViewDimension {
  match dimension {
    D2 => @render_resource.TextureViewDimension::D2
    D2Array => @render_resource.TextureViewDimension::D2Array
    D3 => @render_resource.TextureViewDimension::D3
    Cube => @render_resource.TextureViewDimension::Cube
    CubeArray => @render_resource.TextureViewDimension::CubeArray
  }
}

///|
fn mesh_view_layout_sampler_binding_type(
  sampler_type : MeshViewSamplerBindingType,
) -> @render_resource.SamplerBindingType {
  match sampler_type {
    Filtering => @render_resource.SamplerBindingType::Filtering
    Comparison => @render_resource.SamplerBindingType::Comparison
  }
}

///|
fn mesh_view_layout_min_binding_size(binding : Int) -> UInt64 {
  match binding {
    8 => 16320UL
    9 => 65536UL
    10 => 131072UL
    11 => 16UL
    12 => 2048UL
    13 => 64UL
    14 => 16UL
    15 => 64UL
    16 => 16UL
    _ => 0UL
  }
}

///|
fn mesh_view_layout_entry_to_render_resource(
  entry : MeshViewBindGroupLayoutEntry,
) -> @render_resource.BindGroupLayoutEntry {
  let visibility = mesh_view_layout_stage_visibility(entry.stage)
  let kind = match entry.entry_type {
    UniformBuffer =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        entry.has_dynamic_offset,
        mesh_view_layout_min_binding_size(entry.binding),
      )
    StorageBuffer(read_only) =>
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Storage(read_only),
        entry.has_dynamic_offset,
        mesh_view_layout_min_binding_size(entry.binding),
      )
    Texture(sample_type, dimension, multisampled, _) =>
      @render_resource.BindingType::TextureBinding(
        mesh_view_layout_texture_sample_type(sample_type),
        mesh_view_layout_texture_dimension(dimension),
        multisampled,
      )
    Sampler(sampler_type) =>
      @render_resource.BindingType::SamplerBinding(
        mesh_view_layout_sampler_binding_type(sampler_type),
      )
  }
  let count = match entry.entry_type {
    Texture(_, _, _, array_count) => array_count
    _ => 0
  }
  @render_resource.BindGroupLayoutEntry::new(
    entry.binding,
    visibility,
    kind,
    count~,
  )
}

///|
fn mesh_view_layout_entries_to_render_resource(
  entries : Array[MeshViewBindGroupLayoutEntry],
) -> Array[@render_resource.BindGroupLayoutEntry] {
  let output : Array[@render_resource.BindGroupLayoutEntry] = []
  for entry in entries {
    output.push(mesh_view_layout_entry_to_render_resource(entry))
  }
  output
}

///|
pub fn MeshPipelineViewLayout::main_bind_group_layout_descriptor(
  self : MeshPipelineViewLayout,
) -> @render_resource.BindGroupLayoutDescriptor {
  @render_resource.BindGroupLayoutDescriptor::new(
    self.main_layout_label,
    mesh_view_layout_entries_to_render_resource(self.main_entries),
  )
}

///|
pub fn MeshPipelineViewLayout::binding_array_bind_group_layout_descriptor(
  self : MeshPipelineViewLayout,
) -> @render_resource.BindGroupLayoutDescriptor {
  @render_resource.BindGroupLayoutDescriptor::new(
    self.binding_array_layout_label,
    mesh_view_layout_entries_to_render_resource(self.binding_array_entries),
  )
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
    binding_array_layout_label: label.replace(
      old="mesh_view_layout:",
      new="mesh_view_layout_binding_array:",
    ),
    empty_layout_label: "mesh_view_layout_empty",
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
  MeshPipelineViewLayouts::{
    clustered_forward_buffer_read_only,
    visibility_ranges_buffer_read_only,
    multiple_light_probes_in_array,
    clustered_decals_usable,
    irradiance_volumes_usable,
    oit_supported,
  }
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
    mesh_view_uniform_buffer_entry(12, "light_probes", has_dynamic_offset=true),
    mesh_view_storage_buffer_entry(
      14,
      "visibility_ranges",
      visibility_ranges_buffer_read_only,
      stage=MeshViewBindGroupLayoutEntryStage::Vertex,
    ),
  ]
  if layout_key.contains(MESH_VIEW_LAYOUT_DISTANCE_FOG) {
    main_entries.push(
      mesh_view_uniform_buffer_entry(13, "fog", has_dynamic_offset=true),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_SCREEN_SPACE_REFLECTIONS) {
    main_entries.push(
      mesh_view_uniform_buffer_entry(
        15,
        "ssr_settings",
        has_dynamic_offset=true,
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_CONTACT_SHADOWS) {
    main_entries.push(
      mesh_view_uniform_buffer_entry(
        16,
        "contact_shadows_settings",
        has_dynamic_offset=true,
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_SCREEN_SPACE_AMBIENT_OCCLUSION) {
    main_entries.push(
      mesh_view_texture_entry(
        17,
        "screen_space_ambient_occlusion_texture",
        MeshViewTextureSampleType::FloatNonFilterable,
        MeshViewTextureDimension::D2,
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_TONEMAP_IN_SHADER) {
    main_entries.push(
      mesh_view_texture_entry(
        18,
        "dt_lut_texture",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::D3,
      ),
    )
    main_entries.push(
      mesh_view_sampler_entry(
        19,
        "dt_lut_sampler",
        MeshViewSamplerBindingType::Filtering,
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_DEPTH_PREPASS) {
    main_entries.push(
      mesh_view_texture_entry(
        20,
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
        21,
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
        22,
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
        23,
        "deferred_prepass_texture",
        MeshViewTextureSampleType::UInt,
        MeshViewTextureDimension::D2,
      ),
    )
  }
  main_entries.push(
    mesh_view_texture_entry(
      24,
      "view_transmission_texture",
      MeshViewTextureSampleType::FloatFilterable,
      MeshViewTextureDimension::D2,
    ),
  )
  main_entries.push(
    mesh_view_sampler_entry(
      25,
      "view_transmission_sampler",
      MeshViewSamplerBindingType::Filtering,
    ),
  )
  if layout_key.contains(MESH_VIEW_LAYOUT_OIT_ENABLED) && oit_supported {
    main_entries.push(
      mesh_view_uniform_buffer_entry(
        26,
        "oit_settings",
        has_dynamic_offset=true,
      ),
    )
    main_entries.push(mesh_view_uniform_buffer_entry(27, "oit_nodes_capacity"))
    main_entries.push(mesh_view_storage_buffer_entry(28, "oit_nodes", false))
    main_entries.push(mesh_view_storage_buffer_entry(29, "oit_heads", false))
    main_entries.push(
      mesh_view_storage_buffer_entry(30, "oit_atomic_counter", false),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_ATMOSPHERE) {
    main_entries.push(
      mesh_view_texture_entry(
        31,
        "atmosphere_transmittance_texture",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::D2,
      ),
    )
    main_entries.push(
      mesh_view_sampler_entry(
        32,
        "atmosphere_transmittance_sampler",
        MeshViewSamplerBindingType::Filtering,
      ),
    )
    main_entries.push(
      mesh_view_storage_buffer_entry(33, "atmosphere_data", true),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_STBN) {
    main_entries.push(
      mesh_view_texture_entry(
        34,
        "blue_noise_texture",
        MeshViewTextureSampleType::FloatNonFilterable,
        MeshViewTextureDimension::D2Array,
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_AREA_LIGHT_LUTS) {
    main_entries.push(
      mesh_view_texture_entry(
        35,
        "area_light_luts",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::D2Array,
      ),
    )
    main_entries.push(
      mesh_view_sampler_entry(
        36,
        "area_light_luts_sampler",
        MeshViewSamplerBindingType::Filtering,
      ),
    )
  }
  let binding_array_entries : Array[MeshViewBindGroupLayoutEntry] = []
  if layout_key.contains(MESH_VIEW_LAYOUT_ENVIRONMENT_MAP) {
    binding_array_entries.push(
      mesh_view_texture_entry(
        0,
        "diffuse_environment_maps",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::Cube,
        array_count=if multiple_light_probes_in_array { 8 } else { 0 },
      ),
    )
    binding_array_entries.push(
      mesh_view_texture_entry(
        1,
        "specular_environment_maps",
        MeshViewTextureSampleType::FloatFilterable,
        MeshViewTextureDimension::Cube,
        array_count=if multiple_light_probes_in_array { 8 } else { 0 },
      ),
    )
    binding_array_entries.push(
      mesh_view_sampler_entry(
        2,
        "environment_map_sampler",
        MeshViewSamplerBindingType::Filtering,
      ),
    )
  }
  if layout_key.contains(MESH_VIEW_LAYOUT_IRRADIANCE_VOLUME) &&
    irradiance_volumes_usable {
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
