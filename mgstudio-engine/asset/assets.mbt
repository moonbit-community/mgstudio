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
  items : Array[@ecs.EcsPayload?]
  mut alive : Int
  events : Array[AssetEventPayload]
  dirty : Array[Int]
  marker : T?
}

///|
pub(open) trait Asset: @ecs.EcsPayloadCodec {
  asset_debug_name() -> String
  asset_as_image(Self) -> Image?
}

///|
fn[T : Asset] assets_type_name(_sample : T?) -> String {
  ignore(_sample)
  "Assets<\{T::asset_debug_name()}>"
}

///|
let assets_resource_registry : Ref[@hashmap.HashMap[String, Int]] = Ref(
  @hashmap.HashMap([]),
)

///|
type AssetEventDispatch = (@ecs.World) -> Unit

///|
let asset_event_message_registry : Ref[@hashmap.HashMap[String, Int]] = Ref(
  @hashmap.HashMap([]),
)

///|
let asset_event_dispatch_registry : Ref[
  @hashmap.HashMap[String, AssetEventDispatch],
] = Ref(@hashmap.HashMap([]))

///|
fn[T] registered_asset_event_message_key_with_type_name(
  type_name : String,
) -> @ecs.MessageKey[AssetEvent[T]] {
  match asset_event_message_registry.val.get(type_name) {
    Some(id) =>
      @ecs.message_key_from_id(
        id,
        debug_name="mgstudio_asset::AssetEvent<\{type_name}>",
      )
    None => {
      let key : @ecs.MessageKey[AssetEvent[T]] = @ecs.register_message(
        debug_name="mgstudio_asset::AssetEvent<\{type_name}>",
      )
      asset_event_message_registry.val.set(type_name, key.id())
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
fn[T : Asset] registered_assets_resource_key() -> @ecs.ResourceKey[Assets[T]] {
  let type_name = assets_type_name((None : T?))
  let key = match assets_resource_registry.val.get(type_name) {
    Some(id) =>
      @ecs.resource_key_from_id(id, debug_name="mgstudio_asset::\{type_name}")
    None => {
      let key : @ecs.ResourceKey[Assets[T]] = @ecs.register_resource(
        debug_name="mgstudio_asset::\{type_name}",
      )
      assets_resource_registry.val.set(type_name, key.id())
      key
    }
  }
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
pub impl[T : Asset] @app.Resource for Assets[T] with resource() {
  registered_assets_resource_key()
}

///|
pub impl[T : Asset] @ecs.Message for AssetEvent[T] with message() {
  let type_name = assets_type_name((None : T?))
  registered_asset_event_message_key_with_type_name(type_name)
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
pub fn[T : @ecs.EcsPayloadCodec] Assets::get(
  self : Assets[T],
  handle : Handle[T],
) -> T? {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    None
  } else {
    match self.items[id] {
      Some(payload) => T::from_ecs_payload(payload)
      None => None
    }
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
  assets.events.push(asset_event_to_payload(AssetEvent::Modified(handle)))
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
pub fn[T : @ecs.EcsPayloadCodec] Assets::get_mut(
  self : Assets[T],
  handle : Handle[T],
) -> T? {
  guard self.get(handle) is Some(value) else { return None }
  assets_mark_dirty(self, handle)
  Some(value)
}

///|
pub fn[T : @ecs.EcsPayloadCodec] Assets::iter(
  self : Assets[T],
) -> Array[(Handle[T], T)] {
  let entries : Array[(Handle[T], T)] = []
  for i in 0..<self.items.length() {
    match self.items[i] {
      Some(payload) =>
        match T::from_ecs_payload(payload) {
          Some(value) => entries.push((Handle::new(i), value))
          None => ()
        }
      None => ()
    }
  }
  entries
}

///|
pub fn[T : @ecs.EcsPayloadCodec] Assets::iter_mut(
  self : Assets[T],
) -> Array[(Handle[T], T)] {
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
    let existed = self.items[id] is Some(_)
    if existed {
      match self.items[id] {
        Some(previous_payload) =>
          match T::from_ecs_payload(previous_payload) {
            Some(previous) =>
              match image_asset_sync_on_set(handle, previous, value) {
                Some(ok) => if !ok { return false }
                None => ()
              }
            None => return false
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
pub fn[T : @ecs.EcsPayloadCodec] Assets::insert(
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
  self.items[id] = Some(T::to_ecs_payload(value))
  assets_remove_dirty_handle(self, handle)
  if existed {
    self.events.push(asset_event_to_payload(AssetEvent::Modified(handle)))
  } else {
    self.alive = self.alive + 1
    self.events.push(asset_event_to_payload(AssetEvent::Added(handle)))
  }
  true
}

///|
pub fn[T : @ecs.EcsPayloadCodec] Assets::remove(
  self : Assets[T],
  handle : Handle[T],
) -> T? {
  let id = handle.id()
  if id < 0 || id >= self.items.length() {
    None
  } else {
    match self.items[id] {
      Some(payload) =>
        match T::from_ecs_payload(payload) {
          Some(value) => {
            self.items[id] = None
            self.alive = self.alive - 1
            assets_remove_dirty_handle(self, handle)
            self.events.push(
              asset_event_to_payload(AssetEvent::Removed(handle)),
            )
            Some(value)
          }
          None => None
        }
      None => None
    }
  }
}

///|
pub fn[T : @ecs.EcsPayloadCodec] Assets::contains(
  self : Assets[T],
  handle : Handle[T],
) -> Bool {
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
    match asset_event_from_payload(ev) {
      Some(event) => out.push(event)
      None => ()
    }
  }
  self.events.clear()
  out
}

///|
pub fn[T] Assets::push_event(self : Assets[T], event : AssetEvent[T]) -> Unit {
  self.events.push(asset_event_to_payload(event))
}
