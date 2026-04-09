// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_asset/src/event.rs`.
pub(all) enum AssetEvent[T] {
  Added(Handle[T])
  Modified(Handle[T])
  Removed(Handle[T])
  LoadedWithDependencies(Handle[T])
}

///|
pub fn asset_update_event_messages(world : @ecs.World) -> Unit {
  for entry in asset_event_bridge_registry.val.iter() {
    let (_type_name, bridge) = entry
    bridge(world)
  }
}
