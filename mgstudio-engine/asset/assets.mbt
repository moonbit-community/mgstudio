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
pub struct Assets[T] {
  items : Array[T?]
  mut alive : Int
  events : Array[AssetEvent[T]]
}

///|
let assets_resource_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
fn[T] registered_assets_resource_key() -> @ecs.ResourceKey[Assets[T]] {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  match assets_resource_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "asset resource registry contained a mismatched key for " +
            type_name,
          )
      }
    None => {
      let key : @ecs.ResourceKey[Assets[T]] = @ecs.register_resource(
        debug_name="bevy_asset::Assets<" + type_name + ">",
      )
      assets_resource_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
pub fn[T] assets_resource_key_of(_probe : T) -> @ecs.ResourceKey[Assets[T]] {
  registered_assets_resource_key()
}

///|
pub fn[T] assets_resource_key() -> @ecs.ResourceKey[Assets[T]] {
  registered_assets_resource_key()
}

///|
pub impl[T] @app.Resource for Assets[T] with resource() {
  registered_assets_resource_key()
}

///|
pub fn[T] Assets::new() -> Assets[T] {
  Assets::{ items: [], alive: 0, events: [] }
}

///|
pub fn[T] Assets::len(self : Assets[T]) -> Int {
  self.alive
}

///|
pub fn[T] Assets::add(self : Assets[T], value : T) -> Handle[T] {
  let id = self.items.length()
  self.items.push(Some(value))
  self.alive = self.alive + 1
  let handle = Handle::new(id)
  self.events.push(AssetEvent::Added(handle))
  handle
}

///|
pub fn[T] Assets::reserve_handle(self : Assets[T]) -> Handle[T] {
  let handle = Handle::new(self.items.length())
  self.items.push(None)
  handle
}

///|
pub fn[T] Assets::get(self : Assets[T], handle : Handle[T]) -> T? {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    None
  } else {
    self.items[id]
  }
}

///|
pub fn[T] Assets::set(self : Assets[T], handle : Handle[T], value : T) -> Bool {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    false
  } else {
    let existed = self.items[id] is Some(_)
    self.items[id] = Some(value)
    if existed {
      self.events.push(AssetEvent::Modified(handle))
    } else {
      self.alive = self.alive + 1
      self.events.push(AssetEvent::Added(handle))
    }
    true
  }
}

///|
/// Inserts or updates the asset at the given handle id.
///
/// This grows the internal storage if `handle.id()` exceeds the current length.
pub fn[T] Assets::insert(
  self : Assets[T],
  handle : Handle[T],
  value : T,
) -> Bool {
  let id = handle.id()
  if id < 0 {
    return false
  }
  while self.items.length() <= id {
    self.items.push(None)
  }
  let existed = self.items[id] is Some(_)
  self.items[id] = Some(value)
  if existed {
    self.events.push(AssetEvent::Modified(handle))
  } else {
    self.alive = self.alive + 1
    self.events.push(AssetEvent::Added(handle))
  }
  true
}

///|
pub fn[T] Assets::remove(self : Assets[T], handle : Handle[T]) -> T? {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    None
  } else {
    let value = self.items[id]
    if value is Some(v) {
      self.items[id] = None
      self.alive = self.alive - 1
      self.events.push(AssetEvent::Removed(handle))
      Some(v)
    } else {
      None
    }
  }
}

///|
pub fn[T] Assets::contains(self : Assets[T], handle : Handle[T]) -> Bool {
  self.get(handle) is Some(_)
}

///|
pub fn[T] Assets::is_empty(self : Assets[T]) -> Bool {
  self.alive == 0
}

///|
pub fn[T] Assets::drain_events(self : Assets[T]) -> Array[AssetEvent[T]] {
  let out : Array[AssetEvent[T]] = []
  for ev in self.events {
    out.push(ev)
  }
  self.events.clear()
  out
}

///|
pub fn[T] Assets::push_event(self : Assets[T], event : AssetEvent[T]) -> Unit {
  self.events.push(event)
}
