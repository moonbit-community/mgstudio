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
// Bevy source: `bevy/crates/bevy_pbr/src/material_bind_groups.rs`.

///|
pub(all) struct FallbackBindlessResources {
  filtering_sampler : @wgpu.Sampler
  non_filtering_sampler : @wgpu.Sampler
  comparison_sampler : @wgpu.Sampler
}

///|
pub let ecs_key_fallback_bindless_resources : @ecs.ResourceKey[
  FallbackBindlessResources,
] = @ecs.register_resource(debug_name="mgstudio_pbr::FallbackBindlessResources")

///|
pub impl @app.Resource for FallbackBindlessResources with fn resource() {
  ecs_key_fallback_bindless_resources
}

///|
pub struct StandardMaterialTextureFeatureSet {
  pbr_transmission_textures : Bool
  pbr_multi_layer_material_textures : Bool
  pbr_anisotropy_texture : Bool
  pbr_specular_textures : Bool
} derive(Eq, Debug)

///|
pub fn StandardMaterialTextureFeatureSet::StandardMaterialTextureFeatureSet(
  pbr_transmission_textures? : Bool = false,
  pbr_multi_layer_material_textures? : Bool = false,
  pbr_anisotropy_texture? : Bool = false,
  pbr_specular_textures? : Bool = false,
) -> StandardMaterialTextureFeatureSet {
  StandardMaterialTextureFeatureSet::{
    pbr_transmission_textures,
    pbr_multi_layer_material_textures,
    pbr_anisotropy_texture,
    pbr_specular_textures,
  }
}

///|
pub fn standard_material_default_texture_feature_set() -> StandardMaterialTextureFeatureSet {
  StandardMaterialTextureFeatureSet::StandardMaterialTextureFeatureSet(
    pbr_anisotropy_texture=true,
  )
}

///|
pub fn StandardMaterialTextureFeatureSet::pbr_transmission_textures(
  self : StandardMaterialTextureFeatureSet,
) -> Bool {
  self.pbr_transmission_textures
}

///|
pub fn StandardMaterialTextureFeatureSet::pbr_multi_layer_material_textures(
  self : StandardMaterialTextureFeatureSet,
) -> Bool {
  self.pbr_multi_layer_material_textures
}

///|
pub fn StandardMaterialTextureFeatureSet::pbr_anisotropy_texture(
  self : StandardMaterialTextureFeatureSet,
) -> Bool {
  self.pbr_anisotropy_texture
}

///|
pub fn StandardMaterialTextureFeatureSet::pbr_specular_textures(
  self : StandardMaterialTextureFeatureSet,
) -> Bool {
  self.pbr_specular_textures
}

///|
pub fn FallbackBindlessResources::filtering_sampler(
  self : FallbackBindlessResources,
) -> @wgpu.Sampler {
  self.filtering_sampler
}

///|
pub fn FallbackBindlessResources::non_filtering_sampler(
  self : FallbackBindlessResources,
) -> @wgpu.Sampler {
  self.non_filtering_sampler
}

///|
pub fn FallbackBindlessResources::comparison_sampler(
  self : FallbackBindlessResources,
) -> @wgpu.Sampler {
  self.comparison_sampler
}

///|
fn pbr_create_fallback_filtering_sampler(
  device : @wgpu.Device,
) -> @wgpu.Sampler {
  let sampler = device.create_sampler_u32(
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.FILTER_MODE_NEAREST,
    @wgpu.FILTER_MODE_NEAREST,
    @wgpu.MIPMAP_FILTER_MODE_NEAREST,
  )
  sampler.set_label("fallback filtering sampler")
  sampler
}

///|
fn pbr_create_fallback_non_filtering_sampler(
  device : @wgpu.Device,
) -> @wgpu.Sampler {
  let sampler = device.create_sampler_u32(
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.FILTER_MODE_NEAREST,
    @wgpu.FILTER_MODE_NEAREST,
    @wgpu.MIPMAP_FILTER_MODE_NEAREST,
  )
  sampler.set_label("fallback non-filtering sampler")
  sampler
}

///|
fn pbr_create_fallback_comparison_sampler(
  device : @wgpu.Device,
) -> @wgpu.Sampler {
  let sampler = device.create_sampler_u32(
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.ADDRESS_MODE_CLAMP_TO_EDGE,
    @wgpu.FILTER_MODE_NEAREST,
    @wgpu.FILTER_MODE_NEAREST,
    @wgpu.MIPMAP_FILTER_MODE_NEAREST,
    compare_u32=@wgpu.COMPARE_FUNCTION_ALWAYS,
  )
  sampler.set_label("fallback comparison sampler")
  sampler
}

///|
pub fn init_fallback_bindless_resources(world : @ecs.World) -> Unit {
  guard world.get_resource(@render.render_device_resource_key)
    is Some(render_device) else {
    return
  }
  let device = render_device.wgpu_device()
  world.insert_resource(ecs_key_fallback_bindless_resources, FallbackBindlessResources::{
    filtering_sampler: pbr_create_fallback_filtering_sampler(device),
    non_filtering_sampler: pbr_create_fallback_non_filtering_sampler(device),
    comparison_sampler: pbr_create_fallback_comparison_sampler(device),
  })
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/pbr_material.rs`
// `StandardMaterial` derives `AsBindGroup` with the binding indices mirrored
// here for the descriptor-level material pipeline specializer.
fn standard_material_texture_layout_entry(
  binding : Int,
  fragment : UInt,
) -> @render_resource.BindGroupLayoutEntry {
  @render_resource.BindGroupLayoutEntry::new(
    binding,
    fragment,
    @render_resource.BindingType::TextureBinding(
      @render_resource.TextureSampleType::Float(true),
      @render_resource.TextureViewDimension::D2,
      false,
    ),
  )
}

///|
fn standard_material_sampler_layout_entry(
  binding : Int,
  fragment : UInt,
) -> @render_resource.BindGroupLayoutEntry {
  @render_resource.BindGroupLayoutEntry::new(
    binding,
    fragment,
    @render_resource.BindingType::SamplerBinding(
      @render_resource.SamplerBindingType::Filtering,
    ),
  )
}

///|
fn standard_material_push_texture_sampler_layout_pair(
  entries : Array[@render_resource.BindGroupLayoutEntry],
  texture_binding : Int,
  sampler_binding : Int,
  fragment : UInt,
) -> Unit {
  entries.push(
    standard_material_texture_layout_entry(texture_binding, fragment),
  )
  entries.push(
    standard_material_sampler_layout_entry(sampler_binding, fragment),
  )
}

///|
pub fn standard_material_bind_group_layout_descriptor(
  features? : StandardMaterialTextureFeatureSet = standard_material_default_texture_feature_set(),
) -> @material.BindGroupLayoutDescriptor {
  let fragment = @wgpu.SHADER_STAGE_FRAGMENT.to_uint()
  let material_uniform_visibility = (@wgpu.SHADER_STAGE_VERTEX |
  @wgpu.SHADER_STAGE_FRAGMENT).to_uint()
  let entries : Array[@render_resource.BindGroupLayoutEntry] = [
    @render_resource.BindGroupLayoutEntry::new(
      0,
      material_uniform_visibility,
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        192UL,
      ),
    ),
  ]
  standard_material_push_texture_sampler_layout_pair(entries, 1, 2, fragment)
  standard_material_push_texture_sampler_layout_pair(entries, 3, 4, fragment)
  standard_material_push_texture_sampler_layout_pair(entries, 5, 6, fragment)
  standard_material_push_texture_sampler_layout_pair(entries, 7, 8, fragment)
  standard_material_push_texture_sampler_layout_pair(entries, 9, 10, fragment)
  standard_material_push_texture_sampler_layout_pair(entries, 11, 12, fragment)
  if features.pbr_anisotropy_texture() {
    standard_material_push_texture_sampler_layout_pair(
      entries, 13, 14, fragment,
    )
  }
  if features.pbr_transmission_textures() {
    standard_material_push_texture_sampler_layout_pair(
      entries, 15, 16, fragment,
    )
    standard_material_push_texture_sampler_layout_pair(
      entries, 17, 18, fragment,
    )
    standard_material_push_texture_sampler_layout_pair(
      entries, 19, 20, fragment,
    )
  }
  if features.pbr_multi_layer_material_textures() {
    standard_material_push_texture_sampler_layout_pair(
      entries, 21, 22, fragment,
    )
    standard_material_push_texture_sampler_layout_pair(
      entries, 23, 24, fragment,
    )
    standard_material_push_texture_sampler_layout_pair(
      entries, 25, 26, fragment,
    )
  }
  if features.pbr_specular_textures() {
    standard_material_push_texture_sampler_layout_pair(
      entries, 27, 28, fragment,
    )
    standard_material_push_texture_sampler_layout_pair(
      entries, 29, 30, fragment,
    )
  }
  @material.BindGroupLayoutDescriptor::new("StandardMaterial", entries)
}

///|
pub fn forward_decal_material_bind_group_layout_descriptor() -> @material.BindGroupLayoutDescriptor {
  let entries = standard_material_bind_group_layout_descriptor()
    .entries()
    .copy()
  entries.push(
    @render_resource.BindGroupLayoutEntry::new(
      200,
      @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
      @render_resource.BindingType::BufferBinding(
        @render_resource.BufferBindingType::Uniform,
        false,
        4UL,
      ),
    ),
  )
  @material.BindGroupLayoutDescriptor::new(
    "ForwardDecalMaterial<StandardMaterial>", entries,
  )
}

///|
pub fn extended_material_bind_group_layout_descriptor(
  base : @material.BindGroupLayoutDescriptor,
  extension_entries : Array[@render_resource.BindGroupLayoutEntry],
  label : String,
) -> @material.BindGroupLayoutDescriptor {
  let entries = base.entries().copy()
  for entry in extension_entries {
    entries.push(entry)
  }
  @material.BindGroupLayoutDescriptor::new(label, entries)
}

///|
pub fn material_uses_bindless_resources(
  bindless_supported : Bool,
  bindless_slot_count : Int?,
) -> Bool {
  match bindless_slot_count {
    Some(slot_count) => bindless_supported && slot_count > 1
    None => false
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/render_resource/bind_group.rs`
// (`AsBindGroup::bindless_slot_count`) plus
// `bevy/crates/bevy_pbr/src/pbr_material.rs` (`#[bindless(index_table(range(0..31)))]`).
pub fn standard_material_bindless_slot_count() -> Int? {
  Some(31)
}

///|
// Bevy source: `bevy/crates/bevy_render/macros/src/as_bind_group.rs`
// (`bindless_supported_syntax` generated by `AsBindGroup`).
pub fn standard_material_bindless_supported(
  render_device : @renderer.RenderDevice,
) -> Bool {
  render_device.has_feature_native_texture_binding_array() &&
  render_device.limits_max_storage_buffers_per_shader_stage_u32() > 0U &&
  render_device.limits_max_binding_array_sampler_elements_per_shader_stage_u32() >=
  31U
}

///|
pub struct MaterialBindGroupAllocatorInstallPlan {
  material_label : String
  uses_bindless_resources : Bool
  bindless_slot_count : Int?
  layout_descriptor : @material.BindGroupLayoutDescriptor
}

///|
pub fn MaterialBindGroupAllocatorInstallPlan::material_label(
  self : MaterialBindGroupAllocatorInstallPlan,
) -> String {
  self.material_label
}

///|
pub fn MaterialBindGroupAllocatorInstallPlan::uses_bindless_resources(
  self : MaterialBindGroupAllocatorInstallPlan,
) -> Bool {
  self.uses_bindless_resources
}

///|
pub fn MaterialBindGroupAllocatorInstallPlan::bindless_slot_count(
  self : MaterialBindGroupAllocatorInstallPlan,
) -> Int? {
  self.bindless_slot_count
}

///|
pub fn MaterialBindGroupAllocatorInstallPlan::layout_descriptor(
  self : MaterialBindGroupAllocatorInstallPlan,
) -> @material.BindGroupLayoutDescriptor {
  self.layout_descriptor
}

///|
pub fn standard_material_bind_group_allocator_install_plan(
  bindless_supported : Bool,
  bindless_slot_count : Int?,
  features? : StandardMaterialTextureFeatureSet = standard_material_default_texture_feature_set(),
) -> MaterialBindGroupAllocatorInstallPlan {
  MaterialBindGroupAllocatorInstallPlan::{
    material_label: "StandardMaterial",
    uses_bindless_resources: material_uses_bindless_resources(
      bindless_supported, bindless_slot_count,
    ),
    bindless_slot_count,
    layout_descriptor: standard_material_bind_group_layout_descriptor(features~),
  }
}

///|
pub fn material_bind_group_allocator_for_support(
  bindless_supported : Bool,
  bindless_slot_count : Int?,
) -> MaterialBindGroupAllocator {
  if material_uses_bindless_resources(bindless_supported, bindless_slot_count) {
    MaterialBindGroupAllocator::default_bindless()
  } else {
    MaterialBindGroupAllocator::default_non_bindless()
  }
}

///|
pub struct MaterialBindGroupIndex {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindGroupIndex::new(value : Int) -> MaterialBindGroupIndex {
  MaterialBindGroupIndex::{ value: if value < 0 { 0 } else { value } }
}

///|
pub fn MaterialBindGroupIndex::to_int(self : MaterialBindGroupIndex) -> Int {
  self.value
}

///|
pub struct MaterialBindGroupSlot {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindGroupSlot::new(value : Int) -> MaterialBindGroupSlot {
  MaterialBindGroupSlot::{ value: if value < 0 { 0 } else { value } }
}

///|
pub fn MaterialBindGroupSlot::to_int(self : MaterialBindGroupSlot) -> Int {
  self.value
}

///|
pub struct MaterialBindingId {
  group : MaterialBindGroupIndex
  slot : MaterialBindGroupSlot
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindingId::MaterialBindingId() -> MaterialBindingId {
  MaterialBindingId::{
    group: MaterialBindGroupIndex::new(0),
    slot: MaterialBindGroupSlot::new(0),
  }
}

///|
pub fn MaterialBindingId::new(
  group : MaterialBindGroupIndex,
  slot : MaterialBindGroupSlot,
) -> MaterialBindingId {
  MaterialBindingId::{ group, slot }
}

///|
pub fn MaterialBindingId::group(
  self : MaterialBindingId,
) -> MaterialBindGroupIndex {
  self.group
}

///|
pub fn MaterialBindingId::slot(
  self : MaterialBindingId,
) -> MaterialBindGroupSlot {
  self.slot
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs::RenderMaterialBindings`.

///|
pub struct RenderMaterialBindings {
  bindings : Map[Int, MaterialBindingId]
}

///|
pub fn RenderMaterialBindings::RenderMaterialBindings() -> RenderMaterialBindings {
  RenderMaterialBindings::{ bindings: {} }
}

///|
pub fn RenderMaterialBindings::len(self : RenderMaterialBindings) -> Int {
  self.bindings.length()
}

///|
pub fn RenderMaterialBindings::get(
  self : RenderMaterialBindings,
  material_id : Int,
) -> MaterialBindingId? {
  self.bindings.get(material_id)
}

///|
pub fn RenderMaterialBindings::set(
  self : RenderMaterialBindings,
  material_id : Int,
  binding : MaterialBindingId,
) -> Unit {
  self.bindings.set(material_id, binding)
}

///|
pub fn RenderMaterialBindings::remove(
  self : RenderMaterialBindings,
  material_id : Int,
) -> MaterialBindingId? {
  guard self.bindings.get(material_id) is Some(binding) else { return None }
  self.bindings.remove(material_id)
  Some(binding)
}

///|
const STANDARD_MATERIAL_BIND_GROUP_ALLOCATOR_LABEL : String = "StandardMaterial"

///|
fn prepare_render_material_binding(
  material_id : Int,
  render_material_bindings : RenderMaterialBindings?,
  material_bind_group_allocators : MaterialBindGroupAllocators?,
) -> Unit {
  guard render_material_bindings is Some(render_material_bindings) else {
    return
  }
  guard material_bind_group_allocators is Some(material_bind_group_allocators) else {
    return
  }
  if material_id == DUMMY_MESH_MATERIAL_ID {
    return
  }
  if render_material_bindings.get(material_id) is Some(_) {
    return
  }
  guard material_bind_group_allocators.get(
      STANDARD_MATERIAL_BIND_GROUP_ALLOCATOR_LABEL,
    )
    is Some(allocator) else {
    return
  }
  match allocator.allocate_bindless_material(material_id) {
    Some(binding) => render_material_bindings.set(material_id, binding)
    None => ()
  }
}

///|
fn prepare_render_material_bindings(
  material_instances : RenderMaterialInstances?,
  render_material_bindings : RenderMaterialBindings?,
  material_bind_group_allocators : MaterialBindGroupAllocators?,
) -> Unit {
  guard material_instances is Some(material_instances) else { return }
  for material_id in material_instances.material_asset_ids() {
    prepare_render_material_binding(
      material_id, render_material_bindings, material_bind_group_allocators,
    )
  }
}

///|
pub let ecs_key_render_material_bindings : @ecs.ResourceKey[
  RenderMaterialBindings,
] = @ecs.register_resource(debug_name="mgstudio_pbr::RenderMaterialBindings")

///|
pub impl @app.Resource for RenderMaterialBindings with fn resource() {
  ecs_key_render_material_bindings
}

///|
pub struct MaterialBindGroupEntry {
  material_id : Int
  binding_id : MaterialBindingId
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialBindGroupEntry::new(
  material_id : Int,
  binding_id : MaterialBindingId,
) -> MaterialBindGroupEntry {
  MaterialBindGroupEntry::{ material_id, binding_id }
}

///|
pub fn MaterialBindGroupEntry::material_id(
  self : MaterialBindGroupEntry,
) -> Int {
  self.material_id
}

///|
pub fn MaterialBindGroupEntry::binding_id(
  self : MaterialBindGroupEntry,
) -> MaterialBindingId {
  self.binding_id
}

///|
pub struct MaterialNonBindlessAllocatedBindGroup {
  bind_group_id : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn MaterialNonBindlessAllocatedBindGroup::new(
  bind_group_id : Int,
) -> MaterialNonBindlessAllocatedBindGroup {
  MaterialNonBindlessAllocatedBindGroup::{ bind_group_id, }
}

///|
pub fn MaterialNonBindlessAllocatedBindGroup::bind_group_id(
  self : MaterialNonBindlessAllocatedBindGroup,
) -> Int {
  self.bind_group_id
}

///|
pub struct MaterialBindGroupNonBindlessAllocator {
  bind_groups : Array[MaterialNonBindlessAllocatedBindGroup?]
  free_indices : Array[Int]
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::MaterialBindGroupNonBindlessAllocator() -> MaterialBindGroupNonBindlessAllocator {
  MaterialBindGroupNonBindlessAllocator::{ bind_groups: [], free_indices: [] }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::allocate(
  self : MaterialBindGroupNonBindlessAllocator,
  bind_group_id : Int,
) -> MaterialBindingId {
  match self.free_indices.pop() {
    Some(index) => {
      self.bind_groups[index] = Some(
        MaterialNonBindlessAllocatedBindGroup::new(bind_group_id),
      )
      MaterialBindingId::new(
        MaterialBindGroupIndex::new(index),
        MaterialBindGroupSlot::new(0),
      )
    }
    None => {
      let index = self.bind_groups.length()
      self.bind_groups.push(
        Some(MaterialNonBindlessAllocatedBindGroup::new(bind_group_id)),
      )
      MaterialBindingId::new(
        MaterialBindGroupIndex::new(index),
        MaterialBindGroupSlot::new(0),
      )
    }
  }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::free(
  self : MaterialBindGroupNonBindlessAllocator,
  binding_id : MaterialBindingId,
) -> Unit {
  let index = binding_id.group().to_int()
  if index < 0 || index >= self.bind_groups.length() {
    return
  }
  if self.bind_groups[index] is Some(_) {
    self.bind_groups[index] = None
    self.free_indices.push(index)
  }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::get(
  self : MaterialBindGroupNonBindlessAllocator,
  index : MaterialBindGroupIndex,
) -> MaterialNonBindlessAllocatedBindGroup? {
  let raw_index = index.to_int()
  if raw_index < 0 || raw_index >= self.bind_groups.length() {
    None
  } else {
    self.bind_groups[raw_index]
  }
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::len(
  self : MaterialBindGroupNonBindlessAllocator,
) -> Int {
  self.bind_groups.fold(init=0, fn(acc, entry) {
    if entry is Some(_) {
      acc + 1
    } else {
      acc
    }
  })
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::slab_count(
  self : MaterialBindGroupNonBindlessAllocator,
) -> Int {
  self.bind_groups.length()
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::slabs_size(
  self : MaterialBindGroupNonBindlessAllocator,
) -> Int {
  self.bind_groups.length()
}

///|
pub fn MaterialBindGroupNonBindlessAllocator::allocations(
  self : MaterialBindGroupNonBindlessAllocator,
) -> UInt {
  self.len().reinterpret_as_uint()
}

///|
pub struct MaterialBindGroupBindlessAllocator {
  slab_capacity : Int
  slots : Array[Int?]
  free_slots : Array[Int]
}

///|
pub fn MaterialBindGroupBindlessAllocator::MaterialBindGroupBindlessAllocator() -> MaterialBindGroupBindlessAllocator {
  MaterialBindGroupBindlessAllocator::with_slab_capacity(256)
}

///|
pub fn MaterialBindGroupBindlessAllocator::with_slab_capacity(
  slab_capacity : Int,
) -> MaterialBindGroupBindlessAllocator {
  let capacity = if slab_capacity <= 0 { 1 } else { slab_capacity }
  MaterialBindGroupBindlessAllocator::{
    slab_capacity: capacity,
    slots: [],
    free_slots: [],
  }
}

///|
pub fn MaterialBindGroupBindlessAllocator::allocate(
  self : MaterialBindGroupBindlessAllocator,
  material_id : Int,
) -> MaterialBindingId? {
  match self.free_slots.pop() {
    Some(slot) => {
      self.slots[slot] = Some(material_id)
      Some(
        MaterialBindingId::new(
          MaterialBindGroupIndex::new(0),
          MaterialBindGroupSlot::new(slot),
        ),
      )
    }
    None =>
      if self.slots.length() >= self.slab_capacity {
        None
      } else {
        let slot = self.slots.length()
        self.slots.push(Some(material_id))
        Some(
          MaterialBindingId::new(
            MaterialBindGroupIndex::new(0),
            MaterialBindGroupSlot::new(slot),
          ),
        )
      }
  }
}

///|
pub fn MaterialBindGroupBindlessAllocator::free(
  self : MaterialBindGroupBindlessAllocator,
  binding_id : MaterialBindingId,
) -> Unit {
  let slot = binding_id.slot().to_int()
  if slot < 0 || slot >= self.slots.length() {
    return
  }
  if self.slots[slot] is Some(_) {
    self.slots[slot] = None
    self.free_slots.push(slot)
  }
}

///|
pub fn MaterialBindGroupBindlessAllocator::len(
  self : MaterialBindGroupBindlessAllocator,
) -> Int {
  self.slots.fold(init=0, fn(acc, entry) {
    if entry is Some(_) {
      acc + 1
    } else {
      acc
    }
  })
}

///|
pub fn MaterialBindGroupBindlessAllocator::slab_count(
  self : MaterialBindGroupBindlessAllocator,
) -> Int {
  if self.slots.length() == 0 {
    0
  } else {
    (self.slots.length() + self.slab_capacity - 1) / self.slab_capacity
  }
}

///|
pub fn MaterialBindGroupBindlessAllocator::slabs_size(
  self : MaterialBindGroupBindlessAllocator,
) -> Int {
  self.slab_count() * self.slab_capacity
}

///|
pub fn MaterialBindGroupBindlessAllocator::allocations(
  self : MaterialBindGroupBindlessAllocator,
) -> UInt {
  self.len().reinterpret_as_uint()
}

///|
pub(all) enum MaterialBindGroupAllocator {
  Bindless(MaterialBindGroupBindlessAllocator)
  NonBindless(MaterialBindGroupNonBindlessAllocator)
}

///|
pub fn MaterialBindGroupAllocator::default_bindless() -> MaterialBindGroupAllocator {
  MaterialBindGroupAllocator::Bindless(
    MaterialBindGroupBindlessAllocator::MaterialBindGroupBindlessAllocator(),
  )
}

///|
pub fn MaterialBindGroupAllocator::default_non_bindless() -> MaterialBindGroupAllocator {
  MaterialBindGroupAllocator::NonBindless(
    MaterialBindGroupNonBindlessAllocator::MaterialBindGroupNonBindlessAllocator(),
  )
}

///|
pub fn MaterialBindGroupAllocator::slab_count(
  self : MaterialBindGroupAllocator,
) -> Int {
  match self {
    Bindless(allocator) => allocator.slab_count()
    NonBindless(allocator) => allocator.slab_count()
  }
}

///|
pub fn MaterialBindGroupAllocator::slabs_size(
  self : MaterialBindGroupAllocator,
) -> Int {
  match self {
    Bindless(allocator) => allocator.slabs_size()
    NonBindless(allocator) => allocator.slabs_size()
  }
}

///|
pub fn MaterialBindGroupAllocator::allocations(
  self : MaterialBindGroupAllocator,
) -> UInt {
  match self {
    Bindless(allocator) => allocator.allocations()
    NonBindless(allocator) => allocator.allocations()
  }
}

///|
pub fn MaterialBindGroupAllocator::allocate_bindless_material(
  self : MaterialBindGroupAllocator,
  material_id : Int,
) -> MaterialBindingId? {
  match self {
    Bindless(allocator) => allocator.allocate(material_id)
    NonBindless(_) => None
  }
}

///|
pub fn MaterialBindGroupAllocator::free(
  self : MaterialBindGroupAllocator,
  binding_id : MaterialBindingId,
) -> Unit {
  match self {
    Bindless(allocator) => allocator.free(binding_id)
    NonBindless(allocator) => allocator.free(binding_id)
  }
}

///|
pub struct MaterialBindGroupAllocators {
  allocators : Map[String, MaterialBindGroupAllocator]
}

///|
pub fn MaterialBindGroupAllocators::MaterialBindGroupAllocators() -> MaterialBindGroupAllocators {
  MaterialBindGroupAllocators::{ allocators: {} }
}

///|
pub let ecs_key_material_bind_group_allocators : @ecs.ResourceKey[
  MaterialBindGroupAllocators,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::MaterialBindGroupAllocators",
)

///|
pub fn MaterialBindGroupAllocators::insert(
  self : MaterialBindGroupAllocators,
  key : String,
  allocator : MaterialBindGroupAllocator,
) -> Unit {
  self.allocators.set(key, allocator)
}

///|
pub fn MaterialBindGroupAllocators::get(
  self : MaterialBindGroupAllocators,
  key : String,
) -> MaterialBindGroupAllocator? {
  self.allocators.get(key)
}

///|
pub fn MaterialBindGroupAllocators::contains(
  self : MaterialBindGroupAllocators,
  key : String,
) -> Bool {
  self.allocators.contains(key)
}

///|
pub fn MaterialBindGroupAllocators::len(
  self : MaterialBindGroupAllocators,
) -> Int {
  self.allocators.length()
}

///|
pub fn MaterialBindGroupAllocators::install_standard_material(
  self : MaterialBindGroupAllocators,
  bindless_supported : Bool,
  bindless_slot_count : Int?,
  features? : StandardMaterialTextureFeatureSet = standard_material_default_texture_feature_set(),
) -> MaterialBindGroupAllocatorInstallPlan {
  let plan = standard_material_bind_group_allocator_install_plan(
    bindless_supported,
    bindless_slot_count,
    features~,
  )
  self.insert(
    plan.material_label(),
    if plan.uses_bindless_resources() {
      MaterialBindGroupAllocator::default_bindless()
    } else {
      MaterialBindGroupAllocator::default_non_bindless()
    },
  )
  plan
}

///|
pub struct MaterialBindGroups {
  entries : Array[MaterialBindGroupEntry]
}

///|
pub fn MaterialBindGroups::MaterialBindGroups() -> MaterialBindGroups {
  MaterialBindGroups::{ entries: [] }
}

///|
pub fn MaterialBindGroups::push(
  self : MaterialBindGroups,
  entry : MaterialBindGroupEntry,
) -> Unit {
  self.entries.push(entry)
}

///|
pub fn MaterialBindGroups::entry_count(self : MaterialBindGroups) -> Int {
  self.entries.length()
}
