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
test "ecs query mut: iter_many_mut writes back filtered components" {
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

  let ctx = @core.SystemContext::new()
  ctx.set(@core.SystemTicks::new(0, 1))
  world.set_system_context(ctx)

  let iter = world
    .query1_filtered(comp_position, With::new(comp_velocity))
    .iter_many_mut([e0, e1, e2])
  let seen : Array[(Int, Bool, Bool)] = []
  while iter.fetch_next() is Some((entity, component_mut)) {
    seen.push((entity.id, component_mut.is_added(), component_mut.is_changed()))
    component_mut.get_ref().val.x = component_mut.get_ref().val.x + 10
  }

  inspect(seen, content="[(1, true, true), (2, true, true)]")
  inspect(try! world.get(e1, comp_position), content="Some({x: 12, y: 2})")
  inspect(try! world.get(e2, comp_position), content="Some({x: 14, y: 4})")
}

///|
test "ecs query mut: read-only view_mut does not mark components changed" {
  let world = World::new()
  let comp_velocity : ComponentKey[Velocity] = register_component(
    debug_name="velocity_query_mut_read_only",
  )
  let entity = world.spawn()
  let observed_flags : Array[(Bool, Bool)] = []

  try! world.set(entity, comp_velocity, Velocity::{ dx: 1, dy: 2 })
  let ctx1 = @core.SystemContext::new()
  ctx1.set(@core.SystemTicks::new(0, 1))
  world.set_system_context(ctx1)
  try! world
  .query1_filtered(comp_velocity, All::new())
  .view_mut(fn(_entity, component_mut) {
    observed_flags.push((component_mut.is_added(), component_mut.is_changed()))
  })
  inspect(observed_flags, content="[(true, true)]")

  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let ctx2 = @core.SystemContext::new()
  ctx2.set(@core.SystemTicks::new(1, 2))
  world.set_system_context(ctx2)

  inspect(
    world.query1_filtered(comp_velocity, Changed::new(comp_velocity)).count(),
    content="0",
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

  let ctx = @core.SystemContext::new()
  ctx.set(@core.SystemTicks::new(0, 1))
  world.set_system_context(ctx)

  let query = world.query2_ref_mut_filtered(
    comp_position,
    comp_velocity,
    Without::new(comp_accel),
  )
  inspect(query.count(), content="2")

  let iter = query.iter_many_mut([e2, e1, e0])
  let seen : Array[(Int, Bool, Bool)] = []
  while iter.fetch_next() is Some((entity, position_ref, velocity_mut)) {
    seen.push((entity.id, position_ref.is_added(), velocity_mut.is_added()))
    velocity_mut.get_ref().val.dx = velocity_mut.get_ref().val.dx +
      position_ref.value().x
  }

  inspect(seen, content="[(1, true, true), (0, true, true)]")
  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 11, dy: 10})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 22, dy: 30})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 40, dy: 50})")

  try! query
  .par_iter_mut()
  .for_each(fn(_entity, position_ref, velocity_mut) {
    velocity_mut.get_ref().val.dy = velocity_mut.get_ref().val.dy +
      position_ref.value().y
  })

  inspect(try! world.get(e0, comp_velocity), content="Some({dx: 11, dy: 11})")
  inspect(try! world.get(e1, comp_velocity), content="Some({dx: 22, dy: 33})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 40, dy: 50})")
}
