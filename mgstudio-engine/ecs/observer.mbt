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
pub struct On[E] {
  entity : @core.Entity?
  caller : String?
  event_ref : Ref[E]
  propagate_ref : Ref[Bool]
}

///|
pub fn[E] On::caller(self : On[E]) -> String? {
  self.caller
}

///|
pub fn[E] On::entity(self : On[E]) -> @core.Entity? {
  self.entity
}

///|
pub fn[E] On::event(self : On[E]) -> E {
  self.event_ref.val
}

///|
pub fn[E] On::get_ref(self : On[E]) -> Ref[E] {
  self.event_ref
}

///|
pub fn[E] On::propagate(self : On[E], enabled : Bool) -> Unit {
  self.propagate_ref.val = enabled
}

///|
pub fn[E] On::is_propagating(self : On[E]) -> Bool {
  self.propagate_ref.val
}

///|
pub struct ComponentOn[E, C] {
  entity : @core.Entity
  caller : String?
  marker_event : E?
  marker_component : C?
}

///|
pub fn[E, C] ComponentOn::caller(self : ComponentOn[E, C]) -> String? {
  self.caller
}

///|
pub(open) trait ComponentObserverEvent {
  register_component_observer(World, Int, @core.Entity?, (World) -> Unit) -> ObserverHandle
  current_observer_entity() -> @core.Entity
  current_observer_component_id() -> Int
  marker() -> Self
  debug_name() -> String
}

///|
pub(open) trait TriggerEvent {
  observer_event() -> EventKey[Self]
  observer_entity(Self) -> @core.Entity?
  set_observer_entity(Ref[Self], @core.Entity) -> Unit
  auto_propagate(Self) -> Bool
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
struct ComponentObserverContext {
  entity : @core.Entity
  component_id : Int
}

///|
struct TriggerObserverContext {
  event_key_id : Int
  entity : @core.Entity?
  payload : ErasedValue
  caller : String?
  propagate_ref : Ref[Bool]
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
priv struct TriggerObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
struct WorldObserverRegistry {
  mut next_observer_id : Int
  insert_observers : @hashmap.HashMap[Int, Array[InsertObserver]]
  remove_observers : @hashmap.HashMap[Int, Array[RemoveObserver]]
  trigger_observers : @hashmap.HashMap[Int, Array[TriggerObserver]]
}

///|
fn world_observer_registry_new() -> WorldObserverRegistry {
  {
    next_observer_id: 1,
    insert_observers: @hashmap.HashMap::new(),
    remove_observers: @hashmap.HashMap::new(),
    trigger_observers: @hashmap.HashMap::new(),
  }
}

///|
let current_observer_world_ref : Ref[World?] = Ref::new(None)

///|
fn observer_registry_ref(world : World) -> Ref[WorldObserverRegistry] {
  world.observer_registry
}

///|
fn[T] erased_ref(value_ref : Ref[T]) -> ErasedValue {
  { value: @any.of(value_ref) }
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
fn current_component_observer_context_abort_missing() -> ComponentObserverContext {
  let world = current_observer_world_abort_missing()
  match world.current_component_observer_context {
    Some(context) => context
    None => abort("Missing current component observer context")
  }
}

///|
fn current_trigger_observer_context_abort_missing() -> TriggerObserverContext {
  let world = current_observer_world_abort_missing()
  match world.current_trigger_observer_context {
    Some(context) => context
    None => abort("Missing current trigger observer context")
  }
}

///|
pub fn[E : TriggerEvent] current_observer() -> On[E] {
  let context = current_trigger_observer_context_abort_missing()
  let event_key : EventKey[E] = E::observer_event()
  if context.event_key_id != event_key.id() {
    abort(
      "Current \{E::debug_name()} observer context does not match event `\{event_key.debug_name()}`",
    )
  }
  let event_ref : Ref[E] = context.payload.to_ref() catch {
    _ =>
      abort(
        "Current trigger observer payload type mismatch for `\{E::debug_name()}`",
      )
  }
  On::{
    entity: context.entity,
    caller: context.caller,
    event_ref,
    propagate_ref: context.propagate_ref,
  }
}

///|
pub fn[E : ComponentObserverEvent, C : Component] current_component_observer() -> ComponentOn[
  E,
  C,
] {
  let context = current_component_observer_context_abort_missing()
  let component_key : ComponentKey[C] = Component::component()
  if context.component_id != component_key.id() {
    abort(
      "Current \{E::debug_name()} observer context does not match component `\{component_key.debug_name()}`",
    )
  }
  ComponentOn::{
    entity: context.entity,
    caller: None,
    marker_event: Some(E::marker()),
    marker_component: None,
  }
}

///|
pub fn[C : Component] current_insert_observer() -> ComponentOn[Insert, C] {
  current_component_observer()
}

///|
pub fn[C : Component] current_remove_observer() -> ComponentOn[Remove, C] {
  current_component_observer()
}

///|
fn World::register_insert_component_observer(
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
fn World::register_remove_component_observer(
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
fn World::register_trigger_observer(
  self : World,
  event_key_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let registry_ref = observer_registry_ref(self)
  let observer_id = registry_ref.val.next_observer_id
  registry_ref.val.next_observer_id = observer_id + 1
  let observers = registry_ref.val.trigger_observers.get_or_init(event_key_id, fn() {
    []
  })
  observers.push(TriggerObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
pub impl ComponentObserverEvent for Insert with register_component_observer(
  world,
  component_id,
  entity,
  observer,
) {
  world.register_insert_component_observer(component_id, entity, observer)
}

///|
pub impl ComponentObserverEvent for Insert with current_observer_entity() {
  current_component_observer_context_abort_missing().entity
}

///|
pub impl ComponentObserverEvent for Insert with current_observer_component_id() {
  current_component_observer_context_abort_missing().component_id
}

///|
pub impl ComponentObserverEvent for Insert with marker() {
  Insert::{  }
}

///|
pub impl ComponentObserverEvent for Insert with debug_name() {
  "insert"
}

///|
pub impl ComponentObserverEvent for Remove with register_component_observer(
  world,
  component_id,
  entity,
  observer,
) {
  world.register_remove_component_observer(component_id, entity, observer)
}

///|
pub impl ComponentObserverEvent for Remove with current_observer_entity() {
  current_component_observer_context_abort_missing().entity
}

///|
pub impl ComponentObserverEvent for Remove with current_observer_component_id() {
  current_component_observer_context_abort_missing().component_id
}

///|
pub impl ComponentObserverEvent for Remove with marker() {
  Remove::{  }
}

///|
pub impl ComponentObserverEvent for Remove with debug_name() {
  "remove"
}

///|
pub fn[E : ComponentObserverEvent, C : Component] World::add_component_observer(
  self : World,
  observer : (ComponentOn[E, C]) -> Unit,
) -> ObserverHandle {
  let component_key : ComponentKey[C] = Component::component()
  E::register_component_observer(self, component_key.id(), None, fn(_world) {
    let event : ComponentOn[E, C] = current_component_observer()
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_remove_component_observer(
  self : World,
  observer : (ComponentOn[Remove, C]) -> Unit,
) -> ObserverHandle {
  self.add_component_observer(fn(event : ComponentOn[Remove, C]) {
    observer(event)
  })
}

///|
pub fn[E : ComponentObserverEvent, C : Component] World::add_entity_component_observer(
  self : World,
  entity : @core.Entity,
  observer : (ComponentOn[E, C]) -> Unit,
) -> ObserverHandle {
  let component_key : ComponentKey[C] = Component::component()
  E::register_component_observer(self, component_key.id(), Some(entity), fn(
    _world,
  ) {
    let event : ComponentOn[E, C] = current_component_observer()
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_remove_entity_component_observer(
  self : World,
  entity : @core.Entity,
  observer : (ComponentOn[Remove, C]) -> Unit,
) -> ObserverHandle {
  self.add_entity_component_observer(entity, fn(
    event : ComponentOn[Remove, C],
  ) {
    observer(event)
  })
}

///|
pub fn[E : TriggerEvent] World::add_observer(
  self : World,
  observer : (On[E]) -> Unit,
) -> ObserverHandle {
  let event_key : EventKey[E] = E::observer_event()
  self.register_trigger_observer(event_key.id(), None, fn(_world) {
    let event : On[E] = current_observer()
    observer(event)
  })
}

///|
pub fn[E : TriggerEvent] World::add_entity_observer(
  self : World,
  entity : @core.Entity,
  observer : (On[E]) -> Unit,
) -> ObserverHandle {
  let event_key : EventKey[E] = E::observer_event()
  self.register_trigger_observer(event_key.id(), Some(entity), fn(_world) {
    let event : On[E] = current_observer()
    observer(event)
  })
}

///|
fn World::insert_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[InsertObserver]? {
  self.observer_registry.val.insert_observers.get(component_id)
}

///|
fn World::remove_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[RemoveObserver]? {
  self.observer_registry.val.remove_observers.get(component_id)
}

///|
fn World::trigger_observers_for_event(
  self : World,
  event_key_id : Int,
) -> Array[TriggerObserver]? {
  self.observer_registry.val.trigger_observers.get(event_key_id)
}

///|
fn observer_parent_entity(
  world : World,
  entity : @core.Entity,
) -> @core.Entity? {
  for component_id in world.observer_parent_lookup_component_ids {
    match component_metadata(component_id).relationship_source {
      Some(source) if source.observer_parent_lookup =>
        match (source.target_entity)(world, entity) {
          Some(parent) => return Some(parent)
          None => ()
        }
      _ => ()
    }
  }
  None
}

///|
pub fn[E : TriggerEvent] World::trigger(
  self : World,
  event : E,
  caller? : String? = None,
) -> Unit {
  let event_key : EventKey[E] = E::observer_event()
  let event_ref : Ref[E] = Ref::new(event)
  let payload = erased_ref(event_ref)
  let propagate_ref : Ref[Bool] = Ref::new(E::auto_propagate(event_ref.val))
  let previous_context = self.current_trigger_observer_context
  let previous_world = current_observer_world_ref.val
  current_observer_world_ref.val = Some(self)
  while true {
    let entity = E::observer_entity(event_ref.val)
    self.current_trigger_observer_context = Some({
      event_key_id: event_key.id(),
      entity,
      payload,
      caller,
      propagate_ref,
    })
    self.run_trigger_observers(event_key.id())
    if !propagate_ref.val {
      break
    }
    guard entity is Some(current_entity) else { break }
    guard observer_parent_entity(self, current_entity) is Some(parent) else {
      break
    }
    E::set_observer_entity(event_ref, parent)
  }
  current_observer_world_ref.val = previous_world
  self.current_trigger_observer_context = previous_context
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
  let previous_context = self.current_component_observer_context
  let previous_world = current_observer_world_ref.val
  self.current_component_observer_context = Some({ entity, component_id })
  current_observer_world_ref.val = Some(self)
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  current_observer_world_ref.val = previous_world
  self.current_component_observer_context = previous_context
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
  let previous_context = self.current_component_observer_context
  let previous_world = current_observer_world_ref.val
  self.current_component_observer_context = Some({ entity, component_id })
  current_observer_world_ref.val = Some(self)
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  current_observer_world_ref.val = previous_world
  self.current_component_observer_context = previous_context
}

///|
fn World::run_trigger_observers(self : World, event_key_id : Int) -> Unit {
  guard self.trigger_observers_for_event(event_key_id) is Some(observers) else {
    return
  }
  let context = current_trigger_observer_context_abort_missing()
  let pending : Array[TriggerObserver] = []
  for observer in observers {
    if observer.entity is Some(target_entity) &&
      context.entity != Some(target_entity) {
      continue
    }
    pending.push(observer)
  }
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
}
