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
  fn component() -> ComponentKey[Self]
}

///|
/// ECS resource value constraint.
pub(open) trait ResourceData {}

///|
/// ECS event value constraint.
pub(open) trait EventData {}

///|
pub struct ComponentKey[T] {
  priv id : Int
  priv debug_name : String
  priv access : ComponentAccess[T]
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
pub struct ResourceKey[T] {
  priv id : Int
  priv debug_name : String
  priv access : ResourceAccessOps[T]
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
pub struct EventKey[T] {
  priv id : Int
  priv debug_name : String
  priv access : EventAccessOps[T]
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
priv struct EcsIdAllocatorState {
  mut next_component_id : Int
  mut next_resource_id : Int
  mut next_event_id : Int
  mut next_world_id : Int
}

///|
let ecs_id_allocator_state : EcsIdAllocatorState = {
  next_component_id: ecs_builtin_component_definition_count + 1,
  next_resource_id: 1,
  next_event_id: 1,
  next_world_id: 1,
}

///|
pub fn[T] register_component(
  debug_name? : String = "",
  finalizer? : (T) -> Unit,
) -> ComponentKey[T] {
  let id = ecs_id_allocator_state.next_component_id
  ecs_id_allocator_state.next_component_id = id + 1
  ignore(component_metadata_ensure(id, debug_name~))
  let (finalize_value, has_custom_finalizer) = match finalizer {
    Some(finalize_value) => (finalize_value, true)
    None => (fn(_value : T) { () }, false)
  }
  let key = ComponentKey::{
    id,
    debug_name,
    access: component_access_new(id, finalize_value, has_custom_finalizer),
  }
  key
}

///|
fn allocate_resource_id(debug_name? : String = "") -> Int {
  ignore(debug_name)
  let id = ecs_id_allocator_state.next_resource_id
  ecs_id_allocator_state.next_resource_id = id + 1
  id
}

///|
pub fn[T] register_resource(
  debug_name? : String = "",
  finalizer? : (T) -> Unit = fn(_value : T) { () },
) -> ResourceKey[T] {
  let id = allocate_resource_id(debug_name~)
  ResourceKey::{
    id,
    debug_name,
    access: resource_access_ops_new(id, finalizer~),
  }
}

///|
pub fn[T] register_event(debug_name? : String = "") -> EventKey[T] {
  let id = ecs_id_allocator_state.next_event_id
  ecs_id_allocator_state.next_event_id = id + 1
  let key = EventKey::{ id, debug_name, access: event_access_ops_new(id) }
  register_event_ops(id, key)
  key
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
  WorldClosed(Int)
  TableBatchUnavailable(String)
  ForeignEntityReservation(@core.Entity, Int, Int)
  StaleEntityReservation(@core.Entity)
}

///|
struct BundleInfo {
  id : Int
  component_local_ids : Array[Int]
  component_local_id_presence : @utils.IntBitSet
}

///|
priv struct ArchetypeSignatureTrieNode {
  children : Map[Int, Int]
  mut value : Int?
}

///|
priv struct ArchetypeSignatureIndex {
  nodes : Array[ArchetypeSignatureTrieNode]
}

///|
pub struct World {
  priv lifecycle : WorldLifecycle
  priv cleanup_registry : WorldCleanupRegistry
  priv track_change_locations : Bool
  priv mut structural_generation : Int
  priv mut entity_lifecycle_generation : Int
  priv mut component_registration_generation : Int
  priv component_ids : WorldComponentIds
  priv components : WorldComponents
  priv component_relationship_sources : Map[
    Int,
    ComponentRelationshipSourceMetadata,
  ]
  priv observer_parent_lookup_component_ids : Array[Int]
  priv observer_registry : WorldObserverRegistry
  priv mut current_component_observer_context : ComponentObserverContext?
  priv mut current_trigger_observer_context : TriggerObserverContext?
  priv entities : @core.Entities
  priv allocator_connection : AllocatorConnection
  priv mut change_tick : @core.Tick
  priv mut last_change_tick_check : @core.Tick
  priv mut system_tick_context : @core.SystemTickContext
  priv component_write_transactions : ComponentWriteTransactionState
  priv query_iterations : WorldQueryIterationState
  priv tables : Array[RawTable?]
  priv sparse_component_metadata : Map[
    Int,
    @core.ComponentStore[ComponentTickMetadata],
  ]
  priv mut next_archetype_id : Int
  priv mut next_table_id : Int
  priv mut next_bundle_id : Int
  priv mut next_component_column_table_plan_id : Int
  priv bundle_ids_by_signature : ArchetypeSignatureIndex
  priv bundle_infos : Map[Int, BundleInfo]
  priv component_column_table_plan_ids_by_signature : ArchetypeSignatureIndex
  priv component_column_table_plans : Map[Int, ComponentColumnTablePlan]
  priv archetype_ids_by_signature : ArchetypeSignatureIndex
  priv table_ids_by_signature : ArchetypeSignatureIndex
  priv table_component_local_ids : Map[Int, Array[Int]]
  priv archetype_table_ids : Map[Int, Int]
  priv archetype_component_local_ids : Map[Int, Array[Int]]
  priv archetype_component_local_id_indices : Map[Int, Map[Int, Int]]
  priv archetype_component_local_id_presence : Map[Int, @utils.IntBitSet]
  priv archetype_component_definition_ids : Map[Int, Array[Int]]
  priv archetype_component_definition_id_presence : Map[Int, @utils.IntBitSet]
  priv archetype_ids_by_component_local_id : Map[Int, Array[Int]]
  priv archetype_add_edges_by_component_local_id : Map[Int, Map[Int, Int]]
  priv archetype_remove_edges_by_component_local_id : Map[Int, Map[Int, Int]]
  priv archetype_insert_bundle_edges_by_id : Map[Int, Map[Int, Int]]
  priv archetype_non_empty_ids_by_component_local_id : Map[Int, Array[Int]]
  priv mut non_empty_archetype_ids_sorted : Array[Int]
  priv mut non_empty_archetype_generation : Int
  priv component_membership_generations : Map[Int, Int]
  priv component_membership_counts : Map[Int, Int]
  priv entity_storage : WorldEntityStorageState
  priv required_components : Map[Int, RequiredComponentsState]
  priv used_components : @utils.IntBitSet
  priv added_components : Map[Int, @core.Messages[@core.Entity]]
  priv removed_components : Map[Int, @core.Messages[@core.Entity]]
  priv component_hooks_registry : Map[Int, ComponentHooks]
  priv resource_tick_registry : WorldResourceTickRegistry
  priv mut pre_close_hooks : Array[(World) -> Unit]
  priv mut shutdown_hooks : Array[(World) -> Unit]
  priv mut deferred_hook_command_depth : Int
  priv deferred_hook_commands : Array[DeferredHookCommand]
}

///|
/// Creates a World with an explicit lifecycle.
///
/// The owner must call `World::close`. Prefer `with_world` for lexical scopes.
pub fn World::new(track_change_locations? : Bool = false) -> World {
  let world_id = ecs_id_allocator_state.next_world_id
  ecs_id_allocator_state.next_world_id = world_id + 1
  let world = World::{
    lifecycle: WorldLifecycle::new(world_id),
    cleanup_registry: world_cleanup_registry_new(),
    track_change_locations,
    structural_generation: 0,
    entity_lifecycle_generation: 0,
    component_registration_generation: 0,
    component_ids: world_component_ids_new(),
    components: world_components_new(),
    component_relationship_sources: Map([]),
    observer_parent_lookup_component_ids: [],
    observer_registry: world_observer_registry_new(),
    current_component_observer_context: None,
    current_trigger_observer_context: None,
    entities: @core.Entities::new(),
    allocator_connection: AllocatorConnection::new(world_id, 0),
    change_tick: 0,
    last_change_tick_check: 0,
    system_tick_context: @core.SystemTickContext::new(),
    component_write_transactions: component_write_transaction_state_new(),
    query_iterations: world_query_iteration_state_new(),
    tables: [],
    sparse_component_metadata: Map([]),
    next_archetype_id: 1,
    next_table_id: 1,
    next_bundle_id: 1,
    next_component_column_table_plan_id: 1,
    bundle_ids_by_signature: archetype_signature_index_new(),
    bundle_infos: Map([]),
    component_column_table_plan_ids_by_signature: archetype_signature_index_new(),
    component_column_table_plans: Map([]),
    archetype_ids_by_signature: archetype_signature_index_new(),
    table_ids_by_signature: archetype_signature_index_new(),
    table_component_local_ids: { 0: [] },
    archetype_table_ids: { 0: 0 },
    archetype_component_local_ids: { 0: [] },
    archetype_component_local_id_indices: { 0: Map([]) },
    archetype_component_local_id_presence: { 0: @utils.IntBitSet::new() },
    archetype_component_definition_ids: { 0: [] },
    archetype_component_definition_id_presence: { 0: @utils.IntBitSet::new() },
    archetype_ids_by_component_local_id: Map([]),
    archetype_add_edges_by_component_local_id: Map([]),
    archetype_remove_edges_by_component_local_id: Map([]),
    archetype_insert_bundle_edges_by_id: Map([]),
    archetype_non_empty_ids_by_component_local_id: Map([]),
    non_empty_archetype_ids_sorted: [],
    non_empty_archetype_generation: 0,
    component_membership_generations: Map([]),
    component_membership_counts: Map([]),
    entity_storage: world_entity_storage_state_new(),
    required_components: Map([]),
    used_components: @utils.IntBitSet::new(),
    added_components: Map([]),
    removed_components: Map([]),
    component_hooks_registry: Map([]),
    resource_tick_registry: world_resource_tick_registry_new(),
    pre_close_hooks: [],
    shutdown_hooks: [],
    deferred_hook_command_depth: 0,
    deferred_hook_commands: [],
  }
  world.archetype_ids_by_signature.insert([], 0)
  world.table_ids_by_signature.insert([], 0)
  world.bootstrap_component_registrations()
  world.insert_resource(
    ecs_key_default_query_filters,
    default_query_filters_bootstrap_resource(),
  )
  world
}

///|
/// Returns whether this world records component and resource change locations.
///
/// This is disabled by default, matching Bevy without its non-default
/// `track_location` feature. Enable it at construction time with
/// `World::new(track_change_locations=true)` when change-location diagnostics
/// are required.
pub fn World::tracks_change_locations(self : World) -> Bool {
  self.track_change_locations
}

///|
pub fn World::world_id(self : World) -> Int {
  self.lifecycle.world_id
}

///|
pub fn World::lifecycle_epoch(self : World) -> Int {
  self.lifecycle.epoch
}

///|
pub fn World::is_closed(self : World) -> Bool {
  self.lifecycle.is_closed()
}

///|
pub fn World::is_active(self : World) -> Bool {
  self.lifecycle.is_active()
}

///|
pub fn World::close(self : World) -> Unit {
  self.abort_if_query_iteration_would_be_invalidated("close world")
  guard self.lifecycle.begin_close() else { return }
  self.allocator_connection.close()
  let pre_close_hooks = self.pre_close_hooks
  self.pre_close_hooks = []
  let mut pre_close_index = pre_close_hooks.length() - 1
  while pre_close_index >= 0 {
    pre_close_hooks[pre_close_index](self)
    pre_close_index = pre_close_index - 1
  }
  self.cleanup_registry.drain()
  let shutdown_hooks = self.shutdown_hooks
  self.shutdown_hooks = []
  let mut hook_index = shutdown_hooks.length() - 1
  while hook_index >= 0 {
    shutdown_hooks[hook_index](self)
    hook_index = hook_index - 1
  }
  self.lifecycle.finish_close()
}

///|
/// Adds a hook that runs before World-owned values are finalized.
pub fn World::add_pre_close_hook(self : World, hook : (World) -> Unit) -> Unit {
  guard self.lifecycle.is_active() else {
    abort("cannot add a pre-close hook after World closing has started")
  }
  self.pre_close_hooks.push(hook)
}

///|
pub fn World::add_shutdown_hook(self : World, hook : (World) -> Unit) -> Unit {
  guard self.lifecycle.is_active() else {
    abort("cannot add a shutdown hook after World closing has started")
  }
  self.shutdown_hooks.push(hook)
}

///|
pub fn World::spawn(self : World) -> @core.Entity {
  let reservation = try! self.reserve_entity()
  try! self.spawn_reserved(reservation)
}

///|
pub fn World::reserve_entity(self : World) -> EntityReservation raise EcsError {
  self.allocator_connection.reserve_entity()
}

///|
pub fn World::spawn_reserved(
  self : World,
  reservation : EntityReservation,
) -> @core.Entity raise EcsError {
  let entity = self.allocator_connection.claim(reservation)
  self.spawn_empty_at(entity) catch {
    error => {
      self.allocator_connection.free_spawned(entity)
      raise error
    }
  }
}

///|
pub fn World::spawn_empty_at(
  self : World,
  entity : @core.Entity,
) -> @core.Entity raise EcsError {
  self.ensure_active()
  self.abort_if_query_iteration_would_be_invalidated("spawn entity")
  self.entities.spawn_at(entity) catch {
    err => raise EntityStateError(err)
  }
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
pub fn World::pending_entity_reservation_count(self : World) -> Int {
  self.allocator_connection.pending_count()
}

///|
pub fn World::allocator_connection(self : World) -> AllocatorConnection {
  self.allocator_connection
}

///|
fn World::free_spawned_entity(self : World, entity : @core.Entity) -> Unit {
  self.allocator_connection.free_spawned(entity)
}

///|
pub fn World::is_alive(self : World, entity : @core.Entity) -> Bool {
  self.entities.is_alive(entity)
}

///|
pub fn World::entity_count(self : World) -> Int {
  self.entities.count_spawned()
}

///|
pub fn World::alive_entities(self : World) -> Array[@core.Entity] {
  self.entities.alive_entities()
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
  let caller = hook_caller_from_loc(self, loc)
  let transaction = self.component_remove_transaction_for_despawn(
    entity, caller,
  )
  try! self.commit_component_despawn_transaction(transaction)
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
    component_writer_for_key(key, value),
    caller=hook_caller_from_loc(self, loc),
  )
}

///|
/// Returns the component value for read-only use.
///
/// MoonBit cannot enforce that the returned value is not mutated through an
/// alias. Code that wants ECS change detection or replacement hooks must use
/// `World::get_mut`, `World::update_by_key`,
/// `Write::modify` or `Write::set` instead of mutating the value
/// returned here.
pub fn[T] World::get_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  self.ensure_entity_alive(entity)
  self.component_value_by_key(entity, key)
}

///|
/// Replaces an existing component through the ECS mutation path.
///
/// The update closure receives the current value and must return the value to
/// store. This records component change metadata and runs the same replace and
/// insert observer/hook path as a component replacement.
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
  let caller = hook_caller_from_loc(self, loc)
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
  let caller = hook_caller_from_loc(self, loc)
  guard self.component_remove_transaction_for_key(entity, key.id(), caller)
    is Some(transaction) else {
    self.end_deferred_hook_command_scope(outermost)
    return false
  }
  self.ensure_query_iteration_can_change_structure("remove component")
  self.commit_component_remove_transaction(transaction)
  self.end_deferred_hook_command_scope(outermost)
  true
}

///|
/// Sets or replaces a component through the ECS mutation path.
///
/// This is the correct entry point when inserting a fresh value or replacing an
/// existing value directly. It updates archetype/table storage and records the
/// relevant ECS metadata.
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
/// Returns the component value for read-only use.
///
/// This convenience method has the same read-only contract as
/// `World::get_by_key`: do not mutate the returned value directly when ECS
/// change detection should observe the write.
pub fn[T : Component] World::get(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
) -> T? raise EcsError {
  self.get_by_key(entity, key)
}

///|
/// Replaces an existing component through the ECS mutation path.
///
/// This convenience method has the same write contract as
/// `World::update_by_key`: use it when the write should update component
/// change metadata.
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
  self.ensure_active()
  if !self.entities.is_alive(entity) {
    raise EntityNotAlive(entity)
  }
}

///|
fn World::ensure_active(self : World) -> Unit raise EcsError {
  guard self.lifecycle.is_active() else { raise WorldClosed(self.world_id()) }
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
fn World::entity_lifecycle_generation(self : World) -> Int {
  self.entity_lifecycle_generation
}

///|
fn World::mark_entity_lifecycle_changed(self : World) -> Unit {
  self.entity_lifecycle_generation = self.entity_lifecycle_generation + 1
}

///|
fn World::ensure_removed_component_messages(
  self : World,
  key_id : Int,
) -> @core.Messages[@core.Entity] {
  let local_id = self.ensure_component_registered(key_id)
  match self.removed_components.get(local_id) {
    Some(messages) => messages
    None => {
      let messages = @core.Messages::new()
      self.removed_components.set(local_id, messages)
      messages
    }
  }
}

///|
fn World::ensure_added_component_messages(
  self : World,
  key_id : Int,
) -> @core.Messages[@core.Entity] {
  let local_id = self.ensure_component_registered(key_id)
  match self.added_components.get(local_id) {
    Some(messages) => messages
    None => {
      let messages = @core.Messages::new()
      self.added_components.set(local_id, messages)
      messages
    }
  }
}

///|
fn World::ensure_sparse_component_metadata_store_for_local_id(
  self : World,
  local_id : Int,
) -> @core.ComponentStore[ComponentTickMetadata] {
  guard self.local_component_storage_type(local_id) == Some(SparseSet) else {
    abort(
      "Sparse component metadata store lookup is invalid for local component id \{local_id.to_string()}",
    )
  }
  self.sparse_component_metadata.get_or_init(local_id, fn() {
    @core.ComponentStore::new()
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
    Some(store) => store.get(entity)
    None => None
  }
}

///|
fn World::record_component_added_with_caller(
  self : World,
  entity : @core.Entity,
  key_id : Int,
  caller : String?,
) -> Unit {
  let caller = self.tracked_change_caller(caller)
  let tick = component_write_tick(self)
  let local_id = self.ensure_component_registered(key_id)
  let recorded = match self.local_component_storage_type(local_id) {
    Some(Table) =>
      self.record_table_component_added_by_local_id(
        entity, local_id, tick, caller,
      )
    Some(SparseSet) =>
      self.record_sparse_component_added_by_local_id(
        entity, local_id, tick, caller,
      )
    None => false
  }
  if !recorded {
    ignore(
      self.record_component_write_transaction_added_metadata(
        entity, local_id, tick, caller,
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
  let caller = self.tracked_change_caller(caller)
  let tick = component_write_tick(self)
  let local_id = self.ensure_component_registered(key_id)
  self.record_component_changed_by_local_id_with_tick(
    entity, local_id, tick, caller,
  )
}

///|
fn World::record_component_changed_by_local_id_with_tick(
  self : World,
  entity : @core.Entity,
  local_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Unit {
  let recorded = match self.local_component_storage_type(local_id) {
    Some(Table) =>
      self.record_table_component_changed_by_local_id(
        entity, local_id, tick, caller,
      )
    Some(SparseSet) =>
      self.record_sparse_component_changed_by_local_id(
        entity, local_id, tick, caller,
      )
    None => false
  }
  if !recorded {
    ignore(
      self.record_component_write_transaction_changed_metadata(
        entity, local_id, tick, caller,
      ),
    )
  }
}

///|
fn World::clear_component_tick_records(
  self : World,
  entity : @core.Entity,
  key_id : Int,
) -> Unit {
  guard self.local_component_id(key_id) is Some(local_id) else { return }
  if self.local_component_storage_type(local_id) == Some(SparseSet) {
    self.clear_sparse_component_metadata_by_local_id(entity, local_id)
  }
  self.clear_component_write_transaction_metadata(entity, local_id)
}

///|
fn World::changed_component_caller_by_local_id(
  self : World,
  local_id : Int,
  entity_id : Int,
) -> String? {
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
  match self.active_component_write_metadata(entity_id, local_id) {
    Some(metadata) => metadata.changed_caller
    None => None
  }
}

///|
fn World::added_component_messages(
  self : World,
  key_id : Int,
) -> @core.Messages[@core.Entity]? {
  match self.local_component_id(key_id) {
    Some(local_id) => self.added_components.get(local_id)
    None => None
  }
}

///|
fn World::added_component_tick(
  self : World,
  key_id : Int,
  entity_id : Int,
) -> @core.Tick? {
  guard self.local_component_id(key_id) is Some(local_id) else { return None }
  self.added_component_tick_by_local_id(local_id, entity_id)
}

///|
fn World::added_component_tick_by_local_id(
  self : World,
  local_id : Int,
  entity_id : Int,
) -> @core.Tick? {
  if self.table_component_added_tick_by_local_id(entity_id, local_id)
    is Some(tick) {
    return Some(tick)
  }
  if self.alive_entity_by_id(entity_id) is Some(entity) {
    if self.sparse_component_added_tick_by_local_id(entity, local_id)
      is Some(tick) {
      return Some(tick)
    }
  }
  match self.active_component_write_metadata(entity_id, local_id) {
    Some(metadata) => metadata.added_tick
    None => None
  }
}

///|
fn World::changed_component_tick(
  self : World,
  key_id : Int,
  entity_id : Int,
) -> @core.Tick? {
  guard self.local_component_id(key_id) is Some(local_id) else { return None }
  self.changed_component_tick_by_local_id(local_id, entity_id)
}

///|
fn World::changed_component_tick_by_local_id(
  self : World,
  local_id : Int,
  entity_id : Int,
) -> @core.Tick? {
  if self.table_component_changed_tick_by_local_id(entity_id, local_id)
    is Some(tick) {
    return Some(tick)
  }
  if self.alive_entity_by_id(entity_id) is Some(entity) {
    if self.sparse_component_changed_tick_by_local_id(entity, local_id)
      is Some(tick) {
      return Some(tick)
    }
  }
  match self.active_component_write_metadata(entity_id, local_id) {
    Some(metadata) => metadata.changed_tick
    None => None
  }
}

///|
fn World::removed_component_messages(
  self : World,
  key_id : Int,
) -> @core.Messages[@core.Entity]? {
  match self.local_component_id(key_id) {
    Some(local_id) => self.removed_components.get(local_id)
    None => None
  }
}

///|
pub fn World::read_change_tick(self : World) -> @core.Tick {
  self.change_tick
}

///|
pub fn World::increment_change_tick(self : World) -> @core.Tick {
  self.change_tick = @core.tick_wrapping_add(self.change_tick, 1)
  if @core.tick_relative_to(self.change_tick, self.last_change_tick_check) >=
    @core.check_tick_threshold {
    self.check_change_ticks()
    self.last_change_tick_check = self.change_tick
  }
  self.change_tick
}

///|
pub fn World::last_change_tick(self : World) -> @core.Tick {
  self.system_tick_context.ticks().last_run
}

///|
pub fn World::change_tick(self : World) -> @core.Tick {
  self.change_tick
}

///|
pub fn World::get_tick_context(self : World) -> @core.SystemTickContext {
  self.system_tick_context
}

///|
pub fn World::set_tick_context(
  self : World,
  ctx : @core.SystemTickContext,
) -> Unit {
  self.system_tick_context = ctx
}

///|
pub fn World::check_change_ticks(self : World) -> Unit {
  let present_tick = self.read_change_tick()
  self.resource_tick_registry.check_change_ticks(present_tick)
  for table in self.tables {
    if table is Some(table_ref) {
      table_ref.check_change_ticks(present_tick)
    }
  }
  for entry in self.sparse_component_metadata.iter() {
    let metadata_store = entry.1
    let len = metadata_store.len()
    for index in 0..<len {
      let entity = metadata_store.entity_at(index)
      let metadata = metadata_store.value_at(index)
      ignore(
        metadata_store.set(
          entity,
          component_tick_metadata_check_ticks(metadata, present_tick),
        ),
      )
    }
  }
}

///|
fn component_write_tick(world : World) -> @core.Tick {
  let tick = world.read_change_tick()
  if tick > 0 {
    tick
  } else {
    1
  }
}

///|
fn resource_write_tick(world : World) -> @core.Tick {
  let tick = world.read_change_tick()
  if tick > 0 {
    tick
  } else {
    1
  }
}
