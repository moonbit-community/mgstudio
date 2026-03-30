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
pub(open) trait Component {
  component() -> ComponentKey[Self]
}

///|
/// ECS resource value constraint.
pub(open) trait ResourceData {}

///|
/// ECS event value constraint.
pub(open) trait EventData {}

///|
pub struct ComponentKey[_] {
  id : Int
  debug_name : String
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
  ComponentKey::{ id: self.id, debug_name: self.debug_name }
}

///|
pub struct ResourceKey[_] {
  id : Int
  debug_name : String
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
  ResourceKey::{ id: self.id, debug_name: self.debug_name }
}

///|
pub struct EventKey[_] {
  id : Int
  debug_name : String
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
  EventKey::{ id: self.id, debug_name: self.debug_name }
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
  ComponentKey::{ id, debug_name }
}

///|
pub fn[T] component_key_from_id(
  id : Int,
  debug_name? : String = "",
) -> ComponentKey[T] {
  ComponentKey::{ id, debug_name }
}

///|
pub fn[T] register_resource(debug_name? : String = "") -> ResourceKey[T] {
  if debug_name != "" {
    if resource_ids_by_debug_name.get(debug_name) is Some(id) {
      return ResourceKey::{ id, debug_name }
    }
  }
  let id = next_resource_id_ref.val
  next_resource_id_ref.val = id + 1
  if debug_name != "" {
    resource_ids_by_debug_name.set(debug_name, id)
  }
  ResourceKey::{ id, debug_name }
}

///|
pub fn[T] resource_key_from_id(
  id : Int,
  debug_name? : String = "",
) -> ResourceKey[T] {
  ResourceKey::{ id, debug_name }
}

///|
pub fn[T] register_event(debug_name? : String = "") -> EventKey[T] {
  let id = next_event_id_ref.val
  next_event_id_ref.val = id + 1
  EventKey::{ id, debug_name }
}

///|
pub fn[T] event_key_from_id(id : Int, debug_name? : String = "") -> EventKey[T] {
  EventKey::{ id, debug_name }
}

///|
pub(all) suberror EcsError {
  EntityStateError(@core.EntityError)
  EntityNotAlive(@core.Entity)
  NonUniqueEntityList(@core.Entity)
  ComponentTypeMismatch(Int, String, @core.Entity, String)
  ResourceTypeMismatch(Int, String, String)
  EventTypeMismatch(Int, String, Int, String)
  MessageTypeMismatch(Int, String, Int, String)
}

///|
struct ResourceSlot {
  payload : ErasedValue
}

///|
pub struct World {
  world_id : Int
  entities : @core.Entities
  mut sequence : @core.Sequence
  mut system_context : @core.SystemSequenceContext
  component_columns : Map[Int, Ref[@core.ComponentStore[ErasedValue]]]
  required_components : Map[Int, Ref[RequiredComponentsState]]
  used_components : Map[Int, Bool]
  added_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  changed_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  added_component_sequences : Map[Int, Map[Int, @core.Sequence]]
  changed_component_sequences : Map[Int, Map[Int, @core.Sequence]]
  removed_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  resources : Map[Int, ResourceSlot]
  resource_added_sequences : Map[Int, @core.Sequence]
  resource_changed_sequences : Map[Int, @core.Sequence]
  mut previous_events : Map[Int, Array[ErasedValue]]
  current_events : Map[Int, Array[ErasedValue]]
  mut deferred_hook_command_depth : Int
  deferred_hook_commands : Array[DeferredHookCommand]
}

///|
pub fn World::new() -> World {
  let world_id = next_world_id_ref.val
  next_world_id_ref.val = world_id + 1
  let world = World::{
    world_id,
    entities: @core.Entities::new(),
    sequence: 0,
    system_context: @core.SystemSequenceContext::new(),
    component_columns: {},
    required_components: {},
    used_components: {},
    added_components: {},
    changed_components: {},
    added_component_sequences: {},
    changed_component_sequences: {},
    removed_components: {},
    resources: {},
    resource_added_sequences: {},
    resource_changed_sequences: {},
    previous_events: {},
    current_events: {},
    deferred_hook_command_depth: 0,
    deferred_hook_commands: [],
  }
  world.insert_resource(
    ecs_key_default_query_filters,
    default_query_filters_bootstrap_resource(),
  )
  world
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
#callsite(autofill(loc))
pub fn World::despawn(
  self : World,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.ensure_entity_alive(entity)
  let outermost = self.begin_deferred_hook_command_scope()
  let caller = hook_caller_from_loc(loc)
  let removed_components : Array[(Int, ErasedValue)] = []
  for entry in self.component_columns.iter() {
    let (key_id, store_ref) = entry
    if store_ref.val.get(entity) is Some(payload) {
      removed_components.push((key_id, payload))
    }
  }
  for entry in removed_components {
    self.run_component_despawn_hooks(entity, entry.0, caller~)
  }
  for entry in removed_components {
    self.run_component_replace_hooks(entity, entry.0, caller~)
    self.run_component_remove_hooks(entity, entry.0, caller~)
  }
  self.entities.despawn(entity) catch {
    err => raise EntityStateError(err)
  }
  for entry in removed_components {
    let key_id = entry.0
    if self.component_columns.get(key_id) is Some(store_ref) &&
      store_ref.val.remove(entity) is Some(_) {
      self.run_remove_observers(entity, key_id)
      self.ensure_removed_component_messages(key_id).val.send(
        component_write_sequence(self),
        entity,
      )
      self.clear_component_sequence_records(entity, key_id)
    }
  }
  self.end_deferred_hook_command_scope(outermost)
}

///|
#callsite(autofill(loc))
pub fn[T] World::set_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  value : T,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.insert_component_with_requirements(
    entity,
    key.id(),
    erased_value(value),
    caller=hook_caller_from_loc(loc),
  )
}

///|
pub fn[T] World::get_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  self.ensure_entity_alive(entity)
  guard self.component_columns.get(key.id()) is Some(store_ref) else {
    return None
  }
  match store_ref.val.get(entity) {
    Some(payload) => Some(self.component_value(key, entity, payload))
    None => None
  }
}

///|
#callsite(autofill(loc))
pub fn[T] World::update_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  update : (T) -> T,
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.ensure_entity_alive(entity)
  let outermost = self.begin_deferred_hook_command_scope()
  guard self.component_columns.get(key.id()) is Some(store_ref) else {
    self.end_deferred_hook_command_scope(outermost)
    return false
  }
  guard store_ref.val.get(entity) is Some(payload) else {
    self.end_deferred_hook_command_scope(outermost)
    return false
  }
  let old_value : T = self.component_value(key, entity, payload)
  let new_value = update(old_value)
  let new_payload = erased_value(new_value)
  let caller = hook_caller_from_loc(loc)
  self.run_component_replace_hooks(entity, key.id(), caller~)
  store_ref.val.set(entity, new_payload) |> ignore
  self.record_component_changed(entity, key.id())
  self.run_component_insert_hooks(entity, key.id(), caller~)
  self.end_deferred_hook_command_scope(outermost)
  true
}

///|
#callsite(autofill(loc))
pub fn[T] World::remove_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.ensure_entity_alive(entity)
  let outermost = self.begin_deferred_hook_command_scope()
  let caller = hook_caller_from_loc(loc)
  match self.component_columns.get(key.id()) {
    Some(store_ref) =>
      match store_ref.val.get(entity) {
        Some(_) => {
          self.run_component_replace_hooks(entity, key.id(), caller~)
          self.run_component_remove_hooks(entity, key.id(), caller~)
          ignore(store_ref.val.remove(entity))
          self.run_remove_observers(entity, key.id())
          self.ensure_removed_component_messages(key.id()).val.send(
            component_write_sequence(self),
            entity,
          )
          self.clear_component_sequence_records(entity, key.id())
          self.end_deferred_hook_command_scope(outermost)
          true
        }
        None => {
          self.end_deferred_hook_command_scope(outermost)
          false
        }
      }
    None => {
      self.end_deferred_hook_command_scope(outermost)
      false
    }
  }
}

///|
#callsite(autofill(loc))
pub fn[T : Component] World::set(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
  value : T,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.set_by_key(entity, key, value, loc~)
}

///|
pub fn[T : Component] World::get(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
) -> T? raise EcsError {
  self.get_by_key(entity, key)
}

///|
#callsite(autofill(loc))
pub fn[T : Component] World::update(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
  update : (T) -> T,
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.update_by_key(entity, key, update, loc~)
}

///|
#callsite(autofill(loc))
pub fn[T : Component] World::remove(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.remove_by_key(entity, key, loc~)
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
) -> Ref[@core.ComponentStore[ErasedValue]] {
  self.component_columns.get_or_init(key_id, fn() {
    Ref::new(@core.ComponentStore::new())
  })
}

///|
fn World::component_store(
  self : World,
  key_id : Int,
) -> Ref[@core.ComponentStore[ErasedValue]]? {
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
fn World::ensure_added_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  match self.added_components.get(key_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref::new(@core.Messages::new())
      self.added_components.set(key_id, messages_ref)
      messages_ref
    }
  }
}

///|
fn World::ensure_changed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  match self.changed_components.get(key_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref::new(@core.Messages::new())
      self.changed_components.set(key_id, messages_ref)
      messages_ref
    }
  }
}

///|
fn World::ensure_added_component_sequence_map(
  self : World,
  key_id : Int,
) -> Map[Int, @core.Sequence] {
  match self.added_component_sequences.get(key_id) {
    Some(sequence_by_entity) => sequence_by_entity
    None => {
      let sequence_by_entity : Map[Int, @core.Sequence] = {}
      self.added_component_sequences.set(key_id, sequence_by_entity)
      sequence_by_entity
    }
  }
}

///|
fn World::ensure_changed_component_sequence_map(
  self : World,
  key_id : Int,
) -> Map[Int, @core.Sequence] {
  match self.changed_component_sequences.get(key_id) {
    Some(sequence_by_entity) => sequence_by_entity
    None => {
      let sequence_by_entity : Map[Int, @core.Sequence] = {}
      self.changed_component_sequences.set(key_id, sequence_by_entity)
      sequence_by_entity
    }
  }
}

///|
fn World::record_component_added(
  self : World,
  entity : @core.Entity,
  key_id : Int,
) -> Unit {
  self
  .ensure_added_component_sequence_map(key_id)
  .set(entity.id, component_write_sequence(self))
}

///|
fn World::record_component_changed(
  self : World,
  entity : @core.Entity,
  key_id : Int,
) -> Unit {
  self
  .ensure_changed_component_sequence_map(key_id)
  .set(entity.id, component_write_sequence(self))
  self.ensure_changed_component_messages(key_id).val.send(
    component_write_sequence(self),
    entity,
  )
}

///|
fn World::clear_component_sequence_records(
  self : World,
  entity : @core.Entity,
  key_id : Int,
) -> Unit {
  if self.added_component_sequences.get(key_id) is Some(sequence_by_entity) {
    ignore(sequence_by_entity.remove(entity.id))
  }
  if self.changed_component_sequences.get(key_id) is Some(sequence_by_entity) {
    ignore(sequence_by_entity.remove(entity.id))
  }
}

///|
fn World::record_resource_added(self : World, key_id : Int) -> Unit {
  self.resource_added_sequences.set(key_id, resource_write_sequence(self))
}

///|
fn World::record_resource_changed(self : World, key_id : Int) -> Unit {
  self.resource_changed_sequences.set(key_id, resource_write_sequence(self))
}

///|
fn World::resource_added_sequence(
  self : World,
  key_id : Int,
) -> @core.Sequence? {
  self.resource_added_sequences.get(key_id)
}

///|
fn World::resource_changed_sequence(
  self : World,
  key_id : Int,
) -> @core.Sequence? {
  self.resource_changed_sequences.get(key_id)
}

///|
fn World::added_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]]? {
  self.added_components.get(key_id)
}

///|
fn World::added_component_sequence(
  self : World,
  key_id : Int,
  entity_id : Int,
) -> @core.Sequence? {
  match self.added_component_sequences.get(key_id) {
    Some(sequence_by_entity) => sequence_by_entity.get(entity_id)
    None => None
  }
}

///|
fn World::changed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]]? {
  self.changed_components.get(key_id)
}

///|
fn World::changed_component_sequence(
  self : World,
  key_id : Int,
  entity_id : Int,
) -> @core.Sequence? {
  match self.changed_component_sequences.get(key_id) {
    Some(sequence_by_entity) => sequence_by_entity.get(entity_id)
    None => None
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
fn[T] World::component_ref(
  _self : World,
  key : ComponentKey[T],
  entity : @core.Entity,
  payload : ErasedValue,
) -> Ref[T] raise EcsError {
  payload.to_ref() catch {
    _ =>
      raise ComponentTypeMismatch(
        key.id(),
        key.debug_name(),
        entity,
        payload.type_name(),
      )
  }
}

///|
fn[T] World::component_value(
  self : World,
  key : ComponentKey[T],
  entity : @core.Entity,
  payload : ErasedValue,
) -> T raise EcsError {
  self.component_ref(key, entity, payload).val
}

///|
pub fn World::read_sequence(self : World) -> @core.Sequence {
  self.sequence
}

///|
pub fn World::advance_sequence(self : World) -> @core.Sequence {
  self.sequence = self.sequence + 1
  self.sequence
}

///|
pub fn World::get_sequence_context(self : World) -> @core.SystemSequenceContext {
  self.system_context
}

///|
pub fn World::set_sequence_context(
  self : World,
  ctx : @core.SystemSequenceContext,
) -> Unit {
  self.system_context = ctx
}

///|
fn component_write_sequence(world : World) -> @core.Sequence {
  let tick = world.read_sequence()
  if tick > 0 {
    tick
  } else {
    1
  }
}

///|
fn resource_write_sequence(world : World) -> @core.Sequence {
  let tick = world.read_sequence()
  if tick > 0 {
    tick
  } else {
    1
  }
}
