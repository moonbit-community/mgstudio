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
  let entity = @core.Entity::new(31, 0)

  material_instances.advance_change_tick()
  entity_ticks.extract_entity_needs_specialization(
    entity, 7, material_instances,
  )

  match entity_ticks.get(entity) {
    Some(pair) => {
      debug_inspect(pair.system_tick(), content="7")
      debug_inspect(pair.material_instances_tick(), content="1")
    }
    None => debug_inspect(false, content="true")
  }
}

///|
test "pbr material specialization: cache stores per-view pipeline ids" {
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  let view = @core.Entity::new(1, 0)
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
  let view = @core.Entity::new(4, 0)
  let entity = @core.Entity::new(5, 0)

  entity_ticks.extract_entity_needs_specialization(
    entity, 3, material_instances,
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
  let view_a = @core.Entity::new(9, 0)
  let view_b = @core.Entity::new(10, 0)
  let entity = @core.Entity::new(11, 0)

  entity_ticks.extract_entity_needs_specialization(
    entity, 3, material_instances,
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
