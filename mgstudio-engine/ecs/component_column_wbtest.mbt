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
let component_column_cache_value_key : ComponentKey[ComponentColumnCacheValue] = register_component(
  debug_name="tests.ecs.component_column.cache_value",
)

///|
pub impl Component for ComponentColumnCacheValue with component() {
  component_column_cache_value_key
}

///|
test "ecs component column: cached table values write through raw column" {
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
  guard world.local_component_id(component_column_cache_value_key.id())
    is Some(local_component_id) else {
    fail("expected local component id")
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
    component_column.set_sequence_only(entity, ComponentColumnCacheValue::{
      x: 2,
    }),
  )

  guard world.table_storage(table_id) is Some(table_ref) else {
    fail("expected table storage")
  }
  guard table_ref.val.column(local_component_id) is Some(column_ref) else {
    fail("expected raw table column")
  }
  guard raw_table_value_column_kernel_value(
      column_ref.val.storage,
      table_row.index(),
    )
    is Some(raw_value) else {
    fail("expected raw column value")
  }
  let result : Result[ComponentColumnCacheValue, @any.TypeMismatch] = try? raw_value.to()
  guard result is Ok(value) else { fail("expected raw value type") }
  debug_inspect(value, content="{ x: 2 }")
}

///|
test "ecs mut query: cached table values write through raw column" {
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
  guard world.local_component_id(component_column_cache_value_key.id())
    is Some(local_component_id) else {
    fail("expected local component id")
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

  guard world.table_storage(table_id) is Some(table_ref) else {
    fail("expected table storage")
  }
  guard table_ref.val.column(local_component_id) is Some(column_ref) else {
    fail("expected raw table column")
  }
  guard raw_table_value_column_kernel_value(
      column_ref.val.storage,
      table_row.index(),
    )
    is Some(raw_value) else {
    fail("expected raw column value")
  }
  let result : Result[ComponentColumnCacheValue, @any.TypeMismatch] = try? raw_value.to()
  guard result is Ok(value) else { fail("expected raw value type") }
  debug_inspect(value, content="{ x: 4 }")
}
