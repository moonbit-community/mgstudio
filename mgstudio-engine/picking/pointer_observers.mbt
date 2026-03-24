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
  event_kind() -> PointerEventKind
  source_label() -> String
}

///|
pub impl PointerObserverKind for PointerMove with event_kind() {
  PointerEventKind::Move
}

///|
pub impl PointerObserverKind for PointerMove with source_label() {
  "Pointer<Move>"
}

///|
pub impl PointerObserverKind for PointerEnter with event_kind() {
  PointerEventKind::Enter
}

///|
pub impl PointerObserverKind for PointerEnter with source_label() {
  "Pointer<Enter>"
}

///|
pub impl PointerObserverKind for PointerLeave with event_kind() {
  PointerEventKind::Leave
}

///|
pub impl PointerObserverKind for PointerLeave with source_label() {
  "Pointer<Leave>"
}

///|
pub impl PointerObserverKind for PointerDown with event_kind() {
  PointerEventKind::Down
}

///|
pub impl PointerObserverKind for PointerDown with source_label() {
  "Pointer<Down>"
}

///|
pub impl PointerObserverKind for PointerUp with event_kind() {
  PointerEventKind::Up
}

///|
pub impl PointerObserverKind for PointerUp with source_label() {
  "Pointer<Up>"
}

///|
pub impl PointerObserverKind for PointerClick with event_kind() {
  PointerEventKind::Click
}

///|
pub impl PointerObserverKind for PointerClick with source_label() {
  "Pointer<Click>"
}

///|
pub struct OnPointer[K] {
  event : PointerEvent
}

///|
pub fn[K] OnPointer::event(self : OnPointer[K]) -> PointerEvent {
  self.event
}

///|
pub fn[K] OnPointer::pointer(self : OnPointer[K]) -> PointerId {
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
let current_pointer_event_ref : Ref[PointerEvent?] = Ref::new(None)

///|
fn current_pointer_event_abort_missing() -> PointerEvent {
  match current_pointer_event_ref.val {
    Some(event) => event
    None => abort("OnPointer requires an active pointer event")
  }
}

///|
pub impl[K : PointerObserverKind] @app.SystemParam for OnPointer[K] with init_state(
  world,
) {
  @app.system_param_empty_state(world)
}

///|
pub impl[K : PointerObserverKind] @app.SystemParam for OnPointer[K] with get(
  _state,
) {
  OnPointer::{ event: current_pointer_event_abort_missing() }
}

///|
pub impl[K : PointerObserverKind] @app.SystemParam for OnPointer[K] with store(
  self,
  state,
) {
  @app.system_param_store_no_state(self, state)
}

///|
priv struct PointerObserverEntry {
  kind : PointerEventKind
  source : String
  system : @app.SystemFn[@ecs.World]
  last_run_sequence_ref : Ref[@core.Sequence]
}

///|
struct PointerObserverRegistry {
  entries : Array[PointerObserverEntry]
}

///|
fn PointerObserverRegistry::default() -> PointerObserverRegistry {
  { entries: [] }
}

///|
let ecs_res_key_pointer_observer_registry : @ecs.ResourceKey[
  PointerObserverRegistry,
] = @ecs.register_resource(debug_name="picking.pointer_observer_registry")

///|
pub impl @app.Resource for PointerObserverRegistry with resource() {
  ecs_res_key_pointer_observer_registry
}

///|
fn get_pointer_observer_registry_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointerObserverRegistry] {
  world.resource(ecs_res_key_pointer_observer_registry)
}

///|
pub fn ensure_pointer_observer_registry_system(world : @ecs.World) -> Unit {
  let res = get_pointer_observer_registry_resource(world)
  if res.get() is None {
    res.insert(PointerObserverRegistry::default())
  }
}

///|
fn register_pointer_observer_entry(
  app : @app.App[@ecs.World],
  kind : PointerEventKind,
  source : String,
  system : @app.SystemFn[@ecs.World],
) -> @app.App[@ecs.World] {
  let registry_res = get_pointer_observer_registry_resource(app.world())
  let registry = match registry_res.get() {
    Some(value) => Ref::new(value)
    None => Ref::new(PointerObserverRegistry::default())
  }
  registry.val.entries.push({
    kind,
    source,
    system,
    last_run_sequence_ref: Ref::new(0),
  })
  registry_res.insert(registry.val)
  app
}

///|
pub fn[K : PointerObserverKind] add_pointer_observer(
  app : @app.App[@ecs.World],
  observer : (OnPointer[K]) -> Unit raise,
) -> @app.App[@ecs.World] {
  register_pointer_observer_entry(
    app,
    K::event_kind(),
    K::source_label(),
    @app.fallible_system_param(observer),
  )
}

///|
pub fn[K : PointerObserverKind, P2 : @app.SystemParam] add_pointer_observer2(
  app : @app.App[@ecs.World],
  observer : (OnPointer[K], P2) -> Unit raise,
) -> @app.App[@ecs.World] {
  register_pointer_observer_entry(
    app,
    K::event_kind(),
    K::source_label(),
    @app.fallible_system_param2(observer),
  )
}

///|
pub fn[K : PointerObserverKind, P2 : @app.SystemParam, P3 : @app.SystemParam] add_pointer_observer3(
  app : @app.App[@ecs.World],
  observer : (OnPointer[K], P2, P3) -> Unit raise,
) -> @app.App[@ecs.World] {
  register_pointer_observer_entry(
    app,
    K::event_kind(),
    K::source_label(),
    @app.fallible_system_param3(observer),
  )
}

///|
pub fn[
  K : PointerObserverKind,
  P2 : @app.SystemParam,
  P3 : @app.SystemParam,
  P4 : @app.SystemParam,
] add_pointer_observer4(
  app : @app.App[@ecs.World],
  observer : (OnPointer[K], P2, P3, P4) -> Unit raise,
) -> @app.App[@ecs.World] {
  register_pointer_observer_entry(
    app,
    K::event_kind(),
    K::source_label(),
    @app.fallible_system_param4(observer),
  )
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
        current_pointer_event_ref.val = Some(event)
        @app.run_registered_observer_system(
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
