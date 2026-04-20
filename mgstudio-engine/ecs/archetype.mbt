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
fn archetype_sorted_unique_local_component_ids(
  component_local_ids : Array[Int],
) -> Array[Int] {
  let sorted = component_local_ids.copy()
  sorted.sort()
  let unique : Array[Int] = []
  for component_local_id in sorted {
    if unique.length() == 0 || unique[unique.length() - 1] != component_local_id {
      unique.push(component_local_id)
    }
  }
  unique
}

///|
fn archetype_signature_from_local_component_ids(
  component_local_ids : Array[Int],
) -> String {
  if component_local_ids.length() == 0 {
    return ""
  }
  let mut signature = ""
  for index in 0..<component_local_ids.length() {
    if index > 0 {
      signature = signature + ","
    }
    signature = signature + component_local_ids[index].to_string()
  }
  signature
}

///|
fn archetype_entity_index_by_id(
  entities : Array[@core.Entity],
  entity_id : Int,
) -> Int? {
  for index in 0..<entities.length() {
    if entities[index].id == entity_id {
      return Some(index)
    }
  }
  None
}

///|
fn archetype_insert_sorted_unique(ids : Array[Int], archetype_id : Int) -> Bool {
  if ids.contains(archetype_id) {
    return false
  }
  ids.push(archetype_id)
  ids.sort()
  true
}

///|
fn archetype_remove_sorted(ids : Array[Int], archetype_id : Int) -> Bool {
  let mut remove_index : Int? = None
  for index in 0..<ids.length() {
    if ids[index] == archetype_id {
      remove_index = Some(index)
      break
    }
  }
  guard remove_index is Some(index) else { return false }
  let last_index = ids.length() - 1
  let mut i = index
  while i < last_index {
    ids[i] = ids[i + 1]
    i = i + 1
  }
  ignore(ids.pop())
  true
}

///|
fn World::mark_archetype_non_empty(self : World, archetype_id : Int) -> Unit {
  if archetype_insert_sorted_unique(
      self.non_empty_archetype_ids_sorted,
      archetype_id,
    ) {
    match self.archetype_component_local_ids.get(archetype_id) {
      Some(component_local_ids) =>
        for component_local_id in component_local_ids {
          let non_empty_archetype_ids = self.archetype_non_empty_ids_by_component_local_id.get_or_init(
            component_local_id,
            fn() { [] },
          )
          ignore(
            archetype_insert_sorted_unique(
              non_empty_archetype_ids, archetype_id,
            ),
          )
        }
      None => ()
    }
    self.non_empty_archetype_generation = self.non_empty_archetype_generation +
      1
  }
}

///|
fn World::mark_archetype_empty(self : World, archetype_id : Int) -> Unit {
  if archetype_remove_sorted(self.non_empty_archetype_ids_sorted, archetype_id) {
    match self.archetype_component_local_ids.get(archetype_id) {
      Some(component_local_ids) =>
        for component_local_id in component_local_ids {
          guard self.archetype_non_empty_ids_by_component_local_id.get(
              component_local_id,
            )
            is Some(non_empty_archetype_ids) else {
            continue
          }
          if archetype_remove_sorted(non_empty_archetype_ids, archetype_id) &&
            non_empty_archetype_ids.length() == 0 {
            self.archetype_non_empty_ids_by_component_local_id.remove(
              component_local_id,
            )
          }
        }
      None => ()
    }
    self.non_empty_archetype_generation = self.non_empty_archetype_generation +
      1
  }
}

///|
fn World::ensure_entity_archetype_capacity(
  self : World,
  entity_id : Int,
) -> Unit {
  if entity_id < 0 {
    return
  }
  while self.entity_archetype_ids.length() <= entity_id {
    self.entity_archetype_ids.push(-1)
  }
  while self.entity_component_local_ids.length() <= entity_id {
    self.entity_component_local_ids.push([])
  }
  while self.entity_archetype_rows.length() <= entity_id {
    self.entity_archetype_rows.push(-1)
  }
}

///|
fn World::bump_component_membership_generation_local(
  self : World,
  component_local_id : Int,
) -> Unit {
  let next_generation = self.component_membership_generations
    .get(component_local_id)
    .unwrap_or(0) +
    1
  self.component_membership_generations.set(component_local_id, next_generation)
}

///|
fn World::increment_component_membership_count_local(
  self : World,
  component_local_id : Int,
) -> Unit {
  let next_count = self.component_membership_counts
    .get(component_local_id)
    .unwrap_or(0) +
    1
  self.component_membership_counts.set(component_local_id, next_count)
}

///|
fn World::decrement_component_membership_count_local(
  self : World,
  component_local_id : Int,
) -> Unit {
  let current_count = self.component_membership_counts
    .get(component_local_id)
    .unwrap_or(0)
  if current_count <= 1 {
    self.component_membership_counts.remove(component_local_id)
  } else {
    self.component_membership_counts.set(component_local_id, current_count - 1)
  }
}

///|
fn World::component_membership_generation_for_definition(
  self : World,
  component_definition_id : Int,
) -> Int {
  match self.local_component_id(component_definition_id) {
    Some(component_local_id) =>
      self.component_membership_generations.get(component_local_id).unwrap_or(0)
    None => -1
  }
}

///|
fn World::component_membership_count_for_definition(
  self : World,
  component_definition_id : Int,
) -> Int {
  match self.local_component_id(component_definition_id) {
    Some(component_local_id) =>
      self.component_membership_counts.get(component_local_id).unwrap_or(0)
    None => 0
  }
}

///|
fn World::archetype_add_entity(
  self : World,
  archetype_id : Int,
  entity : @core.Entity,
) -> Unit {
  self.ensure_entity_archetype_capacity(entity.id)
  let entities = self.archetype_entities.get_or_init(archetype_id, fn() { [] })
  let previous_length = entities.length()
  let current_row = self.entity_archetype_rows[entity.id]
  if current_row >= 0 &&
    current_row < entities.length() &&
    entities[current_row].id == entity.id {
    entities[current_row] = entity
    return
  }
  match archetype_entity_index_by_id(entities, entity.id) {
    Some(index) => {
      entities[index] = entity
      self.entity_archetype_rows[entity.id] = index
    }
    None => {
      self.entity_archetype_rows[entity.id] = entities.length()
      entities.push(entity)
      if previous_length == 0 {
        self.mark_archetype_non_empty(archetype_id)
      }
    }
  }
}

///|
fn World::archetype_remove_entity_by_id(
  self : World,
  archetype_id : Int,
  entity_id : Int,
) -> Unit {
  guard self.archetype_entities.get(archetype_id) is Some(entities) else {
    return
  }
  let index = if entity_id >= 0 &&
    entity_id < self.entity_archetype_rows.length() {
    let row = self.entity_archetype_rows[entity_id]
    if row >= 0 && row < entities.length() && entities[row].id == entity_id {
      Some(row)
    } else {
      archetype_entity_index_by_id(entities, entity_id)
    }
  } else {
    archetype_entity_index_by_id(entities, entity_id)
  }
  guard index is Some(index) else { return }
  let last_index = entities.length() - 1
  if index != last_index {
    let swapped_entity = entities[last_index]
    entities[index] = swapped_entity
    self.ensure_entity_archetype_capacity(swapped_entity.id)
    self.entity_archetype_rows[swapped_entity.id] = index
  }
  ignore(entities.pop())
  if entities.length() == 0 {
    self.mark_archetype_empty(archetype_id)
  }
  if entity_id >= 0 && entity_id < self.entity_archetype_rows.length() {
    self.entity_archetype_rows[entity_id] = -1
  }
}

///|
fn World::ensure_archetype_for_local_components(
  self : World,
  component_local_ids : Array[Int],
) -> Int {
  let normalized = archetype_sorted_unique_local_component_ids(
    component_local_ids,
  )
  let signature = archetype_signature_from_local_component_ids(normalized)
  match self.archetype_ids_by_signature.get(signature) {
    Some(archetype_id) => archetype_id
    None => {
      let archetype_id = self.next_archetype_id
      self.next_archetype_id = archetype_id + 1
      self.archetype_ids_by_signature.set(signature, archetype_id)
      self.archetype_component_local_ids.set(archetype_id, normalized)
      let local_component_presence : Map[Int, Bool] = {}
      let definition_component_ids : Array[Int] = []
      let definition_component_presence : Map[Int, Bool] = {}
      for component_local_id in normalized {
        local_component_presence.set(component_local_id, true)
        guard self.definition_component_id(component_local_id)
          is Some(definition_component_id) else {
          continue
        }
        definition_component_ids.push(definition_component_id)
        definition_component_presence.set(definition_component_id, true)
      }
      self.archetype_component_local_id_presence.set(
        archetype_id, local_component_presence,
      )
      self.archetype_component_definition_ids.set(
        archetype_id, definition_component_ids,
      )
      self.archetype_component_definition_id_presence.set(
        archetype_id, definition_component_presence,
      )
      self.archetype_entities.set(archetype_id, [])
      for component_local_id in normalized {
        let archetype_ids = self.archetype_ids_by_component_local_id.get_or_init(
          component_local_id,
          fn() { [] },
        )
        if !archetype_ids.contains(archetype_id) {
          archetype_ids.push(archetype_id)
        }
      }
      archetype_id
    }
  }
}

///|
fn World::entity_local_components(
  self : World,
  entity : @core.Entity,
) -> Array[Int] {
  if entity.id < 0 || entity.id >= self.entity_component_local_ids.length() {
    return []
  }
  self.entity_component_local_ids[entity.id]
}

///|
fn World::initialize_entity_archetype_tracking(
  self : World,
  entity : @core.Entity,
) -> Unit {
  self.ensure_entity_archetype_capacity(entity.id)
  let previous_archetype_id = self.entity_archetype_ids[entity.id]
  if previous_archetype_id >= 0 {
    self.archetype_remove_entity_by_id(previous_archetype_id, entity.id)
  }
  self.entity_component_local_ids[entity.id] = []
  self.entity_archetype_ids[entity.id] = 0
  self.entity_archetype_rows[entity.id] = -1
  self.archetype_add_entity(0, entity)
}

///|
fn World::clear_entity_archetype_tracking(
  self : World,
  entity : @core.Entity,
) -> Unit {
  if entity.id < 0 || entity.id >= self.entity_archetype_ids.length() {
    return
  }
  let previous_archetype_id = self.entity_archetype_ids[entity.id]
  if previous_archetype_id >= 0 {
    self.archetype_remove_entity_by_id(previous_archetype_id, entity.id)
  }
  let component_local_ids = self.entity_component_local_ids[entity.id]
  for component_local_id in component_local_ids {
    self.decrement_component_membership_count_local(component_local_id)
    self.bump_component_membership_generation_local(component_local_id)
  }
  self.entity_archetype_ids[entity.id] = -1
  self.entity_archetype_rows[entity.id] = -1
  self.entity_component_local_ids[entity.id] = []
}

///|
fn World::entity_add_component_local_id(
  self : World,
  entity : @core.Entity,
  component_local_id : Int,
) -> Unit {
  self.ensure_entity_archetype_capacity(entity.id)
  let component_local_ids = self.entity_component_local_ids[entity.id]
  if !component_local_ids.contains(component_local_id) {
    component_local_ids.push(component_local_id)
    self.entity_component_local_ids[entity.id] = component_local_ids
    self.increment_component_membership_count_local(component_local_id)
    self.bump_component_membership_generation_local(component_local_id)
  }
}

///|
fn World::entity_remove_component_local_id(
  self : World,
  entity : @core.Entity,
  component_local_id : Int,
) -> Unit {
  if entity.id < 0 || entity.id >= self.entity_component_local_ids.length() {
    return
  }
  let component_local_ids = self.entity_component_local_ids[entity.id]
  let mut remove_index : Int? = None
  for index in 0..<component_local_ids.length() {
    if component_local_ids[index] == component_local_id {
      remove_index = Some(index)
      break
    }
  }
  guard remove_index is Some(index) else { return }
  let last_index = component_local_ids.length() - 1
  if index != last_index {
    component_local_ids[index] = component_local_ids[last_index]
  }
  ignore(component_local_ids.pop())
  self.entity_component_local_ids[entity.id] = component_local_ids
  self.decrement_component_membership_count_local(component_local_id)
  self.bump_component_membership_generation_local(component_local_id)
}

///|
fn World::refresh_entity_archetype(self : World, entity : @core.Entity) -> Unit {
  if !self.is_alive(entity) {
    return
  }
  self.ensure_entity_archetype_capacity(entity.id)
  let normalized_components = archetype_sorted_unique_local_component_ids(
    self.entity_local_components(entity),
  )
  self.entity_component_local_ids[entity.id] = normalized_components
  let next_archetype_id = self.ensure_archetype_for_local_components(
    normalized_components,
  )
  let previous_archetype_id = self.entity_archetype_ids[entity.id]
  if previous_archetype_id == next_archetype_id {
    return
  }
  if previous_archetype_id >= 0 {
    self.archetype_remove_entity_by_id(previous_archetype_id, entity.id)
  }
  self.entity_archetype_ids[entity.id] = next_archetype_id
  self.archetype_add_entity(next_archetype_id, entity)
}

///|
pub fn World::entity_archetype_id(self : World, entity : @core.Entity) -> Int? {
  if !self.is_alive(entity) {
    return None
  }
  if entity.id < 0 || entity.id >= self.entity_archetype_ids.length() {
    return None
  }
  match self.entity_archetype_ids[entity.id] {
    archetype_id if archetype_id >= 0 => Some(archetype_id)
    _ => None
  }
}

///|
pub fn World::archetype_entity_count(self : World, archetype_id : Int) -> Int {
  match self.archetype_entities.get(archetype_id) {
    Some(entities) => entities.length()
    None => 0
  }
}

///|
pub fn World::archetype_entities_snapshot(
  self : World,
  archetype_id : Int,
) -> Array[@core.Entity] {
  match self.archetype_entities_view(archetype_id) {
    Some(entities) => entities.copy()
    None => []
  }
}

///|
fn World::archetype_entities_view(
  self : World,
  archetype_id : Int,
) -> Array[@core.Entity]? {
  self.archetype_entities.get(archetype_id)
}

///|
pub fn World::archetype_component_ids(
  self : World,
  archetype_id : Int,
) -> Array[Int]? {
  guard self.archetype_component_definition_ids_view(archetype_id)
    is Some(definition_component_ids) else {
    return None
  }
  Some(definition_component_ids.copy())
}

///|
fn World::archetype_component_definition_ids_view(
  self : World,
  archetype_id : Int,
) -> Array[Int]? {
  self.archetype_component_definition_ids.get(archetype_id)
}

///|
fn World::non_empty_archetype_ids_for_component_local_id(
  self : World,
  component_local_id : Int,
) -> Array[Int] {
  match
    self.archetype_non_empty_ids_by_component_local_id.get(component_local_id) {
    Some(archetype_ids) => archetype_ids.copy()
    None => []
  }
}

///|
fn World::archetype_local_component_presence_view(
  self : World,
  archetype_id : Int,
) -> Map[Int, Bool]? {
  self.archetype_component_local_id_presence.get(archetype_id)
}

///|
fn World::archetype_definition_component_presence_view(
  self : World,
  archetype_id : Int,
) -> Map[Int, Bool]? {
  self.archetype_component_definition_id_presence.get(archetype_id)
}

///|
pub fn World::archetype_count(self : World) -> Int {
  let count = Ref::new(0)
  for _ in self.archetype_component_local_ids.iter() {
    count.val = count.val + 1
  }
  count.val
}

///|
pub fn World::archetype_generation(self : World) -> Int {
  self.next_archetype_id
}

///|
fn World::non_empty_archetype_generation(self : World) -> Int {
  self.non_empty_archetype_generation
}

///|
fn World::non_empty_archetype_ids_snapshot(self : World) -> Array[Int] {
  self.non_empty_archetype_ids_sorted.copy()
}
