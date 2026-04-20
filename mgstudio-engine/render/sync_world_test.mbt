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
struct RenderSyncWorldTestComponent {} derive(Eq, Debug)

///|
let ecs_key_render_sync_world_test_component : @ecs.ComponentKey[
  RenderSyncWorldTestComponent,
] = @ecs.register_component(
  debug_name="mgstudio_render::RenderSyncWorldTestComponent",
)

///|
pub impl @ecs.Component for RenderSyncWorldTestComponent with component() {
  ecs_key_render_sync_world_test_component
}

///|
fn synced_render_entities(render_world : @ecs.World) -> Array[@core.Entity] {
  let query : @ecs.QueryState[@core.Entity, @ecs.With[MainEntity]] = render_world.query_filtered(
    @ecs.With::new(ecs_key_main_entity),
  )
  let iter = query.iter(render_world)
  let out : Array[@core.Entity] = []
  while (iter.fetch_next() catch { _ => None }) is Some((entity, _)) {
    out.push(entity)
  }
  out
}

///|
test "render sync world: add/remove syncs entities between main world and render world" {
  let mut main_world = @ecs.World::new()
  let mut render_world = @ecs.World::new()
  main_world.insert_resource(
    ecs_key_pending_sync_entity,
    PendingSyncEntity::default(),
  )

  for _ in 0..<99 {
    ignore(main_world.spawn_empty())
  }

  let main_entity = main_world.spawn()
  try! main_world.set_by_key(
    main_entity,
    ecs_key_render_sync_world_test_component,
    RenderSyncWorldTestComponent::{  },
  )
  try! main_world.set_by_key(
    main_entity,
    ecs_key_sync_to_render_world,
    SyncToRenderWorld::default(),
  )

  let synced = sync_world(main_world, render_world)
  main_world = synced.0
  render_world = synced.1

  debug_inspect(render_world.entity_count(), content="1")
  let synced_render_entities_after_add = synced_render_entities(render_world)
  debug_inspect(synced_render_entities_after_add.length(), content="1")
  let render_entity = synced_render_entities_after_add[0]
  let render_component = (try! main_world.get(
    main_entity,
    key=ecs_key_render_entity,
  )).unwrap()
  debug_inspect(render_component.id() == render_entity, content="true")
  let main_component = (try! render_world.get(
    render_entity,
    key=ecs_key_main_entity,
  )).unwrap()
  debug_inspect(main_component.id() == main_entity, content="true")

  try! main_world.despawn(main_entity)
  let synced_after_remove = sync_world(main_world, render_world)
  main_world = synced_after_remove.0
  render_world = synced_after_remove.1
  debug_inspect(synced_render_entities(render_world).length(), content="0")
  debug_inspect(main_world.is_alive(main_entity), content="false")
}

///|
test "render sync world: cleanup despawns temporary render entities" {
  let render_world = @ecs.World::new()
  let stable = render_world.spawn()
  let temporary0 = render_world.spawn()
  let temporary1 = render_world.spawn()
  try! render_world.set(temporary0, TemporaryRenderEntity::default())
  try! render_world.set(temporary1, TemporaryRenderEntity::default())

  despawn_temporary_render_entities(render_world)

  debug_inspect(render_world.is_alive(stable), content="true")
  debug_inspect(render_world.is_alive(temporary0), content="false")
  debug_inspect(render_world.is_alive(temporary1), content="false")
}
