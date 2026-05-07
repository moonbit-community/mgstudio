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
pub struct ComponentColumn[T] {
  world : World
  key : ComponentKey[T]
  local_component_id : Int
  storage_type : ComponentStorageType
  table_column_cache : Ref[Array[@any.Any?]]
  table_column_cache_ready : Ref[Array[Bool]]
  table_values_cache : Ref[Array[@any.Any?]]
  table_values_cache_ready : Ref[Array[Bool]]
}

///|
pub fn[T] World::component_column(
  self : World,
  key : ComponentKey[T],
) -> ComponentColumn[T]? {
  match self.local_component_id(key.id()) {
    Some(local_component_id) =>
      match self.local_component_storage_type(local_component_id) {
        Some(storage_type) =>
          Some({
            world: self,
            key,
            local_component_id,
            storage_type,
            table_column_cache: Ref([]),
            table_column_cache_ready: Ref([]),
            table_values_cache: Ref([]),
            table_values_cache_ready: Ref([]),
          })
        None => None
      }
    None => None
  }
}

///|
fn[T] ComponentColumn::table_column_ref(
  self : ComponentColumn[T],
  table_id : Int,
) -> Ref[RawTableColumn]? {
  if table_id < 0 {
    return None
  }
  while self.table_column_cache.val.length() <= table_id {
    self.table_column_cache.val.push(None)
  }
  while self.table_column_cache_ready.val.length() <= table_id {
    self.table_column_cache_ready.val.push(false)
  }
  if self.table_column_cache_ready.val[table_id] {
    return match self.table_column_cache.val[table_id] {
      Some(column_any) => Some(column_any.unsafe_coerce())
      None => None
    }
  }
  self.table_column_cache_ready.val[table_id] = true
  match self.world.table_storage(table_id) {
    Some(table_ref) =>
      match table_ref.val.column(self.local_component_id) {
        Some(column_ref) => {
          self.table_column_cache.val[table_id] = Some(@any.of(column_ref))
          Some(column_ref)
        }
        None => None
      }
    None => None
  }
}

///|
fn[T] ComponentColumn::table_values_ref(
  self : ComponentColumn[T],
  table_id : Int,
) -> Array[T]? {
  if table_id < 0 {
    return None
  }
  while self.table_values_cache.val.length() <= table_id {
    self.table_values_cache.val.push(None)
  }
  while self.table_values_cache_ready.val.length() <= table_id {
    self.table_values_cache_ready.val.push(false)
  }
  if self.table_values_cache_ready.val[table_id] {
    return match self.table_values_cache.val[table_id] {
      Some(values_any) => Some(values_any.unsafe_coerce())
      None => None
    }
  }
  self.table_values_cache_ready.val[table_id] = true
  guard self.table_column_ref(table_id) is Some(column_ref) else { return None }
  match column_ref.val.values_cached() {
    Some(values) => {
      self.table_values_cache.val[table_id] = Some(@any.of(values))
      Some(values)
    }
    None => None
  }
}

///|
pub fn[T] ComponentColumn::contains(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Bool {
  match self.world.pending_component_payload_context {
    Some(_) =>
      if self.world.pending_component_payload(entity, self.local_component_id)
        is Some(_) {
        return true
      }
    None => ()
  }
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) => store_ref.val.contains(entity)
        None => false
      }
    Table => {
      let entity_id = entity.id
      guard entity_id >= 0 &&
        entity_id < self.world.entity_table_ids.length() &&
        entity_id < self.world.entity_table_rows.length() else {
        return false
      }
      let table_id = self.world.entity_table_ids[entity_id]
      let row_index = self.world.entity_table_rows[entity_id]
      guard table_id >= 0 && row_index >= 0 else { return false }
      match self.table_values_ref(table_id) {
        Some(values) => row_index < values.length()
        None => false
      }
    }
  }
}

///|
pub fn[T] ComponentColumn::get(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> T? {
  match self.world.pending_component_payload_context {
    Some(_) =>
      if self.world.pending_component_payload(entity, self.local_component_id)
        is Some(payload) {
        let result : Result[T, @any.TypeMismatch] = try? payload.to_value()
        return match result {
          Ok(value) => Some(value)
          Err(_) => None
        }
      }
    None => ()
  }
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) =>
          match store_ref.val.get(entity) {
            Some(payload) => {
              let result : Result[T, @any.TypeMismatch] = try? payload.to_value()
              match result {
                Ok(value) => Some(value)
                Err(_) => None
              }
            }
            None => None
          }
        None => None
      }
    Table => {
      let entity_id = entity.id
      guard entity_id >= 0 &&
        entity_id < self.world.entity_table_ids.length() &&
        entity_id < self.world.entity_table_rows.length() else {
        return None
      }
      let table_id = self.world.entity_table_ids[entity_id]
      let row_index = self.world.entity_table_rows[entity_id]
      guard table_id >= 0 && row_index >= 0 else { return None }
      guard self.table_values_ref(table_id) is Some(values) else { return None }
      if row_index < 0 || row_index >= values.length() {
        None
      } else {
        Some(values[row_index])
      }
    }
  }
}

///|
pub fn[T] ComponentColumn::get_fast(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> T? {
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) =>
          match store_ref.val.get(entity) {
            Some(payload) => {
              let result : Result[T, @any.TypeMismatch] = try? payload.to_value()
              match result {
                Ok(value) => Some(value)
                Err(_) => None
              }
            }
            None => None
          }
        None => None
      }
    Table => {
      let entity_id = entity.id
      guard entity_id >= 0 &&
        entity_id < self.world.entity_table_ids.length() &&
        entity_id < self.world.entity_table_rows.length() else {
        return None
      }
      let table_id = self.world.entity_table_ids[entity_id]
      let row_index = self.world.entity_table_rows[entity_id]
      guard table_id >= 0 && row_index >= 0 else { return None }
      guard self.table_values_ref(table_id) is Some(values) else { return None }
      if row_index >= values.length() {
        None
      } else {
        Some(values[row_index])
      }
    }
  }
}

///|
pub fn[T] ComponentColumn::table_values(
  self : ComponentColumn[T],
  table_id : Int,
) -> Array[T]? {
  guard self.storage_type == Table else { return None }
  self.table_values_ref(table_id)
}

///|
pub fn[T] ComponentColumn::table_value_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.storage_type == Table else { return None }
  guard self.table_values_ref(table_id) is Some(values) else { return None }
  if row_index < 0 || row_index >= values.length() {
    None
  } else {
    Some(values[row_index])
  }
}

///|
pub fn[T] ComponentColumn::table_row_location(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> (Int, Int)? {
  guard self.storage_type == Table else { return None }
  let entity_id = entity.id
  guard entity_id >= 0 &&
    entity_id < self.world.entity_table_ids.length() &&
    entity_id < self.world.entity_table_rows.length() else {
    return None
  }
  let table_id = self.world.entity_table_ids[entity_id]
  let row_index = self.world.entity_table_rows[entity_id]
  guard table_id >= 0 && row_index >= 0 else { return None }
  guard self.table_values_ref(table_id) is Some(values) else { return None }
  guard row_index < values.length() else { return None }
  Some((table_id, row_index))
}

///|
pub fn[T] ComponentColumn::table_value_at_entity_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.storage_type == Table else { return None }
  guard TableRow::from_index(row_index) is Some(row) else { return None }
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return None
  }
  guard table_ref.val.entity_at_row(row) is Some(row_entity) else {
    return None
  }
  guard row_entity.to_bits() == entity.to_bits() else { return None }
  guard self.table_values_ref(table_id) is Some(values) else { return None }
  if row_index < 0 || row_index >= values.length() {
    None
  } else {
    Some(values[row_index])
  }
}

///|
pub fn[T] ComponentColumn::table_value_at_cached_entity_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.storage_type == Table else { return None }
  self.table_value_in_cached_values_at_entity_row(
    entity,
    table_id,
    row_index,
    match self.table_values_ref(table_id) {
      Some(values) => values
      None => return None
    },
  )
}

///|
pub fn[T] ComponentColumn::table_value_in_cached_values_at_entity_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
  values : Array[T],
) -> T? {
  guard self.storage_type == Table else { return None }
  let entity_id = entity.id
  guard entity_id >= 0 &&
    entity_id < self.world.entity_table_ids.length() &&
    entity_id < self.world.entity_table_rows.length() else {
    return None
  }
  if self.world.entity_table_ids[entity_id] != table_id ||
    self.world.entity_table_rows[entity_id] != row_index {
    return None
  }
  if row_index < 0 || row_index >= values.length() {
    None
  } else {
    Some(values[row_index])
  }
}

///|
pub fn[T] ComponentColumn::table_changed_sequence_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
) -> @core.Sequence? {
  guard self.storage_type == Table else { return None }
  guard self.table_column_ref(table_id) is Some(column_ref) else { return None }
  column_ref.val.changed_sequence_at_row(row_index)
}

///|
pub fn[T] ComponentColumn::table_is_changed_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
  system_sequence : @core.SystemSequence,
) -> Bool {
  match self.table_changed_sequence_at_row(table_id, row_index) {
    Some(sequence) => system_sequence.contains(sequence)
    None => false
  }
}

///|
pub fn[T] ComponentColumn::table_is_changed_at_entity_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
  system_sequence : @core.SystemSequence,
) -> Bool? {
  guard self.storage_type == Table else { return None }
  guard TableRow::from_index(row_index) is Some(row) else { return None }
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return None
  }
  guard table_ref.val.entity_at_row(row) is Some(row_entity) else {
    return None
  }
  guard row_entity.to_bits() == entity.to_bits() else { return None }
  Some(self.table_is_changed_at_row(table_id, row_index, system_sequence))
}

///|
pub fn[T] ComponentColumn::for_each_changed_table_entity(
  self : ComponentColumn[T],
  system_sequence : @core.SystemSequence,
  visit : (@core.Entity, Int, Int) -> Bool,
) -> Bool {
  guard self.storage_type == Table else { return true }
  for entry in self.world.tables.iter() {
    let (table_id, table_ref) = entry
    guard self.table_column_ref(table_id) is Some(column_ref) else { continue }
    let row_count = table_ref.val.row_count()
    for row_index in 0..<row_count {
      let changed = match column_ref.val.changed_sequence_at_row(row_index) {
        Some(sequence) => system_sequence.contains(sequence)
        None => false
      }
      if !changed {
        continue
      }
      guard TableRow::from_index(row_index) is Some(row) else { continue }
      guard table_ref.val.entity_at_row(row) is Some(entity) else { continue }
      if !visit(entity, table_id, row_index) {
        return false
      }
    }
  }
  true
}

///|
pub fn[T] ComponentColumn::get_mut(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Mut[T]? {
  if self.contains(entity) {
    Some({
      world: Some(self.world),
      entity: Some(entity),
      key: Some(self.key),
      table_id: self.world.table_id_for_entity(entity),
      row_index: match self.world.entity_table_row(entity) {
        Some(row) => Some(row.index())
        None => None
      },
      local_component_id: Some(self.local_component_id),
    })
  } else {
    None
  }
}

///|
pub fn[T] ComponentColumn::for_each(
  self : ComponentColumn[T],
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) =>
          store_ref.val.for_each(fn(entity, payload) {
            let result : Result[T, @any.TypeMismatch] = try? payload.to_value()
            match result {
              Ok(value) => visit(entity, value)
              Err(_) => ()
            }
          })
        None => ()
      }
    Table => {
      let archetype_ids = self.world
        .archetype_ids_for_component_local_id(self.local_component_id)
        .copy()
      for archetype_id in archetype_ids {
        guard self.world.archetype_entities_view(archetype_id) is Some(entities) else {
          continue
        }
        guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
          continue
        }
        let entity_snapshot = entities.copy()
        guard self.table_values_ref(table_id) is Some(values) else { continue }
        for entity in entity_snapshot {
          let entity_id = entity.id
          if entity_id < 0 || entity_id >= self.world.entity_table_rows.length() {
            continue
          }
          let row_index = self.world.entity_table_rows[entity_id]
          if row_index < 0 || row_index >= values.length() {
            continue
          }
          visit(entity, values[row_index])
        }
      }
    }
  }
}

///|
pub fn[T, U] ComponentColumn::for_each_without(
  self : ComponentColumn[T],
  other : ComponentColumn[U],
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  if self.world.world_id != other.world.world_id {
    self.for_each(fn(entity, value) {
      if !other.contains(entity) {
        visit(entity, value)
      }
    })
    return
  }
  if self.storage_type != Table || other.storage_type != Table {
    self.for_each(fn(entity, value) {
      if !other.contains(entity) {
        visit(entity, value)
      }
    })
    return
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(self.local_component_id)
    .copy()
  for archetype_id in archetype_ids {
    if self.world.archetype_component_local_index(
        archetype_id,
        other.local_component_id,
      )
      is Some(_) {
      continue
    }
    guard self.world.archetype_entities_view(archetype_id) is Some(entities) else {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    guard self.table_column_ref(table_id) is Some(column_ref) else { continue }
    let entity_snapshot = entities.copy()
    guard column_ref.val.values_cached() is Some(values) else { continue }
    for entity in entity_snapshot {
      guard self.world.entity_table_row(entity) is Some(row) else { continue }
      let row_index = row.index()
      if row_index < 0 || row_index >= values.length() {
        continue
      }
      visit(entity, values[row_index])
    }
  }
}

///|
pub fn[T, U] ComponentColumn::for_each_with(
  self : ComponentColumn[T],
  other : ComponentColumn[U],
  visit : (@core.Entity, T, U) -> Unit,
) -> Unit {
  if self.world.world_id != other.world.world_id {
    self.for_each(fn(entity, value) {
      guard other.get(entity) is Some(other_value) else { return }
      visit(entity, value, other_value)
    })
    return
  }
  if self.storage_type != Table || other.storage_type != Table {
    self.for_each(fn(entity, value) {
      guard other.get(entity) is Some(other_value) else { return }
      visit(entity, value, other_value)
    })
    return
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(self.local_component_id)
    .copy()
  for archetype_id in archetype_ids {
    guard self.world.archetype_component_local_index(
        archetype_id,
        other.local_component_id,
      )
      is Some(_) else {
      continue
    }
    guard self.world.archetype_entities_view(archetype_id) is Some(entities) else {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    guard self.table_column_ref(table_id) is Some(left_column_ref) else {
      continue
    }
    guard other.table_column_ref(table_id) is Some(right_column_ref) else {
      continue
    }
    let entity_snapshot = entities.copy()
    guard left_column_ref.val.values_cached() is Some(left_values) else {
      continue
    }
    guard right_column_ref.val.values_cached() is Some(right_values) else {
      continue
    }
    for entity in entity_snapshot {
      guard self.world.entity_table_row(entity) is Some(row) else { continue }
      let row_index = row.index()
      if row_index < 0 ||
        row_index >= left_values.length() ||
        row_index >= right_values.length() {
        continue
      }
      visit(entity, left_values[row_index], right_values[row_index])
    }
  }
}

///|
pub fn[T, U] ComponentColumn::for_each_without_fast(
  self : ComponentColumn[T],
  other : ComponentColumn[U],
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  if self.world.world_id != other.world.world_id {
    self.for_each_without(other, visit)
    return
  }
  if self.storage_type != Table || other.storage_type != Table {
    self.for_each_without(other, visit)
    return
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(self.local_component_id)
    .copy()
  for archetype_id in archetype_ids {
    if self.world.archetype_component_local_index(
        archetype_id,
        other.local_component_id,
      )
      is Some(_) {
      continue
    }
    guard self.world.archetype_entities_view(archetype_id) is Some(entities) else {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    guard self.table_column_ref(table_id) is Some(column_ref) else { continue }
    guard column_ref.val.values_cached() is Some(values) else { continue }
    for entity in entities {
      let entity_id = entity.id
      if entity_id < 0 || entity_id >= self.world.entity_table_rows.length() {
        continue
      }
      let row_index = self.world.entity_table_rows[entity_id]
      if row_index < 0 || row_index >= values.length() {
        continue
      }
      visit(entity, values[row_index])
    }
  }
}

///|
pub fn[T, U] ComponentColumn::for_each_with_fast(
  self : ComponentColumn[T],
  other : ComponentColumn[U],
  visit : (@core.Entity, T, U) -> Unit,
) -> Unit {
  if self.world.world_id != other.world.world_id {
    self.for_each_with(other, visit)
    return
  }
  if self.storage_type != Table || other.storage_type != Table {
    self.for_each_with(other, visit)
    return
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(self.local_component_id)
    .copy()
  for archetype_id in archetype_ids {
    guard self.world.archetype_component_local_index(
        archetype_id,
        other.local_component_id,
      )
      is Some(_) else {
      continue
    }
    guard self.world.archetype_entities_view(archetype_id) is Some(entities) else {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    guard self.table_column_ref(table_id) is Some(left_column_ref) else {
      continue
    }
    guard other.table_column_ref(table_id) is Some(right_column_ref) else {
      continue
    }
    guard left_column_ref.val.values_cached() is Some(left_values) else {
      continue
    }
    guard right_column_ref.val.values_cached() is Some(right_values) else {
      continue
    }
    for entity in entities {
      let entity_id = entity.id
      if entity_id < 0 || entity_id >= self.world.entity_table_rows.length() {
        continue
      }
      let row_index = self.world.entity_table_rows[entity_id]
      if row_index < 0 ||
        row_index >= left_values.length() ||
        row_index >= right_values.length() {
        continue
      }
      visit(entity, left_values[row_index], right_values[row_index])
    }
  }
}

///|
pub fn[T] ComponentColumn::set(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  if !self.set_sequence_only(entity, value) {
    return false
  }
  self.world.ensure_changed_component_messages(self.key.id()).val.send(
    component_write_sequence(self.world),
    entity,
  )
  true
}

///|
pub fn[T] ComponentColumn::set_sequence_only(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let sequence = component_write_sequence(self.world)
  match self.world.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(self.local_component_id) is Some(_) {
        context.payloads.set(
          self.local_component_id,
          erased_writer(self.key, value),
        )
        ignore(
          self.world.record_pending_component_changed_metadata(
            entity,
            self.local_component_id,
            sequence,
            None,
          ),
        )
        return true
      }
    None => ()
  }
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) => {
          guard store_ref.val.set(entity, erased_value(value)) else {
            return false
          }
          ignore(
            self.world.record_sparse_component_changed_by_local_id(
              entity,
              self.local_component_id,
              sequence,
              None,
            ),
          )
          true
        }
        None => false
      }
    Table => {
      guard self.world.table_id_for_entity(entity) is Some(table_id) else {
        return false
      }
      guard self.world.entity_table_row(entity) is Some(row) else {
        return false
      }
      guard self.table_column_ref(table_id) is Some(column_ref) else {
        return false
      }
      let row_index = row.index()
      guard column_ref.val.replace_writer_at_row(
        row_index,
        erased_writer(self.key, value),
      ) else {
        return false
      }
      guard self.world.table_storage(table_id) is Some(table_ref) else {
        return false
      }
      ignore(
        table_ref.val.record_changed_at_row(
          row,
          self.local_component_id,
          sequence,
          None,
        ),
      )
      true
    }
  }
}

///|
pub fn[T] ComponentColumn::set_sequence_only_fast(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let sequence = component_write_sequence(self.world)
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) => {
          guard store_ref.val.set(entity, erased_value(value)) else {
            return false
          }
          ignore(
            self.world.record_sparse_component_changed_by_local_id(
              entity,
              self.local_component_id,
              sequence,
              None,
            ),
          )
          true
        }
        None => false
      }
    Table => {
      let entity_id = entity.id
      guard entity_id >= 0 &&
        entity_id < self.world.entity_table_ids.length() &&
        entity_id < self.world.entity_table_rows.length() else {
        return false
      }
      let table_id = self.world.entity_table_ids[entity_id]
      let row_index = self.world.entity_table_rows[entity_id]
      guard table_id >= 0 && row_index >= 0 else { return false }
      guard self.table_column_ref(table_id) is Some(column_ref) else {
        return false
      }
      guard column_ref.val.replace_writer_at_row(
        row_index,
        erased_writer(self.key, value),
      ) else {
        return false
      }
      ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
      true
    }
  }
}

///|
pub fn[T] ComponentColumn::set_sequence_only_hot(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let sequence = component_write_sequence(self.world)
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) => {
          guard store_ref.val.set(entity, erased_value(value)) else {
            return false
          }
          ignore(
            self.world.record_sparse_component_changed_by_local_id(
              entity,
              self.local_component_id,
              sequence,
              None,
            ),
          )
          true
        }
        None => false
      }
    Table => {
      let entity_id = entity.id
      guard entity_id >= 0 &&
        entity_id < self.world.entity_table_ids.length() &&
        entity_id < self.world.entity_table_rows.length() else {
        return false
      }
      let table_id = self.world.entity_table_ids[entity_id]
      let row_index = self.world.entity_table_rows[entity_id]
      guard table_id >= 0 && row_index >= 0 else { return false }
      guard self.table_column_ref(table_id) is Some(column_ref) else {
        return false
      }
      guard column_ref.val.replace_writer_at_row(
        row_index,
        erased_writer(self.key, value),
      ) else {
        return false
      }
      ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
      true
    }
  }
}

///|
pub fn[T] ComponentColumn::set_sequence_only_hot_at_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  values : Array[T],
  row_index : Int,
  value : T,
  sequence : @core.Sequence,
) -> Bool {
  guard self.storage_type == Table else { return false }
  if row_index < 0 || row_index >= values.length() {
    return false
  }
  values[row_index] = value
  let entity_id = entity.id
  guard entity_id >= 0 && entity_id < self.world.entity_table_ids.length() else {
    return false
  }
  let table_id = self.world.entity_table_ids[entity_id]
  guard table_id >= 0 else { return false }
  guard self.table_column_ref(table_id) is Some(column_ref) else {
    return false
  }
  guard column_ref.val.replace_writer_at_row(
    row_index,
    erased_writer(self.key, value),
  ) else {
    return false
  }
  ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
  true
}

///|
pub fn[T] ComponentColumn::set_sequence_only_hot_at_table_row(
  self : ComponentColumn[T],
  table_id : Int,
  values : Array[T],
  row_index : Int,
  value : T,
  sequence : @core.Sequence,
) -> Bool {
  guard self.storage_type == Table else { return false }
  if row_index < 0 || row_index >= values.length() {
    return false
  }
  values[row_index] = value
  guard table_id >= 0 else { return false }
  guard self.table_column_ref(table_id) is Some(column_ref) else {
    return false
  }
  guard column_ref.val.replace_writer_at_row(
    row_index,
    erased_writer(self.key, value),
  ) else {
    return false
  }
  ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
  true
}

///|
pub fn[T] ComponentColumn::set_sequence_only_hot_at_table_row_value(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
  value : T,
  sequence : @core.Sequence,
) -> Bool {
  guard self.storage_type == Table else { return false }
  guard table_id >= 0 && row_index >= 0 else { return false }
  guard self.table_column_ref(table_id) is Some(column_ref) else {
    return false
  }
  guard column_ref.val.replace_writer_at_row(
    row_index,
    erased_writer(self.key, value),
  ) else {
    return false
  }
  ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
  true
}

///|
pub fn[T] ComponentColumn::record_changed_hot_at_table_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
  sequence : @core.Sequence,
) -> Bool {
  guard self.storage_type == Table else { return false }
  guard table_id >= 0 && row_index >= 0 else { return false }
  guard self.table_column_ref(table_id) is Some(column_ref) else {
    return false
  }
  ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
  true
}
