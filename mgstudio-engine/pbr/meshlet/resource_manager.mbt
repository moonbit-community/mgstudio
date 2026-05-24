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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/resource_manager.rs`.

///|
fn meshlet_resource_non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub(all) enum MeshletResourceTextureFormat {
  NoTextureFormat
  R64Uint
  R32Uint
  R32Float
}

///|
pub(all) enum MeshletResourceStorageTextureAccess {
  NoStorageTextureAccess
  WriteOnly
  ReadOnly
  ReadWrite
  Atomic
}

///|
pub(all) enum MeshletResourceBindingKind {
  Texture2dFloat
  StorageTexture2d
  UniformBuffer
  StorageBufferReadOnly
  StorageBufferReadWrite
  SamplerNonFiltering
}

///|
pub struct MeshletResourceBindGroupLayoutEntry {
  binding_kind : MeshletResourceBindingKind
  texture_format : MeshletResourceTextureFormat
  storage_texture_access : MeshletResourceStorageTextureAccess
  uniform_dynamic_offset : Bool
}

///|
pub struct MeshletResourceBindGroupLayoutDescriptor {
  label : String
  compute_stage : Bool
  vertex_stage : Bool
  fragment_stage : Bool
  entries : Array[MeshletResourceBindGroupLayoutEntry]
  optional : Bool
  enabled : Bool
}

///|
fn meshlet_resource_layout_entry(
  binding_kind : MeshletResourceBindingKind,
  texture_format? : MeshletResourceTextureFormat = MeshletResourceTextureFormat::NoTextureFormat,
  storage_texture_access? : MeshletResourceStorageTextureAccess = MeshletResourceStorageTextureAccess::NoStorageTextureAccess,
  uniform_dynamic_offset? : Bool = false,
) -> MeshletResourceBindGroupLayoutEntry {
  MeshletResourceBindGroupLayoutEntry::{
    binding_kind,
    texture_format,
    storage_texture_access,
    uniform_dynamic_offset,
  }
}

///|
fn meshlet_resource_texture_2d_float() -> MeshletResourceBindGroupLayoutEntry {
  meshlet_resource_layout_entry(MeshletResourceBindingKind::Texture2dFloat)
}

///|
fn meshlet_resource_storage_texture_2d(
  texture_format : MeshletResourceTextureFormat,
  access : MeshletResourceStorageTextureAccess,
) -> MeshletResourceBindGroupLayoutEntry {
  meshlet_resource_layout_entry(
    MeshletResourceBindingKind::StorageTexture2d,
    texture_format~,
    storage_texture_access=access,
  )
}

///|
fn meshlet_resource_uniform_buffer_dynamic() -> MeshletResourceBindGroupLayoutEntry {
  meshlet_resource_layout_entry(
    MeshletResourceBindingKind::UniformBuffer,
    uniform_dynamic_offset=true,
  )
}

///|
fn meshlet_resource_uniform_buffer() -> MeshletResourceBindGroupLayoutEntry {
  meshlet_resource_layout_entry(MeshletResourceBindingKind::UniformBuffer)
}

///|
fn meshlet_resource_storage_read_only() -> MeshletResourceBindGroupLayoutEntry {
  meshlet_resource_layout_entry(
    MeshletResourceBindingKind::StorageBufferReadOnly,
  )
}

///|
fn meshlet_resource_storage_read_write() -> MeshletResourceBindGroupLayoutEntry {
  meshlet_resource_layout_entry(
    MeshletResourceBindingKind::StorageBufferReadWrite,
  )
}

///|
fn meshlet_resource_sampler_non_filtering() -> MeshletResourceBindGroupLayoutEntry {
  meshlet_resource_layout_entry(MeshletResourceBindingKind::SamplerNonFiltering)
}

///|
fn meshlet_resource_bind_group_layout_descriptor(
  label : String,
  compute_stage? : Bool = false,
  vertex_stage? : Bool = false,
  fragment_stage? : Bool = false,
  entries? : Array[MeshletResourceBindGroupLayoutEntry] = [],
  optional? : Bool = false,
  enabled? : Bool = true,
) -> MeshletResourceBindGroupLayoutDescriptor {
  MeshletResourceBindGroupLayoutDescriptor::{
    label,
    compute_stage,
    vertex_stage,
    fragment_stage,
    entries,
    optional,
    enabled,
  }
}

///|
fn meshlet_resource_texture_format_equal(
  lhs : MeshletResourceTextureFormat,
  rhs : MeshletResourceTextureFormat,
) -> Bool {
  match lhs {
    NoTextureFormat => rhs is NoTextureFormat
    R64Uint => rhs is R64Uint
    R32Uint => rhs is R32Uint
    R32Float => rhs is R32Float
  }
}

///|
fn meshlet_resource_storage_texture_access_equal(
  lhs : MeshletResourceStorageTextureAccess,
  rhs : MeshletResourceStorageTextureAccess,
) -> Bool {
  match lhs {
    NoStorageTextureAccess => rhs is NoStorageTextureAccess
    WriteOnly => rhs is WriteOnly
    ReadOnly => rhs is ReadOnly
    ReadWrite => rhs is ReadWrite
    Atomic => rhs is Atomic
  }
}

///|
fn meshlet_resource_binding_kind_equal(
  lhs : MeshletResourceBindingKind,
  rhs : MeshletResourceBindingKind,
) -> Bool {
  match lhs {
    Texture2dFloat => rhs is Texture2dFloat
    StorageTexture2d => rhs is StorageTexture2d
    UniformBuffer => rhs is UniformBuffer
    StorageBufferReadOnly => rhs is StorageBufferReadOnly
    StorageBufferReadWrite => rhs is StorageBufferReadWrite
    SamplerNonFiltering => rhs is SamplerNonFiltering
  }
}

///|
fn meshlet_resource_view_cull_prefix_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  [
    meshlet_resource_texture_2d_float(),
    meshlet_resource_uniform_buffer_dynamic(),
    meshlet_resource_uniform_buffer_dynamic(),
  ]
}

///|
fn meshlet_resource_first_instance_cull_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  let entries = meshlet_resource_view_cull_prefix_entries()
  for _ in 0..<4 {
    entries.push(meshlet_resource_storage_read_only())
  }
  for _ in 0..<6 {
    entries.push(meshlet_resource_storage_read_write())
  }
  entries.push(meshlet_resource_uniform_buffer())
  entries
}

///|
fn meshlet_resource_second_instance_cull_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  let entries = meshlet_resource_view_cull_prefix_entries()
  for _ in 0..<4 {
    entries.push(meshlet_resource_storage_read_only())
  }
  for _ in 0..<3 {
    entries.push(meshlet_resource_storage_read_write())
  }
  for _ in 0..<2 {
    entries.push(meshlet_resource_storage_read_only())
  }
  entries.push(meshlet_resource_uniform_buffer())
  entries
}

///|
fn meshlet_resource_first_bvh_cull_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  let entries = meshlet_resource_view_cull_prefix_entries()
  for _ in 0..<3 {
    entries.push(meshlet_resource_storage_read_only())
  }
  for _ in 0..<11 {
    entries.push(meshlet_resource_storage_read_write())
  }
  entries.push(meshlet_resource_uniform_buffer())
  entries
}

///|
fn meshlet_resource_second_bvh_cull_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  let entries = meshlet_resource_view_cull_prefix_entries()
  for _ in 0..<3 {
    entries.push(meshlet_resource_storage_read_only())
  }
  for _ in 0..<8 {
    entries.push(meshlet_resource_storage_read_write())
  }
  entries.push(meshlet_resource_uniform_buffer())
  entries
}

///|
fn meshlet_resource_first_meshlet_cull_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  let entries = meshlet_resource_view_cull_prefix_entries()
  for _ in 0..<2 {
    entries.push(meshlet_resource_storage_read_only())
  }
  for _ in 0..<2 {
    entries.push(meshlet_resource_storage_read_write())
  }
  entries.push(meshlet_resource_storage_read_only())
  entries.push(meshlet_resource_storage_read_write())
  entries.push(meshlet_resource_storage_read_only())
  for _ in 0..<3 {
    entries.push(meshlet_resource_storage_read_write())
  }
  entries.push(meshlet_resource_uniform_buffer())
  entries
}

///|
fn meshlet_resource_second_meshlet_cull_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  let entries = meshlet_resource_view_cull_prefix_entries()
  for _ in 0..<2 {
    entries.push(meshlet_resource_storage_read_only())
  }
  for _ in 0..<2 {
    entries.push(meshlet_resource_storage_read_write())
  }
  entries.push(meshlet_resource_storage_read_only())
  entries.push(meshlet_resource_storage_read_write())
  for _ in 0..<2 {
    entries.push(meshlet_resource_storage_read_only())
  }
  entries.push(meshlet_resource_uniform_buffer())
  entries
}

///|
fn meshlet_resource_downsample_depth_entries(
  visibility_format : MeshletResourceTextureFormat,
) -> Array[MeshletResourceBindGroupLayoutEntry] {
  let entries = [
    meshlet_resource_storage_texture_2d(
      visibility_format,
      MeshletResourceStorageTextureAccess::ReadOnly,
    ),
  ]
  for _ in 0..<5 {
    entries.push(
      meshlet_resource_storage_texture_2d(
        MeshletResourceTextureFormat::R32Float,
        MeshletResourceStorageTextureAccess::WriteOnly,
      ),
    )
  }
  entries.push(
    meshlet_resource_storage_texture_2d(
      MeshletResourceTextureFormat::R32Float,
      MeshletResourceStorageTextureAccess::ReadWrite,
    ),
  )
  for _ in 0..<6 {
    entries.push(
      meshlet_resource_storage_texture_2d(
        MeshletResourceTextureFormat::R32Float,
        MeshletResourceStorageTextureAccess::WriteOnly,
      ),
    )
  }
  entries.push(meshlet_resource_sampler_non_filtering())
  entries
}

///|
fn meshlet_resource_visibility_buffer_raster_entries(
  visibility_format : MeshletResourceTextureFormat,
) -> Array[MeshletResourceBindGroupLayoutEntry] {
  let entries : Array[MeshletResourceBindGroupLayoutEntry] = []
  for _ in 0..<7 {
    entries.push(meshlet_resource_storage_read_only())
  }
  entries.push(
    meshlet_resource_storage_texture_2d(
      visibility_format,
      MeshletResourceStorageTextureAccess::Atomic,
    ),
  )
  entries.push(meshlet_resource_uniform_buffer_dynamic())
  entries
}

///|
fn meshlet_resource_material_shade_entries() -> Array[
  MeshletResourceBindGroupLayoutEntry,
] {
  let entries = [
    meshlet_resource_storage_texture_2d(
      MeshletResourceTextureFormat::R64Uint,
      MeshletResourceStorageTextureAccess::ReadOnly,
    ),
  ]
  for _ in 0..<7 {
    entries.push(meshlet_resource_storage_read_only())
  }
  entries
}

///|
pub fn meshlet_resource_bind_group_layout_descriptors(
  needs_dispatch_remap? : Bool = false,
) -> Array[MeshletResourceBindGroupLayoutDescriptor] {
  let fill_count_entries : Array[MeshletResourceBindGroupLayoutEntry] = []
  for _ in 0..<(if needs_dispatch_remap { 4 } else { 3 }) {
    fill_count_entries.push(meshlet_resource_storage_read_write())
  }
  [
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_clear_visibility_buffer_bind_group_layout",
      compute_stage=true,
      entries=[
        meshlet_resource_storage_texture_2d(
          MeshletResourceTextureFormat::R64Uint,
          MeshletResourceStorageTextureAccess::WriteOnly,
        ),
      ],
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_clear_visibility_buffer_shadow_view_bind_group_layout",
      compute_stage=true,
      entries=[
        meshlet_resource_storage_texture_2d(
          MeshletResourceTextureFormat::R32Uint,
          MeshletResourceStorageTextureAccess::WriteOnly,
        ),
      ],
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_first_instance_culling_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_first_instance_cull_entries(),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_second_instance_culling_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_second_instance_cull_entries(),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_first_bvh_culling_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_first_bvh_cull_entries(),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_second_bvh_culling_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_second_bvh_cull_entries(),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_first_meshlet_culling_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_first_meshlet_cull_entries(),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_second_meshlet_culling_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_second_meshlet_cull_entries(),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_downsample_depth_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_downsample_depth_entries(
        MeshletResourceTextureFormat::R64Uint,
      ),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_downsample_depth_shadow_view_bind_group_layout",
      compute_stage=true,
      entries=meshlet_resource_downsample_depth_entries(
        MeshletResourceTextureFormat::R32Uint,
      ),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_visibility_buffer_raster_bind_group_layout",
      compute_stage=true,
      vertex_stage=true,
      fragment_stage=true,
      entries=meshlet_resource_visibility_buffer_raster_entries(
        MeshletResourceTextureFormat::R64Uint,
      ),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_visibility_buffer_raster_shadow_view_bind_group_layout",
      compute_stage=true,
      vertex_stage=true,
      fragment_stage=true,
      entries=meshlet_resource_visibility_buffer_raster_entries(
        MeshletResourceTextureFormat::R32Uint,
      ),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_resolve_depth_bind_group_layout",
      fragment_stage=true,
      entries=[
        meshlet_resource_storage_texture_2d(
          MeshletResourceTextureFormat::R64Uint,
          MeshletResourceStorageTextureAccess::ReadOnly,
        ),
      ],
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_resolve_depth_shadow_view_bind_group_layout",
      fragment_stage=true,
      entries=[
        meshlet_resource_storage_texture_2d(
          MeshletResourceTextureFormat::R32Uint,
          MeshletResourceStorageTextureAccess::ReadOnly,
        ),
      ],
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_resolve_material_depth_bind_group_layout",
      fragment_stage=true,
      entries=[
        meshlet_resource_storage_texture_2d(
          MeshletResourceTextureFormat::R64Uint,
          MeshletResourceStorageTextureAccess::ReadOnly,
        ),
        meshlet_resource_storage_read_only(),
        meshlet_resource_storage_read_only(),
      ],
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_mesh_material_shade_bind_group_layout",
      fragment_stage=true,
      entries=meshlet_resource_material_shade_entries(),
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_fill_counts_bind_group_layout",
      compute_stage=true,
      entries=fill_count_entries,
    ),
    meshlet_resource_bind_group_layout_descriptor(
      "meshlet_remap_1d_to_2d_dispatch_bind_group_layout",
      compute_stage=true,
      entries=[
        meshlet_resource_storage_read_write(),
        meshlet_resource_storage_read_write(),
      ],
      optional=true,
      enabled=needs_dispatch_remap,
    ),
  ]
}

///|
pub fn MeshletResourceBindGroupLayoutDescriptor::entry_count(
  self : MeshletResourceBindGroupLayoutDescriptor,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshletResourceBindGroupLayoutDescriptor::count_binding_kind(
  self : MeshletResourceBindGroupLayoutDescriptor,
  kind : MeshletResourceBindingKind,
) -> Int {
  let mut count = 0
  for entry in self.entries {
    if meshlet_resource_binding_kind_equal(entry.binding_kind, kind) {
      count = count + 1
    }
  }
  count
}

///|
pub fn MeshletResourceBindGroupLayoutDescriptor::uses_storage_texture(
  self : MeshletResourceBindGroupLayoutDescriptor,
  texture_format : MeshletResourceTextureFormat,
  access : MeshletResourceStorageTextureAccess,
) -> Bool {
  for entry in self.entries {
    if meshlet_resource_binding_kind_equal(
        entry.binding_kind,
        MeshletResourceBindingKind::StorageTexture2d,
      ) &&
      meshlet_resource_texture_format_equal(
        entry.texture_format,
        texture_format,
      ) &&
      meshlet_resource_storage_texture_access_equal(
        entry.storage_texture_access,
        access,
      ) {
      return true
    }
  }
  false
}

///|
pub struct ResourceManager {
  mut frame_index : Int
  mut cluster_buffer_slots : Int
  mut cull_queue_rightmost_slot : Int
  mut meshlet_buffer_count : Int
  previous_depth_pyramids : Map[Int, Int]
  prepared_view_resources : Map[UInt64, MeshletViewResources]
  prepared_view_bind_groups : Map[UInt64, MeshletViewBindGroups]
  clear_visibility_buffer_bind_group_layout_id : Int
  clear_visibility_buffer_shadow_view_bind_group_layout_id : Int
  first_instance_cull_bind_group_layout_id : Int
  second_instance_cull_bind_group_layout_id : Int
  first_bvh_cull_bind_group_layout_id : Int
  second_bvh_cull_bind_group_layout_id : Int
  first_meshlet_cull_bind_group_layout_id : Int
  second_meshlet_cull_bind_group_layout_id : Int
  visibility_buffer_raster_bind_group_layout_id : Int
  visibility_buffer_raster_shadow_view_bind_group_layout_id : Int
  downsample_depth_bind_group_layout_id : Int
  downsample_depth_shadow_view_bind_group_layout_id : Int
  resolve_depth_bind_group_layout_id : Int
  resolve_depth_shadow_view_bind_group_layout_id : Int
  resolve_material_depth_bind_group_layout_id : Int
  material_shade_bind_group_layout_id : Int
  fill_counts_bind_group_layout_id : Int
  remap_1d_to_2d_dispatch_bind_group_layout_id : Int?
}

///|
pub fn ResourceManager::ResourceManager() -> ResourceManager {
  ResourceManager::new(0)
}

///|
pub fn ResourceManager::new(cluster_buffer_slots : Int) -> ResourceManager {
  let safe_slots = meshlet_resource_non_negative(cluster_buffer_slots)
  ResourceManager::{
    frame_index: 0,
    cluster_buffer_slots: safe_slots,
    cull_queue_rightmost_slot: if safe_slots <= 0 {
      0
    } else {
      safe_slots - 1
    },
    meshlet_buffer_count: 0,
    previous_depth_pyramids: {},
    prepared_view_resources: {},
    prepared_view_bind_groups: {},
    clear_visibility_buffer_bind_group_layout_id: -1,
    clear_visibility_buffer_shadow_view_bind_group_layout_id: -1,
    first_instance_cull_bind_group_layout_id: -1,
    second_instance_cull_bind_group_layout_id: -1,
    first_bvh_cull_bind_group_layout_id: -1,
    second_bvh_cull_bind_group_layout_id: -1,
    first_meshlet_cull_bind_group_layout_id: -1,
    second_meshlet_cull_bind_group_layout_id: -1,
    visibility_buffer_raster_bind_group_layout_id: -1,
    visibility_buffer_raster_shadow_view_bind_group_layout_id: -1,
    downsample_depth_bind_group_layout_id: -1,
    downsample_depth_shadow_view_bind_group_layout_id: -1,
    resolve_depth_bind_group_layout_id: -1,
    resolve_depth_shadow_view_bind_group_layout_id: -1,
    resolve_material_depth_bind_group_layout_id: -1,
    material_shade_bind_group_layout_id: -1,
    fill_counts_bind_group_layout_id: -1,
    remap_1d_to_2d_dispatch_bind_group_layout_id: None,
  }
}

///|
pub fn ResourceManager::advance_frame(self : ResourceManager) -> Unit {
  self.frame_index = self.frame_index + 1
}

///|
pub fn ResourceManager::frame_index(self : ResourceManager) -> Int {
  self.frame_index
}

///|
pub fn ResourceManager::cluster_buffer_slots(self : ResourceManager) -> Int {
  self.cluster_buffer_slots
}

///|
pub fn ResourceManager::cull_queue_rightmost_slot(
  self : ResourceManager,
) -> Int {
  self.cull_queue_rightmost_slot
}

///|
pub fn ResourceManager::set_cluster_buffer_slots(
  self : ResourceManager,
  cluster_buffer_slots : Int,
) -> Unit {
  let safe_slots = meshlet_resource_non_negative(cluster_buffer_slots)
  self.cluster_buffer_slots = safe_slots
  self.cull_queue_rightmost_slot = if safe_slots <= 0 {
    0
  } else {
    safe_slots - 1
  }
}

///|
pub fn ResourceManager::set_meshlet_buffer_count(
  self : ResourceManager,
  count : Int,
) -> Unit {
  self.meshlet_buffer_count = meshlet_resource_non_negative(count)
}

///|
pub fn ResourceManager::meshlet_buffer_count(self : ResourceManager) -> Int {
  self.meshlet_buffer_count
}

///|
pub fn ResourceManager::set_previous_depth_pyramid(
  self : ResourceManager,
  view_entity : Int,
  texture_view_id : Int,
) -> Unit {
  self.previous_depth_pyramids.set(
    meshlet_resource_non_negative(view_entity),
    meshlet_resource_non_negative(texture_view_id),
  )
}

///|
pub fn ResourceManager::previous_depth_pyramid(
  self : ResourceManager,
  view_entity : Int,
) -> Int? {
  self.previous_depth_pyramids.get(meshlet_resource_non_negative(view_entity))
}

///|
pub fn ResourceManager::clear_stale_previous_depth_pyramids(
  self : ResourceManager,
  active_view_entities : Array[Int],
) -> Unit {
  let active = @utils.IntBitSet::new()
  for view_entity in active_view_entities {
    active.insert(meshlet_resource_non_negative(view_entity))
  }
  let stale_keys : Array[Int] = []
  for key in self.previous_depth_pyramids.keys() {
    if !active.contains(key) {
      stale_keys.push(key)
    }
  }
  for stale_key in stale_keys {
    self.previous_depth_pyramids.remove(stale_key)
  }
}

///|
pub fn ResourceManager::bind_group_layout_count(self : ResourceManager) -> Int {
  let base_count = [
    self.clear_visibility_buffer_bind_group_layout_id,
    self.clear_visibility_buffer_shadow_view_bind_group_layout_id,
    self.first_instance_cull_bind_group_layout_id,
    self.second_instance_cull_bind_group_layout_id,
    self.first_bvh_cull_bind_group_layout_id,
    self.second_bvh_cull_bind_group_layout_id,
    self.first_meshlet_cull_bind_group_layout_id,
    self.second_meshlet_cull_bind_group_layout_id,
    self.visibility_buffer_raster_bind_group_layout_id,
    self.visibility_buffer_raster_shadow_view_bind_group_layout_id,
    self.downsample_depth_bind_group_layout_id,
    self.downsample_depth_shadow_view_bind_group_layout_id,
    self.resolve_depth_bind_group_layout_id,
    self.resolve_depth_shadow_view_bind_group_layout_id,
    self.resolve_material_depth_bind_group_layout_id,
    self.material_shade_bind_group_layout_id,
    self.fill_counts_bind_group_layout_id,
  ].fold(init=0, fn(acc, id) { if id >= 0 { acc + 1 } else { acc } })
  let optional_count = if self.remap_1d_to_2d_dispatch_bind_group_layout_id
    is Some(_) {
    1
  } else {
    0
  }
  base_count + optional_count
}

///|
pub struct MeshletViewResources {
  view_entity : @core.Entity
  meshlet_count : Int
  scene_instance_count : Int
  rightmost_slot : Int
  max_bvh_depth : Int
  view_width : Int
  view_height : Int
  not_shadow_view : Bool
  has_material_depth : Bool
}

///|
pub fn MeshletViewResources::new(
  view_entity : @core.Entity,
  meshlet_count : Int,
  scene_instance_count? : Int = meshlet_count,
  rightmost_slot? : Int = 0,
  max_bvh_depth? : Int = 0,
  view_width? : Int = 1,
  view_height? : Int = 1,
  not_shadow_view? : Bool = true,
  has_material_depth? : Bool = true,
) -> MeshletViewResources {
  MeshletViewResources::{
    view_entity,
    meshlet_count: meshlet_resource_non_negative(meshlet_count),
    scene_instance_count: meshlet_resource_non_negative(scene_instance_count),
    rightmost_slot: meshlet_resource_non_negative(rightmost_slot),
    max_bvh_depth: meshlet_resource_non_negative(max_bvh_depth),
    view_width: if view_width <= 0 {
      1
    } else {
      view_width
    },
    view_height: if view_height <= 0 {
      1
    } else {
      view_height
    },
    not_shadow_view,
    has_material_depth,
  }
}

///|
pub fn MeshletViewResources::has_material_depth(
  self : MeshletViewResources,
) -> Bool {
  self.has_material_depth
}

///|
pub fn MeshletViewResources::scene_instance_count(
  self : MeshletViewResources,
) -> Int {
  self.scene_instance_count
}

///|
pub fn MeshletViewResources::rightmost_slot(self : MeshletViewResources) -> Int {
  self.rightmost_slot
}

///|
pub fn MeshletViewResources::max_bvh_depth(self : MeshletViewResources) -> Int {
  self.max_bvh_depth
}

///|
pub fn MeshletViewResources::view_size(
  self : MeshletViewResources,
) -> (Int, Int) {
  (self.view_width, self.view_height)
}

///|
pub fn MeshletViewResources::not_shadow_view(
  self : MeshletViewResources,
) -> Bool {
  self.not_shadow_view
}

///|
pub fn ResourceManager::set_prepared_view_resources(
  self : ResourceManager,
  resources : MeshletViewResources,
) -> Unit {
  self.prepared_view_resources.set(resources.view_entity.to_bits(), resources)
}

///|
pub fn ResourceManager::prepared_view_resources(
  self : ResourceManager,
  view_entity : @core.Entity,
) -> MeshletViewResources? {
  self.prepared_view_resources.get(view_entity.to_bits())
}

///|
pub fn ResourceManager::prepared_view_resource_count(
  self : ResourceManager,
) -> Int {
  self.prepared_view_resources.length()
}

///|
pub fn ResourceManager::prepared_not_shadow_view_count(
  self : ResourceManager,
) -> Int {
  let mut count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.not_shadow_view() {
      count = count + 1
    }
  }
  count
}

///|
pub fn ResourceManager::prepared_shadow_view_count(
  self : ResourceManager,
) -> Int {
  let mut count = 0
  for resources in self.prepared_view_resources.values() {
    if !resources.not_shadow_view() {
      count = count + 1
    }
  }
  count
}

///|
pub fn ResourceManager::prepared_material_depth_view_count(
  self : ResourceManager,
) -> Int {
  let mut count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.not_shadow_view() && resources.has_material_depth() {
      count = count + 1
    }
  }
  count
}

///|
pub fn ResourceManager::prepared_max_bvh_depth(self : ResourceManager) -> Int {
  let mut max_depth = 0
  for resources in self.prepared_view_resources.values() {
    max_depth = max_depth.max(resources.max_bvh_depth())
  }
  max_depth
}

///|
pub fn ResourceManager::clear_stale_prepared_view_resources(
  self : ResourceManager,
  active_view_entities : Array[@core.Entity],
) -> Unit {
  let active : Map[UInt64, Bool] = {}
  for view_entity in active_view_entities {
    active.set(view_entity.to_bits(), true)
  }
  let stale_keys : Array[UInt64] = []
  for key in self.prepared_view_resources.keys() {
    if active.get(key) is None {
      stale_keys.push(key)
    }
  }
  for stale_key in stale_keys {
    self.prepared_view_resources.remove(stale_key)
  }
  let active_bits : Array[UInt64] = []
  for view_entity in active_view_entities {
    active_bits.push(view_entity.to_bits())
  }
  @renderer.clear_stale_meshlet_view_visibility_buffers(active_bits)
}

///|
pub struct MeshletViewBindGroups {
  view_entity : @core.Entity
  bind_group_count : Int
  has_material_shade_bind_group : Bool
}

///|
pub fn MeshletViewBindGroups::new(
  view_entity : @core.Entity,
  bind_group_count : Int,
  has_material_shade_bind_group? : Bool = true,
) -> MeshletViewBindGroups {
  MeshletViewBindGroups::{
    view_entity,
    bind_group_count: meshlet_resource_non_negative(bind_group_count),
    has_material_shade_bind_group,
  }
}

///|
pub fn MeshletViewBindGroups::has_material_shade_bind_group(
  self : MeshletViewBindGroups,
) -> Bool {
  self.has_material_shade_bind_group
}

///|
pub fn ResourceManager::set_prepared_view_bind_groups(
  self : ResourceManager,
  bind_groups : MeshletViewBindGroups,
) -> Unit {
  self.prepared_view_bind_groups.set(
    bind_groups.view_entity.to_bits(),
    bind_groups,
  )
}

///|
pub fn ResourceManager::prepared_view_bind_groups(
  self : ResourceManager,
  view_entity : @core.Entity,
) -> MeshletViewBindGroups? {
  self.prepared_view_bind_groups.get(view_entity.to_bits())
}

///|
pub fn ResourceManager::prepared_view_bind_group_count(
  self : ResourceManager,
) -> Int {
  self.prepared_view_bind_groups.length()
}

///|
pub fn ResourceManager::clear_stale_prepared_view_bind_groups(
  self : ResourceManager,
  active_view_entities : Array[@core.Entity],
) -> Unit {
  let active : Map[UInt64, Bool] = {}
  for view_entity in active_view_entities {
    active.set(view_entity.to_bits(), true)
  }
  let stale_keys : Array[UInt64] = []
  for key in self.prepared_view_bind_groups.keys() {
    if active.get(key) is None {
      stale_keys.push(key)
    }
  }
  for stale_key in stale_keys {
    self.prepared_view_bind_groups.remove(stale_key)
  }
}

///|
pub fn ResourceManager::execute_prepared_clear_visibility_buffers(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_clear_visibility_buffer(
        view_entity_bits=resources.view_entity.to_bits(),
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_first_instance_culls(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.scene_instance_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_first_instance_cull(
        view_entity_bits=resources.view_entity.to_bits(),
        scene_instance_count=resources.scene_instance_count,
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_first_bvh_culls(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.max_bvh_depth <= 0 {
      continue
    }
    if @renderer.execute_meshlet_first_bvh_cull(
        view_entity_bits=resources.view_entity.to_bits(),
        max_bvh_depth=resources.max_bvh_depth,
        rightmost_slot=resources.rightmost_slot,
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_first_meshlet_culls(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_first_meshlet_cull(
        view_entity_bits=resources.view_entity.to_bits(),
        rightmost_slot=resources.rightmost_slot,
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_second_instance_culls(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.scene_instance_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_second_instance_cull(
        view_entity_bits=resources.view_entity.to_bits(),
        scene_instance_count=resources.scene_instance_count,
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_second_bvh_culls(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.max_bvh_depth <= 0 {
      continue
    }
    if @renderer.execute_meshlet_second_bvh_cull(
        view_entity_bits=resources.view_entity.to_bits(),
        max_bvh_depth=resources.max_bvh_depth,
        rightmost_slot=resources.rightmost_slot,
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_second_meshlet_culls(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_second_meshlet_cull(
        view_entity_bits=resources.view_entity.to_bits(),
        rightmost_slot=resources.rightmost_slot,
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_visibility_buffer_software_raster(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_visibility_buffer_software_raster(
        view_entity_bits=resources.view_entity.to_bits(),
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_visibility_buffer_hardware_raster(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_visibility_buffer_hardware_raster(
        view_entity_bits=resources.view_entity.to_bits(),
        rightmost_slot=resources.rightmost_slot,
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_fill_counts(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_fill_counts(
        view_entity_bits=resources.view_entity.to_bits(),
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_downsample_depth(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_downsample_depth(
        view_entity_bits=resources.view_entity.to_bits(),
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_resolve_depth(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 {
      continue
    }
    if @renderer.execute_meshlet_resolve_depth(
        view_entity_bits=resources.view_entity.to_bits(),
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn ResourceManager::execute_prepared_resolve_material_depth(
  self : ResourceManager,
) -> Int {
  let mut dispatch_count = 0
  for resources in self.prepared_view_resources.values() {
    if resources.meshlet_count <= 0 ||
      !resources.not_shadow_view() ||
      !resources.has_material_depth() {
      continue
    }
    if @renderer.execute_meshlet_resolve_material_depth(
        view_entity_bits=resources.view_entity.to_bits(),
      ) {
      dispatch_count = dispatch_count + 1
    }
  }
  dispatch_count
}

///|
pub fn prepare_meshlet_per_frame_resources(
  manager : ResourceManager,
  meshlet_buffer_count : Int,
) -> Unit {
  manager.set_meshlet_buffer_count(meshlet_buffer_count)
  let slots = manager.cluster_buffer_slots()
  if slots <= 0 || meshlet_buffer_count <= 0 {
    manager.cull_queue_rightmost_slot = 0
  } else {
    let limited_count = if meshlet_buffer_count > slots {
      slots
    } else {
      meshlet_buffer_count
    }
    manager.cull_queue_rightmost_slot = limited_count - 1
  }
  @renderer.prepare_meshlet_frame_resources(
    cluster_buffer_slots=manager.cluster_buffer_slots(),
    scene_instance_count=meshlet_buffer_count,
  )
  manager.advance_frame()
}

///|
pub fn prepare_meshlet_view_resources(
  view_entity : @core.Entity,
  meshlet_count : Int,
  rightmost_slot? : Int = 0,
  max_bvh_depth? : Int = 0,
  view_width? : Int = 1,
  view_height? : Int = 1,
  not_shadow_view? : Bool = true,
) -> MeshletViewResources {
  MeshletViewResources::new(
    view_entity,
    meshlet_count,
    scene_instance_count=meshlet_count,
    rightmost_slot~,
    max_bvh_depth~,
    view_width~,
    view_height~,
    not_shadow_view~,
    has_material_depth=meshlet_count > 0,
  )
}

///|
pub fn prepare_meshlet_view_resources_for_view(
  manager : ResourceManager,
  view_entity : @core.Entity,
  meshlet_count : Int,
  max_bvh_depth? : Int = 0,
  view_width? : Int = 1,
  view_height? : Int = 1,
  not_shadow_view? : Bool = true,
) -> MeshletViewResources {
  let resources = prepare_meshlet_view_resources(
    view_entity,
    meshlet_count,
    rightmost_slot=manager.cull_queue_rightmost_slot(),
    max_bvh_depth~,
    view_width~,
    view_height~,
    not_shadow_view~,
  )
  manager.set_prepared_view_resources(resources)
  @renderer.prepare_meshlet_view_visibility_buffer(
    view_entity_bits=view_entity.to_bits(),
    view_width=resources.view_width,
    view_height=resources.view_height,
    not_shadow_view=resources.not_shadow_view,
  )
  resources
}

///|
pub fn prepare_meshlet_view_bind_groups(
  view_entity : @core.Entity,
  bind_group_count : Int,
) -> MeshletViewBindGroups {
  MeshletViewBindGroups::new(
    view_entity,
    bind_group_count,
    has_material_shade_bind_group=bind_group_count > 0,
  )
}

///|
pub fn prepare_meshlet_view_bind_groups_for_view(
  manager : ResourceManager,
  view_entity : @core.Entity,
  bind_group_count : Int,
) -> MeshletViewBindGroups {
  let bind_groups = prepare_meshlet_view_bind_groups(
    view_entity, bind_group_count,
  )
  manager.set_prepared_view_bind_groups(bind_groups)
  bind_groups
}
