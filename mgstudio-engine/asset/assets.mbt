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
  dirty : Array[Handle[T]]
}

///|
let assets_resource_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
type AssetEventDispatch = (@ecs.World) -> Unit

///|
let asset_event_message_registry : Ref[@hashmap.HashMap[String, @any.Any]] = Ref::new(
  @hashmap.HashMap::new(),
)

///|
let asset_event_dispatch_registry : Ref[
  @hashmap.HashMap[String, AssetEventDispatch],
] = Ref::new(@hashmap.HashMap::new())

///|
fn[T] registered_asset_event_message_key_with_type_name(
  type_name : String,
) -> @ecs.MessageKey[AssetEvent[T]] {
  match asset_event_message_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "asset event message registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.MessageKey[AssetEvent[T]] = @ecs.register_message(
        debug_name="mgstudio_asset::AssetEvent<\{type_name}>",
      )
      asset_event_message_registry.val.set(type_name, @any.of(key))
      key
    }
  }
}

///|
fn[T] register_asset_event_dispatch(
  type_name : String,
  key : @ecs.ResourceKey[Assets[T]],
) -> Unit {
  if asset_event_dispatch_registry.val.contains(type_name) {
    return
  }

  let message_key : @ecs.MessageKey[AssetEvent[T]] = registered_asset_event_message_key_with_type_name(
    type_name,
  )
  let dispatch : AssetEventDispatch = fn(world) {
    if !world.contains_message(message_key) {
      world.init_message(message_key)
    }
    match (try! world.get_resource_mut(key)) {
      Some(assets) => {
        let events = assets.modify(fn(value) { value.drain_events() })
        for event in events {
          ignore(world.send_message(message_key, event))
        }
      }
      None => ()
    }
  }
  asset_event_dispatch_registry.val.set(type_name, dispatch)
}

///|
fn[T] registered_assets_resource_key() -> @ecs.ResourceKey[Assets[T]] {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  let key = match assets_resource_registry.val.get(type_name) {
    Some(existing_key) =>
      match existing_key.try_to() {
        Some(key) => key
        None =>
          abort(
            "asset resource registry contained a mismatched key for \{type_name}",
          )
      }
    None => {
      let key : @ecs.ResourceKey[Assets[T]] = @ecs.register_resource(
        debug_name="mgstudio_asset::Assets<\{type_name}>",
      )
      assets_resource_registry.val.set(type_name, @any.of(key))
      key
    }
  }
  register_asset_event_dispatch(type_name, key)
  key
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
pub impl[T] @ecs.Message for AssetEvent[T] with message() {
  let probe : Assets[T] = Assets::new()
  let type_name = @any.of(probe).type_name()
  registered_asset_event_message_key_with_type_name(type_name)
}

///|
pub fn[T] Assets::new() -> Assets[T] {
  Assets::{ items: [], alive: 0, events: [], dirty: [] }
}

///|
pub fn[T] Assets::len(self : Assets[T]) -> Int {
  self.alive
}

///|
pub fn[T] Assets::add(self : Assets[T], value : T) -> Handle[T] {
  let handle = match image_asset_try_cast(value) {
    Some(image) => {
      let handle = image_asset_allocate_handle(self, image)
      let image_handle : Handle[Image] = Handle::new(handle.id())
      image_asset_sync_metadata(image_handle, image)
      handle
    }
    None => Handle::new(self.items.length())
  }
  ignore(assets_store_insert(self, handle, value, false))
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
fn[T] assets_remove_dirty_handle(
  assets : Assets[T],
  handle : Handle[T],
) -> Unit {
  let next : Array[Handle[T]] = []
  for dirty_handle in assets.dirty {
    if dirty_handle.id() != handle.id() {
      next.push(dirty_handle)
    }
  }
  assets.dirty.clear()
  for dirty_handle in next {
    assets.dirty.push(dirty_handle)
  }
}

///|
fn[T] assets_mark_dirty(assets : Assets[T], handle : Handle[T]) -> Unit {
  for dirty_handle in assets.dirty {
    if dirty_handle.id() == handle.id() {
      return
    }
  }
  assets.dirty.push(handle)
  assets.events.push(AssetEvent::Modified(handle))
}

///|
fn[T] assets_drain_dirty(assets : Assets[T]) -> Array[Handle[T]] {
  let handles : Array[Handle[T]] = []
  for handle in assets.dirty {
    handles.push(handle)
  }
  assets.dirty.clear()
  handles
}

///|
pub fn[T] Assets::get_mut(self : Assets[T], handle : Handle[T]) -> T? {
  guard self.get(handle) is Some(value) else { return None }
  assets_mark_dirty(self, handle)
  Some(value)
}

///|
pub fn[T] Assets::set(self : Assets[T], handle : Handle[T], value : T) -> Bool {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    false
  } else {
    let existed = self.items[id] is Some(_)
    if existed {
      match self.items[id] {
        Some(previous) =>
          match image_asset_sync_on_set(handle, previous, value) {
            Some(ok) => if !ok { return false }
            None => ()
          }
        None => ()
      }
    } else if image_asset_try_cast(value) is Some(image) {
      let image_handle : Handle[Image] = Handle::new(handle.id())
      image_asset_sync_metadata(image_handle, image)
    }
    assets_remove_dirty_handle(self, handle)
    assets_store_insert(self, handle, value, existed)
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
  assets_remove_dirty_handle(self, handle)
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
      assets_remove_dirty_handle(self, handle)
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
