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
struct Position {
  mut x : Int
  mut y : Int
} derive(Show, Eq, ToJson, FromJson)

///|
struct Velocity {
  mut dx : Int
  mut dy : Int
} derive(Show, Eq, ToJson, FromJson)

///|
struct Acceleration {
  mut ax : Int
  mut ay : Int
} derive(Show, Eq, ToJson, FromJson)

///|
test "ecs query: query1 view and for_each" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_q1",
  )
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e1, comp_position, Position::{ x: 1, y: 2 })
  try! world.set(e2, comp_position, Position::{ x: 4, y: 6 })

  let sum_ref : Ref[Int] = Ref::new(0)
  try! world
  .query1(comp_position)
  .view(fn(_entity, position) {
    sum_ref.val = sum_ref.val + position.x + position.y
  })
  inspect(sum_ref.val, content="13")

  try! world
  .query1(comp_position)
  .for_each(fn(_entity, position) {
    position.x = position.x + 10
    position.y = position.y + 20
  })

  inspect(try! world.get(e1, comp_position), content="Some({x: 11, y: 22})")
  inspect(try! world.get(e2, comp_position), content="Some({x: 14, y: 26})")
}

///|
test "ecs query: single returns only for exactly one match" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_single",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_single",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  inspect(try! world.query1(comp_position).single(), content="None")

  try! world.set(e0, comp_position, Position::{ x: 5, y: 8 })
  inspect(
    try! world.query1_filtered(comp_position, All::new()).single(),
    content="Some({x: 5, y: 8})",
  )

  try! world.set(e1, comp_position, Position::{ x: 13, y: 21 })
  inspect(try! world.query1(comp_position).single(), content="None")

  try! world.set(e0, comp_velocity, Velocity::{ dx: 1, dy: 1 })
  inspect(
    try! world.query1_filtered(comp_position, With::new(comp_velocity)).single(),
    content="Some({x: 5, y: 8})",
  )

  try! world.set(e1, comp_velocity, Velocity::{ dx: 2, dy: 3 })
  inspect(
    try! world.query1_filtered(comp_position, With::new(comp_velocity)).single(),
    content="None",
  )
}

///|
test "ecs query: query2 view intersection and for_each" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_q2",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_q2",
  )
  let e_match = world.spawn()
  let e_only_position = world.spawn()
  let e_only_velocity0 = world.spawn()
  let e_only_velocity1 = world.spawn()

  try! world.set(e_match, comp_position, Position::{ x: 3, y: 5 })
  try! world.set(e_match, comp_velocity, Velocity::{ dx: 7, dy: 11 })
  try! world.set(e_only_position, comp_position, Position::{ x: 100, y: 200 })
  try! world.set(e_only_velocity0, comp_velocity, Velocity::{ dx: 1, dy: 2 })
  try! world.set(e_only_velocity1, comp_velocity, Velocity::{ dx: 9, dy: 10 })

  let hits_ref : Ref[Int] = Ref::new(0)
  let sum_ref : Ref[Int] = Ref::new(0)
  try! world
  .query2(comp_position, comp_velocity)
  .view(fn(_entity, p, v) {
    hits_ref.val = hits_ref.val + 1
    sum_ref.val = sum_ref.val + p.x + p.y + v.dx + v.dy
  })
  inspect(hits_ref.val, content="1")
  inspect(sum_ref.val, content="26")

  try! world
  .query2(comp_position, comp_velocity)
  .for_each(fn(_entity, p, v) {
    p.x = p.x + v.dx
    p.y = p.y + v.dy
    v.dx = v.dx + 1
    v.dy = v.dy + 1
  })

  inspect(
    try! world.get(e_match, comp_position),
    content="Some({x: 10, y: 16})",
  )
  inspect(
    try! world.get(e_match, comp_velocity),
    content="Some({dx: 8, dy: 12})",
  )
  inspect(
    try! world.get(e_only_position, comp_position),
    content="Some({x: 100, y: 200})",
  )
  inspect(
    try! world.get(e_only_velocity0, comp_velocity),
    content="Some({dx: 1, dy: 2})",
  )
}

///|
test "ecs query: query3 smallest-store driven iteration and for_each" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_q3",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_q3",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_q3",
  )

  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 2 })
  try! world.set(e2, comp_position, Position::{ x: 3, y: 3 })

  try! world.set(e1, comp_velocity, Velocity::{ dx: 4, dy: 5 })
  try! world.set(e2, comp_velocity, Velocity::{ dx: 6, dy: 7 })

  try! world.set(e2, comp_accel, Acceleration::{ ax: 8, ay: 9 })

  let hits_ref : Ref[Int] = Ref::new(0)
  let score_ref : Ref[Int] = Ref::new(0)
  try! world
  .query3(comp_position, comp_velocity, comp_accel)
  .view(fn(_entity, p, v, a) {
    hits_ref.val = hits_ref.val + 1
    score_ref.val = score_ref.val + p.x + p.y + v.dx + v.dy + a.ax + a.ay
  })
  inspect(hits_ref.val, content="1")
  inspect(score_ref.val, content="36")

  try! world
  .query3(comp_position, comp_velocity, comp_accel)
  .for_each(fn(_entity, p, v, a) {
    p.x = p.x + 100
    p.y = p.y + 100
    v.dx = v.dx + 10
    v.dy = v.dy + 10
    a.ax = a.ax + 1
    a.ay = a.ay + 1
  })
  inspect(try! world.get(e2, comp_position), content="Some({x: 103, y: 103})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 16, dy: 17})")
  inspect(try! world.get(e2, comp_accel), content="Some({ax: 9, ay: 10})")
  inspect(try! world.get(e1, comp_accel), content="None")
}

///|
test "ecs query: filtered query supports with/without tuples and entity counts" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_filtered_query",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_filtered_query",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_filtered_query",
  )

  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 2 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 3, dy: 3 })
  try! world.set(e2, comp_position, Position::{ x: 4, y: 4 })
  try! world.set(e2, comp_velocity, Velocity::{ dx: 5, dy: 5 })
  try! world.set(e2, comp_accel, Acceleration::{ ax: 6, ay: 6 })

  let query = world.query1_filtered(
    comp_position,
    (With::new(comp_velocity), Without::new(comp_accel)),
  )
  inspect(query.count(), content="1")
  inspect(try! query.get(e0), content="None")
  inspect(try! query.get(e1), content="Some({x: 2, y: 2})")
  inspect(try! query.get(e2), content="None")

  let matched_entities : Array[Int] = []
  world
  .query_entities_filtered((With::new(comp_position), Without::new(comp_accel)))
  .view(fn(entity) { matched_entities.push(entity.id) })
  inspect(matched_entities, content="[0, 1]")
}

///|
test "ecs query: component ref exposes live component values" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_component_ref",
  )
  let entity = world.spawn()

  try! world.set(entity, comp_position, Position::{ x: 1, y: 2 })
  let ctx1 = @core.SystemSequenceContext::new()
  ctx1.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx1)
  let initial_ref = (try! world.get_ref(entity, comp_position)).unwrap()
  inspect(initial_ref.value(), content="{x: 1, y: 2}")

  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  inspect(
    try! world.update(entity, comp_position, fn(position) {
      Position::{ x: position.x + 10, y: position.y + 20 }
    }),
    content="true",
  )
  let ctx2 = @core.SystemSequenceContext::new()
  ctx2.set(@core.SystemSequence::new(1, 2))
  world.set_sequence_context(ctx2)
  let changed_ref = (try! world.get_ref(entity, comp_position)).unwrap()
  inspect(changed_ref.value(), content="{x: 11, y: 22}")
}

///|
test "ecs query: structural filters compose without change detection" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query_changed",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query_changed",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 2 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 3, dy: 3 })

  inspect(
    world.query1_filtered(comp_position, With::new(comp_position)).count(),
    content="2",
  )
  inspect(
    world
    .query1_filtered(
      comp_position,
      Or::new((Without::new(comp_velocity), With::new(comp_velocity))),
    )
    .count(),
    content="2",
  )

  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  inspect(
    try! world.update(e1, comp_position, fn(position) {
      Position::{ x: position.x + 1, y: position.y + 1 }
    }),
    content="true",
  )

  inspect(
    world.query1_filtered(comp_position, With::new(comp_position)).count(),
    content="2",
  )
  inspect(
    world.query1_filtered(comp_position, Without::new(comp_velocity)).count(),
    content="1",
  )
  inspect(
    world
    .query1_filtered(
      comp_position,
      Or::new((Without::new(comp_velocity), With::new(comp_velocity))),
    )
    .count(),
    content="2",
  )
}

///|
test "ecs query: iter_many_ref preserves filter order without change state" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_iter_many_ref",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_iter_many_ref",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 2 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 3, dy: 3 })
  try! world.set(e2, comp_position, Position::{ x: 4, y: 4 })
  try! world.set(e2, comp_velocity, Velocity::{ dx: 5, dy: 5 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let seen : Array[Int] = []
  let iter = world
    .query1_filtered(comp_position, With::new(comp_velocity))
    .iter_many_ref([e0, e1, e2])
  while true {
    if (try! iter.fetch_next()) is Some((entity, component_ref)) {
      ignore(component_ref)
      seen.push(entity.id)
    } else {
      break
    }
  }
  inspect(seen, content="[1, 2]")
}

///|
test "ecs query: iter_many_unique_ref rejects duplicates and preserves order" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_iter_many_unique_ref",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_iter_many_unique_ref",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 2 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 3, dy: 3 })
  try! world.set(e2, comp_position, Position::{ x: 4, y: 4 })
  try! world.set(e2, comp_velocity, Velocity::{ dx: 5, dy: 5 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let duplicate_result : Result[
    Query1FilteredManyRef[Position, With[Velocity]],
    EcsError,
  ] = try? world
    .query1_filtered(comp_position, With::new(comp_velocity))
    .iter_many_unique_ref([e1, e1])
  guard duplicate_result is Err(NonUniqueEntityList(entity)) else {
    fail("expected duplicate entity diagnostics")
  }
  inspect(entity.id, content="1")

  let seen : Array[Int] = []
  let iter = try! world
    .query1_filtered(comp_position, With::new(comp_velocity))
    .iter_many_unique_ref([e2, e0, e1])
  while true {
    if (try! iter.fetch_next()) is Some((entity, component_ref)) {
      ignore(component_ref)
      seen.push(entity.id)
    } else {
      break
    }
  }
  inspect(seen, content="[2, 1]")
}

///|
test "ecs query: require_single raises skipped unless exactly one match exists" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_require_single",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_require_single",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  let none_result = try? world.query1(comp_position).require_single()
  guard none_result is Err(@ecs.Skipped(message0)) else {
    fail("expected skipped error when no entity matches")
  }
  inspect(message0, content="Expected exactly one matching entity")

  try! world.set(e0, comp_position, Position::{ x: 5, y: 8 })
  inspect(
    try! world.query1_filtered(comp_position, All::new()).require_single(),
    content="{x: 5, y: 8}",
  )
  let single_entity = try! world
    .query_entities_filtered(With::new(comp_position))
    .require_single()
  inspect(single_entity.id, content="0")
  inspect(single_entity.generation, content="1")

  try! world.set(e1, comp_position, Position::{ x: 13, y: 21 })
  try! world.set(e0, comp_velocity, Velocity::{ dx: 1, dy: 1 })
  let filtered_single = try! world
    .query1_filtered(comp_position, With::new(comp_velocity))
    .require_single()
  inspect(filtered_single, content="{x: 5, y: 8}")

  let many_result = try? world.query1(comp_position).require_single()
  guard many_result is Err(@ecs.Skipped(message1)) else {
    fail("expected skipped error when many entities match")
  }
  inspect(message1, content="Expected exactly one matching entity")
}
