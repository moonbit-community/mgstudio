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
test "render3d: pending mesh material queues prepare live views and expire stale views" {
  let live_view = @render_view.RetainedViewEntity::new(@core.Entity::new(30, 1))
  let stale_view = @render_view.RetainedViewEntity::new(
    @core.Entity::new(31, 1),
  )
  let queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  queues
  .queues()
  .push_current(
    live_view,
    @core.Entity::new(32, 1),
    @render.MainEntity::new(@core.Entity::new(33, 1)),
  )
  queues
  .queues()
  .push_current(
    stale_view,
    @core.Entity::new(34, 1),
    @render.MainEntity::new(@core.Entity::new(35, 1)),
  )

  ignore(queues.prepare_for_new_frame(live_view))
  let live_views : @hashset.HashSet[@render_view.RetainedViewEntity] = @hashset.HashSet([],
  )
  live_views.add(live_view)
  queues.expire_stale_views(live_views)

  debug_inspect(queues.current_len(live_view), content="0")
  debug_inspect(queues.prev_len(live_view), content="1")
  debug_inspect(queues.current_len(stale_view), content="0")
  debug_inspect(queues.prev_len(stale_view), content="0")
  debug_inspect(queues.view_len(), content="1")
}

///|
fn material_test_pair_contains(
  pairs : Array[(@core.Entity, @render.MainEntity)],
  render_entity : @core.Entity,
  main_entity : @core.Entity,
) -> Bool {
  for pair in pairs {
    if pair.0 == render_entity && pair.1 == @render.MainEntity::new(main_entity) {
      return true
    }
  }
  false
}

///|
test "render3d: extract render visible entities mirrors camera visible Mesh3d pairs" {
  let world = @ecs.World::new()
  let main_camera = world.spawn()
  let render_camera = world.spawn()
  let main_mesh = world.spawn()
  let render_mesh = world.spawn()
  try! world.set_by_key(main_camera, ecs_key_camera3d, Camera3d::Camera3d())
  try! world.set_by_key(
    main_camera,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  try! world.set_by_key(
    main_camera,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_camera),
  )
  try! world.set_by_key(
    main_mesh,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_mesh),
  )
  let visible = @camera_camera.VisibleEntities::VisibleEntities()
  visible.push(main_mesh, @mesh.ecs_key_mesh3d.id())
  try! world.set_by_key(
    main_camera, @camera_camera.ecs_key_visible_entities, visible,
  )

  render3d_extract_render_visible_entities(world, world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(render3d_mesh_visibility_class()) {
        Some(mesh_visible) => {
          debug_inspect(mesh_visible.visible_len(), content="1")
          debug_inspect(mesh_visible.added_entities().length(), content="1")
          debug_inspect(mesh_visible.removed_entities().length(), content="0")
          debug_inspect(
            mesh_visible.entity_pair_is_visible(
              render_mesh,
              @render.MainEntity::new(main_mesh),
            ),
            content="true",
          )
        }
        None => debug_inspect(false, content="true")
      }
    None => debug_inspect(false, content="true")
  }

  let no_visible_meshes = @camera_camera.VisibleEntities::VisibleEntities()
  try! world.set_by_key(
    main_camera, @camera_camera.ecs_key_visible_entities, no_visible_meshes,
  )
  render3d_extract_render_visible_entities(world, world)

  match
    (try! world.get_by_key(
      render_camera, @render_visibility.ecs_key_render_visible_entities,
    )) {
    Some(render_visible) =>
      match render_visible.get(render3d_mesh_visibility_class()) {
        Some(mesh_visible) => {
          debug_inspect(mesh_visible.visible_len(), content="0")
          debug_inspect(mesh_visible.added_entities().length(), content="0")
          debug_inspect(mesh_visible.removed_entities().length(), content="1")
        }
        None => debug_inspect(false, content="true")
      }
    None => debug_inspect(false, content="true")
  }
}

///|
test "render3d: material specialization candidates come from visible dirty and pending meshes" {
  let world = @ecs.World::new()
  let main_view = @core.Entity::new(41, 1)
  let render_view = world.spawn()
  let unchanged_main = @core.Entity::new(42, 1)
  let unchanged_render = @core.Entity::new(43, 1)
  let changed_main = @core.Entity::new(44, 1)
  let changed_render = @core.Entity::new(45, 1)
  let pending_main = @core.Entity::new(46, 1)
  let pending_render = @core.Entity::new(47, 1)
  let added_main = @core.Entity::new(48, 1)
  let added_render = @core.Entity::new(49, 1)
  let visible_entities = @render_visibility.RenderVisibleEntities::RenderVisibleEntities()
  let visible_class = visible_entities.class_or_insert(
    render3d_mesh_visibility_class(),
  )
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
  ])
  visible_class.prepare_for_new_frame()
  visible_class.update_cpu_culled_entities([
    (unchanged_render, @render.MainEntity::new(unchanged_main)),
    (changed_render, @render.MainEntity::new(changed_main)),
    (pending_render, @render.MainEntity::new(pending_main)),
    (added_render, @render.MainEntity::new(added_main)),
  ])
  visible_class.sort_added_entities()
  try! world.set_by_key(
    render_view, @render_visibility.ecs_key_render_visible_entities, visible_entities,
  )
  let dirty_specializations = @render_visibility.DirtySpecializations::DirtySpecializations()
  dirty_specializations.insert_changed(@render.MainEntity::new(changed_main))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let retained_view = @render_view.RetainedViewEntity::new(main_view)
  pending_queues
  .queues()
  .push_current(
    retained_view,
    pending_render,
    @render.MainEntity::new(pending_main),
  )
  ignore(pending_queues.prepare_for_new_frame(retained_view))

  let candidates = render3d_material_specialization_candidates(
    world, render_view, retained_view, dirty_specializations, pending_queues,
  )

  debug_inspect(candidates.length(), content="3")
  debug_inspect(
    material_test_pair_contains(candidates, added_render, added_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, changed_render, changed_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, pending_render, pending_main),
    content="true",
  )
  debug_inspect(
    material_test_pair_contains(candidates, unchanged_render, unchanged_main),
    content="false",
  )
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
