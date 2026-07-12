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
priv struct ComponentRemoval {
  definition_id : Int
  local_id : Int
}

///|
priv struct ComponentRemoveTransaction {
  entity : @core.Entity
  caller : String?
  removals : Array[ComponentRemoval]
}

///|
fn ComponentRemoveTransaction::ComponentRemoveTransaction(
  entity : @core.Entity,
  caller : String?,
) -> ComponentRemoveTransaction {
  { entity, caller, removals: [] }
}

///|
fn ComponentRemoveTransaction::is_empty(
  self : ComponentRemoveTransaction,
) -> Bool {
  self.removals.is_empty()
}

///|
fn ComponentRemoveTransaction::add(
  self : ComponentRemoveTransaction,
  definition_id : Int,
  local_id : Int,
) -> Unit {
  self.removals.push({ definition_id, local_id })
}

///|
fn World::component_remove_transaction_for_key(
  self : World,
  entity : @core.Entity,
  definition_id : Int,
  caller : String?,
) -> ComponentRemoveTransaction? {
  guard self.component_present(definition_id, entity) else { return None }
  let local_id = self.ensure_component_registered(definition_id)
  let transaction = ComponentRemoveTransaction(entity, caller)
  transaction.add(definition_id, local_id)
  Some(transaction)
}

///|
fn World::component_remove_transaction_for_despawn(
  self : World,
  entity : @core.Entity,
  caller : String?,
) -> ComponentRemoveTransaction {
  let transaction = ComponentRemoveTransaction(entity, caller)
  let component_local_ids = self.entity_local_components(entity).copy()
  for local_id in component_local_ids {
    guard self.definition_component_id(local_id) is Some(definition_id) else {
      continue
    }
    if self.component_present_by_local_id(entity, local_id) {
      transaction.add(definition_id, local_id)
    }
  }
  transaction
}

///|
fn World::run_component_remove_transaction_despawn_phase(
  self : World,
  transaction : ComponentRemoveTransaction,
) -> Unit {
  for removal in transaction.removals {
    self.run_component_despawn_hooks(
      transaction.entity,
      removal.definition_id,
      caller=transaction.caller,
    )
    self.run_despawn_observers(transaction.entity, removal.definition_id)
  }
}

///|
fn World::run_component_remove_transaction_replace_remove_phase(
  self : World,
  transaction : ComponentRemoveTransaction,
) -> Unit {
  for removal in transaction.removals {
    self.run_component_replace_hooks(
      transaction.entity,
      removal.definition_id,
      caller=transaction.caller,
    )
    self.run_replace_observers(transaction.entity, removal.definition_id)
    self.run_component_remove_hooks(
      transaction.entity,
      removal.definition_id,
      caller=transaction.caller,
    )
  }
}

///|
fn World::commit_removed_component_effects(
  self : World,
  transaction : ComponentRemoveTransaction,
) -> Unit {
  let tick = component_write_tick(self)
  for removal in transaction.removals {
    ignore(
      self.remove_component_write_by_local_id(
        transaction.entity,
        removal.local_id,
      ),
    )
    self
    .ensure_removed_component_messages(removal.definition_id)
    .send(tick, transaction.entity)
    self.clear_component_tick_records(transaction.entity, removal.definition_id)
  }
}

///|
fn World::run_component_remove_transaction_remove_observer_phase(
  self : World,
  transaction : ComponentRemoveTransaction,
) -> Unit {
  for removal in transaction.removals {
    self.run_remove_observers(transaction.entity, removal.definition_id)
  }
}

///|
fn World::commit_component_remove_transaction(
  self : World,
  transaction : ComponentRemoveTransaction,
) -> Unit {
  if transaction.is_empty() {
    return
  }
  let removal = transaction.removals[0]
  self.run_component_remove_transaction_replace_remove_phase(transaction)
  self.run_component_remove_transaction_remove_observer_phase(transaction)
  ignore(
    self.remove_component_write_by_local_id(
      transaction.entity,
      removal.local_id,
    ),
  )
  self.entity_remove_component_local_id(transaction.entity, removal.local_id)
  self.refresh_entity_archetype_after_component_remove(
    transaction.entity,
    removal.local_id,
  )
  self.mark_structure_changed()
  self
  .ensure_removed_component_messages(removal.definition_id)
  .send(component_write_tick(self), transaction.entity)
  self.clear_component_tick_records(transaction.entity, removal.definition_id)
}

///|
fn World::commit_component_despawn_transaction(
  self : World,
  transaction : ComponentRemoveTransaction,
) -> Unit raise EcsError {
  self.run_component_remove_transaction_despawn_phase(transaction)
  self.run_component_remove_transaction_replace_remove_phase(transaction)
  self.run_component_remove_transaction_remove_observer_phase(transaction)
  self.commit_removed_component_effects(transaction)
  let freed = self.entities.despawn(transaction.entity) catch {
    err => raise EntityStateError(err)
  }
  self.free_spawned_entity(freed)
  self.clear_entity_archetype_tracking(transaction.entity)
  self.mark_entity_lifecycle_changed()
  self.mark_structure_changed()
}
