// Copyright 2026 International Digital Economy Academy
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
struct TableBatchPosition {
  mut value : Int
} derive(Eq, Debug)

///|
struct TableBatchVelocity {
  value : Int
} derive(Eq, Debug)

///|
struct TableBatchExcluded {}

///|
struct TableBatchFinalized {
  id : Int
} derive(Eq, Debug)

///|
let table_batch_finalized_values : Array[Int] = []

///|
let table_batch_position_key : ComponentKey[TableBatchPosition] = register_component(
  debug_name="ecs.test.TableBatchPosition",
)

///|
let table_batch_velocity_key : ComponentKey[TableBatchVelocity] = register_component(
  debug_name="ecs.test.TableBatchVelocity",
)

///|
let table_batch_excluded_key : ComponentKey[TableBatchExcluded] = register_component(
  debug_name="ecs.test.TableBatchExcluded",
)

///|
let table_batch_finalized_key : ComponentKey[TableBatchFinalized] = register_component(
  debug_name="ecs.test.TableBatchFinalized",
  finalizer=fn(value) { table_batch_finalized_values.push(value.id) },
)

///|
pub impl Component for TableBatchPosition with fn component() {
  table_batch_position_key
}

///|
pub impl Component for TableBatchVelocity with fn component() {
  table_batch_velocity_key
}

///|
pub impl Component for TableBatchExcluded with fn component() {
  table_batch_excluded_key
}

///|
pub impl Component for TableBatchFinalized with fn component() {
  table_batch_finalized_key
}

///|
test "ecs table batch: dense write preserves filters and change detection" {
  let world = World::new()
  defer world.close()
  let changed_entity = try! world.spawn_bundle(
    (TableBatchPosition::{ value: 1 }, TableBatchVelocity::{ value: 10 }),
  )
  let bypassed_entity = try! world.spawn_bundle(
    (TableBatchPosition::{ value: 2 }, TableBatchVelocity::{ value: 20 }),
  )
  let excluded_entity = try! world.spawn_bundle(
    (
      TableBatchPosition::{ value: 3 },
      TableBatchVelocity::{ value: 30 },
      TableBatchExcluded::{  },
    ),
  )
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let query : Query[
    (Write[TableBatchPosition], ReadValue[TableBatchVelocity]),
    Without[TableBatchExcluded],
  ] = query_filtered(world, Without::new(table_batch_excluded_key))

  try! query.for_each_table(fn(batch) {
    let positions = batch.write(table_batch_position_key).unwrap()
    let velocities = batch.read(table_batch_velocity_key).unwrap()
    for row_index in 0..<batch.length() {
      let velocity = velocities.value(row_index).value
      if batch.entity(row_index) == changed_entity {
        positions.modify(row_index, fn(position) { position.value += velocity })
      } else {
        positions.bypass_change_detection(row_index, fn(position) {
          position.value += velocity
          position
        })
      }
    }
  })

  debug_inspect(
    try! world.get_by_key(changed_entity, table_batch_position_key),
    content="Some({ value: 11 })",
  )
  debug_inspect(
    try! world.get_by_key(bypassed_entity, table_batch_position_key),
    content="Some({ value: 22 })",
  )
  debug_inspect(
    try! world.get_by_key(excluded_entity, table_batch_position_key),
    content="Some({ value: 3 })",
  )
  let changed = world
    .changed_components(table_batch_position_key, @core.SystemTicks::new(1, 2))
    .read()
  debug_inspect(changed.contains(changed_entity), content="true")
  debug_inspect(changed.contains(bypassed_entity), content="false")
  debug_inspect(changed.contains(excluded_entity), content="false")
}

///|
test "ecs table batch: writes preserve component replacement finalizers" {
  table_batch_finalized_values.clear()
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_finalized_key, TableBatchFinalized::{
    id: 1,
  })
  let query : Query[Write[TableBatchFinalized], All] = query(world)

  try! query.for_each_table(fn(batch) {
    let values = batch.write(table_batch_finalized_key).unwrap()
    values.set(0, { id: 2 })
    values.bypass_change_detection(0, fn(_value) {
      TableBatchFinalized::{ id: 3 }
    })
  })

  debug_inspect(
    try! world.get_by_key(entity, table_batch_finalized_key),
    content="Some({ id: 3 })",
  )
  debug_inspect(table_batch_finalized_values, content="[1, 2]")
}

///|
test "ecs table batch: filtered rows preserve Changed Added Or semantics" {
  let world = World::new()
  defer world.close()
  let changed_entity = try! world.spawn_bundle(
    (TableBatchPosition::{ value: 1 }, TableBatchVelocity::{ value: 10 }),
  )
  let added_entity = world.spawn()
  try! world.set_by_key(added_entity, table_batch_position_key, TableBatchPosition::{
    value: 2,
  })
  let unchanged_entity = try! world.spawn_bundle(
    (TableBatchPosition::{ value: 3 }, TableBatchVelocity::{ value: 30 }),
  )
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  try! world.set_by_key(changed_entity, table_batch_position_key, TableBatchPosition::{
    value: 11,
  })
  try! world.set_by_key(added_entity, table_batch_velocity_key, TableBatchVelocity::{
    value: 20,
  })
  let tick_context = @core.SystemTickContext::new()
  tick_context.set(@core.SystemTicks::new(1, 2))
  world.set_tick_context(tick_context)
  let query : Query[
    (ReadValue[TableBatchPosition], ReadValue[TableBatchVelocity]),
    Or[(Changed[TableBatchPosition], Added[TableBatchVelocity])],
  ] = query_filtered(
    world,
    Or::new(
      (
        Changed::new(table_batch_position_key),
        Added::new(table_batch_velocity_key),
      ),
    ),
  )
  let seen : Array[@core.Entity] = []

  try! query.for_each_filtered_table(fn(batch, rows) {
    let positions = batch.read(table_batch_position_key).unwrap()
    let velocities = batch.read(table_batch_velocity_key).unwrap()
    try! rows.for_each(fn(row_index) {
      ignore(positions.value(row_index))
      ignore(velocities.value(row_index))
      seen.push(batch.entity(row_index))
    })
  })

  debug_inspect(seen.contains(changed_entity), content="true")
  debug_inspect(seen.contains(added_entity), content="true")
  debug_inspect(seen.contains(unchanged_entity), content="false")
  debug_inspect(seen.length(), content="2")
}
