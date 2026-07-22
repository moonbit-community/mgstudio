// Copyright 2025 International Digital Economy Academy
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
#callsite(autofill(loc))
pub fn[T] World::replace(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  value : T,
  loc~ : SourceLoc,
) -> Bool raise EcsError {
  self.ensure_entity_alive(entity)
  let component_local_id = self.ensure_component_registered(key.id())
  guard self.component_present_by_local_id(entity, component_local_id) else {
    return false
  }
  let outermost = self.begin_deferred_hook_command_scope()
  let caller = hook_caller_from_loc(self, loc)
  self.run_component_replace_hooks(entity, key.id(), caller~)
  ignore(
    self.replace_component_value_by_local_id(
      entity, key, component_local_id, value,
    ),
  )
  self.record_component_changed_with_caller(entity, key.id(), caller)
  self.run_component_insert_hooks(entity, key.id(), caller~)
  self.end_deferred_hook_command_scope(outermost)
  true
}

///|
#callsite(autofill(loc))
pub fn[T] World::take(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  loc~ : SourceLoc,
) -> T? raise EcsError {
  self.ensure_entity_alive(entity)
  let outermost = self.begin_deferred_hook_command_scope()
  defer self.end_deferred_hook_command_scope(outermost)
  let caller = hook_caller_from_loc(self, loc)
  guard self.component_remove_transaction_for_key(entity, key.id(), caller)
    is Some(transaction) else {
    return None
  }
  self.ensure_query_iteration_can_change_structure("take component")
  self.commit_component_take_transaction(transaction, key)
}

///|
pub fn[T] World::component_count(self : World, key : ComponentKey[T]) -> Int {
  match self.local_component_id(key.id()) {
    Some(_) => self.component_membership_count_for_definition(key.id())
    None => 0
  }
}

///|
pub fn[T] World::for_each_component(
  self : World,
  key : ComponentKey[T],
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  match self.component_column(key) {
    Some(column) => column.for_each(visit)
    None => ()
  }
}
