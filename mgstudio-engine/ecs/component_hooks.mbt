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
pub(all) suberror ComponentHooksError {
  DuplicateRegistration(Int)
}

///|
pub struct ComponentHooks {
  on_insert : ((World, @core.Entity, Json) -> Unit)?
  on_replace : ((World, @core.Entity, Json, Json) -> Unit)?
  on_remove : ((World, @core.Entity, Json) -> Unit)?
  on_despawn : ((World, @core.Entity, Json) -> Unit)?
}

///|
pub fn ComponentHooks::new(
  on_insert? : ((World, @core.Entity, Json) -> Unit)? = None,
  on_replace? : ((World, @core.Entity, Json, Json) -> Unit)? = None,
  on_remove? : ((World, @core.Entity, Json) -> Unit)? = None,
  on_despawn? : ((World, @core.Entity, Json) -> Unit)? = None,
) -> ComponentHooks {
  { on_insert, on_replace, on_remove, on_despawn }
}

///|
let component_hooks_registry : @hashmap.HashMap[Int, ComponentHooks] = @hashmap.HashMap::new()

///|
pub fn[T] register_component_hooks(
  key : ComponentKey[T],
  hooks : ComponentHooks,
) -> Unit raise ComponentHooksError {
  if component_hooks_registry.contains(key.id()) {
    raise DuplicateRegistration(key.id())
  }
  component_hooks_registry.set(key.id(), hooks)
}

///|
fn component_hooks(component_id : Int) -> ComponentHooks? {
  component_hooks_registry.get(component_id)
}

///|
fn World::run_component_insert_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  payload : Json,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_insert is Some(on_insert) {
    on_insert(self, entity, payload)
  }
}

///|
fn World::run_component_replace_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  old_payload : Json,
  new_payload : Json,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_replace is Some(on_replace) {
    on_replace(self, entity, old_payload, new_payload)
  }
}

///|
fn World::run_component_remove_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  payload : Json,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_remove is Some(on_remove) {
    on_remove(self, entity, payload)
  }
}

///|
fn World::run_component_despawn_hooks(
  self : World,
  entity : @core.Entity,
  component_id : Int,
  payload : Json,
) -> Unit {
  guard component_hooks(component_id) is Some(hooks) else { return }
  if hooks.on_despawn is Some(on_despawn) {
    on_despawn(self, entity, payload)
  }
}
