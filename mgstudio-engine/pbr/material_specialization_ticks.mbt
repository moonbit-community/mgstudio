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
// Bevy source: `bevy/crates/bevy_pbr/src/material.rs`.

///|
pub struct EntitySpecializationTickPair {
  system_tick : @core.Tick
  material_instances_tick : @core.Tick
} derive(Eq, Debug)

///|
pub fn EntitySpecializationTickPair::new(
  system_tick : @core.Tick,
  material_instances_tick : @core.Tick,
) -> EntitySpecializationTickPair {
  { system_tick, material_instances_tick }
}

///|
pub fn EntitySpecializationTickPair::system_tick(
  self : EntitySpecializationTickPair,
) -> @core.Tick {
  self.system_tick
}

///|
pub fn EntitySpecializationTickPair::material_instances_tick(
  self : EntitySpecializationTickPair,
) -> @core.Tick {
  self.material_instances_tick
}

///|
pub struct EntitySpecializationTicks {
  entities : Map[UInt64, EntitySpecializationTickPair]
}

///|
pub fn EntitySpecializationTicks::EntitySpecializationTicks() -> EntitySpecializationTicks {
  { entities: Map([]) }
}

///|
pub let ecs_key_entity_specialization_ticks : @ecs.ResourceKey[
  EntitySpecializationTicks,
] = @ecs.register_resource(debug_name="mgstudio_pbr::EntitySpecializationTicks")

///|
pub fn EntitySpecializationTicks::len(self : EntitySpecializationTicks) -> Int {
  self.entities.length()
}

///|
pub fn EntitySpecializationTicks::get(
  self : EntitySpecializationTicks,
  entity : @core.Entity,
) -> EntitySpecializationTickPair? {
  self.entities.get(entity.to_bits())
}

///|
pub fn EntitySpecializationTicks::insert(
  self : EntitySpecializationTicks,
  entity : @core.Entity,
  pair : EntitySpecializationTickPair,
) -> Unit {
  self.entities.set(entity.to_bits(), pair)
}

///|
pub fn EntitySpecializationTicks::remove(
  self : EntitySpecializationTicks,
  entity : @core.Entity,
) -> Bool {
  let key = entity.to_bits()
  if self.entities.contains(key) {
    self.entities.remove(key)
    true
  } else {
    false
  }
}

///|
pub fn EntitySpecializationTicks::extract_entity_needs_specialization(
  self : EntitySpecializationTicks,
  entity : @core.Entity,
  system_tick : @core.Tick,
  render_material_instances : RenderMaterialInstances,
  dirty_specializations : @render_visibility.DirtySpecializations,
) -> Unit {
  self.insert(
    entity,
    EntitySpecializationTickPair::new(
      system_tick,
      render_material_instances.current_change_tick(),
    ),
  )
  dirty_specializations.insert_changed(@render.MainEntity::new(entity))
}

///|
pub struct SpecializedMaterialPipelineCacheEntry {
  tick : @core.Tick
  pipeline_id : @material.CachedRenderPipelineId
}

///|
pub fn SpecializedMaterialPipelineCacheEntry::new(
  tick : @core.Tick,
  pipeline_id : @material.CachedRenderPipelineId,
) -> SpecializedMaterialPipelineCacheEntry {
  { tick, pipeline_id }
}

///|
pub fn SpecializedMaterialPipelineCacheEntry::tick(
  self : SpecializedMaterialPipelineCacheEntry,
) -> @core.Tick {
  self.tick
}

///|
pub fn SpecializedMaterialPipelineCacheEntry::pipeline_id(
  self : SpecializedMaterialPipelineCacheEntry,
) -> @material.CachedRenderPipelineId {
  self.pipeline_id
}

///|
pub struct SpecializedMaterialViewPipelineCache {
  entries : Map[UInt64, SpecializedMaterialPipelineCacheEntry]
}

///|
pub fn SpecializedMaterialViewPipelineCache::SpecializedMaterialViewPipelineCache() -> SpecializedMaterialViewPipelineCache {
  { entries: Map([]) }
}

///|
pub fn SpecializedMaterialViewPipelineCache::len(
  self : SpecializedMaterialViewPipelineCache,
) -> Int {
  self.entries.length()
}

///|
pub fn SpecializedMaterialViewPipelineCache::clear(
  self : SpecializedMaterialViewPipelineCache,
) -> Unit {
  self.entries.clear()
}

///|
pub fn SpecializedMaterialViewPipelineCache::get(
  self : SpecializedMaterialViewPipelineCache,
  entity : @core.Entity,
) -> SpecializedMaterialPipelineCacheEntry? {
  self.entries.get(entity.to_bits())
}

///|
pub fn SpecializedMaterialViewPipelineCache::insert(
  self : SpecializedMaterialViewPipelineCache,
  entity : @core.Entity,
  entry : SpecializedMaterialPipelineCacheEntry,
) -> Unit {
  self.entries.set(entity.to_bits(), entry)
}

///|
pub fn SpecializedMaterialViewPipelineCache::remove(
  self : SpecializedMaterialViewPipelineCache,
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
pub struct SpecializedMaterialPipelineCache {
  views : @hashmap.HashMap[
    @render_view.RetainedViewEntity,
    SpecializedMaterialViewPipelineCache,
  ]
}

///|
pub fn SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache() -> SpecializedMaterialPipelineCache {
  { views: HashMap([]) }
}

///|
pub let ecs_key_specialized_material_pipeline_cache : @ecs.ResourceKey[
  SpecializedMaterialPipelineCache,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::SpecializedMaterialPipelineCache",
)

///|
pub fn SpecializedMaterialPipelineCache::len(
  self : SpecializedMaterialPipelineCache,
) -> Int {
  self.views.length()
}

///|
pub fn SpecializedMaterialPipelineCache::clear(
  self : SpecializedMaterialPipelineCache,
) -> Unit {
  self.views.clear()
}

///|
pub fn SpecializedMaterialPipelineCache::get(
  self : SpecializedMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
) -> SpecializedMaterialViewPipelineCache? {
  self.views.get(view)
}

///|
pub fn SpecializedMaterialPipelineCache::pipeline_id(
  self : SpecializedMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
  entity : @core.Entity,
) -> @material.CachedRenderPipelineId? {
  match self.get(view) {
    Some(view_cache) =>
      view_cache.get(entity).map(fn(entry) { entry.pipeline_id() })
    None => None
  }
}

///|
pub fn SpecializedMaterialPipelineCache::view_or_insert(
  self : SpecializedMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
) -> SpecializedMaterialViewPipelineCache {
  match self.views.get(view) {
    Some(cache) => cache
    None => {
      let cache = SpecializedMaterialViewPipelineCache::SpecializedMaterialViewPipelineCache()
      self.views.set(view, cache)
      cache
    }
  }
}

///|
pub fn SpecializedMaterialPipelineCache::clear_view(
  self : SpecializedMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
) -> Unit {
  match self.views.get(view) {
    Some(cache) => {
      cache.clear()
      if cache.len() == 0 {
        self.views.remove(view)
      }
    }
    None => ()
  }
}

///|
pub fn SpecializedMaterialPipelineCache::remove(
  self : SpecializedMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
  entity : @core.Entity,
) -> Bool {
  match self.views.get(view) {
    Some(cache) => cache.remove(entity)
    None => false
  }
}

///|
pub fn SpecializedMaterialPipelineCache::apply_dirty_specializations_for_view(
  self : SpecializedMaterialPipelineCache,
  dirty_specializations : @render_visibility.DirtySpecializations,
  view : @render_view.RetainedViewEntity,
) -> Unit {
  if dirty_specializations.must_wipe_specializations_for_view(view) {
    self.clear_view(view)
  } else {
    for main_entity in dirty_specializations.iter_to_despecialize() {
      ignore(self.remove(view, main_entity.id()))
    }
  }
}

///|
pub fn SpecializedMaterialPipelineCache::insert(
  self : SpecializedMaterialPipelineCache,
  view : @render_view.RetainedViewEntity,
  entity : @core.Entity,
  tick : @core.Tick,
  pipeline_id : @material.CachedRenderPipelineId,
) -> Unit {
  self
  .view_or_insert(view)
  .insert(entity, SpecializedMaterialPipelineCacheEntry::new(tick, pipeline_id))
}

///|
pub fn SpecializedMaterialPipelineCache::remove_entity_from_all_views(
  self : SpecializedMaterialPipelineCache,
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
pub fn SpecializedMaterialPipelineCache::expire_stale_views(
  self : SpecializedMaterialPipelineCache,
  live_views : @hashset.HashSet[@render_view.RetainedViewEntity],
) -> Unit {
  let stale : Array[@render_view.RetainedViewEntity] = []
  for view, _cache in self.views {
    if !live_views.contains(view) {
      stale.push(view)
    }
  }
  for view in stale {
    self.views.remove(view)
  }
}

///|
pub fn material_specialization_tick_is_newer_than(
  tick : @core.Tick,
  last_run : @core.Tick,
  this_run : @core.Tick,
) -> Bool {
  @core.tick_is_newer_than(tick, last_run, this_run)
}

///|
pub fn material_entity_needs_specialization(
  last_specialized_tick : @core.Tick?,
  view_tick : @core.Tick,
  entity_tick : @core.Tick,
  this_run : @core.Tick,
) -> Bool {
  match last_specialized_tick {
    None => true
    Some(tick) =>
      material_specialization_tick_is_newer_than(view_tick, tick, this_run) ||
      material_specialization_tick_is_newer_than(entity_tick, tick, this_run)
  }
}

///|
pub fn sweep_entity_needing_specialization(
  entity_specialization_ticks : EntitySpecializationTicks,
  specialized_material_pipeline_cache : SpecializedMaterialPipelineCache,
  render_material_instances : RenderMaterialInstances,
  entity : @core.Entity,
) -> Bool {
  match entity_specialization_ticks.get(entity) {
    Some(pair) =>
      if pair.material_instances_tick() ==
        render_material_instances.current_change_tick() {
        false
      } else {
        let removed_tick = entity_specialization_ticks.remove(entity)
        ignore(
          specialized_material_pipeline_cache.remove_entity_from_all_views(
            entity,
          ),
        )
        removed_tick
      }
    _ => {
      let removed_tick = entity_specialization_ticks.remove(entity)
      ignore(
        specialized_material_pipeline_cache.remove_entity_from_all_views(entity),
      )
      removed_tick
    }
  }
}
