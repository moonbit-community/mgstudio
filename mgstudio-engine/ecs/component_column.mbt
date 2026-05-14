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
  priv world : World
  priv key : ComponentKey[T]
  priv local_component_id : Int
  priv storage_type : ComponentStorageType
  priv table_column_cache : Ref[Array[Ref[RawTableColumn]?]]
  priv table_column_cache_ready : @utils.IntBitSet
}

///|
pub struct ComponentTableColumn[T] {
  priv column : Ref[RawTableColumn]
  priv key : ComponentKey[T]
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
            table_column_cache_ready: @utils.IntBitSet::new(),
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
  if self.table_column_cache_ready.contains(table_id) {
    return self.table_column_cache.val[table_id]
  }
  self.table_column_cache_ready.insert(table_id)
  match self.world.table_storage(table_id) {
    Some(table_ref) =>
      match table_ref.val.column(self.local_component_id) {
        Some(column_ref) => {
          self.table_column_cache.val[table_id] = Some(column_ref)
          Some(column_ref)
        }
        None => None
      }
    None => None
  }
}

///|
pub fn[T] ComponentColumn::table_column(
  self : ComponentColumn[T],
  table_id : Int,
) -> ComponentTableColumn[T]? {
  guard self.storage_type == Table else { return None }
  match self.table_column_ref(table_id) {
    Some(column) => Some(ComponentTableColumn::{ column, key: self.key })
    None => None
  }
}

///|
pub fn[T] ComponentTableColumn::key(
  self : ComponentTableColumn[T],
) -> ComponentKey[T] {
  self.key
}

///|
pub fn[T : EcsPayloadCodec] ComponentTableColumn::value_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
) -> T? {
  match
    raw_table_value_column_kernel_value(self.column.val.storage, row_index) {
    Some(payload) => T::from_ecs_payload(payload)
    None => None
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentTableColumn::value_at_row_unchecked(
  self : ComponentTableColumn[T],
  row_index : Int,
) -> T? {
  T::from_ecs_payload(
    raw_table_value_column_kernel_value_unchecked(
      self.column.val.storage,
      row_index,
    ),
  )
}

///|
pub fn[T] ComponentTableColumn::is_changed_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
  system_sequence : @core.SystemSequence,
) -> Bool {
  match self.column.val.changed_sequence_at_row(row_index) {
    Some(sequence) => system_sequence.contains(sequence)
    None => false
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentTableColumn::set_sequence_only_hot_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
  value : T,
  sequence : @core.Sequence,
) -> Bool {
  guard row_index >= 0 else { return false }
  guard self.column.val.replace_typed_payload_at_row(
    row_index,
    T::to_ecs_payload(value),
  ) else {
    return false
  }
  ignore(self.column.val.record_changed_at_row(row_index, sequence, None))
  true
}

///|
pub fn[T] ComponentTableColumn::record_changed_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
  sequence : @core.Sequence,
) -> Bool {
  guard row_index >= 0 else { return false }
  ignore(self.column.val.record_changed_at_row(row_index, sequence, None))
  true
}

///|
fn[T : EcsPayloadCodec] ComponentColumn::table_values_ref(
  self : ComponentColumn[T],
  table_id : Int,
) -> Array[T]? {
  if table_id < 0 {
    return None
  }
  guard self.table_column_ref(table_id) is Some(column_ref) else { return None }
  column_ref.val.values_cached()
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
      if !self.world.entity_has_component_local_id(
          entity,
          self.local_component_id,
        ) {
        return false
      }
      let entity_id = entity.id
      guard entity_id >= 0 &&
        entity_id < self.world.entity_table_ids.length() &&
        entity_id < self.world.entity_table_rows.length() else {
        return false
      }
      let table_id = self.world.entity_table_ids[entity_id]
      let row_index = self.world.entity_table_rows[entity_id]
      guard table_id >= 0 && row_index >= 0 else { return false }
      match self.table_column_ref(table_id) {
        Some(column_ref) =>
          row_index < raw_table_value_column_kernel_len(column_ref.val.storage)
        None => false
      }
    }
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::get(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> T? {
  match self.world.pending_component_payload_context {
    Some(_) =>
      if self.world.pending_component_payload(entity, self.local_component_id)
        is Some(payload) {
        return T::from_ecs_payload(payload)
      }
    None => ()
  }
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) =>
          match store_ref.val.get(entity) {
            Some(payload) => T::from_ecs_payload(payload)
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
      guard self.table_column_ref(table_id) is Some(column_ref) else {
        return None
      }
      column_ref.val.value_at_row(row_index)
    }
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::get_fast(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> T? {
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) =>
          match store_ref.val.get(entity) {
            Some(payload) => T::from_ecs_payload(payload)
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
      guard self.table_column_ref(table_id) is Some(column_ref) else {
        return None
      }
      column_ref.val.value_at_row(row_index)
    }
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::table_values(
  self : ComponentColumn[T],
  table_id : Int,
) -> Array[T]? {
  guard self.storage_type == Table else { return None }
  self.table_values_ref(table_id)
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::table_value_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.storage_type == Table else { return None }
  guard row_index >= 0 else { return None }
  guard self.table_column_ref(table_id) is Some(column_ref) else { return None }
  column_ref.val.value_at_row(row_index)
}

///|
pub fn[T] ComponentColumn::table_has_value_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
) -> Bool {
  guard self.storage_type == Table else { return false }
  guard row_index >= 0 else { return false }
  guard self.table_column_ref(table_id) is Some(column_ref) else {
    return false
  }
  row_index < raw_table_value_column_kernel_len(column_ref.val.storage)
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
  guard self.table_column_ref(table_id) is Some(column_ref) else { return None }
  guard row_index < raw_table_value_column_kernel_len(column_ref.val.storage) else {
    return None
  }
  Some((table_id, row_index))
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::table_value_at_entity_row(
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
  guard self.table_column_ref(table_id) is Some(column_ref) else { return None }
  column_ref.val.value_at_row(row_index)
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::table_value_at_cached_entity_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.storage_type == Table else { return None }
  let entity_id = entity.id
  guard entity_id >= 0 &&
    entity_id < self.world.entity_table_ids.length() &&
    entity_id < self.world.entity_table_rows.length() else {
    return None
  }
  guard self.world.entity_table_ids[entity_id] == table_id &&
    self.world.entity_table_rows[entity_id] == row_index else {
    return None
  }
  self.table_value_at_row(table_id, row_index)
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
pub fn[T : EcsPayloadCodec] ComponentColumn::for_each(
  self : ComponentColumn[T],
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) =>
          store_ref.val.for_each(fn(entity, payload) {
            match T::from_ecs_payload(payload) {
              Some(value) => visit(entity, value)
              None => ()
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
        guard self.table_column_ref(table_id) is Some(column_ref) else {
          continue
        }
        let entity_snapshot = entities.copy()
        for entity in entity_snapshot {
          let entity_id = entity.id
          if entity_id < 0 || entity_id >= self.world.entity_table_rows.length() {
            continue
          }
          let row_index = self.world.entity_table_rows[entity_id]
          if row_index < 0 {
            continue
          }
          guard column_ref.val.value_at_row(row_index) is Some(value) else {
            continue
          }
          visit(entity, value)
        }
      }
    }
  }
}

///|
pub fn[T : EcsPayloadCodec, U] ComponentColumn::for_each_without(
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
    for entity in entity_snapshot {
      guard self.world.entity_table_row(entity) is Some(row) else { continue }
      let row_index = row.index()
      if row_index < 0 {
        continue
      }
      guard column_ref.val.value_at_row(row_index) is Some(value) else {
        continue
      }
      visit(entity, value)
    }
  }
}

///|
pub fn[T : EcsPayloadCodec, U : EcsPayloadCodec] ComponentColumn::for_each_with(
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
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    guard self.world.archetype_entities_view(archetype_id) is Some(entities) else {
      continue
    }
    guard self.table_column_ref(table_id) is Some(left_column_ref) else {
      continue
    }
    guard other.table_column_ref(table_id) is Some(right_column_ref) else {
      continue
    }
    let entity_snapshot = entities.copy()
    for entity in entity_snapshot {
      guard self.world.entity_table_row(entity) is Some(row) else { continue }
      let row_index = row.index()
      if row_index < 0 {
        continue
      }
      guard left_column_ref.val.value_at_row(row_index) is Some(left_value) else {
        continue
      }
      guard right_column_ref.val.value_at_row(row_index) is Some(right_value) else {
        continue
      }
      visit(entity, left_value, right_value)
    }
  }
}

///|
pub fn[T : EcsPayloadCodec, U] ComponentColumn::for_each_without_fast(
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
  let visited_tables = @utils.IntBitSet::new()
  for archetype_id in archetype_ids {
    if self.world.archetype_component_local_index(
        archetype_id,
        other.local_component_id,
      )
      is Some(_) {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    guard self.table_column_ref(table_id) is Some(column_ref) else { continue }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.val.rows.entities
    let row_count = entities.length()
    if raw_table_value_column_kernel_len(column_ref.val.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard column_ref.val.value_at_row_unchecked(row_index) is Some(value) else {
        continue
      }
      visit(entity, value)
    }
  }
}

///|
pub fn[T : EcsPayloadCodec, U : EcsPayloadCodec] ComponentColumn::for_each_with_fast(
  self : ComponentColumn[T],
  other : ComponentColumn[U],
  visit : (@core.Entity, T, U) -> Unit,
) -> Unit {
  self.for_each_with_fast_table_row(other, fn(
    entity,
    _table_id,
    _row_index,
    left,
    right,
  ) {
    visit(entity, left, right)
  })
}

///|
pub fn[T : EcsPayloadCodec, U : EcsPayloadCodec] ComponentColumn::for_each_with_fast_table_row(
  self : ComponentColumn[T],
  other : ComponentColumn[U],
  visit : (@core.Entity, Int, Int, T, U) -> Unit,
) -> Unit {
  if self.world.world_id != other.world.world_id {
    self.for_each_with(other, fn(entity, left, right) {
      visit(entity, -1, -1, left, right)
    })
    return
  }
  if self.storage_type != Table || other.storage_type != Table {
    self.for_each_with(other, fn(entity, left, right) {
      visit(entity, -1, -1, left, right)
    })
    return
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(self.local_component_id)
    .copy()
  let visited_tables = @utils.IntBitSet::new()
  for archetype_id in archetype_ids {
    guard self.world.archetype_component_local_index(
        archetype_id,
        other.local_component_id,
      )
      is Some(_) else {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    guard self.table_column_ref(table_id) is Some(left_column_ref) else {
      continue
    }
    guard other.table_column_ref(table_id) is Some(right_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.val.rows.entities
    let row_count = entities.length()
    if raw_table_value_column_kernel_len(left_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(right_column_ref.val.storage) <
      row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard left_column_ref.val.value_at_row_unchecked(row_index)
        is Some(left_value) else {
        continue
      }
      guard right_column_ref.val.value_at_row_unchecked(row_index)
        is Some(right_value) else {
        continue
      }
      visit(entity, table_id, row_index, left_value, right_value)
    }
  }
}

///|
pub fn[T : EcsPayloadCodec, U : EcsPayloadCodec, V : EcsPayloadCodec] ComponentColumn::for_each3_fast_table_row(
  self : ComponentColumn[T],
  second : ComponentColumn[U],
  third : ComponentColumn[V],
  visit : (@core.Entity, Int, Int, T, U, V) -> Unit,
) -> Unit {
  if self.world.world_id != second.world.world_id ||
    self.world.world_id != third.world.world_id {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      visit(entity, -1, -1, first_value, second_value, third_value)
    })
    return
  }
  if self.storage_type != Table ||
    second.storage_type != Table ||
    third.storage_type != Table {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      visit(entity, -1, -1, first_value, second_value, third_value)
    })
    return
  }
  let first_count = self.world.component_membership_counts
    .get(self.local_component_id)
    .unwrap_or(0)
  let second_count = self.world.component_membership_counts
    .get(second.local_component_id)
    .unwrap_or(0)
  let third_count = self.world.component_membership_counts
    .get(third.local_component_id)
    .unwrap_or(0)
  let driver_local_component_id = if first_count <= second_count &&
    first_count <= third_count {
    self.local_component_id
  } else if second_count <= third_count {
    second.local_component_id
  } else {
    third.local_component_id
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(driver_local_component_id)
    .copy()
  let visited_tables = @utils.IntBitSet::new()
  for archetype_id in archetype_ids {
    guard self.world.archetype_local_component_presence_view(archetype_id)
      is Some(presence) else {
      continue
    }
    if !presence.contains(self.local_component_id) ||
      !presence.contains(second.local_component_id) ||
      !presence.contains(third.local_component_id) {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    guard self.table_column_ref(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.table_column_ref(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.table_column_ref(table_id) is Some(third_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.val.rows.entities
    let row_count = entities.length()
    if raw_table_value_column_kernel_len(first_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(second_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(third_column_ref.val.storage) <
      row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard first_column_ref.val.value_at_row_unchecked(row_index)
        is Some(first_value) else {
        continue
      }
      guard second_column_ref.val.value_at_row_unchecked(row_index)
        is Some(second_value) else {
        continue
      }
      guard third_column_ref.val.value_at_row_unchecked(row_index)
        is Some(third_value) else {
        continue
      }
      visit(entity, table_id, row_index, first_value, second_value, third_value)
    }
  }
}

///|
pub fn[T : EcsPayloadCodec, U : EcsPayloadCodec, V : EcsPayloadCodec] ComponentColumn::for_each3_fast_table_row_mark_third_changed(
  self : ComponentColumn[T],
  second : ComponentColumn[U],
  third : ComponentColumn[V],
  sequence : @core.Sequence,
  visit : (@core.Entity, Int, Int, T, U, V) -> Bool,
) -> Unit {
  if self.world.world_id != second.world.world_id ||
    self.world.world_id != third.world.world_id {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      ignore(visit(entity, -1, -1, first_value, second_value, third_value))
    })
    return
  }
  if self.storage_type != Table ||
    second.storage_type != Table ||
    third.storage_type != Table {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      ignore(visit(entity, -1, -1, first_value, second_value, third_value))
    })
    return
  }
  let first_count = self.world.component_membership_counts
    .get(self.local_component_id)
    .unwrap_or(0)
  let second_count = self.world.component_membership_counts
    .get(second.local_component_id)
    .unwrap_or(0)
  let third_count = self.world.component_membership_counts
    .get(third.local_component_id)
    .unwrap_or(0)
  let driver_local_component_id = if first_count <= second_count &&
    first_count <= third_count {
    self.local_component_id
  } else if second_count <= third_count {
    second.local_component_id
  } else {
    third.local_component_id
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(driver_local_component_id)
    .copy()
  let visited_tables = @utils.IntBitSet::new()
  for archetype_id in archetype_ids {
    guard self.world.archetype_local_component_presence_view(archetype_id)
      is Some(presence) else {
      continue
    }
    if !presence.contains(self.local_component_id) ||
      !presence.contains(second.local_component_id) ||
      !presence.contains(third.local_component_id) {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    guard self.table_column_ref(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.table_column_ref(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.table_column_ref(table_id) is Some(third_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.val.rows.entities
    let row_count = entities.length()
    if raw_table_value_column_kernel_len(first_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(second_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(third_column_ref.val.storage) <
      row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard first_column_ref.val.value_at_row_unchecked(row_index)
        is Some(first_value) else {
        continue
      }
      guard second_column_ref.val.value_at_row_unchecked(row_index)
        is Some(second_value) else {
        continue
      }
      guard third_column_ref.val.value_at_row_unchecked(row_index)
        is Some(third_value) else {
        continue
      }
      if visit(
          entity, table_id, row_index, first_value, second_value, third_value,
        ) {
        ignore(
          third_column_ref.val.record_changed_at_row(row_index, sequence, None),
        )
      }
    }
  }
}

///|
pub fn[T : EcsPayloadCodec, U : EcsPayloadCodec, M, N] ComponentColumn::for_each2_with2_markers_fast_table_row(
  self : ComponentColumn[T],
  other : ComponentColumn[U],
  marker_a : ComponentColumn[M],
  marker_b : ComponentColumn[N],
  visit : (@core.Entity, Int, Int, T, U) -> Unit,
) -> Unit {
  if self.world.world_id != other.world.world_id ||
    self.world.world_id != marker_a.world.world_id ||
    self.world.world_id != marker_b.world.world_id {
    self.for_each(fn(entity, first_value) {
      guard other.get(entity) is Some(second_value) else { return }
      guard marker_a.contains(entity) && marker_b.contains(entity) else {
        return
      }
      visit(entity, -1, -1, first_value, second_value)
    })
    return
  }
  if self.storage_type != Table ||
    other.storage_type != Table ||
    marker_a.storage_type != Table ||
    marker_b.storage_type != Table {
    self.for_each(fn(entity, first_value) {
      guard other.get(entity) is Some(second_value) else { return }
      guard marker_a.contains(entity) && marker_b.contains(entity) else {
        return
      }
      visit(entity, -1, -1, first_value, second_value)
    })
    return
  }
  let first_count = self.world.component_membership_counts
    .get(self.local_component_id)
    .unwrap_or(0)
  let second_count = self.world.component_membership_counts
    .get(other.local_component_id)
    .unwrap_or(0)
  let marker_a_count = self.world.component_membership_counts
    .get(marker_a.local_component_id)
    .unwrap_or(0)
  let marker_b_count = self.world.component_membership_counts
    .get(marker_b.local_component_id)
    .unwrap_or(0)
  let driver_local_component_id = if first_count <= second_count &&
    first_count <= marker_a_count &&
    first_count <= marker_b_count {
    self.local_component_id
  } else if second_count <= marker_a_count && second_count <= marker_b_count {
    other.local_component_id
  } else if marker_a_count <= marker_b_count {
    marker_a.local_component_id
  } else {
    marker_b.local_component_id
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(driver_local_component_id)
    .copy()
  let visited_tables = @utils.IntBitSet::new()
  for archetype_id in archetype_ids {
    guard self.world.archetype_local_component_presence_view(archetype_id)
      is Some(presence) else {
      continue
    }
    if !presence.contains(self.local_component_id) ||
      !presence.contains(other.local_component_id) ||
      !presence.contains(marker_a.local_component_id) ||
      !presence.contains(marker_b.local_component_id) {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    guard self.table_column_ref(table_id) is Some(first_column_ref) else {
      continue
    }
    guard other.table_column_ref(table_id) is Some(second_column_ref) else {
      continue
    }
    guard marker_a.table_column_ref(table_id) is Some(_) else { continue }
    guard marker_b.table_column_ref(table_id) is Some(_) else { continue }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.val.rows.entities
    let row_count = entities.length()
    if raw_table_value_column_kernel_len(first_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(second_column_ref.val.storage) <
      row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard first_column_ref.val.value_at_row_unchecked(row_index)
        is Some(first_value) else {
        continue
      }
      guard second_column_ref.val.value_at_row_unchecked(row_index)
        is Some(second_value) else {
        continue
      }
      visit(entity, table_id, row_index, first_value, second_value)
    }
  }
}

///|
pub fn[
  T : EcsPayloadCodec,
  U : EcsPayloadCodec,
  V : EcsPayloadCodec,
  W : EcsPayloadCodec,
] ComponentColumn::for_each4_fast_table_row(
  self : ComponentColumn[T],
  second : ComponentColumn[U],
  third : ComponentColumn[V],
  fourth : ComponentColumn[W],
  visit : (@core.Entity, Int, Int, T, U, V, W) -> Unit,
) -> Unit {
  if self.world.world_id != second.world.world_id ||
    self.world.world_id != third.world.world_id ||
    self.world.world_id != fourth.world.world_id {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      guard fourth.get(entity) is Some(fourth_value) else { return }
      visit(
        entity, -1, -1, first_value, second_value, third_value, fourth_value,
      )
    })
    return
  }
  if self.storage_type != Table ||
    second.storage_type != Table ||
    third.storage_type != Table ||
    fourth.storage_type != Table {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      guard fourth.get(entity) is Some(fourth_value) else { return }
      visit(
        entity, -1, -1, first_value, second_value, third_value, fourth_value,
      )
    })
    return
  }
  let first_count = self.world.component_membership_counts
    .get(self.local_component_id)
    .unwrap_or(0)
  let second_count = self.world.component_membership_counts
    .get(second.local_component_id)
    .unwrap_or(0)
  let third_count = self.world.component_membership_counts
    .get(third.local_component_id)
    .unwrap_or(0)
  let fourth_count = self.world.component_membership_counts
    .get(fourth.local_component_id)
    .unwrap_or(0)
  let driver_local_component_id = if first_count <= second_count &&
    first_count <= third_count &&
    first_count <= fourth_count {
    self.local_component_id
  } else if second_count <= third_count && second_count <= fourth_count {
    second.local_component_id
  } else if third_count <= fourth_count {
    third.local_component_id
  } else {
    fourth.local_component_id
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(driver_local_component_id)
    .copy()
  let visited_tables = @utils.IntBitSet::new()
  for archetype_id in archetype_ids {
    guard self.world.archetype_local_component_presence_view(archetype_id)
      is Some(presence) else {
      continue
    }
    if !presence.contains(self.local_component_id) ||
      !presence.contains(second.local_component_id) ||
      !presence.contains(third.local_component_id) ||
      !presence.contains(fourth.local_component_id) {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    guard self.table_column_ref(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.table_column_ref(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.table_column_ref(table_id) is Some(third_column_ref) else {
      continue
    }
    guard fourth.table_column_ref(table_id) is Some(fourth_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.val.rows.entities
    let row_count = entities.length()
    if raw_table_value_column_kernel_len(first_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(second_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(third_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(fourth_column_ref.val.storage) <
      row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard first_column_ref.val.value_at_row_unchecked(row_index)
        is Some(first_value) else {
        continue
      }
      guard second_column_ref.val.value_at_row_unchecked(row_index)
        is Some(second_value) else {
        continue
      }
      guard third_column_ref.val.value_at_row_unchecked(row_index)
        is Some(third_value) else {
        continue
      }
      guard fourth_column_ref.val.value_at_row_unchecked(row_index)
        is Some(fourth_value) else {
        continue
      }
      visit(
        entity, table_id, row_index, first_value, second_value, third_value, fourth_value,
      )
    }
  }
}

///|
pub fn[
  T : EcsPayloadCodec,
  U : EcsPayloadCodec,
  V : EcsPayloadCodec,
  W : EcsPayloadCodec,
  X : EcsPayloadCodec,
] ComponentColumn::for_each5_fast_table_row(
  self : ComponentColumn[T],
  second : ComponentColumn[U],
  third : ComponentColumn[V],
  fourth : ComponentColumn[W],
  fifth : ComponentColumn[X],
  visit : (@core.Entity, Int, Int, T, U, V, W, X) -> Unit,
) -> Unit {
  if self.world.world_id != second.world.world_id ||
    self.world.world_id != third.world.world_id ||
    self.world.world_id != fourth.world.world_id ||
    self.world.world_id != fifth.world.world_id {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      guard fourth.get(entity) is Some(fourth_value) else { return }
      guard fifth.get(entity) is Some(fifth_value) else { return }
      visit(
        entity, -1, -1, first_value, second_value, third_value, fourth_value, fifth_value,
      )
    })
    return
  }
  if self.storage_type != Table ||
    second.storage_type != Table ||
    third.storage_type != Table ||
    fourth.storage_type != Table ||
    fifth.storage_type != Table {
    self.for_each(fn(entity, first_value) {
      guard second.get(entity) is Some(second_value) else { return }
      guard third.get(entity) is Some(third_value) else { return }
      guard fourth.get(entity) is Some(fourth_value) else { return }
      guard fifth.get(entity) is Some(fifth_value) else { return }
      visit(
        entity, -1, -1, first_value, second_value, third_value, fourth_value, fifth_value,
      )
    })
    return
  }
  let first_count = self.world.component_membership_counts
    .get(self.local_component_id)
    .unwrap_or(0)
  let second_count = self.world.component_membership_counts
    .get(second.local_component_id)
    .unwrap_or(0)
  let third_count = self.world.component_membership_counts
    .get(third.local_component_id)
    .unwrap_or(0)
  let fourth_count = self.world.component_membership_counts
    .get(fourth.local_component_id)
    .unwrap_or(0)
  let fifth_count = self.world.component_membership_counts
    .get(fifth.local_component_id)
    .unwrap_or(0)
  let driver_local_component_id = if first_count <= second_count &&
    first_count <= third_count &&
    first_count <= fourth_count &&
    first_count <= fifth_count {
    self.local_component_id
  } else if second_count <= third_count &&
    second_count <= fourth_count &&
    second_count <= fifth_count {
    second.local_component_id
  } else if third_count <= fourth_count && third_count <= fifth_count {
    third.local_component_id
  } else if fourth_count <= fifth_count {
    fourth.local_component_id
  } else {
    fifth.local_component_id
  }
  let archetype_ids = self.world
    .archetype_ids_for_component_local_id(driver_local_component_id)
    .copy()
  let visited_tables = @utils.IntBitSet::new()
  for archetype_id in archetype_ids {
    guard self.world.archetype_local_component_presence_view(archetype_id)
      is Some(presence) else {
      continue
    }
    if !presence.contains(self.local_component_id) ||
      !presence.contains(second.local_component_id) ||
      !presence.contains(third.local_component_id) ||
      !presence.contains(fourth.local_component_id) ||
      !presence.contains(fifth.local_component_id) {
      continue
    }
    guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    guard self.table_column_ref(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.table_column_ref(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.table_column_ref(table_id) is Some(third_column_ref) else {
      continue
    }
    guard fourth.table_column_ref(table_id) is Some(fourth_column_ref) else {
      continue
    }
    guard fifth.table_column_ref(table_id) is Some(fifth_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.val.rows.entities
    let row_count = entities.length()
    if raw_table_value_column_kernel_len(first_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(second_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(third_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(fourth_column_ref.val.storage) <
      row_count ||
      raw_table_value_column_kernel_len(fifth_column_ref.val.storage) <
      row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard first_column_ref.val.value_at_row_unchecked(row_index)
        is Some(first_value) else {
        continue
      }
      guard second_column_ref.val.value_at_row_unchecked(row_index)
        is Some(second_value) else {
        continue
      }
      guard third_column_ref.val.value_at_row_unchecked(row_index)
        is Some(third_value) else {
        continue
      }
      guard fourth_column_ref.val.value_at_row_unchecked(row_index)
        is Some(fourth_value) else {
        continue
      }
      guard fifth_column_ref.val.value_at_row_unchecked(row_index)
        is Some(fifth_value) else {
        continue
      }
      visit(
        entity, table_id, row_index, first_value, second_value, third_value, fourth_value,
        fifth_value,
      )
    }
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::set(
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
pub fn[T : EcsPayloadCodec] ComponentColumn::set_sequence_only(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let sequence = component_write_sequence(self.world)
  match self.world.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.contains(self.local_component_id) {
        context.payloads.set_writer(
          self.local_component_id,
          ecs_payload_writer(self.key, value),
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
          guard store_ref.val.set(entity, T::to_ecs_payload(value)) else {
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
      guard column_ref.val.replace_typed_payload_at_row(
        row_index,
        T::to_ecs_payload(value),
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
pub fn[T : EcsPayloadCodec] ComponentColumn::set_sequence_only_fast(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let sequence = component_write_sequence(self.world)
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) => {
          guard store_ref.val.set(entity, T::to_ecs_payload(value)) else {
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
      guard column_ref.val.replace_typed_payload_at_row(
        row_index,
        T::to_ecs_payload(value),
      ) else {
        return false
      }
      ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
      true
    }
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::set_sequence_only_hot(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let sequence = component_write_sequence(self.world)
  match self.storage_type {
    SparseSet =>
      match self.world.sparse_component_columns.get(self.local_component_id) {
        Some(store_ref) => {
          guard store_ref.val.set(entity, T::to_ecs_payload(value)) else {
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
      guard column_ref.val.replace_typed_payload_at_row(
        row_index,
        T::to_ecs_payload(value),
      ) else {
        return false
      }
      ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
      true
    }
  }
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::set_sequence_only_hot_at_row(
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
  guard column_ref.val.replace_typed_payload_at_row(
    row_index,
    T::to_ecs_payload(value),
  ) else {
    return false
  }
  ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
  true
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::set_sequence_only_hot_at_table_row(
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
  guard column_ref.val.replace_typed_payload_at_row(
    row_index,
    T::to_ecs_payload(value),
  ) else {
    return false
  }
  ignore(column_ref.val.record_changed_at_row(row_index, sequence, None))
  true
}

///|
pub fn[T : EcsPayloadCodec] ComponentColumn::set_sequence_only_hot_at_table_row_value(
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
  guard column_ref.val.replace_typed_payload_at_row(
    row_index,
    T::to_ecs_payload(value),
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
