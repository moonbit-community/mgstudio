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
pub struct Add {}

///|
pub struct Insert {}

///|
pub struct Replace {}

///|
pub struct Remove {}

///|
pub struct Despawn {}

///|
pub struct On[E] {
  priv world : World
  priv event_key : EventKey[E]
  priv entity : @core.Entity?
  priv caller : String?
}

///|
pub fn[E] On::world(self : On[E]) -> World {
  self.world
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
  let context = self.world.current_trigger_observer_context_abort_missing()
  if context.event_key_id != self.event_key.id() {
    abort("Current observer event is no longer available")
  }
  match (self.event_key.access.current_trigger)(self.world) {
    Some(event) => event
    None => abort("Current observer event is no longer available")
  }
}

///|
pub fn[E] On::propagate(self : On[E], enabled : Bool) -> Unit {
  let context = self.world.current_trigger_observer_context_abort_missing()
  if context.event_key_id != self.event_key.id() {
    abort("Current observer event is no longer available")
  }
  context.propagate = enabled
}

///|
pub fn[E] On::is_propagating(self : On[E]) -> Bool {
  let context = self.world.current_trigger_observer_context_abort_missing()
  if context.event_key_id != self.event_key.id() {
    abort("Current observer event is no longer available")
  }
  context.propagate
}

///|
pub fn[E, R] On::modify(self : On[E], f : (E) -> R) -> R {
  let context = self.world.current_trigger_observer_context_abort_missing()
  if context.event_key_id != self.event_key.id() {
    abort("Current observer event is no longer available")
  }
  let event = match (self.event_key.access.current_trigger)(self.world) {
    Some(event) => event
    None => abort("Current observer event is no longer available")
  }
  let result = f(event)
  (self.event_key.access.set_current_trigger)(self.world, event)
  result
}

///|
pub struct ComponentOn[E, C] {
  priv world : World
  priv entity : @core.Entity
  priv caller : String?
  priv marker_event : E?
  priv marker_component : C?
}

///|
pub fn[E, C] ComponentOn::world(self : ComponentOn[E, C]) -> World {
  self.world
}

///|
pub fn[E, C] ComponentOn::caller(self : ComponentOn[E, C]) -> String? {
  self.caller
}

///|
pub fn[E, C] ComponentOn::entity(self : ComponentOn[E, C]) -> @core.Entity {
  self.entity
}

///|
pub fn[E, C] ComponentOn::marker_event(self : ComponentOn[E, C]) -> E? {
  self.marker_event
}

///|
pub fn[E, C] ComponentOn::marker_component(self : ComponentOn[E, C]) -> C? {
  self.marker_component
}

///|
pub(open) trait ComponentObserverEvent {
  fn register_component_observer(World, Int, @core.Entity?, (World) -> Unit) -> ObserverHandle
  fn marker() -> Self
  fn debug_name() -> String
}

///|
pub(open) trait TriggerEvent {
  fn observer_event() -> EventKey[Self]
  fn observer_entity(Self) -> @core.Entity?
  fn set_observer_entity(Self, @core.Entity) -> Self
  fn auto_propagate(Self) -> Bool
  fn debug_name() -> String
}

///|
pub struct ObserverHandle {
  priv id : Int
  priv world_id : Int
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
  caller : String?
  mut propagate : Bool
}

///|
priv struct InsertObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct AddObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct ReplaceObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct RemoveObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct DespawnObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct TriggerObserver {
  entity : @core.Entity?
  run : (World) -> Unit
}

///|
priv struct ObserverParentLookupAccessor {
  local_component_id : Int
  target_entity : (World, @core.Entity) -> @core.Entity?
}

///|
struct WorldObserverRegistry {
  mut next_observer_id : Int
  add_observers : @hashmap.HashMap[Int, Array[AddObserver]]
  insert_observers : @hashmap.HashMap[Int, Array[InsertObserver]]
  replace_observers : @hashmap.HashMap[Int, Array[ReplaceObserver]]
  remove_observers : @hashmap.HashMap[Int, Array[RemoveObserver]]
  despawn_observers : @hashmap.HashMap[Int, Array[DespawnObserver]]
  trigger_observers : @hashmap.HashMap[Int, Array[TriggerObserver]]
  mut observer_parent_lookup_accessors : Array[ObserverParentLookupAccessor]
  mut observer_parent_lookup_component_registration_generation : Int
  mut observer_parent_lookup_archetype_generation : Int
  mut observer_parent_lookup_metadata_generation : Int
}

///|
fn world_observer_registry_new() -> WorldObserverRegistry {
  {
    next_observer_id: 1,
    add_observers: @hashmap.HashMap([]),
    insert_observers: @hashmap.HashMap([]),
    replace_observers: @hashmap.HashMap([]),
    remove_observers: @hashmap.HashMap([]),
    despawn_observers: @hashmap.HashMap([]),
    trigger_observers: @hashmap.HashMap([]),
    observer_parent_lookup_accessors: [],
    observer_parent_lookup_component_registration_generation: -1,
    observer_parent_lookup_archetype_generation: -1,
    observer_parent_lookup_metadata_generation: -1,
  }
}

///|
fn World::current_component_observer_context_abort_missing(
  self : World,
) -> ComponentObserverContext {
  match self.current_component_observer_context {
    Some(context) => context
    None => abort("Missing current component observer context")
  }
}

///|
fn World::current_trigger_observer_context_abort_missing(
  self : World,
) -> TriggerObserverContext {
  match self.current_trigger_observer_context {
    Some(context) => context
    None => abort("Missing current trigger observer context")
  }
}

///|
pub fn[E : TriggerEvent] World::current_observer(self : World) -> On[E] {
  let context = self.current_trigger_observer_context_abort_missing()
  let event_key : EventKey[E] = E::observer_event()
  if context.event_key_id != event_key.id() {
    abort(
      "Current \{E::debug_name()} observer context does not match event `\{event_key.debug_name()}`",
    )
  }
  On::{ world: self, event_key, entity: context.entity, caller: context.caller }
}

///|
pub fn[E : ComponentObserverEvent, C : Component] World::current_component_observer(
  self : World,
) -> ComponentOn[E, C] {
  let context = self.current_component_observer_context_abort_missing()
  let component_key : ComponentKey[C] = Component::component()
  let expected_component_id = self.ensure_component_registered(
    component_key.id(),
  )
  if context.component_id != expected_component_id {
    abort(
      "Current \{E::debug_name()} observer context does not match component `\{component_key.debug_name()}`",
    )
  }
  ComponentOn::{
    world: self,
    entity: context.entity,
    caller: None,
    marker_event: Some(E::marker()),
    marker_component: None,
  }
}

///|
fn World::register_insert_component_observer(
  self : World,
  component_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let local_component_id = self.ensure_component_registered(component_id)
  let registry = self.observer_registry
  let observer_id = registry.next_observer_id
  registry.next_observer_id = observer_id + 1
  let observers = registry.insert_observers.get_or_init(local_component_id, fn() {
    []
  })
  observers.push(InsertObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
fn World::register_add_component_observer(
  self : World,
  component_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let local_component_id = self.ensure_component_registered(component_id)
  let registry = self.observer_registry
  let observer_id = registry.next_observer_id
  registry.next_observer_id = observer_id + 1
  let observers = registry.add_observers.get_or_init(local_component_id, fn() {
    []
  })
  observers.push(AddObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
fn World::register_replace_component_observer(
  self : World,
  component_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let local_component_id = self.ensure_component_registered(component_id)
  let registry = self.observer_registry
  let observer_id = registry.next_observer_id
  registry.next_observer_id = observer_id + 1
  let observers = registry.replace_observers.get_or_init(local_component_id, fn() {
    []
  })
  observers.push(ReplaceObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
fn World::register_remove_component_observer(
  self : World,
  component_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let local_component_id = self.ensure_component_registered(component_id)
  let registry = self.observer_registry
  let observer_id = registry.next_observer_id
  registry.next_observer_id = observer_id + 1
  let observers = registry.remove_observers.get_or_init(local_component_id, fn() {
    []
  })
  observers.push(RemoveObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
fn World::register_despawn_component_observer(
  self : World,
  component_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let local_component_id = self.ensure_component_registered(component_id)
  let registry = self.observer_registry
  let observer_id = registry.next_observer_id
  registry.next_observer_id = observer_id + 1
  let observers = registry.despawn_observers.get_or_init(local_component_id, fn() {
    []
  })
  observers.push(DespawnObserver::{ entity, run: observer })
  { id: observer_id, world_id: self.world_id() }
}

///|
fn World::register_trigger_observer(
  self : World,
  event_key_id : Int,
  entity : @core.Entity?,
  observer : (World) -> Unit,
) -> ObserverHandle {
  let registry = self.observer_registry
  let observer_id = registry.next_observer_id
  registry.next_observer_id = observer_id + 1
  let observers = registry.trigger_observers.get_or_init(event_key_id, fn() {
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
pub impl ComponentObserverEvent for Add with register_component_observer(
  world,
  component_id,
  entity,
  observer,
) {
  world.register_add_component_observer(component_id, entity, observer)
}

///|
pub impl ComponentObserverEvent for Add with marker() {
  Add::{  }
}

///|
pub impl ComponentObserverEvent for Add with debug_name() {
  "add"
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
pub impl ComponentObserverEvent for Replace with register_component_observer(
  world,
  component_id,
  entity,
  observer,
) {
  world.register_replace_component_observer(component_id, entity, observer)
}

///|
pub impl ComponentObserverEvent for Replace with marker() {
  Replace::{  }
}

///|
pub impl ComponentObserverEvent for Replace with debug_name() {
  "replace"
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
pub impl ComponentObserverEvent for Remove with marker() {
  Remove::{  }
}

///|
pub impl ComponentObserverEvent for Remove with debug_name() {
  "remove"
}

///|
pub impl ComponentObserverEvent for Despawn with register_component_observer(
  world,
  component_id,
  entity,
  observer,
) {
  world.register_despawn_component_observer(component_id, entity, observer)
}

///|
pub impl ComponentObserverEvent for Despawn with marker() {
  Despawn::{  }
}

///|
pub impl ComponentObserverEvent for Despawn with debug_name() {
  "despawn"
}

///|
pub fn[E : ComponentObserverEvent, C : Component] World::add_component_observer(
  self : World,
  observer : (ComponentOn[E, C]) -> Unit,
) -> ObserverHandle {
  let component_key : ComponentKey[C] = Component::component()
  E::register_component_observer(self, component_key.id(), None, fn(world) {
    let event : ComponentOn[E, C] = world.current_component_observer()
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_add_component_observer(
  self : World,
  observer : (ComponentOn[Add, C]) -> Unit,
) -> ObserverHandle {
  self.add_component_observer(fn(event : ComponentOn[Add, C]) {
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_replace_component_observer(
  self : World,
  observer : (ComponentOn[Replace, C]) -> Unit,
) -> ObserverHandle {
  self.add_component_observer(fn(event : ComponentOn[Replace, C]) {
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
pub fn[C : Component] World::add_despawn_component_observer(
  self : World,
  observer : (ComponentOn[Despawn, C]) -> Unit,
) -> ObserverHandle {
  self.add_component_observer(fn(event : ComponentOn[Despawn, C]) {
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
    world,
  ) {
    let event : ComponentOn[E, C] = world.current_component_observer()
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_add_entity_component_observer(
  self : World,
  entity : @core.Entity,
  observer : (ComponentOn[Add, C]) -> Unit,
) -> ObserverHandle {
  self.add_entity_component_observer(entity, fn(event : ComponentOn[Add, C]) {
    observer(event)
  })
}

///|
pub fn[C : Component] World::add_replace_entity_component_observer(
  self : World,
  entity : @core.Entity,
  observer : (ComponentOn[Replace, C]) -> Unit,
) -> ObserverHandle {
  self.add_entity_component_observer(entity, fn(
    event : ComponentOn[Replace, C],
  ) {
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
pub fn[C : Component] World::add_despawn_entity_component_observer(
  self : World,
  entity : @core.Entity,
  observer : (ComponentOn[Despawn, C]) -> Unit,
) -> ObserverHandle {
  self.add_entity_component_observer(entity, fn(
    event : ComponentOn[Despawn, C],
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
  self.register_trigger_observer(event_key.id(), None, fn(world) {
    let event : On[E] = world.current_observer()
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
  self.register_trigger_observer(event_key.id(), Some(entity), fn(world) {
    let event : On[E] = world.current_observer()
    observer(event)
  })
}

///|
fn World::insert_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[InsertObserver]? {
  match self.local_component_id(component_id) {
    Some(local_component_id) =>
      self.observer_registry.insert_observers.get(local_component_id)
    None => None
  }
}

///|
fn World::add_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[AddObserver]? {
  match self.local_component_id(component_id) {
    Some(local_component_id) =>
      self.observer_registry.add_observers.get(local_component_id)
    None => None
  }
}

///|
fn World::replace_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[ReplaceObserver]? {
  match self.local_component_id(component_id) {
    Some(local_component_id) =>
      self.observer_registry.replace_observers.get(local_component_id)
    None => None
  }
}

///|
fn World::remove_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[RemoveObserver]? {
  match self.local_component_id(component_id) {
    Some(local_component_id) =>
      self.observer_registry.remove_observers.get(local_component_id)
    None => None
  }
}

///|
fn World::despawn_observers_for_component(
  self : World,
  component_id : Int,
) -> Array[DespawnObserver]? {
  match self.local_component_id(component_id) {
    Some(local_component_id) =>
      self.observer_registry.despawn_observers.get(local_component_id)
    None => None
  }
}

///|
fn World::trigger_observers_for_event(
  self : World,
  event_key_id : Int,
) -> Array[TriggerObserver]? {
  self.observer_registry.trigger_observers.get(event_key_id)
}

///|
fn World::refresh_observer_parent_lookup_accessors(
  self : World,
) -> Array[ObserverParentLookupAccessor] {
  let registry = self.observer_registry
  let component_registration_generation = self.component_registration_generation()
  let archetype_generation = self.archetype_generation()
  let metadata_generation = component_relationship_metadata_generation()
  if registry.observer_parent_lookup_component_registration_generation ==
    component_registration_generation &&
    registry.observer_parent_lookup_archetype_generation == archetype_generation &&
    registry.observer_parent_lookup_metadata_generation == metadata_generation {
    return registry.observer_parent_lookup_accessors
  }
  let accessors : Array[ObserverParentLookupAccessor] = []
  for local_component_id in self.observer_parent_lookup_component_ids {
    guard self.component_relationship_sources.get(local_component_id)
      is Some(source) else {
      continue
    }
    if !source.observer_parent_lookup {
      continue
    }
    if self.archetype_ids_for_component_local_id(local_component_id).length() ==
      0 {
      continue
    }
    accessors.push({ local_component_id, target_entity: source.target_entity })
  }
  registry.observer_parent_lookup_accessors = accessors
  registry.observer_parent_lookup_component_registration_generation = component_registration_generation
  registry.observer_parent_lookup_archetype_generation = archetype_generation
  registry.observer_parent_lookup_metadata_generation = metadata_generation
  registry.observer_parent_lookup_accessors
}

///|
fn observer_parent_entity(
  world : World,
  entity : @core.Entity,
) -> @core.Entity? {
  guard world.entity_archetype_id(entity) is Some(archetype_id) else {
    return None
  }
  guard world.archetype_local_component_presence_view(archetype_id)
    is Some(local_presence) else {
    return None
  }
  for accessor in world.refresh_observer_parent_lookup_accessors() {
    if !local_presence.contains(accessor.local_component_id) {
      continue
    }
    match (accessor.target_entity)(world, entity) {
      Some(parent) => return Some(parent)
      None => ()
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
  let previous_context = self.current_trigger_observer_context
  let previous_trigger = (event_key.access.current_trigger)(self)
  (event_key.access.set_current_trigger)(self, event)
  while true {
    let current_event = match (event_key.access.current_trigger)(self) {
      Some(event) => event
      None => abort("Current observer event is no longer available")
    }
    let entity = E::observer_entity(current_event)
    let context : TriggerObserverContext = {
      event_key_id: event_key.id(),
      entity,
      caller,
      propagate: E::auto_propagate(current_event),
    }
    self.current_trigger_observer_context = Some(context)
    self.run_trigger_observers(event_key.id())
    if !context.propagate {
      break
    }
    guard entity is Some(current_entity) else { break }
    guard observer_parent_entity(self, current_entity) is Some(parent) else {
      break
    }
    (event_key.access.set_current_trigger)(
      self,
      E::set_observer_entity(current_event, parent),
    )
  }
  match previous_trigger {
    Some(event) => (event_key.access.set_current_trigger)(self, event)
    None => (event_key.access.clear_current_trigger)(self)
  }
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
  let local_component_id = self.ensure_component_registered(component_id)
  self.current_component_observer_context = Some({
    entity,
    component_id: local_component_id,
  })
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  self.current_component_observer_context = previous_context
}

///|
fn World::run_add_observers(
  self : World,
  entity : @core.Entity,
  component_id : Int,
) -> Unit {
  guard self.add_observers_for_component(component_id) is Some(observers) else {
    return
  }
  let pending : Array[AddObserver] = []
  for observer in observers {
    if observer.entity is Some(target_entity) && target_entity != entity {
      continue
    }
    pending.push(observer)
  }
  let previous_context = self.current_component_observer_context
  let local_component_id = self.ensure_component_registered(component_id)
  self.current_component_observer_context = Some({
    entity,
    component_id: local_component_id,
  })
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  self.current_component_observer_context = previous_context
}

///|
fn World::run_replace_observers(
  self : World,
  entity : @core.Entity,
  component_id : Int,
) -> Unit {
  guard self.replace_observers_for_component(component_id) is Some(observers) else {
    return
  }
  let pending : Array[ReplaceObserver] = []
  for observer in observers {
    if observer.entity is Some(target_entity) && target_entity != entity {
      continue
    }
    pending.push(observer)
  }
  let previous_context = self.current_component_observer_context
  let local_component_id = self.ensure_component_registered(component_id)
  self.current_component_observer_context = Some({
    entity,
    component_id: local_component_id,
  })
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
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
  let local_component_id = self.ensure_component_registered(component_id)
  self.current_component_observer_context = Some({
    entity,
    component_id: local_component_id,
  })
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  self.current_component_observer_context = previous_context
}

///|
fn World::run_despawn_observers(
  self : World,
  entity : @core.Entity,
  component_id : Int,
) -> Unit {
  guard self.despawn_observers_for_component(component_id) is Some(observers) else {
    return
  }
  let pending : Array[DespawnObserver] = []
  for observer in observers {
    if observer.entity is Some(target_entity) && target_entity != entity {
      continue
    }
    pending.push(observer)
  }
  let previous_context = self.current_component_observer_context
  let local_component_id = self.ensure_component_registered(component_id)
  self.current_component_observer_context = Some({
    entity,
    component_id: local_component_id,
  })
  let count = pending.length()
  for i in 0..<count {
    let observer = pending[count - 1 - i]
    (observer.run)(self)
  }
  self.current_component_observer_context = previous_context
}

///|
fn World::run_trigger_observers(self : World, event_key_id : Int) -> Unit {
  guard self.trigger_observers_for_event(event_key_id) is Some(observers) else {
    return
  }
  let context = self.current_trigger_observer_context_abort_missing()
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
