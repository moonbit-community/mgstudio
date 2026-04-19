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
fn World::local_component_id(self : World, definition_id : Int) -> Int? {
  self.component_local_ids_by_definition_id.get(definition_id)
}

///|
fn World::definition_component_id(self : World, local_id : Int) -> Int? {
  self.component_definition_ids_by_local_id.get(local_id)
}

///|
fn World::register_observer_parent_lookup_component(
  self : World,
  definition_id : Int,
) -> Unit {
  if !self.observer_parent_lookup_component_ids.contains(definition_id) {
    self.observer_parent_lookup_component_ids.push(definition_id)
  }
}

///|
fn World::install_required_component_metadata(
  self : World,
  requiree_id : Int,
  required : ComponentRequiredMetadata,
) -> Unit {
  if self.required_components_state(requiree_id) is Some(state_ref) &&
    state_ref.val.direct.get(required.required_component_id) is Some(_) {
    return
  }
  let result : Result[Unit, RequiredComponentsError] = try? self.register_required_components_by_keys(
    requiree_id,
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
  component_id : Int,
  metadata : ComponentMetadata,
) -> Unit {
  let component_debug_name = metadata.debug_name
  if !component_hooks_is_empty(metadata.hooks) &&
    self.component_hooks_registry.get(component_id) is None {
    self.component_hooks_registry.set(component_id, metadata.hooks)
  }
  for required in metadata.required_components {
    self.install_required_component_metadata(component_id, required)
  }
  match metadata.relationship_source {
    Some(source) if source.observer_parent_lookup =>
      self.register_observer_parent_lookup_component(component_id)
    _ => ()
  }
  match metadata.relationship_target {
    Some(target) if target.linked_spawn => ()
    _ => ()
  }
  ignore(component_debug_name)
}

///|
fn World::ensure_component_registered(self : World, definition_id : Int) -> Int {
  match self.local_component_id(definition_id) {
    Some(local_id) => local_id
    None => {
      let metadata = component_metadata(definition_id)
      let local_id = self.next_local_component_id
      self.next_local_component_id = local_id + 1
      self.component_local_ids_by_definition_id.set(definition_id, local_id)
      self.component_definition_ids_by_local_id.set(local_id, definition_id)
      self.install_component_metadata(definition_id, metadata)
      local_id
    }
  }
}
