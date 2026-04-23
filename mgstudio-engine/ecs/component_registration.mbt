// Copyright 2026 International Digital Economy Academy
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
fn component_hooks_is_empty(hooks : ComponentHooks) -> Bool {
  hooks.on_add is None &&
  hooks.on_insert is None &&
  hooks.on_replace is None &&
  hooks.on_remove is None &&
  hooks.on_despawn is None
}

///|
pub(all) struct WorldComponentIds {
  mut next_local_id : Int
}

///|
pub(all) struct WorldQueuedRegistrations {
  pending_by_definition_id : Map[Int, Bool]
  mut queue : Array[Int]
  mut cursor : Int
}

///|
pub(all) struct WorldComponents {
  local_ids_by_definition_id : Map[Int, Int]
  definition_ids_by_local_id : Map[Int, Int]
  storage_types_by_local_id : Map[Int, ComponentStorageType]
  queued : WorldQueuedRegistrations
}

///|
fn world_component_ids_new() -> WorldComponentIds {
  { next_local_id: 1 }
}

///|
fn world_queued_registrations_new() -> WorldQueuedRegistrations {
  { pending_by_definition_id: {}, queue: [], cursor: 0 }
}

///|
fn world_components_new() -> WorldComponents {
  {
    local_ids_by_definition_id: {},
    definition_ids_by_local_id: {},
    storage_types_by_local_id: {},
    queued: world_queued_registrations_new(),
  }
}

///|
fn World::bootstrap_component_registration_entry(
  self : World,
  definition_id : Int,
  expected_local_id : Int,
  label : String,
) -> Unit {
  let local_id = self.ensure_component_registered(definition_id)
  if local_id != expected_local_id {
    abort(
      "World bootstrap component ordering mismatch for \{label}: expected local id \{expected_local_id.to_string()}, got \{local_id.to_string()}",
    )
  }
}

///|
fn World::bootstrap_component_registrations(self : World) -> Unit {
  bootstrap_component_metadata()
  self.bootstrap_component_registration_entry(
    ecs_builtin_component_definition_add, 1, "ADD",
  )
  self.bootstrap_component_registration_entry(
    ecs_builtin_component_definition_insert, 2, "INSERT",
  )
  self.bootstrap_component_registration_entry(
    ecs_builtin_component_definition_replace, 3, "REPLACE",
  )
  self.bootstrap_component_registration_entry(
    ecs_builtin_component_definition_remove, 4, "REMOVE",
  )
  self.bootstrap_component_registration_entry(
    ecs_builtin_component_definition_despawn, 5, "DESPAWN",
  )
  self.bootstrap_component_registration_entry(
    ecs_builtin_component_definition_is_resource, 6, "IS_RESOURCE",
  )
}

///|
pub struct ComponentsRegistrator {
  world : World
}

///|
pub struct ComponentsQueuedRegistrator {
  world : World
}

///|
pub fn World::components_registrator(self : World) -> ComponentsRegistrator {
  { world: self }
}

///|
pub fn ComponentsRegistrator::as_queued(
  self : ComponentsRegistrator,
) -> ComponentsQueuedRegistrator {
  { world: self.world }
}

///|
pub fn[T] ComponentsRegistrator::register_component_by_key(
  self : ComponentsRegistrator,
  key : ComponentKey[T],
) -> Int {
  self.world.ensure_component_registered(key.id())
}

///|
pub fn[T : Component] ComponentsRegistrator::register_component(
  self : ComponentsRegistrator,
  key? : ComponentKey[T] = T::component(),
) -> Int {
  self.register_component_by_key(key)
}

///|
pub fn ComponentsRegistrator::apply_queued_registrations(
  self : ComponentsRegistrator,
) -> Unit {
  self.world.apply_queued_component_registrations()
}

///|
pub fn[T] ComponentsQueuedRegistrator::register_component_by_key(
  self : ComponentsQueuedRegistrator,
  key : ComponentKey[T],
) -> Int {
  self.world.queue_register_component_by_key(key)
}

///|
pub fn[T : Component] ComponentsQueuedRegistrator::register_component(
  self : ComponentsQueuedRegistrator,
  key? : ComponentKey[T] = T::component(),
) -> Int {
  self.register_component_by_key(key)
}

///|
fn World::local_component_id(self : World, definition_id : Int) -> Int? {
  self.components.local_ids_by_definition_id.get(definition_id)
}

///|
pub fn[T] World::component_id_by_key(
  self : World,
  key : ComponentKey[T],
) -> Int? {
  self.local_component_id(key.id())
}

///|
pub fn[T : Component] World::component_id(
  self : World,
  key? : ComponentKey[T] = T::component(),
) -> Int? {
  self.component_id_by_key(key)
}

///|
fn World::definition_component_id(self : World, local_id : Int) -> Int? {
  self.components.definition_ids_by_local_id.get(local_id)
}

///|
fn World::local_component_storage_type(
  self : World,
  local_id : Int,
) -> ComponentStorageType? {
  self.components.storage_types_by_local_id.get(local_id)
}

///|
fn World::register_observer_parent_lookup_component(
  self : World,
  definition_id : Int,
) -> Unit {
  let local_id = self.ensure_component_registered(definition_id)
  if !self.observer_parent_lookup_component_ids.contains(local_id) {
    self.observer_parent_lookup_component_ids.push(local_id)
  }
}

///|
fn World::assign_local_component_id(self : World, definition_id : Int) -> Int {
  let local_id = self.component_ids.next_local_id
  self.component_ids.next_local_id = local_id + 1
  self.components.local_ids_by_definition_id.set(definition_id, local_id)
  self.components.definition_ids_by_local_id.set(local_id, definition_id)
  self.component_registration_generation = self.component_registration_generation +
    1
  local_id
}

///|
pub fn World::component_registration_generation(self : World) -> Int {
  self.component_registration_generation
}

///|
fn World::registered_definition_component_ids(self : World) -> Array[Int] {
  let component_ids : Array[Int] = []
  for entry in self.components.local_ids_by_definition_id.iter() {
    component_ids.push(entry.0)
  }
  component_ids
}

///|
fn World::is_component_registration_pending(
  self : World,
  definition_id : Int,
) -> Bool {
  self.components.queued.pending_by_definition_id.get(definition_id) ==
  Some(true)
}

///|
fn World::apply_pending_component_registration(
  self : World,
  definition_id : Int,
) -> Unit {
  if !self.is_component_registration_pending(definition_id) {
    return
  }
  self.components.queued.pending_by_definition_id.remove(definition_id)
  let local_component_id = match self.local_component_id(definition_id) {
    Some(local_component_id) => local_component_id
    None =>
      abort(
        "Pending component registration without local id for definition \{definition_id.to_string()}",
      )
  }
  let metadata = component_metadata(definition_id)
  self.install_component_metadata(definition_id, local_component_id, metadata)
}

///|
pub fn[T] World::queue_register_component_by_key(
  self : World,
  key : ComponentKey[T],
) -> Int {
  let definition_id = key.id()
  match self.local_component_id(definition_id) {
    Some(local_component_id) => local_component_id
    None => {
      let local_component_id = self.assign_local_component_id(definition_id)
      self.components.queued.pending_by_definition_id.set(definition_id, true)
      self.components.queued.queue.push(definition_id)
      local_component_id
    }
  }
}

///|
pub fn[T : Component] World::queue_register_component(
  self : World,
  key? : ComponentKey[T] = T::component(),
) -> Int {
  self.queue_register_component_by_key(key)
}

///|
pub fn World::apply_queued_component_registrations(self : World) -> Unit {
  while self.components.queued.cursor < self.components.queued.queue.length() {
    let definition_id = self.components.queued.queue[self.components.queued.cursor]
    self.components.queued.cursor = self.components.queued.cursor + 1
    self.apply_pending_component_registration(definition_id)
  }
  if self.components.queued.cursor > 0 {
    self.components.queued.queue = []
    self.components.queued.cursor = 0
  }
}

///|
pub fn World::queued_component_registration_count(self : World) -> Int {
  let count = Ref::new(0)
  for entry in self.components.queued.pending_by_definition_id.iter() {
    if entry.1 {
      count.val = count.val + 1
    }
  }
  count.val
}

///|
fn World::install_required_component_metadata(
  self : World,
  requiree_definition_id : Int,
  required : ComponentRequiredMetadata,
) -> Unit {
  let requiree_local_id = self.ensure_component_registered(
    requiree_definition_id,
  )
  let required_local_id = self.ensure_component_registered(
    required.required_component_id,
  )
  if self.required_components_state(requiree_local_id) is Some(state_ref) &&
    state_ref.val.direct.get(required_local_id) is Some(_) {
    return
  }
  let result : Result[Unit, RequiredComponentsError] = try? self.register_required_components_by_keys(
    requiree_definition_id,
    required.required_component_id,
    required.init_value,
  )
  match result {
    Ok(_) => ()
    Err(DuplicateRegistration(_, _)) => ()
    Err(ArchetypeExists(component_id)) =>
      abort(
        "Static required-component registration ran too late for component \{component_id.to_string()}",
      )
    Err(CyclicRequirement(requiree, dependency)) =>
      abort(
        "Static required-component cycle detected: \{requiree.to_string()} -> \{dependency.to_string()}",
      )
  }
}

///|
fn World::install_component_metadata(
  self : World,
  definition_id : Int,
  local_component_id : Int,
  metadata : ComponentMetadata,
) -> Unit {
  if self.local_component_storage_type(local_component_id) is Some(_) {
    return
  }
  let component_debug_name = metadata.debug_name
  let mut hooks = metadata.hooks
  match metadata.relationship_target {
    Some(target) if target.linked_spawn => {
      guard target.linked_entities is Some(linked_entities) else {
        abort(
          "relationship_target(linked_spawn=true) requires linked_entities for component `\{component_debug_name}`",
        )
      }
      if hooks.on_despawn is Some(_) {
        abort(
          "Duplicate static on_despawn hook registration for linked-spawn relationship target `\{component_debug_name}`",
        )
      }
      hooks = ComponentHooks::{
        ..hooks,
        on_despawn: Some(fn(world, context) {
          let source_entities = linked_entities(world, context.entity).copy()
          for source_entity in source_entities {
            if world.is_alive(source_entity) {
              try! world.despawn(source_entity)
            }
          }
        }),
      }
    }
    _ => ()
  }
  if !component_hooks_is_empty(hooks) {
    if self.component_has_been_used(local_component_id) {
      abort(
        "Static hook registration ran too late for component `\{component_debug_name}`",
      )
    }
    let existing = self.component_hooks_registry
      .get(local_component_id)
      .unwrap_or(ComponentHooks::new())
    let merged_result : Result[ComponentHooks, ComponentHooksError] = try? component_hooks_merge(
      existing, hooks, local_component_id,
    )
    match merged_result {
      Ok(merged_hooks) =>
        self.component_hooks_registry.set(local_component_id, merged_hooks)
      Err(DuplicateHookRegistration(_, kind)) =>
        abort(
          "Duplicate static \{component_hook_kind_name(kind)} hook registration for component `\{component_debug_name}`",
        )
      Err(DuplicateRegistration(_)) =>
        abort(
          "Duplicate static hook registration for component `\{component_debug_name}`",
        )
      Err(ComponentAlreadyInUse(_)) =>
        abort(
          "Static hook registration ran too late for component `\{component_debug_name}`",
        )
    }
  }
  self.components.storage_types_by_local_id.set(
    local_component_id,
    metadata.storage_type,
  )
  for required in metadata.required_components {
    self.install_required_component_metadata(definition_id, required)
  }
  match metadata.relationship_source {
    Some(source) => {
      self.component_relationship_sources.set(local_component_id, source)
      if source.observer_parent_lookup {
        self.register_observer_parent_lookup_component(definition_id)
      }
    }
    _ => ()
  }
  ignore(component_debug_name)
}

///|
fn World::ensure_component_registered(self : World, definition_id : Int) -> Int {
  match self.local_component_id(definition_id) {
    Some(local_id) => {
      self.apply_pending_component_registration(definition_id)
      local_id
    }
    None => {
      let local_id = self.assign_local_component_id(definition_id)
      let metadata = component_metadata(definition_id)
      self.install_component_metadata(definition_id, local_id, metadata)
      local_id
    }
  }
}
