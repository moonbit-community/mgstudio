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
let next_component_id_ref : Ref[Int] = Ref(
  ecs_builtin_component_definition_count + 1,
)

///|
let next_resource_id_ref : Ref[Int] = Ref(1)

///|
let next_event_id_ref : Ref[Int] = Ref(1)

///|
let next_world_id_ref : Ref[Int] = Ref(1)

///|
pub fn[T] register_component(debug_name? : String = "") -> ComponentKey[T] {
  let id = next_component_id_ref.val
  next_component_id_ref.val = id + 1
  ignore(component_metadata_ref(id, debug_name~))
  let key = ComponentKey::{ id, debug_name, access: component_access_new() }
  key
}

///|
fn allocate_resource_id(debug_name? : String = "") -> Int {
  ignore(debug_name)
  let id = next_resource_id_ref.val
  next_resource_id_ref.val = id + 1
  id
}

///|
pub fn[T] register_resource(debug_name? : String = "") -> ResourceKey[T] {
  let id = allocate_resource_id(debug_name~)
  ResourceKey::{ id, debug_name, access: resource_access_ops_new() }
}

///|
pub fn[T] register_event(debug_name? : String = "") -> EventKey[T] {
  let id = next_event_id_ref.val
  next_event_id_ref.val = id + 1
  let key = EventKey::{ id, debug_name, access: event_access_ops_new() }
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
}

///|
struct ResourceSlot {
  mut added_tick : @core.Tick?
  mut changed_tick : @core.Tick?
  mut changed_caller : String?
}

///|
struct ComponentTickMetadata {
  added_tick : @core.Tick?
  changed_tick : @core.Tick?
  changed_caller : String?
}

///|
fn component_tick_metadata_empty() -> ComponentTickMetadata {
  { added_tick: None, changed_tick: None, changed_caller: None }
}

///|
fn component_tick_metadata_with_added(
  previous : ComponentTickMetadata?,
  tick : @core.Tick,
  caller : String?,
) -> ComponentTickMetadata {
  let previous = previous.unwrap_or(component_tick_metadata_empty())
  {
    added_tick: Some(tick),
    changed_tick: match previous.changed_tick {
      Some(changed_tick) => Some(changed_tick)
      None => Some(tick)
    },
    changed_caller: caller,
  }
}

///|
fn component_tick_metadata_with_changed(
  previous : ComponentTickMetadata?,
  tick : @core.Tick,
  caller : String?,
) -> ComponentTickMetadata {
  let previous = previous.unwrap_or(component_tick_metadata_empty())
  {
    added_tick: previous.added_tick,
    changed_tick: Some(tick),
    changed_caller: caller,
  }
}

///|
fn component_tick_metadata_check_ticks(
  metadata : ComponentTickMetadata,
  present_tick : @core.Tick,
) -> ComponentTickMetadata {
  {
    added_tick: match metadata.added_tick {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    },
    changed_tick: match metadata.changed_tick {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    },
    changed_caller: metadata.changed_caller,
  }
}

///|
priv struct PendingComponentWriteEntry {
  local_component_id : Int
  mut metadata : ComponentTickMetadata
}

///|
priv struct PendingComponentWriteSet {
  entries : Array[PendingComponentWriteEntry]
  indices_by_local_component_id : Map[Int, Int]
  presence : @utils.IntBitSet
}

///|
fn pending_component_write_set_new() -> PendingComponentWriteSet {
  {
    entries: [],
    indices_by_local_component_id: {},
    presence: @utils.IntBitSet::new(),
  }
}

///|
fn PendingComponentWriteSet::index_of(
  self : PendingComponentWriteSet,
  local_component_id : Int,
) -> Int? {
  self.indices_by_local_component_id.get(local_component_id)
}

///|
fn PendingComponentWriteSet::contains(
  self : PendingComponentWriteSet,
  local_component_id : Int,
) -> Bool {
  self.presence.contains(local_component_id)
}

///|
fn PendingComponentWriteSet::metadata(
  self : PendingComponentWriteSet,
  local_component_id : Int,
) -> ComponentTickMetadata? {
  match self.index_of(local_component_id) {
    Some(index) => Some(self.entries[index].metadata)
    None => None
  }
}

///|
fn PendingComponentWriteSet::insert(
  self : PendingComponentWriteSet,
  local_component_id : Int,
) -> Unit {
  if self.contains(local_component_id) {
    return
  }
  let index = self.entries.length()
  self.entries.push({
    local_component_id,
    metadata: component_tick_metadata_empty(),
  })
  self.indices_by_local_component_id.set(local_component_id, index)
  self.presence.insert(local_component_id)
}

///|
fn PendingComponentWriteSet::set_metadata(
  self : PendingComponentWriteSet,
  local_component_id : Int,
  metadata : ComponentTickMetadata,
) -> Unit {
  match self.index_of(local_component_id) {
    Some(index) => self.entries[index].metadata = metadata
    None => ()
  }
}

///|
struct PendingComponentWriteContext {
  entity_id : Int
  writes : PendingComponentWriteSet
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
  priv world_id : Int
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
  priv observer_registry : Ref[WorldObserverRegistry]
  priv mut current_component_observer_context : ComponentObserverContext?
  priv mut current_trigger_observer_context : TriggerObserverContext?
  priv entities : @core.Entities
  priv mut change_tick : @core.Tick
  priv mut last_change_tick_check : @core.Tick
  priv mut system_tick_context : @core.SystemTickContext
  priv mut pending_component_write_context : PendingComponentWriteContext?
  priv mut active_query_iteration_count : Int
  priv tables : Map[Int, Ref[RawTable]]
  priv sparse_component_metadata : Map[
    Int,
    Ref[@core.ComponentStore[ComponentTickMetadata]],
  ]
  priv mut next_archetype_id : Int
  priv mut next_table_id : Int
  priv mut next_bundle_id : Int
  priv mut next_component_column_table_plan_id : Int
  priv bundle_ids_by_signature : ArchetypeSignatureIndex
  priv bundle_infos : Map[Int, BundleInfo]
  priv component_column_table_plan_ids_by_signature : ArchetypeSignatureIndex
  priv component_column_table_plans : Map[Int, Ref[ComponentColumnTablePlan]]
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
  priv archetype_entities : Map[Int, Array[@core.Entity]]
  priv entity_archetype_ids : Array[Int]
  priv entity_table_ids : Array[Int]
  priv entity_table_rows : Array[Int]
  priv entity_archetype_rows : Array[Int]
  priv entity_component_local_ids : Array[Array[Int]]
  priv entity_component_local_id_presence : Array[@utils.IntBitSet]
  priv required_components : Map[Int, Ref[RequiredComponentsState]]
  priv used_components : @utils.IntBitSet
  priv added_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  priv changed_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  priv removed_components : Map[Int, Ref[@core.Messages[@core.Entity]]]
  priv component_hooks_registry : Map[Int, ComponentHooks]
  priv resources : Map[Int, ResourceSlot]
  priv mut deferred_hook_command_depth : Int
  priv deferred_hook_commands : Array[DeferredHookCommand]
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
    observer_registry: Ref(world_observer_registry_new()),
    current_component_observer_context: None,
    current_trigger_observer_context: None,
    entities: @core.Entities::new(),
    change_tick: 0,
    last_change_tick_check: 0,
    system_tick_context: @core.SystemTickContext::new(),
    pending_component_write_context: None,
    active_query_iteration_count: 0,
    tables: {},
    sparse_component_metadata: {},
    next_archetype_id: 1,
    next_table_id: 1,
    next_bundle_id: 1,
    next_component_column_table_plan_id: 1,
    bundle_ids_by_signature: archetype_signature_index_new(),
    bundle_infos: {},
    component_column_table_plan_ids_by_signature: archetype_signature_index_new(),
    component_column_table_plans: {},
    archetype_ids_by_signature: archetype_signature_index_new(),
    table_ids_by_signature: archetype_signature_index_new(),
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
    entity_component_local_id_presence: [],
    required_components: {},
    used_components: @utils.IntBitSet::new(),
    added_components: {},
    changed_components: {},
    removed_components: {},
    component_hooks_registry: {},
    resources: {},
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
  let caller = hook_caller_from_loc(loc)
  let removed_components : Array[Int] = []
  let component_local_ids = self.entity_local_components(entity).copy()
  for local_id in component_local_ids {
    guard self.definition_component_id(local_id) is Some(key_id) else {
      continue
    }
    if self.component_present_by_local_id(entity, local_id) {
      removed_components.push(key_id)
    }
  }
  for key_id in removed_components {
    self.run_component_despawn_hooks(entity, key_id, caller~)
    self.run_despawn_observers(entity, key_id)
  }
  for key_id in removed_components {
    self.run_component_replace_hooks(entity, key_id, caller~)
    self.run_replace_observers(entity, key_id)
    self.run_component_remove_hooks(entity, key_id, caller~)
  }
  self.entities.despawn(entity) catch {
    err => raise EntityStateError(err)
  }
  self.clear_entity_archetype_tracking(entity)
  self.mark_entity_lifecycle_changed()
  self.mark_structure_changed()
  for key_id in removed_components {
    if self.local_component_id(key_id) is Some(local_id) {
      ignore(self.remove_component_write_by_local_id(entity, local_id))
    }
    self.run_remove_observers(entity, key_id)
    self.ensure_removed_component_messages(key_id).val.send(
      component_write_tick(self),
      entity,
    )
    self.clear_component_tick_records(entity, key_id)
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
    component_writer_for_key(key, value),
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
  guard self.component_present(key.id(), entity) else {
    self.end_deferred_hook_command_scope(outermost)
    return false
  }
  self.ensure_query_iteration_can_change_structure("remove component")
  let component_local_id = self.ensure_component_registered(key.id())
  self.run_component_replace_hooks(entity, key.id(), caller~)
  self.run_replace_observers(entity, key.id())
  self.run_component_remove_hooks(entity, key.id(), caller~)
  ignore(self.remove_component_write_by_local_id(entity, component_local_id))
  self.entity_remove_component_local_id(entity, component_local_id)
  self.refresh_entity_archetype_after_component_remove(
    entity, component_local_id,
  )
  self.mark_structure_changed()
  self.run_remove_observers(entity, key.id())
  self.ensure_removed_component_messages(key.id()).val.send(
    component_write_tick(self),
    entity,
  )
  self.clear_component_tick_records(entity, key.id())
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
fn World::ensure_removed_component_messages(
  self : World,
  key_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  let local_id = self.ensure_component_registered(key_id)
  match self.removed_components.get(local_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref(@core.Messages::new())
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
      let messages_ref = Ref(@core.Messages::new())
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
  self.ensure_changed_component_messages_by_local_id(local_id)
}

///|
fn World::ensure_changed_component_messages_by_local_id(
  self : World,
  local_id : Int,
) -> Ref[@core.Messages[@core.Entity]] {
  match self.changed_components.get(local_id) {
    Some(messages_ref) => messages_ref
    None => {
      let messages_ref = Ref(@core.Messages::new())
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
    Ref(@core.ComponentStore::new())
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
  match self.pending_component_write_context {
    Some(context) =>
      if context.entity_id == entity_id {
        context.writes.metadata(local_component_id)
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
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  match self.pending_component_write_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.writes.contains(local_component_id) {
        context.writes.set_metadata(
          local_component_id,
          component_tick_metadata_with_added(
            context.writes.metadata(local_component_id),
            tick,
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
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  match self.pending_component_write_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.writes.contains(local_component_id) {
        context.writes.set_metadata(
          local_component_id,
          component_tick_metadata_with_changed(
            context.writes.metadata(local_component_id),
            tick,
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
      self.record_pending_component_added_metadata(
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
  let tick = component_write_tick(self)
  let local_id = self.ensure_component_registered(key_id)
  self.record_component_changed_by_local_id_with_tick(
    entity, local_id, tick, caller,
  )
  self.ensure_changed_component_messages_by_local_id(local_id).val.send(
    tick, entity,
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
      self.record_pending_component_changed_metadata(
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
  match self.pending_component_write_context {
    Some(context) =>
      if context.entity_id == entity.id {
        context.writes.set_metadata(local_id, component_tick_metadata_empty())
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
  let tick = resource_write_tick(self)
  slot.added_tick = Some(tick)
  if slot.changed_tick is None {
    slot.changed_tick = Some(tick)
  }
  slot.changed_caller = caller
}

///|
fn World::record_resource_changed_with_caller(
  self : World,
  key_id : Int,
  caller : String?,
) -> Unit {
  guard self.resources.get(key_id) is Some(slot) else { return }
  slot.changed_tick = Some(resource_write_tick(self))
  slot.changed_caller = caller
}

///|
fn World::resource_added_tick_by_id(self : World, key_id : Int) -> @core.Tick? {
  match self.resources.get(key_id) {
    Some(slot) => slot.added_tick
    None => None
  }
}

///|
fn World::resource_changed_tick_by_id(
  self : World,
  key_id : Int,
) -> @core.Tick? {
  match self.resources.get(key_id) {
    Some(slot) => slot.changed_tick
    None => None
  }
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
  match self.pending_component_tick_metadata(entity_id, local_id) {
    Some(metadata) => metadata.added_tick
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
  match self.pending_component_tick_metadata(entity_id, local_id) {
    Some(metadata) => metadata.changed_tick
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
  for entry in self.resources.iter() {
    let slot = entry.1
    slot.added_tick = match slot.added_tick {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    }
    slot.changed_tick = match slot.changed_tick {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    }
  }
  for entry in self.tables.iter() {
    entry.1.val.check_change_ticks(present_tick)
  }
  for entry in self.sparse_component_metadata.iter() {
    let metadata_store = entry.1.val
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
