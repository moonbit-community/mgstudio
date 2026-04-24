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
fn raw_table_invalid_sequence() -> @core.Sequence {
  -1
}

///|
fn raw_table_store_sequence(sequence : @core.Sequence?) -> @core.Sequence {
  match sequence {
    Some(sequence) => sequence
    None => raw_table_invalid_sequence()
  }
}

///|
fn raw_table_load_sequence(sequence : @core.Sequence) -> @core.Sequence? {
  if sequence < 0 {
    None
  } else {
    Some(sequence)
  }
}

///|
let raw_table_changed_caller_ids : @hashmap.HashMap[String, Int] = @hashmap.HashMap::new()

///|
let raw_table_changed_callers_ref : Ref[Array[String?]] = Ref::new([None])

///|
fn raw_table_store_changed_caller(caller : String?) -> Int {
  match caller {
    Some(caller) =>
      match raw_table_changed_caller_ids.get(caller) {
        Some(id) => id
        None => {
          let id = raw_table_changed_callers_ref.val.length()
          raw_table_changed_caller_ids.set(caller, id)
          raw_table_changed_callers_ref.val.push(Some(caller))
          id
        }
      }
    None => 0
  }
}

///|
fn raw_table_load_changed_caller(caller_id : Int) -> String? {
  if caller_id <= 0 {
    return None
  }
  match raw_table_changed_callers_ref.val.get(caller_id) {
    Some(caller) => caller
    None => None
  }
}

///|
priv struct RawTableColumn {
  component_ops : ComponentOps
  storage : RawTableValueColumnKernel
  mut values_cache : @any.Any?
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
fn raw_table_column_new(
  component_ops : ComponentOps,
) -> RawTableColumn {
  {
    component_ops,
    storage: raw_table_value_column_kernel_new(),
    values_cache: Some((component_ops.new_values)()),
  }
}

///|
fn RawTableColumn::payload_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> ErasedValue? {
  match self.values_cache {
    Some(values) =>
      return (self.component_ops.column_ops.payload_at_row)(values, row_index)
    None => ()
  }
  match raw_table_value_column_kernel_value(self.storage, row_index) {
    Some(value) => Some({ value, })
    None => None
  }
}

///|
fn RawTableColumn::replace_payload_at_row(
  self : RawTableColumn,
  row_index : Int,
  payload : ErasedValue,
) -> Bool {
  match (self.component_ops.column_ops.writer_from_payload)(payload) {
    Some(writer) =>
      self.replace_writer_at_row(row_index, writer)
    None => false
  }
}

///|
fn RawTableColumn::replace_writer_at_row(
  self : RawTableColumn,
  row_index : Int,
  writer : ErasedWriter,
) -> Bool {
  if writer.component_definition_id != self.component_ops.definition_id {
    return false
  }
  guard raw_table_value_column_kernel_replace(
    self.storage,
    row_index,
    writer.to_any(),
  ) else {
    return false
  }
  match self.values_cache {
    Some(values) =>
      (self.component_ops.column_ops.replace_writer_at_row)(
        values,
        row_index,
        writer,
      )
    None => true
  }
}

///|
fn RawTableColumn::append_writer(
  self : RawTableColumn,
  writer : ErasedWriter,
) -> Bool {
  if writer.component_definition_id != self.component_ops.definition_id {
    return false
  }
  guard raw_table_value_column_kernel_push(
    self.storage,
    writer.to_any(),
    raw_table_invalid_sequence(),
    raw_table_invalid_sequence(),
    0,
  ) else {
    return false
  }
  match self.values_cache {
    Some(values) =>
      (self.component_ops.column_ops.append_writer)(values, writer)
    None => true
  }
}

///|
fn RawTableColumn::append_from_row(
  self : RawTableColumn,
  source : RawTableColumn,
  row_index : Int,
) -> Bool {
  match source.payload_at_row(row_index) {
    Some(payload) =>
      match (self.component_ops.column_ops.writer_from_payload)(payload) {
        Some(writer) => self.append_writer(writer)
        None => false
      }
    None => false
  }
}

///|
fn RawTableColumn::append_metadata(self : RawTableColumn) -> Unit {
  ignore(self)
}

///|
fn RawTableColumn::set_metadata_at_row(
  self : RawTableColumn,
  row_index : Int,
  added_sequence : @core.Sequence?,
  changed_sequence : @core.Sequence?,
  changed_caller : String?,
) -> Bool {
  if !raw_table_value_column_kernel_set_metadata(
      self.storage,
      row_index,
      raw_table_store_sequence(added_sequence),
      raw_table_store_sequence(changed_sequence),
      raw_table_store_changed_caller(changed_caller),
    ) {
    return false
  }
  true
}

///|
fn RawTableColumn::added_sequence_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> @core.Sequence? {
  if row_index < 0 ||
    row_index >= raw_table_value_column_kernel_len(self.storage) {
    return None
  }
  raw_table_load_sequence(
    raw_table_value_column_kernel_added(self.storage, row_index),
  )
}

///|
fn RawTableColumn::changed_sequence_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> @core.Sequence? {
  if row_index < 0 ||
    row_index >= raw_table_value_column_kernel_len(self.storage) {
    return None
  }
  raw_table_load_sequence(
    raw_table_value_column_kernel_changed(self.storage, row_index),
  )
}

///|
fn RawTableColumn::changed_caller_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> String? {
  if row_index < 0 ||
    row_index >= raw_table_value_column_kernel_len(self.storage) {
    return None
  }
  raw_table_load_changed_caller(
    raw_table_value_column_kernel_changed_caller_id(self.storage, row_index),
  )
}

///|
fn RawTableColumn::record_added_at_row(
  self : RawTableColumn,
  row_index : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  self.set_metadata_at_row(
    row_index,
    Some(sequence),
    self.changed_sequence_at_row(row_index),
    caller,
  )
}

///|
fn RawTableColumn::record_changed_at_row(
  self : RawTableColumn,
  row_index : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  self.set_metadata_at_row(
    row_index,
    self.added_sequence_at_row(row_index),
    Some(sequence),
    caller,
  )
}

///|
fn[T] RawTableColumn::value_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> T? raise @any.TypeMismatch {
  match self.values_cache {
    Some(values_any) => {
      let values : Array[T] = values_any.unsafe_coerce()
      if row_index < 0 || row_index >= values.length() {
        return None
      }
      return Some(values[row_index])
    }
    None =>
      match self.values_snapshot() {
        Some(values) => {
          self.values_cache = Some(@any.of(values))
          if row_index < 0 || row_index >= values.length() {
            return None
          }
          return Some(values[row_index])
        }
        None => ()
      }
  }
  match raw_table_value_column_kernel_value(self.storage, row_index) {
    Some(value) => Some(value.to())
    None => None
  }
}

///|
fn[T] RawTableColumn::values_snapshot(
  self : RawTableColumn,
) -> Array[T]? {
  let values : Array[T] = []
  let len = raw_table_value_column_kernel_len(self.storage)
  for row_index in 0..<len {
    guard raw_table_value_column_kernel_value(self.storage, row_index)
      is Some(value_any) else {
      return None
    }
    let result : Result[T, @any.TypeMismatch] = try? value_any.to()
    match result {
      Ok(value) => values.push(value)
      Err(_) => return None
    }
  }
  Some(values)
}

///|
fn[T] RawTableColumn::values_cached(self : RawTableColumn) -> Array[T]? {
  match self.values_cache {
    Some(values) => Some(values.unsafe_coerce())
    None =>
      match self.values_snapshot() {
        Some(values) => {
          self.values_cache = Some(@any.of(values))
          Some(values)
        }
        None => None
      }
  }
}

///|
fn RawTableColumn::type_name(self : RawTableColumn) -> String {
  self.component_ops.debug_name
}

///|
fn raw_table_column_swap_remove(
  column_ref : Ref[RawTableColumn],
  row_index : Int,
) -> Bool {
  let column = column_ref.val
  if !raw_table_value_column_kernel_swap_remove(column.storage, row_index) {
    return false
  }
  match column.values_cache {
    Some(values) =>
      if !(column.component_ops.column_ops.swap_remove_row)(values, row_index) {
        return false
      }
    None => ()
  }
  true
}

///|
fn raw_table_new(world : World, component_local_ids : Array[Int]) -> RawTable {
  let component_indices : Map[Int, Int] = {}
  let columns : Array[Ref[RawTableColumn]] = []
  for index in 0..<component_local_ids.length() {
    let component_local_id = component_local_ids[index]
    component_indices.set(component_local_id, index)
    let definition_id = match world.definition_component_id(component_local_id) {
      Some(definition_id) => definition_id
      None =>
        abort(
          "Missing component definition id for local component \{component_local_id.to_string()}",
        )
    }
    let ops = component_ops(definition_id)
    columns.push(Ref::new(raw_table_column_new(ops)))
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
fn RawTable::column(
  self : RawTable,
  component_local_id : Int,
) -> Ref[RawTableColumn]? {
  guard self.component_index(component_local_id) is Some(component_index) else {
    return None
  }
  Some(self.columns[component_index])
}

///|
fn RawTable::column_type_name(
  self : RawTable,
  component_local_id : Int,
) -> String? {
  match self.column(component_local_id) {
    Some(column_ref) => Some(column_ref.val.type_name())
    None => None
  }
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
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.payload_at_row(row.index())
}

///|
///|
fn[T] RawTable::value_at_row_index(
  self : RawTable,
  row_index : Int,
  component_local_id : Int,
) -> T? raise @any.TypeMismatch {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.value_at_row(row_index)
}

///|
fn RawTable::replace_payload_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  payload : ErasedValue,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.replace_payload_at_row(row.index(), payload)
}

///|
fn RawTable::replace_writer_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  writer : ErasedWriter,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.replace_writer_at_row(row.index(), writer)
}

///|
fn[T] RawTable::replace_value_at_row_index(
  self : RawTable,
  row_index : Int,
  component_local_id : Int,
  key : ComponentKey[T],
  value : T,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.replace_writer_at_row(row_index, erased_writer(key, value))
}

fn RawTable::added_sequence_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> @core.Sequence? {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.added_sequence_at_row(row.index())
}

///|
fn RawTable::changed_sequence_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> @core.Sequence? {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.changed_sequence_at_row(row.index())
}

///|
fn RawTable::changed_caller_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> String? {
  guard self.column(component_local_id) is Some(column_ref) else {
    return None
  }
  column_ref.val.changed_caller_at_row(row.index())
}

///|
fn RawTable::record_added_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.record_added_at_row(row.index(), sequence, caller)
}

///|
fn RawTable::record_changed_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.val.record_changed_at_row(row.index(), sequence, caller)
}

///|
fn RawTable::append_row_from_source_table(
  self : RawTable,
  entity : @core.Entity,
  source_table : Ref[RawTable]?,
  source_row : TableRow?,
  pending_payloads : Map[Int, ErasedWriter],
  pending_metadata : Map[Int, ComponentTickMetadata],
) -> TableRow? {
  let row = raw_table_row_kernel_push(self.rows, entity)
  let row_index = row
  for column_index in 0..<self.columns.length() {
    let component_local_id = self.component_local_ids[column_index]
    let column = self.columns[column_index].val
    let mut added_sequence : @core.Sequence? = None
    let mut changed_sequence : @core.Sequence? = None
    let mut changed_caller : String? = None
    let appended = match source_table {
      Some(source_table_ref) =>
        match source_row {
          Some(source_row) =>
            match source_table_ref.val.column(component_local_id) {
              Some(source_column_ref) => {
                added_sequence = source_column_ref.val.added_sequence_at_row(
                  source_row.index(),
                )
                changed_sequence = source_column_ref.val.changed_sequence_at_row(
                  source_row.index(),
                )
                changed_caller = source_column_ref.val.changed_caller_at_row(
                  source_row.index(),
                )
                column.append_from_row(
                  source_column_ref.val,
                  source_row.index(),
                )
              }
              None =>
                match pending_payloads.get(component_local_id) {
                  Some(writer) => {
                    match pending_metadata.get(component_local_id) {
                      Some(metadata) => {
                        added_sequence = metadata.added_sequence
                        changed_sequence = metadata.changed_sequence
                        changed_caller = metadata.changed_caller
                      }
                      None => ()
                    }
                    column.append_writer(writer)
                  }
                  None => false
                }
            }
          None =>
            match pending_payloads.get(component_local_id) {
              Some(writer) => {
                match pending_metadata.get(component_local_id) {
                  Some(metadata) => {
                    added_sequence = metadata.added_sequence
                    changed_sequence = metadata.changed_sequence
                    changed_caller = metadata.changed_caller
                  }
                  None => ()
                }
                column.append_writer(writer)
              }
              None => false
            }
        }
      None =>
        match pending_payloads.get(component_local_id) {
          Some(writer) => {
            match pending_metadata.get(component_local_id) {
              Some(metadata) => {
                added_sequence = metadata.added_sequence
                changed_sequence = metadata.changed_sequence
                changed_caller = metadata.changed_caller
              }
              None => ()
            }
            column.append_writer(writer)
          }
          None => false
        }
    }
    if !appended {
      for rollback_column_index in 0..<column_index {
        ignore(raw_table_column_swap_remove(self.columns[rollback_column_index], row_index))
      }
      ignore(raw_table_row_kernel_swap_remove(self.rows, row_index))
      return None
    }
    column.append_metadata()
    if !column.set_metadata_at_row(
        row_index,
        added_sequence,
        changed_sequence,
        changed_caller,
      ) {
      for rollback_column_index in 0..<(column_index + 1) {
        ignore(raw_table_column_swap_remove(self.columns[rollback_column_index], row_index))
      }
      ignore(raw_table_row_kernel_swap_remove(self.rows, row_index))
      return None
    }
  }
  TableRow::from_index(row)
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
    Ref::new(raw_table_new(self, component_local_ids))
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
        match context.payloads.get(local_component_id) {
          Some(writer) => Some(writer.to_erased_value())
          None => None
        }
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
  payloads : Map[Int, ErasedWriter],
  metadata : Map[Int, ComponentTickMetadata],
) -> PendingComponentPayloadContext? {
  let previous = self.pending_component_payload_context
  self.pending_component_payload_context = Some({
    entity_id: entity.id,
    payloads,
    metadata,
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
fn World::set_query_sparse_anchor_payload_context(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  payload : ErasedValue,
) -> Unit {
  self.current_query_sparse_anchor_payload_context = Some({
    entity_id: entity.id,
    local_component_id,
    payload,
  })
}

///|
fn World::clear_query_sparse_anchor_payload_context(self : World) -> Unit {
  self.current_query_sparse_anchor_payload_context = None
}

///|
fn World::query_sparse_anchor_payload(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  match self.current_query_sparse_anchor_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.local_component_id == local_component_id {
        Some(context.payload)
      } else {
        None
      }
    None => None
  }
}

///|
fn World::table_id_for_entity(self : World, entity : @core.Entity) -> Int? {
  self.table_id_for_entity_id(entity.id)
}

///|
fn World::table_id_for_entity_id(self : World, entity_id : Int) -> Int? {
  guard entity_id >= 0 && entity_id < self.entity_table_ids.length() else {
    return None
  }
  let table_id = self.entity_table_ids[entity_id]
  if table_id < 0 {
    return None
  }
  Some(table_id)
}

///|
fn World::entity_table_row(self : World, entity : @core.Entity) -> TableRow? {
  self.entity_table_row_by_id(entity.id)
}

///|
fn World::entity_table_row_by_id(self : World, entity_id : Int) -> TableRow? {
  guard entity_id >= 0 && entity_id < self.entity_table_rows.length() else {
    return None
  }
  TableRow::from_index(self.entity_table_rows[entity_id])
}

///|
fn World::alive_entity_by_id(self : World, entity_id : Int) -> @core.Entity? {
  guard entity_id >= 0 && entity_id < self.entity_archetype_ids.length() else {
    return None
  }
  let archetype_id = self.entity_archetype_ids[entity_id]
  guard archetype_id >= 0 else { return None }
  guard self.archetype_entities_view(archetype_id) is Some(entities) else {
    return None
  }
  if entity_id < self.entity_archetype_rows.length() {
    let row_index = self.entity_archetype_rows[entity_id]
    if row_index >= 0 && row_index < entities.length() {
      let entity = entities[row_index]
      if entity.id == entity_id {
        return Some(entity)
      }
    }
  }
  for entity in entities {
    if entity.id == entity_id {
      return Some(entity)
    }
  }
  None
}

///|
fn[T] World::component_value_by_local_id(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  local_component_id : Int,
) -> T? raise EcsError {
  match self.pending_component_payload_context {
    Some(_) =>
      if self.pending_component_payload(entity, local_component_id)
        is Some(payload) {
        return Some(self.component_value(key, entity, payload))
      }
    None => ()
  }
  match self.current_query_sparse_anchor_payload_context {
    Some(_) =>
      if self.query_sparse_anchor_payload(entity, local_component_id)
        is Some(payload) {
        return Some(self.component_value(key, entity, payload))
      }
    None => ()
  }
  match self.local_component_storage_type(local_component_id) {
    Some(SparseSet) =>
      match self.sparse_component_columns.get(local_component_id) {
        Some(store_ref) =>
          match store_ref.val.get(entity) {
            Some(payload) => Some(self.component_value(key, entity, payload))
            None => None
          }
        None => None
      }
    Some(Table) => {
      let entity_id = entity.id
      guard entity_id >= 0 &&
        entity_id < self.entity_table_ids.length() &&
        entity_id < self.entity_table_rows.length() else {
        return None
      }
      let table_id = self.entity_table_ids[entity_id]
      let row_index = self.entity_table_rows[entity_id]
      guard table_id >= 0 && row_index >= 0 else { return None }
      guard self.table_storage(table_id) is Some(table_ref) else { return None }
      guard table_ref.val.column(local_component_id) is Some(column_ref) else {
        return None
      }
      match column_ref.val.payload_at_row(row_index) {
        Some(payload) => Some(self.component_value(key, entity, payload))
        None => None
      }
    }
    None => None
  }
}

///|
fn[T] World::component_value_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  match self.local_component_id(key.id()) {
    Some(local_component_id) =>
      self.component_value_by_local_id(entity, key, local_component_id)
    None => None
  }
}

///|
fn[T] World::replace_component_value_by_local_id(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  local_component_id : Int,
  value : T,
) -> Bool {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(local_component_id) is Some(_) {
        context.payloads.set(local_component_id, erased_writer(key, value))
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
      store_ref.val.set(entity, erased_value(value))
    }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return false
      }
      guard self.table_storage(table_id) is Some(table_ref) else {
        return false
      }
      guard self.entity_table_row(entity) is Some(row) else { return false }
      table_ref.val.replace_writer_at_row(
        row,
        local_component_id,
        erased_writer(key, value),
      )
    }
    None => false
  }
}

///|
fn[T] World::replace_component_value_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  value : T,
) -> Bool {
  match self.local_component_id(key.id()) {
    Some(local_component_id) =>
      self.replace_component_value_by_local_id(
        entity,
        key,
        local_component_id,
        value,
      )
    None => false
  }
}

///|
fn[T] World::replace_component_value_at_table_row(
  self : World,
  key : ComponentKey[T],
  local_component_id : Int,
  table_id : Int,
  row_index : Int,
  value : T,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return false
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return false }
  table_ref.val.replace_value_at_row_index(
    row_index,
    local_component_id,
    key,
    value,
  )
}

///|
fn World::table_component_added_sequence_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> @core.Sequence? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.val.added_sequence_at_row(row, local_component_id)
}

///|
fn World::table_component_changed_sequence_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> @core.Sequence? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.val.changed_sequence_at_row(row, local_component_id)
}

///|
fn World::table_component_changed_caller_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> String? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.val.changed_caller_at_row(row, local_component_id)
}

///|
fn World::table_has_component_local_id(
  self : World,
  table_id : Int,
  local_component_id : Int,
) -> Bool {
  guard table_id >= 0 else { return false }
  match self.table_storage(table_id) {
    Some(table_ref) => table_ref.val.column(local_component_id) is Some(_)
    None => false
  }
}

///|
fn[T] World::component_value_by_key_at_table_row(
  self : World,
  key : ComponentKey[T],
  table_id : Int,
  row_index : Int,
) -> T? raise EcsError {
  guard self.local_component_id(key.id()) is Some(local_component_id) else {
    return None
  }
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  let result : Result[T?, @any.TypeMismatch] = try? table_ref.val.value_at_row_index(
    row_index,
    local_component_id,
  )
  match result {
    Ok(value) => value
    Err(_) =>
      raise ComponentTypeMismatch(
        key.id(),
        key.debug_name(),
        @core.Entity::placeholder(),
        table_ref.val.column_type_name(local_component_id).unwrap_or(
          "unknown",
        ),
      )
  }
}

///|
fn World::record_table_component_added_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return false
  }
  guard self.table_id_for_entity(entity) is Some(table_id) else { return false }
  guard self.table_storage(table_id) is Some(table_ref) else { return false }
  guard self.entity_table_row(entity) is Some(row) else { return false }
  table_ref.val.record_added_at_row(row, local_component_id, sequence, caller)
}

///|
fn World::record_table_component_changed_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return false
  }
  guard self.table_id_for_entity(entity) is Some(table_id) else { return false }
  guard self.table_storage(table_id) is Some(table_ref) else { return false }
  guard self.entity_table_row(entity) is Some(row) else { return false }
  table_ref.val.record_changed_at_row(
    row,
    local_component_id,
    sequence,
    caller,
  )
}

///|
fn World::sparse_component_added_sequence_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> @core.Sequence? {
  match self.sparse_component_metadata_for_entity(entity, local_component_id) {
    Some(metadata) => metadata.added_sequence
    None => None
  }
}

///|
fn World::sparse_component_changed_sequence_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> @core.Sequence? {
  match self.sparse_component_metadata_for_entity(entity, local_component_id) {
    Some(metadata) => metadata.changed_sequence
    None => None
  }
}

///|
fn World::sparse_component_changed_caller_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> String? {
  match self.sparse_component_metadata_for_entity(entity, local_component_id) {
    Some(metadata) => metadata.changed_caller
    None => None
  }
}

///|
fn World::record_sparse_component_added_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return false
  }
  guard self.sparse_component_columns.get(local_component_id) is Some(store_ref) else {
    return false
  }
  guard store_ref.val.contains(entity) else { return false }
  let metadata_store_ref = self.ensure_sparse_component_metadata_store_for_local_id(
    local_component_id,
  )
  metadata_store_ref.val.upsert(
    entity,
    component_tick_metadata_with_added(
      metadata_store_ref.val.get(entity),
      sequence,
      caller,
    ),
  )
  true
}

///|
fn World::record_sparse_component_changed_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  sequence : @core.Sequence,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return false
  }
  guard self.sparse_component_columns.get(local_component_id) is Some(store_ref) else {
    return false
  }
  guard store_ref.val.contains(entity) else { return false }
  let metadata_store_ref = self.ensure_sparse_component_metadata_store_for_local_id(
    local_component_id,
  )
  metadata_store_ref.val.upsert(
    entity,
    component_tick_metadata_with_changed(
      metadata_store_ref.val.get(entity),
      sequence,
      caller,
    ),
  )
  true
}

///|
fn World::clear_sparse_component_metadata_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> Unit {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return
  }
  match self.sparse_component_metadata.get(local_component_id) {
    Some(store_ref) => ignore(store_ref.val.remove(entity))
    None => ()
  }
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
  if self.query_sparse_anchor_payload(entity, local_component_id) is Some(payload) {
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
        guard self.definition_component_id(local_component_id)
          is Some(definition_id) else {
          return false
        }
        let ops = component_ops(definition_id)
        match (ops.column_ops.writer_from_payload)(payload) {
          Some(writer) => {
            context.payloads.set(local_component_id, writer)
            return true
          }
          None => return false
        }
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
fn World::replace_component_writer_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  writer : ErasedWriter,
) -> Bool {
  match self.pending_component_payload_context {
    Some(context) =>
      if context.entity_id == entity.id &&
        context.payloads.get(local_component_id) is Some(_) {
        context.payloads.set(local_component_id, writer)
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
      store_ref.val.set(entity, writer.to_erased_value())
    }
    Some(Table) => {
      guard self.table_id_for_entity(entity) is Some(table_id) else {
        return false
      }
      guard self.table_storage(table_id) is Some(table_ref) else {
        return false
      }
      guard self.entity_table_row(entity) is Some(row) else { return false }
      table_ref.val.replace_writer_at_row(row, local_component_id, writer)
    }
    None => false
  }
}

///|
fn World::replace_component_writer(
  self : World,
  component_definition_id : Int,
  entity : @core.Entity,
  writer : ErasedWriter,
) -> Bool {
  match self.local_component_id(component_definition_id) {
    Some(local_component_id) =>
      self.replace_component_writer_by_local_id(
        entity,
        local_component_id,
        writer,
      )
    None => false
  }
}

fn World::remove_sparse_component_payload_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> ErasedValue? {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return None
  }
  let removed = match self.sparse_component_columns.get(local_component_id) {
    Some(store_ref) => store_ref.val.remove(entity)
    None => None
  }
  self.clear_sparse_component_metadata_by_local_id(entity, local_component_id)
  removed
}

///|
fn World::write_pending_sparse_component_payloads(
  self : World,
  entity : @core.Entity,
  pending_payloads : Map[Int, ErasedWriter],
  pending_metadata : Map[Int, ComponentTickMetadata],
) -> Unit {
  for entry in pending_payloads.iter() {
    let component_local_id = entry.0
    let payload = entry.1.to_erased_value()
    if self.local_component_storage_type(component_local_id) == Some(SparseSet) {
      let store_ref = self.ensure_component_store_for_local_id(
        component_local_id,
        SparseSet,
      )
      store_ref.val.insert(entity, payload)
      let metadata_store_ref = self.ensure_sparse_component_metadata_store_for_local_id(
        component_local_id,
      )
      let metadata = pending_metadata
        .get(component_local_id)
        .unwrap_or(component_tick_metadata_empty())
      metadata_store_ref.val.insert(entity, metadata)
    }
  }
}
