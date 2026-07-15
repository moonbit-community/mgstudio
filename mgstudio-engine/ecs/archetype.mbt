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
fn archetype_signature_trie_node_new() -> ArchetypeSignatureTrieNode {
  { children: Map([]), value: None }
}

///|
fn archetype_signature_index_new() -> ArchetypeSignatureIndex {
  { nodes: [archetype_signature_trie_node_new()] }
}

///|
fn ArchetypeSignatureIndex::lookup(
  self : ArchetypeSignatureIndex,
  component_ids : Array[Int],
) -> Int? {
  let mut node_id = 0
  for component_id in component_ids {
    guard self.nodes[node_id].children.get(component_id) is Some(next_node_id) else {
      return None
    }
    node_id = next_node_id
  }
  self.nodes[node_id].value
}

///|
fn ArchetypeSignatureIndex::insert(
  self : ArchetypeSignatureIndex,
  component_ids : Array[Int],
  value : Int,
) -> Unit {
  let mut node_id = 0
  for component_id in component_ids {
    let node = self.nodes[node_id]
    let next_node_id = match node.children.get(component_id) {
      Some(existing) => existing
      None => {
        let created = self.nodes.length()
        self.nodes.push(archetype_signature_trie_node_new())
        node.children.set(component_id, created)
        created
      }
    }
    node_id = next_node_id
  }
  self.nodes[node_id].value = Some(value)
}

///|
fn archetype_int_bit_set_from_ids(ids : Array[Int]) -> @utils.IntBitSet {
  let bit_set = @utils.IntBitSet::new()
  for id in ids {
    bit_set.insert(id)
  }
  bit_set
}

///|
fn archetype_local_components_with_added_component(
  component_local_ids : Array[Int],
  component_local_id : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  let mut inserted = false
  for existing_component_local_id in component_local_ids {
    if !inserted && component_local_id < existing_component_local_id {
      result.push(component_local_id)
      inserted = true
    }
    result.push(existing_component_local_id)
  }
  if !inserted {
    result.push(component_local_id)
  }
  result
}

///|
fn archetype_local_components_with_removed_component(
  component_local_ids : Array[Int],
  component_local_id : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  let mut removed = false
  for existing_component_local_id in component_local_ids {
    if !removed && existing_component_local_id == component_local_id {
      removed = true
      continue
    }
    result.push(existing_component_local_id)
  }
  if removed {
    result
  } else {
    component_local_ids.copy()
  }
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
fn archetype_insert_sorted_unique_by_binary_search(
  ids : Array[Int],
  archetype_id : Int,
) -> Bool {
  let mut low = 0
  let mut high = ids.length()
  while low < high {
    let mid = (low + high) / 2
    let current = ids[mid]
    if current == archetype_id {
      return false
    } else if current < archetype_id {
      low = mid + 1
    } else {
      high = mid
    }
  }
  ids.push(archetype_id)
  let mut index = ids.length() - 1
  while index > low {
    ids[index] = ids[index - 1]
    index = index - 1
  }
  ids[low] = archetype_id
  true
}

///|
fn archetype_insert_sorted_unique(ids : Array[Int], archetype_id : Int) -> Bool {
  if ids.length() == 0 || ids[ids.length() - 1] < archetype_id {
    ids.push(archetype_id)
    return true
  }
  if ids[ids.length() - 1] == archetype_id {
    return false
  }
  archetype_insert_sorted_unique_by_binary_search(ids, archetype_id)
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
fn archetype_union_sorted_unique_local_component_ids_with_presence(
  base_component_local_ids : Array[Int],
  base_component_presence : @utils.IntBitSet,
  added_component_local_ids : Array[Int],
) -> Array[Int] {
  if added_component_local_ids.length() == 0 {
    return base_component_local_ids.copy()
  }
  let result = base_component_local_ids.copy()
  for component_local_id in added_component_local_ids {
    if !base_component_presence.contains(component_local_id) {
      result.push(component_local_id)
    }
  }
  if result.length() == base_component_local_ids.length() {
    return result
  }
  result.sort()
  result
}

///|
fn World::ensure_bundle_info_for_writes(
  self : World,
  writes : Array[(Int, ComponentWriter)],
) -> BundleInfo? {
  if writes.length() == 0 {
    return None
  }
  if writes.length() == 1 {
    return None
  }
  let component_definition_ids : Array[Int] = []
  let component_definition_presence = @utils.IntBitSet::new()
  for write in writes {
    let component_definition_id = write.0
    if !component_definition_presence.contains(component_definition_id) {
      component_definition_presence.insert(component_definition_id)
      component_definition_ids.push(component_definition_id)
    }
  }
  if component_definition_ids.length() == 0 {
    return None
  }
  let bundle_component_definition_ids = archetype_sorted_unique_local_component_ids(
    component_definition_ids,
  )
  match self.bundle_ids_by_signature.lookup(bundle_component_definition_ids) {
    Some(bundle_id) =>
      match self.bundle_infos.get(bundle_id) {
        Some(info) => return Some(info)
        None => ()
      }
    None => ()
  }
  let component_local_ids : Array[Int] = []
  for component_definition_id in bundle_component_definition_ids {
    let component_local_id = self.ensure_component_registered(
      component_definition_id,
    )
    component_local_ids.push(component_local_id)
    match self.required_components_state(component_local_id) {
      Some(state) =>
        for entry in state.all {
          component_local_ids.push(entry.component_id)
        }
      None => ()
    }
  }
  let bundle_component_local_ids = archetype_sorted_unique_local_component_ids(
    component_local_ids,
  )
  let bundle_id = self.next_bundle_id
  self.next_bundle_id = bundle_id + 1
  let info = BundleInfo::{
    id: bundle_id,
    component_local_ids: bundle_component_local_ids,
    component_local_id_presence: archetype_int_bit_set_from_ids(
      bundle_component_local_ids,
    ),
  }
  self.bundle_ids_by_signature.insert(
    bundle_component_definition_ids, bundle_id,
  )
  self.bundle_infos.set(bundle_id, info)
  Some(info)
}

///|
fn archetype_bundle_info_covers_component_writes(
  component_writes : ComponentWriteSet,
  bundle_info : BundleInfo,
) -> Bool {
  for entry in component_writes.entries {
    let component_local_id = entry.local_component_id
    if !bundle_info.component_local_id_presence.contains(component_local_id) {
      return false
    }
  }
  true
}

///|
pub enum ArchetypeBundleMigrationPath {
  SameArchetype
  NewArchetypeSameTable
  NewArchetypeNewTable
} derive(Eq)

///|
priv struct ArchetypeBundleMigrationPlan {
  from_archetype_id : Int
  to_archetype_id : Int
  from_table_id : Int
  to_table_id : Int
  path : ArchetypeBundleMigrationPath
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
  while self.entity_storage.entity_archetype_ids.length() <= entity_id {
    self.entity_storage.entity_archetype_ids.push(-1)
  }
  while self.entity_storage.entity_table_ids.length() <= entity_id {
    self.entity_storage.entity_table_ids.push(-1)
  }
  while self.entity_storage.entity_table_rows.length() <= entity_id {
    self.entity_storage.entity_table_rows.push(-1)
  }
  while self.entity_storage.entity_archetype_rows.length() <= entity_id {
    self.entity_storage.entity_archetype_rows.push(-1)
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
  let entities = self.entity_storage.archetype_entities.get_or_init(
    archetype_id,
    fn() { [] },
  )
  let previous_length = entities.length()
  let current_row = self.entity_storage.entity_archetype_rows[entity.id]
  if current_row >= 0 &&
    current_row < entities.length() &&
    entities[current_row].id == entity.id {
    entities[current_row] = entity
    return
  }
  match archetype_entity_index_by_id(entities, entity.id) {
    Some(index) => {
      entities[index] = entity
      self.entity_storage.entity_archetype_rows[entity.id] = index
    }
    None => {
      self.entity_storage.entity_archetype_rows[entity.id] = entities.length()
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
  guard self.entity_storage.archetype_entities.get(archetype_id)
    is Some(entities) else {
    return
  }
  let index = if entity_id >= 0 &&
    entity_id < self.entity_storage.entity_archetype_rows.length() {
    let row = self.entity_storage.entity_archetype_rows[entity_id]
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
    self.entity_storage.entity_archetype_rows[swapped_entity.id] = index
  }
  ignore(entities.pop())
  if entities.length() == 0 {
    self.mark_archetype_empty(archetype_id)
  }
  if entity_id >= 0 &&
    entity_id < self.entity_storage.entity_archetype_rows.length() {
    self.entity_storage.entity_archetype_rows[entity_id] = -1
  }
}

///|
fn World::table_local_components_for_archetype_components(
  self : World,
  archetype_component_local_ids : Array[Int],
) -> Array[Int] {
  let table_component_local_ids : Array[Int] = []
  for component_local_id in archetype_component_local_ids {
    match self.local_component_storage_type(component_local_id) {
      Some(Table) => table_component_local_ids.push(component_local_id)
      _ => ()
    }
  }
  table_component_local_ids
}

///|
fn World::ensure_table_for_local_components(
  self : World,
  archetype_component_local_ids : Array[Int],
) -> Int {
  let table_component_local_ids = self.table_local_components_for_archetype_components(
    archetype_component_local_ids,
  )
  match self.table_ids_by_signature.lookup(table_component_local_ids) {
    Some(table_id) => table_id
    None => {
      let table_id = self.next_table_id
      self.next_table_id = table_id + 1
      self.table_ids_by_signature.insert(table_component_local_ids, table_id)
      self.table_component_local_ids.set(table_id, table_component_local_ids)
      table_id
    }
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
  match self.archetype_ids_by_signature.lookup(normalized) {
    Some(archetype_id) => archetype_id
    None => {
      let archetype_id = self.next_archetype_id
      self.next_archetype_id = archetype_id + 1
      let table_id = self.ensure_table_for_local_components(normalized)
      self.archetype_ids_by_signature.insert(normalized, archetype_id)
      self.archetype_table_ids.set(archetype_id, table_id)
      self.archetype_component_local_ids.set(archetype_id, normalized)
      let local_component_indices : Map[Int, Int] = Map([])
      let local_component_presence = @utils.IntBitSet::new()
      let definition_component_ids : Array[Int] = []
      let definition_component_presence = @utils.IntBitSet::new()
      for index in 0..<normalized.length() {
        let component_local_id = normalized[index]
        local_component_indices.set(component_local_id, index)
        local_component_presence.insert(component_local_id)
        guard self.definition_component_id(component_local_id)
          is Some(definition_component_id) else {
          continue
        }
        definition_component_ids.push(definition_component_id)
        definition_component_presence.insert(definition_component_id)
      }
      self.archetype_component_local_id_presence.set(
        archetype_id, local_component_presence,
      )
      self.archetype_component_local_id_indices.set(
        archetype_id, local_component_indices,
      )
      self.archetype_component_definition_ids.set(
        archetype_id, definition_component_ids,
      )
      self.archetype_component_definition_id_presence.set(
        archetype_id, definition_component_presence,
      )
      self.entity_storage.archetype_entities.set(archetype_id, [])
      for component_local_id in normalized {
        let archetype_ids = self.archetype_ids_by_component_local_id.get_or_init(
          component_local_id,
          fn() { [] },
        )
        archetype_ids.push(archetype_id)
      }
      archetype_id
    }
  }
}

///|
fn World::cache_archetype_add_edge(
  self : World,
  from_archetype_id : Int,
  component_local_id : Int,
  to_archetype_id : Int,
) -> Unit {
  let add_edges = self.archetype_add_edges_by_component_local_id.get_or_init(
    from_archetype_id,
    fn() { Map([]) },
  )
  add_edges.set(component_local_id, to_archetype_id)
  let remove_edges = self.archetype_remove_edges_by_component_local_id.get_or_init(
    to_archetype_id,
    fn() { Map([]) },
  )
  remove_edges.set(component_local_id, from_archetype_id)
}

///|
fn World::cache_archetype_remove_edge(
  self : World,
  from_archetype_id : Int,
  component_local_id : Int,
  to_archetype_id : Int,
) -> Unit {
  let remove_edges = self.archetype_remove_edges_by_component_local_id.get_or_init(
    from_archetype_id,
    fn() { Map([]) },
  )
  remove_edges.set(component_local_id, to_archetype_id)
  let add_edges = self.archetype_add_edges_by_component_local_id.get_or_init(
    to_archetype_id,
    fn() { Map([]) },
  )
  add_edges.set(component_local_id, from_archetype_id)
}

///|
fn World::cached_archetype_insert_bundle_edge_target(
  self : World,
  from_archetype_id : Int,
  bundle_id : Int,
) -> Int? {
  match self.archetype_insert_bundle_edges_by_id.get(from_archetype_id) {
    Some(edges) => edges.get(bundle_id)
    None => None
  }
}

///|
fn World::cache_archetype_insert_bundle_edge(
  self : World,
  from_archetype_id : Int,
  bundle_id : Int,
  to_archetype_id : Int,
) -> Unit {
  let edges = self.archetype_insert_bundle_edges_by_id.get_or_init(
    from_archetype_id,
    fn() { Map([]) },
  )
  edges.set(bundle_id, to_archetype_id)
}

///|
fn World::ensure_archetype_insert_bundle_edge_target(
  self : World,
  from_archetype_id : Int,
  bundle_info : BundleInfo,
) -> Int {
  match
    self.cached_archetype_insert_bundle_edge_target(
      from_archetype_id,
      bundle_info.id,
    ) {
    Some(target_archetype_id) => target_archetype_id
    None => {
      let from_components = self.archetype_component_local_ids
        .get(from_archetype_id)
        .unwrap_or([])
      let from_presence = self.archetype_component_local_id_presence
        .get(from_archetype_id)
        .unwrap_or(@utils.IntBitSet::new())
      let target_components = archetype_union_sorted_unique_local_component_ids_with_presence(
        from_components,
        from_presence,
        bundle_info.component_local_ids,
      )
      let target_archetype_id = self.ensure_archetype_for_local_components(
        target_components,
      )
      self.cache_archetype_insert_bundle_edge(
        from_archetype_id,
        bundle_info.id,
        target_archetype_id,
      )
      target_archetype_id
    }
  }
}

///|
fn World::ensure_archetype_add_edge_target(
  self : World,
  from_archetype_id : Int,
  component_local_id : Int,
) -> Int {
  let from_presence = self.archetype_component_local_id_presence
    .get(from_archetype_id)
    .unwrap_or(@utils.IntBitSet::new())
  match self.archetype_add_edges_by_component_local_id.get(from_archetype_id) {
    Some(add_edges) =>
      match add_edges.get(component_local_id) {
        Some(target_archetype_id) => target_archetype_id
        None =>
          if from_presence.contains(component_local_id) {
            self.cache_archetype_add_edge(
              from_archetype_id, component_local_id, from_archetype_id,
            )
            from_archetype_id
          } else {
            let from_components = self.archetype_component_local_ids
              .get(from_archetype_id)
              .unwrap_or([])
            let target_components = archetype_local_components_with_added_component(
              from_components, component_local_id,
            )
            let target_archetype_id = self.ensure_archetype_for_local_components(
              target_components,
            )
            self.cache_archetype_add_edge(
              from_archetype_id, component_local_id, target_archetype_id,
            )
            target_archetype_id
          }
      }
    None =>
      if from_presence.contains(component_local_id) {
        self.cache_archetype_add_edge(
          from_archetype_id, component_local_id, from_archetype_id,
        )
        from_archetype_id
      } else {
        let from_components = self.archetype_component_local_ids
          .get(from_archetype_id)
          .unwrap_or([])
        let target_components = archetype_local_components_with_added_component(
          from_components, component_local_id,
        )
        let target_archetype_id = self.ensure_archetype_for_local_components(
          target_components,
        )
        self.cache_archetype_add_edge(
          from_archetype_id, component_local_id, target_archetype_id,
        )
        target_archetype_id
      }
  }
}

///|
fn World::ensure_archetype_remove_edge_target(
  self : World,
  from_archetype_id : Int,
  component_local_id : Int,
) -> Int {
  let from_presence = self.archetype_component_local_id_presence
    .get(from_archetype_id)
    .unwrap_or(@utils.IntBitSet::new())
  match
    self.archetype_remove_edges_by_component_local_id.get(from_archetype_id) {
    Some(remove_edges) =>
      match remove_edges.get(component_local_id) {
        Some(target_archetype_id) => target_archetype_id
        None =>
          if !from_presence.contains(component_local_id) {
            self.cache_archetype_remove_edge(
              from_archetype_id, component_local_id, from_archetype_id,
            )
            from_archetype_id
          } else {
            let from_components = self.archetype_component_local_ids
              .get(from_archetype_id)
              .unwrap_or([])
            let target_components = archetype_local_components_with_removed_component(
              from_components, component_local_id,
            )
            let target_archetype_id = self.ensure_archetype_for_local_components(
              target_components,
            )
            self.cache_archetype_remove_edge(
              from_archetype_id, component_local_id, target_archetype_id,
            )
            target_archetype_id
          }
      }
    None =>
      if !from_presence.contains(component_local_id) {
        self.cache_archetype_remove_edge(
          from_archetype_id, component_local_id, from_archetype_id,
        )
        from_archetype_id
      } else {
        let from_components = self.archetype_component_local_ids
          .get(from_archetype_id)
          .unwrap_or([])
        let target_components = archetype_local_components_with_removed_component(
          from_components, component_local_id,
        )
        let target_archetype_id = self.ensure_archetype_for_local_components(
          target_components,
        )
        self.cache_archetype_remove_edge(
          from_archetype_id, component_local_id, target_archetype_id,
        )
        target_archetype_id
      }
  }
}

///|
fn World::archetype_table_id_or_invalid(
  self : World,
  archetype_id : Int,
) -> Int {
  self.archetype_table_ids.get(archetype_id).unwrap_or(-1)
}

///|
fn World::bundle_migration_plan(
  self : World,
  from_archetype_id : Int,
  to_archetype_id : Int,
) -> ArchetypeBundleMigrationPlan {
  let from_table_id = self.archetype_table_id_or_invalid(from_archetype_id)
  let to_table_id = self.archetype_table_id_or_invalid(to_archetype_id)
  let path = if from_archetype_id == to_archetype_id {
    SameArchetype
  } else if from_table_id >= 0 && from_table_id == to_table_id {
    NewArchetypeSameTable
  } else {
    NewArchetypeNewTable
  }
  ArchetypeBundleMigrationPlan::{
    from_archetype_id,
    to_archetype_id,
    from_table_id,
    to_table_id,
    path,
  }
}

///|
fn World::bundle_migrate_same_archetype(
  self : World,
  entity : @core.Entity,
  archetype_id : Int,
) -> Unit {
  self.entity_storage.entity_archetype_ids[entity.id] = archetype_id
  self.entity_storage.entity_table_ids[entity.id] = self.archetype_table_id_or_invalid(
    archetype_id,
  )
  if archetype_id < 0 {
    self.entity_storage.entity_archetype_rows[entity.id] = -1
    return
  }
  if self.entity_storage.archetype_entities.get(archetype_id) is Some(entities) {
    if archetype_entity_index_by_id(entities, entity.id) is Some(index) {
      self.entity_storage.entity_archetype_rows[entity.id] = index
      return
    }
  }
  self.archetype_add_entity(archetype_id, entity)
}

///|
fn World::bundle_migrate_new_archetype(
  self : World,
  entity : @core.Entity,
  from_archetype_id : Int,
  to_archetype_id : Int,
) -> Unit {
  if from_archetype_id >= 0 {
    self.archetype_remove_entity_by_id(from_archetype_id, entity.id)
  }
  self.entity_storage.entity_archetype_ids[entity.id] = to_archetype_id
  self.entity_storage.entity_table_ids[entity.id] = self.archetype_table_id_or_invalid(
    to_archetype_id,
  )
  if to_archetype_id >= 0 {
    self.archetype_add_entity(to_archetype_id, entity)
  } else {
    self.entity_storage.entity_archetype_rows[entity.id] = -1
  }
}

///|
fn World::swap_remove_entity_from_table(
  self : World,
  entity : @core.Entity,
  table_id : Int,
) -> Unit {
  guard self.entity_table_row(entity) is Some(row) else {
    if entity.id >= 0 &&
      entity.id < self.entity_storage.entity_table_rows.length() {
      self.entity_storage.entity_table_ids[entity.id] = -1
      self.entity_storage.entity_table_rows[entity.id] = -1
    }
    return
  }
  guard self.table_storage(table_id) is Some(table_ref) else {
    self.entity_storage.entity_table_ids[entity.id] = -1
    self.entity_storage.entity_table_rows[entity.id] = -1
    return
  }
  match table_ref.swap_remove_row(self, row) {
    Some(result) => {
      if result.swapped_entity is Some(swapped_entity) &&
        result.swapped_row is Some(swapped_row) {
        self.ensure_entity_archetype_capacity(swapped_entity.id)
        self.entity_storage.entity_table_rows[swapped_entity.id] = swapped_row.index()
      }
      self.ensure_entity_archetype_capacity(result.removed_entity.id)
      self.entity_storage.entity_table_ids[result.removed_entity.id] = -1
      self.entity_storage.entity_table_rows[result.removed_entity.id] = -1
    }
    None => {
      self.entity_storage.entity_table_ids[entity.id] = -1
      self.entity_storage.entity_table_rows[entity.id] = -1
    }
  }
}

///|
fn World::bundle_migrate_new_archetype_same_table(
  self : World,
  entity : @core.Entity,
  from_archetype_id : Int,
  to_archetype_id : Int,
  component_writes : ComponentWriteSet,
) -> Unit {
  self.bundle_migrate_new_archetype(entity, from_archetype_id, to_archetype_id)
  self.commit_sparse_component_write_metadata(entity, component_writes)
}

///|
fn World::bundle_migrate_new_archetype_new_table(
  self : World,
  entity : @core.Entity,
  from_archetype_id : Int,
  to_archetype_id : Int,
  component_writes : ComponentWriteSet,
) -> Unit {
  let from_table_id = self.archetype_table_id_or_invalid(from_archetype_id)
  let to_table_id = self.archetype_table_id_or_invalid(to_archetype_id)
  let source_row = self.entity_table_row(entity)
  let source_table = if from_table_id >= 0 {
    self.table_storage(from_table_id)
  } else {
    None
  }
  let target_component_local_ids = if to_table_id >= 0 {
    self.table_component_local_ids.get(to_table_id).unwrap_or([])
  } else {
    []
  }
  let target_row = if to_table_id >= 0 &&
    target_component_local_ids.length() > 0 {
    let appended_row = match
      self
      .ensure_table_storage(to_table_id)
      .append_row_from_source_table(
        self, entity, source_table, source_row, component_writes,
      ) {
      Some(row) => Some(row)
      None =>
        abort(
          "Failed to append target table row during archetype migration for table \{to_table_id.to_string()}",
        )
    }
    appended_row
  } else {
    None
  }
  if from_table_id >= 0 {
    self.swap_remove_entity_from_table(entity, from_table_id)
  } else if entity.id >= 0 &&
    entity.id < self.entity_storage.entity_table_rows.length() {
    self.entity_storage.entity_table_ids[entity.id] = -1
    self.entity_storage.entity_table_rows[entity.id] = -1
  }
  if from_archetype_id >= 0 {
    self.archetype_remove_entity_by_id(from_archetype_id, entity.id)
  }
  self.entity_storage.entity_archetype_ids[entity.id] = to_archetype_id
  if to_archetype_id >= 0 {
    self.archetype_add_entity(to_archetype_id, entity)
  } else {
    self.entity_storage.entity_archetype_rows[entity.id] = -1
  }
  self.entity_storage.entity_table_ids[entity.id] = if to_table_id >= 0 &&
    target_component_local_ids.length() > 0 {
    to_table_id
  } else {
    -1
  }
  self.entity_storage.entity_table_rows[entity.id] = match target_row {
    Some(row) => row.index()
    None => -1
  }
  self.commit_sparse_component_write_metadata(entity, component_writes)
}

///|
fn World::execute_bundle_migration_plan(
  self : World,
  entity : @core.Entity,
  plan : ArchetypeBundleMigrationPlan,
  component_writes : ComponentWriteSet,
) -> ArchetypeBundleMigrationPath {
  self.ensure_entity_archetype_capacity(entity.id)
  match plan.path {
    SameArchetype =>
      self.bundle_migrate_same_archetype(entity, plan.to_archetype_id)
    NewArchetypeSameTable =>
      if plan.from_table_id >= 0 && plan.from_table_id == plan.to_table_id {
        self.bundle_migrate_new_archetype_same_table(
          entity,
          plan.from_archetype_id,
          plan.to_archetype_id,
          component_writes,
        )
      } else {
        self.bundle_migrate_new_archetype_new_table(
          entity,
          plan.from_archetype_id,
          plan.to_archetype_id,
          component_writes,
        )
      }
    NewArchetypeNewTable =>
      if plan.from_table_id >= 0 && plan.from_table_id == plan.to_table_id {
        self.bundle_migrate_new_archetype_same_table(
          entity,
          plan.from_archetype_id,
          plan.to_archetype_id,
          component_writes,
        )
      } else {
        self.bundle_migrate_new_archetype_new_table(
          entity,
          plan.from_archetype_id,
          plan.to_archetype_id,
          component_writes,
        )
      }
  }
  plan.path
}

///|
fn World::migrate_entity_bundle(
  self : World,
  entity : @core.Entity,
  from_archetype_id : Int,
  to_archetype_id : Int,
  component_writes : ComponentWriteSet,
) -> ArchetypeBundleMigrationPath {
  let plan = self.bundle_migration_plan(from_archetype_id, to_archetype_id)
  self.execute_bundle_migration_plan(entity, plan, component_writes)
}

///|
pub fn World::bundle_migration_path_for_archetypes(
  self : World,
  from_archetype_id : Int,
  to_archetype_id : Int,
) -> ArchetypeBundleMigrationPath {
  self.bundle_migration_plan(from_archetype_id, to_archetype_id).path
}

///|
fn bundle_migration_path_label(path : ArchetypeBundleMigrationPath) -> String {
  match path {
    SameArchetype => "same-archetype"
    NewArchetypeSameTable => "new-archetype-same-table"
    NewArchetypeNewTable => "new-archetype-new-table"
  }
}

///|
pub fn World::bundle_migration_path_label_for_archetypes(
  self : World,
  from_archetype_id : Int,
  to_archetype_id : Int,
) -> String {
  bundle_migration_path_label(
    self.bundle_migration_path_for_archetypes(
      from_archetype_id, to_archetype_id,
    ),
  )
}

///|
fn World::entity_local_components(
  self : World,
  entity : @core.Entity,
) -> Array[Int] {
  guard self.entity_archetype_id(entity) is Some(archetype_id) else {
    return []
  }
  self.archetype_component_local_ids.get(archetype_id).unwrap_or([])
}

///|
fn World::entity_has_component_local_id(
  self : World,
  entity : @core.Entity,
  component_local_id : Int,
) -> Bool {
  guard self.entity_archetype_id(entity) is Some(archetype_id) else {
    return false
  }
  match self.archetype_component_local_id_presence.get(archetype_id) {
    Some(presence) => presence.contains(component_local_id)
    None => false
  }
}

///|
fn World::initialize_entity_archetype_tracking(
  self : World,
  entity : @core.Entity,
) -> Unit {
  self.ensure_entity_archetype_capacity(entity.id)
  let previous_archetype_id = self.entity_storage.entity_archetype_ids[entity.id]
  ignore(
    self.migrate_entity_bundle(
      entity,
      previous_archetype_id,
      0,
      component_write_set_new(),
    ),
  )
}

///|
fn World::clear_entity_archetype_tracking(
  self : World,
  entity : @core.Entity,
) -> Unit {
  if entity.id < 0 ||
    entity.id >= self.entity_storage.entity_archetype_ids.length() {
    return
  }
  let previous_archetype_id = self.entity_storage.entity_archetype_ids[entity.id]
  let component_local_ids = self.entity_local_components(entity)
  for component_local_id in component_local_ids {
    self.decrement_component_membership_count_local(component_local_id)
    self.bump_component_membership_generation_local(component_local_id)
  }
  ignore(
    self.migrate_entity_bundle(
      entity,
      previous_archetype_id,
      -1,
      component_write_set_new(),
    ),
  )
}

///|
fn World::record_entity_component_added_local_id(
  self : World,
  component_local_id : Int,
) -> Unit {
  self.increment_component_membership_count_local(component_local_id)
  self.bump_component_membership_generation_local(component_local_id)
}

///|
fn World::record_entity_component_removed_local_id(
  self : World,
  component_local_id : Int,
) -> Unit {
  self.decrement_component_membership_count_local(component_local_id)
  self.bump_component_membership_generation_local(component_local_id)
}

///|
fn World::refresh_entity_archetype_with_bundle_info(
  self : World,
  entity : @core.Entity,
  bundle_info : BundleInfo?,
  component_writes : ComponentWriteSet,
) -> Unit {
  if !self.is_alive(entity) {
    return
  }
  self.ensure_entity_archetype_capacity(entity.id)
  let previous_archetype_id = self.entity_storage.entity_archetype_ids[entity.id]
  let mut next_archetype_id : Int? = None
  match bundle_info {
    Some(bundle_info) if previous_archetype_id >= 0 =>
      if archetype_bundle_info_covers_component_writes(
          component_writes, bundle_info,
        ) {
        next_archetype_id = Some(
          self.ensure_archetype_insert_bundle_edge_target(
            previous_archetype_id, bundle_info,
          ),
        )
      }
    _ => ()
  }
  if next_archetype_id is None &&
    previous_archetype_id >= 0 &&
    component_writes.entries.length() == 1 {
    next_archetype_id = Some(
      self.ensure_archetype_add_edge_target(
        previous_archetype_id,
        component_writes.entries[0].local_component_id,
      ),
    )
  }
  if next_archetype_id is None {
    let previous_component_local_ids = self.archetype_component_local_ids
      .get(previous_archetype_id)
      .unwrap_or([])
    let previous_presence = self.archetype_component_local_id_presence
      .get(previous_archetype_id)
      .unwrap_or(@utils.IntBitSet::new())
    let added_component_local_ids : Array[Int] = []
    for entry in component_writes.entries {
      added_component_local_ids.push(entry.local_component_id)
    }
    let target_component_local_ids = archetype_union_sorted_unique_local_component_ids_with_presence(
      previous_component_local_ids, previous_presence, added_component_local_ids,
    )
    next_archetype_id = Some(
      self.ensure_archetype_for_local_components(target_component_local_ids),
    )
  }
  guard next_archetype_id is Some(next_archetype_id) else { return }
  ignore(
    self.migrate_entity_bundle(
      entity, previous_archetype_id, next_archetype_id, component_writes,
    ),
  )
}

///|
fn World::refresh_entity_archetype_with_component_writes(
  self : World,
  entity : @core.Entity,
  component_writes : ComponentWriteSet,
) -> Unit {
  self.refresh_entity_archetype_with_bundle_info(entity, None, component_writes)
}

///|
fn World::refresh_entity_archetype(self : World, entity : @core.Entity) -> Unit {
  self.refresh_entity_archetype_with_component_writes(
    entity,
    component_write_set_new(),
  )
}

///|
fn World::refresh_entity_archetype_after_component_remove(
  self : World,
  entity : @core.Entity,
  removed_component_local_id : Int,
) -> Unit {
  if !self.is_alive(entity) {
    return
  }
  self.ensure_entity_archetype_capacity(entity.id)
  let previous_archetype_id = self.entity_storage.entity_archetype_ids[entity.id]
  if previous_archetype_id < 0 {
    self.refresh_entity_archetype(entity)
    return
  }
  let next_archetype_id = self.ensure_archetype_remove_edge_target(
    previous_archetype_id, removed_component_local_id,
  )
  ignore(
    self.migrate_entity_bundle(
      entity,
      previous_archetype_id,
      next_archetype_id,
      component_write_set_new(),
    ),
  )
}

///|
pub fn World::entity_archetype_id(self : World, entity : @core.Entity) -> Int? {
  if !self.is_alive(entity) {
    return None
  }
  if entity.id < 0 ||
    entity.id >= self.entity_storage.entity_archetype_ids.length() {
    return None
  }
  match self.entity_storage.entity_archetype_ids[entity.id] {
    archetype_id if archetype_id >= 0 => Some(archetype_id)
    _ => None
  }
}

///|
pub fn World::archetype_entity_count(self : World, archetype_id : Int) -> Int {
  match self.entity_storage.archetype_entities.get(archetype_id) {
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
  self.entity_storage.archetype_entities.get(archetype_id)
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
pub fn World::archetype_table_id(self : World, archetype_id : Int) -> Int? {
  self.archetype_table_ids.get(archetype_id)
}

///|
pub fn World::archetype_component_local_index(
  self : World,
  archetype_id : Int,
  component_local_id : Int,
) -> Int? {
  match self.archetype_component_local_id_indices.get(archetype_id) {
    Some(indices) => indices.get(component_local_id)
    None => None
  }
}

///|
fn World::archetype_ids_for_component_local_id(
  self : World,
  component_local_id : Int,
) -> Array[Int] {
  match self.archetype_ids_by_component_local_id.get(component_local_id) {
    Some(archetype_ids) => archetype_ids.copy()
    None => []
  }
}

///|
fn World::archetype_local_component_presence_view(
  self : World,
  archetype_id : Int,
) -> @utils.IntBitSet? {
  self.archetype_component_local_id_presence.get(archetype_id)
}

///|
fn World::archetype_definition_component_presence_view(
  self : World,
  archetype_id : Int,
) -> @utils.IntBitSet? {
  self.archetype_component_definition_id_presence.get(archetype_id)
}

///|
pub fn World::archetype_count(self : World) -> Int {
  let mut count = 0
  for _ in self.archetype_component_local_ids.iter() {
    count = count + 1
  }
  count
}

///|
pub fn World::archetype_generation(self : World) -> Int {
  self.next_archetype_id
}
