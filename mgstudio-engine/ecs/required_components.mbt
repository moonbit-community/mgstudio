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
  init : () -> ErasedValue
  depth : Int
}

///|
struct RequiredComponentsState {
  direct_order : Array[Int]
  direct : Map[Int, RequiredComponentRegistration]
  mut all : Array[RequiredComponentRegistration]
}

///|
pub struct RequiredComponents {
  component_ids : Array[Int]
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
  { direct_order: [], direct: {}, all: [] }
}

///|
fn World::required_components_state(
  self : World,
  component_id : Int,
) -> Ref[RequiredComponentsState]? {
  self.required_components.get(component_id)
}

///|
fn World::ensure_required_components_state(
  self : World,
  component_id : Int,
) -> Ref[RequiredComponentsState] {
  self.required_components.get_or_init(component_id, fn() {
    Ref::new(required_components_state_new())
  })
}

///|
fn World::component_has_been_used(self : World, component_id : Int) -> Bool {
  self.used_components.get(component_id).unwrap_or(false)
}

///|
fn World::mark_component_used(self : World, component_id : Int) -> Unit {
  self.used_components.set(component_id, true)
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
fn World::rebuild_required_components_for(
  self : World,
  component_id : Int,
  rebuilt : Map[Int, Bool],
) -> Unit {
  if rebuilt.get(component_id).unwrap_or(false) {
    return
  }

  let state_ref = self.ensure_required_components_state(component_id)
  let direct_order = state_ref.val.direct_order
  let rebuilt_all : Array[RequiredComponentRegistration] = []

  for required_id in direct_order {
    guard state_ref.val.direct.get(required_id) is Some(direct_entry) else {
      continue
    }

    if self.required_components_state(required_id) is Some(required_state_ref) {
      self.rebuild_required_components_for(required_id, rebuilt)
      if !required_components_contains_registration(rebuilt_all, required_id) {
        for inherited in required_state_ref.val.all {
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

  state_ref.val.all = rebuilt_all
  rebuilt.set(component_id, true)
}

///|
fn World::rebuild_all_required_components(self : World) -> Unit {
  let rebuilt : Map[Int, Bool] = {}
  let component_ids : Array[Int] = []
  for entry in self.required_components.iter() {
    component_ids.push(entry.0)
  }
  for component_id in component_ids {
    self.rebuild_required_components_for(component_id, rebuilt)
  }
}

///|
fn World::register_required_components_by_keys(
  self : World,
  requiree : Int,
  required : Int,
  init_value : () -> ErasedValue,
) -> Unit raise RequiredComponentsError {
  if self.component_has_been_used(requiree) {
    raise ArchetypeExists(requiree)
  }

  let state_ref = self.ensure_required_components_state(requiree)
  if state_ref.val.direct.get(required) is Some(_) {
    raise DuplicateRegistration(requiree, required)
  }

  if requiree == required {
    raise CyclicRequirement(requiree, required)
  }

  if self.required_components_state(required) is Some(required_state_ref) &&
    required_components_contains_registration(
      required_state_ref.val.all,
      requiree,
    ) {
    raise CyclicRequirement(requiree, required)
  }

  state_ref.val.direct_order.push(required)
  state_ref.val.direct.set(required, {
    component_id: required,
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
    fn() { erased_value(R::default()) },
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
    fn() { erased_value(init()) },
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
    fn() { erased_value(R::default()) },
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
    fn() { erased_value(init()) },
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
  component_id : Int,
) -> RequiredComponents? {
  match self.required_components_state(component_id) {
    Some(state_ref) => {
      let component_ids : Array[Int] = []
      for entry in state_ref.val.all {
        component_ids.push(entry.component_id)
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
  payload : ErasedValue,
  caller? : String? = None,
) -> Unit raise EcsError {
  self.ensure_entity_alive(entity)
  let outermost = self.begin_deferred_hook_command_scope()
  self.insert_component_with_requirements_unchecked(
    entity,
    component_id,
    payload,
    caller~,
  )
  self.end_deferred_hook_command_scope(outermost)
}

///|
fn World::insert_component_with_requirements_unchecked(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  payload : ErasedValue,
  caller? : String? = None,
) -> Unit {
  let store_ref = self.ensure_component_store(component_id)
  let replacing = store_ref.val.get(entity) is Some(_)
  if replacing {
    self.run_component_replace_hooks(entity, component_id, caller~)
  }
  store_ref.val.insert(entity, payload)
  self.mark_component_used(component_id)
  self.record_component_changed(entity, component_id)

  if !replacing {
    self.record_component_added(entity, component_id)
    self.ensure_added_component_messages(component_id).val.send(
      component_write_sequence(self),
      entity,
    )
    self.run_component_add_hooks(entity, component_id, caller~)
  }
  self.run_component_insert_hooks(entity, component_id, caller~)
  self.run_insert_observers(entity, component_id)
  if replacing {
    return
  }

  guard self.required_components_state(component_id) is Some(state_ref) else {
    return
  }
  for entry in state_ref.val.all {
    let required_store_ref = self.ensure_component_store(entry.component_id)
    if required_store_ref.val.contains(entity) {
      continue
    }
    self.insert_component_with_requirements_unchecked(
      entity,
      entry.component_id,
      (entry.init)(),
      caller~,
    )
  }
}
