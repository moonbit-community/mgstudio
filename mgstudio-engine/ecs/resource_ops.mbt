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
priv struct ResourceOps {
  contains : (World) -> Bool
  payload : (World) -> EcsPayload?
  set_payload : (World, EcsPayload) -> Bool
  remove_payload : (World) -> EcsPayload?
}

///|
let resource_ops_registry : @hashmap.HashMap[Int, ResourceOps] = @hashmap.HashMap([],
)

///|
fn[T : EcsPayloadCodec] resource_ops_for_key(
  key : ResourceKey[T],
) -> ResourceOps {
  {
    contains: key.access.contains,
    payload: fn(world) {
      match (key.access.get)(world) {
        Some(value) => Some(T::to_ecs_payload(value))
        None => None
      }
    },
    set_payload: fn(world, payload) {
      match T::from_ecs_payload(payload) {
        Some(value) => {
          (key.access.set)(world, value)
          true
        }
        None => false
      }
    },
    remove_payload: fn(world) {
      match (key.access.remove)(world) {
        Some(value) => Some(T::to_ecs_payload(value))
        None => None
      }
    },
  }
}

///|
fn[T : EcsPayloadCodec] register_resource_ops(
  resource_id : Int,
  key : ResourceKey[T],
) -> Unit {
  if resource_ops_registry.get(resource_id) is Some(_) {
    return
  }
  resource_ops_registry.set(resource_id, resource_ops_for_key(key))
}

///|
fn resource_ops(resource_id : Int) -> ResourceOps {
  match resource_ops_registry.get(resource_id) {
    Some(ops) => ops
    None =>
      abort(
        "Missing resource ops for resource definition \{resource_id.to_string()}",
      )
  }
}
