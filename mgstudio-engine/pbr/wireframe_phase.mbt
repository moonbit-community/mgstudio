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
pub struct Wireframe3dBatchSetKey {
  pipeline : @material.CachedRenderPipelineId
  asset_id : Int
  draw_function : @material.DrawFunctionId
  slabs : @render_mesh.MeshSlabs
  mesh_asset_id : Int?
}

///|
pub fn Wireframe3dBatchSetKey::new(
  pipeline : @material.CachedRenderPipelineId,
  asset_id : Int,
  draw_function : @material.DrawFunctionId,
  slabs : @render_mesh.MeshSlabs,
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
) -> @render_mesh.MeshSlabs {
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
pub fn WireframePhaseItemExtraIndex::indirect_parameters_range(
  self : WireframePhaseItemExtraIndex,
) -> (Int, Int, Int?)? {
  match self {
    IndirectParametersIndex(range_start, range_end, batch_set_index) =>
      Some((range_start, range_end, batch_set_index))
    _ => None
  }
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
  main_entity : @render.MainEntity
  batch_range : Wireframe3dBatchRange
  extra_index : WireframePhaseItemExtraIndex
}

///|
pub fn Wireframe3d::new(
  batch_set_key : Wireframe3dBatchSetKey,
  bin_key : Wireframe3dBinKey,
  render_entity : @core.Entity,
  main_entity : @render.MainEntity,
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
pub fn Wireframe3d::main_entity(self : Wireframe3d) -> @render.MainEntity {
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
pub(all) enum WireframeBinnedRenderPhaseType {
  MultidrawableMesh
  BatchableMesh
  UnbatchableMesh
  NonMesh
} derive(Eq, Debug)

///|
pub fn WireframeBinnedRenderPhaseType::mesh(
  batchable : Bool,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> WireframeBinnedRenderPhaseType {
  match (batchable, gpu_preprocessing_support.is_culling_supported()) {
    (true, true) => MultidrawableMesh
    (true, false) => BatchableMesh
    (false, _) => UnbatchableMesh
  }
}

///|
pub struct WireframePipelineKey {
  mesh_key : @material.ErasedMeshPipelineKey
  wide : Bool
  quads : Bool
  line_mode : Bool
} derive(Eq, Debug)

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
  mesh_layout : @material.MaterialMeshVertexLayout
  quads : Bool
  line_mode : Bool
}

///|
pub fn WireframeWidePipelineCacheKey::new(
  mesh_key : @material.ErasedMeshPipelineKey,
  mesh_layout : @material.MaterialMeshVertexLayout,
  quads : Bool,
  line_mode : Bool,
) -> WireframeWidePipelineCacheKey {
  WireframeWidePipelineCacheKey::{ mesh_key, mesh_layout, quads, line_mode }
}

///|
fn wireframe_wide_pipeline_cache_key_equal(
  left : WireframeWidePipelineCacheKey,
  right : WireframeWidePipelineCacheKey,
) -> Bool {
  left.mesh_key == right.mesh_key &&
  left.mesh_layout.equal(right.mesh_layout) &&
  left.quads == right.quads &&
  left.line_mode == right.line_mode
}

///|
pub struct WireframePipelineCacheKey {
  key : WireframePipelineKey
  mesh_layout : @material.MaterialMeshVertexLayout
}

///|
pub fn WireframePipelineCacheKey::new(
  key : WireframePipelineKey,
  mesh_layout : @material.MaterialMeshVertexLayout,
) -> WireframePipelineCacheKey {
  WireframePipelineCacheKey::{ key, mesh_layout }
}

///|
fn wireframe_pipeline_cache_key_equal(
  left : WireframePipelineCacheKey,
  right : WireframePipelineCacheKey,
) -> Bool {
  left.key == right.key && left.mesh_layout.equal(right.mesh_layout)
}

///|
struct WireframeThinPipelineCacheEntry {
  key : WireframePipelineCacheKey
  pipeline_id : @material.CachedRenderPipelineId
}

///|
struct WireframeWidePipelineCacheEntry {
  key : WireframeWidePipelineCacheKey
  pipeline_id : @material.CachedRenderPipelineId
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
  wide : Array[WireframeWidePipelineCacheEntry]
}

///|
pub fn SpecializedWireframePipelineCache::SpecializedWireframePipelineCache() -> SpecializedWireframePipelineCache {
  SpecializedWireframePipelineCache::{ views: {}, wide: [] }
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
  for entry in self.wide {
    if wireframe_wide_pipeline_cache_key_equal(entry.key, key) {
      return Some(entry.pipeline_id)
    }
  }
  None
}

///|
pub fn SpecializedWireframePipelineCache::insert_wide_pipeline(
  self : SpecializedWireframePipelineCache,
  key : WireframeWidePipelineCacheKey,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  for index in 0..<self.wide.length() {
    if wireframe_wide_pipeline_cache_key_equal(self.wide[index].key, key) {
      self.wide[index] = WireframeWidePipelineCacheEntry::{ key, pipeline_id }
      return
    }
  }
  self.wide.push(WireframeWidePipelineCacheEntry::{ key, pipeline_id })
}

///|
pub struct SpecializedWireframeMeshPipelines {
  entries : Array[WireframeThinPipelineCacheEntry]
}

///|
pub fn SpecializedWireframeMeshPipelines::SpecializedWireframeMeshPipelines() -> SpecializedWireframeMeshPipelines {
  SpecializedWireframeMeshPipelines::{ entries: [] }
}

///|
pub let ecs_key_specialized_wireframe_mesh_pipelines : @ecs.ResourceKey[
  SpecializedWireframeMeshPipelines,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedMeshPipelines<Wireframe3dPipeline>",
)

///|
pub impl @app.Resource for SpecializedWireframeMeshPipelines with fn resource() {
  ecs_key_specialized_wireframe_mesh_pipelines
}

///|
pub fn SpecializedWireframeMeshPipelines::len(
  self : SpecializedWireframeMeshPipelines,
) -> Int {
  self.entries.length()
}

///|
pub fn SpecializedWireframeMeshPipelines::pipeline_id(
  self : SpecializedWireframeMeshPipelines,
  key : WireframePipelineCacheKey,
) -> @material.CachedRenderPipelineId? {
  for entry in self.entries {
    if wireframe_pipeline_cache_key_equal(entry.key, key) {
      return Some(entry.pipeline_id)
    }
  }
  None
}

///|
pub fn SpecializedWireframeMeshPipelines::insert(
  self : SpecializedWireframeMeshPipelines,
  key : WireframePipelineCacheKey,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  for index in 0..<self.entries.length() {
    if wireframe_pipeline_cache_key_equal(self.entries[index].key, key) {
      self.entries[index] = WireframeThinPipelineCacheEntry::{
        key,
        pipeline_id,
      }
      return
    }
  }
  self.entries.push(WireframeThinPipelineCacheEntry::{ key, pipeline_id })
}

///|
pub struct RenderWireframeInstances {
  entries : Map[UInt64, Int]
  mut last_source_change_tick : @core.Tick
}

///|
pub fn RenderWireframeInstances::RenderWireframeInstances() -> RenderWireframeInstances {
  RenderWireframeInstances::{ entries: {}, last_source_change_tick: 0 }
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
fn RenderWireframeInstances::source_system_ticks(
  self : RenderWireframeInstances,
  source_world : @ecs.World,
) -> @core.SystemTicks {
  @core.SystemTicks::new(
    self.last_source_change_tick,
    source_world.read_change_tick(),
  )
}

///|
fn RenderWireframeInstances::set_last_source_change_tick(
  self : RenderWireframeInstances,
  tick : @core.Tick,
) -> Unit {
  self.last_source_change_tick = tick
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
pub struct RenderWireframeAssets {
  assets : Map[Int, RenderWireframeMaterial]
}

///|
pub fn RenderWireframeAssets::RenderWireframeAssets() -> RenderWireframeAssets {
  RenderWireframeAssets::{ assets: {} }
}

///|
pub let ecs_key_render_wireframe_assets : @ecs.ResourceKey[
  RenderWireframeAssets,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::RenderAssets<RenderWireframeMaterial>",
)

///|
pub impl @app.Resource for RenderWireframeAssets with fn resource() {
  ecs_key_render_wireframe_assets
}

///|
pub fn RenderWireframeAssets::clear(self : RenderWireframeAssets) -> Unit {
  self.assets.clear()
}

///|
pub fn RenderWireframeAssets::insert(
  self : RenderWireframeAssets,
  asset_id : Int,
  material : RenderWireframeMaterial,
) -> Unit {
  self.assets.set(asset_id, material)
}

///|
pub fn RenderWireframeAssets::get(
  self : RenderWireframeAssets,
  asset_id : Int,
) -> RenderWireframeMaterial? {
  self.assets.get(asset_id)
}

///|
pub fn RenderWireframeAssets::as_map(
  self : RenderWireframeAssets,
) -> Map[Int, RenderWireframeMaterial] {
  self.assets
}

///|
pub fn RenderWireframeAssets::len(self : RenderWireframeAssets) -> Int {
  self.assets.length()
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
pub fn WireframeWideBindGroups::params_words(
  self : WireframeWideBindGroups,
) -> Array[UInt] {
  let words : Array[UInt] = []
  for params in self.params {
    words.push(params.index_offset())
    words.push(params.vertex_stride_u32s())
    words.push(params.position_offset_u32s())
  }
  words
}

///|
pub fn WireframeWideBindGroups::mesh_asset_ids_in_param_order(
  self : WireframeWideBindGroups,
) -> Array[Int] {
  let mesh_asset_ids = Array::make(self.params.length(), -1)
  for mesh_asset_id, dynamic_offset in self.mesh_asset_dynamic_offsets {
    if dynamic_offset >= 0 && dynamic_offset < mesh_asset_ids.length() {
      mesh_asset_ids[dynamic_offset] = mesh_asset_id
    }
  }
  mesh_asset_ids
}

///|
fn wireframe_render_mesh_vertex_layout(
  render_mesh : @render_mesh.RenderMesh,
) -> @mesh.VertexBufferLayout {
  render_mesh.layout().layout().layout()
}

///|
fn wireframe_position_offset_bytes(
  vertex_layout : @mesh.VertexBufferLayout,
) -> Int {
  let attributes = vertex_layout.attributes()
  match attributes.get(0) {
    Some(attribute) => attribute.offset()
    None => 0
  }
}

///|
pub fn prepare_wireframe_wide_bind_groups(
  render_mesh_instances : RenderMeshInstances,
  render_meshes : @render_mesh.RenderMeshAssets,
  render_wireframe_instances : RenderWireframeInstances,
  render_wireframe_assets : RenderWireframeAssets,
  mesh_allocator : @render_mesh.MeshAllocator,
  wide_bind_groups : WireframeWideBindGroups,
) -> Unit {
  wide_bind_groups.clear()
  let seen : Map[Int, Bool] = {}
  for entity_bits, wireframe_asset_id in render_wireframe_instances.entries {
    guard render_wireframe_assets.get(wireframe_asset_id) is Some(material) else {
      continue
    }
    if material.line_width <= 1.0F &&
      material.topology != WireframeTopology::Quads {
      continue
    }
    let entity = @render.MainEntity::new(@core.Entity::from_bits(entity_bits))
    guard render_mesh_instances.render_mesh_queue_data(entity)
      is Some(mesh_instance) else {
      continue
    }
    let mesh_asset_id = mesh_instance.mesh_asset_id()
    guard !seen.contains(mesh_asset_id) else { continue }
    seen.set(mesh_asset_id, true)
    guard render_meshes.get(mesh_asset_id) is Some(render_mesh) else {
      continue
    }
    guard mesh_allocator.mesh_vertex_slice(mesh_asset_id) is Some(_vertex_slice) else {
      continue
    }
    guard mesh_allocator.mesh_index_slice(mesh_asset_id) is Some(index_slice) else {
      continue
    }
    let vertex_layout = wireframe_render_mesh_vertex_layout(render_mesh)
    let vertex_stride_bytes = vertex_layout.array_stride()
    let position_offset_bytes = wireframe_position_offset_bytes(vertex_layout)
    ignore(
      wide_bind_groups.push(
        mesh_asset_id,
        WireframeVertexPullParams::new(
          index_slice.start().reinterpret_as_uint(),
          (vertex_stride_bytes / 4).reinterpret_as_uint(),
          (position_offset_bytes / 4).reinterpret_as_uint(),
        ),
      ),
    )
  }
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
  mut current_frame : @hashset.HashSet[(@core.Entity, @render.MainEntity)]
  mut prev_frame : @hashset.HashSet[(@core.Entity, @render.MainEntity)]
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
  main_entity : @render.MainEntity,
) -> Unit {
  self.current_frame.add((render_entity, main_entity))
}

///|
pub fn ViewPendingWireframeQueues::prev_frame(
  self : ViewPendingWireframeQueues,
) -> @hashset.HashSet[(@core.Entity, @render.MainEntity)] {
  self.prev_frame
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
pub fn PendingWireframeQueues::view(
  self : PendingWireframeQueues,
  retained_view_entity : @core.Entity,
) -> ViewPendingWireframeQueues? {
  self.views.get(retained_view_entity.to_bits())
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
  main_entity : @render.MainEntity,
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
pub fn DirtyWireframeSpecializations::entity_pair_from_visible_main_entity(
  _self : DirtyWireframeSpecializations,
  render_visible_mesh_entities : @render_visibility.RenderVisibleEntitiesClass,
  main_entity : @render.MainEntity,
) -> (@core.Entity, @render.MainEntity)? {
  for pair in render_visible_mesh_entities.entities_cpu_culling {
    if pair.1 == main_entity {
      return Some(pair)
    }
  }
  match render_visible_mesh_entities.entities_gpu_culling.get(main_entity) {
    Some(entity) => Some((entity, main_entity))
    None => None
  }
}

///|
fn wireframe_main_entity_in_pairs(
  pairs : Array[(@core.Entity, @render.MainEntity)],
  main_entity : @render.MainEntity,
) -> Bool {
  for pair in pairs {
    if pair.1 == main_entity {
      return true
    }
  }
  false
}

///|
pub fn DirtyWireframeSpecializations::iter_to_specialize(
  self : DirtyWireframeSpecializations,
  view : @core.Entity,
  render_visible_mesh_entities : @render_visibility.RenderVisibleEntitiesClass,
  last_frame_view_pending_queues : @hashset.HashSet[
    (@core.Entity, @render.MainEntity),
  ],
) -> Array[(@core.Entity, @render.MainEntity)] {
  let result : Array[(@core.Entity, @render.MainEntity)] = []
  if self.must_wipe_specializations_for_view(view) {
    for pair in render_visible_mesh_entities.iter_visible() {
      result.push(pair)
    }
  } else {
    for pair in render_visible_mesh_entities.added_entities() {
      result.push(pair)
    }
    for main_entity in self.changed_renderables.values() {
      match
        self.entity_pair_from_visible_main_entity(
          render_visible_mesh_entities, main_entity,
        ) {
        Some(pair) => result.push(pair)
        None => ()
      }
    }
  }
  for pair in last_frame_view_pending_queues.iter() {
    if render_visible_mesh_entities.entity_pair_is_visible(pair.0, pair.1) {
      result.push(pair)
    }
  }
  result
}

///|
pub fn DirtyWireframeSpecializations::iter_to_dequeue(
  self : DirtyWireframeSpecializations,
  view : @core.Entity,
  render_visible_mesh_entities : @render_visibility.RenderVisibleEntitiesClass,
) -> Array[@render.MainEntity] {
  let result : Array[@render.MainEntity] = []
  for pair in render_visible_mesh_entities.removed_entities() {
    result.push(pair.1)
  }
  if self.must_wipe_specializations_for_view(view) {
    for pair in render_visible_mesh_entities.iter_visible() {
      result.push(pair.1)
    }
  } else {
    for main_entity in self.changed_renderables.values() {
      result.push(main_entity)
    }
    for main_entity in self.removed_renderables.values() {
      result.push(main_entity)
    }
  }
  result
}

///|
pub fn DirtyWireframeSpecializations::iter_to_queue(
  self : DirtyWireframeSpecializations,
  view : @core.Entity,
  render_visible_mesh_entities : @render_visibility.RenderVisibleEntitiesClass,
  last_frame_view_pending_queues : @hashset.HashSet[
    (@core.Entity, @render.MainEntity),
  ],
) -> Array[(@core.Entity, @render.MainEntity)] {
  let result : Array[(@core.Entity, @render.MainEntity)] = []
  if self.must_wipe_specializations_for_view(view) {
    for pair in render_visible_mesh_entities.iter_visible() {
      result.push(pair)
    }
  } else {
    let added = render_visible_mesh_entities.added_entities()
    for pair in added {
      result.push(pair)
    }
    for main_entity in self.changed_renderables.values() {
      if !wireframe_main_entity_in_pairs(added, main_entity) {
        match
          self.entity_pair_from_visible_main_entity(
            render_visible_mesh_entities, main_entity,
          ) {
          Some(pair) => result.push(pair)
          None => ()
        }
      }
    }
  }
  for pair in last_frame_view_pending_queues.iter() {
    if render_visible_mesh_entities.entity_pair_is_visible(pair.0, pair.1) {
      result.push(pair)
    }
  }
  result
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
  mut items : Array[Wireframe3d]
  input_uniform_indices : Map[UInt64, UInt]
  phase_types : Map[UInt64, WireframeBinnedRenderPhaseType]
}

///|
pub fn Wireframe3dViewPhase::new(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
) -> Wireframe3dViewPhase {
  Wireframe3dViewPhase::{
    gpu_preprocessing_mode,
    items: [],
    input_uniform_indices: {},
    phase_types: {},
  }
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
pub fn Wireframe3dViewPhase::is_empty(self : Wireframe3dViewPhase) -> Bool {
  self.items.length() == 0
}

///|
// Bevy source:
// `bevy/crates/bevy_render/src/render_phase/mod.rs::BinnedRenderPhase::prepare_for_new_frame`.
pub fn Wireframe3dViewPhase::prepare_for_new_frame(
  _self : Wireframe3dViewPhase,
) -> Unit {
  // The local phase does not yet materialize Bevy's transient batch sets or
  // unbatchable buffer indices. Cached bins and phase items remain intact.
}

///|
pub fn Wireframe3dViewPhase::items(
  self : Wireframe3dViewPhase,
) -> Array[Wireframe3d] {
  let result : Array[Wireframe3d] = []
  for item in self.items {
    result.push(item)
  }
  result
}

///|
fn wireframe_effective_phase_type(
  gpu_preprocessing_mode : @render_batching.GpuPreprocessingMode,
  phase_type : WireframeBinnedRenderPhaseType,
) -> WireframeBinnedRenderPhaseType {
  if gpu_preprocessing_mode ==
    @render_batching.GpuPreprocessingMode::PreprocessingOnly &&
    phase_type == MultidrawableMesh {
    BatchableMesh
  } else {
    phase_type
  }
}

///|
pub fn Wireframe3dViewPhase::add(
  self : Wireframe3dViewPhase,
  batch_set_key : Wireframe3dBatchSetKey,
  bin_key : Wireframe3dBinKey,
  representative_entity : (@core.Entity, @render.MainEntity),
  input_uniform_index : UInt,
  phase_type : WireframeBinnedRenderPhaseType,
) -> Unit {
  let effective_phase_type = wireframe_effective_phase_type(
    self.gpu_preprocessing_mode,
    phase_type,
  )
  self.items.push(
    Wireframe3d::new(
      batch_set_key,
      bin_key,
      representative_entity.0,
      representative_entity.1,
      Wireframe3dBatchRange::new(
        input_uniform_index.reinterpret_as_int(),
        input_uniform_index.reinterpret_as_int() + 1,
      ),
      WireframePhaseItemExtraIndex::none(),
    ),
  )
  let key = representative_entity.1.id().to_bits()
  self.input_uniform_indices.set(key, input_uniform_index)
  self.phase_types.set(key, effective_phase_type)
}

///|
pub fn Wireframe3dViewPhase::remove(
  self : Wireframe3dViewPhase,
  main_entity : @render.MainEntity,
) -> Unit {
  let key = main_entity.id().to_bits()
  if !self.phase_types.contains(key) {
    return
  }
  let retained : Array[Wireframe3d] = []
  for item in self.items {
    if item.main_entity() != main_entity {
      retained.push(item)
    }
  }
  self.items = retained
  self.input_uniform_indices.remove(key)
  self.phase_types.remove(key)
}

///|
pub fn Wireframe3dViewPhase::input_uniform_index(
  self : Wireframe3dViewPhase,
  main_entity : @render.MainEntity,
) -> UInt? {
  self.input_uniform_indices.get(main_entity.id().to_bits())
}

///|
pub fn Wireframe3dViewPhase::phase_type(
  self : Wireframe3dViewPhase,
  main_entity : @render.MainEntity,
) -> WireframeBinnedRenderPhaseType? {
  self.phase_types.get(main_entity.id().to_bits())
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
  let key = retained_view_entity.to_bits()
  match self.views.get(key) {
    Some(phase) => phase.prepare_for_new_frame()
    None =>
      self.views.set(key, Wireframe3dViewPhase::new(gpu_preprocessing_mode))
  }
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
pub fn Wireframe3dPhases::add(
  self : Wireframe3dPhases,
  retained_view_entity : @core.Entity,
  batch_set_key : Wireframe3dBatchSetKey,
  bin_key : Wireframe3dBinKey,
  representative_entity : (@core.Entity, @render.MainEntity),
  input_uniform_index : UInt,
  phase_type : WireframeBinnedRenderPhaseType,
) -> Unit {
  match self.views.get(retained_view_entity.to_bits()) {
    Some(phase) =>
      phase.add(
        batch_set_key, bin_key, representative_entity, input_uniform_index, phase_type,
      )
    None => ()
  }
}

///|
pub fn Wireframe3dPhases::remove(
  self : Wireframe3dPhases,
  retained_view_entity : @core.Entity,
  main_entity : @render.MainEntity,
) -> Unit {
  match self.views.get(retained_view_entity.to_bits()) {
    Some(phase) => phase.remove(main_entity)
    None => ()
  }
}

///|
pub fn Wireframe3dPhases::phase(
  self : Wireframe3dPhases,
  retained_view_entity : @core.Entity,
) -> Wireframe3dViewPhase? {
  self.views.get(retained_view_entity.to_bits())
}

///|
pub fn Wireframe3dPhases::retained_view_entities(
  self : Wireframe3dPhases,
) -> Array[@core.Entity] {
  let result : Array[@core.Entity] = []
  for view_bits, _phase in self.views {
    result.push(@core.Entity::from_bits(view_bits))
  }
  result
}

///|
pub struct WireframeViewKeyCache {
  views : Map[UInt64, UInt64]
}

///|
pub fn WireframeViewKeyCache::WireframeViewKeyCache() -> WireframeViewKeyCache {
  WireframeViewKeyCache::{ views: {} }
}

///|
pub let ecs_key_wireframe_view_key_cache : @ecs.ResourceKey[
  WireframeViewKeyCache,
] = @ecs.register_resource(debug_name="mgstudio_pbr::ViewKeyCache")

///|
pub impl @app.Resource for WireframeViewKeyCache with fn resource() {
  ecs_key_wireframe_view_key_cache
}

///|
pub fn WireframeViewKeyCache::insert(
  self : WireframeViewKeyCache,
  retained_view_entity : @core.Entity,
  view_key_bits : UInt64,
) -> Unit {
  self.views.set(retained_view_entity.to_bits(), view_key_bits)
}

///|
pub fn WireframeViewKeyCache::get(
  self : WireframeViewKeyCache,
  retained_view_entity : @core.Entity,
) -> UInt64? {
  self.views.get(retained_view_entity.to_bits())
}

///|
pub fn WireframeViewKeyCache::len(self : WireframeViewKeyCache) -> Int {
  self.views.length()
}

///|
pub fn WireframeViewKeyCache::retain_live_views(
  self : WireframeViewKeyCache,
  live_views : Map[UInt64, Bool],
) -> Unit {
  let stale : Array[UInt64] = []
  for view_bits, _key in self.views {
    if !live_views.contains(view_bits) {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    self.views.remove(view_bits)
  }
}

///|
fn wireframe_mesh_key_for_instance(
  view_key_bits : UInt64,
  render_mesh : @render_mesh.RenderMesh,
  flags : RenderMeshInstanceFlags,
  visibility_range_dither? : Bool = false,
  lightmapped? : Bool = false,
) -> @material.ErasedMeshPipelineKey {
  let mut mesh_key_bits = view_key_bits |
    @mesh.BaseMeshPipelineKey::from_primitive_topology_and_strip_index(
      render_mesh.primitive_topology(),
      render_mesh.index_format(),
    ).bits()
  if visibility_range_dither {
    mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_VISIBILITY_RANGE_DITHER
  }
  if lightmapped {
    mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_LIGHTMAPPED
  }
  if (mesh_key_bits & MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS) != 0UL {
    if flags.contains(RenderMeshInstanceFlags::has_previous_skin()) {
      mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN
    }
    if flags.contains(RenderMeshInstanceFlags::has_previous_morph()) {
      mesh_key_bits = mesh_key_bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH
    }
  }
  @material.ErasedMeshPipelineKey::new(mesh_key_bits, "MeshPipelineKey")
}

///|
fn register_wireframe_pipeline_descriptor_for_same_frame_draw(
  pipeline_cache : @render_resource.PipelineCache,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  pipeline_cache.process_queue()
  let descriptor = pipeline_cache.get_render_pipeline_descriptor(pipeline_id) catch {
    _ => return
  }
  @render.host_gpu_register_mesh3d_material_pipeline_descriptor(
    material_pipeline_id=pipeline_id.id(),
    descriptor~,
  )
}

///|
fn specialize_wireframe_pipeline_id(
  specialized_wireframe_pipeline_cache : SpecializedWireframePipelineCache,
  specialized_wireframe_mesh_pipelines : SpecializedWireframeMeshPipelines,
  pipeline_cache : @render_resource.PipelineCache,
  pipeline : Wireframe3dPipeline,
  mesh_pipeline : MeshPipeline,
  view_key_bits : UInt64,
  render_mesh : @render_mesh.RenderMesh,
  mesh_instance : RenderMeshQueueData,
  material : RenderWireframeMaterial?,
  visibility_range_dither~ : Bool,
  lightmapped~ : Bool,
) -> @material.CachedRenderPipelineId? {
  let mesh_key = wireframe_mesh_key_for_instance(
    view_key_bits,
    render_mesh,
    mesh_instance.flags(),
    visibility_range_dither~,
    lightmapped~,
  )
  let wireframe_key = WireframePipelineKey::from_material(mesh_key, material)
  let mesh_layout = render_mesh.layout()
  if wireframe_key.wide() {
    let wide_key = WireframeWidePipelineCacheKey::new(
      wireframe_key.mesh_key(),
      mesh_layout,
      wireframe_key.quads(),
      wireframe_key.line_mode(),
    )
    match specialized_wireframe_pipeline_cache.wide_pipeline_id(wide_key) {
      Some(pipeline_id) => Some(pipeline_id)
      None => {
        let descriptor = Some(
          pipeline.specialize(
            wireframe_key,
            mesh_pipeline.specialize(mesh_key, mesh_layout),
          ),
        ) catch {
          _ => None
        }
        let pipeline_id = match descriptor {
          Some(value) => pipeline_cache.queue_render_pipeline(value)
          None => @material.CachedRenderPipelineId::invalid()
        }
        if pipeline_id.id() != @material.CachedRenderPipelineId::invalid().id() {
          register_wireframe_pipeline_descriptor_for_same_frame_draw(
            pipeline_cache, pipeline_id,
          )
        }
        specialized_wireframe_pipeline_cache.insert_wide_pipeline(
          wide_key, pipeline_id,
        )
        Some(pipeline_id)
      }
    }
  } else {
    let thin_key = WireframePipelineCacheKey::new(wireframe_key, mesh_layout)
    match specialized_wireframe_mesh_pipelines.pipeline_id(thin_key) {
      Some(pipeline_id) => Some(pipeline_id)
      None => {
        let descriptor = Some(
          pipeline.specialize(
            wireframe_key,
            mesh_pipeline.specialize(mesh_key, mesh_layout),
          ),
        ) catch {
          _ => None
        }
        guard descriptor is Some(value) else { return None }
        let pipeline_id = pipeline_cache.queue_render_pipeline(value)
        register_wireframe_pipeline_descriptor_for_same_frame_draw(
          pipeline_cache, pipeline_id,
        )
        specialized_wireframe_mesh_pipelines.insert(thin_key, pipeline_id)
        Some(pipeline_id)
      }
    }
  }
}

///|
pub fn specialize_wireframe_phase_items(
  retained_view_entity : @core.Entity,
  render_mesh_visible_entities : @render_visibility.RenderVisibleEntitiesClass,
  view_pending_wireframe_queues : ViewPendingWireframeQueues,
  specialized_wireframe_pipeline_cache : SpecializedWireframePipelineCache,
  specialized_wireframe_mesh_pipelines : SpecializedWireframeMeshPipelines,
  render_wireframe_instances : RenderWireframeInstances,
  dirty_wireframe_specializations : DirtyWireframeSpecializations,
  render_wireframe_assets : Map[Int, RenderWireframeMaterial],
  render_mesh_instances : RenderMeshInstances,
  render_meshes : @render_mesh.RenderMeshAssets,
  view_key_bits : UInt64,
  render_visibility_ranges : @render_visibility.RenderVisibilityRanges,
  render_lightmaps : @lightmap.RenderLightmaps,
  pipeline : Wireframe3dPipeline,
  mesh_pipeline : MeshPipeline,
  pipeline_cache : @render_resource.PipelineCache,
) -> Unit {
  despecialize_wireframe_view_cache(
    specialized_wireframe_pipeline_cache, dirty_wireframe_specializations, retained_view_entity,
  )
  let candidates = dirty_wireframe_specializations.iter_to_specialize(
    retained_view_entity,
    render_mesh_visible_entities,
    view_pending_wireframe_queues.prev_frame(),
  )
  for pair in candidates {
    let render_entity = pair.0
    let visible_entity = pair.1
    if specialized_wireframe_pipeline_cache.pipeline_id(
        retained_view_entity, visible_entity,
      )
      is Some(_) {
      continue
    }
    guard render_wireframe_instances.get(visible_entity)
      is Some(wireframe_asset_id) else {
      continue
    }
    guard render_mesh_instances.render_mesh_queue_data(visible_entity)
      is Some(mesh_instance) else {
      view_pending_wireframe_queues.push_current(render_entity, visible_entity)
      continue
    }
    guard render_meshes.get(mesh_instance.mesh_asset_id()) is Some(render_mesh) else {
      continue
    }
    let material = render_wireframe_assets.get(wireframe_asset_id)
    let visibility_range_dither = render_visibility_ranges.entity_has_crossfading_visibility_ranges(
      visible_entity.id().id,
    )
    let lightmapped = render_lightmaps.get(visible_entity.id()) is Some(_)
    guard specialize_wireframe_pipeline_id(
        specialized_wireframe_pipeline_cache,
        specialized_wireframe_mesh_pipelines,
        pipeline_cache,
        pipeline,
        mesh_pipeline,
        view_key_bits,
        render_mesh,
        mesh_instance,
        material,
        visibility_range_dither~,
        lightmapped~,
      )
      is Some(pipeline_id) else {
      continue
    }
    specialized_wireframe_pipeline_cache.insert(
      retained_view_entity, visible_entity, pipeline_id,
    )
  }
}

///|
pub fn queue_wireframe_phase_items(
  wireframe_phase : Wireframe3dViewPhase,
  retained_view_entity : @core.Entity,
  render_mesh_visible_entities : @render_visibility.RenderVisibleEntitiesClass,
  view_pending_wireframe_queues : ViewPendingWireframeQueues,
  specialized_wireframe_pipeline_cache : SpecializedWireframePipelineCache,
  render_wireframe_instances : RenderWireframeInstances,
  dirty_wireframe_specializations : DirtyWireframeSpecializations,
  render_wireframe_assets : Map[Int, RenderWireframeMaterial],
  render_mesh_instances : RenderMeshInstances,
  mesh_allocator : @render_mesh.MeshAllocator,
  draw_functions : Wireframe3dDrawFunctions,
  gpu_preprocessing_support : @render_batching.GpuPreprocessingSupport,
) -> Unit {
  for
    main_entity in dirty_wireframe_specializations.iter_to_dequeue(
      retained_view_entity, render_mesh_visible_entities,
    ) {
    wireframe_phase.remove(main_entity)
  }
  let candidates = dirty_wireframe_specializations.iter_to_queue(
    retained_view_entity,
    render_mesh_visible_entities,
    view_pending_wireframe_queues.prev_frame(),
  )
  for pair in candidates {
    let render_entity = pair.0
    let visible_entity = pair.1
    guard render_wireframe_instances.get(visible_entity)
      is Some(wireframe_asset_id) else {
      continue
    }
    guard specialized_wireframe_pipeline_cache.pipeline_id(
        retained_view_entity, visible_entity,
      )
      is Some(pipeline_id) else {
      continue
    }
    guard render_mesh_instances.render_mesh_queue_data(visible_entity)
      is Some(mesh_instance) else {
      view_pending_wireframe_queues.push_current(render_entity, visible_entity)
      continue
    }
    let is_wide = match render_wireframe_assets.get(wireframe_asset_id) {
      Some(material) =>
        material.line_width > 1.0F ||
        material.topology == WireframeTopology::Quads
      None => false
    }
    let draw_function = if is_wide {
      draw_functions.wide()
    } else {
      draw_functions.thin()
    }
    guard mesh_allocator.mesh_slabs(mesh_instance.mesh_asset_id())
      is Some(slabs) else {
      continue
    }
    let batch_set_key = Wireframe3dBatchSetKey::new(
      pipeline_id,
      wireframe_asset_id,
      draw_function,
      if is_wide {
        @render_mesh.MeshSlabs::new(
          slabs.vertex_slab_id(),
          index_slab_id=None,
          morph_target_slab_id=slabs.morph_target_slab_id(),
        )
      } else {
        slabs
      },
      mesh_asset_id=if is_wide {
        Some(mesh_instance.mesh_asset_id())
      } else {
        None
      },
    )
    let bin_key = Wireframe3dBinKey::new(mesh_instance.mesh_asset_id())
    wireframe_phase.add(
      batch_set_key,
      bin_key,
      (render_entity, visible_entity),
      mesh_instance.current_uniform_index(),
      WireframeBinnedRenderPhaseType::mesh(
        mesh_instance.should_batch(),
        gpu_preprocessing_support,
      ),
    )
  }
}
