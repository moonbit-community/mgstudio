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
  x : Int
  y : Int
} derive(Show, Eq, ToJson, FromJson)

///|
struct Velocity {
  dx : Int
  dy : Int
} derive(Show, Eq, ToJson, FromJson)

///|
struct Acceleration {
  ax : Int
  ay : Int
} derive(Show, Eq, ToJson, FromJson)

///|
test "ecs query: query1 for_each and update" {
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
  .for_each(fn(_entity, position) {
    sum_ref.val = sum_ref.val + position.x + position.y
  })
  inspect(sum_ref.val, content="13")

  try! world
  .query1(comp_position)
  .update(fn(_entity, position) {
    Position::{ x: position.x + 10, y: position.y + 20 }
  })

  inspect(try! world.get(e1, comp_position), content="Some({x: 11, y: 22})")
  inspect(try! world.get(e2, comp_position), content="Some({x: 14, y: 26})")
}

///|
test "ecs query: query2 intersection and update" {
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
  .for_each(fn(_entity, p, v) {
    hits_ref.val = hits_ref.val + 1
    sum_ref.val = sum_ref.val + p.x + p.y + v.dx + v.dy
  })
  inspect(hits_ref.val, content="1")
  inspect(sum_ref.val, content="26")

  try! world
  .query2(comp_position, comp_velocity)
  .update(fn(_entity, p, v) {
    (
      Position::{ x: p.x + v.dx, y: p.y + v.dy },
      Velocity::{ dx: v.dx + 1, dy: v.dy + 1 },
    )
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
test "ecs query: query3 smallest-store driven iteration and update" {
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
  .for_each(fn(_entity, p, v, a) {
    hits_ref.val = hits_ref.val + 1
    score_ref.val = score_ref.val + p.x + p.y + v.dx + v.dy + a.ax + a.ay
  })
  inspect(hits_ref.val, content="1")
  inspect(score_ref.val, content="36")

  try! world
  .query3(comp_position, comp_velocity, comp_accel)
  .update(fn(_entity, p, v, a) {
    (
      Position::{ x: p.x + 100, y: p.y + 100 },
      Velocity::{ dx: v.dx + 10, dy: v.dy + 10 },
      Acceleration::{ ax: a.ax + 1, ay: a.ay + 1 },
    )
  })
  inspect(try! world.get(e2, comp_position), content="Some({x: 103, y: 103})")
  inspect(try! world.get(e2, comp_velocity), content="Some({dx: 16, dy: 17})")
  inspect(try! world.get(e2, comp_accel), content="Some({ax: 9, ay: 10})")
  inspect(try! world.get(e1, comp_accel), content="None")
}
