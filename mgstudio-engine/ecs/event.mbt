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
struct EventAccessOps[T] {
  send : (World, T) -> Unit
  read : (World) -> Array[T]
  clear : (World) -> Unit
  advance : (World) -> Unit
  current_trigger : (World) -> T?
  set_current_trigger : (World, T) -> Unit
  clear_current_trigger : (World) -> Unit
}

///|
priv struct EventQueueSlot[T] {
  mut previous : Array[T]
  current : Array[T]
}

///|
priv struct EventOps {
  advance : (World) -> Unit
}

///|
let event_ops_registry : @hashmap.HashMap[Int, EventOps] = HashMap([])

///|
fn[T] event_access_ops_new(event_id : Int) -> EventAccessOps[T] {
  let slots_by_world : Map[Int, EventQueueSlot[T]] = Map([])
  let current_trigger_by_world : Map[Int, T] = Map([])
  let ensure_cleanup = fn(world : World) {
    let world_id = world.world_id()
    world.register_cleanup_once(event_storage_cleanup_key(event_id), fn() {
      slots_by_world.remove(world_id)
      current_trigger_by_world.remove(world_id)
    })
  }
  let slot = fn(world : World) -> EventQueueSlot[T] {
    match slots_by_world.get(world.world_id()) {
      Some(slot) => slot
      None => {
        let slot : EventQueueSlot[T] = { previous: [], current: [] }
        ensure_cleanup(world)
        slots_by_world.set(world.world_id(), slot)
        slot
      }
    }
  }
  let access : EventAccessOps[T] = {
    send: fn(world, event) { slot(world).current.push(event) },
    read: fn(world) {
      let out : Array[T] = []
      let slot = slot(world)
      for event in slot.previous {
        out.push(event)
      }
      for event in slot.current {
        out.push(event)
      }
      out
    },
    clear: fn(world) {
      let slot = slot(world)
      slot.previous.clear()
      slot.current.clear()
    },
    advance: fn(world) {
      let slot = slot(world)
      slot.previous = slot.current.copy()
      slot.current.clear()
    },
    current_trigger: fn(world) {
      current_trigger_by_world.get(world.world_id())
    },
    set_current_trigger: fn(world, event) {
      ensure_cleanup(world)
      current_trigger_by_world.set(world.world_id(), event)
    },
    clear_current_trigger: fn(world) {
      current_trigger_by_world.remove(world.world_id())
    },
  }
  access
}

///|
fn[T] register_event_ops(id : Int, key : EventKey[T]) -> Unit {
  if event_ops_registry.contains(id) {
    return
  }
  event_ops_registry.set(id, { advance: key.access.advance })
}

///|
pub fn[T] World::send_event(self : World, key : EventKey[T], event : T) -> Unit {
  (key.access.send)(self, event)
}

///|
pub fn[T] World::read_events(self : World, key : EventKey[T]) -> Array[T] {
  (key.access.read)(self)
}

///|
pub fn[T] World::clear_events(self : World, key : EventKey[T]) -> Unit {
  (key.access.clear)(self)
}

///|
pub fn World::advance_event_frame(self : World) -> Unit {
  for entry in event_ops_registry.iter() {
    (entry.1.advance)(self)
  }
}
