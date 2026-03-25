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
pub struct PickingEvents {
  mut events : Array[@pointer_events.PointerEvent]
} derive(ToJson, FromJson)

///|
pub fn PickingEvents::default() -> PickingEvents {
  PickingEvents::{ events: [] }
}

///|
pub fn PickingEvents::push(
  self : Ref[PickingEvents],
  event : @pointer_events.PointerEvent,
) -> Unit {
  self.val.events = self.val.events + [event]
}

///|
pub fn PickingEvents::drain(
  self : Ref[PickingEvents],
) -> Array[@pointer_events.PointerEvent] {
  let out = self.val.events
  self.val.events = []
  out
}

///|
let ecs_res_key_picking_events : @ecs.ResourceKey[PickingEvents] = @ecs.register_resource(
  debug_name="picking.picking_events",
)

///|
pub impl Resource for PickingEvents with resource() {
  ecs_res_key_picking_events
}

///|
pub fn get_picking_events_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PickingEvents] {
  world.resource(ecs_res_key_picking_events)
}

///|
pub struct PointerMove {}

///|
pub struct PointerEnter {}

///|
pub struct PointerLeave {}

///|
pub struct PointerDown {}

///|
pub struct PointerUp {}

///|
pub struct PointerClick {}

///|
pub(open) trait PointerObserverKind {
  event_kind() -> @pointer_events.PointerEventKind
  source_label() -> String
}

///|
pub impl PointerObserverKind for PointerMove with event_kind() {
  @pointer_events.PointerEventKind::Move
}

///|
pub impl PointerObserverKind for PointerMove with source_label() {
  "Pointer<Move>"
}

///|
pub impl PointerObserverKind for PointerEnter with event_kind() {
  @pointer_events.PointerEventKind::Enter
}

///|
pub impl PointerObserverKind for PointerEnter with source_label() {
  "Pointer<Enter>"
}

///|
pub impl PointerObserverKind for PointerLeave with event_kind() {
  @pointer_events.PointerEventKind::Leave
}

///|
pub impl PointerObserverKind for PointerLeave with source_label() {
  "Pointer<Leave>"
}

///|
pub impl PointerObserverKind for PointerDown with event_kind() {
  @pointer_events.PointerEventKind::Down
}

///|
pub impl PointerObserverKind for PointerDown with source_label() {
  "Pointer<Down>"
}

///|
pub impl PointerObserverKind for PointerUp with event_kind() {
  @pointer_events.PointerEventKind::Up
}

///|
pub impl PointerObserverKind for PointerUp with source_label() {
  "Pointer<Up>"
}

///|
pub impl PointerObserverKind for PointerClick with event_kind() {
  @pointer_events.PointerEventKind::Click
}

///|
pub impl PointerObserverKind for PointerClick with source_label() {
  "Pointer<Click>"
}

///|
pub struct OnPointer[K] {
  event : @pointer_events.PointerEvent
}

///|
pub fn[K] OnPointer::event(self : OnPointer[K]) -> @pointer_events.PointerEvent {
  self.event
}

///|
pub fn[K] OnPointer::pointer(self : OnPointer[K]) -> @pointer_events.PointerId {
  self.event.pointer
}

///|
pub fn[K] OnPointer::position(self : OnPointer[K]) -> @math.Vec2 {
  self.event.position
}

///|
pub fn[K] OnPointer::target(self : OnPointer[K]) -> @core.Entity? {
  self.event.target
}

///|
let current_pointer_event_ref : Ref[@pointer_events.PointerEvent?] = Ref::new(
  None,
)

///|
fn current_pointer_event_abort_missing() -> @pointer_events.PointerEvent {
  match current_pointer_event_ref.val {
    Some(event) => event
    None => abort("OnPointer requires an active pointer event")
  }
}

///|
pub impl[K : PointerObserverKind] SystemParam for OnPointer[K] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[K : PointerObserverKind] SystemParam for OnPointer[K] with get(_state) {
  OnPointer::{ event: current_pointer_event_abort_missing() }
}

///|
pub impl[K : PointerObserverKind] SystemParam for OnPointer[K] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
priv struct PointerObserverEntry {
  kind : @pointer_events.PointerEventKind
  source : String
  target : @core.Entity?
  system : SystemFn[@ecs.World]
  last_run_sequence_ref : Ref[@core.Sequence]
}

///|
priv struct PointerObserverRegistry {
  entries : Array[PointerObserverEntry]
}

///|
fn PointerObserverRegistry::default() -> PointerObserverRegistry {
  { entries: [] }
}

///|
let ecs_res_key_pointer_observer_registry : @ecs.ResourceKey[
  PointerObserverRegistry,
] = @ecs.register_resource(debug_name="app.pointer_observer_registry")

///|
fn get_pointer_observer_registry_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointerObserverRegistry] {
  world.resource(ecs_res_key_pointer_observer_registry)
}

///|
fn register_pointer_observer_entry_in_world(
  world : @ecs.World,
  kind : @pointer_events.PointerEventKind,
  source : String,
  target : @core.Entity?,
  system : SystemFn[@ecs.World],
) -> Unit {
  let registry_res = get_pointer_observer_registry_resource(world)
  let registry = match registry_res.get() {
    Some(value) => Ref::new(value)
    None => Ref::new(PointerObserverRegistry::default())
  }
  registry.val.entries.push({
    kind,
    source,
    target,
    system,
    last_run_sequence_ref: Ref::new(0),
  })
  registry_res.insert(registry.val)
}

///|
fn register_pointer_observer_entry_in_sub_app(
  sub_app : SubApp[@ecs.World],
  kind : @pointer_events.PointerEventKind,
  source : String,
  target : @core.Entity?,
  system : SystemFn[@ecs.World],
) -> SubApp[@ecs.World] {
  register_pointer_observer_entry_in_world(
    sub_app.world(),
    kind,
    source,
    target,
    system,
  )
  sub_app
}

///|
pub fn[K : PointerObserverKind] SubApp::add_pointer_observer(
  self : SubApp[@ecs.World],
  observer : (OnPointer[K]) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_pointer_observer_entry_in_sub_app(
    self,
    K::event_kind(),
    K::source_label(),
    None,
    fallible_system_param(observer),
  )
}

///|
pub fn[K : PointerObserverKind] App::add_pointer_observer(
  self : App[@ecs.World],
  observer : (OnPointer[K]) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_pointer_observer(observer)
  self
}

///|
pub fn[K : PointerObserverKind, P2 : SystemParam] SubApp::add_pointer_observer2(
  self : SubApp[@ecs.World],
  observer : (OnPointer[K], P2) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_pointer_observer_entry_in_sub_app(
    self,
    K::event_kind(),
    K::source_label(),
    None,
    fallible_system_param2(observer),
  )
}

///|
pub fn[K : PointerObserverKind, P2 : SystemParam] App::add_pointer_observer2(
  self : App[@ecs.World],
  observer : (OnPointer[K], P2) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_pointer_observer2(observer)
  self
}

///|
pub fn[K : PointerObserverKind, P2 : SystemParam, P3 : SystemParam] SubApp::add_pointer_observer3(
  self : SubApp[@ecs.World],
  observer : (OnPointer[K], P2, P3) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_pointer_observer_entry_in_sub_app(
    self,
    K::event_kind(),
    K::source_label(),
    None,
    fallible_system_param3(observer),
  )
}

///|
pub fn[K : PointerObserverKind, P2 : SystemParam, P3 : SystemParam] App::add_pointer_observer3(
  self : App[@ecs.World],
  observer : (OnPointer[K], P2, P3) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_pointer_observer3(observer)
  self
}

///|
pub fn[
  K : PointerObserverKind,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] SubApp::add_pointer_observer4(
  self : SubApp[@ecs.World],
  observer : (OnPointer[K], P2, P3, P4) -> Unit raise,
) -> SubApp[@ecs.World] {
  register_pointer_observer_entry_in_sub_app(
    self,
    K::event_kind(),
    K::source_label(),
    None,
    fallible_system_param4(observer),
  )
}

///|
pub fn[
  K : PointerObserverKind,
  P2 : SystemParam,
  P3 : SystemParam,
  P4 : SystemParam,
] App::add_pointer_observer4(
  self : App[@ecs.World],
  observer : (OnPointer[K], P2, P3, P4) -> Unit raise,
) -> App[@ecs.World] {
  self.sub_apps.main = self.sub_apps.main.add_pointer_observer4(observer)
  self
}

///|
pub fn dispatch_pointer_observers_system(world : @ecs.World) -> Unit {
  let registry_res = get_pointer_observer_registry_resource(world)
  let events_res = get_picking_events_resource(world)
  guard registry_res.get() is Some(registry) else { return }
  guard events_res.get() is Some(events) else { return }
  for event in events.events {
    for entry in registry.entries {
      if entry.kind == event.kind {
        match entry.target {
          Some(target) => {
            guard event.target == Some(target) else { continue }
          }
          None => ()
        }
        current_pointer_event_ref.val = Some(event)
        run_registered_observer_system(
          world,
          entry.last_run_sequence_ref,
          entry.system,
          source=entry.source,
        )
        current_pointer_event_ref.val = None
      }
    }
  }
}
