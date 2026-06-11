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
pub struct WireframeMeshSlabs {
  vertex_slab_id : Int
  index_slab_id : Int?
  morph_target_slab_id : Int?
} derive(Eq, Debug)

///|
pub fn WireframeMeshSlabs::new(
  vertex_slab_id : Int,
  index_slab_id? : Int? = None,
  morph_target_slab_id? : Int? = None,
) -> WireframeMeshSlabs {
  WireframeMeshSlabs::{ vertex_slab_id, index_slab_id, morph_target_slab_id }
}

///|
pub fn WireframeMeshSlabs::vertex_slab_id(self : WireframeMeshSlabs) -> Int {
  self.vertex_slab_id
}

///|
pub fn WireframeMeshSlabs::index_slab_id(self : WireframeMeshSlabs) -> Int? {
  self.index_slab_id
}

///|
pub fn WireframeMeshSlabs::morph_target_slab_id(
  self : WireframeMeshSlabs,
) -> Int? {
  self.morph_target_slab_id
}

///|
pub struct Wireframe3dBatchSetKey {
  pipeline : @material.CachedRenderPipelineId
  asset_id : Int
  draw_function : @material.DrawFunctionId
  slabs : WireframeMeshSlabs
  mesh_asset_id : Int?
}

///|
pub fn Wireframe3dBatchSetKey::new(
  pipeline : @material.CachedRenderPipelineId,
  asset_id : Int,
  draw_function : @material.DrawFunctionId,
  slabs : WireframeMeshSlabs,
  mesh_asset_id? : Int? = None,
) -> Wireframe3dBatchSetKey {
  Wireframe3dBatchSetKey::{
    pipeline,
    asset_id,
    draw_function,
    slabs,
    mesh_asset_id,
  }
}

///|
pub fn Wireframe3dBatchSetKey::pipeline(
  self : Wireframe3dBatchSetKey,
) -> @material.CachedRenderPipelineId {
  self.pipeline
}

///|
pub fn Wireframe3dBatchSetKey::asset_id(self : Wireframe3dBatchSetKey) -> Int {
  self.asset_id
}

///|
pub fn Wireframe3dBatchSetKey::draw_function(
  self : Wireframe3dBatchSetKey,
) -> @material.DrawFunctionId {
  self.draw_function
}

///|
pub fn Wireframe3dBatchSetKey::slabs(
  self : Wireframe3dBatchSetKey,
) -> WireframeMeshSlabs {
  self.slabs
}

///|
pub fn Wireframe3dBatchSetKey::mesh_asset_id(
  self : Wireframe3dBatchSetKey,
) -> Int? {
  self.mesh_asset_id
}

///|
pub fn Wireframe3dBatchSetKey::indexed(self : Wireframe3dBatchSetKey) -> Bool {
  self.slabs.index_slab_id is Some(_)
}

///|
pub struct Wireframe3dBinKey {
  asset_id : Int
} derive(Eq, Debug)

///|
pub fn Wireframe3dBinKey::new(asset_id : Int) -> Wireframe3dBinKey {
  Wireframe3dBinKey::{ asset_id, }
}

///|
pub fn Wireframe3dBinKey::asset_id(self : Wireframe3dBinKey) -> Int {
  self.asset_id
}

///|
pub(all) enum WireframePhaseItemExtraIndex {
  NoExtraIndex
  DynamicOffset(Int)
  IndirectParametersIndex(Int, Int, Int?)
} derive(Eq, Debug)

///|
pub fn WireframePhaseItemExtraIndex::none() -> WireframePhaseItemExtraIndex {
  NoExtraIndex
}

///|
pub fn WireframePhaseItemExtraIndex::dynamic_offset(
  offset : Int,
) -> WireframePhaseItemExtraIndex {
  DynamicOffset(offset)
}

///|
pub fn WireframePhaseItemExtraIndex::indirect_parameters_index(
  range_start : Int,
  range_end : Int,
  batch_set_index? : Int? = None,
) -> WireframePhaseItemExtraIndex {
  IndirectParametersIndex(range_start, range_end, batch_set_index)
}

///|
pub struct Wireframe3dBatchRange {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn Wireframe3dBatchRange::new(
  start : Int,
  end : Int,
) -> Wireframe3dBatchRange {
  let safe_start = if start < 0 { 0 } else { start }
  let safe_end = if end < safe_start { safe_start } else { end }
  Wireframe3dBatchRange::{ start: safe_start, end: safe_end }
}

///|
pub fn Wireframe3dBatchRange::start(self : Wireframe3dBatchRange) -> Int {
  self.start
}

///|
pub fn Wireframe3dBatchRange::end(self : Wireframe3dBatchRange) -> Int {
  self.end
}

///|
pub fn Wireframe3dBatchRange::count(self : Wireframe3dBatchRange) -> Int {
  self.end - self.start
}

///|
pub struct Wireframe3d {
  batch_set_key : Wireframe3dBatchSetKey
  bin_key : Wireframe3dBinKey
  render_entity : @core.Entity
  main_entity : @core.Entity
  batch_range : Wireframe3dBatchRange
  extra_index : WireframePhaseItemExtraIndex
}

///|
pub fn Wireframe3d::new(
  batch_set_key : Wireframe3dBatchSetKey,
  bin_key : Wireframe3dBinKey,
  render_entity : @core.Entity,
  main_entity : @core.Entity,
  batch_range : Wireframe3dBatchRange,
  extra_index : WireframePhaseItemExtraIndex,
) -> Wireframe3d {
  Wireframe3d::{
    batch_set_key,
    bin_key,
    render_entity,
    main_entity,
    batch_range,
    extra_index,
  }
}

///|
pub fn Wireframe3d::entity(self : Wireframe3d) -> @core.Entity {
  self.render_entity
}

///|
pub fn Wireframe3d::main_entity(self : Wireframe3d) -> @core.Entity {
  self.main_entity
}

///|
pub fn Wireframe3d::draw_function(
  self : Wireframe3d,
) -> @material.DrawFunctionId {
  self.batch_set_key.draw_function
}

///|
pub fn Wireframe3d::cached_pipeline(
  self : Wireframe3d,
) -> @material.CachedRenderPipelineId {
  self.batch_set_key.pipeline
}

///|
pub fn Wireframe3d::batch_range(self : Wireframe3d) -> Wireframe3dBatchRange {
  self.batch_range
}

///|
pub fn Wireframe3d::extra_index(
  self : Wireframe3d,
) -> WireframePhaseItemExtraIndex {
  self.extra_index
}

///|
pub fn Wireframe3d::batch_set_key(self : Wireframe3d) -> Wireframe3dBatchSetKey {
  self.batch_set_key
}

///|
pub fn Wireframe3d::bin_key(self : Wireframe3d) -> Wireframe3dBinKey {
  self.bin_key
}

///|
pub struct WireframePipelineKey {
  mesh_key : @material.ErasedMeshPipelineKey
  wide : Bool
  quads : Bool
  line_mode : Bool
}

///|
pub fn WireframePipelineKey::new(
  mesh_key : @material.ErasedMeshPipelineKey,
  wide : Bool,
  quads : Bool,
  line_mode : Bool,
) -> WireframePipelineKey {
  WireframePipelineKey::{ mesh_key, wide, quads, line_mode }
}

///|
pub fn WireframePipelineKey::mesh_key(
  self : WireframePipelineKey,
) -> @material.ErasedMeshPipelineKey {
  self.mesh_key
}

///|
pub fn WireframePipelineKey::wide(self : WireframePipelineKey) -> Bool {
  self.wide
}

///|
pub fn WireframePipelineKey::quads(self : WireframePipelineKey) -> Bool {
  self.quads
}

///|
pub fn WireframePipelineKey::line_mode(self : WireframePipelineKey) -> Bool {
  self.line_mode
}

///|
pub fn WireframePipelineKey::from_material(
  mesh_key : @material.ErasedMeshPipelineKey,
  material : RenderWireframeMaterial?,
) -> WireframePipelineKey {
  let quads = match material {
    Some(value) => value.topology == Quads
    None => false
  }
  let thick = match material {
    Some(value) => value.line_width > 1.0F
    None => false
  }
  let wide = thick || quads
  WireframePipelineKey::{ mesh_key, wide, quads, line_mode: wide && !thick }
}

///|
pub struct WireframeWidePipelineCacheKey {
  mesh_key : @material.ErasedMeshPipelineKey
  mesh_layout_key : String
  quads : Bool
  line_mode : Bool
}

///|
pub fn WireframeWidePipelineCacheKey::new(
  mesh_key : @material.ErasedMeshPipelineKey,
  mesh_layout_key : String,
  quads : Bool,
  line_mode : Bool,
) -> WireframeWidePipelineCacheKey {
  WireframeWidePipelineCacheKey::{ mesh_key, mesh_layout_key, quads, line_mode }
}

///|
fn wireframe_wide_pipeline_cache_key_id(
  key : WireframeWidePipelineCacheKey,
) -> String {
  "\{key.mesh_key.type_tag()}:\{key.mesh_key.bits()}:\{key.mesh_layout_key}:\{key.quads}:\{key.line_mode}"
}

///|
pub struct SpecializedWireframeViewPipelineCache {
  map : Map[UInt64, @material.CachedRenderPipelineId]
}

///|
pub fn SpecializedWireframeViewPipelineCache::SpecializedWireframeViewPipelineCache() -> SpecializedWireframeViewPipelineCache {
  SpecializedWireframeViewPipelineCache::{ map: {} }
}

///|
pub fn SpecializedWireframeViewPipelineCache::len(
  self : SpecializedWireframeViewPipelineCache,
) -> Int {
  self.map.length()
}

///|
pub fn SpecializedWireframeViewPipelineCache::get(
  self : SpecializedWireframeViewPipelineCache,
  entity : @core.Entity,
) -> @material.CachedRenderPipelineId? {
  self.map.get(entity.to_bits())
}

///|
pub fn SpecializedWireframeViewPipelineCache::insert(
  self : SpecializedWireframeViewPipelineCache,
  entity : @core.Entity,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  self.map.set(entity.to_bits(), pipeline_id)
}

///|
pub fn SpecializedWireframeViewPipelineCache::remove(
  self : SpecializedWireframeViewPipelineCache,
  entity : @core.Entity,
) -> Bool {
  let key = entity.to_bits()
  if self.map.contains(key) {
    self.map.remove(key)
    true
  } else {
    false
  }
}

///|
pub struct SpecializedWireframePipelineCache {
  views : Map[UInt64, SpecializedWireframeViewPipelineCache]
  wide : Map[String, @material.CachedRenderPipelineId]
}

///|
pub fn SpecializedWireframePipelineCache::SpecializedWireframePipelineCache() -> SpecializedWireframePipelineCache {
  SpecializedWireframePipelineCache::{ views: {}, wide: {} }
}

///|
pub let ecs_key_specialized_wireframe_pipeline_cache : @ecs.ResourceKey[
  SpecializedWireframePipelineCache,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedWireframePipelineCache",
)

///|
pub impl @app.Resource for SpecializedWireframePipelineCache with fn resource() {
  ecs_key_specialized_wireframe_pipeline_cache
}

///|
pub fn SpecializedWireframePipelineCache::len(
  self : SpecializedWireframePipelineCache,
) -> Int {
  self.views.length()
}

///|
pub fn SpecializedWireframePipelineCache::wide_len(
  self : SpecializedWireframePipelineCache,
) -> Int {
  self.wide.length()
}

///|
pub fn SpecializedWireframePipelineCache::view_or_insert(
  self : SpecializedWireframePipelineCache,
  view : @core.Entity,
) -> SpecializedWireframeViewPipelineCache {
  let key = view.to_bits()
  match self.views.get(key) {
    Some(cache) => cache
    None => {
      let cache = SpecializedWireframeViewPipelineCache::SpecializedWireframeViewPipelineCache()
      self.views.set(key, cache)
      cache
    }
  }
}

///|
pub fn SpecializedWireframePipelineCache::insert(
  self : SpecializedWireframePipelineCache,
  view : @core.Entity,
  entity : @core.Entity,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  self.view_or_insert(view).insert(entity, pipeline_id)
}

///|
pub fn SpecializedWireframePipelineCache::pipeline_id(
  self : SpecializedWireframePipelineCache,
  view : @core.Entity,
  entity : @core.Entity,
) -> @material.CachedRenderPipelineId? {
  match self.views.get(view.to_bits()) {
    Some(cache) => cache.get(entity)
    None => None
  }
}

///|
pub fn SpecializedWireframePipelineCache::remove_entity_from_all_views(
  self : SpecializedWireframePipelineCache,
  entity : @core.Entity,
) -> Int {
  let mut removed = 0
  for _, cache in self.views {
    if cache.remove(entity) {
      removed = removed + 1
    }
  }
  removed
}

///|
pub fn SpecializedWireframePipelineCache::wide_pipeline_id(
  self : SpecializedWireframePipelineCache,
  key : WireframeWidePipelineCacheKey,
) -> @material.CachedRenderPipelineId? {
  self.wide.get(wireframe_wide_pipeline_cache_key_id(key))
}

///|
pub fn SpecializedWireframePipelineCache::insert_wide_pipeline(
  self : SpecializedWireframePipelineCache,
  key : WireframeWidePipelineCacheKey,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  self.wide.set(wireframe_wide_pipeline_cache_key_id(key), pipeline_id)
}

///|
pub struct RenderWireframeInstances {
  entries : Map[UInt64, Int]
}

///|
pub fn RenderWireframeInstances::RenderWireframeInstances() -> RenderWireframeInstances {
  RenderWireframeInstances::{ entries: {} }
}

///|
pub let ecs_key_render_wireframe_instances : @ecs.ResourceKey[
  RenderWireframeInstances,
] = @ecs.register_resource(debug_name="mgstudio_pbr::RenderWireframeInstances")

///|
pub impl @app.Resource for RenderWireframeInstances with fn resource() {
  ecs_key_render_wireframe_instances
}

///|
pub fn RenderWireframeInstances::len(self : RenderWireframeInstances) -> Int {
  self.entries.length()
}

///|
pub fn RenderWireframeInstances::clear(self : RenderWireframeInstances) -> Unit {
  self.entries.clear()
}

///|
pub fn RenderWireframeInstances::get(
  self : RenderWireframeInstances,
  entity : @core.Entity,
) -> Int? {
  self.entries.get(entity.to_bits())
}

///|
pub fn RenderWireframeInstances::insert(
  self : RenderWireframeInstances,
  entity : @core.Entity,
  material_asset_id : Int,
) -> Unit {
  self.entries.set(entity.to_bits(), material_asset_id)
}

///|
pub fn RenderWireframeInstances::remove(
  self : RenderWireframeInstances,
  entity : @core.Entity,
) -> Bool {
  let key = entity.to_bits()
  if self.entries.contains(key) {
    self.entries.remove(key)
    true
  } else {
    false
  }
}

///|
pub struct WireframeWideBindGroups {
  params : Array[WireframeVertexPullParams]
  mesh_asset_dynamic_offsets : Map[Int, Int]
}

///|
pub fn WireframeWideBindGroups::WireframeWideBindGroups() -> WireframeWideBindGroups {
  WireframeWideBindGroups::{ params: [], mesh_asset_dynamic_offsets: {} }
}

///|
pub let ecs_key_wireframe_wide_bind_groups : @ecs.ResourceKey[
  WireframeWideBindGroups,
] = @ecs.register_resource(debug_name="mgstudio_pbr::WireframeWideBindGroups")

///|
pub impl @app.Resource for WireframeWideBindGroups with fn resource() {
  ecs_key_wireframe_wide_bind_groups
}

///|
pub fn WireframeWideBindGroups::clear(self : WireframeWideBindGroups) -> Unit {
  self.params.clear()
  self.mesh_asset_dynamic_offsets.clear()
}

///|
pub fn WireframeWideBindGroups::len(self : WireframeWideBindGroups) -> Int {
  self.mesh_asset_dynamic_offsets.length()
}

///|
pub fn WireframeWideBindGroups::push(
  self : WireframeWideBindGroups,
  mesh_asset_id : Int,
  params : WireframeVertexPullParams,
) -> Int {
  let dynamic_offset = self.params.length()
  self.params.push(params)
  self.mesh_asset_dynamic_offsets.set(mesh_asset_id, dynamic_offset)
  dynamic_offset
}

///|
pub fn WireframeWideBindGroups::dynamic_offset(
  self : WireframeWideBindGroups,
  mesh_asset_id : Int,
) -> Int? {
  self.mesh_asset_dynamic_offsets.get(mesh_asset_id)
}

///|
pub fn WireframeWideBindGroups::params(
  self : WireframeWideBindGroups,
  dynamic_offset : Int,
) -> WireframeVertexPullParams? {
  self.params.get(dynamic_offset)
}

///|
pub struct Wireframe3dDrawFunctions {
  draw_functions : @material.DrawFunctions
  thin : @material.DrawFunctionId
  wide : @material.DrawFunctionId
}

///|
pub fn Wireframe3dDrawFunctions::Wireframe3dDrawFunctions() -> Wireframe3dDrawFunctions {
  let draw_functions = @material.DrawFunctions::new()
  let thin = draw_functions.register("DrawWireframe3dThin")
  let wide = draw_functions.register("DrawWireframe3dWide")
  Wireframe3dDrawFunctions::{ draw_functions, thin, wide }
}

///|
pub let ecs_key_wireframe_3d_draw_functions : @ecs.ResourceKey[
  Wireframe3dDrawFunctions,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::DrawFunctions<Wireframe3d>",
)

///|
pub impl @app.Resource for Wireframe3dDrawFunctions with fn resource() {
  ecs_key_wireframe_3d_draw_functions
}

///|
pub fn Wireframe3dDrawFunctions::thin(
  self : Wireframe3dDrawFunctions,
) -> @material.DrawFunctionId {
  self.thin
}

///|
pub fn Wireframe3dDrawFunctions::wide(
  self : Wireframe3dDrawFunctions,
) -> @material.DrawFunctionId {
  self.wide
}

///|
pub fn Wireframe3dDrawFunctions::len(self : Wireframe3dDrawFunctions) -> Int {
  self.draw_functions.len()
}

///|
pub struct PendingWireframeQueues {
  current_frame : Array[(@core.Entity, @core.Entity)]
  previous_frame : Array[(@core.Entity, @core.Entity)]
}

///|
pub fn PendingWireframeQueues::PendingWireframeQueues() -> PendingWireframeQueues {
  PendingWireframeQueues::{ current_frame: [], previous_frame: [] }
}

///|
pub let ecs_key_pending_wireframe_queues : @ecs.ResourceKey[
  PendingWireframeQueues,
] = @ecs.register_resource(debug_name="mgstudio_pbr::PendingWireframeQueues")

///|
pub impl @app.Resource for PendingWireframeQueues with fn resource() {
  ecs_key_pending_wireframe_queues
}

///|
pub fn PendingWireframeQueues::prepare_for_new_frame(
  self : PendingWireframeQueues,
) -> Unit {
  self.previous_frame.clear()
  for item in self.current_frame {
    self.previous_frame.push(item)
  }
  self.current_frame.clear()
}

///|
pub fn PendingWireframeQueues::push_current(
  self : PendingWireframeQueues,
  render_entity : @core.Entity,
  main_entity : @core.Entity,
) -> Unit {
  self.current_frame.push((render_entity, main_entity))
}

///|
pub fn PendingWireframeQueues::current_len(
  self : PendingWireframeQueues,
) -> Int {
  self.current_frame.length()
}

///|
pub fn PendingWireframeQueues::previous_len(
  self : PendingWireframeQueues,
) -> Int {
  self.previous_frame.length()
}

///|
pub struct DirtyWireframeSpecializations {
  changed_renderables : Map[UInt64, @core.Entity]
  removed_renderables : Map[UInt64, @core.Entity]
  views : Map[UInt64, @core.Entity]
}

///|
pub fn DirtyWireframeSpecializations::DirtyWireframeSpecializations() -> DirtyWireframeSpecializations {
  DirtyWireframeSpecializations::{
    changed_renderables: {},
    removed_renderables: {},
    views: {},
  }
}

///|
pub let ecs_key_dirty_wireframe_specializations : @ecs.ResourceKey[
  DirtyWireframeSpecializations,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::DirtyWireframeSpecializations",
)

///|
pub impl @app.Resource for DirtyWireframeSpecializations with fn resource() {
  ecs_key_dirty_wireframe_specializations
}

///|
pub fn DirtyWireframeSpecializations::clear(
  self : DirtyWireframeSpecializations,
) -> Unit {
  self.changed_renderables.clear()
  self.removed_renderables.clear()
  self.views.clear()
}

///|
pub fn DirtyWireframeSpecializations::insert_changed(
  self : DirtyWireframeSpecializations,
  entity : @core.Entity,
) -> Unit {
  self.changed_renderables.set(entity.to_bits(), entity)
}

///|
pub fn DirtyWireframeSpecializations::insert_removed(
  self : DirtyWireframeSpecializations,
  entity : @core.Entity,
) -> Unit {
  self.removed_renderables.set(entity.to_bits(), entity)
}

///|
pub fn DirtyWireframeSpecializations::changed_len(
  self : DirtyWireframeSpecializations,
) -> Int {
  self.changed_renderables.length()
}

///|
pub fn DirtyWireframeSpecializations::removed_len(
  self : DirtyWireframeSpecializations,
) -> Int {
  self.removed_renderables.length()
}

///|
pub fn DirtyWireframeSpecializations::changed_contains(
  self : DirtyWireframeSpecializations,
  entity : @core.Entity,
) -> Bool {
  self.changed_renderables.contains(entity.to_bits())
}

///|
pub fn DirtyWireframeSpecializations::removed_contains(
  self : DirtyWireframeSpecializations,
  entity : @core.Entity,
) -> Bool {
  self.removed_renderables.contains(entity.to_bits())
}
