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
  for_each_payload : (World, (@core.Entity, EcsPayload) -> Unit) -> Unit
  payload : (World, @core.Entity) -> EcsPayload?
  set_payload : (World, @core.Entity, EcsPayload) -> Bool
  remove_payload : (World, @core.Entity) -> EcsPayload?
}

///|
let component_ops_registry : @hashmap.HashMap[Int, ComponentOps] = @hashmap.HashMap([],
)

///|
fn[T : EcsPayloadCodec] component_ops_for_key(
  key : ComponentKey[T],
) -> ComponentOps {
  let definition_id = key.id()
  let debug_name = key.debug_name()
  {
    definition_id,
    debug_name,
    contains: key.access.contains,
    for_each_entity: fn(world, visit) {
      (key.access.for_each)(world, fn(entity, _value) { visit(entity) })
    },
    for_each_payload: fn(world, visit) {
      (key.access.for_each)(world, fn(entity, value) {
        visit(entity, T::to_ecs_payload(value))
      })
    },
    payload: key.access.payload,
    set_payload: key.access.set_payload,
    remove_payload: key.access.remove_payload,
  }
}

///|
fn[T : EcsPayloadCodec] register_component_ops(
  component_id : Int,
  key : ComponentKey[T],
) -> Unit {
  if component_ops_registry.get(component_id) is Some(_) {
    return
  }
  component_ops_registry.set(component_id, component_ops_for_key(key))
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
