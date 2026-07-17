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
  dirty : Array[Int]
  marker : T?
}

///|
pub(open) trait Asset {
  fn asset_debug_name() -> String
  fn asset_as_image(Self) -> Image?
  fn asset_resource_keys() -> AssetResourceKeys[Self]
}

///|
fn[T : Asset] assets_type_name(_sample : T?) -> String {
  ignore(_sample)
  "Assets<\{T::asset_debug_name()}>"
}

///|
pub struct AssetResourceKeys[T] {
  assets : @ecs.ResourceKey[Assets[T]]
  event : @ecs.MessageKey[AssetEvent[T]]
  load_failed : @ecs.MessageKey[AssetLoadFailedEvent[T]]
}

///|
pub fn[T] register_asset_resource_keys(
  asset_debug_name : String,
) -> AssetResourceKeys[T] {
  let type_name = "Assets<\{asset_debug_name}>"
  {
    assets: @ecs.register_resource(debug_name="mgstudio_asset::\{type_name}"),
    event: @ecs.register_message(
      debug_name="mgstudio_asset::AssetEvent<\{type_name}>",
    ),
    load_failed: @ecs.register_message(
      debug_name="mgstudio_asset::AssetLoadFailedEvent<\{type_name}>",
    ),
  }
}

///|
type AssetEventDispatch = (@ecs.World) -> Unit

///|
let asset_event_dispatch_registry : @hashmap.HashMap[String, AssetEventDispatch] = @hashmap.HashMap([],
)

///|
fn[T : Asset] registered_asset_event_message_key() -> @ecs.MessageKey[
  AssetEvent[T],
] {
  T::asset_resource_keys().event
}

///|
fn[T : Asset] register_asset_event_dispatch(
  type_name : String,
  key : @ecs.ResourceKey[Assets[T]],
) -> Unit {
  if asset_event_dispatch_registry.contains(type_name) {
    return
  }

  let message_key : @ecs.MessageKey[AssetEvent[T]] = registered_asset_event_message_key()
  let dispatch : AssetEventDispatch = fn(world) {
    if !world.contains_message(message_key) {
      world.init_message(message_key)
    }
    match world.get_resource_mut(key) {
      Some(assets) => {
        let events = assets.modify(fn(value) { value.drain_events() })
        for event in events {
          ignore(world.send_message(message_key, event))
        }
      }
      None => ()
    }
  }
  asset_event_dispatch_registry.set(type_name, dispatch)
}

///|
fn[T : Asset] registered_assets_resource_key() -> @ecs.ResourceKey[Assets[T]] {
  let type_name = assets_type_name((None : T?))
  let key = T::asset_resource_keys().assets
  register_asset_event_dispatch(type_name, key)
  asset_register_load_failed_event_for_asset_type((None : T?))
  key
}

///|
pub fn[T : Asset] assets_resource_key_of(
  _probe : T,
) -> @ecs.ResourceKey[Assets[T]] {
  ignore(_probe)
  registered_assets_resource_key()
}

///|
pub fn[T : Asset] assets_resource_key() -> @ecs.ResourceKey[Assets[T]] {
  registered_assets_resource_key()
}

///|
pub impl[T : Asset] @app.Resource for Assets[T] with fn resource() {
  registered_assets_resource_key()
}

///|
pub impl[T : Asset] @ecs.Message for AssetEvent[T] with fn message() {
  registered_asset_event_message_key()
}

///|
pub fn[T] Assets::new() -> Assets[T] {
  Assets::{ items: [], alive: 0, events: [], dirty: [], marker: None }
}

///|
pub fn[T] Assets::len(self : Assets[T]) -> Int {
  self.alive
}

///|
pub fn[T : Asset] Assets::add(self : Assets[T], value : T) -> Handle[T] {
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
  self.get_by_id(handle.id())
}

///|
fn[T] Assets::get_by_id(self : Assets[T], id : Int) -> T? {
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
  let next : Array[Int] = []
  let id = handle.id()
  for dirty_id in assets.dirty {
    if dirty_id != id {
      next.push(dirty_id)
    }
  }
  assets.dirty.clear()
  for dirty_id in next {
    assets.dirty.push(dirty_id)
  }
}

///|
fn[T] assets_mark_dirty(assets : Assets[T], handle : Handle[T]) -> Unit {
  let id = handle.id()
  for dirty_id in assets.dirty {
    if dirty_id == id {
      return
    }
  }
  assets.dirty.push(id)
  assets.events.push(AssetEvent::Modified(handle))
}

///|
fn[T] assets_drain_dirty(assets : Assets[T]) -> Array[Handle[T]] {
  let handles : Array[Handle[T]] = []
  for id in assets.dirty {
    handles.push(Handle::new(id))
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
pub fn[T] Assets::iter(self : Assets[T]) -> Array[(Handle[T], T)] {
  let entries : Array[(Handle[T], T)] = []
  for i in 0..<self.items.length() {
    match self.items[i] {
      Some(value) => entries.push((Handle::new(i), value))
      None => ()
    }
  }
  entries
}

///|
pub fn[T] Assets::iter_mut(self : Assets[T]) -> Array[(Handle[T], T)] {
  let entries = self.iter()
  for entry in entries {
    let (handle, _) = entry
    assets_mark_dirty(self, handle)
  }
  entries
}

///|
pub fn[T : Asset] Assets::set(
  self : Assets[T],
  handle : Handle[T],
  value : T,
) -> Bool {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    false
  } else {
    match self.items[id] {
      Some(previous) =>
        match image_asset_sync_on_set(handle, previous, value) {
          Some(ok) => if !ok { return false }
          None => ()
        }
      None =>
        if image_asset_try_cast(value) is Some(image) {
          let image_handle : Handle[Image] = Handle::new(handle.id())
          image_asset_sync_metadata(image_handle, image)
        }
    }
    let existed = self.items[id] is Some(_)
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
    match self.items[id] {
      Some(value) => {
        self.items[id] = None
        self.alive = self.alive - 1
        assets_remove_dirty_handle(self, handle)
        self.events.push(AssetEvent::Removed(handle))
        Some(value)
      }
      None => None
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
