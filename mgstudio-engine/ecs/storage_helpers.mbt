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
priv struct TableId {
  raw : Int
}

///|
fn TableId::empty() -> TableId {
  { raw: 0 }
}

///|
fn TableId::from_index(index : Int) -> TableId? {
  if index < 0 {
    None
  } else {
    Some({ raw: index })
  }
}

///|
fn TableId::index(self : TableId) -> Int {
  self.raw
}

///|
priv struct TableRow {
  raw : Int
}

///|
fn TableRow::from_index(index : Int) -> TableRow? {
  if index < 0 {
    None
  } else {
    Some({ raw: index })
  }
}

///|
fn TableRow::index(self : TableRow) -> Int {
  self.raw
}

///|
priv enum ComponentColumnWriteKind {
  Initialized
  Replaced
} derive(Eq)

///|
priv struct ComponentColumnWriteResult {
  kind : ComponentColumnWriteKind
  row : TableRow
}

///|
priv struct StorageSwapRemoveResult[T] {
  removed_entity : @core.Entity
  removed_value : T
  removed_row : TableRow
  swapped_entity : @core.Entity?
  swapped_row : TableRow?
}

///|
priv struct StorageMoveToSupersetResult {
  moved_entity : @core.Entity
  source_row : TableRow
  target_row : TableRow
  source_swapped_entity : @core.Entity?
  source_swapped_row : TableRow?
}

///|
fn table_row_from_index(index : Int) -> TableRow? {
  TableRow::from_index(index)
}

///|
fn[T] sparse_set_row_valid(
  storage : @core.SparseSet[T],
  row : TableRow,
) -> Bool {
  let index = row.index()
  index >= 0 && index < storage.len()
}

///|
fn[T] sparse_set_entry_at_table_row(
  storage : @core.SparseSet[T],
  row : TableRow,
) -> (@core.Entity, T)? {
  guard sparse_set_row_valid(storage, row) else { return None }
  let index = row.index()
  Some((storage.entity_at(index), storage.value_at(index)))
}

///|
fn[T] sparse_set_entry_at_row(
  storage : @core.SparseSet[T],
  row : Int,
) -> (@core.Entity, T)? {
  match table_row_from_index(row) {
    Some(table_row) => sparse_set_entry_at_table_row(storage, table_row)
    None => None
  }
}

///|
fn[T] component_store_len(store_ref : Ref[@core.ComponentStore[T]]) -> Int {
  store_ref.val.storage.len()
}

///|
fn[T] component_store_contains_entity(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> Bool {
  store_ref.val.storage.contains(entity)
}

///|
fn[T] component_store_index_of_entity(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> Int? {
  store_ref.val.storage.index_of(entity)
}

///|
fn[T] component_store_get_entity(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> T? {
  store_ref.val.storage.get(entity)
}

///|
fn[T] component_store_table_row_of_entity(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> TableRow? {
  match component_store_index_of_entity(store_ref, entity) {
    Some(index) => table_row_from_index(index)
    None => None
  }
}

///|
fn[T] component_store_entity_at_table_row(
  store_ref : Ref[@core.ComponentStore[T]],
  row : TableRow,
) -> @core.Entity? {
  match sparse_set_entry_at_table_row(store_ref.val.storage, row) {
    Some(entry) => Some(entry.0)
    None => None
  }
}

///|
fn[T] component_store_value_at_table_row(
  store_ref : Ref[@core.ComponentStore[T]],
  row : TableRow,
) -> T? {
  match sparse_set_entry_at_table_row(store_ref.val.storage, row) {
    Some(entry) => Some(entry.1)
    None => None
  }
}

///|
fn[T] component_store_initialize_column_value(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
  value : T,
) -> TableRow? {
  if component_store_contains_entity(store_ref, entity) {
    return None
  }
  store_ref.val.storage.insert(entity, value)
  component_store_table_row_of_entity(store_ref, entity)
}

///|
fn[T] component_store_replace_column_value(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
  value : T,
) -> TableRow? {
  if !store_ref.val.storage.set(entity, value) {
    return None
  }
  component_store_table_row_of_entity(store_ref, entity)
}

///|
fn[T] component_store_write_column_value(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
  value : T,
) -> ComponentColumnWriteResult? {
  match component_store_replace_column_value(store_ref, entity, value) {
    Some(row) => Some({ kind: Replaced, row })
    None =>
      match component_store_initialize_column_value(store_ref, entity, value) {
        Some(row) => Some({ kind: Initialized, row })
        None => None
      }
  }
}

///|
fn[T] component_store_set_entity(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
  value : T,
) -> Bool {
  component_store_replace_column_value(store_ref, entity, value) is Some(_)
}

///|
fn[T] component_store_entry_at_row(
  store_ref : Ref[@core.ComponentStore[T]],
  row : Int,
) -> (@core.Entity, T)? {
  sparse_set_entry_at_row(store_ref.val.storage, row)
}

///|
fn[T] component_store_snapshot_entries(
  store_ref : Ref[@core.ComponentStore[T]],
) -> Array[(@core.Entity, T)] {
  storage_helpers_keep_move_symbols_alive(store_ref)
  let entries : Array[(@core.Entity, T)] = []
  for row in 0..<store_ref.val.storage.len() {
    match component_store_entry_at_row(store_ref, row) {
      Some(entry) => entries.push(entry)
      None => ()
    }
  }
  entries
}

///|
fn[T] component_store_swap_remove_entity(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> StorageSwapRemoveResult[T]? {
  let storage = store_ref.val.storage
  guard component_store_table_row_of_entity(store_ref, entity)
    is Some(remove_row) else {
    return None
  }
  let remove_row_index = remove_row.index()
  let last_row_index = storage.len() - 1
  let swapped_entity = if remove_row_index == last_row_index {
    None
  } else {
    Some(storage.entity_at(last_row_index))
  }
  let swapped_row = if remove_row_index == last_row_index {
    None
  } else {
    Some(remove_row)
  }
  match store_ref.val.storage.remove(entity) {
    Some(removed_value) =>
      Some({
        removed_entity: entity,
        removed_value,
        removed_row: remove_row,
        swapped_entity,
        swapped_row,
      })
    None => None
  }
}

///|
fn[T] component_store_swap_remove_table_row(
  store_ref : Ref[@core.ComponentStore[T]],
  row : TableRow,
) -> StorageSwapRemoveResult[T]? {
  match component_store_entity_at_table_row(store_ref, row) {
    Some(entity) => component_store_swap_remove_entity(store_ref, entity)
    None => None
  }
}

///|
fn[T] component_store_swap_remove_row(
  store_ref : Ref[@core.ComponentStore[T]],
  row : Int,
) -> StorageSwapRemoveResult[T]? {
  match table_row_from_index(row) {
    Some(table_row) =>
      component_store_swap_remove_table_row(store_ref, table_row)
    None => None
  }
}

///|
fn[T] component_store_move_entity_to_superset(
  source_ref : Ref[@core.ComponentStore[T]],
  target_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> StorageMoveToSupersetResult? {
  match component_store_swap_remove_entity(source_ref, entity) {
    Some(result) => {
      target_ref.val.storage.insert(result.removed_entity, result.removed_value)
      match
        component_store_table_row_of_entity(target_ref, result.removed_entity) {
        Some(target_row) =>
          Some({
            moved_entity: result.removed_entity,
            source_row: result.removed_row,
            target_row,
            source_swapped_entity: result.swapped_entity,
            source_swapped_row: result.swapped_row,
          })
        None => None
      }
    }
    None => None
  }
}

///|
fn[T] component_store_move_table_row_to_superset(
  source_ref : Ref[@core.ComponentStore[T]],
  target_ref : Ref[@core.ComponentStore[T]],
  row : TableRow,
) -> StorageMoveToSupersetResult? {
  match component_store_entity_at_table_row(source_ref, row) {
    Some(entity) =>
      component_store_move_entity_to_superset(source_ref, target_ref, entity)
    None => None
  }
}

///|
fn[T] component_store_move_entity(
  source_ref : Ref[@core.ComponentStore[T]],
  target_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> Bool {
  component_store_move_entity_to_superset(source_ref, target_ref, entity)
  is Some(_)
}

///|
fn[T] component_store_move_row(
  source_ref : Ref[@core.ComponentStore[T]],
  target_ref : Ref[@core.ComponentStore[T]],
  row : Int,
) -> Bool {
  match table_row_from_index(row) {
    Some(table_row) =>
      component_store_move_table_row_to_superset(
        source_ref, target_ref, table_row,
      )
      is Some(_)
    None => false
  }
}

///|
fn[T] storage_helpers_keep_move_symbols_alive(
  store_ref : Ref[@core.ComponentStore[T]],
) -> Unit {
  ignore(TableId::empty())
  ignore(TableId::from_index(-1))
  ignore(component_store_swap_remove_row(store_ref, -1))
  ignore(component_store_move_row(store_ref, store_ref, -1))
}
