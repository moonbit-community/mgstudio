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
pub struct MeshletViewMaterialsMainOpaquePass {
  mut entries : Array[(Int, Int, Int)]
}

///|
pub let ecs_key_meshlet_view_materials_main_opaque_pass : @ecs.ComponentKey[
  MeshletViewMaterialsMainOpaquePass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_main_opaque_pass",
)

///|
pub fn MeshletViewMaterialsMainOpaquePass::default() -> MeshletViewMaterialsMainOpaquePass {
  MeshletViewMaterialsMainOpaquePass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsMainOpaquePass::push(
  self : MeshletViewMaterialsMainOpaquePass,
  material_bin : (Int, Int, Int),
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
  mut entries : Array[(Int, Int, Int)]
}

///|
pub let ecs_key_meshlet_view_materials_prepass : @ecs.ComponentKey[
  MeshletViewMaterialsPrepass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_prepass",
)

///|
pub fn MeshletViewMaterialsPrepass::default() -> MeshletViewMaterialsPrepass {
  MeshletViewMaterialsPrepass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsPrepass::push(
  self : MeshletViewMaterialsPrepass,
  material_bin : (Int, Int, Int),
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
  mut entries : Array[(Int, Int, Int)]
}

///|
pub let ecs_key_meshlet_view_materials_deferred_gbuffer_prepass : @ecs.ComponentKey[
  MeshletViewMaterialsDeferredGBufferPrepass,
] = @ecs.register_component(
  debug_name="render3d.meshlet_view_materials_deferred_gbuffer_prepass",
)

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::default() -> MeshletViewMaterialsDeferredGBufferPrepass {
  MeshletViewMaterialsDeferredGBufferPrepass::{ entries: [] }
}

///|
pub fn MeshletViewMaterialsDeferredGBufferPrepass::push(
  self : MeshletViewMaterialsDeferredGBufferPrepass,
  material_bin : (Int, Int, Int),
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
pub fn MeshletViewMaterialPipelineKey::default() -> MeshletViewMaterialPipelineKey {
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
  material_asset_id : Int,
) -> Int {
  let key_bits = meshlet_view_key_bits(view_key)
  let _safe_asset_id = meshlet_material_non_negative(material_asset_id)
  pipeline_base + pass_variant * 1_000_000 + key_bits
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
  view_key? : MeshletViewMaterialPipelineKey = MeshletViewMaterialPipelineKey::default(),
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
    let pipeline_id = meshlet_material_pipeline_id(
      1000,
      1,
      view_key,
      material_input.material_asset_id,
    )
    if queued_material_ids.contains(material_input.material_id) {
      continue
    }
    queued_material_ids.insert(material_input.material_id)
    view_materials.push(
      (
        material_input.material_id,
        pipeline_id,
        material_input.material_bind_group_id,
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
  view_key? : MeshletViewMaterialPipelineKey = MeshletViewMaterialPipelineKey::default(),
  deferred_enabled? : Bool = true,
) -> Unit {
  prepass_materials.clear()
  deferred_prepass_materials.clear()
  let queued_prepass_material_ids = @utils.IntBitSet::new()
  let queued_deferred_material_ids = @utils.IntBitSet::new()
  for material_input in material_inputs {
    if !(material_input.alpha_mode is @material.AlphaMode3d::Opaque) {
      continue
    }
    if material_input.reads_view_transmission_texture {
      continue
    }
    let material_wants_deferred = material_input.opaque_render_method
      is @material.OpaqueRendererMethod::Deferred
    if deferred_enabled && view_key.deferred_prepass && material_wants_deferred {
      let prepass_view_key = view_key.for_meshlet_prepass(true)
      if queued_deferred_material_ids.contains(material_input.material_id) {
        continue
      }
      queued_deferred_material_ids.insert(material_input.material_id)
      let pipeline_id = meshlet_material_pipeline_id(
        3000,
        3,
        prepass_view_key,
        material_input.material_asset_id,
      )
      deferred_prepass_materials.push(
        (
          material_input.material_id,
          pipeline_id,
          material_input.material_bind_group_id,
        ),
      )
      continue
    }
    if !view_key.normal_prepass && !view_key.motion_vector_prepass {
      continue
    }
    if queued_prepass_material_ids.contains(material_input.material_id) {
      continue
    }
    queued_prepass_material_ids.insert(material_input.material_id)
    let prepass_view_key = view_key.for_meshlet_prepass(false)
    let pipeline_id = meshlet_material_pipeline_id(
      2000,
      2,
      prepass_view_key,
      material_input.material_asset_id,
    )
    prepass_materials.push(
      (
        material_input.material_id,
        pipeline_id,
        material_input.material_bind_group_id,
      ),
    )
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
pub impl @ecs.Component for MeshletViewMaterialsMainOpaquePass with component() {
  ecs_key_meshlet_view_materials_main_opaque_pass
}

///|
pub impl @ecs.Component for MeshletViewMaterialsPrepass with component() {
  ecs_key_meshlet_view_materials_prepass
}

///|
pub impl @ecs.Component for MeshletViewMaterialsDeferredGBufferPrepass with component() {
  ecs_key_meshlet_view_materials_deferred_gbuffer_prepass
}
