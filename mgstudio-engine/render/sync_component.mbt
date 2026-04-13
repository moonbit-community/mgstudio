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
// Bevy source: `bevy/crates/bevy_render/src/sync_component.rs`.

///|
pub struct SyncComponentPlugin[_, _] {}

///|
pub fn[C, F] SyncComponentPlugin::default() -> SyncComponentPlugin[C, F] {
  SyncComponentPlugin::{  }
}

///|
pub struct SyncComponentHooksState {
  mut removed_component_records : Int
}

///|
pub fn SyncComponentHooksState::default() -> SyncComponentHooksState {
  SyncComponentHooksState::{ removed_component_records: 0 }
}

///|
pub fn SyncComponentHooksState::record_component_removed(
  self : SyncComponentHooksState,
) -> Unit {
  self.removed_component_records = self.removed_component_records + 1
}

///|
pub fn SyncComponentHooksState::removed_component_records(
  self : SyncComponentHooksState,
) -> Int {
  self.removed_component_records
}

///|
pub fn sync_component_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_plugin(app)
}

///|
pub fn sync_component(world : @ecs.World) -> Unit {
  ignore(world)
}
