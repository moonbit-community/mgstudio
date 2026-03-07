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
pub struct ComponentInsertObserver {
  debug_name : String
  run : (World, @core.Entity) -> Unit
}

///|
let component_insert_observer_registry : @hashmap.HashMap[
  Int,
  Array[ComponentInsertObserver],
] = @hashmap.HashMap::new()

///|
pub fn[T] register_component_insert_observer(
  key : ComponentKey[T],
  debug_name : String,
  observer : (World, @core.Entity) -> Unit,
) -> Bool {
  let observers = component_insert_observer_registry.get_or_init(key.id(), fn() {
    []
  })
  for existing in observers {
    if existing.debug_name == debug_name {
      return false
    }
  }
  observers.push(ComponentInsertObserver::{ debug_name, run: observer })
  true
}

///|
fn component_insert_observers(
  component_id : Int,
) -> Array[ComponentInsertObserver]? {
  component_insert_observer_registry.get(component_id)
}

///|
fn World::run_component_insert_observers(
  self : World,
  entity : @core.Entity,
  component_id : Int,
) -> Unit {
  guard component_insert_observers(component_id) is Some(observers) else {
    return
  }
  for observer in observers {
    (observer.run)(self, entity)
  }
}
