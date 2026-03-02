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
pub(open) trait Component: ToJson + @json.FromJson {}

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
  let id = next_resource_id_ref.val
  next_resource_id_ref.val = id + 1
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
pub struct World {
  entities : @core.Entities
  mut change_tick : @core.Tick
  mut system_context : @core.SystemContext
  component_columns : Map[Int, Ref[@core.ComponentStore[Json]]]
  resources : Map[Int, Json]
  mut previous_events : Map[Int, Array[Json]]
  current_events : Map[Int, Array[Json]]
}

///|
pub fn World::new() -> World {
  World::{
    entities: @core.Entities::new(),
    change_tick: 0,
    system_context: @core.SystemContext::new(),
    component_columns: {},
    resources: {},
    previous_events: {},
    current_events: {},
  }
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
pub fn World::despawn(
  self : World,
  entity : @core.Entity,
) -> Unit raise EcsError {
  self.entities.despawn(entity) catch {
    err => raise EntityStateError(err)
  }
  for entry in self.component_columns.iter() {
    let (_key_id, store_ref) = entry
    store_ref.val.remove(entity) |> ignore
  }
}

///|
pub fn[T : ToJson] World::set(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  value : T,
) -> Unit raise EcsError {
  self.ensure_entity_alive(entity)
  let store_ref = self.ensure_component_store(key.id())
  store_ref.val.insert(entity, value.to_json(), self.change_tick)
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
  store_ref.val.set(entity, new_value.to_json(), self.change_tick) |> ignore
  true
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
pub impl @core.SpawnWorld for World with spawn_empty(self) {
  self.spawn_empty()
}

///|
pub impl @core.SpawnWorld for World with despawn(self, entity) {
  self.entities.despawn(entity) catch {
    _ => ()
  }
  for entry in self.component_columns.iter() {
    let (_key_id, store_ref) = entry
    store_ref.val.remove(entity) |> ignore
  }
}

///|
pub impl @core.ChangeTickWorld for World with read_change_tick(self) {
  self.change_tick
}

///|
pub impl @core.ChangeTickWorld for World with increment_change_tick(self) {
  self.change_tick = self.change_tick + 1
  self.change_tick
}

///|
pub impl @core.SystemContextWorld for World with get_system_context(self) {
  self.system_context
}

///|
pub impl @core.SystemContextWorld for World with set_system_context(self, ctx) {
  self.system_context = ctx
}
