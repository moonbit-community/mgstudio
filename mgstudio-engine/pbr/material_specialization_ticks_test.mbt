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
test "pbr material specialization: entity ticks capture system and material instance ticks" {
  let entity_ticks = EntitySpecializationTicks::EntitySpecializationTicks()
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  let dirty = @render_visibility.DirtySpecializations::DirtySpecializations()
  let entity = @core.Entity::new(31, 0)

  material_instances.advance_change_tick()
  entity_ticks.extract_entity_needs_specialization(
    entity, 7, material_instances, dirty,
  )

  match entity_ticks.get(entity) {
    Some(pair) => {
      debug_inspect(pair.system_tick(), content="7")
      debug_inspect(pair.material_instances_tick(), content="1")
    }
    None => debug_inspect(false, content="true")
  }
  debug_inspect(
    dirty.changed_contains(@render.MainEntity::new(entity)),
    content="true",
  )
}

///|
test "pbr material specialization: cache stores per-view pipeline ids" {
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(1, 0))
  let entity = @core.Entity::new(2, 0)
  let pipeline_id = @material.CachedRenderPipelineId::new(55UL)

  cache.insert(view, entity, 11, pipeline_id)
  debug_inspect(cache.len(), content="1")
  let cached_entry = match cache.get(view) {
    Some(view_cache) => view_cache.get(entity)
    None => None
  }
  match cached_entry {
    Some(entry) => {
      debug_inspect(entry.tick(), content="11")
      debug_inspect(entry.pipeline_id().id(), content="55")
    }
    None => debug_inspect(false, content="true")
  }
  debug_inspect(
    cache.pipeline_id(view, entity).map(fn(value) { value.id() }),
    content="Some(55)",
  )
}

///|
test "pbr material specialization: needs specialization follows view or entity tick freshness" {
  debug_inspect(
    material_entity_needs_specialization(None, 1, 1, 2),
    content="true",
  )
  debug_inspect(
    material_entity_needs_specialization(Some(5), 6, 5, 7),
    content="true",
  )
  debug_inspect(
    material_entity_needs_specialization(Some(5), 5, 6, 7),
    content="true",
  )
  debug_inspect(
    material_entity_needs_specialization(Some(5), 5, 5, 7),
    content="false",
  )
}

///|
test "pbr material specialization: sweep preserves same-frame material type replacement" {
  let entity_ticks = EntitySpecializationTicks::EntitySpecializationTicks()
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  let dirty = @render_visibility.DirtySpecializations::DirtySpecializations()
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(4, 0))
  let entity = @core.Entity::new(5, 0)

  entity_ticks.extract_entity_needs_specialization(
    entity, 3, material_instances, dirty,
  )
  cache.insert(view, entity, 3, @material.CachedRenderPipelineId::new(77UL))

  debug_inspect(
    sweep_entity_needing_specialization(
      entity_ticks, cache, material_instances, entity,
    ),
    content="false",
  )
  debug_inspect(entity_ticks.len(), content="1")
  debug_inspect(
    cache.get(view).map(fn(value) { value.len() }),
    content="Some(1)",
  )
}

///|
test "pbr material specialization: sweep removes stale ticks and cached pipelines" {
  let entity_ticks = EntitySpecializationTicks::EntitySpecializationTicks()
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  let dirty = @render_visibility.DirtySpecializations::DirtySpecializations()
  let view_a = @render_view.RetainedViewEntity::new(@core.Entity::new(9, 0))
  let view_b = @render_view.RetainedViewEntity::new(@core.Entity::new(10, 0))
  let entity = @core.Entity::new(11, 0)

  entity_ticks.extract_entity_needs_specialization(
    entity, 3, material_instances, dirty,
  )
  material_instances.advance_change_tick()
  cache.insert(view_a, entity, 3, @material.CachedRenderPipelineId::new(7UL))
  cache.insert(view_b, entity, 3, @material.CachedRenderPipelineId::new(8UL))

  debug_inspect(
    sweep_entity_needing_specialization(
      entity_ticks, cache, material_instances, entity,
    ),
    content="true",
  )
  debug_inspect(entity_ticks.len(), content="0")
  debug_inspect(
    cache.get(view_a).map(fn(value) { value.len() }),
    content="Some(0)",
  )
  debug_inspect(
    cache.get(view_b).map(fn(value) { value.len() }),
    content="Some(0)",
  )
}

///|
test "pbr material specialization: cache clears dirty views and expires stale retained views" {
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  let live_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(20, 0),
    auxiliary_entity=Some(@core.Entity::new(21, 0)),
    subview_index=1,
  )
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(22, 0),
  )
  let entity = @core.Entity::new(23, 0)
  cache.insert(
    live_view,
    entity,
    1,
    @material.CachedRenderPipelineId::new(31UL),
  )
  cache.insert(
    stale_view,
    entity,
    1,
    @material.CachedRenderPipelineId::new(32UL),
  )

  cache.clear_view(live_view)
  debug_inspect(cache.pipeline_id(live_view, entity) is None, content="true")
  debug_inspect(
    cache.pipeline_id(stale_view, entity).map(fn(value) { value.id() }),
    content="Some(32)",
  )

  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  live_views.add(live_view)
  cache.expire_stale_views(live_views)
  debug_inspect(cache.pipeline_id(stale_view, entity) is None, content="true")
}

///|
test "pbr material specialization: cache applies dirty specialization removals per retained view" {
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  let dirty = @render_visibility.DirtySpecializations::DirtySpecializations()
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(30, 0))
  let other_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(31, 0),
  )
  let changed_entity = @core.Entity::new(32, 0)
  let removed_entity = @core.Entity::new(33, 0)
  let stable_entity = @core.Entity::new(34, 0)

  cache.insert(
    view,
    changed_entity,
    1,
    @material.CachedRenderPipelineId::new(41UL),
  )
  cache.insert(
    view,
    removed_entity,
    1,
    @material.CachedRenderPipelineId::new(42UL),
  )
  cache.insert(
    view,
    stable_entity,
    1,
    @material.CachedRenderPipelineId::new(43UL),
  )
  cache.insert(
    other_view,
    changed_entity,
    1,
    @material.CachedRenderPipelineId::new(44UL),
  )
  dirty.insert_changed(@render.MainEntity::new(changed_entity))
  dirty.insert_removed(@render.MainEntity::new(removed_entity))

  cache.apply_dirty_specializations_for_view(dirty, view)
  debug_inspect(cache.pipeline_id(view, changed_entity) is None, content="true")
  debug_inspect(cache.pipeline_id(view, removed_entity) is None, content="true")
  debug_inspect(
    cache.pipeline_id(view, stable_entity).map(fn(value) { value.id() }),
    content="Some(43)",
  )
  debug_inspect(
    cache.pipeline_id(other_view, changed_entity).map(fn(value) { value.id() }),
    content="Some(44)",
  )
}
