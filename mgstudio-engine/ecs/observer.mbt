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
pub struct Insert {}

///|
pub struct Remove {}

///|
pub struct On[E, C] {
  entity : @core.Entity
  marker_event : E?
  marker_component : C?
}

///|
pub(open) trait ObserverEvent {
  register_observer(World, Int, @core.Entity?, (World) -> Unit) -> ObserverHandle
  current_observer_entity() -> @core.Entity
  current_observer_component_id() -> Int
  marker() -> Self
  debug_name() -> String
}

///|
pub struct ObserverHandle {
  id : Int
  world_id : Int
}

///|
pub fn ObserverHandle::id(self : ObserverHandle) -> Int {
  self.id
}

///|
pub fn ObserverHandle::world_id(self : ObserverHandle) -> Int {
  self.world_id
}

///|
priv struct ObserverContext {
  entity : @core.Entity
  component_id : Int
}

///|
priv struct InsertObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct RemoveObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct WorldObserverRegistry {
  mut next_observer_id : Int
  insert_observers : @hashmap.HashMap[Int, Array[InsertObserver]]
  remove_observers : @hashmap.HashMap[Int, Array[RemoveObserver]]
}

///|
fn world_observer_registry_new() -> WorldObserverRegistry {
  {
    next_observer_id: 1,
    insert_observers: @hashmap.HashMap::new(),
    remove_observers: @hashmap.HashMap::new(),
  }
}

///|
let insert_observer_registries : @hashmap.HashMap[
  Int,
  Ref[WorldObserverRegistry],
] = @hashmap.HashMap::new()

///|
let current_observer_context_ref : Ref[ObserverContext?] = Ref::new(None)

///|
let current_observer_world_ref : Ref[World?] = Ref::new(None)

///|
fn observer_registry_ref(world : World) -> Ref[WorldObserverRegistry] {
  insert_observer_registries.get_or_init(world.world_id(), fn() {
    Ref::new(world_observer_registry_new())
  })
}

///|
pub fn current_observer_world() -> World? {
  current_observer_world_ref.val
}

///|
pub fn current_observer_world_abort_missing() -> World {
  match current_observer_world() {
    Some(world) => world
    None => abort("Missing current observer world")
  }
}

///|
fn current_observer_context_abort_missing() -> ObserverContext {
  match current_observer_context_ref.val {
    Some(context) => context
    None => abort("Missing current observer context")
  }
}

///|
pub fn[E : ObserverEvent, C : Component] current_observer() -> On[E, C] {
  let context = current_observer_context_abort_missing()
  let component_key : ComponentKey[C] = Component::component()
  if context.component_id != component_key.id() {
    abort(
      "Current " +
      E::debug_name() +
      " observer context does not match component `" +
      component_key.debug_name() +
      "`",
    )
  }
  On::{
    entity: context.entity,
    marker_event: Some(E::marker()),
    marker_component: None,
  }
}

///|
pub fn[C : Component] current_insert_observer() -> On[Insert, C] {
  current_observer()
}

///|
pub fn[C : Component] current_remove_observer() -> On[Remove, C] {
  current_observer()
}

///|
fn World::register_insert_observer(
  self : World,
  component_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let registry_ref = observer_registry_ref(self)
  let observer_id = registry_ref.val.next_observer_id
  registry_ref.val.next_observer_id = observer_id + 1
  let observers = registry_ref.val.insert_observers.get_or_init(component_id, fn() {
    []
  })
  observers.push(InsertObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
fn World::register_remove_observer(
  self : World,
  component_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let registry_ref = observer_registry_ref(self)
  let observer_id = registry_ref.val.next_observer_id
  registry_ref.val.next_observer_id = observer_id + 1
  let observers = registry_ref.val.remove_observers.get_or_init(component_id, fn() {
    []
  })
  observers.push(RemoveObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
pub impl ObserverEvent for Insert with register_observer(
  world,
  component_id,
  entity,
  observer,
) {
  world.register_insert_observer(component_id, entity, observer)
}

///|
pub impl ObserverEvent for Insert with current_observer_entity() {
  current_observer_context_abort_missing().entity
}

///|
pub impl ObserverEvent for Insert with current_observer_component_id() {
  current_observer_context_abort_missing().component_id
}

///|
pub impl ObserverEvent for Insert with marker() {
  Insert::{  }
}

///|
pub impl ObserverEvent for Insert with debug_name() {
  "insert"
}

///|
pub impl ObserverEvent for Remove with register_observer(
  world,
  component_id,
  entity,
  observer,
) {
  world.register_remove_observer(component_id, entity, observer)
}

///|
pub impl ObserverEvent for Remove with current_observer_entity() {
  current_observer_context_abort_missing().entity
}

///|
pub impl ObserverEvent for Remove with current_observer_component_id() {
  current_observer_context_abort_missing().component_id
}

///|
pub impl ObserverEvent for Remove with marker() {
  Remove::{  }
}

///|
pub impl ObserverEvent for Remove with debug_name() {
  "remove"
}

///|
pub fn[E : ObserverEvent, C : Component] World::add_observer(
  self : World,
  observer : (On[E, C]) -> Unit,
) -> ObserverHandle {
  let component_key : ComponentKey[C] = Component::component()
  E::register_observer(self, component_key.id(), None, fn(_world) {
    let event : On[E, C] = current_observer()
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_remove_observer(
  self : World,
  observer : (On[Remove, C]) -> Unit,
) -> ObserverHandle {
  self.add_observer(fn(event : On[Remove, C]) { observer(event) })
}

///|
pub fn[E : ObserverEvent, C : Component] World::add_entity_observer(
  self : World,
  entity : @core.Entity,
  observer : (On[E, C]) -> Unit,
) -> ObserverHandle {
  let component_key : ComponentKey[C] = Component::component()
  E::register_observer(self, component_key.id(), Some(entity), fn(_world) {
    let event : On[E, C] = current_observer()
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_remove_entity_observer(
  self : World,
  entity : @core.Entity,
  observer : (On[Remove, C]) -> Unit,
) -> ObserverHandle {
  self.add_entity_observer(entity, fn(event : On[Remove, C]) { observer(event) })
}

///|
fn World::insert_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[InsertObserver]? {
  match insert_observer_registries.get(self.world_id()) {
    Some(registry_ref) => registry_ref.val.insert_observers.get(component_id)
    None => None
  }
}

///|
fn World::remove_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[RemoveObserver]? {
  match insert_observer_registries.get(self.world_id()) {
    Some(registry_ref) => registry_ref.val.remove_observers.get(component_id)
    None => None
  }
}

///|
fn World::run_insert_observers(
  self : World,
  entity : @core.Entity,
  component_id : Int,
) -> Unit {
  guard self.insert_observers_for_component(component_id) is Some(observers) else {
    return
  }
  let pending : Array[InsertObserver] = []
  for observer in observers {
    if observer.entity is Some(target_entity) && target_entity != entity {
      continue
    }
    pending.push(observer)
  }
  let previous_context = current_observer_context_ref.val
  let previous_world = current_observer_world_ref.val
  current_observer_context_ref.val = Some({ entity, component_id })
  current_observer_world_ref.val = Some(self)
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  current_observer_world_ref.val = previous_world
  current_observer_context_ref.val = previous_context
}

///|
fn World::run_remove_observers(
  self : World,
  entity : @core.Entity,
  component_id : Int,
) -> Unit {
  guard self.remove_observers_for_component(component_id) is Some(observers) else {
    return
  }
  let pending : Array[RemoveObserver] = []
  for observer in observers {
    if observer.entity is Some(target_entity) && target_entity != entity {
      continue
    }
    pending.push(observer)
  }
  let previous_context = current_observer_context_ref.val
  let previous_world = current_observer_world_ref.val
  current_observer_context_ref.val = Some({ entity, component_id })
  current_observer_world_ref.val = Some(self)
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  current_observer_world_ref.val = previous_world
  current_observer_context_ref.val = previous_context
}
