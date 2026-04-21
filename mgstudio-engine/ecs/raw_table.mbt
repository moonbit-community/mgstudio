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
priv struct RawTableColumn {
  mut values : Array[ErasedValue]
}

///|
struct RawTable {
  component_local_ids : Array[Int]
  component_indices : Map[Int, Int]
  rows : RawTableRowKernel
  columns : Array[Ref[RawTableColumn]]
}

///|
priv struct RawTableSwapRemoveResult {
  removed_entity : @core.Entity
  swapped_entity : @core.Entity?
  swapped_row : TableRow?
}

///|
fn raw_table_column_new() -> RawTableColumn {
  { values: [] }
}

///|
fn raw_table_new(component_local_ids : Array[Int]) -> RawTable {
  let component_indices : Map[Int, Int] = {}
  let columns : Array[Ref[RawTableColumn]] = []
  for index in 0..<component_local_ids.length() {
    component_indices.set(component_local_ids[index], index)
    columns.push(Ref::new(raw_table_column_new()))
  }
  {
    component_local_ids: component_local_ids.copy(),
    component_indices,
    rows: raw_table_row_kernel_new(),
    columns,
  }
}

///|
fn RawTable::row_count(self : RawTable) -> Int {
  raw_table_row_kernel_len(self.rows)
}

///|
fn RawTable::component_index(self : RawTable, component_local_id : Int) -> Int? {
  self.component_indices.get(component_local_id)
}

///|
fn RawTable::entity_at_row(self : RawTable, row : TableRow) -> @core.Entity? {
  raw_table_row_kernel_entity_at(self.rows, row.index())
}

///|
fn RawTable::payload_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> ErasedValue? {
  guard self.component_index(component_local_id) is Some(component_index) else {
    return None
  }
  let row_index = row.index()
  let values = self.columns[component_index].val.values
  if row_index < 0 || row_index >= values.length() {
    return None
  }
  Some(values[row_index])
}

///|
fn RawTable::replace_payload_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  payload : ErasedValue,
) -> Bool {
  guard self.component_index(component_local_id) is Some(component_index) else {
    return false
  }
  let row_index = row.index()
  let values = self.columns[component_index].val.values
  if row_index < 0 || row_index >= values.length() {
    return false
  }
  values[row_index] = payload
  true
}

///|
fn RawTable::append_row(
  self : RawTable,
  entity : @core.Entity,
  ordered_payloads : Array[ErasedValue],
) -> TableRow? {
  if ordered_payloads.length() != self.columns.length() {
    return None
  }
  let row = raw_table_row_kernel_push(self.rows, entity)
  for column_index in 0..<self.columns.length() {
    self.columns[column_index].val.values.push(ordered_payloads[column_index])
  }
  TableRow::from_index(row)
}

///|
fn raw_table_column_swap_remove(
  column_ref : Ref[RawTableColumn],
  row_index : Int,
) -> Bool {
  let values = column_ref.val.values
  if row_index < 0 || row_index >= values.length() {
    return false
  }
  let last_index = values.length() - 1
  if row_index != last_index {
    values[row_index] = values[last_index]
  }
  ignore(values.pop())
  true
}

///|
fn RawTable::swap_remove_row(
  self : RawTable,
  row : TableRow,
) -> RawTableSwapRemoveResult? {
  let row_index = row.index()
  let len = self.row_count()
  if row_index < 0 || row_index >= len {
    return None
  }
  let removed_entity = match self.entity_at_row(row) {
    Some(entity) => entity
    None => return None
  }
  let last_row_index = len - 1
  let swapped_entity = if row_index == last_row_index {
    None
  } else {
    raw_table_row_kernel_entity_at(self.rows, last_row_index)
  }
  for column_ref in self.columns {
    ignore(raw_table_column_swap_remove(column_ref, row_index))
  }
  guard raw_table_row_kernel_swap_remove(self.rows, row_index) else {
    return None
  }
  Some({
    removed_entity,
    swapped_entity,
    swapped_row: if row_index == last_row_index {
      None
    } else {
      TableRow::from_index(row_index)
    },
  })
}

///|
fn World::ensure_table_storage(self : World, table_id : Int) -> Ref[RawTable] {
  let component_local_ids = self.table_component_local_ids
    .get(table_id)
    .unwrap_or([])
  self.tables.get_or_init(table_id, fn() {
    Ref::new(raw_table_new(component_local_ids))
  })
}

///|
fn World::table_storage(self : World, table_id : Int) -> Ref[RawTable]? {
  self.tables.get(table_id)
}

///|
fn World::pending_component_payload(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id {
        context.payloads.get(local_component_id)
      } else {
        None
      }
    None => None
  }
}

///|
fn World::push_pending_component_payload_context(
  self : World,
  entity : @core.Entity,
  payloads : Map[Int, ErasedValue],
) -> PendingComponentPayloadContext? {
  let previous = self.pending_component_payload_context
  self.pending_component_payload_context = Some({
    entity_id: entity.id,
    payloads,
  })
  previous
}

///|
fn World::restore_pending_component_payload_context(
  self : World,
  previous : PendingComponentPayloadContext?,
) -> Unit {
  self.pending_component_payload_context = previous
}

///|
fn World::table_id_for_entity(self : World, entity : @core.Entity) -> Int? {
  guard entity.id >= 0 && entity.id < self.entity_archetype_ids.length() else {
    return None
  }
  let archetype_id = self.entity_archetype_ids[entity.id]
  if archetype_id < 0 {
    return None
  }
  self.archetype_table_ids.get(archetype_id)
}

///|
fn World::entity_table_row(self : World, entity : @core.Entity) -> TableRow? {
  guard entity.id >= 0 && entity.id < self.entity_table_rows.length() else {
    return None
  }
  TableRow::from_index(self.entity_table_rows[entity.id])
}

///|
fn World::component_payload_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  if self.pending_component_payload(entity, local_component_id) is Some(payload) {
    return Some(payload)
  }
  match self.local_component_storage_type(local_component_id) {
    Some(SparseSet) =>
      match self.sparse_component_columns.get(local_component_id) {
        Some(store_ref) => store_ref.val.get(entity)
        None => None
      }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return None
      }
      guard self.table_storage(table_id) is Some(table_ref) else { return None }
      guard self.entity_table_row(entity) is Some(row) else { return None }
      table_ref.val.payload_at_row(row, local_component_id)
    }
    None => None
  }
}

///|
fn World::component_payload(
  self : World,
  component_definition_id : Int,
  entity : @core.Entity,
) -> ErasedValue? {
  match self.local_component_id(component_definition_id) {
    Some(local_component_id) =>
      self.component_payload_by_local_id(entity, local_component_id)
    None => None
  }
}

///|
fn World::replace_component_payload_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  payload : ErasedValue,
) -> Bool {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(local_component_id) is Some(_) {
        context.payloads.set(local_component_id, payload)
        return true
      }
    None => ()
  }
  match self.local_component_storage_type(local_component_id) {
    Some(SparseSet) => {
      let store_ref = self.ensure_component_store_for_local_id(
        local_component_id,
        SparseSet,
      )
      store_ref.val.set(entity, payload)
    }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return false
      }
      guard self.table_storage(table_id) is Some(table_ref) else {
        return false
      }
      guard self.entity_table_row(entity) is Some(row) else { return false }
      table_ref.val.replace_payload_at_row(row, local_component_id, payload)
    }
    None => false
  }
}

///|
fn World::replace_component_payload(
  self : World,
  component_definition_id : Int,
  entity : @core.Entity,
  payload : ErasedValue,
) -> Bool {
  match self.local_component_id(component_definition_id) {
    Some(local_component_id) =>
      self.replace_component_payload_by_local_id(
        entity, local_component_id, payload,
      )
    None => false
  }
}

///|
fn World::remove_sparse_component_payload_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return None
  }
  match self.sparse_component_columns.get(local_component_id) {
    Some(store_ref) => store_ref.val.remove(entity)
    None => None
  }
}

///|
fn World::write_pending_sparse_component_payloads(
  self : World,
  entity : @core.Entity,
  pending_payloads : Map[Int, ErasedValue],
) -> Unit {
  for entry in pending_payloads.iter() {
    let component_local_id = entry.0
    let payload = entry.1
    if self.local_component_storage_type(component_local_id) == Some(SparseSet) {
      let store_ref = self.ensure_component_store_for_local_id(
        component_local_id,
        SparseSet,
      )
      store_ref.val.insert(entity, payload)
    }
  }
}
