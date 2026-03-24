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
test "ecs batching strategy: calc batch size respects limits" {
  inspect(
    BatchingStrategy::new()
    .min_batch_size(4)
    .max_batch_size(16)
    .batches_per_thread(2)
    .calc_batch_size(fn() { 100 }, 4),
    content="13",
  )

  inspect(
    BatchingStrategy::fixed(32).calc_batch_size(fn() { 1000 }, 4),
    content="32",
  )
}

///|
test "ecs query mut: iter_many_mut updates filtered components without change flags" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_iter_many_mut",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_iter_many_mut",
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

  let iter = world
    .query1_filtered(comp_position, With::new(comp_velocity))
    .iter_many_mut([e0, e1, e2])
  let seen : Array[Int] = []
  while iter.fetch_next() is Some((entity, component_mut)) {
    seen.push(entity.id)
    component_mut.get_ref().val.x = component_mut.get_ref().val.x + 10
  }

  inspect(seen, content="[1, 2]")
  inspect(try! world.get(e1, comp_position), content="Some({x: 12, y: 2})")
  inspect(try! world.get(e2, comp_position), content="Some({x: 14, y: 4})")
}

///|
test "ecs query mut: read-only view_mut leaves data accessible" {
  let world = World::new()
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query_mut_read_only",
  )
  let entity = world.spawn()
  let observed_velocity : Array[Velocity] = []

  try! world.set(entity, comp_velocity, Velocity::{ dx: 1, dy: 2 })
  let ctx1 = @core.SystemSequenceContext::new()
  ctx1.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx1)
  try! world
  .query1_filtered(comp_velocity, All::new())
  .view_mut(fn(_entity, component_mut) {
    observed_velocity.push(component_mut.get())
  })
  inspect(observed_velocity, content="[{dx: 1, dy: 2}]")

  world.advance_sequence() |> ignore
  world.advance_sequence() |> ignore
  let ctx2 = @core.SystemSequenceContext::new()
  ctx2.set(@core.SystemSequence::new(1, 2))
  world.set_sequence_context(ctx2)

  inspect(world.query1_filtered(comp_velocity, All::new()).count(), content="1")
}

///|
test "ecs query mut: default query filters also apply to mutable queries" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query_mut_disabled",
  )
  let enabled = world.spawn()
  let disabled = world.spawn()

  try! world.set(enabled, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(disabled, comp_position, Position::{ x: 2, y: 2 })
  try! world.set(disabled, ecs_key_disabled, Disabled::new())

  let seen_enabled : Array[Int] = []
  try! world
  .query1(comp_position)
  .view_mut(fn(entity, position) {
    seen_enabled.push(entity.id)
    position.get_ref().val.x = position.get_ref().val.x + 10
  })

  let seen_disabled : Array[Int] = []
  try! world
  .query1_filtered(comp_position, With::new(ecs_key_disabled))
  .view_mut(fn(entity, position) {
    seen_disabled.push(entity.id)
    position.get_ref().val.x = position.get_ref().val.x + 100
  })

  inspect(seen_enabled, content="[0]")
  inspect(seen_disabled, content="[1]")
  inspect(try! world.get(enabled, comp_position), content="Some({x: 11, y: 1})")
  inspect(
    try! world.get(disabled, comp_position),
    content="Some({x: 102, y: 2})",
  )
}

///|
test "ecs query mut: query2 ref mut supports iter_many_mut and par_iter_mut" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query2_ref_mut",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query2_ref_mut",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_query2_ref_mut",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(e0, comp_velocity, Velocity::{ dx: 10, dy: 10 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 3 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 20, dy: 30 })
  try! world.set(e2, comp_position, Position::{ x: 4, y: 5 })
  try! world.set(e2, comp_velocity, Velocity::{ dx: 40, dy: 50 })
  try! world.set(e2, comp_accel, Acceleration::{ ax: 1, ay: 1 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query2_ref_mut_filtered(
    comp_position,
    comp_velocity,
    Without::new(comp_accel),
  )
  inspect(query.count(), content="2")

  let iter = query.iter_many_mut([e2, e1, e0])
  let seen : Array[Int] = []
  while iter.fetch_next() is Some((entity, position_ref, velocity_mut)) {
    seen.push(entity.id)
    velocity_mut.get_ref().val.dx = velocity_mut.get_ref().val.dx +
      position_ref.value().x
  }

  inspect(seen, content="[1, 0]")
  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 11, dy: 10})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 22, dy: 30})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 40, dy: 50})")

  try! query
  .par_iter_mut()
  .batching_strategy(BatchingStrategy::fixed(32))
  .for_each(fn(_entity, position_ref, velocity_mut) {
    velocity_mut.get_ref().val.dy = velocity_mut.get_ref().val.dy +
      position_ref.value().y
  })

  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 11, dy: 11})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 22, dy: 33})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 40, dy: 50})")
}

///|
test "ecs query mut: query2 value mut contiguous_iter_mut yields dense chunks" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query2_value_mut_contiguous",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query2_value_mut_contiguous",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()
  let e3 = world.spawn()

  try! world.set(e0, comp_velocity, Velocity::{ dx: 10, dy: 0 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 20, dy: 0 })
  try! world.set(e2, comp_velocity, Velocity::{ dx: 30, dy: 0 })
  try! world.set(e3, comp_velocity, Velocity::{ dx: 40, dy: 0 })

  try! world.set(e0, comp_position, Position::{ x: 1, y: 0 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 0 })
  try! world.set(e3, comp_position, Position::{ x: 4, y: 0 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query2_value_mut_filtered(
    comp_position,
    comp_velocity,
    All::new(),
  )
  guard query.contiguous_iter_mut() is Some(iter) else {
    fail("expected contiguous iterator for query2 value mut")
  }

  let chunk_lens : Array[Int] = []
  while iter.fetch_next() is Some((positions, velocities)) {
    chunk_lens.push(positions.length())
    inspect(positions.length() == velocities.length(), content="true")
    for i in 0..<positions.length() {
      velocities[i].get_ref().val.dx = velocities[i].get_ref().val.dx +
        positions[i].x
    }
  }

  inspect(chunk_lens, content="[2, 1]")
  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 11, dy: 0})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 22, dy: 0})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 30, dy: 0})")
  inspect(try! world.get(e3, comp_velocity), content="Some({dx: 44, dy: 0})")
}

///|
test "ecs query mut: query2 ref mut contiguous_iter_mut preserves chunk shape" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query2_ref_mut_contiguous",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query2_ref_mut_contiguous",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()
  let e3 = world.spawn()

  try! world.set(e0, comp_velocity, Velocity::{ dx: 10, dy: 0 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 20, dy: 0 })
  try! world.set(e2, comp_velocity, Velocity::{ dx: 30, dy: 0 })
  try! world.set(e3, comp_velocity, Velocity::{ dx: 40, dy: 0 })

  try! world.set(e0, comp_position, Position::{ x: 1, y: 0 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 0 })
  try! world.set(e3, comp_position, Position::{ x: 4, y: 0 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query2_ref_mut_filtered(
    comp_position,
    comp_velocity,
    All::new(),
  )
  guard query.contiguous_iter_mut() is Some(iter) else {
    fail("expected contiguous iterator for query2 ref mut")
  }

  let chunk_lens : Array[Int] = []
  while iter.fetch_next() is Some((positions, velocities)) {
    chunk_lens.push(positions.length())
    inspect(positions.length() == velocities.length(), content="true")
    for i in 0..<positions.length() {
      velocities[i].get_ref().val.dx = velocities[i].get_ref().val.dx +
        positions[i].value().x
    }
  }

  inspect(chunk_lens, content="[2, 1]")
  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 11, dy: 0})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 22, dy: 0})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 30, dy: 0})")
  inspect(try! world.get(e3, comp_velocity), content="Some({dx: 44, dy: 0})")
}

///|
test "ecs query mut: plain query1 supports count and view_mut" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query1_plain_mut",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 2 })
  try! world.set(e1, comp_position, Position::{ x: 3, y: 4 })
  inspect(world.query1(comp_position).count(), content="2")

  let ctx1 = @core.SystemSequenceContext::new()
  ctx1.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx1)
  try! world.query1(comp_position).view_mut(fn(_entity, _position_mut) { () })
  inspect(world.query1_filtered(comp_position, All::new()).count(), content="2")

  world.advance_sequence() |> ignore
  let ctx2 = @core.SystemSequenceContext::new()
  ctx2.set(@core.SystemSequence::new(1, 2))
  world.set_sequence_context(ctx2)
  inspect(world.query1_filtered(comp_position, All::new()).count(), content="2")
}

///|
test "ecs query mut: query2 value mut filtered matches required pair only" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query2_value_mut",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query2_value_mut",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_query2_value_mut",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 1 })
  try! world.set(e0, comp_velocity, Velocity::{ dx: 10, dy: 20 })
  try! world.set(e1, comp_position, Position::{ x: 2, y: 2 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 30, dy: 40 })
  try! world.set(e1, comp_accel, Acceleration::{ ax: 1, ay: 1 })
  try! world.set(e2, comp_position, Position::{ x: 3, y: 3 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query2_value_mut_filtered(
    comp_position,
    comp_velocity,
    Without::new(comp_accel),
  )
  inspect(query.count(), content="1")
  if (try! query.get(e0)) is Some((position, velocity_mut)) {
    inspect(position, content="{x: 1, y: 1}")
    inspect(velocity_mut.get(), content="{dx: 10, dy: 20}")
  } else {
    inspect(false, content="true")
  }
  try! query
  .par_iter_mut()
  .for_each(fn(_entity, position, velocity_mut) {
    velocity_mut.get_ref().val.dx = velocity_mut.get_ref().val.dx + position.x
  })

  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 11, dy: 20})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 30, dy: 40})")
}

///|
test "ecs query mut: query3 value ref mut filtered supports mixed data shape" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query3_value_ref_mut",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query3_value_ref_mut",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_query3_value_ref_mut",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 2 })
  try! world.set(e0, comp_velocity, Velocity::{ dx: 3, dy: 4 })
  try! world.set(e0, comp_accel, Acceleration::{ ax: 5, ay: 6 })
  try! world.set(e1, comp_position, Position::{ x: 7, y: 8 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 9, dy: 10 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query3_value_ref_mut_filtered(
    comp_position,
    comp_velocity,
    comp_accel,
    All::new(),
  )
  inspect(query.count(), content="1")
  try! query
  .par_iter_mut()
  .for_each(fn(_entity, position, velocity_ref, accel_mut) {
    accel_mut.get_ref().val.ax = accel_mut.get_ref().val.ax +
      position.x +
      velocity_ref.value().dx
  })

  inspect(try! world.get(e0, comp_accel), content="Some({ax: 9, ay: 6})")
  inspect(try! world.get(e1, comp_accel), content="None")
}

///|
test "ecs query mut: query3 ref mut optional preserves optional ref semantics" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query3_ref_mut_optional",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query3_ref_mut_optional",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_query3_ref_mut_optional",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 1, y: 2 })
  try! world.set(e0, comp_velocity, Velocity::{ dx: 3, dy: 4 })
  try! world.set(e0, comp_accel, Acceleration::{ ax: 5, ay: 6 })
  try! world.set(e1, comp_position, Position::{ x: 7, y: 8 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 9, dy: 10 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query3_ref_mut_optional_filtered(
    comp_position,
    comp_velocity,
    comp_accel,
    All::new(),
  )
  inspect(query.count(), content="2")

  let seen : Array[Int] = []
  try! query.view_mut(fn(entity, position_ref, velocity_mut, accel_ref) {
    ignore(accel_ref)
    seen.push(entity.id)
    velocity_mut.get_ref().val.dy = velocity_mut.get_ref().val.dy +
      position_ref.value().y
  })

  inspect(seen, content="[0, 1]")
  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 3, dy: 6})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 9, dy: 18})")
}

///|
test "ecs query mut: get_mut mutates erased slot directly" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query1_get_mut_direct",
  )
  let entity = world.spawn()

  try! world.set(entity, comp_position, Position::{ x: 1, y: 2 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  if (try! world.query1(comp_position).get_mut(entity)) is Some(position_mut) {
    position_mut.get_ref().val.x = position_mut.get_ref().val.x + 5
  } else {
    inspect(false, content="true")
  }

  inspect(try! world.get(entity, comp_position), content="Some({x: 6, y: 2})")
}

///|
test "ecs query mut: query2 value with_mut writes back random access updates" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query2_with_mut",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query2_with_mut",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_query2_with_mut",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 2, y: 3 })
  try! world.set(e0, comp_velocity, Velocity::{ dx: 10, dy: 20 })
  try! world.set(e1, comp_position, Position::{ x: 7, y: 8 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 30, dy: 40 })
  try! world.set(e1, comp_accel, Acceleration::{ ax: 1, ay: 1 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query2_value_mut_filtered(
    comp_position,
    comp_velocity,
    Without::new(comp_accel),
  )
  inspect(
    try! query.with_mut(e0, fn(position, velocity_mut) {
      velocity_mut.get_ref().val.dx = velocity_mut.get_ref().val.dx + position.x
    }),
    content="true",
  )
  inspect(
    try! query.with_mut(e1, fn(_position, _velocity_mut) {  }),
    content="false",
  )

  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 12, dy: 20})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 30, dy: 40})")
}

///|
test "ecs query mut: query3 with_mut writes back mixed random access updates" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query3_with_mut",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query3_with_mut",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_query3_with_mut",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, comp_position, Position::{ x: 2, y: 4 })
  try! world.set(e0, comp_velocity, Velocity::{ dx: 10, dy: 20 })
  try! world.set(e0, comp_accel, Acceleration::{ ax: 1, ay: 2 })
  try! world.set(e1, comp_position, Position::{ x: 7, y: 8 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 30, dy: 40 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let value_ref_mut_query = world.query3_value_ref_mut_filtered(
    comp_position,
    comp_velocity,
    comp_accel,
    All::new(),
  )
  inspect(
    try! value_ref_mut_query.with_mut(e0, fn(
      position,
      velocity_ref,
      accel_mut,
    ) {
      accel_mut.get_ref().val.ax = accel_mut.get_ref().val.ax +
        position.x +
        velocity_ref.value().dx
    }),
    content="true",
  )
  inspect(
    try! value_ref_mut_query.with_mut(e1, fn(
      _position,
      _velocity_ref,
      _accel_mut,
    ) {

    }),
    content="false",
  )
  inspect(try! world.get(e0, comp_accel), content="Some({ax: 13, ay: 2})")
  inspect(try! world.get(e1, comp_accel), content="None")

  let ref_mut_optional_query = world.query3_ref_mut_optional_filtered(
    comp_position,
    comp_velocity,
    comp_accel,
    All::new(),
  )
  let saw_missing_optional_ref = Ref::new(false)
  inspect(
    try! ref_mut_optional_query.with_mut(e1, fn(
      position_ref,
      velocity_mut,
      accel_ref,
    ) {
      saw_missing_optional_ref.val = accel_ref is None
      velocity_mut.get_ref().val.dy = velocity_mut.get_ref().val.dy +
        position_ref.value().y
    }),
    content="true",
  )
  inspect(saw_missing_optional_ref.val, content="true")
  inspect(
    try! ref_mut_optional_query.with_mut(world.spawn(), fn(
      _position_ref,
      _velocity_mut,
      _accel_ref,
    ) {

    }),
    content="false",
  )
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 30, dy: 48})")
}

///|
test "ecs query mut: get_unchecked supports transform-style random access" {
  let world = World::new()
  let comp_position : ComponentKey[Position] = register_component(
    debug_name="position_query3_get_unchecked",
  )
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query3_get_unchecked",
  )
  let comp_accel : ComponentKey[Acceleration] = register_component(
    debug_name="accel_query3_get_unchecked",
  )
  let entity = world.spawn()

  try! world.set(entity, comp_position, Position::{ x: 2, y: 4 })
  try! world.set(entity, comp_velocity, Velocity::{ dx: 10, dy: 20 })
  try! world.set(entity, comp_accel, Acceleration::{ ax: 1, ay: 2 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let query = world.query3_ref_mut_optional_filtered(
    comp_position,
    comp_velocity,
    comp_accel,
    All::new(),
  )
  if (try! query.get_unchecked(entity))
    is Some((position_ref, velocity_mut, accel_ref)) {
    inspect(position_ref.value(), content="{x: 2, y: 4}")
    inspect(
      match accel_ref {
        Some(value) => value.value()
        None => Acceleration::{ ax: -1, ay: -1 }
      },
      content="{ax: 1, ay: 2}",
    )
    velocity_mut.get_ref().val.dx = velocity_mut.get_ref().val.dx +
      position_ref.value().x
  } else {
    fail("expected query item for matching entity")
  }

  inspect(
    try! world.get(entity, comp_velocity),
    content="Some({dx: 12, dy: 20})",
  )
}

///|
test "ecs query mut: iter_many_unique_mut rejects duplicates and preserves order" {
  let world = World::new()
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query1_iter_many_unique_mut",
  )
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set(e0, comp_velocity, Velocity::{ dx: 1, dy: 10 })
  try! world.set(e1, comp_velocity, Velocity::{ dx: 2, dy: 20 })

  let ctx = @core.SystemSequenceContext::new()
  ctx.set(@core.SystemSequence::new(0, 1))
  world.set_sequence_context(ctx)

  let duplicate_result : Result[Query1FilteredManyMut[Velocity, All], EcsError] = try? world
    .query1(comp_velocity)
    .iter_many_unique_mut([e1, e1])
  guard duplicate_result is Err(NonUniqueEntityList(entity)) else {
    fail("expected duplicate entity diagnostics")
  }
  inspect(entity.id, content="1")

  let seen : Array[Int] = []
  let iter = try! world.query1(comp_velocity).iter_many_unique_mut([e1, e2, e0])
  while (try! iter.fetch_next()) is Some((entity, velocity_mut)) {
    seen.push(entity.id)
    velocity_mut.get_ref().val.dy = velocity_mut.get_ref().val.dy + entity.id
  }

  inspect(seen, content="[1, 0]")
  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 1, dy: 10})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 2, dy: 21})")
}
