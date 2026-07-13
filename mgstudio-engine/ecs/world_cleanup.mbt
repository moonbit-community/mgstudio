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
priv struct WorldCleanupEntry {
  key : Int
  cleanup : () -> Unit
}

///|
priv struct WorldCleanupRegistry {
  registered : @utils.IntBitSet
  entries : Array[WorldCleanupEntry]
}

///|
fn world_cleanup_registry_new() -> WorldCleanupRegistry {
  { registered: @utils.IntBitSet::new(), entries: [] }
}

///|
fn component_storage_cleanup_key(definition_id : Int) -> Int {
  definition_id * 3
}

///|
fn resource_storage_cleanup_key(definition_id : Int) -> Int {
  definition_id * 3 + 1
}

///|
fn event_storage_cleanup_key(definition_id : Int) -> Int {
  definition_id * 3 + 2
}

///|
fn WorldCleanupRegistry::register_once(
  self : WorldCleanupRegistry,
  key : Int,
  cleanup : () -> Unit,
) -> Unit {
  guard !self.registered.contains(key) else { return }
  self.registered.insert(key)
  self.entries.push({ key, cleanup })
}

///|
fn WorldCleanupRegistry::drain(self : WorldCleanupRegistry) -> Unit {
  let mut index = self.entries.length() - 1
  while index >= 0 {
    let entry = self.entries[index]
    self.registered.remove(entry.key)
    (entry.cleanup)()
    index = index - 1
  }
  self.entries.clear()
  self.registered.clear()
}

///|
fn World::register_cleanup_once(
  self : World,
  key : Int,
  cleanup : () -> Unit,
) -> Unit {
  guard self.lifecycle.is_active() else {
    abort("cannot register cleanup after World closing has started")
  }
  self.cleanup_registry.register_once(key, cleanup)
}

///|
/// Runs `body` with a fresh World and closes it when the body returns or raises.
pub fn[R] with_world(body : (World) -> R raise?) -> R raise? {
  let world = World::new()
  defer world.close()
  body(world)
}
