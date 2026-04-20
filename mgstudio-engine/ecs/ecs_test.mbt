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
struct Counter {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct BrokenCounter {
  value : String
} derive(Eq, Debug, ToJson, FromJson)

///|
struct GlobalConfig {
  fps : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct TickEvent {
  frame : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
let typed_counter_key : ComponentKey[TypedCounter] = register_component(
  debug_name="typed_counter",
)

///|
let typed_marker_key : ComponentKey[TypedMarker] = register_component(
  debug_name="typed_marker",
)

///|
struct TypedCounter {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct TypedMarker {
  enabled : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
struct WorldLocalProbe {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct WorldLocalComponent {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct QueuedRequireA {}

///|
struct QueuedRequireB {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct SparseStorageCounter {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct StorageModeProbe {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
let world_local_probe_key : ComponentKey[WorldLocalProbe] = register_component(
  debug_name="world_local_probe",
)

///|
let world_local_component_key : ComponentKey[WorldLocalComponent] = register_component(
  debug_name="world_local_component",
)

///|
let queued_require_a_key : ComponentKey[QueuedRequireA] = register_component(
  debug_name="queued_require_a",
)

///|
let queued_require_b_key : ComponentKey[QueuedRequireB] = register_component(
  debug_name="queued_require_b",
)

///|
let sparse_storage_counter_key : ComponentKey[SparseStorageCounter] = register_component(
  debug_name="sparse_storage_counter",
)

///|
let storage_mode_probe_key : ComponentKey[StorageModeProbe] = register_component(
  debug_name="storage_mode_probe",
)

///|
let queued_require_metadata_initialized : Ref[Bool] = Ref::new(false)

///|
let sparse_storage_metadata_initialized : Ref[Bool] = Ref::new(false)

///|
fn ensure_queued_require_metadata_registered() -> Unit {
  if queued_require_metadata_initialized.val {
    return
  }
  ignore(
    component_metadata_builder(queued_require_a_key).require_with(
      queued_require_b_key,
      fn() { QueuedRequireB::{ value: 42 } },
    ),
  )
  queued_require_metadata_initialized.val = true
}

///|
fn ensure_sparse_storage_metadata_registered() -> Unit {
  if sparse_storage_metadata_initialized.val {
    return
  }
  ignore(
    component_metadata_builder(sparse_storage_counter_key).storage_sparse_set(),
  )
  sparse_storage_metadata_initialized.val = true
}

///|
pub impl Component for TypedCounter with component() {
  typed_counter_key
}

///|
pub impl Component for TypedMarker with component() {
  typed_marker_key
}

///|
pub impl Component for WorldLocalProbe with component() {
  world_local_probe_key
}

///|
pub impl Component for WorldLocalComponent with component() {
  world_local_component_key
}

///|
pub impl Component for QueuedRequireA with component() {
  queued_require_a_key
}

///|
pub impl Component for QueuedRequireB with component() {
  queued_require_b_key
}

///|
pub impl Component for SparseStorageCounter with component() {
  sparse_storage_counter_key
}

///|
pub impl Component for StorageModeProbe with component() {
  storage_mode_probe_key
}

///|
test "ecs: register key ids are monotonic" {
  let comp_a : ComponentKey[Counter] = register_component(debug_name="counter")
  let comp_b : ComponentKey[Counter] = register_component(
    debug_name="counter_b",
  )
  debug_inspect(comp_b.id() > comp_a.id(), content="true")

  let res_a : ResourceKey[GlobalConfig] = register_resource(debug_name="cfg")
  let res_b : ResourceKey[GlobalConfig] = register_resource(debug_name="cfg_b")
  debug_inspect(res_b.id() > res_a.id(), content="true")

  let event_a : EventKey[TickEvent] = register_event(debug_name="tick")
  let event_b : EventKey[TickEvent] = register_event(debug_name="tick_b")
  debug_inspect(event_b.id() > event_a.id(), content="true")
}

///|
test "ecs: register_resource reuses stable id for repeated debug_name" {
  let res_a : ResourceKey[GlobalConfig] = register_resource(
    debug_name="stable_cfg",
  )
  let res_b : ResourceKey[GlobalConfig] = register_resource(
    debug_name="stable_cfg",
  )
  debug_inspect(res_a.id() == res_b.id(), content="true")
}

///|
test "ecs: register_message reuses stable id for repeated debug_name" {
  let message_a : MessageKey[TickEvent] = register_message(
    debug_name="stable_tick_message",
  )
  let message_b : MessageKey[TickEvent] = register_message(
    debug_name="stable_tick_message",
  )
  debug_inspect(message_a.id() == message_b.id(), content="true")
}

///|
test "ecs: spawn set get update and despawn cleanup" {
  let world = World::new()
  let comp_counter : ComponentKey[Counter] = register_component(
    debug_name="counter",
  )
  let entity = world.spawn()

  try! world.set_by_key(entity, comp_counter, Counter::{ value: 3 })
  debug_inspect(
    try! world.get_by_key(entity, comp_counter),
    content="Some({ value: 3 })",
  )

  debug_inspect(
    try! world.update_by_key(entity, comp_counter, fn(counter) {
      Counter::{ value: counter.value + 9 }
    }),
    content="true",
  )
  debug_inspect(
    try! world.get_by_key(entity, comp_counter),
    content="Some({ value: 12 })",
  )

  try! world.despawn(entity)
  debug_inspect(world.is_alive(entity), content="false")
}

///|
test "ecs: type mismatch includes context" {
  let world = World::new()
  let comp_counter : ComponentKey[Counter] = register_component(
    debug_name="counter_decode",
  )
  let comp_broken : ComponentKey[BrokenCounter] = comp_counter.cast()
  let entity = world.spawn()

  try! world.set_by_key(entity, comp_counter, Counter::{ value: 7 })

  let result : Result[BrokenCounter?, EcsError] = try? world.get_by_key(
    entity, comp_broken,
  )
  guard result is Err(ComponentTypeMismatch(key_id, _name, _entity, _actual)) else {
    fail("expected component type mismatch")
  }
  debug_inspect(key_id == comp_counter.id(), content="true")
}

///|
test "ecs: dead entity fails fast" {
  let world = World::new()
  let comp_counter : ComponentKey[Counter] = register_component(
    debug_name="counter_dead",
  )
  let entity = world.spawn()
  try! world.despawn(entity)

  let set_result : Result[Unit, EcsError] = try? world.set_by_key(
    entity,
    comp_counter,
    Counter::{ value: 1 },
  )
  guard set_result is Err(EntityNotAlive(_)) else {
    fail("expected EntityNotAlive for set")
  }
}

///|
test "ecs: typed component api uses component ownership" {
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let counter_key : ComponentKey[TypedCounter] = Component::component()
  let marker_key : ComponentKey[TypedMarker] = Component::component()

  debug_inspect(counter_key.id() == typed_counter_key.id(), content="true")
  debug_inspect(marker_key.id() == typed_marker_key.id(), content="true")

  try! (world.entity_mut(e0).insert_component(TypedCounter::{ value: 10 })
  |> ignore)
  try! (world.entity_mut(e1).insert_component(TypedCounter::{ value: 20 })
  |> ignore)
  try! (world.entity_mut(e1).insert_component(TypedMarker::{ enabled: true })
  |> ignore)

  let initial_counter : TypedCounter? = try! World::get(world, e0)
  debug_inspect(initial_counter, content="Some({ value: 10 })")
  debug_inspect(
    try! World::update(world, e0, fn(counter : TypedCounter) {
      TypedCounter::{ value: counter.value + 5 }
    }),
    content="true",
  )
  let updated_counter : TypedCounter? = try! World::get(world, e0)
  debug_inspect(updated_counter, content="Some({ value: 15 })")

  let without_marker : Without[TypedMarker] = Without::new(marker_key)
  let filtered : Query[@ecs.Comp[TypedCounter], Without[TypedMarker]] = @ecs.query_filtered(
    world, without_marker,
  )
  debug_inspect(filtered.count(), content="1")
  debug_inspect(
    match (try! filtered.get(e0)) {
      Some(counter) => Some(counter.value())
      None => None
    },
    content="Some({ value: 15 })",
  )
  debug_inspect(
    match (try! filtered.get(e1)) {
      Some(counter) => Some(counter.value())
      None => None
    },
    content="None",
  )

  let tick = world.advance_sequence()
  ignore(tick)
  debug_inspect(tick == 1, content="true")
  debug_inspect(try! world.remove_by_key(e0, counter_key), content="true")
  let removed : Array[@core.Entity] = world
    .removed_components(counter_key, @core.SystemSequence::new(0, 1))
    .read()
  json_inspect(removed, content=[{ "id": 0, "generation": 1 }])
}

///|
test "ecs: archetype tracking follows structural mutations" {
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  let empty_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(empty_archetype_id == 0, content="true")
  debug_inspect(
    world.entity_archetype_id(e1).unwrap_or(-1) == empty_archetype_id,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(empty_archetype_id) == 2,
    content="true",
  )

  try! world.set(e0, TypedCounter::{ value: 1 })
  let counter_only_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(counter_only_archetype_id != empty_archetype_id, content="true")
  debug_inspect(
    world.archetype_entity_count(empty_archetype_id) == 1,
    content="true",
  )

  try! world.set(e0, TypedMarker::{ enabled: true })
  let counter_marker_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(
    counter_marker_archetype_id != counter_only_archetype_id,
    content="true",
  )

  try! world.set(e1, TypedCounter::{ value: 2 })
  try! world.set(e1, TypedMarker::{ enabled: true })
  debug_inspect(
    world.entity_archetype_id(e1).unwrap_or(-1) == counter_marker_archetype_id,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_marker_archetype_id) == 2,
    content="true",
  )

  try! (world.remove_by_key(e1, typed_marker_key) |> ignore)
  debug_inspect(
    world.entity_archetype_id(e1).unwrap_or(-1) == counter_only_archetype_id,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_marker_archetype_id) == 1,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_only_archetype_id) == 1,
    content="true",
  )

  try! world.despawn(e0)
  debug_inspect(world.entity_archetype_id(e0) == None, content="true")
  debug_inspect(
    world.archetype_entity_count(counter_marker_archetype_id) == 0,
    content="true",
  )
}

///|
test "ecs: archetype swap-remove keeps row tracking consistent" {
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, TypedCounter::{ value: 0 })
  try! world.set(e1, TypedCounter::{ value: 1 })
  try! world.set(e2, TypedCounter::{ value: 2 })

  let counter_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(
    world.entity_archetype_id(e1).unwrap_or(-1) == counter_archetype_id,
    content="true",
  )
  debug_inspect(
    world.entity_archetype_id(e2).unwrap_or(-1) == counter_archetype_id,
    content="true",
  )

  try! (world.remove_by_key(e1, typed_counter_key) |> ignore)
  debug_inspect(
    world.archetype_entity_count(counter_archetype_id) == 2,
    content="true",
  )

  let snapshot = world.archetype_entities_snapshot(counter_archetype_id)
  let mut has_e0 = false
  let mut has_e1 = false
  let mut has_e2 = false
  for entity in snapshot {
    if entity.id == e0.id && entity.generation == e0.generation {
      has_e0 = true
    }
    if entity.id == e1.id && entity.generation == e1.generation {
      has_e1 = true
    }
    if entity.id == e2.id && entity.generation == e2.generation {
      has_e2 = true
    }
  }
  debug_inspect(has_e0, content="true")
  debug_inspect(!has_e1, content="true")
  debug_inspect(has_e2, content="true")
}

///|
test "ecs: component runtime ids are world-local and isolated" {
  let world0 = World::new()
  let world1 = World::new()
  let e0 = world0.spawn()
  let e1 = world1.spawn()

  // Force different local registration order between worlds.
  try! world0.set_by_key(e0, world_local_probe_key, WorldLocalProbe::{
    value: 1,
  })
  try! world0.set_by_key(e0, world_local_component_key, WorldLocalComponent::{
    value: 2,
  })
  try! world1.set_by_key(e1, world_local_component_key, WorldLocalComponent::{
    value: 3,
  })

  let world0_id = world0
    .component_id_by_key(world_local_component_key)
    .unwrap_or(-1)
  let world1_id = world1
    .component_id_by_key(world_local_component_key)
    .unwrap_or(-1)
  debug_inspect(world0_id > 0 && world1_id > 0, content="true")
  debug_inspect(world0_id != world1_id, content="true")
}

///|
test "ecs: queued component registration preserves local ids and required-components semantics" {
  ensure_queued_require_metadata_registered()
  let world = World::new()
  let entity = world.spawn()

  let queued_a_id = world.queue_register_component_by_key(queued_require_a_key)
  let queued_b_id = world.queue_register_component_by_key(queued_require_b_key)
  debug_inspect(world.queued_component_registration_count(), content="2")

  // Trigger registration through normal component insertion, which must consume
  // pending queue entries without re-allocating local ids.
  try! world.set_by_key(entity, queued_require_a_key, QueuedRequireA::{  })

  debug_inspect(
    world.component_id_by_key(queued_require_a_key).unwrap_or(-1) == queued_a_id,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(queued_require_b_key).unwrap_or(-1) == queued_b_id,
    content="true",
  )
  debug_inspect(world.queued_component_registration_count(), content="0")
  debug_inspect(
    try! world.get_by_key(entity, queued_require_b_key),
    content="Some({ value: 42 })",
  )
}

///|
test "ecs: apply_queued_component_registrations materializes pending components" {
  ensure_queued_require_metadata_registered()
  let world = World::new()
  let queued_a_id = world.queue_register_component_by_key(queued_require_a_key)
  let queued_b_id = world.queue_register_component_by_key(queued_require_b_key)

  world.apply_queued_component_registrations()
  debug_inspect(world.queued_component_registration_count(), content="0")
  debug_inspect(
    world.component_id_by_key(queued_require_a_key).unwrap_or(-1) == queued_a_id,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(queued_require_b_key).unwrap_or(-1) == queued_b_id,
    content="true",
  )
}

///|
test "ecs: components registrator queued registration preserves ids" {
  ensure_queued_require_metadata_registered()
  let world = World::new()
  let registrator = world.components_registrator()
  let queued = registrator.as_queued()
  let queued_a_id = queued.register_component_by_key(queued_require_a_key)
  let queued_b_id = queued.register_component_by_key(queued_require_b_key)

  debug_inspect(world.queued_component_registration_count(), content="2")
  registrator.apply_queued_registrations()
  debug_inspect(world.queued_component_registration_count(), content="0")

  let registered_a_id = registrator.register_component_by_key(
    queued_require_a_key,
  )
  let registered_b_id = registrator.register_component_by_key(
    queued_require_b_key,
  )
  debug_inspect(registered_a_id == queued_a_id, content="true")
  debug_inspect(registered_b_id == queued_b_id, content="true")
}

///|
test "ecs: sparse-set storage metadata routes through world storage split" {
  ensure_sparse_storage_metadata_registered()
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, sparse_storage_counter_key, SparseStorageCounter::{
    value: 7,
  })
  debug_inspect(
    try! world.get_by_key(entity, sparse_storage_counter_key),
    content="Some({ value: 7 })",
  )
  debug_inspect(
    try! world.remove_by_key(entity, sparse_storage_counter_key),
    content="true",
  )
  debug_inspect(
    try! world.get_by_key(entity, sparse_storage_counter_key),
    content="None",
  )
}

///|
test "ecs: world-local storage type remains stable after metadata mutation" {
  ignore(component_metadata_builder(storage_mode_probe_key).storage_table())

  let world0 = World::new()
  let entity0 = world0.spawn()
  try! world0.set_by_key(entity0, storage_mode_probe_key, StorageModeProbe::{
    value: 10,
  })

  // Mutate global metadata after world0 registration.
  ignore(
    component_metadata_builder(storage_mode_probe_key).storage_sparse_set(),
  )

  let world1 = World::new()
  let entity1 = world1.spawn()
  try! world1.set_by_key(entity1, storage_mode_probe_key, StorageModeProbe::{
    value: 20,
  })

  debug_inspect(
    try! world0.get_by_key(entity0, storage_mode_probe_key),
    content="Some({ value: 10 })",
  )
  debug_inspect(
    try! world1.get_by_key(entity1, storage_mode_probe_key),
    content="Some({ value: 20 })",
  )
  debug_inspect(
    try! world0.remove_by_key(entity0, storage_mode_probe_key),
    content="true",
  )
  debug_inspect(
    try! world1.remove_by_key(entity1, storage_mode_probe_key),
    content="true",
  )
}
