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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/material_pipeline_prepare.rs`.

///|
pub(all) enum MeshletMaterialPassVariant {
  MainOpaque
  Prepass
  DeferredGBufferPrepass
}

///|
pub(all) enum MeshletMaterialViewLayoutKind {
  MeshView
  PrepassNoMotionVectors
  PrepassMotionVectors
}

///|
pub(all) enum MeshletMaterialFragmentShaderKind {
  MeshletMaterial
  MeshletFragmentOverride
  MeshletPrepassFragmentOverride
  MeshletDeferredFragmentOverride
}

///|
pub fn meshlet_fake_vertex_buffer_layout() -> @mesh.MeshVertexBufferLayout {
  let position = @mesh.MeshVertexAttribute::position()
  let normal = @mesh.MeshVertexAttribute::normal()
  let uv_0 = @mesh.MeshVertexAttribute::uv_0()
  let tangent = @mesh.MeshVertexAttribute::tangent()
  @mesh.MeshVertexBufferLayout::new(
    attribute_ids=[position.id(), normal.id(), uv_0.id(), tangent.id()],
    layout=@mesh.VertexBufferLayout::new(
      array_stride=48,
      step_mode=@mesh.MeshVertexStepMode::Vertex,
      attributes=[
        @mesh.VertexAttribute::new(
          offset=0,
          format=position.format(),
          shader_location=0,
        ),
        @mesh.VertexAttribute::new(
          offset=12,
          format=normal.format(),
          shader_location=1,
        ),
        @mesh.VertexAttribute::new(
          offset=24,
          format=uv_0.format(),
          shader_location=2,
        ),
        @mesh.VertexAttribute::new(
          offset=32,
          format=tangent.format(),
          shader_location=3,
        ),
      ],
    ),
  )
}

///|
pub struct MeshletMaterialPipelineDescriptor {
  pass_variant : MeshletMaterialPassVariant
  view_key : MeshletViewMaterialPipelineKey
  view_layout_kind : MeshletMaterialViewLayoutKind
  fake_vertex_buffer_layout : @mesh.MeshVertexBufferLayout
  layout_count : Int
  uses_binding_array_layout : Bool
  uses_empty_bind_group_layout : Bool
  uses_material_shade_layout : Bool
  material_layout_id : Int
  vertex_shader_label : String
  fragment_shader_kind : MeshletMaterialFragmentShaderKind
  shader_def_meshlet_material_pass : Bool
  shader_def_count : Int
  uses_material_fragment_entry_point : Bool
  depth_format_depth16_unorm : Bool
  depth_write_enabled : Bool
  depth_compare_equal : Bool
  zero_initialize_workgroup_memory : Bool
}

///|
pub fn MeshletMaterialPipelineDescriptor::new(
  pass_variant? : MeshletMaterialPassVariant = MeshletMaterialPassVariant::MainOpaque,
  view_key? : MeshletViewMaterialPipelineKey = MeshletViewMaterialPipelineKey::MeshletViewMaterialPipelineKey(),
  view_layout_kind? : MeshletMaterialViewLayoutKind = MeshletMaterialViewLayoutKind::MeshView,
  fake_vertex_buffer_layout? : @mesh.MeshVertexBufferLayout = meshlet_fake_vertex_buffer_layout(),
  layout_count? : Int = 4,
  uses_binding_array_layout? : Bool = true,
  uses_empty_bind_group_layout? : Bool = false,
  uses_material_shade_layout? : Bool = true,
  material_layout_id? : Int = 0,
  vertex_shader_label? : String = "pbr/meshlet/meshlet_mesh_material.wgsl",
  fragment_shader_kind? : MeshletMaterialFragmentShaderKind = MeshletMaterialFragmentShaderKind::MeshletMaterial,
  shader_def_meshlet_material_pass? : Bool = true,
  shader_def_count? : Int = 1,
  uses_material_fragment_entry_point? : Bool = true,
  depth_format_depth16_unorm? : Bool = true,
  depth_write_enabled? : Bool = false,
  depth_compare_equal? : Bool = true,
  zero_initialize_workgroup_memory? : Bool = false,
) -> MeshletMaterialPipelineDescriptor {
  MeshletMaterialPipelineDescriptor::{
    pass_variant,
    view_key,
    view_layout_kind,
    fake_vertex_buffer_layout,
    layout_count: meshlet_material_non_negative(layout_count),
    uses_binding_array_layout,
    uses_empty_bind_group_layout,
    uses_material_shade_layout,
    material_layout_id: meshlet_material_non_negative(material_layout_id),
    vertex_shader_label,
    fragment_shader_kind,
    shader_def_meshlet_material_pass,
    shader_def_count: meshlet_material_non_negative(shader_def_count),
    uses_material_fragment_entry_point,
    depth_format_depth16_unorm,
    depth_write_enabled,
    depth_compare_equal,
    zero_initialize_workgroup_memory,
  }
}

///|
pub struct MeshletViewMaterialEntry {
  material_id : Int
  material_pipeline_id : Int
  material_bind_group : Int
  descriptor : MeshletMaterialPipelineDescriptor
}

///|
pub struct MeshletViewMaterialsMainOpaquePass {
  mut entries : Array[MeshletViewMaterialEntry]
}

///|
pub let ecs_key_meshlet_view_materials_main_opaque_pass : @ecs.ComponentKey[
  MeshletViewMaterialsMainOpaquePass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_main_opaque_pass",
)

///|
pub fn MeshletViewMaterialsMainOpaquePass::MeshletViewMaterialsMainOpaquePass() -> MeshletViewMaterialsMainOpaquePass {
  MeshletViewMaterialsMainOpaquePass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsMainOpaquePass::push(
  self : MeshletViewMaterialsMainOpaquePass,
  material_bin : MeshletViewMaterialEntry,
) -> Unit {
  self.entries.push(material_bin)
}

///|
pub fn MeshletViewMaterialsMainOpaquePass::len(
  self : MeshletViewMaterialsMainOpaquePass,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshletViewMaterialsMainOpaquePass::clear(
  self : MeshletViewMaterialsMainOpaquePass,
) -> Unit {
  self.entries = []
}

///|
pub struct MeshletViewMaterialsPrepass {
  mut entries : Array[MeshletViewMaterialEntry]
}

///|
pub let ecs_key_meshlet_view_materials_prepass : @ecs.ComponentKey[
  MeshletViewMaterialsPrepass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_prepass",
)

///|
pub fn MeshletViewMaterialsPrepass::MeshletViewMaterialsPrepass() -> MeshletViewMaterialsPrepass {
  MeshletViewMaterialsPrepass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsPrepass::push(
  self : MeshletViewMaterialsPrepass,
  material_bin : MeshletViewMaterialEntry,
) -> Unit {
  self.entries.push(material_bin)
}

///|
pub fn MeshletViewMaterialsPrepass::len(
  self : MeshletViewMaterialsPrepass,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshletViewMaterialsPrepass::clear(
  self : MeshletViewMaterialsPrepass,
) -> Unit {
  self.entries = []
}

///|
pub struct MeshletViewMaterialsDeferredGBufferPrepass {
  mut entries : Array[MeshletViewMaterialEntry]
}

///|
pub let ecs_key_meshlet_view_materials_deferred_gbuffer_prepass : @ecs.ComponentKey[
  MeshletViewMaterialsDeferredGBufferPrepass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_deferred_gbuffer_prepass",
)

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::MeshletViewMaterialsDeferredGBufferPrepass() -> MeshletViewMaterialsDeferredGBufferPrepass {
  MeshletViewMaterialsDeferredGBufferPrepass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::push(
  self : MeshletViewMaterialsDeferredGBufferPrepass,
  material_bin : MeshletViewMaterialEntry,
) -> Unit {
  self.entries.push(material_bin)
}

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::len(
  self : MeshletViewMaterialsDeferredGBufferPrepass,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::clear(
  self : MeshletViewMaterialsDeferredGBufferPrepass,
) -> Unit {
  self.entries = []
}

///|
pub struct MeshletViewMaterialPipelineKey {
  hdr : Bool
  normal_prepass : Bool
  depth_prepass : Bool
  motion_vector_prepass : Bool
  deferred_prepass : Bool
  temporal_jitter : Bool
  projection_type : Int
  shadow_filter_method : Int
  tonemap_in_shader : Bool
  tonemapping_mode : Int
  deband_dither : Bool
  environment_map : Bool
  irradiance_volume : Bool
  ssao : Bool
  distance_fog : Bool
}

///|
pub fn MeshletViewMaterialPipelineKey::equal(
  self : MeshletViewMaterialPipelineKey,
  other : MeshletViewMaterialPipelineKey,
) -> Bool {
  self.hdr == other.hdr &&
  self.normal_prepass == other.normal_prepass &&
  self.depth_prepass == other.depth_prepass &&
  self.motion_vector_prepass == other.motion_vector_prepass &&
  self.deferred_prepass == other.deferred_prepass &&
  self.temporal_jitter == other.temporal_jitter &&
  self.projection_type == other.projection_type &&
  self.shadow_filter_method == other.shadow_filter_method &&
  self.tonemap_in_shader == other.tonemap_in_shader &&
  self.tonemapping_mode == other.tonemapping_mode &&
  self.deband_dither == other.deband_dither &&
  self.environment_map == other.environment_map &&
  self.irradiance_volume == other.irradiance_volume &&
  self.ssao == other.ssao &&
  self.distance_fog == other.distance_fog
}

///|
pub fn MeshletViewMaterialPipelineKey::new(
  hdr? : Bool = false,
  normal_prepass? : Bool = false,
  depth_prepass? : Bool = false,
  motion_vector_prepass? : Bool = false,
  deferred_prepass? : Bool = false,
  temporal_jitter? : Bool = false,
  projection_type? : Int = 0,
  shadow_filter_method? : Int = 0,
  tonemap_in_shader? : Bool = false,
  tonemapping_mode? : Int = 0,
  deband_dither? : Bool = false,
  environment_map? : Bool = false,
  irradiance_volume? : Bool = false,
  ssao? : Bool = false,
  distance_fog? : Bool = false,
) -> MeshletViewMaterialPipelineKey {
  let projection_type = if projection_type < 0 { 0 } else { projection_type }
  let shadow_filter_method = if shadow_filter_method < 0 {
    0
  } else {
    shadow_filter_method
  }
  let tonemapping_mode = if tonemapping_mode < 0 { 0 } else { tonemapping_mode }
  MeshletViewMaterialPipelineKey::{
    hdr,
    normal_prepass,
    depth_prepass,
    motion_vector_prepass,
    deferred_prepass,
    temporal_jitter,
    projection_type,
    shadow_filter_method,
    tonemap_in_shader,
    tonemapping_mode,
    deband_dither,
    environment_map,
    irradiance_volume,
    ssao,
    distance_fog,
  }
}

///|
pub fn MeshletViewMaterialPipelineKey::MeshletViewMaterialPipelineKey() -> MeshletViewMaterialPipelineKey {
  MeshletViewMaterialPipelineKey::new()
}

///|
pub fn MeshletViewMaterialPipelineKey::with_deferred_prepass(
  self : MeshletViewMaterialPipelineKey,
  deferred_prepass : Bool,
) -> MeshletViewMaterialPipelineKey {
  MeshletViewMaterialPipelineKey::{ ..self, deferred_prepass, }
}

///|
pub fn MeshletViewMaterialPipelineKey::for_meshlet_prepass(
  self : MeshletViewMaterialPipelineKey,
  deferred_prepass : Bool,
) -> MeshletViewMaterialPipelineKey {
  MeshletViewMaterialPipelineKey::{
    hdr: self.hdr,
    normal_prepass: self.normal_prepass,
    depth_prepass: false,
    motion_vector_prepass: self.motion_vector_prepass,
    deferred_prepass,
    temporal_jitter: false,
    projection_type: 0,
    shadow_filter_method: 0,
    tonemap_in_shader: false,
    tonemapping_mode: 0,
    deband_dither: false,
    environment_map: false,
    irradiance_volume: false,
    ssao: false,
    distance_fog: false,
  }
}

///|
pub struct MeshletPreparedMaterialInput {
  material_id : Int
  material_asset_id : Int
  opaque_render_method : @material.OpaqueRendererMethod
  alpha_mode : @material.AlphaMode3d
  reads_view_transmission_texture : Bool
  material_bind_group_id : Int
  material_layout_id : Int
  material_shader_def_count : Int
  has_material_layout : Bool
  has_material_bind_group_allocator : Bool
  has_material_bind_group : Bool
  has_meshlet_fragment_shader_override : Bool
  has_meshlet_prepass_fragment_shader_override : Bool
  has_meshlet_deferred_fragment_shader_override : Bool
}

///|
fn meshlet_material_non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub fn MeshletPreparedMaterialInput::new(
  material_id : Int,
  material_asset_id : Int,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    material_id: meshlet_material_non_negative(material_id),
    material_asset_id: meshlet_material_non_negative(material_asset_id),
    opaque_render_method: @material.OpaqueRendererMethod::Forward,
    alpha_mode: @material.AlphaMode3d::Opaque,
    reads_view_transmission_texture: false,
    material_bind_group_id: meshlet_material_non_negative(material_id),
    material_layout_id: 0,
    material_shader_def_count: 0,
    has_material_layout: true,
    has_material_bind_group_allocator: true,
    has_material_bind_group: true,
    has_meshlet_fragment_shader_override: false,
    has_meshlet_prepass_fragment_shader_override: false,
    has_meshlet_deferred_fragment_shader_override: false,
  }
}

///|
pub fn MeshletPreparedMaterialInput::with_opaque_render_method(
  self : MeshletPreparedMaterialInput,
  opaque_render_method : @material.OpaqueRendererMethod,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{ ..self, opaque_render_method, }
}

///|
pub fn MeshletPreparedMaterialInput::with_alpha_mode(
  self : MeshletPreparedMaterialInput,
  alpha_mode : @material.AlphaMode3d,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{ ..self, alpha_mode, }
}

///|
pub fn MeshletPreparedMaterialInput::with_reads_view_transmission_texture(
  self : MeshletPreparedMaterialInput,
  reads_view_transmission_texture : Bool,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{ ..self, reads_view_transmission_texture, }
}

///|
pub fn MeshletPreparedMaterialInput::with_material_bind_group_id(
  self : MeshletPreparedMaterialInput,
  material_bind_group_id : Int,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    ..self,
    material_bind_group_id: meshlet_material_non_negative(
      material_bind_group_id,
    ),
  }
}

///|
pub fn MeshletPreparedMaterialInput::with_material_layout_id(
  self : MeshletPreparedMaterialInput,
  material_layout_id : Int,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    ..self,
    material_layout_id: meshlet_material_non_negative(material_layout_id),
  }
}

///|
pub fn MeshletPreparedMaterialInput::with_material_shader_def_count(
  self : MeshletPreparedMaterialInput,
  material_shader_def_count : Int,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    ..self,
    material_shader_def_count: meshlet_material_non_negative(
      material_shader_def_count,
    ),
  }
}

///|
pub fn MeshletPreparedMaterialInput::without_material_layout(
  self : MeshletPreparedMaterialInput,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{ ..self, has_material_layout: false }
}

///|
pub fn MeshletPreparedMaterialInput::without_material_bind_group_allocator(
  self : MeshletPreparedMaterialInput,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    ..self,
    has_material_bind_group_allocator: false,
  }
}

///|
pub fn MeshletPreparedMaterialInput::without_material_bind_group(
  self : MeshletPreparedMaterialInput,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{ ..self, has_material_bind_group: false }
}

///|
pub fn MeshletPreparedMaterialInput::with_meshlet_fragment_shader_override(
  self : MeshletPreparedMaterialInput,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    ..self,
    has_meshlet_fragment_shader_override: true,
  }
}

///|
pub fn MeshletPreparedMaterialInput::with_meshlet_prepass_fragment_shader_override(
  self : MeshletPreparedMaterialInput,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    ..self,
    has_meshlet_prepass_fragment_shader_override: true,
  }
}

///|
pub fn MeshletPreparedMaterialInput::with_meshlet_deferred_fragment_shader_override(
  self : MeshletPreparedMaterialInput,
) -> MeshletPreparedMaterialInput {
  MeshletPreparedMaterialInput::{
    ..self,
    has_meshlet_deferred_fragment_shader_override: true,
  }
}

///|
pub fn meshlet_material_prepare_entry_count(
  main_opaque : MeshletViewMaterialsMainOpaquePass,
  prepass : MeshletViewMaterialsPrepass,
  deferred_prepass : MeshletViewMaterialsDeferredGBufferPrepass,
) -> Int {
  main_opaque.entries.length() +
  prepass.entries.length() +
  deferred_prepass.entries.length()
}

///|
fn meshlet_view_key_bits(view_key : MeshletViewMaterialPipelineKey) -> Int {
  let mut bits = 0
  if view_key.hdr {
    bits = bits | 1
  }
  if view_key.normal_prepass {
    bits = bits | 2
  }
  if view_key.depth_prepass {
    bits = bits | 4
  }
  if view_key.motion_vector_prepass {
    bits = bits | 8
  }
  if view_key.deferred_prepass {
    bits = bits | 16
  }
  if view_key.temporal_jitter {
    bits = bits | 32
  }
  if view_key.tonemap_in_shader {
    bits = bits | 64
  }
  if view_key.deband_dither {
    bits = bits | 128
  }
  if view_key.environment_map {
    bits = bits | 256
  }
  if view_key.irradiance_volume {
    bits = bits | 512
  }
  if view_key.ssao {
    bits = bits | 1024
  }
  if view_key.distance_fog {
    bits = bits | 2048
  }
  bits = bits | (view_key.projection_type << 12)
  bits = bits | (view_key.shadow_filter_method << 16)
  bits = bits | (view_key.tonemapping_mode << 20)
  bits
}

///|
fn meshlet_material_pipeline_id(
  pipeline_base : Int,
  pass_variant : Int,
  view_key : MeshletViewMaterialPipelineKey,
  material_input : MeshletPreparedMaterialInput,
) -> Int {
  let key_bits = meshlet_view_key_bits(view_key)
  let meshlet_shader_bits = (if material_input.has_meshlet_fragment_shader_override {
      1
    } else {
      0
    }) |
    (if material_input.has_meshlet_prepass_fragment_shader_override {
      2
    } else {
      0
    }) |
    (if material_input.has_meshlet_deferred_fragment_shader_override {
      4
    } else {
      0
    })
  pipeline_base +
  pass_variant * 1_000_000 +
  key_bits +
  (meshlet_material_non_negative(material_input.material_layout_id) << 24) +
  (meshlet_shader_bits << 21)
}

///|
fn meshlet_material_shader_def_count(
  material_input : MeshletPreparedMaterialInput,
) -> Int {
  material_input.material_shader_def_count + 1
}

///|
fn meshlet_main_opaque_pipeline_descriptor(
  view_key : MeshletViewMaterialPipelineKey,
  material_input : MeshletPreparedMaterialInput,
) -> MeshletMaterialPipelineDescriptor {
  MeshletMaterialPipelineDescriptor::{
    pass_variant: MeshletMaterialPassVariant::MainOpaque,
    view_key,
    view_layout_kind: MeshletMaterialViewLayoutKind::MeshView,
    fake_vertex_buffer_layout: meshlet_fake_vertex_buffer_layout(),
    layout_count: 4,
    uses_binding_array_layout: true,
    uses_empty_bind_group_layout: false,
    uses_material_shade_layout: true,
    material_layout_id: material_input.material_layout_id,
    vertex_shader_label: "pbr/meshlet/meshlet_mesh_material.wgsl",
    fragment_shader_kind: if material_input.has_meshlet_fragment_shader_override {
      MeshletMaterialFragmentShaderKind::MeshletFragmentOverride
    } else {
      MeshletMaterialFragmentShaderKind::MeshletMaterial
    },
    shader_def_meshlet_material_pass: true,
    shader_def_count: meshlet_material_shader_def_count(material_input),
    uses_material_fragment_entry_point: true,
    depth_format_depth16_unorm: true,
    depth_write_enabled: false,
    depth_compare_equal: true,
    zero_initialize_workgroup_memory: false,
  }
}

///|
fn meshlet_prepass_view_layout_kind(
  view_key : MeshletViewMaterialPipelineKey,
) -> MeshletMaterialViewLayoutKind {
  if view_key.motion_vector_prepass {
    MeshletMaterialViewLayoutKind::PrepassMotionVectors
  } else {
    MeshletMaterialViewLayoutKind::PrepassNoMotionVectors
  }
}

///|
fn meshlet_prepass_fragment_shader_kind(
  view_key : MeshletViewMaterialPipelineKey,
  material_input : MeshletPreparedMaterialInput,
) -> MeshletMaterialFragmentShaderKind {
  if view_key.deferred_prepass {
    if material_input.has_meshlet_deferred_fragment_shader_override {
      MeshletMaterialFragmentShaderKind::MeshletDeferredFragmentOverride
    } else {
      MeshletMaterialFragmentShaderKind::MeshletMaterial
    }
  } else if material_input.has_meshlet_prepass_fragment_shader_override {
    MeshletMaterialFragmentShaderKind::MeshletPrepassFragmentOverride
  } else {
    MeshletMaterialFragmentShaderKind::MeshletMaterial
  }
}

///|
fn meshlet_material_fragment_shader_is_meshlet_material(
  kind : MeshletMaterialFragmentShaderKind,
) -> Bool {
  kind is MeshletMaterialFragmentShaderKind::MeshletMaterial
}

///|
fn meshlet_prepass_pipeline_descriptor(
  pass_variant : MeshletMaterialPassVariant,
  view_key : MeshletViewMaterialPipelineKey,
  material_input : MeshletPreparedMaterialInput,
) -> MeshletMaterialPipelineDescriptor {
  let fragment_shader_kind = meshlet_prepass_fragment_shader_kind(
    view_key, material_input,
  )
  MeshletMaterialPipelineDescriptor::{
    pass_variant,
    view_key,
    view_layout_kind: meshlet_prepass_view_layout_kind(view_key),
    fake_vertex_buffer_layout: meshlet_fake_vertex_buffer_layout(),
    layout_count: 4,
    uses_binding_array_layout: false,
    uses_empty_bind_group_layout: true,
    uses_material_shade_layout: true,
    material_layout_id: material_input.material_layout_id,
    vertex_shader_label: "pbr/meshlet/meshlet_mesh_material.wgsl",
    fragment_shader_kind,
    shader_def_meshlet_material_pass: true,
    shader_def_count: meshlet_material_shader_def_count(material_input),
    uses_material_fragment_entry_point: meshlet_material_fragment_shader_is_meshlet_material(
      fragment_shader_kind,
    ),
    depth_format_depth16_unorm: true,
    depth_write_enabled: false,
    depth_compare_equal: true,
    zero_initialize_workgroup_memory: false,
  }
}

///|
pub fn MeshletViewMaterialEntry::new(
  material_id : Int,
  material_pipeline_id : Int,
  material_bind_group : Int,
  descriptor : MeshletMaterialPipelineDescriptor,
) -> MeshletViewMaterialEntry {
  MeshletViewMaterialEntry::{
    material_id: meshlet_material_non_negative(material_id),
    material_pipeline_id,
    material_bind_group: meshlet_material_non_negative(material_bind_group),
    descriptor,
  }
}

///|
fn meshlet_material_input_has_required_binding_state(
  material_input : MeshletPreparedMaterialInput,
) -> Bool {
  material_input.has_material_layout &&
  material_input.has_material_bind_group_allocator &&
  material_input.has_material_bind_group
}

///|
fn meshlet_material_inputs_from_ids(
  material_ids : Array[Int],
) -> Array[MeshletPreparedMaterialInput] {
  let material_inputs : Array[MeshletPreparedMaterialInput] = []
  for material_id in material_ids {
    material_inputs.push(
      MeshletPreparedMaterialInput::new(material_id, material_id),
    )
  }
  material_inputs
}

///|
pub fn prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(
  view_materials : MeshletViewMaterialsMainOpaquePass,
  material_inputs : Array[MeshletPreparedMaterialInput],
  view_key? : MeshletViewMaterialPipelineKey = MeshletViewMaterialPipelineKey::MeshletViewMaterialPipelineKey(),
) -> Unit {
  view_materials.clear()
  let queued_material_ids = @utils.IntBitSet::new()
  for material_input in material_inputs {
    if !(material_input.alpha_mode is @material.AlphaMode3d::Opaque) {
      continue
    }
    if material_input.reads_view_transmission_texture {
      continue
    }
    if material_input.opaque_render_method !=
      @material.OpaqueRendererMethod::Forward {
      continue
    }
    if !meshlet_material_input_has_required_binding_state(material_input) {
      continue
    }
    let pipeline_id = meshlet_material_pipeline_id(
      1000, 1, view_key, material_input,
    )
    if queued_material_ids.contains(material_input.material_id) {
      continue
    }
    queued_material_ids.insert(material_input.material_id)
    view_materials.push(
      MeshletViewMaterialEntry::new(
        material_input.material_id,
        pipeline_id,
        material_input.material_bind_group_id,
        meshlet_main_opaque_pipeline_descriptor(view_key, material_input),
      ),
    )
  }
}

///|
pub fn prepare_material_meshlet_meshes_main_opaque_pass(
  view_materials : MeshletViewMaterialsMainOpaquePass,
  material_ids : Array[Int],
) -> Unit {
  prepare_material_meshlet_meshes_main_opaque_pass_with_inputs(
    view_materials,
    meshlet_material_inputs_from_ids(material_ids),
  )
}

///|
pub fn prepare_material_meshlet_meshes_prepass_with_inputs(
  prepass_materials : MeshletViewMaterialsPrepass,
  deferred_prepass_materials : MeshletViewMaterialsDeferredGBufferPrepass,
  material_inputs : Array[MeshletPreparedMaterialInput],
  view_key? : MeshletViewMaterialPipelineKey = MeshletViewMaterialPipelineKey::MeshletViewMaterialPipelineKey(),
  deferred_enabled? : Bool = true,
) -> Unit {
  prepass_materials.clear()
  deferred_prepass_materials.clear()
  let queued_prepass_material_ids = @utils.IntBitSet::new()
  let queued_deferred_material_ids = @utils.IntBitSet::new()
  let view_has_deferred_prepass = view_key.deferred_prepass
  let mut working_view_key = view_key.for_meshlet_prepass(false)
  for material_input in material_inputs {
    if !(material_input.alpha_mode is @material.AlphaMode3d::Opaque) {
      continue
    }
    if material_input.reads_view_transmission_texture {
      continue
    }
    if !meshlet_material_input_has_required_binding_state(material_input) {
      continue
    }
    let material_wants_deferred = material_input.opaque_render_method
      is @material.OpaqueRendererMethod::Deferred
    if deferred_enabled && view_has_deferred_prepass && material_wants_deferred {
      working_view_key = working_view_key.with_deferred_prepass(true)
    } else if !working_view_key.normal_prepass &&
      !working_view_key.motion_vector_prepass {
      continue
    }
    let route_deferred = working_view_key.deferred_prepass
    if route_deferred {
      if queued_deferred_material_ids.contains(material_input.material_id) {
        continue
      }
      queued_deferred_material_ids.insert(material_input.material_id)
    } else {
      if queued_prepass_material_ids.contains(material_input.material_id) {
        continue
      }
      queued_prepass_material_ids.insert(material_input.material_id)
    }
    let pass_variant = if route_deferred {
      MeshletMaterialPassVariant::DeferredGBufferPrepass
    } else {
      MeshletMaterialPassVariant::Prepass
    }
    let pipeline_id = meshlet_material_pipeline_id(
      if route_deferred {
        3000
      } else {
        2000
      },
      if route_deferred {
        3
      } else {
        2
      },
      working_view_key,
      material_input,
    )
    let entry = MeshletViewMaterialEntry::new(
      material_input.material_id,
      pipeline_id,
      material_input.material_bind_group_id,
      meshlet_prepass_pipeline_descriptor(
        pass_variant, working_view_key, material_input,
      ),
    )
    if route_deferred {
      deferred_prepass_materials.push(entry)
    } else {
      prepass_materials.push(entry)
    }
  }
}

///|
pub fn prepare_material_meshlet_meshes_prepass(
  prepass_materials : MeshletViewMaterialsPrepass,
  deferred_prepass_materials : MeshletViewMaterialsDeferredGBufferPrepass,
  material_ids : Array[Int],
  deferred_enabled? : Bool = true,
) -> Unit {
  prepare_material_meshlet_meshes_prepass_with_inputs(
    prepass_materials,
    deferred_prepass_materials,
    meshlet_material_inputs_from_ids(material_ids),
    deferred_enabled~,
  )
}

///|
pub impl @ecs.Component for MeshletViewMaterialsMainOpaquePass with fn component() {
  ecs_key_meshlet_view_materials_main_opaque_pass
}

///|
pub impl @ecs.Component for MeshletViewMaterialsPrepass with fn component() {
  ecs_key_meshlet_view_materials_prepass
}

///|
pub impl @ecs.Component for MeshletViewMaterialsDeferredGBufferPrepass with fn component() {
  ecs_key_meshlet_view_materials_deferred_gbuffer_prepass
}
