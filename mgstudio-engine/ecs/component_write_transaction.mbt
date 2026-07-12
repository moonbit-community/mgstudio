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
priv struct ComponentWriteEntry {
  local_component_id : Int
  mut metadata : ComponentTickMetadata
}

///|
priv struct ComponentWriteSet {
  entries : Array[ComponentWriteEntry]
  indices_by_local_component_id : Map[Int, Int]
  presence : @utils.IntBitSet
}

///|
fn component_write_set_new() -> ComponentWriteSet {
  {
    entries: [],
    indices_by_local_component_id: Map([]),
    presence: @utils.IntBitSet::new(),
  }
}

///|
fn ComponentWriteSet::index_of(
  self : ComponentWriteSet,
  local_component_id : Int,
) -> Int? {
  self.indices_by_local_component_id.get(local_component_id)
}

///|
fn ComponentWriteSet::contains(
  self : ComponentWriteSet,
  local_component_id : Int,
) -> Bool {
  self.presence.contains(local_component_id)
}

///|
fn ComponentWriteSet::metadata(
  self : ComponentWriteSet,
  local_component_id : Int,
) -> ComponentTickMetadata? {
  match self.index_of(local_component_id) {
    Some(index) => Some(self.entries[index].metadata)
    None => None
  }
}

///|
fn ComponentWriteSet::insert(
  self : ComponentWriteSet,
  local_component_id : Int,
) -> Unit {
  if self.contains(local_component_id) {
    return
  }
  let index = self.entries.length()
  self.entries.push({
    local_component_id,
    metadata: component_tick_metadata_empty(),
  })
  self.indices_by_local_component_id.set(local_component_id, index)
  self.presence.insert(local_component_id)
}

///|
fn ComponentWriteSet::set_metadata(
  self : ComponentWriteSet,
  local_component_id : Int,
  metadata : ComponentTickMetadata,
) -> Unit {
  match self.index_of(local_component_id) {
    Some(index) => self.entries[index].metadata = metadata
    None => ()
  }
}

///|
priv struct ComponentWriteTransaction {
  entity_id : Int
  writes : ComponentWriteSet
}

///|
priv struct ComponentWriteTransactionState {
  mut active : ComponentWriteTransaction?
}

///|
priv struct ComponentInsertTransaction {
  entity : @core.Entity
  writes : ComponentWriteSet
  assume_no_existing_components : Bool
  caller : String?
  mut structural_changed : Bool
}

///|
fn component_write_transaction_state_new() -> ComponentWriteTransactionState {
  { active: None }
}

///|
fn ComponentWriteTransaction::ComponentWriteTransaction(
  entity : @core.Entity,
  writes : ComponentWriteSet,
) -> ComponentWriteTransaction {
  { entity_id: entity.id, writes }
}

///|
fn ComponentInsertTransaction::ComponentInsertTransaction(
  entity : @core.Entity,
  writes : ComponentWriteSet,
  assume_no_existing_components : Bool,
  caller : String?,
) -> ComponentInsertTransaction {
  {
    entity,
    writes,
    assume_no_existing_components,
    caller,
    structural_changed: false,
  }
}

///|
fn ComponentInsertTransaction::replaces_existing_component(
  self : ComponentInsertTransaction,
  world : World,
  component_definition_id : Int,
  component_local_id : Int,
) -> Bool {
  if self.assume_no_existing_components {
    self.writes.contains(component_local_id)
  } else {
    world.component_present(component_definition_id, self.entity)
  }
}

///|
fn ComponentInsertTransaction::mark_structural_changed(
  self : ComponentInsertTransaction,
) -> Unit {
  self.structural_changed = true
}

///|
fn ComponentWriteTransaction::targets_entity_id(
  self : ComponentWriteTransaction,
  entity_id : Int,
) -> Bool {
  self.entity_id == entity_id
}

///|
fn ComponentWriteTransaction::targets_entity(
  self : ComponentWriteTransaction,
  entity : @core.Entity,
) -> Bool {
  self.targets_entity_id(entity.id)
}

///|
fn ComponentWriteTransaction::contains(
  self : ComponentWriteTransaction,
  entity : @core.Entity,
  local_component_id : Int,
) -> Bool {
  self.targets_entity(entity) && self.writes.contains(local_component_id)
}

///|
fn ComponentWriteTransaction::metadata(
  self : ComponentWriteTransaction,
  entity_id : Int,
  local_component_id : Int,
) -> ComponentTickMetadata? {
  if self.targets_entity_id(entity_id) {
    self.writes.metadata(local_component_id)
  } else {
    None
  }
}

///|
fn ComponentWriteTransaction::record_added_metadata(
  self : ComponentWriteTransaction,
  entity : @core.Entity,
  local_component_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  if !self.contains(entity, local_component_id) {
    return false
  }
  self.writes.set_metadata(
    local_component_id,
    component_tick_metadata_with_added(
      self.writes.metadata(local_component_id),
      tick,
      caller,
    ),
  )
  true
}

///|
fn ComponentWriteTransaction::record_changed_metadata(
  self : ComponentWriteTransaction,
  entity : @core.Entity,
  local_component_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  if !self.contains(entity, local_component_id) {
    return false
  }
  self.writes.set_metadata(
    local_component_id,
    component_tick_metadata_with_changed(
      self.writes.metadata(local_component_id),
      tick,
      caller,
    ),
  )
  true
}

///|
fn World::component_write_transaction_contains(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> Bool {
  match self.component_write_transactions.active {
    Some(transaction) => transaction.contains(entity, local_component_id)
    None => false
  }
}

///|
fn World::active_component_write_set_for_entity(
  self : World,
  entity : @core.Entity,
) -> ComponentWriteSet? {
  match self.component_write_transactions.active {
    Some(transaction) if transaction.targets_entity(entity) =>
      Some(transaction.writes)
    _ => None
  }
}

///|
fn World::has_active_component_write_transaction_for_entity(
  self : World,
  entity : @core.Entity,
) -> Bool {
  self.active_component_write_set_for_entity(entity) is Some(_)
}

///|
fn World::begin_component_write_transaction(
  self : World,
  entity : @core.Entity,
  writes : ComponentWriteSet,
) -> ComponentWriteTransaction? {
  let previous = self.component_write_transactions.active
  self.component_write_transactions.active = Some(
    ComponentWriteTransaction(entity, writes),
  )
  previous
}

///|
fn World::restore_component_write_transaction(
  self : World,
  previous : ComponentWriteTransaction?,
) -> Unit {
  self.component_write_transactions.active = previous
}

///|
fn World::active_component_write_metadata(
  self : World,
  entity_id : Int,
  local_component_id : Int,
) -> ComponentTickMetadata? {
  match self.component_write_transactions.active {
    Some(transaction) => transaction.metadata(entity_id, local_component_id)
    None => None
  }
}

///|
fn World::clear_component_write_transaction_metadata(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
) -> Unit {
  match self.component_write_transactions.active {
    Some(transaction) if transaction.targets_entity(entity) =>
      transaction.writes.set_metadata(
        local_component_id,
        component_tick_metadata_empty(),
      )
    _ => ()
  }
}

///|
fn World::record_component_write_transaction_added_metadata(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  match self.component_write_transactions.active {
    Some(transaction) =>
      transaction.record_added_metadata(
        entity, local_component_id, tick, caller,
      )
    None => false
  }
}

///|
fn World::record_component_write_transaction_changed_metadata(
  self : World,
  entity : @core.Entity,
  local_component_id : Int,
  tick : @core.Tick,
  caller : String?,
) -> Bool {
  match self.component_write_transactions.active {
    Some(transaction) =>
      transaction.record_changed_metadata(
        entity, local_component_id, tick, caller,
      )
    None => false
  }
}
