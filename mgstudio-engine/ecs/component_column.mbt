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
  priv table_column_cache : Array[RawTableColumn?]
  priv table_column_cache_ready : @utils.IntBitSet
}

///|
pub struct ComponentTableColumn[T] {
  priv world : World
  priv table_id : Int
  priv local_component_id : Int
  priv column : RawTableColumn
  priv key : ComponentKey[T]
}

///|
priv struct ComponentColumnTablePlan {
  component_local_ids : Array[Int]
  mut archetype_generation : Int
  mut table_ids : Array[Int]
}

///|
fn component_column_table_plan_new(
  component_local_ids : Array[Int],
) -> ComponentColumnTablePlan {
  { component_local_ids, archetype_generation: -1, table_ids: [] }
}

///|
fn World::component_column_table_plan(
  self : World,
  component_local_ids : Array[Int],
) -> ComponentColumnTablePlan {
  let normalized = archetype_sorted_unique_local_component_ids(
    component_local_ids,
  )
  match self.component_column_table_plan_ids_by_signature.lookup(normalized) {
    Some(plan_id) =>
      match self.component_column_table_plans.get(plan_id) {
        Some(plan) => plan
        None => {
          let plan = component_column_table_plan_new(normalized)
          self.component_column_table_plans.set(plan_id, plan)
          plan
        }
      }
    None => {
      let plan_id = self.next_component_column_table_plan_id
      self.next_component_column_table_plan_id = plan_id + 1
      self.component_column_table_plan_ids_by_signature.insert(
        normalized, plan_id,
      )
      let plan = component_column_table_plan_new(normalized)
      self.component_column_table_plans.set(plan_id, plan)
      plan
    }
  }
}

///|
fn World::rebuild_component_column_table_plan(
  self : World,
  plan : ComponentColumnTablePlan,
) -> Unit {
  let component_local_ids = plan.component_local_ids
  if component_local_ids.length() == 0 {
    plan.table_ids = []
    plan.archetype_generation = self.archetype_generation()
    return
  }
  let mut driver_local_component_id = component_local_ids[0]
  let mut driver_count = self.component_membership_counts
    .get(driver_local_component_id)
    .unwrap_or(0)
  for index in 1..<component_local_ids.length() {
    let component_local_id = component_local_ids[index]
    let count = self.component_membership_counts
      .get(component_local_id)
      .unwrap_or(0)
    if count < driver_count {
      driver_local_component_id = component_local_id
      driver_count = count
    }
  }
  let table_ids : Array[Int] = []
  let visited_tables = @utils.IntBitSet::new()
  let archetype_ids = self.archetype_ids_for_component_local_id(
    driver_local_component_id,
  )
  for archetype_id in archetype_ids {
    guard self.archetype_local_component_presence_view(archetype_id)
      is Some(presence) else {
      continue
    }
    let mut matches = true
    for component_local_id in component_local_ids {
      if !presence.contains(component_local_id) {
        matches = false
        break
      }
    }
    if !matches {
      continue
    }
    guard self.archetype_table_id(archetype_id) is Some(table_id) else {
      continue
    }
    if visited_tables.contains(table_id) {
      continue
    }
    visited_tables.insert(table_id)
    table_ids.push(table_id)
  }
  plan.table_ids = table_ids
  plan.archetype_generation = self.archetype_generation()
}

///|
fn World::component_column_matching_table_ids(
  self : World,
  component_local_ids : Array[Int],
) -> Array[Int] {
  let plan = self.component_column_table_plan(component_local_ids)
  if plan.archetype_generation != self.archetype_generation() {
    self.rebuild_component_column_table_plan(plan)
  }
  plan.table_ids
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
            table_column_cache: [],
            table_column_cache_ready: @utils.IntBitSet::new(),
          })
        None => None
      }
    None => None
  }
}

///|
fn[T] ComponentColumn::cached_table_column(
  self : ComponentColumn[T],
  table_id : Int,
) -> RawTableColumn? {
  if table_id < 0 {
    return None
  }
  while self.table_column_cache.length() <= table_id {
    self.table_column_cache.push(None)
  }
  if self.table_column_cache_ready.contains(table_id) {
    return self.table_column_cache[table_id]
  }
  self.table_column_cache_ready.insert(table_id)
  match self.world.table_storage(table_id) {
    Some(table_ref) =>
      match table_ref.column(self.local_component_id) {
        Some(column_ref) => {
          self.table_column_cache[table_id] = Some(column_ref)
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
  match self.cached_table_column(table_id) {
    Some(column) =>
      Some(ComponentTableColumn::{
        world: self.world,
        table_id,
        local_component_id: self.local_component_id,
        column,
        key: self.key,
      })
    None => None
  }
}

///|
fn[T] ComponentTableColumn::entity_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
) -> @core.Entity? {
  guard row_index >= 0 else { return None }
  guard self.world.table_storage(self.table_id) is Some(table_ref) else {
    return None
  }
  guard TableRow::from_index(row_index) is Some(row) else { return None }
  table_ref.entity_at_row(row)
}

///|
pub fn[T] ComponentTableColumn::key(
  self : ComponentTableColumn[T],
) -> ComponentKey[T] {
  self.key
}

///|
pub fn[T] ComponentTableColumn::value_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
) -> T? {
  guard self.entity_at_row(row_index) is Some(entity) else { return None }
  guard self.world.entity_has_component_local_id(
    entity,
    self.local_component_id,
  ) else {
    return None
  }
  self.key.component_get_table_row(self.world, self.table_id, row_index)
}

///|
pub fn[T] ComponentTableColumn::value_at_row_unchecked(
  self : ComponentTableColumn[T],
  row_index : Int,
) -> T? {
  self.value_at_row(row_index)
}

///|
pub fn[T] ComponentTableColumn::is_changed_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
  system_ticks : @core.SystemTicks,
) -> Bool {
  match self.column.changed_tick_at_row(row_index) {
    Some(tick) => system_ticks.contains(tick)
    None => false
  }
}

///|
pub fn[T] ComponentTableColumn::set_tick_only_hot_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
  value : T,
  tick : @core.Tick,
) -> Bool {
  guard row_index >= 0 else { return false }
  guard self.entity_at_row(row_index) is Some(entity) else { return false }
  guard self.world.entity_has_component_local_id(
    entity,
    self.local_component_id,
  ) else {
    return false
  }
  self.key.component_set_table_row(self.world, self.table_id, row_index, value)
  ignore(self.column.record_changed_at_row(row_index, tick, None))
  true
}

///|
pub fn[T] ComponentTableColumn::record_changed_at_row(
  self : ComponentTableColumn[T],
  row_index : Int,
  tick : @core.Tick,
) -> Bool {
  guard row_index >= 0 else { return false }
  ignore(self.column.record_changed_at_row(row_index, tick, None))
  true
}

///|
fn[T] ComponentColumn::table_values_for_table(
  self : ComponentColumn[T],
  table_id : Int,
) -> Array[T]? {
  if table_id < 0 {
    return None
  }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return None
  }
  ignore(column_ref)
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return None
  }
  let values : Array[T] = []
  let entities = table_ref.rows.entities
  for row_index in 0..<entities.length() {
    let entity = entities[row_index]
    guard self.world.entity_has_component_local_id(
      entity,
      self.local_component_id,
    ) else {
      return None
    }
    guard self.key.component_get_table_row(self.world, table_id, row_index)
      is Some(value) else {
      return None
    }
    values.push(value)
  }
  Some(values)
}

///|
pub fn[T] ComponentColumn::contains(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> Bool {
  if self.world.component_write_transaction_contains(
      entity,
      self.local_component_id,
    ) {
    return true
  }
  match self.storage_type {
    SparseSet =>
      self.world.entity_has_component_local_id(entity, self.local_component_id) &&
      self.key.component_contains(self.world, entity)
    Table => {
      if !self.world.entity_has_component_local_id(
          entity,
          self.local_component_id,
        ) {
        return false
      }
      guard self.world.entity_table_location(entity)
        is Some((table_id, row_index)) else {
        return false
      }
      match self.cached_table_column(table_id) {
        Some(column_ref) =>
          row_index < raw_table_column_kernel_len(column_ref.storage) &&
          self.key.component_get_table_row(self.world, table_id, row_index)
          is Some(_)
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
  if self.world.component_write_transaction_contains(
      entity,
      self.local_component_id,
    ) {
    return self.key.component_get(self.world, entity)
  }
  match self.storage_type {
    SparseSet =>
      if self.world.entity_has_component_local_id(
          entity,
          self.local_component_id,
        ) {
        self.key.component_get(self.world, entity)
      } else {
        None
      }
    Table => {
      guard self.world.entity_table_location(entity)
        is Some((table_id, row_index)) else {
        return None
      }
      guard self.cached_table_column(table_id) is Some(column_ref) else {
        return None
      }
      if row_index < raw_table_column_kernel_len(column_ref.storage) {
        self.key.component_get_table_row(self.world, table_id, row_index)
      } else {
        None
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
      if self.world.entity_has_component_local_id(
          entity,
          self.local_component_id,
        ) {
        self.key.component_get(self.world, entity)
      } else {
        None
      }
    Table => {
      guard self.world.entity_table_location(entity)
        is Some((table_id, row_index)) else {
        return None
      }
      guard self.cached_table_column(table_id) is Some(column_ref) else {
        return None
      }
      if row_index < raw_table_column_kernel_len(column_ref.storage) {
        self.key.component_get_table_row(self.world, table_id, row_index)
      } else {
        None
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
  self.table_values_for_table(table_id)
}

///|
pub fn[T] ComponentColumn::table_value_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.storage_type == Table else { return None }
  guard row_index >= 0 else { return None }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return None
  }
  guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
    return None
  }
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return None
  }
  guard TableRow::from_index(row_index) is Some(row) else { return None }
  guard table_ref.entity_at_row(row) is Some(entity) else { return None }
  guard self.world.entity_has_component_local_id(
    entity,
    self.local_component_id,
  ) else {
    return None
  }
  self.key.component_get_table_row(self.world, table_id, row_index)
}

///|
pub fn[T] ComponentColumn::table_has_value_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
) -> Bool {
  guard self.storage_type == Table else { return false }
  guard row_index >= 0 else { return false }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return false
  }
  guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
    return false
  }
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return false
  }
  guard TableRow::from_index(row_index) is Some(row) else { return false }
  guard table_ref.entity_at_row(row) is Some(entity) else { return false }
  self.world.entity_has_component_local_id(entity, self.local_component_id) &&
  self.key.component_get_table_row(self.world, table_id, row_index) is Some(_)
}

///|
pub fn[T] ComponentColumn::table_row_location(
  self : ComponentColumn[T],
  entity : @core.Entity,
) -> (Int, Int)? {
  guard self.storage_type == Table else { return None }
  guard self.world.entity_table_location(entity) is Some((table_id, row_index)) else {
    return None
  }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return None
  }
  guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
    return None
  }
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
  guard table_ref.entity_at_row(row) is Some(row_entity) else { return None }
  guard row_entity.to_bits() == entity.to_bits() else { return None }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return None
  }
  guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
    return None
  }
  self.key.component_get_table_row(self.world, table_id, row_index)
}

///|
pub fn[T] ComponentColumn::table_value_at_cached_entity_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
) -> T? {
  guard self.storage_type == Table else { return None }
  guard self.world.entity_table_location(entity)
    is Some((actual_table_id, actual_row_index)) else {
    return None
  }
  guard actual_table_id == table_id && actual_row_index == row_index else {
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
  guard self.world.entity_table_location(entity)
    is Some((actual_table_id, actual_row_index)) else {
    return None
  }
  if actual_table_id != table_id || actual_row_index != row_index {
    return None
  }
  if row_index < 0 || row_index >= values.length() {
    None
  } else {
    Some(values[row_index])
  }
}

///|
pub fn[T] ComponentColumn::table_changed_tick_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
) -> @core.Tick? {
  guard self.storage_type == Table else { return None }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return None
  }
  column_ref.changed_tick_at_row(row_index)
}

///|
pub fn[T] ComponentColumn::table_is_changed_at_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
  system_ticks : @core.SystemTicks,
) -> Bool {
  match self.table_changed_tick_at_row(table_id, row_index) {
    Some(tick) => system_ticks.contains(tick)
    None => false
  }
}

///|
pub fn[T] ComponentColumn::table_is_changed_at_entity_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
  system_ticks : @core.SystemTicks,
) -> Bool? {
  guard self.storage_type == Table else { return None }
  guard TableRow::from_index(row_index) is Some(row) else { return None }
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return None
  }
  guard table_ref.entity_at_row(row) is Some(row_entity) else { return None }
  guard row_entity.to_bits() == entity.to_bits() else { return None }
  Some(self.table_is_changed_at_row(table_id, row_index, system_ticks))
}

///|
pub fn[T] ComponentColumn::for_each_changed_table_entity(
  self : ComponentColumn[T],
  system_ticks : @core.SystemTicks,
  visit : (@core.Entity, Int, Int) -> Bool,
) -> Bool {
  guard self.storage_type == Table else { return true }
  for entry in self.world.tables.iter() {
    let (table_id, table_ref) = entry
    guard self.cached_table_column(table_id) is Some(column_ref) else {
      continue
    }
    let row_count = table_ref.row_count()
    for row_index in 0..<row_count {
      let changed = match column_ref.changed_tick_at_row(row_index) {
        Some(tick) => system_ticks.contains(tick)
        None => false
      }
      if !changed {
        continue
      }
      guard TableRow::from_index(row_index) is Some(row) else { continue }
      guard table_ref.entity_at_row(row) is Some(entity) else { continue }
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
    let (table_id, row_index) = match self.world.entity_table_location(entity) {
      Some(location) => location
      None => (-1, -1)
    }
    Some(
      mut_from_component_location(
        self.world,
        entity,
        self.key,
        self.local_component_id,
        table_id,
        row_index,
      ),
    )
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
      self.key.component_for_each(self.world, fn(entity, value) {
        if self.world.entity_has_component_local_id(
            entity,
            self.local_component_id,
          ) {
          visit(entity, value)
        }
      })
    Table => {
      let archetype_ids = self.world.archetype_ids_for_component_local_id(
        self.local_component_id,
      )
      for archetype_id in archetype_ids {
        guard self.world.archetype_entities_view(archetype_id) is Some(entities) else {
          continue
        }
        guard self.world.archetype_table_id(archetype_id) is Some(table_id) else {
          continue
        }
        guard self.cached_table_column(table_id) is Some(column_ref) else {
          continue
        }
        let entity_snapshot = entities.copy()
        for entity in entity_snapshot {
          guard self.world.entity_table_location(entity)
            is Some((actual_table_id, row_index)) else {
            continue
          }
          guard actual_table_id == table_id else { continue }
          guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
            continue
          }
          guard self.key.component_get_table_row(
              self.world,
              table_id,
              row_index,
            )
            is Some(value) else {
            continue
          }
          visit(entity, value)
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
  let archetype_ids = self.world.archetype_ids_for_component_local_id(
    self.local_component_id,
  )
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
    guard self.cached_table_column(table_id) is Some(column_ref) else {
      continue
    }
    let entity_snapshot = entities.copy()
    for entity in entity_snapshot {
      guard self.world.entity_table_row(entity) is Some(row) else { continue }
      let row_index = row.index()
      if row_index < 0 {
        continue
      }
      guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
        continue
      }
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(value) else {
        continue
      }
      visit(entity, value)
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
  let archetype_ids = self.world.archetype_ids_for_component_local_id(
    self.local_component_id,
  )
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
    guard self.cached_table_column(table_id) is Some(left_column_ref) else {
      continue
    }
    guard other.cached_table_column(table_id) is Some(right_column_ref) else {
      continue
    }
    let entity_snapshot = entities.copy()
    for entity in entity_snapshot {
      guard self.world.entity_table_row(entity) is Some(row) else { continue }
      let row_index = row.index()
      if row_index < 0 {
        continue
      }
      guard row_index < raw_table_column_kernel_len(left_column_ref.storage) &&
        row_index < raw_table_column_kernel_len(right_column_ref.storage) else {
        continue
      }
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(left_value) else {
        continue
      }
      guard other.key.component_get_table_row(self.world, table_id, row_index)
        is Some(right_value) else {
        continue
      }
      visit(entity, left_value, right_value)
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
  let table_ids = self.world.component_column_matching_table_ids([
    self.local_component_id,
  ])
  for table_id in table_ids {
    if self.world.table_has_component_local_id(
        table_id,
        other.local_component_id,
      ) {
      continue
    }
    guard self.cached_table_column(table_id) is Some(column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.rows.entities
    let row_count = entities.length()
    if raw_table_column_kernel_len(column_ref.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(value) else {
        continue
      }
      visit(entity, value)
    }
  }
}

///|
pub fn[T, U] ComponentColumn::for_each_with_fast(
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
pub fn[T, U] ComponentColumn::for_each_with_fast_table_row(
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
  let table_ids = self.world.component_column_matching_table_ids([
    self.local_component_id,
    other.local_component_id,
  ])
  for table_id in table_ids {
    guard self.cached_table_column(table_id) is Some(left_column_ref) else {
      continue
    }
    guard other.cached_table_column(table_id) is Some(right_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.rows.entities
    let row_count = entities.length()
    if raw_table_column_kernel_len(left_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(right_column_ref.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(left_value) else {
        continue
      }
      guard other.key.component_get_table_row(self.world, table_id, row_index)
        is Some(right_value) else {
        continue
      }
      visit(entity, table_id, row_index, left_value, right_value)
    }
  }
}

///|
pub fn[T, U, V] ComponentColumn::for_each3_fast_table_row(
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
  let table_ids = self.world.component_column_matching_table_ids([
    self.local_component_id,
    second.local_component_id,
    third.local_component_id,
  ])
  for table_id in table_ids {
    guard self.cached_table_column(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.cached_table_column(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.cached_table_column(table_id) is Some(third_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.rows.entities
    let row_count = entities.length()
    if raw_table_column_kernel_len(first_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(second_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(third_column_ref.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(first_value) else {
        continue
      }
      guard second.key.component_get_table_row(self.world, table_id, row_index)
        is Some(second_value) else {
        continue
      }
      guard third.key.component_get_table_row(self.world, table_id, row_index)
        is Some(third_value) else {
        continue
      }
      visit(entity, table_id, row_index, first_value, second_value, third_value)
    }
  }
}

///|
pub fn[T, U, V] ComponentColumn::for_each3_fast_table_row_mark_third_changed(
  self : ComponentColumn[T],
  second : ComponentColumn[U],
  third : ComponentColumn[V],
  tick : @core.Tick,
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
  let table_ids = self.world.component_column_matching_table_ids([
    self.local_component_id,
    second.local_component_id,
    third.local_component_id,
  ])
  for table_id in table_ids {
    guard self.cached_table_column(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.cached_table_column(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.cached_table_column(table_id) is Some(third_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.rows.entities
    let row_count = entities.length()
    if raw_table_column_kernel_len(first_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(second_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(third_column_ref.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(first_value) else {
        continue
      }
      guard second.key.component_get_table_row(self.world, table_id, row_index)
        is Some(second_value) else {
        continue
      }
      guard third.key.component_get_table_row(self.world, table_id, row_index)
        is Some(third_value) else {
        continue
      }
      if visit(
          entity, table_id, row_index, first_value, second_value, third_value,
        ) {
        ignore(third_column_ref.record_changed_at_row(row_index, tick, None))
      }
    }
  }
}

///|
pub fn[T, U, M, N] ComponentColumn::for_each2_with2_markers_fast_table_row(
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
  let table_ids = self.world.component_column_matching_table_ids([
    self.local_component_id,
    other.local_component_id,
    marker_a.local_component_id,
    marker_b.local_component_id,
  ])
  for table_id in table_ids {
    guard self.cached_table_column(table_id) is Some(first_column_ref) else {
      continue
    }
    guard other.cached_table_column(table_id) is Some(second_column_ref) else {
      continue
    }
    guard marker_a.cached_table_column(table_id) is Some(_) else { continue }
    guard marker_b.cached_table_column(table_id) is Some(_) else { continue }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.rows.entities
    let row_count = entities.length()
    if raw_table_column_kernel_len(first_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(second_column_ref.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(first_value) else {
        continue
      }
      guard other.key.component_get_table_row(self.world, table_id, row_index)
        is Some(second_value) else {
        continue
      }
      visit(entity, table_id, row_index, first_value, second_value)
    }
  }
}

///|
pub fn[T, U, V, W] ComponentColumn::for_each4_fast_table_row(
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
  let table_ids = self.world.component_column_matching_table_ids([
    self.local_component_id,
    second.local_component_id,
    third.local_component_id,
    fourth.local_component_id,
  ])
  for table_id in table_ids {
    guard self.cached_table_column(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.cached_table_column(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.cached_table_column(table_id) is Some(third_column_ref) else {
      continue
    }
    guard fourth.cached_table_column(table_id) is Some(fourth_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.rows.entities
    let row_count = entities.length()
    if raw_table_column_kernel_len(first_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(second_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(third_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(fourth_column_ref.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(first_value) else {
        continue
      }
      guard second.key.component_get_table_row(self.world, table_id, row_index)
        is Some(second_value) else {
        continue
      }
      guard third.key.component_get_table_row(self.world, table_id, row_index)
        is Some(third_value) else {
        continue
      }
      guard fourth.key.component_get_table_row(self.world, table_id, row_index)
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
pub fn[T, U, V, W, X] ComponentColumn::for_each5_fast_table_row(
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
  let table_ids = self.world.component_column_matching_table_ids([
    self.local_component_id,
    second.local_component_id,
    third.local_component_id,
    fourth.local_component_id,
    fifth.local_component_id,
  ])
  for table_id in table_ids {
    guard self.cached_table_column(table_id) is Some(first_column_ref) else {
      continue
    }
    guard second.cached_table_column(table_id) is Some(second_column_ref) else {
      continue
    }
    guard third.cached_table_column(table_id) is Some(third_column_ref) else {
      continue
    }
    guard fourth.cached_table_column(table_id) is Some(fourth_column_ref) else {
      continue
    }
    guard fifth.cached_table_column(table_id) is Some(fifth_column_ref) else {
      continue
    }
    guard self.world.table_storage(table_id) is Some(table_ref) else {
      continue
    }
    let entities = table_ref.rows.entities
    let row_count = entities.length()
    if raw_table_column_kernel_len(first_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(second_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(third_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(fourth_column_ref.storage) < row_count ||
      raw_table_column_kernel_len(fifth_column_ref.storage) < row_count {
      continue
    }
    for row_index in 0..<row_count {
      let entity = entities[row_index]
      guard self.key.component_get_table_row(self.world, table_id, row_index)
        is Some(first_value) else {
        continue
      }
      guard second.key.component_get_table_row(self.world, table_id, row_index)
        is Some(second_value) else {
        continue
      }
      guard third.key.component_get_table_row(self.world, table_id, row_index)
        is Some(third_value) else {
        continue
      }
      guard fourth.key.component_get_table_row(self.world, table_id, row_index)
        is Some(fourth_value) else {
        continue
      }
      guard fifth.key.component_get_table_row(self.world, table_id, row_index)
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
pub fn[T] ComponentColumn::set(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  if !self.set_tick_only(entity, value) {
    return false
  }
  self.world
  .ensure_changed_component_messages(self.key.id())
  .send(component_write_tick(self.world), entity)
  true
}

///|
pub fn[T] ComponentColumn::set_tick_only(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let tick = component_write_tick(self.world)
  if self.world.component_write_transaction_contains(
      entity,
      self.local_component_id,
    ) {
    self.key.component_set(self.world, entity, value)
    ignore(
      self.world.record_component_write_transaction_changed_metadata(
        entity,
        self.local_component_id,
        tick,
        None,
      ),
    )
    return true
  }
  match self.storage_type {
    SparseSet => {
      guard self.world.entity_has_component_local_id(
        entity,
        self.local_component_id,
      ) else {
        return false
      }
      self.key.component_set(self.world, entity, value)
      ignore(
        self.world.record_sparse_component_changed_by_local_id(
          entity,
          self.local_component_id,
          tick,
          None,
        ),
      )
      true
    }
    Table => {
      guard self.world.table_id_for_entity(entity) is Some(table_id) else {
        return false
      }
      guard self.world.entity_table_row(entity) is Some(row) else {
        return false
      }
      guard self.cached_table_column(table_id) is Some(column_ref) else {
        return false
      }
      let row_index = row.index()
      guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
        return false
      }
      self.key.component_set(self.world, entity, value)
      guard self.world.table_storage(table_id) is Some(table_ref) else {
        return false
      }
      ignore(
        table_ref.record_changed_at_row(
          row,
          self.local_component_id,
          tick,
          None,
        ),
      )
      true
    }
  }
}

///|
pub fn[T] ComponentColumn::set_tick_only_fast(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let tick = component_write_tick(self.world)
  match self.storage_type {
    SparseSet => {
      guard self.world.entity_has_component_local_id(
        entity,
        self.local_component_id,
      ) else {
        return false
      }
      self.key.component_set(self.world, entity, value)
      ignore(
        self.world.record_sparse_component_changed_by_local_id(
          entity,
          self.local_component_id,
          tick,
          None,
        ),
      )
      true
    }
    Table => {
      guard self.world.entity_table_location(entity)
        is Some((table_id, row_index)) else {
        return false
      }
      guard self.cached_table_column(table_id) is Some(column_ref) else {
        return false
      }
      guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
        return false
      }
      self.key.component_set(self.world, entity, value)
      ignore(column_ref.record_changed_at_row(row_index, tick, None))
      true
    }
  }
}

///|
pub fn[T] ComponentColumn::set_tick_only_hot(
  self : ComponentColumn[T],
  entity : @core.Entity,
  value : T,
) -> Bool {
  let tick = component_write_tick(self.world)
  match self.storage_type {
    SparseSet => {
      guard self.world.entity_has_component_local_id(
        entity,
        self.local_component_id,
      ) else {
        return false
      }
      self.key.component_set(self.world, entity, value)
      ignore(
        self.world.record_sparse_component_changed_by_local_id(
          entity,
          self.local_component_id,
          tick,
          None,
        ),
      )
      true
    }
    Table => {
      guard self.world.entity_table_location(entity)
        is Some((table_id, row_index)) else {
        return false
      }
      guard self.cached_table_column(table_id) is Some(column_ref) else {
        return false
      }
      guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
        return false
      }
      self.key.component_set(self.world, entity, value)
      ignore(column_ref.record_changed_at_row(row_index, tick, None))
      true
    }
  }
}

///|
pub fn[T] ComponentColumn::set_tick_only_hot_at_row(
  self : ComponentColumn[T],
  entity : @core.Entity,
  values : Array[T],
  row_index : Int,
  value : T,
  tick : @core.Tick,
) -> Bool {
  guard self.storage_type == Table else { return false }
  if row_index < 0 || row_index >= values.length() {
    return false
  }
  guard self.world.entity_table_location(entity)
    is Some((table_id, actual_row_index)) else {
    return false
  }
  guard actual_row_index == row_index else { return false }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return false
  }
  guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
    return false
  }
  values[row_index] = value
  self.key.component_set(self.world, entity, value)
  ignore(column_ref.record_changed_at_row(row_index, tick, None))
  true
}

///|
pub fn[T] ComponentColumn::set_tick_only_hot_at_table_row(
  self : ComponentColumn[T],
  table_id : Int,
  values : Array[T],
  row_index : Int,
  value : T,
  tick : @core.Tick,
) -> Bool {
  guard self.storage_type == Table else { return false }
  if row_index < 0 || row_index >= values.length() {
    return false
  }
  values[row_index] = value
  guard table_id >= 0 else { return false }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return false
  }
  guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
    return false
  }
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return false
  }
  guard TableRow::from_index(row_index) is Some(row) else { return false }
  guard table_ref.entity_at_row(row) is Some(entity) else { return false }
  self.key.component_set(self.world, entity, value)
  ignore(column_ref.record_changed_at_row(row_index, tick, None))
  true
}

///|
pub fn[T] ComponentColumn::set_tick_only_hot_at_table_row_value(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
  value : T,
  tick : @core.Tick,
) -> Bool {
  guard self.storage_type == Table else { return false }
  guard table_id >= 0 && row_index >= 0 else { return false }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return false
  }
  guard row_index < raw_table_column_kernel_len(column_ref.storage) else {
    return false
  }
  guard self.world.table_storage(table_id) is Some(table_ref) else {
    return false
  }
  guard TableRow::from_index(row_index) is Some(row) else { return false }
  guard table_ref.entity_at_row(row) is Some(entity) else { return false }
  self.key.component_set(self.world, entity, value)
  ignore(column_ref.record_changed_at_row(row_index, tick, None))
  true
}

///|
pub fn[T] ComponentColumn::record_changed_hot_at_table_row(
  self : ComponentColumn[T],
  table_id : Int,
  row_index : Int,
  tick : @core.Tick,
) -> Bool {
  guard self.storage_type == Table else { return false }
  guard table_id >= 0 && row_index >= 0 else { return false }
  guard self.cached_table_column(table_id) is Some(column_ref) else {
    return false
  }
  ignore(column_ref.record_changed_at_row(row_index, tick, None))
  true
}
