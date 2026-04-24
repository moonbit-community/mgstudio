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
struct MutQueryPosition {
  mut x : Int
  y : Int
} derive(Debug, Eq)

///|
struct MutQueryVelocity {
  mut dx : Int
  mut dy : Int
} derive(Debug, Eq)

///|
struct MutQueryAcceleration {
  ax : Int
  ay : Int
} derive(Debug, Eq)

///|
struct MutQueryMarker {} derive(Debug, Eq)

///|
struct MutQueryMethodValue {
  mut value : Int
} derive(Debug, Eq)

///|
fn MutQueryMethodValue::bump(self : MutQueryMethodValue) -> Unit {
  self.value = self.value + 1
}

///|
let mut_query_position_key : ComponentKey[MutQueryPosition] = register_component(
  debug_name="tests.ecs.mut_query.position",
)

///|
let mut_query_velocity_key : ComponentKey[MutQueryVelocity] = register_component(
  debug_name="tests.ecs.mut_query.velocity",
)

///|
let mut_query_acceleration_key : ComponentKey[MutQueryAcceleration] = register_component(
  debug_name="tests.ecs.mut_query.acceleration",
)

///|
let mut_query_marker_key : ComponentKey[MutQueryMarker] = register_component(
  debug_name="tests.ecs.mut_query.marker",
)

///|
let mut_query_method_value_key : ComponentKey[MutQueryMethodValue] = register_component(
  debug_name="tests.ecs.mut_query.method_value",
)

///|
pub impl Component for MutQueryPosition with component() {
  mut_query_position_key
}

///|
pub impl Component for MutQueryVelocity with component() {
  mut_query_velocity_key
}

///|
pub impl Component for MutQueryAcceleration with component() {
  mut_query_acceleration_key
}

///|
pub impl Component for MutQueryMarker with component() {
  mut_query_marker_key
}

///|
pub impl Component for MutQueryMethodValue with component() {
  mut_query_method_value_key
}

///|
fn set_test_sequence(world : World, last_run : Int, this_run : Int) -> Unit {
  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(last_run, this_run))
  world.set_sequence_context(ctx)
}

///|
test "ecs batching strategy: calc batch size respects limits" {
  debug_inspect(
    BatchingStrategy::new()
    .min_batch_size(4)
    .max_batch_size(16)
    .batches_per_thread(2)
    .calc_batch_size(fn() { 100 }, 4),
    content="13",
  )

  debug_inspect(
    BatchingStrategy::fixed(32).calc_batch_size(fn() { 1000 }, 4),
    content="32",
  )
}

///|
test "ecs mut query: generic Query applies disabled filters and updates components" {
  let world = World::new()
  let enabled = world.spawn()
  let disabled = world.spawn()

  try! world.set_by_key(enabled, mut_query_position_key, MutQueryPosition::{
    x: 1,
    y: 1,
  })
  try! world.set_by_key(disabled, mut_query_position_key, MutQueryPosition::{
    x: 2,
    y: 2,
  })
  try! world.set_by_key(disabled, ecs_key_disabled, Disabled::new())

  set_test_sequence(world, 0, 1)

  let visible_query : Query[Mut[MutQueryPosition], All] = query(world)
  let seen_visible : Array[Int] = []
  try! visible_query.view(fn(entity, position_mut) {
    seen_visible.push(entity.id)
    position_mut.modify(fn(value) { value.x = value.x + 10 })
  })

  let disabled_query : Query[Mut[MutQueryPosition], With[Disabled]] = query_filtered(
    world,
    With::new(ecs_key_disabled),
  )
  let seen_disabled : Array[Int] = []
  try! disabled_query.view(fn(entity, position_mut) {
    seen_disabled.push(entity.id)
    position_mut.modify(fn(value) { value.x = value.x + 100 })
  })

  debug_inspect(seen_visible, content="[0]")
  debug_inspect(seen_disabled, content="[1]")
  debug_inspect(
    try! world.get_by_key(enabled, mut_query_position_key),
    content="Some({ x: 11, y: 1 })",
  )
  debug_inspect(
    try! world.get_by_key(disabled, mut_query_position_key),
    content="Some({ x: 102, y: 2 })",
  )
}

///|
test "ecs query: view permits non-structural replacement but rejects structural insertion" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, mut_query_position_key, MutQueryPosition::{
    x: 1,
    y: 2,
  })
  let query : Query[Comp[MutQueryPosition], All] = query(world)
  let replace_result : Ref[Result[Unit, EcsError]?] = Ref::new(None)
  try! query.view(fn(entity, _position) {
    replace_result.val = Some(
      try? world.set_by_key(entity, mut_query_position_key, MutQueryPosition::{
        x: 3,
        y: 4,
      }),
    )
  })
  guard replace_result.val is Some(Ok(_)) else {
    fail("expected existing component replacement to be allowed")
  }
  debug_inspect(
    try! world.get_by_key(entity, mut_query_position_key),
    content="Some({ x: 3, y: 4 })",
  )

  let insert_result : Ref[Result[Unit, EcsError]?] = Ref::new(None)
  try! query.view(fn(entity, _position) {
    insert_result.val = Some(
      try? world.set_by_key(entity, mut_query_velocity_key, MutQueryVelocity::{
        dx: 1,
        dy: 1,
      }),
    )
  })
  guard insert_result.val is Some(
    Err(StructuralChangeDuringQueryIteration("insert component")),
  ) else {
    fail("expected inserting a new component during Query::view to be rejected")
  }
}

///|
test "ecs query: view rejects structural removal" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, mut_query_position_key, MutQueryPosition::{
    x: 1,
    y: 2,
  })
  let query : Query[Comp[MutQueryPosition], All] = query(world)
  let remove_result : Ref[Result[Bool, EcsError]?] = Ref::new(None)
  try! query.view(fn(entity, _position) {
    remove_result.val = Some(try? world.remove_by_key(entity, mut_query_position_key))
  })
  guard remove_result.val is Some(
    Err(StructuralChangeDuringQueryIteration("remove component")),
  ) else {
    fail("expected removing a component during Query::view to be rejected")
  }
  debug_inspect(
    try! world.get_by_key(entity, mut_query_position_key),
    content="Some({ x: 1, y: 2 })",
  )
}

///|
test "ecs mut query: detect changes helpers support explicit mutation and marking" {
  let world = World::new()
  let entity = world.spawn()

  try! world.set_by_key(entity, mut_query_position_key, MutQueryPosition::{
    x: 2,
    y: 3,
  })
  world.advance_sequence() |> ignore
  set_test_sequence(world, 0, 1)

  let first_query : Query[Mut[MutQueryPosition], All] = query(world)
  let first_position = try! first_query.require_single()
  debug_inspect(first_position.is_added(), content="true")
  debug_inspect(first_position.is_changed(), content="true")
  debug_inspect(first_position.added(), content="1")
  debug_inspect(first_position.last_changed(), content="1")
  debug_inspect(
    first_position.changed_by().unwrap().contains("query_mut_test.mbt"),
    content="true",
  )

  world.advance_sequence() |> ignore
  set_test_sequence(world, 1, 2)

  let second_query : Query[Mut[MutQueryPosition], All] = query(world)
  let second_position = try! second_query.require_single()
  debug_inspect(second_position.is_added(), content="false")
  debug_inspect(second_position.is_changed(), content="false")

  second_position.modify(fn(value) { value.x = 9 })
  debug_inspect(second_position.last_changed(), content="2")

  second_position.set_changed()
  debug_inspect(second_position.last_changed(), content="2")
  debug_inspect(
    second_position.changed_by().unwrap().contains("query_mut_test.mbt"),
    content="true",
  )
  debug_inspect(
    try! world.get_by_key(entity, mut_query_position_key),
    content="Some({ x: 9, y: 3 })",
  )
}

///|
test "ecs mut query: Mut::modify persists method-style mutations" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(
    entity,
    mut_query_method_value_key,
    MutQueryMethodValue::{ value: 1 },
  )
  let query : Query[Mut[MutQueryMethodValue], All] = query(world)
  let component_mut = try! query.require_single()
  component_mut.modify(fn(value) { value.bump() })
  debug_inspect(
    try! world.get_by_key(entity, mut_query_method_value_key),
    content="Some({ value: 2 })",
  )
}

///|
test "ecs mut query: QueryState supports get, require_single, iter_many_unique and mixed data" {
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set_by_key(e0, mut_query_position_key, MutQueryPosition::{
    x: 2,
    y: 3,
  })
  try! world.set_by_key(e0, mut_query_velocity_key, MutQueryVelocity::{
    dx: 10,
    dy: 20,
  })
  try! world.set_by_key(e1, mut_query_position_key, MutQueryPosition::{
    x: 7,
    y: 8,
  })
  try! world.set_by_key(e1, mut_query_velocity_key, MutQueryVelocity::{
    dx: 30,
    dy: 40,
  })
  try! world.set_by_key(e1, mut_query_acceleration_key, MutQueryAcceleration::{
    ax: 1,
    ay: 1,
  })

  set_test_sequence(world, 0, 1)

  let state : QueryState[
    (Comp[MutQueryPosition], Mut[MutQueryVelocity]),
    Without[MutQueryAcceleration],
  ] = world.query_filtered(Without::new(mut_query_acceleration_key))

  debug_inspect(state.count(world), content="1")
  if (try! state.get(world, e0)) is Some((position, velocity_mut)) {
    debug_inspect(position.value(), content="{ x: 2, y: 3 }")
    velocity_mut.modify(fn(value) { value.dx = value.dx + position.value().x })
  } else {
    fail("expected matching entity")
  }

  let (single_position, single_velocity) = try! state.require_single(world)
  debug_inspect(single_position.value(), content="{ x: 2, y: 3 }")
  debug_inspect(single_velocity.peek(), content="{ dx: 12, dy: 20 }")

  let query : Query[
    (Comp[MutQueryPosition], Mut[MutQueryVelocity]),
    Without[MutQueryAcceleration],
  ] = query_filtered(world, Without::new(mut_query_acceleration_key))
  let duplicate_result : Result[
    QueryMany[
      (Comp[MutQueryPosition], Mut[MutQueryVelocity]),
      Without[MutQueryAcceleration],
    ],
    EcsError,
  ] = try? query.iter_many_unique([e0, e0])
  guard duplicate_result is Err(NonUniqueEntityList(entity)) else {
    fail("expected duplicate entity diagnostics")
  }
  debug_inspect(entity.id, content="0")

  let seen : Array[Int] = []
  let iter = try! query.iter_many_unique([e1, e2, e0])
  while (try! iter.fetch_next()) is Some((entity, data)) {
    seen.push(entity.id)
    let (position, velocity_mut) = data
    velocity_mut.modify(fn(value) { value.dy = value.dy + position.value().y })
  }

  debug_inspect(seen, content="[0]")
  debug_inspect(
    try! world.get_by_key(e0, mut_query_velocity_key),
    content="Some({ dx: 12, dy: 23 })",
  )
  debug_inspect(
    try! world.get_by_key(e1, mut_query_velocity_key),
    content="Some({ dx: 30, dy: 40 })",
  )
}

///|
test "ecs mut query: contiguous_iter and par_iter work with generic Mut query data" {
  let world = World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()
  let e3 = world.spawn()

  try! world.set_by_key(e0, mut_query_position_key, MutQueryPosition::{
    x: 1,
    y: 1,
  })
  try! world.set_by_key(e1, mut_query_position_key, MutQueryPosition::{
    x: 2,
    y: 2,
  })
  try! world.set_by_key(e3, mut_query_position_key, MutQueryPosition::{
    x: 4,
    y: 4,
  })
  try! world.set_by_key(e0, mut_query_velocity_key, MutQueryVelocity::{
    dx: 10,
    dy: 0,
  })
  try! world.set_by_key(e1, mut_query_velocity_key, MutQueryVelocity::{
    dx: 20,
    dy: 0,
  })
  try! world.set_by_key(e2, mut_query_velocity_key, MutQueryVelocity::{
    dx: 30,
    dy: 0,
  })
  try! world.set_by_key(e3, mut_query_velocity_key, MutQueryVelocity::{
    dx: 40,
    dy: 0,
  })

  set_test_sequence(world, 0, 1)

  let state : QueryState[(Comp[MutQueryPosition], Mut[MutQueryVelocity]), All] = world.query()
  guard state.contiguous_iter(world) is Some(iter) else {
    fail("expected contiguous iterator for generic mut query")
  }

  let chunk_values : Array[Int] = []
  while (try! iter.fetch_next()) is Some((position, velocity_mut)) {
    chunk_values.push(position.value().x)
    velocity_mut.modify(fn(value) { value.dx = value.dx + position.value().x })
  }
  debug_inspect(chunk_values, content="[1, 2, 4]")

  let query : Query[(Comp[MutQueryPosition], Mut[MutQueryVelocity]), All] = query(
    world,
  )
  try! query
  .par_iter()
  .batching_strategy(BatchingStrategy::fixed(32))
  .for_each(fn(_entity, data) {
    let (position, velocity_mut) = data
    velocity_mut.modify(fn(value) { value.dy = value.dy + position.value().y })
  })

  debug_inspect(
    try! world.get_by_key(e0, mut_query_velocity_key),
    content="Some({ dx: 11, dy: 1 })",
  )
  debug_inspect(
    try! world.get_by_key(e1, mut_query_velocity_key),
    content="Some({ dx: 22, dy: 2 })",
  )
  debug_inspect(
    try! world.get_by_key(e2, mut_query_velocity_key),
    content="Some({ dx: 30, dy: 0 })",
  )
  debug_inspect(
    try! world.get_by_key(e3, mut_query_velocity_key),
    content="Some({ dx: 44, dy: 4 })",
  )
}

///|
test "ecs mut query: EntityMut query data provides Bevy-style entity access" {
  let world = World::new()
  let entity = world.spawn()
  let other = world.spawn()

  try! world.set_by_key(entity, mut_query_marker_key, MutQueryMarker::{  })
  try! world.set_by_key(entity, mut_query_velocity_key, MutQueryVelocity::{
    dx: 3,
    dy: 4,
  })
  try! world.set_by_key(other, mut_query_velocity_key, MutQueryVelocity::{
    dx: 9,
    dy: 10,
  })

  set_test_sequence(world, 0, 1)

  let entity_query : Query[EntityMut, With[MutQueryMarker]] = query_filtered(
    world,
    With::new(mut_query_marker_key),
  )
  let entity_mut = try! entity_query.require_single()
  debug_inspect(entity_mut.id().id, content="0")
  debug_inspect(
    try! entity_mut.contains(key=mut_query_velocity_key),
    content="true",
  )
  if (try! entity_mut.get_mut(key=mut_query_velocity_key)) is Some(velocity_mut) {
    velocity_mut.modify(fn(value) { value.dy = value.dy + 5 })
  } else {
    fail("expected mutable velocity")
  }
  ignore(
    try! entity_mut.insert_component(MutQueryAcceleration::{ ax: 7, ay: 8 }),
  )
  let other_mut = try! world.entity_mut(other)
  try! other_mut.despawn()

  debug_inspect(
    try! world.get_by_key(entity, mut_query_velocity_key),
    content="Some({ dx: 3, dy: 9 })",
  )
  debug_inspect(
    try! world.get_by_key(entity, mut_query_acceleration_key),
    content="Some({ ax: 7, ay: 8 })",
  )
  debug_inspect(
    try! world.get_by_key(entity, mut_query_marker_key),
    content="Some({})",
  )
  let alive_query : Query[@core.Entity, All] = query(world)
  debug_inspect(alive_query.count(), content="1")
}
