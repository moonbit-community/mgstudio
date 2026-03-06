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
/// ECS component value constraint.
pub(open) trait Component: ToJson + @json.FromJson {
  component() -> ComponentKey[Self]
}

///|
/// ECS resource value constraint.
pub(open) trait ResourceData: ToJson + @json.FromJson {}

///|
/// ECS event value constraint.
pub(open) trait EventData: ToJson + @json.FromJson {}

///|
pub struct ComponentKey[T] {
  id : Int
  debug_name : String
  marker : T?
}

///|
pub fn[T] ComponentKey::id(self : ComponentKey[T]) -> Int {
  self.id
}

///|
pub fn[T] ComponentKey::debug_name(self : ComponentKey[T]) -> String {
  self.debug_name
}

///|
pub fn[U, T] ComponentKey::cast(self : ComponentKey[T]) -> ComponentKey[U] {
  ComponentKey::{ id: self.id, debug_name: self.debug_name, marker: None }
}

///|
pub struct ResourceKey[T] {
  id : Int
  debug_name : String
  marker : T?
}

///|
pub fn[T] ResourceKey::id(self : ResourceKey[T]) -> Int {
  self.id
}

///|
pub fn[T] ResourceKey::debug_name(self : ResourceKey[T]) -> String {
  self.debug_name
}

///|
pub fn[U, T] ResourceKey::cast(self : ResourceKey[T]) -> ResourceKey[U] {
  ResourceKey::{ id: self.id, debug_name: self.debug_name, marker: None }
}

///|
pub struct EventKey[T] {
  id : Int
  debug_name : String
  marker : T?
}

///|
pub fn[T] EventKey::id(self : EventKey[T]) -> Int {
  self.id
}

///|
pub fn[T] EventKey::debug_name(self : EventKey[T]) -> String {
  self.debug_name
}

///|
pub fn[U, T] EventKey::cast(self : EventKey[T]) -> EventKey[U] {
  EventKey::{ id: self.id, debug_name: self.debug_name, marker: None }
}

///|
let next_component_id_ref : Ref[Int] = Ref::new(1)

///|
let next_resource_id_ref : Ref[Int] = Ref::new(1)

///|
let next_event_id_ref : Ref[Int] = Ref::new(1)

///|
let next_world_id_ref : Ref[Int] = Ref::new(1)

///|
let resource_ids_by_debug_name : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()

///|
pub fn[T] register_component(debug_name? : String = "") -> ComponentKey[T] {
  let id = next_component_id_ref.val
  next_component_id_ref.val = id + 1
  ComponentKey::{ id, debug_name, marker: None }
}

///|
pub fn[T] component_key_from_id(
  id : Int,
  debug_name? : String = "",
) -> ComponentKey[T] {
  ComponentKey::{ id, debug_name, marker: None }
}

///|
pub fn[T] register_resource(debug_name? : String = "") -> ResourceKey[T] {
  if debug_name != "" {
    if resource_ids_by_debug_name.get(debug_name) is Some(id) {
      return ResourceKey::{ id, debug_name, marker: None }
    }
  }
  let id = next_resource_id_ref.val
  next_resource_id_ref.val = id + 1
  if debug_name != "" {
    resource_ids_by_debug_name.set(debug_name, id)
  }
  ResourceKey::{ id, debug_name, marker: None }
}

///|
pub fn[T] resource_key_from_id(
  id : Int,
  debug_name? : String = "",
) -> ResourceKey[T] {
  ResourceKey::{ id, debug_name, marker: None }
}

///|
pub fn[T] register_event(debug_name? : String = "") -> EventKey[T] {
  let id = next_event_id_ref.val
  next_event_id_ref.val = id + 1
  EventKey::{ id, debug_name, marker: None }
}

///|
pub fn[T] event_key_from_id(id : Int, debug_name? : String = "") -> EventKey[T] {
  EventKey::{ id, debug_name, marker: None }
}

///|
pub(all) suberror EcsError {
  EntityStateError(@core.EntityError)
  EntityNotAlive(@core.Entity)
  ComponentDecodeFailed(Int, String, @core.Entity, @json.JsonDecodeError)
  ResourceDecodeFailed(Int, String, @json.JsonDecodeError)
  EventDecodeFailed(Int, String, Int, @json.JsonDecodeError)
}

///|
struct ResourceSlot {
  payload : Json
  added_tick : @core.Tick
  changed_tick : @core.Tick
}

///|
pub struct World {
  world_id : Int
  entities : @core.Entities
  mut change_tick : @core.Tick
  mut system_context : @core.SystemContext
  component_columns : Map[Int, Ref[@core.ComponentStore[Json]]]
  required_components : Map[Int, Ref[RequiredComponentsState]]
  used_components : Map[Int, Bool]
  removed_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  resources : Map[Int, ResourceSlot]
  mut previous_events : Map[Int, Array[Json]]
  current_events : Map[Int, Array[Json]]
}

///|
pub fn World::new() -> World {
  let world_id = next_world_id_ref.val
  next_world_id_ref.val = world_id + 1
  World::{
    world_id,
    entities: @core.Entities::new(),
    change_tick: 0,
    system_context: @core.SystemContext::new(),
    component_columns: {},
    required_components: {},
    used_components: {},
    removed_components: {},
    resources: {},
    previous_events: {},
    current_events: {},
  }
}

///|
pub fn World::world_id(self : World) -> Int {
  self.world_id
}

///|
pub fn World::spawn(self : World) -> @core.Entity {
  self.entities.spawn()
}

///|
pub fn World::spawn_empty(self : World) -> @core.Entity {
  self.spawn()
}

///|
pub fn World::is_alive(self : World, entity : @core.Entity) -> Bool {
  self.entities.is_alive(entity)
}

///|
pub fn World::entity_count(self : World) -> Int {
  self.entities.len()
}

///|
pub fn World::despawn(
  self : World,
  entity : @core.Entity,
) -> Unit raise EcsError {
  self.entities.despawn(entity) catch {
    err => raise EntityStateError(err)
  }
  for entry in self.component_columns.iter() {
    let (key_id, store_ref) = entry
    if store_ref.val.remove(entity) is Some(_) {
      self.ensure_removed_component_messages(key_id).val.send(
        component_write_change_tick(self),
        entity,
      )
    }
  }
}

///|
pub fn[T : ToJson] World::set(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  value : T,
) -> Unit raise EcsError {
  self.insert_component_json_with_requirements(
    entity,
    key.id(),
    value.to_json(),
    component_write_change_tick(self),
  )
}

///|
pub fn[T : @json.FromJson] World::get(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  self.ensure_entity_alive(entity)
  guard self.component_columns.get(key.id()) is Some(store_ref) else {
    return None
  }
  match store_ref.val.get(entity) {
    Some(payload) => Some(self.decode_component_payload(key, entity, payload))
    None => None
  }
}

///|
pub fn[T : ToJson + @json.FromJson] World::update(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  update : (T) -> T,
) -> Bool raise EcsError {
  self.ensure_entity_alive(entity)
  guard self.component_columns.get(key.id()) is Some(store_ref) else {
    return false
  }
  guard store_ref.val.get(entity) is Some(payload) else { return false }
  let old_value : T = self.decode_component_payload(key, entity, payload)
  let new_value = update(old_value)
  store_ref.val.set(
    entity,
    new_value.to_json(),
    component_write_change_tick(self),
  )
  |> ignore
  true
}

///|
pub fn[T] World::remove(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool raise EcsError {
  self.ensure_entity_alive(entity)
  match self.component_columns.get(key.id()) {
    Some(store_ref) =>
      match store_ref.val.remove(entity) {
        Some(_) => {
          self.ensure_removed_component_messages(key.id()).val.send(
            component_write_change_tick(self),
            entity,
          )
          true
        }
        None => false
      }
    None => false
  }
}

///|
fn World::ensure_entity_alive(
  self : World,
  entity : @core.Entity,
) -> Unit raise EcsError {
  if !self.entities.is_alive(entity) {
    raise EntityNotAlive(entity)
  }
}

///|
fn World::ensure_component_store(
  self : World,
  key_id : Int,
) -> Ref[@core.ComponentStore[Json]] {
  self.component_columns.get_or_init(key_id, fn() {
    Ref::new(@core.ComponentStore::new())
  })
}

///|
fn World::component_store(
  self : World,
  key_id : Int,
) -> Ref[@core.ComponentStore[Json]]? {
  self.component_columns.get(key_id)
}

///|
fn World::ensure_removed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  match self.removed_components.get(key_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref::new(@core.Messages::new())
      self.removed_components.set(key_id, messages_ref)
      messages_ref
    }
  }
}

///|
fn World::removed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]]? {
  self.removed_components.get(key_id)
}

///|
fn[T : @json.FromJson] World::decode_component_payload(
  _self : World,
  key : ComponentKey[T],
  entity : @core.Entity,
  payload : Json,
) -> T raise EcsError {
  @json.from_json(payload) catch {
    err => raise ComponentDecodeFailed(key.id(), key.debug_name(), entity, err)
  }
}

///|
pub fn World::read_change_tick(self : World) -> @core.Tick {
  self.change_tick
}

///|
pub fn World::increment_change_tick(self : World) -> @core.Tick {
  self.change_tick = self.change_tick + 1
  self.change_tick
}

///|
pub fn World::get_system_context(self : World) -> @core.SystemContext {
  self.system_context
}

///|
pub fn World::set_system_context(
  self : World,
  ctx : @core.SystemContext,
) -> Unit {
  self.system_context = ctx
}

///|
fn component_write_change_tick(world : World) -> @core.Tick {
  let tick = world.read_change_tick()
  if tick > 0 {
    tick
  } else {
    1
  }
}
