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
#valtype
struct TableBatchValuePosition {
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
let table_batch_value_position_key : ComponentKey[TableBatchValuePosition] = register_component(
  debug_name="ecs.test.TableBatchValuePosition",
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
pub impl Component for TableBatchValuePosition with fn component() {
  table_batch_value_position_key
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
test "ecs table batch: bound change writer marks only selected rows" {
  let world = World::new(track_change_locations=true)
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()
  try! world.set_by_key(first, table_batch_position_key, TableBatchPosition::{
    value: 1,
  })
  try! world.set_by_key(second, table_batch_position_key, TableBatchPosition::{
    value: 2,
  })
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let write_query : Query[Write[TableBatchPosition], All] = query(world)

  try! write_query.for_each_table(fn(batch) {
    let positions = batch.write(table_batch_position_key).unwrap()
    positions.with_change_writer(fn(changes) {
      for row_index in 0..<batch.length() {
        if batch.entity(row_index) == first {
          positions.peek(row_index).value += 10
          changes.set_changed(row_index)
        }
      }
    })
  })

  let changed = world
    .changed_components(table_batch_position_key, @core.SystemTicks::new(1, 2))
    .read()
  debug_inspect(changed.contains(first), content="true")
  debug_inspect(changed.contains(second), content="false")
  let read_query : Query[Read[TableBatchPosition], All] = query(world)
  let first_value = (try! read_query.get(first)).unwrap()
  debug_inspect(first_value.value(), content="{ value: 11 }")
  debug_inspect(first_value.changed_by() is Some(_), content="true")
}

///|
test "panic ecs table batch: escaped change writer is invalid" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_position_key, TableBatchPosition::{
    value: 1,
  })
  let query : Query[Write[TableBatchPosition], All] = query(world)
  let mut escaped : TableBatchChangeWriter? = None

  try! query.for_each_table(fn(batch) {
    batch
    .write(table_batch_position_key)
    .unwrap()
    .with_change_writer(fn(changes) { escaped = Some(changes) })
  })
  escaped.unwrap().set_changed(0)
}

///|
test "ecs table batch: read view exposes complete live column" {
  let world = World::new()
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()
  try! world.set_by_key(first, table_batch_velocity_key, TableBatchVelocity::{
    value: 10,
  })
  try! world.set_by_key(second, table_batch_velocity_key, TableBatchVelocity::{
    value: 20,
  })
  let query : Query[ReadValue[TableBatchVelocity], All] = query(world)
  let seen : Array[Int] = []

  try! query.for_each_table(fn(batch) {
    batch.read(table_batch_velocity_key).unwrap().with_values(fn(values) {
      for value in values {
        seen.push(value.value)
      }
    })
  })

  debug_inspect(seen, content="[10, 20]")
}

///|
test "ecs table batch: entity view exposes complete live table" {
  let world = World::new()
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()
  try! world.set_by_key(first, table_batch_velocity_key, TableBatchVelocity::{
    value: 10,
  })
  try! world.set_by_key(second, table_batch_velocity_key, TableBatchVelocity::{
    value: 20,
  })
  let query : Query[ReadValue[TableBatchVelocity], All] = query(world)
  let seen : Array[Int] = []

  try! query.for_each_table(fn(batch) {
    batch.with_entities(fn(entities) {
      for entity in entities {
        seen.push(entity.id)
      }
    })
  })

  debug_inspect(seen, content="[0, 1]")
}

///|
test "ecs table batch: update_inplace replaces value components and marks changed" {
  let world = World::new()
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()
  try! world.set_by_key(first, table_batch_value_position_key, TableBatchValuePosition::{
    value: 1,
  })
  try! world.set_by_key(second, table_batch_value_position_key, TableBatchValuePosition::{
    value: 2,
  })
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let query : Query[Write[TableBatchValuePosition], All] = query(world)

  try! query.for_each_table(fn(batch) {
    let positions = batch.write(table_batch_value_position_key).unwrap()
    positions.update_inplace(fn(values) {
      for row_index in 0..<values.length() {
        values[row_index] = TableBatchValuePosition::{
          value: values[row_index].value + 10,
        }
      }
    })
  })

  debug_inspect(
    try! world.get_by_key(first, table_batch_value_position_key),
    content="Some({ value: 11 })",
  )
  debug_inspect(
    try! world.get_by_key(second, table_batch_value_position_key),
    content="Some({ value: 12 })",
  )
  let changed = world
    .changed_components(
      table_batch_value_position_key,
      @core.SystemTicks::new(1, 2),
    )
    .read()
  debug_inspect(changed.contains(first), content="true")
  debug_inspect(changed.contains(second), content="true")
}

///|
test "ecs table batch: update_inplace bypass preserves change ticks" {
  let world = World::new()
  defer world.close()
  let first = world.spawn()
  let second = world.spawn()
  try! world.set_by_key(first, table_batch_value_position_key, TableBatchValuePosition::{
    value: 1,
  })
  try! world.set_by_key(second, table_batch_value_position_key, TableBatchValuePosition::{
    value: 2,
  })
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  let query : Query[Write[TableBatchValuePosition], All] = query(world)

  try! query.for_each_table(fn(batch) {
    let positions = batch.write(table_batch_value_position_key).unwrap()
    positions.update_inplace_bypass_change_detection(fn(values) {
      for row_index in 0..<values.length() {
        values[row_index] = TableBatchValuePosition::{
          value: values[row_index].value + 10,
        }
      }
    })
  })

  debug_inspect(
    try! world.get_by_key(first, table_batch_value_position_key),
    content="Some({ value: 11 })",
  )
  debug_inspect(
    try! world.get_by_key(second, table_batch_value_position_key),
    content="Some({ value: 12 })",
  )
  let changed = world
    .changed_components(
      table_batch_value_position_key,
      @core.SystemTicks::new(1, 2),
    )
    .read()
  debug_inspect(changed.contains(first), content="false")
  debug_inspect(changed.contains(second), content="false")
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
test "panic ecs table batch: update_inplace rejects custom finalizers" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_finalized_key, TableBatchFinalized::{
    id: 1,
  })
  let query : Query[Write[TableBatchFinalized], All] = query(world)

  try! query.for_each_table(fn(batch) {
    let values = batch.write(table_batch_finalized_key).unwrap()
    values.update_inplace(fn(_items) { () })
  })
}

///|
test "panic ecs table batch: update_inplace rejects filtered row batches" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_position_key, TableBatchPosition::{
    value: 1,
  })
  let query : Query[Write[TableBatchPosition], Changed[TableBatchPosition]] = query_filtered(
    world,
    Changed::new(table_batch_position_key),
  )

  ignore(
    try! query.try_for_each_filtered_table(fn(batch, _rows) {
      let values = batch.write(table_batch_position_key).unwrap()
      values.update_inplace(fn(_items) { () })
    }),
  )
}

///|
test "panic ecs table batch: read view rejects filtered row batches" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_velocity_key, TableBatchVelocity::{
    value: 10,
  })
  let query : Query[ReadValue[TableBatchVelocity], Changed[TableBatchVelocity]] = query_filtered(
    world,
    Changed::new(table_batch_velocity_key),
  )

  ignore(
    try! query.try_for_each_filtered_table(fn(batch, _rows) {
      batch.read(table_batch_velocity_key).unwrap().with_values(fn(_values) {
        ()
      })
    }),
  )
}

///|
test "panic ecs table batch: entity view rejects filtered row batches" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_velocity_key, TableBatchVelocity::{
    value: 10,
  })
  let query : Query[ReadValue[TableBatchVelocity], Changed[TableBatchVelocity]] = query_filtered(
    world,
    Changed::new(table_batch_velocity_key),
  )

  ignore(
    try! query.try_for_each_filtered_table(fn(batch, _rows) {
      batch.with_entities(fn(_entities) { () })
    }),
  )
}

///|
test "panic ecs table batch: update_inplace bypass rejects custom finalizers" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_finalized_key, TableBatchFinalized::{
    id: 1,
  })
  let query : Query[Write[TableBatchFinalized], All] = query(world)

  try! query.for_each_table(fn(batch) {
    let values = batch.write(table_batch_finalized_key).unwrap()
    values.update_inplace_bypass_change_detection(fn(_items) { () })
  })
}

///|
test "panic ecs table batch: update_inplace bypass rejects filtered row batches" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_position_key, TableBatchPosition::{
    value: 1,
  })
  let query : Query[Write[TableBatchPosition], Changed[TableBatchPosition]] = query_filtered(
    world,
    Changed::new(table_batch_position_key),
  )

  ignore(
    try! query.try_for_each_filtered_table(fn(batch, _rows) {
      let values = batch.write(table_batch_position_key).unwrap()
      values.update_inplace_bypass_change_detection(fn(_items) { () })
    }),
  )
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
    (Write[TableBatchPosition], ReadValue[TableBatchVelocity]),
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

  let used_batch = try! query.try_for_each_filtered_table(fn(batch, rows) {
    let positions = batch.write(table_batch_position_key).unwrap()
    let velocities = batch.read(table_batch_velocity_key).unwrap()
    rows.with_write_values(positions, fn(position_values) {
      rows.with_read_values(velocities, fn(velocity_values) {
        try! rows.for_each(fn(row_index) {
          ignore(position_values[row_index])
          ignore(velocity_values[row_index])
          seen.push(batch.entity(row_index))
        })
      })
    })
  })

  debug_inspect(used_batch, content="true")
  debug_inspect(seen.contains(changed_entity), content="true")
  debug_inspect(seen.contains(added_entity), content="true")
  debug_inspect(seen.contains(unchanged_entity), content="false")
  debug_inspect(seen.length(), content="2")
}

///|
test "ecs table batch: unavailable dense filter preserves row fallback" {
  let world = World::new()
  defer world.close()
  let entity = world.spawn()
  try! world.set_by_key(entity, table_batch_position_key, TableBatchPosition::{
    value: 1,
  })
  world.increment_change_tick() |> ignore
  world.increment_change_tick() |> ignore
  try! world.set_by_key(entity, table_batch_position_key, TableBatchPosition::{
    value: 2,
  })
  let tick_context = @core.SystemTickContext::new()
  tick_context.set(@core.SystemTicks::new(1, 2))
  world.set_tick_context(tick_context)
  let query : Query[
    @core.Entity,
    Or[(Changed[TableBatchPosition], Changed[TableBatchExcluded])],
  ] = query_filtered(
    world,
    Or::new(
      (
        Changed::new(table_batch_position_key),
        Changed::new(table_batch_excluded_key),
      ),
    ),
  )
  let seen : Array[@core.Entity] = []
  let mut callback_invoked = false

  let used_batch = try! query.try_for_each_filtered_table(fn(_batch, _rows) {
    callback_invoked = true
  })
  if !used_batch {
    try! query.for_each(fn(_entity, value) { seen.push(value) })
  }

  debug_inspect(used_batch, content="false")
  debug_inspect(callback_invoked, content="false")
  debug_inspect(seen, content="[{ id: 0, generation: 1 }]")
}
