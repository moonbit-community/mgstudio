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
struct ComponentOps {
  definition_id : Int
  debug_name : String
  contains : (World, @core.Entity) -> Bool
  for_each_entity : (World, (@core.Entity) -> Unit) -> Unit
  remove : (World, @core.Entity) -> Bool
  move_table_row_and_swap_remove : (World, @core.Entity, Int, Int, Int, Int) -> Bool
  move_staged_to_table_row : (World, @core.Entity, Int, Int) -> Bool
  swap_remove_table_row : (World, Int, Int) -> Unit
  table_row_count : (World, Int) -> Int
}

///|
let component_ops_registry : @hashmap.HashMap[Int, ComponentOps] = @hashmap.HashMap([],
)

///|
fn[T] component_ops_for_key(key : ComponentKey[T]) -> ComponentOps {
  let definition_id = key.id()
  let debug_name = key.debug_name()
  {
    definition_id,
    debug_name,
    contains: fn(world, entity) { key.component_contains(world, entity) },
    for_each_entity: fn(world, visit) {
      key.component_for_each(world, fn(entity, _value) { visit(entity) })
    },
    remove: fn(world, entity) { key.component_remove(world, entity) },
    move_table_row_and_swap_remove: fn(
      world,
      entity,
      source_table_id,
      source_row_index,
      target_table_id,
      target_row_index,
    ) {
      key.component_move_table_row_and_swap_remove(
        world, entity, source_table_id, source_row_index, target_table_id, target_row_index,
      )
    },
    move_staged_to_table_row: fn(world, entity, table_id, row_index) {
      key.component_move_staged_to_table_row(world, entity, table_id, row_index)
    },
    swap_remove_table_row: fn(world, table_id, row_index) {
      key.component_swap_remove_table_row(world, table_id, row_index)
    },
    table_row_count: fn(world, table_id) {
      key.component_table_row_count(world, table_id)
    },
  }
}

///|
fn[T] register_component_ops(component_id : Int, key : ComponentKey[T]) -> Unit {
  if component_ops_registry.get(component_id) is Some(_) {
    return
  }
  component_ops_registry.set(component_id, component_ops_for_key(key))
}

///|
fn[T] ensure_component_ops_for_key(key : ComponentKey[T]) -> Unit {
  register_component_ops(key.id(), key)
}

///|
fn component_ops(component_id : Int) -> ComponentOps {
  match component_ops_registry.get(component_id) {
    Some(ops) => ops
    None =>
      abort(
        "Missing component ops for component definition \{component_id.to_string()}",
      )
  }
}
