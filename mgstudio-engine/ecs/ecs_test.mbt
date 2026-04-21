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
struct QueuedOrderProbe {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
struct ParityHookRegistrationProbe {} derive(Eq, Debug)

///|
struct ParityRequiredA {} derive(Eq, Debug)

///|
struct ParityRequiredB {} derive(Eq, Debug)

///|
struct ParityRequiredC {} derive(Eq, Debug)

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
let queued_order_probe_key : ComponentKey[QueuedOrderProbe] = register_component(
  debug_name="queued_order_probe",
)

///|
let parity_hook_registration_probe_key : ComponentKey[
  ParityHookRegistrationProbe,
] = register_component(debug_name="parity_hook_registration_probe")

///|
let parity_required_a_key : ComponentKey[ParityRequiredA] = register_component(
  debug_name="parity_required_a",
)

///|
let parity_required_b_key : ComponentKey[ParityRequiredB] = register_component(
  debug_name="parity_required_b",
)

///|
let parity_required_c_key : ComponentKey[ParityRequiredC] = register_component(
  debug_name="parity_required_c",
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
fn int_array_set_equals(lhs : Array[Int], rhs : Array[Int]) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  let lhs_sorted = lhs.copy()
  let rhs_sorted = rhs.copy()
  lhs_sorted.sort()
  rhs_sorted.sort()
  for index in 0..<lhs_sorted.length() {
    if lhs_sorted[index] != rhs_sorted[index] {
      return false
    }
  }
  true
}

///|
fn entity_snapshot_contains(
  entities : Array[@core.Entity],
  target : @core.Entity,
) -> Bool {
  for entity in entities {
    if entity.id == target.id && entity.generation == target.generation {
      return true
    }
  }
  false
}

///|
fn entity_snapshot_count(
  entities : Array[@core.Entity],
  target : @core.Entity,
) -> Int {
  let mut count = 0
  for entity in entities {
    if entity.id == target.id && entity.generation == target.generation {
      count = count + 1
    }
  }
  count
}

///|
fn entity_snapshot_index(
  entities : Array[@core.Entity],
  entity : @core.Entity,
) -> Int {
  for index in 0..<entities.length() {
    let current = entities[index]
    if current.id == entity.id && current.generation == entity.generation {
      return index
    }
  }
  -1
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
pub impl Component for QueuedOrderProbe with component() {
  queued_order_probe_key
}

///|
pub impl Component for ParityHookRegistrationProbe with component() {
  parity_hook_registration_probe_key
}

///|
pub impl Component for ParityRequiredA with component() {
  parity_required_a_key
}

///|
pub impl Component for ParityRequiredB with component() {
  parity_required_b_key
}

///|
pub impl Component for ParityRequiredC with component() {
  parity_required_c_key
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
test "ecs: world bootstrap ordering for lifecycle pseudo-components is fixed" {
  let world = World::new()
  let add_key : ComponentKey[Add] = component_key_from_id(
    ecs_builtin_component_definition_add,
  )
  let insert_key : ComponentKey[Insert] = component_key_from_id(
    ecs_builtin_component_definition_insert,
  )
  let replace_key : ComponentKey[Replace] = component_key_from_id(
    ecs_builtin_component_definition_replace,
  )
  let remove_key : ComponentKey[Remove] = component_key_from_id(
    ecs_builtin_component_definition_remove,
  )
  let despawn_key : ComponentKey[Despawn] = component_key_from_id(
    ecs_builtin_component_definition_despawn,
  )
  let is_resource_key : ComponentKey[Unit] = component_key_from_id(
    ecs_builtin_component_definition_is_resource,
  )
  debug_inspect(
    world.component_id_by_key(add_key).unwrap_or(-1) == 1,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(insert_key).unwrap_or(-1) == 2,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(replace_key).unwrap_or(-1) == 3,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(remove_key).unwrap_or(-1) == 4,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(despawn_key).unwrap_or(-1) == 5,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(is_resource_key).unwrap_or(-1) == 6,
    content="true",
  )
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
test "ecs: spawn_bundle supports flat bundles and empty bundles" {
  ensure_sparse_storage_metadata_registered()
  let world = World::new()

  let empty = try! world.spawn_bundle(())
  let nested = try! world.spawn_bundle(
    (
      TypedCounter::{ value: 9 },
      TypedMarker::{ enabled: true },
      SparseStorageCounter::{ value: 12 },
    ),
  )

  debug_inspect(world.is_alive(empty), content="true")
  debug_inspect(
    world.entity_archetype_id(empty).unwrap_or(-1) == 0,
    content="true",
  )
  debug_inspect(try! world.get_by_key(empty, typed_counter_key), content="None")
  debug_inspect(
    try! world.get_by_key(nested, typed_counter_key),
    content="Some({ value: 9 })",
  )
  debug_inspect(
    try! world.get_by_key(nested, typed_marker_key),
    content="Some({ enabled: true })",
  )
  debug_inspect(
    try! world.get_by_key(nested, sparse_storage_counter_key),
    content="Some({ value: 12 })",
  )
}

///|
test "ecs: for_each_component tolerates structural changes during iteration" {
  let world = World::new()
  let visited : Array[Int] = []

  for i in 0..<32 {
    let entity = world.spawn()
    try! world.set_by_key(entity, typed_counter_key, TypedCounter::{ value: i })
  }

  world.for_each_component(typed_counter_key, fn(entity, _counter) {
    visited.push(entity.id)
    try! world.set_by_key(entity, typed_marker_key, TypedMarker::{
      enabled: true,
    })
  })

  visited.sort()
  debug_inspect(visited.length(), content="32")
  debug_inspect(visited[0], content="0")
  debug_inspect(visited[31], content="31")
  debug_inspect(world.component_count(typed_marker_key), content="32")
}

///|
test "ecs: bundle migration paths follow archetype/table topology" {
  ensure_sparse_storage_metadata_registered()
  let world = World::new()
  let entity = world.spawn()

  let empty_archetype_id = world.entity_archetype_id(entity).unwrap_or(-1)
  debug_inspect(world.archetype_table_id(empty_archetype_id), content="Some(0)")

  try! world.set(entity, TypedCounter::{ value: 1 })
  let counter_archetype_id = world.entity_archetype_id(entity).unwrap_or(-1)
  debug_inspect(
    world.bundle_migration_path_label_for_archetypes(
      empty_archetype_id, counter_archetype_id,
    ) ==
    "new-archetype-new-table",
    content="true",
  )

  let counter_table_id = world
    .archetype_table_id(counter_archetype_id)
    .unwrap_or(-1)
  debug_inspect(counter_table_id >= 0, content="true")

  try! world.set_by_key(entity, sparse_storage_counter_key, SparseStorageCounter::{
    value: 7,
  })
  let counter_sparse_archetype_id = world
    .entity_archetype_id(entity)
    .unwrap_or(-1)
  debug_inspect(
    world.bundle_migration_path_label_for_archetypes(
      counter_archetype_id, counter_sparse_archetype_id,
    ) ==
    "new-archetype-same-table",
    content="true",
  )
  debug_inspect(
    world.archetype_table_id(counter_sparse_archetype_id).unwrap_or(-1) ==
    counter_table_id,
    content="true",
  )

  try! (world.remove_by_key(entity, sparse_storage_counter_key) |> ignore)
  let back_to_counter_archetype_id = world
    .entity_archetype_id(entity)
    .unwrap_or(-1)
  debug_inspect(
    back_to_counter_archetype_id == counter_archetype_id,
    content="true",
  )
  debug_inspect(
    world.bundle_migration_path_label_for_archetypes(
      counter_archetype_id, counter_archetype_id,
    ) ==
    "same-archetype",
    content="true",
  )
}

///|
test "ecs: bundle migration execution keeps path boundaries and row consistency" {
  ensure_sparse_storage_metadata_registered()
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, TypedCounter::{ value: 10 })
  try! world.set(e1, TypedCounter::{ value: 20 })

  let counter_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(
    world.entity_archetype_id(e1).unwrap_or(-1) == counter_archetype_id,
    content="true",
  )
  let counter_table_id = world
    .archetype_table_id(counter_archetype_id)
    .unwrap_or(-1)
  let counter_entities_before = world.archetype_entities_snapshot(
    counter_archetype_id,
  )
  let e0_counter_row_before = entity_snapshot_index(counter_entities_before, e0)
  let e1_counter_row_before = entity_snapshot_index(counter_entities_before, e1)
  debug_inspect(
    e0_counter_row_before >= 0 && e1_counter_row_before >= 0,
    content="true",
  )

  debug_inspect(
    world.bundle_migration_path_label_for_archetypes(
      counter_archetype_id, counter_archetype_id,
    ) ==
    "same-archetype",
    content="true",
  )
  debug_inspect(
    try! world.update_by_key(e0, typed_counter_key, fn(counter) {
      TypedCounter::{ value: counter.value }
    }),
    content="true",
  )
  debug_inspect(
    world.entity_archetype_id(e0).unwrap_or(-1) == counter_archetype_id,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_archetype_id) == 2,
    content="true",
  )
  let counter_entities_after_same = world.archetype_entities_snapshot(
    counter_archetype_id,
  )
  debug_inspect(
    entity_snapshot_count(counter_entities_after_same, e0) == 1,
    content="true",
  )
  let e0_counter_row_after_same = entity_snapshot_index(
    counter_entities_after_same, e0,
  )
  debug_inspect(
    e0_counter_row_after_same == e0_counter_row_before,
    content="true",
  )
  debug_inspect(
    entity_snapshot_index(counter_entities_after_same, e1) ==
    e1_counter_row_before,
    content="true",
  )

  try! world.set_by_key(e0, sparse_storage_counter_key, SparseStorageCounter::{
    value: 7,
  })
  let counter_sparse_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(
    world.bundle_migration_path_label_for_archetypes(
      counter_archetype_id, counter_sparse_archetype_id,
    ) ==
    "new-archetype-same-table",
    content="true",
  )
  debug_inspect(
    world.archetype_table_id(counter_sparse_archetype_id).unwrap_or(-1) ==
    counter_table_id,
    content="true",
  )
  let counter_sparse_entities_after_same_table = world.archetype_entities_snapshot(
    counter_sparse_archetype_id,
  )
  let counter_entities_after_same_table = world.archetype_entities_snapshot(
    counter_archetype_id,
  )
  let e0_counter_row_after_same_table = entity_snapshot_index(
    counter_sparse_entities_after_same_table, e0,
  )
  let e1_counter_row_after_same_table = entity_snapshot_index(
    counter_entities_after_same_table, e1,
  )
  debug_inspect(e0_counter_row_after_same_table == 0, content="true")
  debug_inspect(e1_counter_row_after_same_table == 0, content="true")

  try! world.set(e0, TypedMarker::{ enabled: true })
  let counter_sparse_marker_archetype_id = world
    .entity_archetype_id(e0)
    .unwrap_or(-1)
  debug_inspect(
    world.bundle_migration_path_label_for_archetypes(
      counter_sparse_archetype_id, counter_sparse_marker_archetype_id,
    ) ==
    "new-archetype-new-table",
    content="true",
  )
  let marker_table_id = world
    .archetype_table_id(counter_sparse_marker_archetype_id)
    .unwrap_or(-1)
  debug_inspect(
    marker_table_id >= 0 && marker_table_id != counter_table_id,
    content="true",
  )
  let counter_sparse_entities_after_new_table = world.archetype_entities_snapshot(
    counter_sparse_archetype_id,
  )
  let counter_sparse_marker_entities_after_new_table = world.archetype_entities_snapshot(
    counter_sparse_marker_archetype_id,
  )
  let counter_entities_after_new_table = world.archetype_entities_snapshot(
    counter_archetype_id,
  )
  debug_inspect(
    entity_snapshot_index(counter_sparse_entities_after_new_table, e0) == -1,
    content="true",
  )
  debug_inspect(
    entity_snapshot_index(counter_sparse_marker_entities_after_new_table, e0) ==
    0,
    content="true",
  )
  debug_inspect(
    entity_snapshot_index(counter_entities_after_new_table, e1) ==
    e1_counter_row_after_same_table,
    content="true",
  )
  debug_inspect(
    match (try! world.get_by_key(e0, typed_counter_key)) {
      Some(counter) => counter.value == 10
      None => false
    },
    content="true",
  )
  debug_inspect(
    match (try! world.get_by_key(e1, typed_counter_key)) {
      Some(counter) => counter.value == 20
      None => false
    },
    content="true",
  )
}

///|
test "ecs: structural mutations keep archetype membership deterministic" {
  ensure_sparse_storage_metadata_registered()
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  let empty_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(world.archetype_count() == 1, content="true")
  debug_inspect(
    world.archetype_entity_count(empty_archetype_id) == 2,
    content="true",
  )
  debug_inspect(
    int_array_set_equals(
      world.archetype_component_ids(empty_archetype_id).unwrap_or([]),
      [],
    ),
    content="true",
  )

  try! world.set(e0, TypedCounter::{ value: 1 })
  let counter_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  let counter_local_id = world
    .component_id_by_key(typed_counter_key)
    .unwrap_or(-1)
  debug_inspect(world.archetype_count() == 2, content="true")
  debug_inspect(
    world.archetype_entity_count(empty_archetype_id) == 1,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_archetype_id) == 1,
    content="true",
  )
  debug_inspect(
    int_array_set_equals(
      world.archetype_component_ids(counter_archetype_id).unwrap_or([]),
      [typed_counter_key.id()],
    ),
    content="true",
  )
  debug_inspect(
    world.archetype_component_local_index(
      counter_archetype_id, counter_local_id,
    ) ==
    Some(0),
    content="true",
  )
  let counter_entities_after_first_add = world.archetype_entities_snapshot(
    counter_archetype_id,
  )
  debug_inspect(
    entity_snapshot_contains(counter_entities_after_first_add, e0),
    content="true",
  )
  debug_inspect(
    !entity_snapshot_contains(counter_entities_after_first_add, e1),
    content="true",
  )

  try! world.set(e1, TypedCounter::{ value: 2 })
  debug_inspect(
    world.archetype_entity_count(counter_archetype_id) == 2,
    content="true",
  )

  try! world.set(e0, TypedMarker::{ enabled: true })
  let counter_marker_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(
    world.archetype_entity_count(counter_archetype_id) == 1,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_marker_archetype_id) == 1,
    content="true",
  )
  debug_inspect(
    int_array_set_equals(
      world.archetype_component_ids(counter_marker_archetype_id).unwrap_or([]),
      [typed_counter_key.id(), typed_marker_key.id()],
    ),
    content="true",
  )

  try! world.set_by_key(e0, sparse_storage_counter_key, SparseStorageCounter::{
    value: 9,
  })
  let counter_marker_sparse_archetype_id = world
    .entity_archetype_id(e0)
    .unwrap_or(-1)
  debug_inspect(
    world.archetype_entity_count(counter_marker_archetype_id) == 0,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_marker_sparse_archetype_id) == 1,
    content="true",
  )
  debug_inspect(
    int_array_set_equals(
      world
      .archetype_component_ids(counter_marker_sparse_archetype_id)
      .unwrap_or([]),
      [
        typed_counter_key.id(),
        typed_marker_key.id(),
        sparse_storage_counter_key.id(),
      ],
    ),
    content="true",
  )
  debug_inspect(
    world.bundle_migration_path_label_for_archetypes(
      counter_marker_archetype_id, counter_marker_sparse_archetype_id,
    ) ==
    "new-archetype-same-table",
    content="true",
  )

  try! (world.remove_by_key(e0, typed_marker_key) |> ignore)
  let counter_sparse_archetype_id = world.entity_archetype_id(e0).unwrap_or(-1)
  debug_inspect(
    world.archetype_entity_count(counter_marker_sparse_archetype_id) == 0,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_sparse_archetype_id) == 1,
    content="true",
  )
  debug_inspect(
    int_array_set_equals(
      world.archetype_component_ids(counter_sparse_archetype_id).unwrap_or([]),
      [typed_counter_key.id(), sparse_storage_counter_key.id()],
    ),
    content="true",
  )

  try! world.despawn(e0)
  debug_inspect(world.entity_archetype_id(e0) == None, content="true")
  debug_inspect(
    world.archetype_entity_count(counter_sparse_archetype_id) == 0,
    content="true",
  )
  debug_inspect(
    world.archetype_entity_count(counter_archetype_id) == 1,
    content="true",
  )
  let counter_entities_after_despawn = world.archetype_entities_snapshot(
    counter_archetype_id,
  )
  debug_inspect(
    !entity_snapshot_contains(counter_entities_after_despawn, e0),
    content="true",
  )
  debug_inspect(
    entity_snapshot_contains(counter_entities_after_despawn, e1),
    content="true",
  )
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
test "ecs: queued registration flush preserves deterministic queue order and local ids" {
  ensure_queued_require_metadata_registered()
  let world = World::new()
  let registrator = world.components_registrator()
  let queued = registrator.as_queued()

  let queued_a_id = queued.register_component_by_key(queued_require_a_key)
  let queued_probe_id = queued.register_component_by_key(queued_order_probe_key)
  let queued_b_id = queued.register_component_by_key(queued_require_b_key)

  debug_inspect(queued_a_id < queued_probe_id, content="true")
  debug_inspect(queued_probe_id < queued_b_id, content="true")
  debug_inspect(world.queued_component_registration_count(), content="3")

  registrator.apply_queued_registrations()
  debug_inspect(world.queued_component_registration_count(), content="0")
  debug_inspect(
    world.component_id_by_key(queued_require_a_key).unwrap_or(-1) == queued_a_id,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(queued_order_probe_key).unwrap_or(-1) ==
    queued_probe_id,
    content="true",
  )
  debug_inspect(
    world.component_id_by_key(queued_require_b_key).unwrap_or(-1) == queued_b_id,
    content="true",
  )
}

///|
test "ecs: queued registration ids stay stable across worlds with identical queue order" {
  ensure_queued_require_metadata_registered()
  let world0 = World::new()
  let world1 = World::new()

  let registrator0 = world0.components_registrator()
  let registrator1 = world1.components_registrator()
  let queued0 = registrator0.as_queued()
  let queued1 = registrator1.as_queued()

  let world0_a_id = queued0.register_component_by_key(queued_require_a_key)
  let world0_probe_id = queued0.register_component_by_key(
    queued_order_probe_key,
  )
  let world0_b_id = queued0.register_component_by_key(queued_require_b_key)

  let world1_a_id = queued1.register_component_by_key(queued_require_a_key)
  let world1_probe_id = queued1.register_component_by_key(
    queued_order_probe_key,
  )
  let world1_b_id = queued1.register_component_by_key(queued_require_b_key)

  debug_inspect(world0_a_id == world1_a_id, content="true")
  debug_inspect(world0_probe_id == world1_probe_id, content="true")
  debug_inspect(world0_b_id == world1_b_id, content="true")

  registrator0.apply_queued_registrations()
  registrator1.apply_queued_registrations()
  debug_inspect(
    world0.component_id_by_key(queued_require_a_key).unwrap_or(-1) ==
    world0_a_id,
    content="true",
  )
  debug_inspect(
    world1.component_id_by_key(queued_require_a_key).unwrap_or(-1) ==
    world1_a_id,
    content="true",
  )
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

///|
test "ecs parity wave2: duplicate hook kind registration fails in-world" {
  let world = World::new()
  let builder = world.register_component_hooks_for_key(
    parity_hook_registration_probe_key,
  )
  ignore(try! builder.on_insert(fn(_world, _context) { () }))

  let duplicate_result : Result[
    ComponentHooksBuilder[ParityHookRegistrationProbe],
    ComponentHooksError,
  ] = try? world
    .register_component_hooks_for_key(parity_hook_registration_probe_key)
    .on_insert(fn(_world, _context) { () })

  guard duplicate_result
    is Err(DuplicateHookRegistration(component_id, OnInsert)) else {
    fail("expected duplicate hook kind registration to fail")
  }
  let expected_component_id = world
    .component_id_by_key(parity_hook_registration_probe_key)
    .unwrap_or(-1)
  debug_inspect(component_id == expected_component_id, content="true")
}

///|
test "ecs parity wave2: late hook registration after archetype use fails" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, parity_hook_registration_probe_key, ParityHookRegistrationProbe::{

  })

  let late_result : Result[
    ComponentHooksBuilder[ParityHookRegistrationProbe],
    ComponentHooksError,
  ] = try? world
    .register_component_hooks_for_key(parity_hook_registration_probe_key)
    .on_add(fn(_world, _context) { () })
  guard late_result is Err(ComponentAlreadyInUse(component_id)) else {
    fail("expected late hook registration to fail")
  }
  let expected_component_id = world
    .component_id_by_key(parity_hook_registration_probe_key)
    .unwrap_or(-1)
  debug_inspect(component_id == expected_component_id, content="true")
}

///|
test "ecs parity wave2: required_by tracks transitive closure and cycle registration fails" {
  let world = World::new()

  try! world.register_required_components_with(
    parity_required_a_key,
    parity_required_b_key,
    fn() { ParityRequiredB::{  } },
  )
  try! world.register_required_components_with(
    parity_required_b_key,
    parity_required_c_key,
    fn() { ParityRequiredC::{  } },
  )

  let required_by_c = world
    .get_required_by_components(parity_required_c_key)
    .unwrap()
  debug_inspect(required_by_c.len(), content="2")
  debug_inspect(
    required_by_c.contains(parity_required_a_key.id()),
    content="true",
  )
  debug_inspect(
    required_by_c.contains(parity_required_b_key.id()),
    content="true",
  )

  let cycle_result : Result[Unit, RequiredComponentsError] = try? world.register_required_components_with(
    parity_required_c_key,
    parity_required_a_key,
    fn() { ParityRequiredA::{  } },
  )
  guard cycle_result is Err(CyclicRequirement(requiree_id, required_id)) else {
    fail("expected cycle registration to fail")
  }
  let expected_requiree_id = world
    .component_id_by_key(parity_required_c_key)
    .unwrap_or(-1)
  let expected_required_id = world
    .component_id_by_key(parity_required_a_key)
    .unwrap_or(-1)
  debug_inspect(requiree_id == expected_requiree_id, content="true")
  debug_inspect(required_id == expected_required_id, content="true")
}
