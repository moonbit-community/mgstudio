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
struct ObserverMarker {
  value : Int
} derive(Eq, Debug)

///|
let observer_marker_key : ComponentKey[ObserverMarker] = register_component(
  debug_name="tests.ecs.observer.marker",
)

///|
pub impl Component for ObserverMarker with component() {
  observer_marker_key
}

///|
struct ObserverParentLink {
  parent : @core.Entity
} derive(Eq, Debug)

///|
let observer_parent_link_key : ComponentKey[ObserverParentLink] = register_component(
  debug_name="tests.ecs.observer.parent_link",
)

///|
pub impl Component for ObserverParentLink with component() {
  observer_parent_link_key
}

///|
struct ObserverParentLinkStable {
  parent : @core.Entity
} derive(Eq, Debug)

///|
let observer_parent_link_stable_key : ComponentKey[ObserverParentLinkStable] = register_component(
  debug_name="tests.ecs.observer.parent_link_stable",
)

///|
pub impl Component for ObserverParentLinkStable with component() {
  observer_parent_link_stable_key
}

///|
struct ObserverParentLinkLate {
  parent : @core.Entity
} derive(Eq, Debug)

///|
let observer_parent_link_late_key : ComponentKey[ObserverParentLinkLate] = register_component(
  debug_name="tests.ecs.observer.parent_link_late",
)

///|
pub impl Component for ObserverParentLinkLate with component() {
  observer_parent_link_late_key
}

///|
struct ObserverParentLookupProbe {
  parent : @core.Entity
} derive(Eq, Debug)

///|
let observer_parent_lookup_probe_key : ComponentKey[ObserverParentLookupProbe] = register_component(
  debug_name="tests.ecs.observer.parent_link_probe",
)

///|
let observer_parent_lookup_probe_calls_ref : Ref[Int] = Ref::new(0)

///|
let observer_parent_lookup_probe_world0_id_ref : Ref[Int] = Ref::new(-1)

///|
let observer_parent_lookup_probe_world1_id_ref : Ref[Int] = Ref::new(-1)

///|
let observer_parent_lookup_probe_world0_calls_ref : Ref[Int] = Ref::new(0)

///|
let observer_parent_lookup_probe_world1_calls_ref : Ref[Int] = Ref::new(0)

///|
fn reset_observer_parent_lookup_probe_counters(
  world0_id : Int,
  world1_id : Int,
) -> Unit {
  observer_parent_lookup_probe_calls_ref.val = 0
  observer_parent_lookup_probe_world0_calls_ref.val = 0
  observer_parent_lookup_probe_world1_calls_ref.val = 0
  observer_parent_lookup_probe_world0_id_ref.val = world0_id
  observer_parent_lookup_probe_world1_id_ref.val = world1_id
}

///|
fn observer_parent_lookup_probe_target_entity(
  world : World,
  entity : @core.Entity,
) -> @core.Entity? {
  observer_parent_lookup_probe_calls_ref.val = observer_parent_lookup_probe_calls_ref.val +
    1
  let world_id = world.world_id()
  if world_id == observer_parent_lookup_probe_world0_id_ref.val {
    observer_parent_lookup_probe_world0_calls_ref.val = observer_parent_lookup_probe_world0_calls_ref.val +
      1
  } else if world_id == observer_parent_lookup_probe_world1_id_ref.val {
    observer_parent_lookup_probe_world1_calls_ref.val = observer_parent_lookup_probe_world1_calls_ref.val +
      1
  }
  match
    (try world.get_by_key(entity, observer_parent_lookup_probe_key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(link) => Some(link.parent)
    None => None
  }
}

///|
fn observer_parent_link_stable_target_entity(
  world : World,
  entity : @core.Entity,
) -> @core.Entity? {
  match
    (try world.get_by_key(entity, observer_parent_link_stable_key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(link) => Some(link.parent)
    None => None
  }
}

///|
fn observer_parent_link_late_target_entity(
  world : World,
  entity : @core.Entity,
) -> @core.Entity? {
  match
    (try world.get_by_key(entity, observer_parent_link_late_key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(link) => Some(link.parent)
    None => None
  }
}

///|
fn init {
  ignore(
    component_metadata_builder(observer_parent_link_key).relationship_source(
      fn(world, entity) {
        match
          (try world.get_by_key(entity, observer_parent_link_key) catch {
            _ => None
          } noraise {
            value => value
          }) {
          Some(link) => Some(link.parent)
          None => None
        }
      },
      observer_parent_lookup=true,
    ),
  )
  ignore(
    component_metadata_builder(observer_parent_link_late_key).relationship_source(
      observer_parent_link_late_target_entity,
      observer_parent_lookup=true,
    ),
  )
  ignore(
    component_metadata_builder(observer_parent_lookup_probe_key).relationship_source(
      observer_parent_lookup_probe_target_entity,
      observer_parent_lookup=true,
    ),
  )
}

///|
struct ObserverDetonate {
  mut entity : @core.Entity
  radius : Int
} derive(Eq)

///|
let observer_detonate_event_key : EventKey[ObserverDetonate] = register_event(
  debug_name="tests.ecs.observer.detonate",
)

///|
pub impl TriggerEvent for ObserverDetonate with observer_event() {
  observer_detonate_event_key
}

///|
pub impl TriggerEvent for ObserverDetonate with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl TriggerEvent for ObserverDetonate with set_observer_entity(
  event,
  entity,
) {
  event.entity = entity
  event
}

///|
pub impl TriggerEvent for ObserverDetonate with auto_propagate(_self) {
  false
}

///|
pub impl TriggerEvent for ObserverDetonate with debug_name() {
  "ObserverDetonate"
}

///|
struct ObserverAttack {
  mut damage : Int
  mut entity : @core.Entity
} derive(Eq)

///|
let observer_attack_event_key : EventKey[ObserverAttack] = register_event(
  debug_name="tests.ecs.observer.attack",
)

///|
pub impl TriggerEvent for ObserverAttack with observer_event() {
  observer_attack_event_key
}

///|
pub impl TriggerEvent for ObserverAttack with observer_entity(self) {
  Some(self.entity)
}

///|
pub impl TriggerEvent for ObserverAttack with set_observer_entity(event, entity) {
  event.entity = entity
  event
}

///|
pub impl TriggerEvent for ObserverAttack with auto_propagate(_self) {
  true
}

///|
pub impl TriggerEvent for ObserverAttack with debug_name() {
  "ObserverAttack"
}

///|
test "ecs observer: world add_component_observer is world-scoped and fires on replace" {
  let world0 = World::new()
  let world1 = World::new()
  let seen_entities : Array[Int] = []
  let first_hits : Ref[Int] = Ref::new(0)
  let second_hits : Ref[Int] = Ref::new(0)
  let captured_world_id : Ref[Int] = Ref::new(-1)

  let first_handle = world0.add_component_observer(fn(
    event : ComponentOn[Insert, ObserverMarker],
  ) {
    first_hits.val = first_hits.val + 1
    seen_entities.push(event.entity.id)
    captured_world_id.val = current_observer_world_abort_missing().world_id()
  })
  ignore(
    world0.add_component_observer(fn(
      _event : ComponentOn[Insert, ObserverMarker],
    ) {
      second_hits.val = second_hits.val + 1
    }),
  )

  let entity0 = world0.spawn()
  let entity1 = world1.spawn()

  try! world0.set_by_key(entity0, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  try! world0.set_by_key(entity0, observer_marker_key, ObserverMarker::{
    value: 2,
  })
  try! world1.set_by_key(entity1, observer_marker_key, ObserverMarker::{
    value: 3,
  })

  debug_inspect(first_handle.world_id() == world0.world_id(), content="true")
  debug_inspect(first_handle.id() > 0, content="true")
  debug_inspect(first_hits.val, content="2")
  debug_inspect(second_hits.val, content="2")
  debug_inspect(seen_entities, content="[0, 0]")
  debug_inspect(captured_world_id.val == world0.world_id(), content="true")
}

///|
test "ecs observer: add_entity_component_observer only fires for the bound entity" {
  let world = World::new()
  let entity0 = world.spawn()
  let entity1 = world.spawn()
  let seen_entities : Array[Int] = []
  let hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_entity_component_observer(entity0, fn(
      event : ComponentOn[Insert, ObserverMarker],
    ) {
      hits.val = hits.val + 1
      seen_entities.push(event.entity.id)
    }),
  )

  try! world.set_by_key(entity0, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  try! world.set_by_key(entity1, observer_marker_key, ObserverMarker::{
    value: 2,
  })
  try! world.set_by_key(entity0, observer_marker_key, ObserverMarker::{
    value: 3,
  })

  debug_inspect(hits.val, content="2")
  debug_inspect(seen_entities, content="[0, 0]")
}

///|
test "ecs observer: world add_component_observer fires on remove" {
  let world = World::new()
  let entity = world.spawn()
  let seen_entities : Array[Int] = []
  let hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_component_observer(fn(
      event : ComponentOn[Remove, ObserverMarker],
    ) {
      hits.val = hits.val + 1
      seen_entities.push(event.entity.id)
    }),
  )

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  debug_inspect(
    try! world.remove_by_key(entity, observer_marker_key),
    content="true",
  )
  debug_inspect(
    try! world.remove_by_key(entity, observer_marker_key),
    content="false",
  )

  debug_inspect(hits.val, content="1")
  debug_inspect(seen_entities, content="[0]")
}

///|
test "ecs observer: add observers only fire on first insertion" {
  let world = World::new()
  let entity = world.spawn()
  let hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_add_component_observer(fn(
      _event : ComponentOn[Add, ObserverMarker],
    ) {
      hits.val = hits.val + 1
    }),
  )

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 2,
  })
  debug_inspect(hits.val, content="1")
}

///|
test "ecs observer: replace observers fire on replace and remove paths" {
  let world = World::new()
  let entity = world.spawn()
  let hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_replace_component_observer(fn(
      _event : ComponentOn[Replace, ObserverMarker],
    ) {
      hits.val = hits.val + 1
    }),
  )

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  ignore(
    try! world.update_by_key(entity, observer_marker_key, fn(marker) {
      ObserverMarker::{ value: marker.value + 1 }
    }),
  )
  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 3,
  })
  ignore(try! world.remove_by_key(entity, observer_marker_key))

  debug_inspect(hits.val, content="3")
}

///|
test "ecs observer: despawn observers fire only during despawn" {
  let world = World::new()
  let keep_entity = world.spawn()
  let despawn_entity = world.spawn()
  let hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_despawn_component_observer(fn(
      _event : ComponentOn[Despawn, ObserverMarker],
    ) {
      hits.val = hits.val + 1
    }),
  )

  try! world.set_by_key(keep_entity, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  try! world.set_by_key(despawn_entity, observer_marker_key, ObserverMarker::{
    value: 2,
  })
  ignore(try! world.remove_by_key(keep_entity, observer_marker_key))
  try! world.despawn(despawn_entity)

  debug_inspect(hits.val, content="1")
}

///|
test "ecs observer: lifecycle observer ordering is deterministic" {
  let world = World::new()
  let entity = world.spawn()
  let add_order : Array[String] = []
  let insert_order : Array[String] = []
  let replace_order : Array[String] = []
  let remove_order : Array[String] = []
  let despawn_order : Array[String] = []

  ignore(
    world.add_add_component_observer(fn(
      _event : ComponentOn[Add, ObserverMarker],
    ) {
      add_order.push("first")
    }),
  )
  ignore(
    world.add_add_component_observer(fn(
      _event : ComponentOn[Add, ObserverMarker],
    ) {
      add_order.push("second")
    }),
  )

  ignore(
    world.add_component_observer(fn(
      _event : ComponentOn[Insert, ObserverMarker],
    ) {
      insert_order.push("first")
    }),
  )
  ignore(
    world.add_component_observer(fn(
      _event : ComponentOn[Insert, ObserverMarker],
    ) {
      insert_order.push("second")
    }),
  )

  ignore(
    world.add_replace_component_observer(fn(
      _event : ComponentOn[Replace, ObserverMarker],
    ) {
      replace_order.push("first")
    }),
  )
  ignore(
    world.add_replace_component_observer(fn(
      _event : ComponentOn[Replace, ObserverMarker],
    ) {
      replace_order.push("second")
    }),
  )

  ignore(
    world.add_remove_component_observer(fn(
      _event : ComponentOn[Remove, ObserverMarker],
    ) {
      remove_order.push("first")
    }),
  )
  ignore(
    world.add_remove_component_observer(fn(
      _event : ComponentOn[Remove, ObserverMarker],
    ) {
      remove_order.push("second")
    }),
  )

  ignore(
    world.add_despawn_component_observer(fn(
      _event : ComponentOn[Despawn, ObserverMarker],
    ) {
      despawn_order.push("first")
    }),
  )
  ignore(
    world.add_despawn_component_observer(fn(
      _event : ComponentOn[Despawn, ObserverMarker],
    ) {
      despawn_order.push("second")
    }),
  )

  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 2,
  })
  debug_inspect(
    try! world.remove_by_key(entity, observer_marker_key),
    content="true",
  )
  try! world.set_by_key(entity, observer_marker_key, ObserverMarker::{
    value: 3,
  })
  try! world.despawn(entity)

  debug_inspect(
    add_order,
    content="[\"second\", \"first\", \"second\", \"first\"]",
  )
  debug_inspect(
    insert_order,
    content="[\"second\", \"first\", \"second\", \"first\", \"second\", \"first\"]",
  )
  debug_inspect(
    replace_order,
    content="[\"second\", \"first\", \"second\", \"first\", \"second\", \"first\"]",
  )
  debug_inspect(
    remove_order,
    content="[\"second\", \"first\", \"second\", \"first\"]",
  )
  debug_inspect(despawn_order, content="[\"second\", \"first\"]")
}

///|
test "ecs observer: world add_observer and add_entity_observer handle custom events" {
  let world = World::new()
  let entity0 = world.spawn()
  let entity1 = world.spawn()
  let global_entities : Array[Int] = []
  let bound_entities : Array[Int] = []
  let global_hits : Ref[Int] = Ref::new(0)
  let bound_hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_observer(fn(event : On[ObserverDetonate]) {
      global_hits.val = global_hits.val + 1
      guard event.entity() is Some(entity) else { return }
      global_entities.push(entity.id)
    }),
  )

  ignore(
    world.add_entity_observer(entity0, fn(event : On[ObserverDetonate]) {
      bound_hits.val = bound_hits.val + 1
      guard event.entity() is Some(entity) else { return }
      bound_entities.push(entity.id)
    }),
  )

  world.trigger(ObserverDetonate::{ entity: entity0, radius: 1 })
  world.trigger(ObserverDetonate::{ entity: entity1, radius: 2 })

  debug_inspect(global_hits.val, content="2")
  debug_inspect(bound_hits.val, content="1")
  debug_inspect(global_entities, content="[0, 1]")
  debug_inspect(bound_entities, content="[0]")
}

///|
test "ecs observer: trigger propagation bubbles to parent and carries payload mutations" {
  let world = World::new()
  let parent = world.spawn()
  let child = world.spawn()
  let order : Array[String] = []
  try! world.set_by_key(child, observer_parent_link_key, ObserverParentLink::{
    parent,
  })

  ignore(
    world.add_entity_observer(child, fn(event : On[ObserverAttack]) {
      order.push("child")
      event.modify(fn(value) { value.damage = event.event().damage - 3 })
    }),
  )

  ignore(
    world.add_entity_observer(parent, fn(event : On[ObserverAttack]) {
      order.push("parent:\{event.event().damage.to_string()}")
    }),
  )

  world.trigger(ObserverAttack::{ damage: 10, entity: child })

  debug_inspect(order, content="[\"child\", \"parent:7\"]")
}

///|
test "ecs observer: trigger propagation can be halted early" {
  let world = World::new()
  let parent = world.spawn()
  let child = world.spawn()
  let order : Array[String] = []
  try! world.set_by_key(child, observer_parent_link_key, ObserverParentLink::{
    parent,
  })

  ignore(
    world.add_entity_observer(child, fn(event : On[ObserverAttack]) {
      order.push("child")
      event.propagate(false)
    }),
  )

  ignore(
    world.add_entity_observer(parent, fn(_event : On[ObserverAttack]) {
      order.push("parent")
    }),
  )

  world.trigger(ObserverAttack::{ damage: 4, entity: child })

  debug_inspect(order, content="[\"child\"]")
}

///|
test "ecs observer: parent lookup cache refreshes after late relationship registration" {
  let world = World::new()
  let parent = world.spawn()
  let child = world.spawn()
  let parent_hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_entity_observer(parent, fn(_event : On[ObserverAttack]) {
      parent_hits.val = parent_hits.val + 1
    }),
  )

  world.trigger(ObserverAttack::{ damage: 10, entity: child })
  debug_inspect(parent_hits.val, content="0")

  try! world.set_by_key(child, observer_parent_link_late_key, ObserverParentLinkLate::{
    parent,
  })
  world.trigger(ObserverAttack::{ damage: 10, entity: child })
  debug_inspect(parent_hits.val, content="1")
}

///|
test "ecs observer: parent lookup accessor is captured per-world registration" {
  let world0 = World::new()
  let parent0 = world0.spawn()
  let child0 = world0.spawn()
  let world0_hits : Ref[Int] = Ref::new(0)

  ignore(
    component_metadata_builder(observer_parent_link_stable_key).relationship_source(
      observer_parent_link_stable_target_entity,
      observer_parent_lookup=true,
    ),
  )
  try! world0.set_by_key(child0, observer_parent_link_stable_key, ObserverParentLinkStable::{
    parent: parent0,
  })

  // Mutate global metadata after world0 registered the component.
  // world0 must keep using the already-installed world-local accessor.
  ignore(
    component_metadata_builder(observer_parent_link_stable_key).relationship_source(
      fn(_world, _entity) { None },
      observer_parent_lookup=true,
    ),
  )

  let world1 = World::new()
  let parent1 = world1.spawn()
  let child1 = world1.spawn()
  let world1_hits : Ref[Int] = Ref::new(0)
  try! world1.set_by_key(child1, observer_parent_link_stable_key, ObserverParentLinkStable::{
    parent: parent1,
  })

  ignore(
    world0.add_entity_observer(parent0, fn(_event : On[ObserverAttack]) {
      world0_hits.val = world0_hits.val + 1
    }),
  )
  ignore(
    world1.add_entity_observer(parent1, fn(_event : On[ObserverAttack]) {
      world1_hits.val = world1_hits.val + 1
    }),
  )

  world0.trigger(ObserverAttack::{ damage: 10, entity: child0 })
  world1.trigger(ObserverAttack::{ damage: 10, entity: child1 })

  debug_inspect(world0_hits.val, content="1")
  debug_inspect(world1_hits.val, content="0")

  // Restore metadata so test ordering cannot leak behavior.
  ignore(
    component_metadata_builder(observer_parent_link_stable_key).relationship_source(
      observer_parent_link_stable_target_entity,
      observer_parent_lookup=true,
    ),
  )
}

///|
test "ecs observer: parent lookup cache tracks archetype register and unregister transitions" {
  let world = World::new()
  let parent = world.spawn()
  let child = world.spawn()
  let parent_hits : Ref[Int] = Ref::new(0)
  reset_observer_parent_lookup_probe_counters(world.world_id(), -1)

  ignore(
    world
    .components_registrator()
    .register_component_by_key(observer_parent_lookup_probe_key),
  )
  ignore(
    world.add_entity_observer(parent, fn(_event : On[ObserverAttack]) {
      parent_hits.val = parent_hits.val + 1
    }),
  )

  world.trigger(ObserverAttack::{ damage: 10, entity: child })
  debug_inspect(observer_parent_lookup_probe_calls_ref.val, content="0")
  debug_inspect(parent_hits.val, content="0")

  try! world.set_by_key(child, observer_parent_lookup_probe_key, ObserverParentLookupProbe::{
    parent,
  })
  world.trigger(ObserverAttack::{ damage: 10, entity: child })
  debug_inspect(observer_parent_lookup_probe_calls_ref.val, content="1")
  debug_inspect(parent_hits.val, content="1")

  debug_inspect(
    try! world.remove_by_key(child, observer_parent_lookup_probe_key),
    content="true",
  )
  world.trigger(ObserverAttack::{ damage: 10, entity: child })
  debug_inspect(observer_parent_lookup_probe_calls_ref.val, content="1")
  debug_inspect(parent_hits.val, content="1")
}

///|
test "ecs observer: parent lookup cache isolates archetype activity per world" {
  let world0 = World::new()
  let world1 = World::new()
  reset_observer_parent_lookup_probe_counters(
    world0.world_id(),
    world1.world_id(),
  )

  ignore(
    world0
    .components_registrator()
    .register_component_by_key(observer_parent_lookup_probe_key),
  )
  ignore(
    world1
    .components_registrator()
    .register_component_by_key(observer_parent_lookup_probe_key),
  )

  let parent0 = world0.spawn()
  let child0 = world0.spawn()
  let parent1 = world1.spawn()
  let child1 = world1.spawn()
  let world0_hits : Ref[Int] = Ref::new(0)
  let world1_hits : Ref[Int] = Ref::new(0)

  try! world0.set_by_key(child0, observer_parent_lookup_probe_key, ObserverParentLookupProbe::{
    parent: parent0,
  })

  ignore(
    world0.add_entity_observer(parent0, fn(_event : On[ObserverAttack]) {
      world0_hits.val = world0_hits.val + 1
    }),
  )
  ignore(
    world1.add_entity_observer(parent1, fn(_event : On[ObserverAttack]) {
      world1_hits.val = world1_hits.val + 1
    }),
  )

  world0.trigger(ObserverAttack::{ damage: 7, entity: child0 })
  world1.trigger(ObserverAttack::{ damage: 7, entity: child1 })

  debug_inspect(observer_parent_lookup_probe_world0_calls_ref.val, content="1")
  debug_inspect(observer_parent_lookup_probe_world1_calls_ref.val, content="0")
  debug_inspect(observer_parent_lookup_probe_calls_ref.val, content="1")
  debug_inspect(world0_hits.val, content="1")
  debug_inspect(world1_hits.val, content="0")
}

///|
test "ecs observer: add_remove_entity_component_observer only fires for the bound entity" {
  let world = World::new()
  let entity0 = world.spawn()
  let entity1 = world.spawn()
  let seen_entities : Array[Int] = []
  let hits : Ref[Int] = Ref::new(0)

  ignore(
    world.add_remove_entity_component_observer(entity0, fn(
      event : ComponentOn[Remove, ObserverMarker],
    ) {
      hits.val = hits.val + 1
      seen_entities.push(event.entity.id)
    }),
  )

  try! world.set_by_key(entity0, observer_marker_key, ObserverMarker::{
    value: 1,
  })
  try! world.set_by_key(entity1, observer_marker_key, ObserverMarker::{
    value: 2,
  })
  debug_inspect(
    try! world.remove_by_key(entity0, observer_marker_key),
    content="true",
  )
  debug_inspect(
    try! world.remove_by_key(entity1, observer_marker_key),
    content="true",
  )

  debug_inspect(hits.val, content="1")
  debug_inspect(seen_entities, content="[0]")
}
