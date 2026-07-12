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
pub(all) suberror RequiredComponentsError {
  ArchetypeExists(Int)
  DuplicateRegistration(Int, Int)
  CyclicRequirement(Int, Int)
}

///|
priv struct RequiredComponentRegistration {
  component_id : Int
  init : () -> ComponentWriter
  depth : Int
}

///|
struct RequiredComponentsState {
  direct_order : Array[Int]
  direct : Map[Int, RequiredComponentRegistration]
  mut all : Array[RequiredComponentRegistration]
  mut required_by : Array[Int]
}

///|
pub struct RequiredComponents {
  priv component_ids : Array[Int]
}

///|
pub fn RequiredComponents::iter_ids(self : RequiredComponents) -> Array[Int] {
  self.component_ids
}

///|
pub fn RequiredComponents::len(self : RequiredComponents) -> Int {
  self.component_ids.length()
}

///|
pub fn RequiredComponents::is_empty(self : RequiredComponents) -> Bool {
  self.component_ids.length() == 0
}

///|
pub fn RequiredComponents::contains(
  self : RequiredComponents,
  component_id : Int,
) -> Bool {
  for id in self.component_ids {
    if id == component_id {
      return true
    }
  }
  false
}

///|
fn required_components_state_new() -> RequiredComponentsState {
  { direct_order: [], direct: Map([]), all: [], required_by: [] }
}

///|
fn World::required_components_state(
  self : World,
  component_local_id : Int,
) -> RequiredComponentsState? {
  self.required_components.get(component_local_id)
}

///|
fn World::ensure_required_components_state(
  self : World,
  component_local_id : Int,
) -> RequiredComponentsState {
  self.required_components.get_or_init(component_local_id, fn() {
    required_components_state_new()
  })
}

///|
fn World::component_has_been_used(self : World, component_id : Int) -> Bool {
  self.used_components.contains(component_id)
}

///|
fn World::mark_component_used(self : World, component_id : Int) -> Unit {
  self.used_components.insert(component_id)
}

///|
fn required_components_copy_entry(
  entry : RequiredComponentRegistration,
  depth_offset : Int,
) -> RequiredComponentRegistration {
  {
    component_id: entry.component_id,
    init: entry.init,
    depth: entry.depth + depth_offset,
  }
}

///|
fn required_components_contains_registration(
  entries : Array[RequiredComponentRegistration],
  component_id : Int,
) -> Bool {
  for entry in entries {
    if entry.component_id == component_id {
      return true
    }
  }
  false
}

///|
fn required_components_index_of(
  entries : Array[RequiredComponentRegistration],
  component_id : Int,
) -> Int? {
  for i in 0..<entries.length() {
    if entries[i].component_id == component_id {
      return Some(i)
    }
  }
  None
}

///|
fn required_components_push_unique(
  entries : Array[Int],
  component_id : Int,
) -> Unit {
  if !entries.contains(component_id) {
    entries.push(component_id)
  }
}

///|
fn World::required_components_reaches(
  self : World,
  from_component_id : Int,
  target_component_id : Int,
  visited : @utils.IntBitSet,
) -> Bool {
  if from_component_id == target_component_id {
    return true
  }
  if visited.contains(from_component_id) {
    return false
  }
  visited.insert(from_component_id)
  guard self.required_components_state(from_component_id) is Some(state) else {
    return false
  }
  for required_id in state.direct_order {
    guard state.direct.get(required_id) is Some(_) else { continue }
    if self.required_components_reaches(
        required_id, target_component_id, visited,
      ) {
      return true
    }
  }
  false
}

///|
fn World::rebuild_required_components_for(
  self : World,
  component_id : Int,
  rebuilt : @utils.IntBitSet,
) -> Unit {
  if rebuilt.contains(component_id) {
    return
  }

  let state = self.ensure_required_components_state(component_id)
  let direct_order = state.direct_order
  let rebuilt_all : Array[RequiredComponentRegistration] = []

  for required_id in direct_order {
    guard state.direct.get(required_id) is Some(direct_entry) else { continue }

    if self.required_components_state(required_id) is Some(required_state) {
      self.rebuild_required_components_for(required_id, rebuilt)
      if !required_components_contains_registration(rebuilt_all, required_id) {
        for inherited in required_state.all {
          if !required_components_contains_registration(
              rebuilt_all,
              inherited.component_id,
            ) {
            rebuilt_all.push(required_components_copy_entry(inherited, 1))
          }
        }
      }
    }

    let direct_registration = {
      component_id: required_id,
      init: direct_entry.init,
      depth: 1,
    }
    if required_components_index_of(rebuilt_all, required_id) is Some(index) {
      rebuilt_all[index] = direct_registration
    } else {
      rebuilt_all.push(direct_registration)
    }
  }

  state.all = rebuilt_all
  rebuilt.insert(component_id)
}

///|
fn World::rebuild_required_by_components(self : World) -> Unit {
  let local_component_ids : Array[Int] = []
  for entry in self.required_components.iter() {
    local_component_ids.push(entry.0)
  }
  local_component_ids.sort()
  for local_component_id in local_component_ids {
    self.ensure_required_components_state(local_component_id).required_by = []
  }
  for requiree_local_id in local_component_ids {
    let state = self.ensure_required_components_state(requiree_local_id)
    for required in state.all {
      let required_state = self.ensure_required_components_state(
        required.component_id,
      )
      required_components_push_unique(
        required_state.required_by,
        requiree_local_id,
      )
    }
  }
  for local_component_id in local_component_ids {
    self.ensure_required_components_state(local_component_id).required_by.sort()
  }
}

///|
fn World::rebuild_all_required_components(self : World) -> Unit {
  let rebuilt = @utils.IntBitSet::new()
  let component_ids : Array[Int] = []
  for entry in self.required_components.iter() {
    component_ids.push(entry.0)
  }
  component_ids.sort()
  for component_id in component_ids {
    self.rebuild_required_components_for(component_id, rebuilt)
  }
  self.rebuild_required_by_components()
}

///|
fn World::register_required_components_by_keys(
  self : World,
  requiree : Int,
  required : Int,
  init_value : () -> ComponentWriter,
) -> Unit raise RequiredComponentsError {
  let requiree_local_id = self.ensure_component_registered(requiree)
  if self.component_has_been_used(requiree_local_id) {
    raise ArchetypeExists(requiree_local_id)
  }

  let required_local_id = self.ensure_component_registered(required)
  let state = self.ensure_required_components_state(requiree_local_id)
  if state.direct.get(required_local_id) is Some(_) {
    raise DuplicateRegistration(requiree_local_id, required_local_id)
  }

  if requiree_local_id == required_local_id {
    raise CyclicRequirement(requiree_local_id, required_local_id)
  }

  let visited = @utils.IntBitSet::new()
  if self.required_components_reaches(
      required_local_id, requiree_local_id, visited,
    ) {
    raise CyclicRequirement(requiree_local_id, required_local_id)
  }

  state.direct_order.push(required_local_id)
  state.direct.set(required_local_id, {
    component_id: required_local_id,
    init: init_value,
    depth: 1,
  })
  self.rebuild_all_required_components()
}

///|
pub fn[T, R : Default] World::register_required_components(
  self : World,
  requiree_key : ComponentKey[T],
  required_key : ComponentKey[R],
) -> Unit raise RequiredComponentsError {
  self.register_required_components_by_keys(
    requiree_key.id(),
    required_key.id(),
    fn() { component_writer_for_key(required_key, R::default()) },
  )
}

///|
pub fn[T, R] World::register_required_components_with(
  self : World,
  requiree_key : ComponentKey[T],
  required_key : ComponentKey[R],
  init : () -> R,
) -> Unit raise RequiredComponentsError {
  self.register_required_components_by_keys(
    requiree_key.id(),
    required_key.id(),
    fn() { component_writer_for_key(required_key, init()) },
  )
}

///|
pub fn[T, R : Default] World::try_register_required_components(
  self : World,
  requiree_key : ComponentKey[T],
  required_key : ComponentKey[R],
) -> Unit raise RequiredComponentsError {
  self.register_required_components_by_keys(
    requiree_key.id(),
    required_key.id(),
    fn() { component_writer_for_key(required_key, R::default()) },
  )
}

///|
pub fn[T, R] World::try_register_required_components_with(
  self : World,
  requiree_key : ComponentKey[T],
  required_key : ComponentKey[R],
  init : () -> R,
) -> Unit raise RequiredComponentsError {
  self.register_required_components_by_keys(
    requiree_key.id(),
    required_key.id(),
    fn() { component_writer_for_key(required_key, init()) },
  )
}

///|
pub fn[T] World::get_required_components(
  self : World,
  requiree_key : ComponentKey[T],
) -> RequiredComponents? {
  self.get_required_components_by_id(requiree_key.id())
}

///|
pub fn World::get_required_components_by_id(
  self : World,
  component_definition_id : Int,
) -> RequiredComponents? {
  guard self.local_component_id(component_definition_id)
    is Some(component_local_id) else {
    return None
  }
  match self.required_components_state(component_local_id) {
    Some(state) => {
      let component_ids : Array[Int] = []
      for entry in state.all {
        if self.definition_component_id(entry.component_id)
          is Some(definition_id) {
          component_ids.push(definition_id)
        }
      }
      Some(RequiredComponents::{ component_ids, })
    }
    None => None
  }
}

///|
pub fn[T] World::get_required_by_components(
  self : World,
  required_key : ComponentKey[T],
) -> RequiredComponents? {
  self.get_required_by_components_by_id(required_key.id())
}

///|
pub fn World::get_required_by_components_by_id(
  self : World,
  component_definition_id : Int,
) -> RequiredComponents? {
  guard self.local_component_id(component_definition_id)
    is Some(component_local_id) else {
    return None
  }
  match self.required_components_state(component_local_id) {
    Some(state) => {
      let component_ids : Array[Int] = []
      for requiree_local_id in state.required_by {
        if self.definition_component_id(requiree_local_id)
          is Some(definition_id) {
          component_ids.push(definition_id)
        }
      }
      Some(RequiredComponents::{ component_ids, })
    }
    None => None
  }
}

///|
fn World::insert_component_with_requirements(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  writer : ComponentWriter,
  caller? : String? = None,
) -> Unit raise EcsError {
  self.insert_component_writes_with_requirements(
    entity,
    [(component_id, writer)],
    caller~,
  )
}

///|
fn World::insert_component_writes_with_requirements(
  self : World,
  entity : @core.Entity,
  writes : Array[(Int, ComponentWriter)],
  caller? : String? = None,
) -> Unit raise EcsError {
  self.ensure_entity_alive(entity)
  if self.has_active_query_iteration() {
    for write in writes {
      if !self.component_present(write.0, entity) {
        self.ensure_query_iteration_can_change_structure("insert component")
      }
    }
  }
  let outermost = self.begin_deferred_hook_command_scope()
  let bundle_info = self.ensure_bundle_info_for_writes(writes)
  let has_existing_transaction = self.has_active_component_write_transaction_for_entity(
    entity,
  )
  let assume_no_existing_components = !has_existing_transaction &&
    entity.id >= 0 &&
    entity.id < self.entity_storage.entity_archetype_ids.length() &&
    self.entity_storage.entity_archetype_ids[entity.id] == 0 &&
    entity.id < self.entity_storage.entity_component_local_ids.length() &&
    self.entity_storage.entity_component_local_ids[entity.id].length() == 0
  let component_writes = self
    .active_component_write_set_for_entity(entity)
    .unwrap_or(component_write_set_new())
  let previous_transaction = self.begin_component_write_transaction(
    entity, component_writes,
  )
  let transaction = ComponentInsertTransaction(
    entity, component_writes, assume_no_existing_components, caller,
  )
  for write in writes {
    self.insert_component_with_requirements_unchecked(
      transaction,
      write.0,
      write.1,
    )
  }
  if transaction.structural_changed {
    self.refresh_entity_archetype_with_bundle_info(
      entity,
      bundle_info,
      transaction.writes,
    )
    self.mark_structure_changed()
  }
  self.restore_component_write_transaction(previous_transaction)
  self.end_deferred_hook_command_scope(outermost)
}

///|
pub fn World::insert_component_writers(
  self : World,
  entity : @core.Entity,
  writers : Array[ComponentWriter],
  caller? : String? = None,
) -> Unit raise EcsError {
  if writers.is_empty() {
    return
  }
  let writes : Array[(Int, ComponentWriter)] = []
  for writer in writers {
    writes.push((writer.component_definition_id, writer))
  }
  self.insert_component_writes_with_requirements(entity, writes, caller~)
}

///|
fn World::insert_component_with_requirements_unchecked(
  self : World,
  transaction : ComponentInsertTransaction,
  component_definition_id : Int,
  writer : ComponentWriter,
) -> Unit {
  let component_local_id = self.ensure_component_registered(
    component_definition_id,
  )
  let entity = transaction.entity
  let caller = transaction.caller
  let replacing = transaction.replaces_existing_component(
    self, component_definition_id, component_local_id,
  )
  if replacing {
    self.run_component_replace_hooks(entity, component_definition_id, caller~)
    self.run_replace_observers(entity, component_definition_id)
  }
  if replacing {
    ignore(
      self.replace_component_writer(component_definition_id, entity, writer),
    )
  } else {
    transaction.writes.insert(component_local_id)
    writer.apply(self, entity)
  }
  self.mark_component_used(component_local_id)
  self.record_component_changed_with_caller(
    entity, component_definition_id, caller,
  )

  if !replacing {
    self.entity_add_component_local_id(entity, component_local_id)
    transaction.mark_structural_changed()
    self.record_component_added_with_caller(
      entity, component_definition_id, caller,
    )
    self
    .ensure_added_component_messages(component_definition_id)
    .send(component_write_tick(self), entity)
  }
  if replacing {
    self.run_component_insert_hooks(entity, component_definition_id, caller~)
    self.run_insert_observers(entity, component_definition_id)
    return
  }

  if self.required_components_state(component_local_id) is Some(state) {
    for entry in state.all {
      if self.component_present_by_local_id(entity, entry.component_id) ||
        transaction.writes.contains(entry.component_id) {
        continue
      }
      guard self.definition_component_id(entry.component_id)
        is Some(required_definition_id) else {
        continue
      }
      self.insert_component_with_requirements_unchecked(
        transaction,
        required_definition_id,
        (entry.init)(),
      )
    }
  }
  self.run_component_add_hooks(entity, component_definition_id, caller~)
  self.run_add_observers(entity, component_definition_id)
  self.run_component_insert_hooks(entity, component_definition_id, caller~)
  self.run_insert_observers(entity, component_definition_id)
}
