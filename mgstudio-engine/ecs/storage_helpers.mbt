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
priv struct StorageSwapRemoveResult[T] {
  removed_entity : @core.Entity
  removed_value : T
  swapped_entity : @core.Entity?
}

///|
fn[T] sparse_set_row_valid(storage : @core.SparseSet[T], row : Int) -> Bool {
  row >= 0 && row < storage.len()
}

///|
fn[T] sparse_set_entry_at_row(
  storage : @core.SparseSet[T],
  row : Int,
) -> (@core.Entity, T)? {
  guard sparse_set_row_valid(storage, row) else { return None }
  Some((storage.entity_at(row), storage.value_at(row)))
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
fn[T] component_store_set_entity(
  store_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
  value : T,
) -> Bool {
  store_ref.val.storage.set(entity, value)
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
  guard component_store_index_of_entity(store_ref, entity) is Some(remove_row) else {
    return None
  }
  let last_row = storage.len() - 1
  let swapped_entity = if remove_row == last_row {
    None
  } else {
    Some(storage.entity_at(last_row))
  }
  match store_ref.val.storage.remove(entity) {
    Some(removed_value) =>
      Some({ removed_entity: entity, removed_value, swapped_entity })
    None => None
  }
}

///|
fn[T] component_store_swap_remove_row(
  store_ref : Ref[@core.ComponentStore[T]],
  row : Int,
) -> StorageSwapRemoveResult[T]? {
  match sparse_set_entry_at_row(store_ref.val.storage, row) {
    Some(entry) => component_store_swap_remove_entity(store_ref, entry.0)
    None => None
  }
}

///|
fn[T] component_store_move_entity(
  source_ref : Ref[@core.ComponentStore[T]],
  target_ref : Ref[@core.ComponentStore[T]],
  entity : @core.Entity,
) -> Bool {
  match component_store_swap_remove_entity(source_ref, entity) {
    Some(result) => {
      target_ref.val.storage.insert(result.removed_entity, result.removed_value)
      ignore(result.swapped_entity)
      true
    }
    None => false
  }
}

///|
fn[T] component_store_move_row(
  source_ref : Ref[@core.ComponentStore[T]],
  target_ref : Ref[@core.ComponentStore[T]],
  row : Int,
) -> Bool {
  match sparse_set_entry_at_row(source_ref.val.storage, row) {
    Some(entry) => component_store_move_entity(source_ref, target_ref, entry.0)
    None => false
  }
}

///|
fn[T] storage_helpers_keep_move_symbols_alive(
  store_ref : Ref[@core.ComponentStore[T]],
) -> Unit {
  ignore(component_store_swap_remove_row(store_ref, -1))
  ignore(component_store_move_row(store_ref, store_ref, -1))
}
