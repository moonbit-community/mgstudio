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
pub let ecs_builtin_component_definition_add : Int = 1

///|
pub let ecs_builtin_component_definition_insert : Int = 2

///|
pub let ecs_builtin_component_definition_replace : Int = 3

///|
pub let ecs_builtin_component_definition_remove : Int = 4

///|
pub let ecs_builtin_component_definition_despawn : Int = 5

///|
pub let ecs_builtin_component_definition_is_resource : Int = 6

///|
pub let ecs_builtin_component_definition_count : Int = 6

///|
let next_component_id_ref : Ref[Int] = Ref::new(
  ecs_builtin_component_definition_count + 1,
)

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
  ignore(component_metadata_ref(id, debug_name~))
  let key = ComponentKey::{ id, debug_name }
  register_component_ops(id, key)
  key
}

///|
pub fn[T] component_key_from_id(
  id : Int,
  debug_name? : String = "",
) -> ComponentKey[T] {
  ignore(component_metadata_ref(id, debug_name~))
  let key = ComponentKey::{ id, debug_name }
  register_component_ops(id, key)
  key
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
  StructuralChangeDuringQueryIteration(String)
  ComponentTypeMismatch(Int, String, @core.Entity, String)
  ResourceTypeMismatch(Int, String, String)
  EventTypeMismatch(Int, String, Int, String)
  MessageTypeMismatch(Int, String, Int, String)
}

///|
struct ResourceSlot {
  mut payload : ErasedValue
  mut added_sequence : @core.Sequence?
  mut changed_sequence : @core.Sequence?
  mut changed_caller : String?
}

///|
struct ComponentTickMetadata {
  added_sequence : @core.Sequence?
  changed_sequence : @core.Sequence?
  changed_caller : String?
}

///|
fn component_tick_metadata_empty() -> ComponentTickMetadata {
  { added_sequence: None, changed_sequence: None, changed_caller: None }
}

///|
fn component_tick_metadata_with_added(
  previous : ComponentTickMetadata?,
  sequence : @core.Sequence,
  caller : String?,
) -> ComponentTickMetadata {
  let previous = previous.unwrap_or(component_tick_metadata_empty())
  {
    added_sequence: Some(sequence),
    changed_sequence: previous.changed_sequence,
    changed_caller: caller,
  }
}

///|
fn component_tick_metadata_with_changed(
  previous : ComponentTickMetadata?,
  sequence : @core.Sequence,
  caller : String?,
) -> ComponentTickMetadata {
  let previous = previous.unwrap_or(component_tick_metadata_empty())
  {
    added_sequence: previous.added_sequence,
    changed_sequence: Some(sequence),
    changed_caller: caller,
  }
}

///|
struct PendingComponentPayloadContext {
  entity_id : Int
  payloads : Map[Int, ErasedWriter]
  metadata : Map[Int, ComponentTickMetadata]
}

///|
struct QuerySparseAnchorPayloadContext {
  entity_id : Int
  local_component_id : Int
  payload : ErasedValue
}

///|
struct BundleInfo {
  id : Int
  component_local_ids : Array[Int]
}

///|
pub struct World {
  world_id : Int
  mut structural_generation : Int
  mut entity_lifecycle_generation : Int
  mut component_registration_generation : Int
  component_ids : WorldComponentIds
  components : WorldComponents
  component_relationship_sources : Map[Int, ComponentRelationshipSourceMetadata]
  observer_parent_lookup_component_ids : Array[Int]
  observer_registry : Ref[WorldObserverRegistry]
  mut current_component_observer_context : ComponentObserverContext?
  mut current_trigger_observer_context : TriggerObserverContext?
  entities : @core.Entities
  mut sequence : @core.Sequence
  mut system_context : @core.SystemSequenceContext
  mut pending_component_payload_context : PendingComponentPayloadContext?
  mut current_query_sparse_anchor_payload_context : QuerySparseAnchorPayloadContext?
  mut active_query_iteration_count : Int
  tables : Map[Int, Ref[RawTable]]
  sparse_component_columns : Map[Int, Ref[@core.ComponentStore[ErasedValue]]]
  sparse_component_metadata : Map[
    Int,
    Ref[@core.ComponentStore[ComponentTickMetadata]],
  ]
  component_store_cache_by_definition_id : Map[
    Int,
    Ref[@core.ComponentStore[ErasedValue]],
  ]
  mut next_archetype_id : Int
  mut next_table_id : Int
  mut next_bundle_id : Int
  bundle_ids_by_signature : Map[String, Int]
  bundle_infos : Map[Int, BundleInfo]
  archetype_ids_by_signature : Map[String, Int]
  table_ids_by_signature : Map[String, Int]
  table_component_local_ids : Map[Int, Array[Int]]
  archetype_table_ids : Map[Int, Int]
  archetype_component_local_ids : Map[Int, Array[Int]]
  archetype_component_local_id_indices : Map[Int, Map[Int, Int]]
  archetype_component_local_id_presence : Map[Int, @utils.IntBitSet]
  archetype_component_definition_ids : Map[Int, Array[Int]]
  archetype_component_definition_id_presence : Map[Int, @utils.IntBitSet]
  archetype_ids_by_component_local_id : Map[Int, Array[Int]]
  archetype_add_edges_by_component_local_id : Map[Int, Map[Int, Int]]
  archetype_remove_edges_by_component_local_id : Map[Int, Map[Int, Int]]
  archetype_insert_bundle_edges_by_id : Map[Int, Map[Int, Int]]
  archetype_non_empty_ids_by_component_local_id : Map[Int, Array[Int]]
  mut non_empty_archetype_ids_sorted : Array[Int]
  mut non_empty_archetype_generation : Int
  component_membership_generations : Map[Int, Int]
  component_membership_counts : Map[Int, Int]
  archetype_entities : Map[Int, Array[@core.Entity]]
  entity_archetype_ids : Array[Int]
  entity_table_ids : Array[Int]
  entity_table_rows : Array[Int]
  entity_archetype_rows : Array[Int]
  entity_component_local_ids : Array[Array[Int]]
  required_components : Map[Int, Ref[RequiredComponentsState]]
  used_components : @utils.IntBitSet
  added_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  changed_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  removed_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  component_hooks_registry : Map[Int, ComponentHooks]
  resources : Map[Int, ResourceSlot]
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
    structural_generation: 0,
    entity_lifecycle_generation: 0,
    component_registration_generation: 0,
    component_ids: world_component_ids_new(),
    components: world_components_new(),
    component_relationship_sources: {},
    observer_parent_lookup_component_ids: [],
    observer_registry: Ref::new(world_observer_registry_new()),
    current_component_observer_context: None,
    current_trigger_observer_context: None,
    entities: @core.Entities::new(),
    sequence: 0,
    system_context: @core.SystemSequenceContext::new(),
    pending_component_payload_context: None,
    current_query_sparse_anchor_payload_context: None,
    active_query_iteration_count: 0,
    tables: {},
    sparse_component_columns: {},
    sparse_component_metadata: {},
    component_store_cache_by_definition_id: {},
    next_archetype_id: 1,
    next_table_id: 1,
    next_bundle_id: 1,
    bundle_ids_by_signature: {},
    bundle_infos: {},
    archetype_ids_by_signature: { "": 0 },
    table_ids_by_signature: { "": 0 },
    table_component_local_ids: { 0: [] },
    archetype_table_ids: { 0: 0 },
    archetype_component_local_ids: { 0: [] },
    archetype_component_local_id_indices: { 0: {} },
    archetype_component_local_id_presence: { 0: @utils.IntBitSet::new() },
    archetype_component_definition_ids: { 0: [] },
    archetype_component_definition_id_presence: { 0: @utils.IntBitSet::new() },
    archetype_ids_by_component_local_id: {},
    archetype_add_edges_by_component_local_id: {},
    archetype_remove_edges_by_component_local_id: {},
    archetype_insert_bundle_edges_by_id: {},
    archetype_non_empty_ids_by_component_local_id: {},
    non_empty_archetype_ids_sorted: [],
    non_empty_archetype_generation: 0,
    component_membership_generations: {},
    component_membership_counts: {},
    archetype_entities: { 0: [] },
    entity_archetype_ids: [],
    entity_table_ids: [],
    entity_table_rows: [],
    entity_archetype_rows: [],
    entity_component_local_ids: [],
    required_components: {},
    used_components: @utils.IntBitSet::new(),
    added_components: {},
    changed_components: {},
    removed_components: {},
    component_hooks_registry: {},
    resources: {},
    previous_events: {},
    current_events: {},
    deferred_hook_command_depth: 0,
    deferred_hook_commands: [],
  }
  world.bootstrap_component_registrations()
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
  self.abort_if_query_iteration_would_be_invalidated("spawn entity")
  let entity = self.entities.spawn()
  self.initialize_entity_archetype_tracking(entity)
  self.mark_entity_lifecycle_changed()
  self.mark_structure_changed()
  entity
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
  self.ensure_query_iteration_can_change_structure("despawn entity")
  let outermost = self.begin_deferred_hook_command_scope()
  let caller = hook_caller_from_loc(loc)
  let removed_components : Array[(Int, ErasedValue)] = []
  let component_local_ids = self.entity_local_components(entity).copy()
  for local_id in component_local_ids {
    guard self.definition_component_id(local_id) is Some(key_id) else {
      continue
    }
    if self.component_payload_by_local_id(entity, local_id) is Some(payload) {
      removed_components.push((key_id, payload))
    }
  }
  for entry in removed_components {
    self.run_component_despawn_hooks(entity, entry.0, caller~)
    self.run_despawn_observers(entity, entry.0)
  }
  for entry in removed_components {
    self.run_component_replace_hooks(entity, entry.0, caller~)
    self.run_replace_observers(entity, entry.0)
    self.run_component_remove_hooks(entity, entry.0, caller~)
  }
  self.entities.despawn(entity) catch {
    err => raise EntityStateError(err)
  }
  self.clear_entity_archetype_tracking(entity)
  self.mark_entity_lifecycle_changed()
  self.mark_structure_changed()
  for entry in removed_components {
    let key_id = entry.0
    if self.local_component_id(key_id) is Some(local_id) &&
      self.local_component_storage_type(local_id) == Some(SparseSet) {
      ignore(self.remove_sparse_component_payload_by_local_id(entity, local_id))
    }
    self.run_remove_observers(entity, key_id)
    self.ensure_removed_component_messages(key_id).val.send(
      component_write_sequence(self),
      entity,
    )
    self.clear_component_sequence_records(entity, key_id)
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
    erased_writer(key, value),
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
  self.component_value_by_key(entity, key)
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
  guard self.component_value_by_key(entity, key) is Some(old_value) else {
    self.end_deferred_hook_command_scope(outermost)
    return false
  }
  let new_value = update(old_value)
  let caller = hook_caller_from_loc(loc)
  self.run_component_replace_hooks(entity, key.id(), caller~)
  self.run_replace_observers(entity, key.id())
  ignore(self.replace_component_value_by_key(entity, key, new_value))
  self.record_component_changed_with_caller(entity, key.id(), caller)
  self.run_component_insert_hooks(entity, key.id(), caller~)
  self.run_insert_observers(entity, key.id())
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
  guard self.component_payload(key.id(), entity) is Some(_) else {
    self.end_deferred_hook_command_scope(outermost)
    return false
  }
  self.ensure_query_iteration_can_change_structure("remove component")
  let component_local_id = self.ensure_component_registered(key.id())
  self.run_component_replace_hooks(entity, key.id(), caller~)
  self.run_replace_observers(entity, key.id())
  self.run_component_remove_hooks(entity, key.id(), caller~)
  if self.local_component_storage_type(component_local_id) == Some(SparseSet) {
    ignore(
      self.remove_sparse_component_payload_by_local_id(
        entity, component_local_id,
      ),
    )
  }
  self.entity_remove_component_local_id(entity, component_local_id)
  self.refresh_entity_archetype_after_component_remove(
    entity, component_local_id,
  )
  self.mark_structure_changed()
  self.run_remove_observers(entity, key.id())
  self.ensure_removed_component_messages(key.id()).val.send(
    component_write_sequence(self),
    entity,
  )
  self.clear_component_sequence_records(entity, key.id())
  self.end_deferred_hook_command_scope(outermost)
  true
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
pub fn World::structural_generation(self : World) -> Int {
  self.structural_generation
}

///|
fn World::mark_structure_changed(self : World) -> Unit {
  self.structural_generation = self.structural_generation + 1
}

///|
fn World::begin_query_iteration(self : World) -> Unit {
  self.active_query_iteration_count = self.active_query_iteration_count + 1
}

///|
fn World::end_query_iteration(self : World) -> Unit {
  self.active_query_iteration_count = self.active_query_iteration_count - 1
}

///|
fn World::has_active_query_iteration(self : World) -> Bool {
  self.active_query_iteration_count > 0
}

///|
fn World::ensure_query_iteration_can_change_structure(
  self : World,
  operation : String,
) -> Unit raise EcsError {
  if self.has_active_query_iteration() {
    raise StructuralChangeDuringQueryIteration(operation)
  }
}

///|
fn World::abort_if_query_iteration_would_be_invalidated(
  self : World,
  operation : String,
) -> Unit {
  if self.has_active_query_iteration() {
    abort(
      "Structural ECS change during Query::view is not allowed: \{operation}",
    )
  }
}

///|
fn World::entity_lifecycle_generation(self : World) -> Int {
  self.entity_lifecycle_generation
}

///|
fn World::mark_entity_lifecycle_changed(self : World) -> Unit {
  self.entity_lifecycle_generation = self.entity_lifecycle_generation + 1
}

///|
fn World::ensure_component_store_for_local_id(
  self : World,
  local_id : Int,
  storage_type : ComponentStorageType,
) -> Ref[@core.ComponentStore[ErasedValue]] {
  match storage_type {
    Table =>
      abort(
        "Table component storage is backed by RawTable; sparse component store lookup is invalid for local component id \{local_id.to_string()}",
      )
    SparseSet =>
      self.sparse_component_columns.get_or_init(local_id, fn() {
        Ref::new(@core.ComponentStore::new())
      })
  }
}

///|
fn World::ensure_removed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  let local_id = self.ensure_component_registered(key_id)
  match self.removed_components.get(local_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref::new(@core.Messages::new())
      self.removed_components.set(local_id, messages_ref)
      messages_ref
    }
  }
}

///|
fn World::ensure_added_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  let local_id = self.ensure_component_registered(key_id)
  match self.added_components.get(local_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref::new(@core.Messages::new())
      self.added_components.set(local_id, messages_ref)
      messages_ref
    }
  }
}

///|
fn World::ensure_changed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  let local_id = self.ensure_component_registered(key_id)
  match self.changed_components.get(local_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref::new(@core.Messages::new())
      self.changed_components.set(local_id, messages_ref)
      messages_ref
    }
  }
}

///|
fn World::ensure_sparse_component_metadata_store_for_local_id(
  self : World,
  local_id : Int,
) -> Ref[@core.ComponentStore[ComponentTickMetadata]] {
  guard self.local_component_storage_type(local_id) == Some(SparseSet) else {
    abort(
      "Sparse component metadata store lookup is invalid for local component id \{local_id.to_string()}",
    )
  }
  self.sparse_component_metadata.get_or_init(local_id, fn() {
    Ref::new(@core.ComponentStore::new())
  })
}

///|
fn World::sparse_component_metadata_for_entity(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ComponentTickMetadata? {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return None
  }
  match self.sparse_component_metadata.get(local_component_id) {
    Some(store_ref) => store_ref.val.get(entity)
    None => None
  }
}

///|
fn World::pending_component_tick_metadata(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> ComponentTickMetadata? {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity_id {
        context.metadata.get(local_component_id)
      } else {
        None
      }
    None => None
  }
}

///|
fn World::record_pending_component_added_metadata(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(local_component_id) is Some(_) {
        context.metadata.set(
          local_component_id,
          component_tick_metadata_with_added(
            context.metadata.get(local_component_id),
            sequence,
            caller,
          ),
        )
        true
      } else {
        false
      }
    None => false
  }
}

///|
fn World::record_pending_component_changed_metadata(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(local_component_id) is Some(_) {
        context.metadata.set(
          local_component_id,
          component_tick_metadata_with_changed(
            context.metadata.get(local_component_id),
            sequence,
            caller,
          ),
        )
        true
      } else {
        false
      }
    None => false
  }
}

///|
fn World::record_component_added_with_caller(
  self : World,
  entity : @core.Entity,
  key_id : Int,
  caller : String?,
) -> Unit {
  let sequence = component_write_sequence(self)
  let local_id = self.ensure_component_registered(key_id)
  let recorded = match self.local_component_storage_type(local_id) {
    Some(Table) =>
      self.record_table_component_added_by_local_id(
        entity, local_id, sequence, caller,
      )
    Some(SparseSet) =>
      self.record_sparse_component_added_by_local_id(
        entity, local_id, sequence, caller,
      )
    None => false
  }
  if !recorded {
    ignore(
      self.record_pending_component_added_metadata(
        entity, local_id, sequence, caller,
      ),
    )
  }
}

///|
fn World::record_component_changed_with_caller(
  self : World,
  entity : @core.Entity,
  key_id : Int,
  caller : String?,
) -> Unit {
  self.record_component_changed_sequence_only_with_caller(
    entity, key_id, caller,
  )
  self.ensure_changed_component_messages(key_id).val.send(
    component_write_sequence(self),
    entity,
  )
}

///|
fn World::record_component_changed_sequence_only_with_caller(
  self : World,
  entity : @core.Entity,
  key_id : Int,
  caller : String?,
) -> Unit {
  let sequence = component_write_sequence(self)
  let local_id = self.ensure_component_registered(key_id)
  let recorded = match self.local_component_storage_type(local_id) {
    Some(Table) =>
      self.record_table_component_changed_by_local_id(
        entity, local_id, sequence, caller,
      )
    Some(SparseSet) =>
      self.record_sparse_component_changed_by_local_id(
        entity, local_id, sequence, caller,
      )
    None => false
  }
  if !recorded {
    ignore(
      self.record_pending_component_changed_metadata(
        entity, local_id, sequence, caller,
      ),
    )
  }
}

///|
fn World::clear_component_sequence_records(
  self : World,
  entity : @core.Entity,
  key_id : Int,
) -> Unit {
  guard self.local_component_id(key_id) is Some(local_id) else { return }
  if self.local_component_storage_type(local_id) == Some(SparseSet) {
    self.clear_sparse_component_metadata_by_local_id(entity, local_id)
  }
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id {
        context.metadata.remove(local_id)
      }
    None => ()
  }
}

///|
fn World::record_resource_added(self : World, key_id : Int) -> Unit {
  self.record_resource_added_with_caller(key_id, None)
}

///|
fn World::record_resource_changed(self : World, key_id : Int) -> Unit {
  self.record_resource_changed_with_caller(key_id, None)
}

///|
fn World::record_resource_added_with_caller(
  self : World,
  key_id : Int,
  caller : String?,
) -> Unit {
  guard self.resources.get(key_id) is Some(slot) else { return }
  slot.added_sequence = Some(resource_write_sequence(self))
  slot.changed_caller = caller
}

///|
fn World::record_resource_changed_with_caller(
  self : World,
  key_id : Int,
  caller : String?,
) -> Unit {
  guard self.resources.get(key_id) is Some(slot) else { return }
  slot.changed_sequence = Some(resource_write_sequence(self))
  slot.changed_caller = caller
}

///|
fn World::resource_added_sequence(
  self : World,
  key_id : Int,
) -> @core.Sequence? {
  match self.resources.get(key_id) {
    Some(slot) => slot.added_sequence
    None => None
  }
}

///|
fn World::resource_changed_sequence(
  self : World,
  key_id : Int,
) -> @core.Sequence? {
  match self.resources.get(key_id) {
    Some(slot) => slot.changed_sequence
    None => None
  }
}

///|
fn World::changed_component_caller(
  self : World,
  key_id : Int,
  entity_id : Int,
) -> String? {
  guard self.local_component_id(key_id) is Some(local_id) else { return None }
  if self.table_component_changed_caller_by_local_id(entity_id, local_id)
    is Some(caller) {
    return Some(caller)
  }
  if self.alive_entity_by_id(entity_id) is Some(entity) {
    if self.sparse_component_changed_caller_by_local_id(entity, local_id)
      is Some(caller) {
      return Some(caller)
    }
  }
  match self.pending_component_tick_metadata(entity_id, local_id) {
    Some(metadata) => metadata.changed_caller
    None => None
  }
}

///|
fn World::resource_changed_caller(self : World, key_id : Int) -> String? {
  match self.resources.get(key_id) {
    Some(slot) => slot.changed_caller
    None => None
  }
}

///|
fn World::added_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]]? {
  match self.local_component_id(key_id) {
    Some(local_id) => self.added_components.get(local_id)
    None => None
  }
}

///|
fn World::added_component_sequence(
  self : World,
  key_id : Int,
  entity_id : Int,
) -> @core.Sequence? {
  guard self.local_component_id(key_id) is Some(local_id) else { return None }
  if self.table_component_added_sequence_by_local_id(entity_id, local_id)
    is Some(sequence) {
    return Some(sequence)
  }
  if self.alive_entity_by_id(entity_id) is Some(entity) {
    if self.sparse_component_added_sequence_by_local_id(entity, local_id)
      is Some(sequence) {
      return Some(sequence)
    }
  }
  match self.pending_component_tick_metadata(entity_id, local_id) {
    Some(metadata) => metadata.added_sequence
    None => None
  }
}

///|
fn World::changed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]]? {
  match self.local_component_id(key_id) {
    Some(local_id) => self.changed_components.get(local_id)
    None => None
  }
}

///|
fn World::changed_component_sequence(
  self : World,
  key_id : Int,
  entity_id : Int,
) -> @core.Sequence? {
  guard self.local_component_id(key_id) is Some(local_id) else { return None }
  if self.table_component_changed_sequence_by_local_id(entity_id, local_id)
    is Some(sequence) {
    return Some(sequence)
  }
  if self.alive_entity_by_id(entity_id) is Some(entity) {
    if self.sparse_component_changed_sequence_by_local_id(entity, local_id)
      is Some(sequence) {
      return Some(sequence)
    }
  }
  match self.pending_component_tick_metadata(entity_id, local_id) {
    Some(metadata) => metadata.changed_sequence
    None => None
  }
}

///|
fn World::removed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]]? {
  match self.local_component_id(key_id) {
    Some(local_id) => self.removed_components.get(local_id)
    None => None
  }
}

///|
fn[T] World::component_value(
  _self : World,
  key : ComponentKey[T],
  entity : @core.Entity,
  payload : ErasedValue,
) -> T raise EcsError {
  payload.to_value() catch {
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
