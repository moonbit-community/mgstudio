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
  guard self.component_store(key.id()) is Some(store_ref) else { return false }
  guard store_ref.val.get(entity) is Some(_) else { return false }
  let payload = erased_value(value)
  let outermost = self.begin_deferred_hook_command_scope()
  let caller = hook_caller_from_loc(loc)
  self.run_component_replace_hooks(entity, key.id(), caller~)
  ignore(store_ref.val.set(entity, payload))
  self.record_component_changed(entity, key.id())
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
  let previous = self.get_by_key(entity, key)
  if previous is Some(_) {
    self.remove_by_key(entity, key, loc~) |> ignore
  }
  previous
}

///|
pub fn[T] World::component_count(self : World, key : ComponentKey[T]) -> Int {
  match self.component_store(key.id()) {
    Some(store_ref) => store_ref.val.len()
    None => 0
  }
}

///|
pub fn[T] World::for_each_component(
  self : World,
  key : ComponentKey[T],
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  guard self.component_store(key.id()) is Some(store_ref) else { return }
  let entries : Array[(@core.Entity, ErasedValue)] = []
  store_ref.val.for_each(fn(entity, payload) { entries.push((entity, payload)) })
  for entry in entries {
    try self.component_value(key, entry.0, entry.1) catch {
      _ => ()
    } noraise {
      value => visit(entry.0, value)
    }
  }
}
