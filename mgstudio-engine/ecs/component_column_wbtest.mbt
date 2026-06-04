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
struct ComponentColumnCacheValue {
  x : Int
} derive(Debug, Eq)

///|
struct ComponentColumnMigrationMarker {
  y : Int
} derive(Debug, Eq)

///|
let component_column_cache_value_key : ComponentKey[ComponentColumnCacheValue] = register_component(
  debug_name="tests.ecs.component_column.cache_value",
)

///|
let component_column_migration_marker_key : ComponentKey[
  ComponentColumnMigrationMarker,
] = register_component(debug_name="tests.ecs.component_column.migration_marker")

///|
pub impl Component for ComponentColumnCacheValue with fn component() {
  component_column_cache_value_key
}

///|
pub impl Component for ComponentColumnMigrationMarker with fn component() {
  component_column_migration_marker_key
}

///|
test "ecs component column: cached table values write through typed storage" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, component_column_cache_value_key, ComponentColumnCacheValue::{
    x: 1,
  })
  guard world.table_id_for_entity(entity) is Some(table_id) else {
    fail("expected table entity")
  }
  guard world.entity_table_row(entity) is Some(table_row) else {
    fail("expected table row")
  }
  guard world.component_column(component_column_cache_value_key)
    is Some(component_column) else {
    fail("expected component column")
  }
  guard component_column.table_values(table_id) is Some(values) else {
    fail("expected table values")
  }
  debug_inspect(values[table_row.index()], content="{ x: 1 }")

  ignore(
    component_column.set_tick_only(entity, ComponentColumnCacheValue::{ x: 2 }),
  )

  let value_opt = try! world.get_by_key(
    entity, component_column_cache_value_key,
  )
  guard value_opt is Some(value) else { fail("expected typed component value") }
  debug_inspect(value, content="{ x: 2 }")
}

///|
test "ecs component column: hot table row value write updates typed storage and change tick" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, component_column_cache_value_key, ComponentColumnCacheValue::{
    x: 5,
  })
  guard world.table_id_for_entity(entity) is Some(table_id) else {
    fail("expected table entity")
  }
  guard world.entity_table_row(entity) is Some(table_row) else {
    fail("expected table row")
  }
  guard world.component_column(component_column_cache_value_key)
    is Some(component_column) else {
    fail("expected component column")
  }
  let tick : @core.Tick = 7
  let wrote = component_column.set_tick_only_hot_at_table_row_value(
    table_id,
    table_row.index(),
    ComponentColumnCacheValue::{ x: 6 },
    tick,
  )
  debug_inspect(wrote, content="true")
  debug_inspect(
    component_column_cache_value_key.component_get_table_row(
      world,
      table_id,
      table_row.index(),
    ),
    content="Some({ x: 6 })",
  )
  guard component_column.table_column(table_id) is Some(table_column) else {
    fail("expected cached table column")
  }
  debug_inspect(
    table_column.is_changed_at_row(
      table_row.index(),
      @core.SystemTicks::new(0, 7),
    ),
    content="true",
  )
}

///|
test "ecs component column: table migration moves canonical typed rows" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, component_column_cache_value_key, ComponentColumnCacheValue::{
    x: 10,
  })
  guard world.table_id_for_entity(entity) is Some(old_table_id) else {
    fail("expected initial table entity")
  }
  guard world.entity_table_row(entity) is Some(old_table_row) else {
    fail("expected initial table row")
  }
  debug_inspect(
    component_column_cache_value_key.component_get_table_row(
      world,
      old_table_id,
      old_table_row.index(),
    ),
    content="Some({ x: 10 })",
  )

  try! world.set_by_key(entity, component_column_migration_marker_key, ComponentColumnMigrationMarker::{
    y: 20,
  })
  guard world.table_id_for_entity(entity) is Some(new_table_id) else {
    fail("expected migrated table entity")
  }
  guard world.entity_table_row(entity) is Some(new_table_row) else {
    fail("expected migrated table row")
  }
  if new_table_id == old_table_id {
    fail("expected adding a table component to migrate to a new table")
  }

  debug_inspect(
    component_column_cache_value_key.component_get_table_row(
      world,
      old_table_id,
      old_table_row.index(),
    ),
    content="None",
  )
  debug_inspect(
    component_column_cache_value_key.component_get_table_row(
      world,
      new_table_id,
      new_table_row.index(),
    ),
    content="Some({ x: 10 })",
  )
  debug_inspect(
    component_column_migration_marker_key.component_get_table_row(
      world,
      new_table_id,
      new_table_row.index(),
    ),
    content="Some({ y: 20 })",
  )
  debug_inspect(
    try! world.get_by_key(entity, component_column_cache_value_key),
    content="Some({ x: 10 })",
  )
}

///|
test "ecs component column: table storage iteration does not retain staged duplicates" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, component_column_cache_value_key, ComponentColumnCacheValue::{
    x: 30,
  })
  try! world.set_by_key(entity, component_column_cache_value_key, ComponentColumnCacheValue::{
    x: 31,
  })
  try! world.set_by_key(entity, component_column_migration_marker_key, ComponentColumnMigrationMarker::{
    y: 32,
  })
  let seen : Array[(Int, Int)] = []
  component_column_cache_value_key.component_for_each(world, fn(
    seen_entity,
    value,
  ) {
    if seen_entity.to_bits() == entity.to_bits() {
      seen.push((seen_entity.id, value.x))
    }
  })
  debug_inspect(seen, content="[(0, 31)]")
}

///|
test "ecs mut query: cached table values write through typed storage" {
  let world = World::new()
  let entity = world.spawn()
  try! world.set_by_key(entity, component_column_cache_value_key, ComponentColumnCacheValue::{
    x: 3,
  })
  guard world.table_id_for_entity(entity) is Some(table_id) else {
    fail("expected table entity")
  }
  guard world.entity_table_row(entity) is Some(table_row) else {
    fail("expected table row")
  }
  guard world.component_column(component_column_cache_value_key)
    is Some(component_column) else {
    fail("expected component column")
  }
  guard component_column.table_values(table_id) is Some(values) else {
    fail("expected table values")
  }
  debug_inspect(values[table_row.index()], content="{ x: 3 }")

  let query : Query[Mut[ComponentColumnCacheValue], All] = query(world)
  try! query.view(fn(_entity, value_mut) {
    value_mut.set(ComponentColumnCacheValue::{ x: 4 })
  })

  let value_opt = try! world.get_by_key(
    entity, component_column_cache_value_key,
  )
  guard value_opt is Some(value) else { fail("expected typed component value") }
  debug_inspect(value, content="{ x: 4 }")
}
