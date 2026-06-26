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
test "render3d: materials startup initializes bevy material render resources" {
  let world = @ecs.World::new()

  init_materials_resources(world)

  debug_inspect(
    world.get_resource(ecs_key_entity_specialization_ticks) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_specialized_material_pipeline_cache) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@render_visibility.DirtySpecializations::resource())
    is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@pbr_render.LightKeyCache::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    )
    is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_render_material_instances) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(ecs_key_material_bind_group_allocators) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(PendingMeshMaterialQueues::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    world.get_resource(@pbr_render.PendingShadowQueues::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    get_default_opaque_renderer_method_resource(world).is_present(),
    content="true",
  )
}

///|
test "render3d: materials startup preserves existing material render resources" {
  let world = @ecs.World::new()
  let entity_ticks = EntitySpecializationTicks::EntitySpecializationTicks()
  let entity = @core.Entity::new(12, 0)
  entity_ticks.insert(entity, EntitySpecializationTickPair::new(5, 6))
  world.insert_resource(ecs_key_entity_specialization_ticks, entity_ticks)

  init_materials_resources(world)

  match world.get_resource(ecs_key_entity_specialization_ticks) {
    Some(ticks) =>
      debug_inspect(
        ticks.get(entity).map(fn(pair) { pair.system_tick() }),
        content="Some(5)",
      )
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: materials startup preserves pending queue resources" {
  let world = @ecs.World::new()
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(10, 1))
  let mesh_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  mesh_queues
  .queues()
  .push_current(
    view,
    @core.Entity::new(1, 1),
    @render.MainEntity::new(@core.Entity::new(2, 1)),
  )
  let shadow_queues = @pbr_render.PendingShadowQueues::PendingShadowQueues()
  shadow_queues
  .queues()
  .push_current(
    view,
    @core.Entity::new(3, 1),
    @render.MainEntity::new(@core.Entity::new(4, 1)),
  )
  world.insert_resource(PendingMeshMaterialQueues::resource(), mesh_queues)
  world.insert_resource(
    @pbr_render.PendingShadowQueues::resource(),
    shadow_queues,
  )

  init_materials_resources(world)

  match world.get_resource(PendingMeshMaterialQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(view), content="1")
    None => debug_inspect(false, content="true")
  }
  match world.get_resource(@pbr_render.PendingShadowQueues::resource()) {
    Some(queues) =>
      debug_inspect(queues.queues().current_len(view), content="1")
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: materials startup preserves shadow specialization caches" {
  let world = @ecs.World::new()
  let view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(10, 1),
    auxiliary_entity=Some(@core.Entity::new(20, 1)),
    subview_index=1,
  )
  let main_entity = @render.MainEntity::new(@core.Entity::new(11, 1))
  let light_key_cache = @pbr_render.LightKeyCache::LightKeyCache()
  light_key_cache.insert(
    view,
    @material.ErasedMeshPipelineKey::new(13UL, "MeshPipelineKey"),
  )
  let shadow_cache = @pbr_render.SpecializedShadowMaterialPipelineCache::SpecializedShadowMaterialPipelineCache()
  shadow_cache.insert(
    view,
    main_entity,
    @material.CachedRenderPipelineId::new(21UL),
    @material.DrawFunctionId::new(5U),
  )
  world.insert_resource(@pbr_render.LightKeyCache::resource(), light_key_cache)
  world.insert_resource(
    @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    shadow_cache,
  )

  init_materials_resources(world)

  match world.get_resource(@pbr_render.LightKeyCache::resource()) {
    Some(cache) =>
      debug_inspect(
        cache.get(view).map(fn(key) { key.bits() }),
        content="Some(13)",
      )
    None => debug_inspect(false, content="true")
  }
  match
    world.get_resource(
      @pbr_render.SpecializedShadowMaterialPipelineCache::resource(),
    ) {
    Some(cache) =>
      debug_inspect(
        cache.pipeline_id(view, main_entity).map(fn(value) { value.id() }),
        content="Some(21)",
      )
    None => debug_inspect(false, content="true")
  }
}
