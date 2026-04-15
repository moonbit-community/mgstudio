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
// Bevy source: `bevy/crates/bevy_render/src/sync_world.rs`.

///|
const SYNC_WORLD_PLUGIN_NAME : String = "mgstudio.render.SyncWorldPlugin"

///|
pub struct SyncWorldPlugin {}

///|
pub fn SyncWorldPlugin::default() -> SyncWorldPlugin {
  SyncWorldPlugin::{  }
}

///|
pub impl @app.Plugin for SyncWorldPlugin with name(_self) {
  SYNC_WORLD_PLUGIN_NAME
}

///|
pub impl @app.Plugin for SyncWorldPlugin with build(self, app) {
  sync_world_plugin_with(app, self)
}

///|
pub struct SyncToRenderWorld {}

///|
pub fn SyncToRenderWorld::default() -> SyncToRenderWorld {
  SyncToRenderWorld::{  }
}

///|
pub impl Default for SyncToRenderWorld with default() {
  SyncToRenderWorld::default()
}

///|
pub let ecs_key_sync_to_render_world : @ecs.ComponentKey[SyncToRenderWorld] = @ecs.register_component(
  debug_name="mgstudio_render::SyncToRenderWorld",
)

///|
pub impl @ecs.Component for SyncToRenderWorld with component() {
  ecs_key_sync_to_render_world
}

///|
pub struct RenderEntity {
  entity : @core.Entity
}

///|
pub fn RenderEntity::new(entity : @core.Entity) -> RenderEntity {
  RenderEntity::{ entity, }
}

///|
pub fn RenderEntity::id(self : RenderEntity) -> @core.Entity {
  self.entity
}

///|
pub let ecs_key_render_entity : @ecs.ComponentKey[RenderEntity] = @ecs.register_component(
  debug_name="mgstudio_render::RenderEntity",
)

///|
pub impl @ecs.Component for RenderEntity with component() {
  ecs_key_render_entity
}

///|
pub struct MainEntity {
  entity : @core.Entity
}

///|
pub fn MainEntity::new(entity : @core.Entity) -> MainEntity {
  MainEntity::{ entity, }
}

///|
pub fn MainEntity::id(self : MainEntity) -> @core.Entity {
  self.entity
}

///|
pub let ecs_key_main_entity : @ecs.ComponentKey[MainEntity] = @ecs.register_component(
  debug_name="mgstudio_render::MainEntity",
)

///|
pub impl @ecs.Component for MainEntity with component() {
  ecs_key_main_entity
}

///|
pub struct TemporaryRenderEntity {}

///|
pub fn TemporaryRenderEntity::default() -> TemporaryRenderEntity {
  TemporaryRenderEntity::{  }
}

///|
pub let ecs_key_temporary_render_entity : @ecs.ComponentKey[
  TemporaryRenderEntity,
] = @ecs.register_component(debug_name="mgstudio_render::TemporaryRenderEntity")

///|
pub impl @ecs.Component for TemporaryRenderEntity with component() {
  ecs_key_temporary_render_entity
}

///|
pub(all) enum EntityRecord {
  Added(@core.Entity)
  Removed(RenderEntity)
  ComponentRemoved(@core.Entity, (@ecs.World, @core.Entity) -> @ecs.World)
}

///|
pub struct PendingSyncEntity {
  records : Ref[Array[EntityRecord]]
}

///|
pub fn PendingSyncEntity::default() -> PendingSyncEntity {
  PendingSyncEntity::{ records: Ref::new([]) }
}

///|
pub fn PendingSyncEntity::push(
  self : PendingSyncEntity,
  record : EntityRecord,
) -> Unit {
  self.records.val.push(record)
}

///|
pub fn PendingSyncEntity::drain(
  self : PendingSyncEntity,
) -> Array[EntityRecord] {
  let out = self.records.val
  self.records.val = []
  out
}

///|
pub let ecs_key_pending_sync_entity : @ecs.ResourceKey[PendingSyncEntity] = @ecs.register_resource(
  debug_name="mgstudio_render::PendingSyncEntity",
)

///|
pub impl @app.Resource for PendingSyncEntity with resource() {
  ecs_key_pending_sync_entity
}

///|
fn ensure_pending_sync_entity_resource(world : @ecs.World) -> Unit {
  if (try! world.get_resource(PendingSyncEntity::resource())) is None {
    world.insert_resource(
      PendingSyncEntity::resource(),
      PendingSyncEntity::default(),
    )
  }
}

///|
fn pending_sync_entity_ref_or_abort(
  world : @ecs.World,
) -> Ref[PendingSyncEntity] {
  ensure_pending_sync_entity_resource(world)
  match (try! world.get_resource_ref_mut(PendingSyncEntity::resource())) {
    Some(pending_ref) => pending_ref
    None => abort("Missing PendingSyncEntity resource in main world")
  }
}

///|
fn track_sync_to_render_world_added(
  event : @ecs.ComponentOn[@ecs.Insert, SyncToRenderWorld],
) -> Unit {
  let world = @ecs.current_observer_world_abort_missing()
  pending_sync_entity_ref_or_abort(world).val.push(
    EntityRecord::Added(event.entity),
  )
}

///|
fn track_sync_to_render_world_removed(
  event : @ecs.ComponentOn[@ecs.Remove, SyncToRenderWorld],
) -> Unit {
  let world = @ecs.current_observer_world_abort_missing()
  match
    (world.get_by_key(event.entity, ecs_key_render_entity) catch { _ => None }) {
    Some(render_entity) =>
      pending_sync_entity_ref_or_abort(world).val.push(
        EntityRecord::Removed(render_entity),
      )
    None => ()
  }
}

///|
fn entity_sync_system(
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> (@ecs.World, @ecs.World) {
  let records = match
    (try! main_world.get_resource_ref_mut(PendingSyncEntity::resource())) {
    Some(pending_ref) => pending_ref.val.drain()
    None => []
  }
  for record in records {
    match record {
      EntityRecord::Added(main_entity) => {
        if !main_world.is_alive(main_entity) {
          continue
        }
        if (main_world.get_by_key(main_entity, ecs_key_render_entity) catch {
            _ => None
          })
          is Some(_) {
          abort(
            "Attempting to synchronize an entity that has already been synchronized!",
          )
        }
        let render_entity = render_world.spawn()
        let mut render_world_inserted = true
        render_world.set_by_key(
          render_entity,
          ecs_key_main_entity,
          MainEntity::new(main_entity),
        ) catch {
          _ => render_world_inserted = false
        }
        if !render_world_inserted {
          render_world.despawn(render_entity) catch {
            _ => ()
          }
          abort(
            "sync_world: failed to attach MainEntity on render world entity",
          )
        }
        let mut main_world_inserted = true
        main_world.set_by_key(
          main_entity,
          ecs_key_render_entity,
          RenderEntity::new(render_entity),
        ) catch {
          _ => main_world_inserted = false
        }
        if !main_world_inserted {
          render_world.despawn(render_entity) catch {
            _ => ()
          }
          abort(
            "sync_world: failed to attach RenderEntity on main world entity",
          )
        }
      }
      EntityRecord::Removed(render_entity) =>
        if render_world.is_alive(render_entity.id()) {
          render_world.despawn(render_entity.id()) catch {
            _ => ()
          }
        }
      EntityRecord::ComponentRemoved(main_entity, removal) => {
        guard (main_world.get_by_key(main_entity, ecs_key_render_entity) catch {
            _ => None
          })
          is Some(render_entity) else {
          continue
        }
        if !render_world.is_alive(render_entity.id()) {
          continue
        }
        ignore(removal(render_world, render_entity.id()))
      }
    }
  }
  (main_world, render_world)
}

///|
pub fn despawn_temporary_render_entities(world : @ecs.World) -> Unit {
  let query : @ecs.QueryState[@core.Entity, @ecs.With[TemporaryRenderEntity]] = world.query_filtered(
    @ecs.With::new(TemporaryRenderEntity::component()),
  )
  let iter = query.iter(world)
  let entities : Array[@core.Entity] = []
  while (iter.fetch_next() catch { _ => None }) is Some((entity, _)) {
    entities.push(entity)
  }
  entities.sort_by(fn(left : @core.Entity, right : @core.Entity) -> Int {
    if left.id < right.id {
      -1
    } else if left.id > right.id {
      1
    } else {
      0
    }
  })
  let mut index = entities.length()
  while index > 0 {
    index = index - 1
    let entity = entities[index]
    if world.is_alive(entity) {
      world.despawn(entity) catch {
        _ => ()
      }
    }
  }
}

///|
pub fn sync_build(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(SyncWorldPlugin::default())
}

///|
pub fn sync_world_plugin_with(
  app : @app.App[@ecs.World],
  plugin : SyncWorldPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let mut next = app
  ensure_pending_sync_entity_resource(next.world())
  next = next
    .add_component_observer(track_sync_to_render_world_added)
    .add_component_observer(track_sync_to_render_world_removed)
  next
}

///|
pub fn sync_world(
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> (@ecs.World, @ecs.World) {
  entity_sync_system(main_world, render_world)
}
