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
pub impl Component for MutQueryPosition with fn component() {
  mut_query_position_key
}

///|
pub impl Component for MutQueryVelocity with fn component() {
  mut_query_velocity_key
}

///|
pub impl Component for MutQueryAcceleration with fn component() {
  mut_query_acceleration_key
}

///|
pub impl Component for MutQueryMarker with fn component() {
  mut_query_marker_key
}

///|
pub impl Component for MutQueryMethodValue with fn component() {
  mut_query_method_value_key
}

///|
fn set_test_tick(
  world : World,
  last_run : @core.Tick,
  this_run : @core.Tick,
) -> Unit {
  let ctx = @core.SystemTickContext::new()
  ctx.set(@core.SystemTicks::new(last_run, this_run))
  world.set_tick_context(ctx)
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
  defer world.close()
  let enabled = world.spawn()
  let disabled = world.spawn()

  try! world.set_by_key(enabled, mut_query_position_key, { x: 1, y: 1 })
  try! world.set_by_key(disabled, mut_query_position_key, { x: 2, y: 2 })
  try! world.set_by_key(disabled, ecs_key_disabled, Disabled::new())

  set_test_tick(world, 0, 1)

  let visible_query : Query[Write[MutQueryPosition], All] = query(world)
  let seen_visible : Array[Int] = []
  try! visible_query.view(fn(entity, position_mut) {
    seen_visible.push(entity.id)
    position_mut.modify(fn(value) { value.x = value.x + 10 })
  })

  let disabled_query : Query[Write[MutQueryPosition], With[Disabled]] = query_filtered(
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
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, mut_query_position_key, { x: 1, y: 2 })
  let query : Query[Read[MutQueryPosition], All] = query(world)
  let replace_succeeded : Ref[Bool] = Ref(false)
  let replace_failed : Ref[Bool] = Ref(false)
  try! query.view(fn(entity, _position) {
    world.set_by_key(entity, mut_query_position_key, { x: 3, y: 4 }) catch {
      _ => replace_failed.val = true
    }
    replace_succeeded.val = true
  })
  debug_inspect(replace_failed.val, content="false")
  debug_inspect(replace_succeeded.val, content="true")
  debug_inspect(
    try! world.get_by_key(entity, mut_query_position_key),
    content="Some({ x: 3, y: 4 })",
  )

  let insert_error : Ref[EcsError?] = Ref(None)
  try! query.view(fn(entity, _position) {
    world.set_by_key(entity, mut_query_velocity_key, { dx: 1, dy: 1 }) catch {
      err => insert_error.val = Some(err)
    }
  })
  guard insert_error.val
    is Some(StructuralChangeDuringQueryIteration("insert component")) else {
    fail("expected inserting a new component during Query::view to be rejected")
  }
}

///|
test "ecs query: view rejects structural removal" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, mut_query_position_key, { x: 1, y: 2 })
  let query : Query[Read[MutQueryPosition], All] = query(world)
  let remove_error : Ref[EcsError?] = Ref(None)
  try! query.view(fn(entity, _position) {
    ignore(
      world.remove_by_key(entity, mut_query_position_key) catch {
        err => {
          remove_error.val = Some(err)
          false
        }
      },
    )
  })
  guard remove_error.val
    is Some(StructuralChangeDuringQueryIteration("remove component")) else {
    fail("expected removing a component during Query::view to be rejected")
  }
  debug_inspect(
    try! world.get_by_key(entity, mut_query_position_key),
    content="Some({ x: 1, y: 2 })",
  )
}

///|
test "panic ecs query: escaped iterator rejects an invalidated World lease" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, mut_query_position_key, { x: 1, y: 2 })
  let lease = WorldLease::new(world)
  let query : Query[ReadValue[MutQueryPosition], All] = query_filtered_with_cache_and_lease(
    lease,
    All::new(),
    QueryCache::new(),
  )
  let iter = query.iter()
  lease.invalidate()
  ignore(try! iter.fetch_next())
}

///|
test "panic ecs query: active view rejects World close" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, mut_query_position_key, { x: 1, y: 2 })
  let query : Query[ReadValue[MutQueryPosition], All] = query(world)
  try! query.view(fn(_entity, _position) { world.close() })
}

///|
test "panic ecs query: escaped iterator rejects structural invalidation" {
  let world = World::new()
  defer world.close()
  let first = world.spawn()
  try! world.set_by_key(first, mut_query_position_key, { x: 1, y: 2 })
  let second = world.spawn()
  try! world.set_by_key(second, mut_query_position_key, { x: 3, y: 4 })
  let query : Query[ReadValue[MutQueryPosition], All] = query(world)
  let iter = query.iter()
  ignore(try! iter.fetch_next())
  ignore(world.spawn())
  ignore(try! iter.fetch_next())
}

///|
test "ecs query: nested read-only views keep the outer scope active" {
  let world = World::new()
  defer world.close()
  let first = world.spawn()
  try! world.set_by_key(first, mut_query_position_key, { x: 1, y: 2 })
  let second = world.spawn()
  try! world.set_by_key(second, mut_query_position_key, { x: 3, y: 4 })
  let outer : Query[ReadValue[MutQueryPosition], All] = query(world)
  let inner : Query[ReadValue[MutQueryPosition], All] = query(world)
  let visits = Ref(0)
  try! outer.view(fn(_outer_entity, _outer_position) {
    try! inner.view(fn(_inner_entity, _inner_position) {
      visits.val = visits.val + 1
    })
  })
  debug_inspect(visits.val, content="4")
}

///|
test "ecs mut query: detect changes helpers support explicit mutation and marking" {
  let world = World::new(track_change_locations=true)
  defer world.close()
  let entity = world.spawn()

  try! world.set_by_key(entity, mut_query_position_key, { x: 2, y: 3 })
  world.increment_change_tick() |> ignore
  set_test_tick(world, 0, 1)

  let first_query : Query[Write[MutQueryPosition], All] = query(world)
  let first_position = try! first_query.require_single()
  debug_inspect(first_position.is_added(), content="true")
  debug_inspect(first_position.is_changed(), content="true")
  debug_inspect(first_position.added(), content="1")
  debug_inspect(first_position.last_changed(), content="1")
  debug_inspect(
    first_position.changed_by().unwrap().contains("query_mut_test.mbt"),
    content="true",
  )

  world.increment_change_tick() |> ignore
  set_test_tick(world, 1, 2)

  let second_query : Query[Write[MutQueryPosition], All] = query(world)
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
test "ecs mut query: Write::modify persists method-style mutations" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, mut_query_method_value_key, { value: 1 })
  let query : Query[Write[MutQueryMethodValue], All] = query(world)
  let component_mut = try! query.require_single()
  component_mut.modify(fn(value) { value.bump() })
  debug_inspect(
    try! world.get_by_key(entity, mut_query_method_value_key),
    content="Some({ value: 2 })",
  )
}

///|
test "ecs mut query: table-bound Write set replaces values and marks changes" {
  let world = World::new()
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()
  try! world.set_by_key(first, mut_query_position_key, { x: 1, y: 2 })
  try! world.set_by_key(second, mut_query_position_key, { x: 3, y: 4 })
  world.increment_change_tick() |> ignore
  set_test_tick(world, 0, 1)

  let query : Query[Write[MutQueryPosition], All] = query(world)
  try! query.for_each(fn(entity, position) {
    position.set({ x: entity.id + 10, y: entity.id + 20 })
  })

  debug_inspect(
    try! world.get_by_key(first, mut_query_position_key),
    content="Some({ x: 10, y: 20 })",
  )
  debug_inspect(
    try! world.get_by_key(second, mut_query_position_key),
    content="Some({ x: 11, y: 21 })",
  )
  debug_inspect(
    world.is_changed_by_key(
      first,
      mut_query_position_key,
      @core.SystemTicks::new(0, 1),
    ),
    content="true",
  )
}

///|
test "ecs mut query: QueryState supports get, require_single, iter_many_unique and mixed data" {
  let world = World::new()
  defer world.close()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set_by_key(e0, mut_query_position_key, { x: 2, y: 3 })
  try! world.set_by_key(e0, mut_query_velocity_key, { dx: 10, dy: 20 })
  try! world.set_by_key(e1, mut_query_position_key, { x: 7, y: 8 })
  try! world.set_by_key(e1, mut_query_velocity_key, { dx: 30, dy: 40 })
  try! world.set_by_key(e1, mut_query_acceleration_key, { ax: 1, ay: 1 })

  set_test_tick(world, 0, 1)

  let state : QueryState[
    (Read[MutQueryPosition], Write[MutQueryVelocity]),
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
    (Read[MutQueryPosition], Write[MutQueryVelocity]),
    Without[MutQueryAcceleration],
  ] = query_filtered(world, Without::new(mut_query_acceleration_key))
  let duplicate_entity : @core.Entity? = try {
    ignore(query.iter_many_unique([e0, e0]))
    None
  } catch {
    NonUniqueEntityList(entity) => Some(entity)
    _ => fail("expected duplicate entity diagnostics")
  }
  guard duplicate_entity is Some(entity) else {
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
test "ecs mut query: contiguous_iter and par_iter work with generic Write query data" {
  let world = World::new()
  defer world.close()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()
  let e3 = world.spawn()

  try! world.set_by_key(e0, mut_query_position_key, { x: 1, y: 1 })
  try! world.set_by_key(e1, mut_query_position_key, { x: 2, y: 2 })
  try! world.set_by_key(e3, mut_query_position_key, { x: 4, y: 4 })
  try! world.set_by_key(e0, mut_query_velocity_key, { dx: 10, dy: 0 })
  try! world.set_by_key(e1, mut_query_velocity_key, { dx: 20, dy: 0 })
  try! world.set_by_key(e2, mut_query_velocity_key, { dx: 30, dy: 0 })
  try! world.set_by_key(e3, mut_query_velocity_key, { dx: 40, dy: 0 })

  set_test_tick(world, 0, 1)

  let state : QueryState[(Read[MutQueryPosition], Write[MutQueryVelocity]), All] = world.query()
  guard state.contiguous_iter(world) is Some(iter) else {
    fail("expected contiguous iterator for generic mut query")
  }

  let chunk_values : Array[Int] = []
  while (try! iter.fetch_next()) is Some((position, velocity_mut)) {
    chunk_values.push(position.value().x)
    velocity_mut.modify(fn(value) { value.dx = value.dx + position.value().x })
  }
  debug_inspect(chunk_values, content="[1, 2, 4]")

  let query : Query[(Read[MutQueryPosition], Write[MutQueryVelocity]), All] = query(
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
#warnings("-unnecessary_annotation")
test "ecs mut query: EntityMut query data provides Bevy-style entity access" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  let other = world.spawn()

  try! world.set_by_key(entity, mut_query_marker_key, MutQueryMarker::{  })
  try! world.set_by_key(entity, mut_query_velocity_key, { dx: 3, dy: 4 })
  try! world.set_by_key(other, mut_query_velocity_key, { dx: 9, dy: 10 })

  set_test_tick(world, 0, 1)

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
