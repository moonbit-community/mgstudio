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
// Bevy source: `bevy/crates/bevy_render/src/mesh/allocator.rs`.

///|
const MESH_ALLOCATOR_PLUGIN_NAME : String = "mgstudio.render.mesh.MeshAllocatorPlugin"

///|
pub const MESH_ALLOCATOR_COPY_BUFFER_ALIGNMENT : Int = 4

///|
pub(all) enum MeshAllocatorElementClass {
  Vertex
  Index
} derive(Eq, Debug)

///|
pub(all) enum MeshAllocatorSlabKind {
  General
  LargeObject
} derive(Eq, Debug)

///|
pub(all) enum MeshAllocatorSlabGrowthKind {
  NoGrowthNeeded
  NeededGrowth
  CantGrow
} derive(Eq, Debug)

///|
pub struct MeshSlabs {
  vertex_slab_id : Int
  index_slab_id : Int?
  morph_target_slab_id : Int?
} derive(Eq, Debug)

///|
pub fn MeshSlabs::new(
  vertex_slab_id : Int,
  index_slab_id? : Int? = None,
  morph_target_slab_id? : Int? = None,
) -> MeshSlabs {
  MeshSlabs::{ vertex_slab_id, index_slab_id, morph_target_slab_id }
}

///|
pub fn MeshSlabs::vertex_slab_id(self : MeshSlabs) -> Int {
  self.vertex_slab_id
}

///|
pub fn MeshSlabs::index_slab_id(self : MeshSlabs) -> Int? {
  self.index_slab_id
}

///|
pub fn MeshSlabs::morph_target_slab_id(self : MeshSlabs) -> Int? {
  self.morph_target_slab_id
}

///|
pub struct MeshAllocatorSettings {
  min_slab_size : Int
  max_slab_size : Int
  large_threshold : Int
  growth_factor : Float
}

///|
pub fn MeshAllocatorSettings::new(
  min_slab_size~ : Int,
  max_slab_size~ : Int,
  large_threshold~ : Int,
  growth_factor~ : Float,
) -> MeshAllocatorSettings {
  MeshAllocatorSettings::{
    min_slab_size,
    max_slab_size,
    large_threshold,
    growth_factor,
  }
}

///|
pub fn MeshAllocatorSettings::MeshAllocatorSettings() -> MeshAllocatorSettings {
  MeshAllocatorSettings::new(
    min_slab_size=1024 * 1024,
    max_slab_size=1024 * 1024 * 512,
    large_threshold=1024 * 1024 * 256,
    growth_factor=1.5F,
  )
}

///|
pub impl Default for MeshAllocatorSettings with fn default() {
  MeshAllocatorSettings::MeshAllocatorSettings()
}

///|
pub let mesh_allocator_settings_resource_key : @ecs.ResourceKey[
  MeshAllocatorSettings,
] = @ecs.register_resource(debug_name="mgstudio_render::MeshAllocatorSettings")

///|
pub impl @app.Resource for MeshAllocatorSettings with fn resource() {
  mesh_allocator_settings_resource_key
}

///|
pub fn MeshAllocatorSettings::min_slab_size(
  self : MeshAllocatorSettings,
) -> Int {
  self.min_slab_size
}

///|
pub fn MeshAllocatorSettings::max_slab_size(
  self : MeshAllocatorSettings,
) -> Int {
  self.max_slab_size
}

///|
pub fn MeshAllocatorSettings::large_threshold(
  self : MeshAllocatorSettings,
) -> Int {
  self.large_threshold
}

///|
pub fn MeshAllocatorSettings::growth_factor(
  self : MeshAllocatorSettings,
) -> Float {
  self.growth_factor
}

///|
pub struct MeshAllocatorElementLayout {
  class : MeshAllocatorElementClass
  size : Int
  elements_per_slot : Int
} derive(Eq, Debug)

///|
pub fn MeshAllocatorElementLayout::new(
  class : MeshAllocatorElementClass,
  size : Int,
) -> MeshAllocatorElementLayout {
  if size <= 0 {
    abort("mesh allocator element size must be positive")
  }
  let elements_per_slot = match size % MESH_ALLOCATOR_COPY_BUFFER_ALIGNMENT {
    0 => 1
    1 => 4
    2 => 2
    _ => 4
  }
  MeshAllocatorElementLayout::{ class, size, elements_per_slot }
}

///|
pub fn MeshAllocatorElementLayout::vertex(
  vertex_stride : Int,
) -> MeshAllocatorElementLayout {
  MeshAllocatorElementLayout::new(Vertex, vertex_stride)
}

///|
pub fn MeshAllocatorElementLayout::index_u16() -> MeshAllocatorElementLayout {
  MeshAllocatorElementLayout::new(Index, 2)
}

///|
pub fn MeshAllocatorElementLayout::index_u32() -> MeshAllocatorElementLayout {
  MeshAllocatorElementLayout::new(Index, 4)
}

///|
pub fn MeshAllocatorElementLayout::class(
  self : MeshAllocatorElementLayout,
) -> MeshAllocatorElementClass {
  self.class
}

///|
pub fn MeshAllocatorElementLayout::size(
  self : MeshAllocatorElementLayout,
) -> Int {
  self.size
}

///|
pub fn MeshAllocatorElementLayout::elements_per_slot(
  self : MeshAllocatorElementLayout,
) -> Int {
  self.elements_per_slot
}

///|
pub fn MeshAllocatorElementLayout::slot_size(
  self : MeshAllocatorElementLayout,
) -> Int {
  self.size * self.elements_per_slot
}

///|
pub struct MeshAllocatorSlabGrowth {
  kind : MeshAllocatorSlabGrowthKind
  old_slot_capacity : Int
  current_slot_capacity : Int
} derive(Eq, Debug)

///|
pub fn MeshAllocatorSlabGrowth::kind(
  self : MeshAllocatorSlabGrowth,
) -> MeshAllocatorSlabGrowthKind {
  self.kind
}

///|
pub fn MeshAllocatorSlabGrowth::old_slot_capacity(
  self : MeshAllocatorSlabGrowth,
) -> Int {
  self.old_slot_capacity
}

///|
pub fn MeshAllocatorSlabGrowth::current_slot_capacity(
  self : MeshAllocatorSlabGrowth,
) -> Int {
  self.current_slot_capacity
}

///|
pub struct MeshAllocatorSlabPlan {
  slab_id : Int
  kind : MeshAllocatorSlabKind
  layout : MeshAllocatorElementLayout
  offset : Int
  slot_count : Int
  current_slot_capacity : Int
  growth : MeshAllocatorSlabGrowth
} derive(Eq, Debug)

///|
pub fn MeshAllocatorSlabPlan::slab_id(self : MeshAllocatorSlabPlan) -> Int {
  self.slab_id
}

///|
pub fn MeshAllocatorSlabPlan::kind(
  self : MeshAllocatorSlabPlan,
) -> MeshAllocatorSlabKind {
  self.kind
}

///|
pub fn MeshAllocatorSlabPlan::layout(
  self : MeshAllocatorSlabPlan,
) -> MeshAllocatorElementLayout {
  self.layout
}

///|
pub fn MeshAllocatorSlabPlan::offset(self : MeshAllocatorSlabPlan) -> Int {
  self.offset
}

///|
pub fn MeshAllocatorSlabPlan::slot_count(self : MeshAllocatorSlabPlan) -> Int {
  self.slot_count
}

///|
pub fn MeshAllocatorSlabPlan::current_slot_capacity(
  self : MeshAllocatorSlabPlan,
) -> Int {
  self.current_slot_capacity
}

///|
pub fn MeshAllocatorSlabPlan::growth(
  self : MeshAllocatorSlabPlan,
) -> MeshAllocatorSlabGrowth {
  self.growth
}

///|
fn mesh_allocator_div_ceil(value : Int, divisor : Int) -> Int {
  if divisor <= 0 {
    abort("mesh allocator divisor must be positive")
  }
  if value <= 0 {
    0
  } else {
    (value + divisor - 1) / divisor
  }
}

///|
fn mesh_allocator_min_allocator_size(slot_count : Int) -> Int {
  if slot_count <= 0 {
    1
  } else {
    slot_count
  }
}

///|
fn mesh_allocator_initial_general_slab_slot_capacity(
  layout : MeshAllocatorElementLayout,
  data_slot_count : Int,
  settings : MeshAllocatorSettings,
) -> Int {
  mesh_allocator_div_ceil(settings.min_slab_size, layout.slot_size()).max(
    mesh_allocator_min_allocator_size(data_slot_count),
  )
}

///|
fn mesh_allocator_max_general_slab_slot_capacity(
  layout : MeshAllocatorElementLayout,
  data_slot_count : Int,
  settings : MeshAllocatorSettings,
) -> Int {
  mesh_allocator_div_ceil(settings.max_slab_size, layout.slot_size()).max(
    mesh_allocator_min_allocator_size(data_slot_count),
  )
}

///|
fn mesh_allocator_growth_capacity(
  current_slot_capacity : Int,
  settings : MeshAllocatorSettings,
  layout : MeshAllocatorElementLayout,
) -> Int {
  let grown = @float.ceil(
      Float::from_int(current_slot_capacity) * settings.growth_factor,
    )
    .to_double()
    .to_int()
  let max_slots = settings.max_slab_size / layout.slot_size()
  grown.min(max_slots)
}

///|
pub fn mesh_allocator_grow_general_slab_if_necessary(
  current_slot_capacity : Int,
  new_size_in_slots : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::MeshAllocatorSettings(),
) -> MeshAllocatorSlabGrowth {
  let initial_slot_capacity = current_slot_capacity
  if current_slot_capacity >= new_size_in_slots {
    return MeshAllocatorSlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: initial_slot_capacity,
      current_slot_capacity,
    }
  }
  let mut capacity = current_slot_capacity
  while capacity < new_size_in_slots {
    let next_capacity = mesh_allocator_growth_capacity(
      capacity, settings, layout,
    )
    if next_capacity == capacity {
      return MeshAllocatorSlabGrowth::{
        kind: CantGrow,
        old_slot_capacity: initial_slot_capacity,
        current_slot_capacity: capacity,
      }
    }
    capacity = next_capacity
  }
  MeshAllocatorSlabGrowth::{
    kind: NeededGrowth,
    old_slot_capacity: initial_slot_capacity,
    current_slot_capacity: capacity,
  }
}

///|
pub fn mesh_allocator_plan_new_general_slab(
  slab_id : Int,
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::MeshAllocatorSettings(),
) -> MeshAllocatorSlabPlan {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  let data_slot_count = mesh_allocator_div_ceil(
    data_element_count,
    layout.elements_per_slot(),
  )
  let current_slot_capacity = mesh_allocator_initial_general_slab_slot_capacity(
    layout, data_slot_count, settings,
  )
  ignore(
    mesh_allocator_max_general_slab_slot_capacity(
      layout, data_slot_count, settings,
    ),
  )
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: General,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity,
    growth: MeshAllocatorSlabGrowth::{
      kind: NeededGrowth,
      old_slot_capacity: 0,
      current_slot_capacity,
    },
  }
}

///|
pub fn mesh_allocator_plan_large_slab(
  slab_id : Int,
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
) -> MeshAllocatorSlabPlan {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  let data_slot_count = mesh_allocator_div_ceil(
    data_element_count,
    layout.elements_per_slot(),
  )
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: LargeObject,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity: data_slot_count,
    growth: MeshAllocatorSlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: data_slot_count,
      current_slot_capacity: data_slot_count,
    },
  }
}

///|
pub fn mesh_allocator_should_allocate_large(
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::MeshAllocatorSettings(),
) -> Bool {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  let data_slot_count = mesh_allocator_div_ceil(
    data_element_count,
    layout.elements_per_slot(),
  )
  data_slot_count * layout.slot_size() >=
  settings.large_threshold.min(settings.max_slab_size)
}

///|
pub(all) enum MeshAllocatorAllocationResidency {
  Pending
  Resident
} derive(Eq, Debug)

///|
pub struct MeshAllocatorSlice {
  slab_id : Int
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn MeshAllocatorSlice::slab_id(self : MeshAllocatorSlice) -> Int {
  self.slab_id
}

///|
pub fn MeshAllocatorSlice::start(self : MeshAllocatorSlice) -> Int {
  self.start
}

///|
pub fn MeshAllocatorSlice::end(self : MeshAllocatorSlice) -> Int {
  self.end
}

///|
pub(all) enum MeshAllocatorBufferUsage {
  VertexBuffer
  IndexBuffer
} derive(Eq, Debug)

///|
pub struct MeshAllocatorBufferPlan {
  slab_id : Int
  label : String
  usage : MeshAllocatorBufferUsage
  size : Int
  mapped_at_creation : Bool
} derive(Eq, Debug)

///|
pub fn MeshAllocatorBufferPlan::slab_id(self : MeshAllocatorBufferPlan) -> Int {
  self.slab_id
}

///|
pub fn MeshAllocatorBufferPlan::label(self : MeshAllocatorBufferPlan) -> String {
  self.label
}

///|
pub fn MeshAllocatorBufferPlan::usage(
  self : MeshAllocatorBufferPlan,
) -> MeshAllocatorBufferUsage {
  self.usage
}

///|
pub fn MeshAllocatorBufferPlan::size(self : MeshAllocatorBufferPlan) -> Int {
  self.size
}

///|
pub fn MeshAllocatorBufferPlan::mapped_at_creation(
  self : MeshAllocatorBufferPlan,
) -> Bool {
  self.mapped_at_creation
}

///|
pub fn MeshAllocatorBufferUsage::is_vertex_buffer(
  self : MeshAllocatorBufferUsage,
) -> Bool {
  self == VertexBuffer
}

///|
pub fn MeshAllocatorBufferUsage::is_index_buffer(
  self : MeshAllocatorBufferUsage,
) -> Bool {
  self == IndexBuffer
}

///|
pub struct MeshAllocatorUploadPlan {
  slab_id : Int
  label : String
  usage : MeshAllocatorBufferUsage
  offset : Int
  size : Int
  mapped_at_creation : Bool
} derive(Eq, Debug)

///|
pub fn MeshAllocatorUploadPlan::slab_id(self : MeshAllocatorUploadPlan) -> Int {
  self.slab_id
}

///|
pub fn MeshAllocatorUploadPlan::label(self : MeshAllocatorUploadPlan) -> String {
  self.label
}

///|
pub fn MeshAllocatorUploadPlan::usage(
  self : MeshAllocatorUploadPlan,
) -> MeshAllocatorBufferUsage {
  self.usage
}

///|
pub fn MeshAllocatorUploadPlan::offset(self : MeshAllocatorUploadPlan) -> Int {
  self.offset
}

///|
pub fn MeshAllocatorUploadPlan::size(self : MeshAllocatorUploadPlan) -> Int {
  self.size
}

///|
pub fn MeshAllocatorUploadPlan::mapped_at_creation(
  self : MeshAllocatorUploadPlan,
) -> Bool {
  self.mapped_at_creation
}

///|
pub struct MeshAllocatorReallocateSlabPlan {
  slab_id : Int
  label : String
  usage : MeshAllocatorBufferUsage
  new_size : Int
  old_copy_size : Int
} derive(Eq, Debug)

///|
pub fn MeshAllocatorReallocateSlabPlan::slab_id(
  self : MeshAllocatorReallocateSlabPlan,
) -> Int {
  self.slab_id
}

///|
pub fn MeshAllocatorReallocateSlabPlan::label(
  self : MeshAllocatorReallocateSlabPlan,
) -> String {
  self.label
}

///|
pub fn MeshAllocatorReallocateSlabPlan::usage(
  self : MeshAllocatorReallocateSlabPlan,
) -> MeshAllocatorBufferUsage {
  self.usage
}

///|
pub fn MeshAllocatorReallocateSlabPlan::new_size(
  self : MeshAllocatorReallocateSlabPlan,
) -> Int {
  self.new_size
}

///|
pub fn MeshAllocatorReallocateSlabPlan::old_copy_size(
  self : MeshAllocatorReallocateSlabPlan,
) -> Int {
  self.old_copy_size
}

///|
pub struct MeshAllocatorRenderMeshPlan {
  vertex_allocation : MeshAllocatorSlabPlan?
  index_allocation : MeshAllocatorSlabPlan?
  vertex_upload : MeshAllocatorUploadPlan?
  index_upload : MeshAllocatorUploadPlan?
  vertex_reallocate : MeshAllocatorReallocateSlabPlan?
  index_reallocate : MeshAllocatorReallocateSlabPlan?
} derive(Eq, Debug)

///|
pub fn MeshAllocatorRenderMeshPlan::vertex_allocation(
  self : MeshAllocatorRenderMeshPlan,
) -> MeshAllocatorSlabPlan? {
  self.vertex_allocation
}

///|
pub fn MeshAllocatorRenderMeshPlan::index_allocation(
  self : MeshAllocatorRenderMeshPlan,
) -> MeshAllocatorSlabPlan? {
  self.index_allocation
}

///|
pub fn MeshAllocatorRenderMeshPlan::vertex_upload(
  self : MeshAllocatorRenderMeshPlan,
) -> MeshAllocatorUploadPlan? {
  self.vertex_upload
}

///|
pub fn MeshAllocatorRenderMeshPlan::index_upload(
  self : MeshAllocatorRenderMeshPlan,
) -> MeshAllocatorUploadPlan? {
  self.index_upload
}

///|
pub fn MeshAllocatorRenderMeshPlan::vertex_reallocate(
  self : MeshAllocatorRenderMeshPlan,
) -> MeshAllocatorReallocateSlabPlan? {
  self.vertex_reallocate
}

///|
pub fn MeshAllocatorRenderMeshPlan::index_reallocate(
  self : MeshAllocatorRenderMeshPlan,
) -> MeshAllocatorReallocateSlabPlan? {
  self.index_reallocate
}

///|
pub(all) struct MeshAllocatorSlabAllocation {
  mesh_id : Int
  offset : Int
  slot_count : Int
  residency : MeshAllocatorAllocationResidency
}

///|
pub(all) struct MeshAllocatorFreeRange {
  offset : Int
  slot_count : Int
}

///|
pub(all) struct MeshAllocatorSlabState {
  id : Int
  kind : MeshAllocatorSlabKind
  layout : MeshAllocatorElementLayout
  mut current_slot_capacity : Int
  max_slot_capacity : Int
  allocations : Array[MeshAllocatorSlabAllocation]
  free_ranges : Array[MeshAllocatorFreeRange]
}

///|
pub(all) struct MeshAllocatorMeshSlabEntry {
  mesh_id : Int
  slab_id : Int
}

///|
pub struct MeshAllocator {
  slabs : Array[MeshAllocatorSlabState]
  mesh_id_to_vertex_slab : Array[MeshAllocatorMeshSlabEntry]
  mesh_id_to_index_slab : Array[MeshAllocatorMeshSlabEntry]
  mut next_slab_id : Int
  general_vertex_slabs_supported : Bool
}

///|
pub fn MeshAllocator::new(
  general_vertex_slabs_supported? : Bool = true,
) -> MeshAllocator {
  MeshAllocator::{
    slabs: [],
    mesh_id_to_vertex_slab: [],
    mesh_id_to_index_slab: [],
    next_slab_id: 0,
    general_vertex_slabs_supported,
  }
}

///|
pub fn MeshAllocator::MeshAllocator() -> MeshAllocator {
  MeshAllocator::new()
}

///|
pub impl Default for MeshAllocator with fn default() {
  MeshAllocator::MeshAllocator()
}

///|
pub let mesh_allocator_resource_key : @ecs.ResourceKey[MeshAllocator] = @ecs.register_resource(
  debug_name="mgstudio_render::MeshAllocator",
)

///|
pub impl @app.Resource for MeshAllocator with fn resource() {
  mesh_allocator_resource_key
}

///|
pub struct MeshAllocatorPlugin {}

///|
pub fn MeshAllocatorPlugin::MeshAllocatorPlugin() -> MeshAllocatorPlugin {
  MeshAllocatorPlugin::{  }
}

///|
pub fn mesh_allocator_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  mesh_allocator_plugin_with(app, MeshAllocatorPlugin::MeshAllocatorPlugin())
}

///|
pub impl @app.Plugin for MeshAllocatorPlugin with fn name(_self) {
  MESH_ALLOCATOR_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MeshAllocatorPlugin with fn build(self, app) {
  mesh_allocator_plugin_with(app, self)
}

///|
pub fn mesh_allocator_plugin_with(
  app : @app.App[@ecs.World],
  plugin : MeshAllocatorPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app
  .init_resource(fn() { MeshAllocatorSettings::MeshAllocatorSettings() })
  .init_resource(fn() { MeshAllocator::MeshAllocator() })
  .init_resource(fn() { RenderMeshAssets::RenderMeshAssets() })
}

///|
fn mesh_allocator_layout_eq(
  left : MeshAllocatorElementLayout,
  right : MeshAllocatorElementLayout,
) -> Bool {
  left.class == right.class &&
  left.size == right.size &&
  left.elements_per_slot == right.elements_per_slot
}

///|
fn mesh_allocator_data_slot_count(
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
) -> Int {
  let data_element_count = mesh_allocator_div_ceil(data_byte_len, layout.size())
  mesh_allocator_div_ceil(data_element_count, layout.elements_per_slot())
}

///|
fn mesh_allocator_next_multiple_of(value : Int, quantum : Int) -> Int {
  mesh_allocator_div_ceil(value, quantum) * quantum
}

///|
fn mesh_allocator_buffer_usage(
  element_class : MeshAllocatorElementClass,
) -> MeshAllocatorBufferUsage {
  match element_class {
    Vertex => VertexBuffer
    Index => IndexBuffer
  }
}

///|
fn mesh_allocator_buffer_usage_label(
  usage : MeshAllocatorBufferUsage,
) -> String {
  match usage {
    VertexBuffer => "vertex "
    IndexBuffer => "index "
  }
}

///|
fn mesh_allocator_buffer_label(
  kind : MeshAllocatorSlabKind,
  slab_id : Int,
  usage : MeshAllocatorBufferUsage,
) -> String {
  let slab_kind = match kind {
    General => "general"
    LargeObject => "large"
  }
  "\{slab_kind} mesh slab \{slab_id} (\{mesh_allocator_buffer_usage_label(usage)}buffer)"
}

///|
fn MeshAllocator::allocate_slab_id(self : MeshAllocator) -> Int {
  let slab_id = self.next_slab_id
  self.next_slab_id = self.next_slab_id + 1
  slab_id
}

///|
fn mesh_allocator_find_slab_index(
  slabs : Array[MeshAllocatorSlabState],
  slab_id : Int,
) -> Int? {
  for index in 0..<slabs.length() {
    if slabs[index].id == slab_id {
      return Some(index)
    }
  }
  None
}

///|
fn mesh_allocator_find_map_index(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
) -> Int? {
  for index in 0..<entries.length() {
    if entries[index].mesh_id == mesh_id {
      return Some(index)
    }
  }
  None
}

///|
fn mesh_allocator_record_map(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
  slab_id : Int,
) -> Unit {
  match mesh_allocator_find_map_index(entries, mesh_id) {
    Some(index) =>
      entries[index] = MeshAllocatorMeshSlabEntry::{ mesh_id, slab_id }
    None => entries.push(MeshAllocatorMeshSlabEntry::{ mesh_id, slab_id })
  }
}

///|
fn mesh_allocator_remove_map(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
) -> Int? {
  match mesh_allocator_find_map_index(entries, mesh_id) {
    Some(index) => {
      let entry = entries[index]
      ignore(entries.remove(index))
      Some(entry.slab_id)
    }
    None => None
  }
}

///|
fn mesh_allocator_lookup_map(
  entries : Array[MeshAllocatorMeshSlabEntry],
  mesh_id : Int,
) -> Int? {
  match mesh_allocator_find_map_index(entries, mesh_id) {
    Some(index) => Some(entries[index].slab_id)
    None => None
  }
}

///|
fn MeshAllocator::record_allocation(
  self : MeshAllocator,
  mesh_id : Int,
  slab_id : Int,
  element_class : MeshAllocatorElementClass,
) -> Unit {
  match element_class {
    Vertex =>
      mesh_allocator_record_map(self.mesh_id_to_vertex_slab, mesh_id, slab_id)
    Index =>
      mesh_allocator_record_map(self.mesh_id_to_index_slab, mesh_id, slab_id)
  }
}

///|
fn mesh_allocator_merge_free_ranges(
  free_ranges : Array[MeshAllocatorFreeRange],
) -> Unit {
  free_ranges.sort_by(fn(left, right) {
    if left.offset < right.offset {
      -1
    } else if left.offset > right.offset {
      1
    } else {
      0
    }
  })
  let mut index = 0
  while index + 1 < free_ranges.length() {
    let current = free_ranges[index]
    let next = free_ranges[index + 1]
    if current.offset + current.slot_count >= next.offset {
      let merged_end = (current.offset + current.slot_count).max(
        next.offset + next.slot_count,
      )
      free_ranges[index] = MeshAllocatorFreeRange::{
        offset: current.offset,
        slot_count: merged_end - current.offset,
      }
      ignore(free_ranges.remove(index + 1))
    } else {
      index = index + 1
    }
  }
}

///|
fn MeshAllocatorSlabState::is_empty(self : MeshAllocatorSlabState) -> Bool {
  self.allocations.is_empty()
}

///|
fn MeshAllocatorSlabState::buffer_size(self : MeshAllocatorSlabState) -> Int {
  self.current_slot_capacity * self.layout.slot_size()
}

///|
fn MeshAllocatorSlabState::try_allocate_free_range(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
  data_slot_count : Int,
) -> MeshAllocatorSlabAllocation? {
  for range_index in 0..<self.free_ranges.length() {
    let free_range = self.free_ranges[range_index]
    if free_range.slot_count >= data_slot_count {
      let allocation = MeshAllocatorSlabAllocation::{
        mesh_id,
        offset: free_range.offset,
        slot_count: data_slot_count,
        residency: Pending,
      }
      if free_range.slot_count == data_slot_count {
        ignore(self.free_ranges.remove(range_index))
      } else {
        self.free_ranges[range_index] = MeshAllocatorFreeRange::{
          offset: free_range.offset + data_slot_count,
          slot_count: free_range.slot_count - data_slot_count,
        }
      }
      self.allocations.push(allocation)
      return Some(allocation)
    }
  }
  None
}

///|
fn MeshAllocatorSlabState::grow_if_necessary(
  self : MeshAllocatorSlabState,
  new_size_in_slots : Int,
  settings : MeshAllocatorSettings,
) -> MeshAllocatorSlabGrowth {
  let growth = mesh_allocator_grow_general_slab_if_necessary(
    self.current_slot_capacity,
    new_size_in_slots,
    self.layout,
    settings~,
  )
  if growth.kind == NeededGrowth {
    self.current_slot_capacity = growth.current_slot_capacity
  }
  growth
}

///|
fn MeshAllocatorSlabState::remove_allocation(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
) -> Bool {
  for index in 0..<self.allocations.length() {
    let allocation = self.allocations[index]
    if allocation.mesh_id == mesh_id {
      self.free_ranges.push(MeshAllocatorFreeRange::{
        offset: allocation.offset,
        slot_count: allocation.slot_count,
      })
      ignore(self.allocations.remove(index))
      mesh_allocator_merge_free_ranges(self.free_ranges)
      return true
    }
  }
  false
}

///|
fn MeshAllocatorSlabState::mark_resident(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
) -> Bool {
  for index in 0..<self.allocations.length() {
    let allocation = self.allocations[index]
    if allocation.mesh_id == mesh_id {
      self.allocations[index] = MeshAllocatorSlabAllocation::{
        ..allocation,
        residency: Resident,
      }
      return true
    }
  }
  false
}

///|
fn MeshAllocatorSlabState::slice_for_mesh(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
) -> MeshAllocatorSlice? {
  for allocation in self.allocations {
    if allocation.mesh_id == mesh_id {
      return Some(MeshAllocatorSlice::{
        slab_id: self.id,
        start: allocation.offset * self.layout.elements_per_slot,
        end: (allocation.offset + allocation.slot_count) *
        self.layout.elements_per_slot,
      })
    }
  }
  None
}

///|
fn MeshAllocatorSlabState::buffer_plan(
  self : MeshAllocatorSlabState,
  mapped_at_creation : Bool,
) -> MeshAllocatorBufferPlan {
  let usage = mesh_allocator_buffer_usage(self.layout.class)
  MeshAllocatorBufferPlan::{
    slab_id: self.id,
    label: mesh_allocator_buffer_label(self.kind, self.id, usage),
    usage,
    size: self.current_slot_capacity * self.layout.slot_size(),
    mapped_at_creation,
  }
}

///|
fn MeshAllocatorSlabState::upload_plan_for_mesh(
  self : MeshAllocatorSlabState,
  mesh_id : Int,
  data_byte_len : Int,
) -> MeshAllocatorUploadPlan? {
  for allocation in self.allocations {
    if allocation.mesh_id == mesh_id {
      if allocation.residency != Pending {
        return None
      }
      let usage = mesh_allocator_buffer_usage(self.layout.class)
      let slot_size = self.layout.slot_size()
      return Some(MeshAllocatorUploadPlan::{
        slab_id: self.id,
        label: mesh_allocator_buffer_label(self.kind, self.id, usage),
        usage,
        offset: if self.kind == LargeObject {
          0
        } else {
          allocation.offset * slot_size
        },
        size: if self.kind == LargeObject {
          data_byte_len
        } else {
          mesh_allocator_next_multiple_of(data_byte_len, slot_size)
        },
        mapped_at_creation: self.kind == LargeObject,
      })
    }
  }
  None
}

///|
fn MeshAllocator::allocate_large(
  self : MeshAllocator,
  mesh_id : Int,
  data_slot_count : Int,
  layout : MeshAllocatorElementLayout,
) -> MeshAllocatorSlabPlan {
  let slab_id = self.allocate_slab_id()
  self.record_allocation(mesh_id, slab_id, layout.class)
  self.slabs.push(MeshAllocatorSlabState::{
    id: slab_id,
    kind: LargeObject,
    layout,
    current_slot_capacity: data_slot_count,
    max_slot_capacity: data_slot_count,
    allocations: [
      MeshAllocatorSlabAllocation::{
        mesh_id,
        offset: 0,
        slot_count: data_slot_count,
        residency: Pending,
      },
    ],
    free_ranges: [],
  })
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: LargeObject,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity: data_slot_count,
    growth: MeshAllocatorSlabGrowth::{
      kind: NoGrowthNeeded,
      old_slot_capacity: data_slot_count,
      current_slot_capacity: data_slot_count,
    },
  }
}

///|
fn MeshAllocator::allocate_general(
  self : MeshAllocator,
  mesh_id : Int,
  data_slot_count : Int,
  layout : MeshAllocatorElementLayout,
  settings : MeshAllocatorSettings,
) -> MeshAllocatorSlabPlan {
  for slab_index in 0..<self.slabs.length() {
    let slab = self.slabs[slab_index]
    if slab.kind == General && mesh_allocator_layout_eq(slab.layout, layout) {
      match slab.try_allocate_free_range(mesh_id, data_slot_count) {
        Some(allocation) => {
          let growth = slab.grow_if_necessary(
            allocation.offset + data_slot_count,
            settings,
          )
          if growth.kind == CantGrow {
            ignore(slab.remove_allocation(mesh_id))
            continue
          }
          self.record_allocation(mesh_id, slab.id, layout.class)
          return MeshAllocatorSlabPlan::{
            slab_id: slab.id,
            kind: General,
            layout,
            offset: allocation.offset,
            slot_count: data_slot_count,
            current_slot_capacity: slab.current_slot_capacity,
            growth,
          }
        }
        None => ()
      }
    }
  }
  let slab_id = self.allocate_slab_id()
  let initial_slot_capacity = mesh_allocator_initial_general_slab_slot_capacity(
    layout, data_slot_count, settings,
  )
  let max_slot_capacity = mesh_allocator_max_general_slab_slot_capacity(
    layout, data_slot_count, settings,
  )
  let free_ranges = if max_slot_capacity > data_slot_count {
    [
      MeshAllocatorFreeRange::{
        offset: data_slot_count,
        slot_count: max_slot_capacity - data_slot_count,
      },
    ]
  } else {
    []
  }
  self.slabs.push(MeshAllocatorSlabState::{
    id: slab_id,
    kind: General,
    layout,
    current_slot_capacity: initial_slot_capacity,
    max_slot_capacity,
    allocations: [
      MeshAllocatorSlabAllocation::{
        mesh_id,
        offset: 0,
        slot_count: data_slot_count,
        residency: Pending,
      },
    ],
    free_ranges,
  })
  self.record_allocation(mesh_id, slab_id, layout.class)
  MeshAllocatorSlabPlan::{
    slab_id,
    kind: General,
    layout,
    offset: 0,
    slot_count: data_slot_count,
    current_slot_capacity: initial_slot_capacity,
    growth: MeshAllocatorSlabGrowth::{
      kind: NeededGrowth,
      old_slot_capacity: 0,
      current_slot_capacity: initial_slot_capacity,
    },
  }
}

///|
pub fn MeshAllocator::allocate(
  self : MeshAllocator,
  mesh_id : Int,
  data_byte_len : Int,
  layout : MeshAllocatorElementLayout,
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::MeshAllocatorSettings(),
) -> MeshAllocatorSlabPlan? {
  if data_byte_len <= 0 {
    return None
  }
  let data_slot_count = mesh_allocator_data_slot_count(data_byte_len, layout)
  if layout.class == Vertex && !self.general_vertex_slabs_supported {
    return Some(self.allocate_large(mesh_id, data_slot_count, layout))
  }
  if data_slot_count * layout.slot_size() >=
    settings.large_threshold.min(settings.max_slab_size) {
    Some(self.allocate_large(mesh_id, data_slot_count, layout))
  } else {
    Some(self.allocate_general(mesh_id, data_slot_count, layout, settings))
  }
}

///|
fn MeshAllocator::reallocate_plan_for_allocation(
  self : MeshAllocator,
  allocation : MeshAllocatorSlabPlan?,
) -> MeshAllocatorReallocateSlabPlan? {
  match allocation {
    Some(plan) =>
      if plan.growth().kind() == NeededGrowth {
        self.reallocate_slab_plan(
          plan.slab_id(),
          plan.growth().old_slot_capacity(),
        )
      } else {
        None
      }
    None => None
  }
}

///|
fn mesh_allocator_render_mesh_index_byte_len(
  mesh : RenderMesh,
  index_layout : MeshAllocatorElementLayout,
) -> Int? {
  match mesh.buffer_info() {
    Indexed(index_count, _) =>
      if index_count > 0 {
        Some(index_count * index_layout.size())
      } else {
        None
      }
    NonIndexed => None
  }
}

///|
fn mesh_allocator_render_mesh_index_layout(
  mesh : RenderMesh,
) -> MeshAllocatorElementLayout {
  match mesh.buffer_info() {
    Indexed(_, Uint16) => MeshAllocatorElementLayout::index_u16()
    Indexed(_, Uint32) => MeshAllocatorElementLayout::index_u32()
    NonIndexed => MeshAllocatorElementLayout::index_u32()
  }
}

///|
pub fn MeshAllocator::allocate_render_mesh(
  self : MeshAllocator,
  mesh_id : Int,
  mesh : RenderMesh,
  vertex_stride : Int,
  index_layout? : MeshAllocatorElementLayout = mesh_allocator_render_mesh_index_layout(
    mesh,
  ),
  settings? : MeshAllocatorSettings = MeshAllocatorSettings::MeshAllocatorSettings(),
) -> MeshAllocatorRenderMeshPlan {
  let vertex_byte_len = mesh.vertex_count() * vertex_stride
  let vertex_allocation = if vertex_byte_len > 0 {
    self.allocate(
      mesh_id,
      vertex_byte_len,
      MeshAllocatorElementLayout::vertex(vertex_stride),
      settings~,
    )
  } else {
    None
  }
  let vertex_upload = match vertex_allocation {
    Some(_) => self.pending_upload_plan(mesh_id, Vertex, vertex_byte_len)
    None => None
  }
  let index_byte_len = mesh_allocator_render_mesh_index_byte_len(
    mesh, index_layout,
  )
  let index_allocation = match index_byte_len {
    Some(byte_len) => self.allocate(mesh_id, byte_len, index_layout, settings~)
    None => None
  }
  let index_upload = match index_byte_len {
    Some(byte_len) => self.pending_upload_plan(mesh_id, Index, byte_len)
    None => None
  }
  MeshAllocatorRenderMeshPlan::{
    vertex_allocation,
    index_allocation,
    vertex_upload,
    index_upload,
    vertex_reallocate: self.reallocate_plan_for_allocation(vertex_allocation),
    index_reallocate: self.reallocate_plan_for_allocation(index_allocation),
  }
}

///|
pub fn MeshAllocator::mesh_slabs(
  self : MeshAllocator,
  mesh_id : Int,
) -> MeshSlabs? {
  guard mesh_allocator_lookup_map(self.mesh_id_to_vertex_slab, mesh_id)
    is Some(vertex_slab_id) else {
    return None
  }
  Some(
    MeshSlabs::new(
      vertex_slab_id,
      index_slab_id=mesh_allocator_lookup_map(
        self.mesh_id_to_index_slab,
        mesh_id,
      ),
    ),
  )
}

///|
pub fn MeshAllocator::mesh_vertex_slice(
  self : MeshAllocator,
  mesh_id : Int,
) -> MeshAllocatorSlice? {
  match mesh_allocator_lookup_map(self.mesh_id_to_vertex_slab, mesh_id) {
    Some(slab_id) => self.mesh_slice_in_slab(mesh_id, slab_id)
    None => None
  }
}

///|
pub fn MeshAllocator::mesh_index_slice(
  self : MeshAllocator,
  mesh_id : Int,
) -> MeshAllocatorSlice? {
  match mesh_allocator_lookup_map(self.mesh_id_to_index_slab, mesh_id) {
    Some(slab_id) => self.mesh_slice_in_slab(mesh_id, slab_id)
    None => None
  }
}

///|
pub fn MeshAllocator::mesh_slice_in_slab(
  self : MeshAllocator,
  mesh_id : Int,
  slab_id : Int,
) -> MeshAllocatorSlice? {
  match mesh_allocator_find_slab_index(self.slabs, slab_id) {
    Some(index) => self.slabs[index].slice_for_mesh(mesh_id)
    None => None
  }
}

///|
pub fn MeshAllocator::slab_count(self : MeshAllocator) -> Int {
  self.slabs.length()
}

///|
pub fn MeshAllocator::slabs_size(self : MeshAllocator) -> Int {
  let mut size = 0
  for slab in self.slabs {
    size = size + slab.buffer_size()
  }
  size
}

///|
pub fn MeshAllocator::allocations(self : MeshAllocator) -> Int {
  self.mesh_id_to_index_slab.length()
}

///|
pub fn MeshAllocator::mark_resident(
  self : MeshAllocator,
  mesh_id : Int,
  element_class : MeshAllocatorElementClass,
) -> Bool {
  let slab_id = match element_class {
    Vertex => mesh_allocator_lookup_map(self.mesh_id_to_vertex_slab, mesh_id)
    Index => mesh_allocator_lookup_map(self.mesh_id_to_index_slab, mesh_id)
  }
  match slab_id {
    Some(slab_id) =>
      match mesh_allocator_find_slab_index(self.slabs, slab_id) {
        Some(index) => self.slabs[index].mark_resident(mesh_id)
        None => false
      }
    None => false
  }
}

///|
pub fn MeshAllocator::mark_vertex_resident(
  self : MeshAllocator,
  mesh_id : Int,
) -> Bool {
  self.mark_resident(mesh_id, Vertex)
}

///|
pub fn MeshAllocator::mark_index_resident(
  self : MeshAllocator,
  mesh_id : Int,
) -> Bool {
  self.mark_resident(mesh_id, Index)
}

///|
pub fn MeshAllocator::pending_upload_plan(
  self : MeshAllocator,
  mesh_id : Int,
  element_class : MeshAllocatorElementClass,
  data_byte_len : Int,
) -> MeshAllocatorUploadPlan? {
  let slab_id = match element_class {
    Vertex => mesh_allocator_lookup_map(self.mesh_id_to_vertex_slab, mesh_id)
    Index => mesh_allocator_lookup_map(self.mesh_id_to_index_slab, mesh_id)
  }
  match slab_id {
    Some(slab_id) =>
      match mesh_allocator_find_slab_index(self.slabs, slab_id) {
        Some(index) =>
          self.slabs[index].upload_plan_for_mesh(mesh_id, data_byte_len)
        None => None
      }
    None => None
  }
}

///|
pub fn MeshAllocator::reallocate_slab_plan(
  self : MeshAllocator,
  slab_id : Int,
  old_slot_capacity : Int,
) -> MeshAllocatorReallocateSlabPlan? {
  match mesh_allocator_find_slab_index(self.slabs, slab_id) {
    Some(index) => {
      let slab = self.slabs[index]
      if slab.kind != General {
        return None
      }
      let buffer = slab.buffer_plan(false)
      Some(MeshAllocatorReallocateSlabPlan::{
        slab_id,
        label: buffer.label,
        usage: buffer.usage,
        new_size: buffer.size,
        old_copy_size: old_slot_capacity * slab.layout.slot_size(),
      })
    }
    None => None
  }
}

///|
pub fn MeshAllocator::free_mesh(self : MeshAllocator, mesh_id : Int) -> Unit {
  let vertex_slab_id = mesh_allocator_remove_map(
    self.mesh_id_to_vertex_slab,
    mesh_id,
  )
  let index_slab_id = mesh_allocator_remove_map(
    self.mesh_id_to_index_slab,
    mesh_id,
  )
  match vertex_slab_id {
    Some(slab_id) => self.free_allocation_in_slab(mesh_id, slab_id)
    None => ()
  }
  match index_slab_id {
    Some(slab_id) => self.free_allocation_in_slab(mesh_id, slab_id)
    None => ()
  }
  self.remove_empty_slabs()
}

///|
pub fn MeshAllocator::free_meshes(
  self : MeshAllocator,
  removed : Array[Int],
  modified : Array[Int],
) -> Unit {
  for mesh_id in removed {
    self.free_mesh(mesh_id)
  }
  for mesh_id in modified {
    self.free_mesh(mesh_id)
  }
}

///|
fn MeshAllocator::free_allocation_in_slab(
  self : MeshAllocator,
  mesh_id : Int,
  slab_id : Int,
) -> Unit {
  match mesh_allocator_find_slab_index(self.slabs, slab_id) {
    Some(index) => ignore(self.slabs[index].remove_allocation(mesh_id))
    None => ()
  }
}

///|
fn MeshAllocator::remove_empty_slabs(self : MeshAllocator) -> Unit {
  let mut index = 0
  while index < self.slabs.length() {
    if self.slabs[index].is_empty() {
      ignore(self.slabs.remove(index))
    } else {
      index = index + 1
    }
  }
}
