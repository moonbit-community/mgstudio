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
fn raw_table_invalid_tick() -> @core.Tick {
  -1
}

///|
fn raw_table_store_tick(tick : @core.Tick?) -> @core.Tick {
  match tick {
    Some(tick) => tick
    None => raw_table_invalid_tick()
  }
}

///|
fn raw_table_load_tick(tick : @core.Tick) -> @core.Tick? {
  if tick < 0 {
    None
  } else {
    Some(tick)
  }
}

///|
let raw_table_changed_caller_ids : @hashmap.HashMap[String, Int] = @hashmap.HashMap([],
)

///|
let raw_table_changed_callers : Array[String?] = [None]

///|
fn raw_table_store_changed_caller(caller : String?) -> Int {
  match caller {
    Some(caller) =>
      match raw_table_changed_caller_ids.get(caller) {
        Some(id) => id
        None => {
          let id = raw_table_changed_callers.length()
          raw_table_changed_caller_ids.set(caller, id)
          raw_table_changed_callers.push(Some(caller))
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
  match raw_table_changed_callers.get(caller_id) {
    Some(caller) => caller
    None => None
  }
}

///|
pub(all) struct RawTableColumn {
  component_ops : ComponentOps
  storage : RawTableColumnKernel
}

///|
struct RawTable {
  table_id : Int
  component_local_ids : Array[Int]
  component_indices : Map[Int, Int]
  rows : RawTableRowKernel
  columns : Array[RawTableColumn]
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
  track_change_locations : Bool,
) -> RawTableColumn {
  {
    component_ops,
    storage: raw_table_column_kernel_new(track_change_locations),
  }
}

///|
fn RawTableColumn::append_row(self : RawTableColumn) -> Bool {
  raw_table_column_kernel_push(
    self.storage,
    raw_table_invalid_tick(),
    raw_table_invalid_tick(),
    0,
  )
}

///|
fn RawTableColumn::append_from_row(
  self : RawTableColumn,
  source : RawTableColumn,
  row_index : Int,
) -> Bool {
  if row_index < 0 || row_index >= raw_table_column_kernel_len(source.storage) {
    return false
  }
  self.append_row()
}

///|
fn RawTableColumn::set_metadata_at_row(
  self : RawTableColumn,
  row_index : Int,
  added_tick : @core.Tick?,
  changed_tick : @core.Tick?,
  changed_caller : String?,
) -> Bool {
  if !raw_table_column_kernel_set_metadata(
      self.storage,
      row_index,
      raw_table_store_tick(added_tick),
      raw_table_store_tick(changed_tick),
      raw_table_store_changed_caller(changed_caller),
    ) {
    return false
  }
  true
}

///|
fn RawTableColumn::added_tick_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> @core.Tick? {
  if row_index < 0 || row_index >= raw_table_column_kernel_len(self.storage) {
    return None
  }
  raw_table_load_tick(raw_table_column_kernel_added(self.storage, row_index))
}

///|
fn RawTableColumn::changed_tick_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> @core.Tick? {
  if row_index < 0 || row_index >= raw_table_column_kernel_len(self.storage) {
    return None
  }
  raw_table_load_tick(raw_table_column_kernel_changed(self.storage, row_index))
}

///|
fn RawTableColumn::changed_caller_at_row(
  self : RawTableColumn,
  row_index : Int,
) -> String? {
  if row_index < 0 || row_index >= raw_table_column_kernel_len(self.storage) {
    return None
  }
  raw_table_load_changed_caller(
    raw_table_column_kernel_changed_caller_id(self.storage, row_index),
  )
}

///|
fn RawTableColumn::record_added_at_row(
  self : RawTableColumn,
  row_index : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  self.set_metadata_at_row(
    row_index,
    Some(tick),
    match self.changed_tick_at_row(row_index) {
      Some(changed_tick) => Some(changed_tick)
      None => Some(tick)
    },
    caller,
  )
}

///|
fn RawTableColumn::record_changed_at_row(
  self : RawTableColumn,
  row_index : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  self.record_changed_id_at_row(
    row_index,
    tick,
    raw_table_store_changed_caller(caller),
  )
}

///|
fn RawTableColumn::record_changed_id_at_row(
  self : RawTableColumn,
  row_index : Int,
  tick : @core.Tick,
  caller_id : Int,
) -> Bool {
  raw_table_column_kernel_set_changed(
    self.storage,
    row_index,
    raw_table_store_tick(Some(tick)),
    caller_id,
  )
}

///|
fn RawTableColumn::check_change_ticks(
  self : RawTableColumn,
  present_tick : @core.Tick,
) -> Unit {
  let len = raw_table_column_kernel_len(self.storage)
  for row_index in 0..<len {
    let added_tick = match self.added_tick_at_row(row_index) {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    }
    let changed_tick = match self.changed_tick_at_row(row_index) {
      Some(tick) => Some(@core.tick_check(tick, present_tick))
      None => None
    }
    ignore(
      self.set_metadata_at_row(
        row_index,
        added_tick,
        changed_tick,
        self.changed_caller_at_row(row_index),
      ),
    )
  }
}

///|
fn raw_table_column_swap_remove(
  world : World,
  table_id : Int,
  column_ref : RawTableColumn,
  row_index : Int,
) -> Bool {
  (column_ref.component_ops.swap_remove_table_row)(world, table_id, row_index)
  raw_table_column_kernel_swap_remove(column_ref.storage, row_index)
}

///|
fn raw_table_column_metadata_swap_remove(
  column_ref : RawTableColumn,
  row_index : Int,
) -> Bool {
  raw_table_column_kernel_swap_remove(column_ref.storage, row_index)
}

///|
fn raw_table_new(
  world : World,
  table_id : Int,
  component_local_ids : Array[Int],
) -> RawTable {
  let component_indices : Map[Int, Int] = Map([])
  let columns : Array[RawTableColumn] = []
  for index in 0..<component_local_ids.length() {
    let component_local_id = component_local_ids[index]
    component_indices.set(component_local_id, index)
    let definition_id = match
      world.definition_component_id(component_local_id) {
      Some(definition_id) => definition_id
      None =>
        abort(
          "Missing component definition id for local component \{component_local_id.to_string()}",
        )
    }
    let ops = component_ops(definition_id)
    columns.push(raw_table_column_new(ops, world.tracks_change_locations()))
  }
  {
    table_id,
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
) -> RawTableColumn? {
  guard self.component_index(component_local_id) is Some(component_index) else {
    return None
  }
  Some(self.columns[component_index])
}

///|
fn RawTable::entity_at_row(self : RawTable, row : TableRow) -> @core.Entity? {
  raw_table_row_kernel_entity_at(self.rows, row.index())
}

///|
fn RawTable::added_tick_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> @core.Tick? {
  guard self.column(component_local_id) is Some(column_ref) else { return None }
  column_ref.added_tick_at_row(row.index())
}

///|
fn RawTable::changed_tick_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> @core.Tick? {
  guard self.column(component_local_id) is Some(column_ref) else { return None }
  column_ref.changed_tick_at_row(row.index())
}

///|
fn RawTable::changed_caller_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
) -> String? {
  guard self.column(component_local_id) is Some(column_ref) else { return None }
  column_ref.changed_caller_at_row(row.index())
}

///|
fn RawTable::record_added_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.record_added_at_row(row.index(), tick, caller)
}

///|
fn RawTable::record_changed_at_row(
  self : RawTable,
  row : TableRow,
  component_local_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  guard self.column(component_local_id) is Some(column_ref) else {
    return false
  }
  column_ref.record_changed_at_row(row.index(), tick, caller)
}

///|
fn World::record_table_component_changed_at_table_row(
  self : World,
  local_component_id : Int,
  table_id : Int,
  row_index : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  guard self.table_storage(table_id) is Some(table_ref) else { return false }
  guard TableRow::from_index(row_index) is Some(row) else { return false }
  table_ref.record_changed_at_row(row, local_component_id, tick, caller)
}

///|
fn RawTable::check_change_ticks(
  self : RawTable,
  present_tick : @core.Tick,
) -> Unit {
  for column_ref in self.columns {
    column_ref.check_change_ticks(present_tick)
  }
}

///|
fn RawTable::append_row_from_source_table(
  self : RawTable,
  world : World,
  entity : @core.Entity,
  source_table : RawTable?,
  source_row : TableRow?,
  component_writes : ComponentWriteSet,
) -> TableRow? {
  let row = raw_table_row_kernel_push(self.rows, entity)
  let row_index = row
  // Table component ids inherit the sorted, unique archetype signature, so
  // source and target columns can be merged without a lookup or allocation.
  let mut source_column_index = 0
  for column_index in 0..<self.columns.length() {
    let component_local_id = self.component_local_ids[column_index]
    let column = self.columns[column_index]
    let mut added_tick : @core.Tick? = None
    let mut changed_tick : @core.Tick? = None
    let mut changed_caller : String? = None
    let appended = match source_table {
      Some(source_table_ref) =>
        match source_row {
          Some(source_row) => {
            while source_column_index <
                  source_table_ref.component_local_ids.length() &&
                  source_table_ref.component_local_ids[source_column_index] <
                  component_local_id {
              source_column_index = source_column_index + 1
            }
            if source_column_index <
              source_table_ref.component_local_ids.length() &&
              source_table_ref.component_local_ids[source_column_index] ==
              component_local_id {
              let source_column_ref = source_table_ref.columns[source_column_index]
              added_tick = source_column_ref.added_tick_at_row(
                source_row.index(),
              )
              changed_tick = source_column_ref.changed_tick_at_row(
                source_row.index(),
              )
              changed_caller = source_column_ref.changed_caller_at_row(
                source_row.index(),
              )
              column.append_from_row(source_column_ref, source_row.index())
            } else if component_writes.contains(component_local_id) {
              match component_writes.metadata(component_local_id) {
                Some(metadata) => {
                  added_tick = metadata.added_tick
                  changed_tick = metadata.changed_tick
                  changed_caller = metadata.changed_caller
                }
                None => ()
              }
              column.append_row()
            } else {
              false
            }
          }
          None =>
            if component_writes.contains(component_local_id) {
              match component_writes.metadata(component_local_id) {
                Some(metadata) => {
                  added_tick = metadata.added_tick
                  changed_tick = metadata.changed_tick
                  changed_caller = metadata.changed_caller
                }
                None => ()
              }
              column.append_row()
            } else {
              false
            }
        }
      None =>
        if component_writes.contains(component_local_id) {
          match component_writes.metadata(component_local_id) {
            Some(metadata) => {
              added_tick = metadata.added_tick
              changed_tick = metadata.changed_tick
              changed_caller = metadata.changed_caller
            }
            None => ()
          }
          column.append_row()
        } else {
          false
        }
    }
    if !appended {
      for rollback_column_index in 0..<column_index {
        ignore(
          raw_table_column_swap_remove(
            world,
            self.table_id,
            self.columns[rollback_column_index],
            row_index,
          ),
        )
      }
      ignore(raw_table_row_kernel_swap_remove(self.rows, row_index))
      return None
    }
    if !column.set_metadata_at_row(
        row_index, added_tick, changed_tick, changed_caller,
      ) {
      for rollback_column_index in 0..<(column_index + 1) {
        ignore(
          raw_table_column_swap_remove(
            world,
            self.table_id,
            self.columns[rollback_column_index],
            row_index,
          ),
        )
      }
      ignore(raw_table_row_kernel_swap_remove(self.rows, row_index))
      return None
    }
  }
  // Raw target rows are fully prepared before typed ownership changes. No
  // callbacks or public world access occur until the source row is finalized.
  source_column_index = 0
  for column_index in 0..<self.columns.length() {
    let component_local_id = self.component_local_ids[column_index]
    let column = self.columns[column_index]
    let moved_value = match (source_table, source_row) {
      (Some(source_table_ref), Some(source_row)) => {
        while source_column_index <
              source_table_ref.component_local_ids.length() &&
              source_table_ref.component_local_ids[source_column_index] <
              component_local_id {
          source_column_index = source_column_index + 1
        }
        if source_column_index < source_table_ref.component_local_ids.length() &&
          source_table_ref.component_local_ids[source_column_index] ==
          component_local_id {
          (column.component_ops.move_table_row_and_swap_remove)(
            world,
            entity,
            source_table_ref.table_id,
            source_row.index(),
            self.table_id,
            row_index,
          )
        } else {
          (column.component_ops.move_staged_to_table_row)(
            world,
            entity,
            self.table_id,
            row_index,
          )
        }
      }
      _ =>
        (column.component_ops.move_staged_to_table_row)(
          world,
          entity,
          self.table_id,
          row_index,
        )
    }
    if !moved_value {
      abort(
        "Missing typed component value while appending table row for component \{component_local_id.to_string()} in table \{self.table_id.to_string()}",
      )
    }
  }
  TableRow::from_index(row)
}

///|
fn RawTable::swap_remove_row(
  self : RawTable,
  world : World,
  row : TableRow,
  target_component_local_ids : Array[Int],
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
  let mut target_column_index = 0
  for column_index in 0..<self.columns.length() {
    let component_local_id = self.component_local_ids[column_index]
    while target_column_index < target_component_local_ids.length() &&
          target_component_local_ids[target_column_index] < component_local_id {
      target_column_index = target_column_index + 1
    }
    let column_ref = self.columns[column_index]
    if target_column_index < target_component_local_ids.length() &&
      target_component_local_ids[target_column_index] == component_local_id {
      ignore(raw_table_column_metadata_swap_remove(column_ref, row_index))
    } else {
      ignore(
        raw_table_column_swap_remove(
          world,
          self.table_id,
          column_ref,
          row_index,
        ),
      )
    }
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
fn World::ensure_table_storage(self : World, table_id : Int) -> RawTable {
  if table_id < 0 {
    abort("Cannot ensure table storage for negative table id")
  }
  let component_local_ids = self.table_component_local_ids
    .get(table_id)
    .unwrap_or([])
  while self.tables.length() <= table_id {
    self.tables.push(None)
  }
  match self.tables[table_id] {
    Some(table_ref) => table_ref
    None => {
      let table_ref = raw_table_new(self, table_id, component_local_ids)
      self.tables[table_id] = Some(table_ref)
      table_ref
    }
  }
}

///|
fn World::table_storage(self : World, table_id : Int) -> RawTable? {
  if table_id < 0 || table_id >= self.tables.length() {
    return None
  }
  self.tables[table_id]
}

///|
fn World::table_entities_view(
  self : World,
  table_id : Int,
) -> Array[@core.Entity]? {
  match self.table_storage(table_id) {
    Some(table_ref) => Some(table_ref.rows.entities)
    None => None
  }
}

///|
fn World::table_id_for_entity(self : World, entity : @core.Entity) -> Int? {
  self.table_id_for_entity_id(entity.id)
}

///|
fn World::table_id_for_entity_id(self : World, entity_id : Int) -> Int? {
  guard entity_id >= 0 &&
    entity_id < self.entity_storage.entity_table_ids.length() else {
    return None
  }
  let table_id = self.entity_storage.entity_table_ids[entity_id]
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
  guard entity_id >= 0 &&
    entity_id < self.entity_storage.entity_table_rows.length() else {
    return None
  }
  TableRow::from_index(self.entity_storage.entity_table_rows[entity_id])
}

///|
pub fn World::entity_table_location_by_id(
  self : World,
  entity_id : Int,
) -> (Int, Int)? {
  guard entity_id >= 0 &&
    entity_id < self.entity_storage.entity_table_ids.length() &&
    entity_id < self.entity_storage.entity_table_rows.length() else {
    return None
  }
  let table_id = self.entity_storage.entity_table_ids[entity_id]
  let row_index = self.entity_storage.entity_table_rows[entity_id]
  guard table_id >= 0 && row_index >= 0 else { return None }
  Some((table_id, row_index))
}

///|
pub fn World::entity_table_location(
  self : World,
  entity : @core.Entity,
) -> (Int, Int)? {
  guard self.is_alive(entity) else { return None }
  self.entity_table_location_by_id(entity.id)
}

///|
fn World::alive_entity_by_id(self : World, entity_id : Int) -> @core.Entity? {
  guard entity_id >= 0 &&
    entity_id < self.entity_storage.entity_archetype_ids.length() else {
    return None
  }
  let archetype_id = self.entity_storage.entity_archetype_ids[entity_id]
  guard archetype_id >= 0 else { return None }
  guard self.archetype_entities_view(archetype_id) is Some(entities) else {
    return None
  }
  if entity_id < self.entity_storage.entity_archetype_rows.length() {
    let row_index = self.entity_storage.entity_archetype_rows[entity_id]
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
) -> T? {
  guard self.component_write_transaction_contains(entity, local_component_id) ||
    self.entity_has_component_local_id(entity, local_component_id) else {
    return None
  }
  key.component_get(self, entity)
}

///|
fn[T] World::component_value_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? {
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
  if self.component_write_transaction_contains(entity, local_component_id) {
    key.component_set(self, entity, value)
    return true
  }
  guard self.entity_has_component_local_id(entity, local_component_id) else {
    return false
  }
  key.component_set(self, entity, value)
  true
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
        entity, key, local_component_id, value,
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
  guard TableRow::from_index(row_index) is Some(row) else { return false }
  guard table_ref.entity_at_row(row) is Some(entity) else { return false }
  guard self.entity_has_component_local_id(entity, local_component_id) else {
    return false
  }
  key.component_set_table_row(self, table_id, row_index, value)
  true
}

///|
fn World::table_component_added_tick_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> @core.Tick? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.added_tick_at_row(row, local_component_id)
}

///|
fn World::table_component_changed_tick_by_local_id(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> @core.Tick? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_id_for_entity_id(entity_id) is Some(table_id) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard self.entity_table_row_by_id(entity_id) is Some(row) else { return None }
  table_ref.changed_tick_at_row(row, local_component_id)
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
  table_ref.changed_caller_at_row(row, local_component_id)
}

///|
fn World::table_has_component_local_id(
  self : World,
  table_id : Int,
  local_component_id : Int,
) -> Bool {
  guard table_id >= 0 else { return false }
  match self.table_storage(table_id) {
    Some(table_ref) => table_ref.column(local_component_id) is Some(_)
    None => false
  }
}

///|
fn[T] World::component_value_by_table_row_fast(
  self : World,
  key : ComponentKey[T],
  local_component_id : Int,
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return None
  }
  guard self.table_storage(table_id) is Some(table_ref) else { return None }
  guard table_ref.column(local_component_id) is Some(_) else { return None }
  guard TableRow::from_index(row_index) is Some(row) else { return None }
  guard table_ref.entity_at_row(row) is Some(entity) else { return None }
  guard self.entity_has_component_local_id(entity, local_component_id) else {
    return None
  }
  key.component_get_table_row(self, table_id, row_index)
}

///|
fn[T] World::component_value_by_table_row_unchecked(
  self : World,
  key : ComponentKey[T],
  local_component_id : Int,
  table_id : Int,
  row_index : Int,
) -> T {
  if self.local_component_storage_type(local_component_id) != Some(Table) {
    abort("Required table fetch used a non-table component")
  }
  guard self.table_storage(table_id) is Some(table_ref) else {
    abort("Required table fetch used a missing table")
  }
  guard table_ref.column(local_component_id) is Some(_) else {
    abort("Required table fetch used a table without the component")
  }
  if row_index < 0 || row_index >= table_ref.row_count() {
    abort("Required table fetch row is out of bounds")
  }
  key.component_get_table_row_unchecked(self, table_id, row_index)
}

///|
fn World::record_table_component_added_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return false
  }
  guard self.table_id_for_entity(entity) is Some(table_id) else { return false }
  guard self.table_storage(table_id) is Some(table_ref) else { return false }
  guard self.entity_table_row(entity) is Some(row) else { return false }
  table_ref.record_added_at_row(row, local_component_id, tick, caller)
}

///|
fn World::record_table_component_changed_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(Table) else {
    return false
  }
  guard self.table_id_for_entity(entity) is Some(table_id) else { return false }
  guard self.table_storage(table_id) is Some(table_ref) else { return false }
  guard self.entity_table_row(entity) is Some(row) else { return false }
  table_ref.record_changed_at_row(row, local_component_id, tick, caller)
}

///|
fn World::sparse_component_added_tick_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> @core.Tick? {
  match self.sparse_component_metadata_for_entity(entity, local_component_id) {
    Some(metadata) => metadata.added_tick
    None => None
  }
}

///|
fn World::sparse_component_changed_tick_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> @core.Tick? {
  match self.sparse_component_metadata_for_entity(entity, local_component_id) {
    Some(metadata) => metadata.changed_tick
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
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return false
  }
  guard self.definition_component_id(local_component_id) is Some(definition_id) else {
    return false
  }
  let ops = component_ops(definition_id)
  guard (ops.contains)(self, entity) else { return false }
  let metadata_store = self.ensure_sparse_component_metadata_store_for_local_id(
    local_component_id,
  )
  metadata_store.upsert(
    entity,
    component_tick_metadata_with_added(metadata_store.get(entity), tick, caller),
  )
  ignore(
    self.record_component_write_transaction_added_metadata(
      entity, local_component_id, tick, caller,
    ),
  )
  true
}

///|
fn World::record_sparse_component_changed_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  guard self.local_component_storage_type(local_component_id) == Some(SparseSet) else {
    return false
  }
  guard self.definition_component_id(local_component_id) is Some(definition_id) else {
    return false
  }
  let ops = component_ops(definition_id)
  guard (ops.contains)(self, entity) else { return false }
  let metadata_store = self.ensure_sparse_component_metadata_store_for_local_id(
    local_component_id,
  )
  metadata_store.upsert(
    entity,
    component_tick_metadata_with_changed(
      metadata_store.get(entity),
      tick,
      caller,
    ),
  )
  ignore(
    self.record_component_write_transaction_changed_metadata(
      entity, local_component_id, tick, caller,
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
    Some(store) => ignore(store.remove(entity))
    None => ()
  }
}

///|
fn World::component_present_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> Bool {
  self.component_write_transaction_contains(entity, local_component_id) ||
  self.entity_has_component_local_id(entity, local_component_id)
}

///|
fn World::component_present(
  self : World,
  component_definition_id : Int,
  entity : @core.Entity,
) -> Bool {
  match self.local_component_id(component_definition_id) {
    Some(local_component_id) =>
      self.component_present_by_local_id(entity, local_component_id)
    None => false
  }
}

///|
fn World::replace_component_writer_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  writer : ComponentWriter,
) -> Bool {
  if self.component_write_transaction_contains(entity, local_component_id) {
    writer.apply(self, entity)
    return true
  }
  guard self.entity_has_component_local_id(entity, local_component_id) else {
    return false
  }
  guard self.definition_component_id(local_component_id) is Some(definition_id) else {
    return false
  }
  guard writer.component_definition_id == definition_id else { return false }
  writer.apply(self, entity)
  true
}

///|
fn World::replace_component_writer(
  self : World,
  component_definition_id : Int,
  entity : @core.Entity,
  writer : ComponentWriter,
) -> Bool {
  match self.local_component_id(component_definition_id) {
    Some(local_component_id) =>
      self.replace_component_writer_by_local_id(
        entity, local_component_id, writer,
      )
    None => false
  }
}

///|
fn World::remove_component_write_by_local_id(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> Bool {
  guard self.definition_component_id(local_component_id) is Some(definition_id) else {
    return false
  }
  let ops = component_ops(definition_id)
  let removed = (ops.remove)(self, entity)
  self.clear_sparse_component_metadata_by_local_id(entity, local_component_id)
  removed
}

///|
fn World::commit_sparse_component_write_metadata(
  self : World,
  entity : @core.Entity,
  component_writes : ComponentWriteSet,
) -> Unit {
  for entry in component_writes.entries {
    let component_local_id = entry.local_component_id
    if self.local_component_storage_type(component_local_id) == Some(SparseSet) {
      let metadata_store = self.ensure_sparse_component_metadata_store_for_local_id(
        component_local_id,
      )
      metadata_store.insert(entity, entry.metadata)
    }
  }
}
