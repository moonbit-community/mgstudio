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
pub impl @app.PluginReplacement for SyncWorldPlugin with plugin_name(_self) {
  SYNC_WORLD_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for SyncWorldPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    sync_world_plugin_with(app, self)
  }
}

///|
pub struct SyncToRenderWorld {}

///|
pub fn SyncToRenderWorld::default() -> SyncToRenderWorld {
  SyncToRenderWorld::{  }
}

///|
pub struct RenderEntity {
  id : Int
}

///|
pub fn RenderEntity::new(id : Int) -> RenderEntity {
  RenderEntity::{ id, }
}

///|
pub fn RenderEntity::id(self : RenderEntity) -> Int {
  self.id
}

///|
pub struct MainEntity {
  id : Int
}

///|
pub fn MainEntity::new(id : Int) -> MainEntity {
  MainEntity::{ id, }
}

///|
pub fn MainEntity::id(self : MainEntity) -> Int {
  self.id
}

///|
pub(all) enum EntityRecord {
  Added(Int)
  Removed(RenderEntity)
  ComponentRemoved(Int)
}

///|
pub struct PendingSyncEntity {
  records : Array[EntityRecord]
}

///|
pub fn PendingSyncEntity::default() -> PendingSyncEntity {
  PendingSyncEntity::{ records: [] }
}

///|
pub fn PendingSyncEntity::push(
  self : PendingSyncEntity,
  record : EntityRecord,
) -> Unit {
  self.records.push(record)
}

///|
pub fn PendingSyncEntity::drain(
  self : PendingSyncEntity,
) -> Array[EntityRecord] {
  let out = self.records
  self.records.clear()
  out
}

///|
pub fn sync_world_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  sync_world_plugin_with(app, SyncWorldPlugin::default())
}

///|
pub fn sync_world_plugin_with(
  app : @app.App[@ecs.World],
  plugin : SyncWorldPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  render_plugin(app)
}

///|
pub fn sync_world(main_world : @ecs.World, render_world : @ecs.World) -> Unit {
  ignore(main_world)
  ignore(render_world)
}
