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
struct ComponentAccess[T] {
  contains : (World, @core.Entity) -> Bool
  get : (World, @core.Entity) -> T?
  set : (World, @core.Entity, T) -> Unit
  for_each : (World, (@core.Entity, T) -> Unit) -> Unit
  payload : (World, @core.Entity) -> EcsPayload?
  set_payload : (World, @core.Entity, EcsPayload) -> Bool
  remove_payload : (World, @core.Entity) -> EcsPayload?
}

///|
struct ResourceAccessOps[T] {
  contains : (World) -> Bool
  get : (World) -> T?
  set : (World, T) -> Unit
  remove : (World) -> T?
}

///|
priv struct TypedResourceSlot[T] {
  mut value : T
}

///|
fn[T : EcsPayloadCodec] component_access_new() -> ComponentAccess[T] {
  let stores_by_world : Map[Int, @core.ComponentStore[T]] = {}
  let get_store = fn(world : World) -> @core.ComponentStore[T] {
    match stores_by_world.get(world.world_id) {
      Some(store) => store
      None => {
        let store : @core.ComponentStore[T] = @core.ComponentStore::new()
        stores_by_world.set(world.world_id, store)
        store
      }
    }
  }
  {
    contains: fn(world, entity) { get_store(world).contains(entity) },
    get: fn(world, entity) { get_store(world).get(entity) },
    set: fn(world, entity, value) { get_store(world).upsert(entity, value) },
    for_each: fn(world, visit) { get_store(world).for_each(visit) },
    payload: fn(world, entity) {
      match get_store(world).get(entity) {
        Some(value) => Some(T::to_ecs_payload(value))
        None => None
      }
    },
    set_payload: fn(world, entity, payload) {
      match T::from_ecs_payload(payload) {
        Some(value) => {
          get_store(world).upsert(entity, value)
          true
        }
        None => false
      }
    },
    remove_payload: fn(world, entity) {
      match get_store(world).remove(entity) {
        Some(value) => Some(T::to_ecs_payload(value))
        None => None
      }
    },
  }
}

///|
fn[T] resource_access_ops_new() -> ResourceAccessOps[T] {
  let slots_by_world : Map[Int, TypedResourceSlot[T]] = {}
  {
    contains: fn(world) { slots_by_world.contains(world.world_id) },
    get: fn(world) {
      match slots_by_world.get(world.world_id) {
        Some(slot) => Some(slot.value)
        None => None
      }
    },
    set: fn(world, value) {
      match slots_by_world.get(world.world_id) {
        Some(slot) => slot.value = value
        None => slots_by_world.set(world.world_id, { value, })
      }
    },
    remove: fn(world) {
      match slots_by_world.get(world.world_id) {
        Some(slot) => {
          let value = slot.value
          slots_by_world.remove(world.world_id)
          Some(value)
        }
        None => None
      }
    },
  }
}
