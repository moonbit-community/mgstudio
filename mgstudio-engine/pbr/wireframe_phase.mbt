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
pub fn SpecializedWireframeViewPipelineCache::clear(
  self : SpecializedWireframeViewPipelineCache,
) -> Unit {
  self.map.clear()
}

///|
pub fn SpecializedWireframeViewPipelineCache::get(
  self : SpecializedWireframeViewPipelineCache,
  entity : @render.MainEntity,
) -> @material.CachedRenderPipelineId? {
  self.map.get(entity.id().to_bits())
}

///|
pub fn SpecializedWireframeViewPipelineCache::insert(
  self : SpecializedWireframeViewPipelineCache,
  entity : @render.MainEntity,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  self.map.set(entity.id().to_bits(), pipeline_id)
}

///|
pub fn SpecializedWireframeViewPipelineCache::remove(
  self : SpecializedWireframeViewPipelineCache,
  entity : @render.MainEntity,
) -> Bool {
  let key = entity.id().to_bits()
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
  entity : @render.MainEntity,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  self.view_or_insert(view).insert(entity, pipeline_id)
}

///|
pub fn SpecializedWireframePipelineCache::pipeline_id(
  self : SpecializedWireframePipelineCache,
  view : @core.Entity,
  entity : @render.MainEntity,
) -> @material.CachedRenderPipelineId? {
  match self.views.get(view.to_bits()) {
    Some(cache) => cache.get(entity)
    None => None
  }
}

///|
pub fn SpecializedWireframePipelineCache::clear_view(
  self : SpecializedWireframePipelineCache,
  view : @core.Entity,
) -> Unit {
  match self.views.get(view.to_bits()) {
    Some(cache) => cache.clear()
    None => ()
  }
}

///|
pub fn SpecializedWireframePipelineCache::remove_from_view(
  self : SpecializedWireframePipelineCache,
  view : @core.Entity,
  entity : @render.MainEntity,
) -> Bool {
  match self.views.get(view.to_bits()) {
    Some(cache) => cache.remove(entity)
    None => false
  }
}

///|
pub fn SpecializedWireframePipelineCache::remove_entity_from_all_views(
  self : SpecializedWireframePipelineCache,
  entity : @render.MainEntity,
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
pub fn SpecializedWireframePipelineCache::contains_view(
  self : SpecializedWireframePipelineCache,
  view : @core.Entity,
) -> Bool {
  self.views.contains(view.to_bits())
}

///|
pub fn SpecializedWireframePipelineCache::expire_stale_views(
  self : SpecializedWireframePipelineCache,
  live_views : Map[UInt64, Bool],
) -> Unit {
  let stale : Array[UInt64] = []
  for view_bits, _cache in self.views {
    if !live_views.contains(view_bits) {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    self.views.remove(view_bits)
  }
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
  entity : @render.MainEntity,
) -> Int? {
  self.entries.get(entity.id().to_bits())
}

///|
pub fn RenderWireframeInstances::insert(
  self : RenderWireframeInstances,
  entity : @render.MainEntity,
  material_asset_id : Int,
) -> Unit {
  self.entries.set(entity.id().to_bits(), material_asset_id)
}

///|
pub fn RenderWireframeInstances::remove(
  self : RenderWireframeInstances,
  entity : @render.MainEntity,
) -> Bool {
  let key = entity.id().to_bits()
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
pub struct ViewPendingWireframeQueues {
  mut current_frame : @hashset.HashSet[(@core.Entity, @core.Entity)]
  mut prev_frame : @hashset.HashSet[(@core.Entity, @core.Entity)]
}

///|
pub fn ViewPendingWireframeQueues::ViewPendingWireframeQueues() -> ViewPendingWireframeQueues {
  ViewPendingWireframeQueues::{
    current_frame: @hashset.HashSet([]),
    prev_frame: @hashset.HashSet([]),
  }
}

///|
pub fn ViewPendingWireframeQueues::prepare_for_new_frame(
  self : ViewPendingWireframeQueues,
) -> Unit {
  let prev_frame = self.prev_frame
  self.prev_frame = self.current_frame
  self.current_frame = prev_frame
  self.current_frame.clear()
}

///|
pub fn ViewPendingWireframeQueues::push_current(
  self : ViewPendingWireframeQueues,
  render_entity : @core.Entity,
  main_entity : @core.Entity,
) -> Unit {
  self.current_frame.add((render_entity, main_entity))
}

///|
pub fn ViewPendingWireframeQueues::current_len(
  self : ViewPendingWireframeQueues,
) -> Int {
  self.current_frame.length()
}

///|
pub fn ViewPendingWireframeQueues::prev_len(
  self : ViewPendingWireframeQueues,
) -> Int {
  self.prev_frame.length()
}

///|
pub struct PendingWireframeQueues {
  views : Map[UInt64, ViewPendingWireframeQueues]
}

///|
pub fn PendingWireframeQueues::PendingWireframeQueues() -> PendingWireframeQueues {
  PendingWireframeQueues::{ views: {} }
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
pub fn PendingWireframeQueues::view_or_insert(
  self : PendingWireframeQueues,
  retained_view_entity : @core.Entity,
) -> ViewPendingWireframeQueues {
  let key = retained_view_entity.to_bits()
  match self.views.get(key) {
    Some(queues) => queues
    None => {
      let queues = ViewPendingWireframeQueues::ViewPendingWireframeQueues()
      self.views.set(key, queues)
      queues
    }
  }
}

///|
pub fn PendingWireframeQueues::prepare_for_new_frame(
  self : PendingWireframeQueues,
  retained_view_entity : @core.Entity,
) -> ViewPendingWireframeQueues {
  let queues = self.view_or_insert(retained_view_entity)
  queues.prepare_for_new_frame()
  queues
}

///|
pub fn PendingWireframeQueues::push_current(
  self : PendingWireframeQueues,
  retained_view_entity : @core.Entity,
  render_entity : @core.Entity,
  main_entity : @core.Entity,
) -> Unit {
  self
  .view_or_insert(retained_view_entity)
  .push_current(render_entity, main_entity)
}

///|
pub fn PendingWireframeQueues::current_len(
  self : PendingWireframeQueues,
  retained_view_entity : @core.Entity,
) -> Int {
  match self.views.get(retained_view_entity.to_bits()) {
    Some(queues) => queues.current_len()
    None => 0
  }
}

///|
pub fn PendingWireframeQueues::prev_len(
  self : PendingWireframeQueues,
  retained_view_entity : @core.Entity,
) -> Int {
  match self.views.get(retained_view_entity.to_bits()) {
    Some(queues) => queues.prev_len()
    None => 0
  }
}

///|
pub fn PendingWireframeQueues::contains_view(
  self : PendingWireframeQueues,
  retained_view_entity : @core.Entity,
) -> Bool {
  self.views.contains(retained_view_entity.to_bits())
}

///|
pub fn PendingWireframeQueues::view_len(self : PendingWireframeQueues) -> Int {
  self.views.length()
}

///|
pub fn PendingWireframeQueues::expire_stale_views(
  self : PendingWireframeQueues,
  live_views : Map[UInt64, Bool],
) -> Unit {
  let stale : Array[UInt64] = []
  for view_bits, _queues in self.views {
    if !live_views.contains(view_bits) {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    self.views.remove(view_bits)
  }
}

///|
pub struct DirtyWireframeSpecializations {
  changed_renderables : Map[UInt64, @render.MainEntity]
  removed_renderables : Map[UInt64, @render.MainEntity]
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
  entity : @render.MainEntity,
) -> Unit {
  self.changed_renderables.set(entity.id().to_bits(), entity)
}

///|
pub fn DirtyWireframeSpecializations::insert_removed(
  self : DirtyWireframeSpecializations,
  entity : @render.MainEntity,
) -> Unit {
  self.removed_renderables.set(entity.id().to_bits(), entity)
}

///|
pub fn DirtyWireframeSpecializations::insert_view(
  self : DirtyWireframeSpecializations,
  view : @core.Entity,
) -> Unit {
  self.views.set(view.to_bits(), view)
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
pub fn DirtyWireframeSpecializations::views_len(
  self : DirtyWireframeSpecializations,
) -> Int {
  self.views.length()
}

///|
pub fn DirtyWireframeSpecializations::changed_contains(
  self : DirtyWireframeSpecializations,
  entity : @render.MainEntity,
) -> Bool {
  self.changed_renderables.contains(entity.id().to_bits())
}

///|
pub fn DirtyWireframeSpecializations::removed_contains(
  self : DirtyWireframeSpecializations,
  entity : @render.MainEntity,
) -> Bool {
  self.removed_renderables.contains(entity.id().to_bits())
}

///|
pub fn DirtyWireframeSpecializations::must_wipe_specializations_for_view(
  self : DirtyWireframeSpecializations,
  view : @core.Entity,
) -> Bool {
  self.views.contains(view.to_bits())
}

///|
pub fn DirtyWireframeSpecializations::to_despecialize(
  self : DirtyWireframeSpecializations,
) -> Array[@render.MainEntity] {
  let entities : Array[@render.MainEntity] = []
  for entity in self.changed_renderables.values() {
    entities.push(entity)
  }
  for entity in self.removed_renderables.values() {
    entities.push(entity)
  }
  entities
}

///|
pub fn despecialize_wireframe_view_cache(
  specialized_material_pipeline_cache : SpecializedWireframePipelineCache,
  dirty_wireframe_specializations : DirtyWireframeSpecializations,
  retained_view_entity : @core.Entity,
) -> Unit {
  if dirty_wireframe_specializations.must_wipe_specializations_for_view(
      retained_view_entity,
    ) {
    specialized_material_pipeline_cache.clear_view(retained_view_entity)
  } else {
    for renderable_entity in dirty_wireframe_specializations.to_despecialize() {
      specialized_material_pipeline_cache.remove_from_view(
        retained_view_entity, renderable_entity,
      )
      |> ignore
    }
  }
}

///|
pub struct Wireframe3dViewPhase {
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode
  items : Array[Wireframe3d]
}

///|
pub fn Wireframe3dViewPhase::new(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> Wireframe3dViewPhase {
  Wireframe3dViewPhase::{ gpu_preprocessing_mode, items: [] }
}

///|
pub fn Wireframe3dViewPhase::gpu_preprocessing_mode(
  self : Wireframe3dViewPhase,
) -> @render_batching.GpuPreprocessingMode {
  self.gpu_preprocessing_mode
}

///|
pub fn Wireframe3dViewPhase::len(self : Wireframe3dViewPhase) -> Int {
  self.items.length()
}

///|
pub struct Wireframe3dPhases {
  views : Map[UInt64, Wireframe3dViewPhase]
}

///|
pub fn Wireframe3dPhases::Wireframe3dPhases() -> Wireframe3dPhases {
  Wireframe3dPhases::{ views: {} }
}

///|
pub let ecs_key_wireframe_3d_phases : @ecs.ResourceKey[Wireframe3dPhases] = @ecs.register_resource(
  debug_name="mgstudio_pbr::Wireframe3dPhases",
)

///|
pub impl @app.Resource for Wireframe3dPhases with fn resource() {
  ecs_key_wireframe_3d_phases
}

///|
pub fn Wireframe3dPhases::prepare_for_new_frame(
  self : Wireframe3dPhases,
  retained_view_entity : @core.Entity,
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> Unit {
  self.views.set(
    retained_view_entity.to_bits(),
    Wireframe3dViewPhase::new(gpu_preprocessing_mode),
  )
}

///|
pub fn Wireframe3dPhases::retain_live_views(
  self : Wireframe3dPhases,
  live_views : Map[UInt64, Bool],
) -> Unit {
  let stale : Array[UInt64] = []
  for view_bits, _phase in self.views {
    if !live_views.contains(view_bits) {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    self.views.remove(view_bits)
  }
}

///|
pub fn Wireframe3dPhases::len(self : Wireframe3dPhases) -> Int {
  self.views.length()
}

///|
pub fn Wireframe3dPhases::contains(
  self : Wireframe3dPhases,
  retained_view_entity : @core.Entity,
) -> Bool {
  self.views.contains(retained_view_entity.to_bits())
}

///|
pub fn Wireframe3dPhases::phase(
  self : Wireframe3dPhases,
  retained_view_entity : @core.Entity,
) -> Wireframe3dViewPhase? {
  self.views.get(retained_view_entity.to_bits())
}
