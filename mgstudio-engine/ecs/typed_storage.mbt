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
  remove : (World, @core.Entity) -> Bool
  take : (World, @core.Entity) -> T?
  for_each : (World, (@core.Entity, T) -> Unit) -> Unit
  get_table_row : (World, Int, Int) -> T?
  get_table_row_unchecked : (World, Int, Int) -> T
  set_table_row : (World, Int, Int, T) -> Unit
  move_table_row : (World, @core.Entity, Int, Int, Int, Int) -> Bool
  move_staged_to_table_row : (World, @core.Entity, Int, Int) -> Bool
  swap_remove_table_row : (World, Int, Int) -> Unit
  table_row_count : (World, Int) -> Int
  finalize_value : (T) -> Unit
}

///|
struct ResourceAccessOps[T] {
  contains : (World) -> Bool
  get : (World) -> T?
  set : (World, T) -> Unit
  remove : (World) -> T?
  drop : (World) -> Bool
  record_added : (World, @core.Tick, String?) -> Unit
  record_changed : (World, @core.Tick, String?) -> Unit
  added_tick : (World) -> @core.Tick?
  changed_tick : (World) -> @core.Tick?
  changed_caller : (World) -> String?
  check_change_ticks : (World, @core.Tick) -> Unit
}

///|
priv struct TypedResourceSlot[T] {
  mut value : T
  mut added_tick : @core.Tick?
  mut changed_tick : @core.Tick?
  mut changed_caller : String?
}

///|
priv struct DenseComponentColumn[T] {
  values : Array[T]
}

///|
priv struct TypedComponentStorage[T] {
  staged_by_entity : @core.ComponentStore[T]
  dense_columns_by_table : Map[Int, DenseComponentColumn[T]]
}

///|
fn[T] typed_component_storage_new() -> TypedComponentStorage[T] {
  {
    staged_by_entity: @core.ComponentStore::new(),
    dense_columns_by_table: Map([]),
  }
}

///|
fn[T] TypedComponentStorage::ensure_dense_column(
  self : TypedComponentStorage[T],
  table_id : Int,
) -> DenseComponentColumn[T] {
  self.dense_columns_by_table.get_or_init(table_id, fn() { { values: [] } })
}

///|
fn[T] TypedComponentStorage::get_table_row(
  self : TypedComponentStorage[T],
  table_id : Int,
  row_index : Int,
) -> T? {
  guard row_index >= 0 else { return None }
  guard self.dense_columns_by_table.get(table_id) is Some(column) else {
    return None
  }
  guard row_index < column.values.length() else { return None }
  Some(column.values[row_index])
}

///|
fn[T] TypedComponentStorage::get_table_row_unchecked(
  self : TypedComponentStorage[T],
  table_id : Int,
  row_index : Int,
) -> T {
  guard self.dense_columns_by_table.get(table_id) is Some(column) else {
    abort("Missing dense component column for a matched table")
  }
  if row_index < 0 || row_index >= column.values.length() {
    abort("Dense component row is out of bounds for a matched table")
  }
  column.values[row_index]
}

///|
fn[T] TypedComponentStorage::set_table_row(
  self : TypedComponentStorage[T],
  table_id : Int,
  row_index : Int,
  value : T,
) -> Unit {
  if row_index < 0 {
    abort("Dense component column row index must be non-negative")
  }
  let column = self.ensure_dense_column(table_id)
  if row_index == column.values.length() {
    column.values.push(value)
  } else if row_index < column.values.length() {
    column.values[row_index] = value
  } else {
    abort(
      "Dense component column cannot initialize row \{row_index.to_string()} after length \{column.values.length().to_string()}",
    )
  }
}

///|
fn[T] TypedComponentStorage::swap_remove_table_row(
  self : TypedComponentStorage[T],
  table_id : Int,
  row_index : Int,
) -> Unit {
  guard self.dense_columns_by_table.get(table_id) is Some(column) else {
    return
  }
  guard row_index >= 0 && row_index < column.values.length() else { return }
  let last_index = column.values.length() - 1
  if row_index != last_index {
    column.values[row_index] = column.values[last_index]
  }
  ignore(column.values.pop())
}

///|
fn[T] component_access_new(
  component_id : Int,
  finalizer? : (T) -> Unit = fn(_value : T) { () },
) -> ComponentAccess[T] {
  let stores_by_world : Map[Int, TypedComponentStorage[T]] = Map([])
  let finalize_world_id = fn(world_id : Int) {
    guard stores_by_world.get(world_id) is Some(store) else { return }
    stores_by_world.remove(world_id)
    store.staged_by_entity.for_each(fn(_entity, value) { finalizer(value) })
    for entry in store.dense_columns_by_table.iter() {
      for value in entry.1.values {
        finalizer(value)
      }
    }
  }
  let get_store = fn(world : World) -> TypedComponentStorage[T] {
    match stores_by_world.get(world.world_id()) {
      Some(store) => store
      None => {
        let store : TypedComponentStorage[T] = typed_component_storage_new()
        let world_id = world.world_id()
        world.register_cleanup_once(
          component_storage_cleanup_key(component_id),
          fn() { finalize_world_id(world_id) },
        )
        stores_by_world.set(world_id, store)
        store
      }
    }
  }
  let table_location = fn(world : World, entity : @core.Entity) -> (Int, Int)? {
    guard world.local_component_id(component_id) is Some(local_component_id) else {
      return None
    }
    guard world.local_component_storage_type(local_component_id) == Some(Table) else {
      return None
    }
    guard world.entity_table_location(entity) is Some((table_id, row_index)) else {
      return None
    }
    guard world.table_has_component_local_id(table_id, local_component_id) else {
      return None
    }
    Some((table_id, row_index))
  }
  {
    contains: fn(world, entity) {
      let store = get_store(world)
      match table_location(world, entity) {
        Some((table_id, row_index)) =>
          store.get_table_row(table_id, row_index) is Some(_)
        None => store.staged_by_entity.contains(entity)
      }
    },
    get: fn(world, entity) {
      let store = get_store(world)
      match table_location(world, entity) {
        Some((table_id, row_index)) => store.get_table_row(table_id, row_index)
        None => store.staged_by_entity.get(entity)
      }
    },
    set: fn(world, entity, value) {
      let store = get_store(world)
      match table_location(world, entity) {
        Some((table_id, row_index)) => {
          match store.staged_by_entity.remove(entity) {
            Some(staged) => finalizer(staged)
            None => ()
          }
          match store.get_table_row(table_id, row_index) {
            Some(previous) => finalizer(previous)
            None => ()
          }
          store.set_table_row(table_id, row_index, value)
        }
        None => {
          match store.staged_by_entity.get(entity) {
            Some(previous) => finalizer(previous)
            None => ()
          }
          store.staged_by_entity.upsert(entity, value)
        }
      }
    },
    remove: fn(world, entity) {
      let store = get_store(world)
      let staged = store.staged_by_entity.remove(entity)
      match table_location(world, entity) {
        Some((table_id, row_index)) => {
          match staged {
            Some(value) => finalizer(value)
            None => ()
          }
          match store.get_table_row(table_id, row_index) {
            Some(value) => {
              // The structural transaction swap-removes this dense row after
              // running removal hooks. Only finalize the discarded value here.
              finalizer(value)
              true
            }
            None => false
          }
        }
        None =>
          match staged {
            Some(value) => {
              finalizer(value)
              true
            }
            None => false
          }
      }
    },
    take: fn(world, entity) {
      let store = get_store(world)
      let staged = store.staged_by_entity.remove(entity)
      match table_location(world, entity) {
        Some((table_id, row_index)) => {
          match staged {
            Some(value) => finalizer(value)
            None => ()
          }
          // The caller receives ownership. The structural transaction only
          // forgets the source row and must not run the component finalizer.
          store.get_table_row(table_id, row_index)
        }
        None => staged
      }
    },
    for_each: fn(world, visit) {
      let store = get_store(world)
      for table_entry in store.dense_columns_by_table.iter() {
        let table_id = table_entry.0
        let values = table_entry.1.values
        guard world.table_entities_view(table_id) is Some(entities) else {
          continue
        }
        for row_index in 0..<values.length() {
          guard row_index < entities.length() else { continue }
          visit(entities[row_index], values[row_index])
        }
      }
      store.staged_by_entity.for_each(visit)
    },
    get_table_row: fn(world, table_id, row_index) {
      get_store(world).get_table_row(table_id, row_index)
    },
    get_table_row_unchecked: fn(world, table_id, row_index) {
      get_store(world).get_table_row_unchecked(table_id, row_index)
    },
    set_table_row: fn(world, table_id, row_index, value) {
      let store = get_store(world)
      match store.get_table_row(table_id, row_index) {
        Some(previous) => finalizer(previous)
        None => ()
      }
      store.set_table_row(table_id, row_index, value)
    },
    move_table_row: fn(
      world,
      entity,
      source_table_id,
      source_row_index,
      target_table_id,
      target_row_index,
    ) {
      let store = get_store(world)
      ignore(store.staged_by_entity.remove(entity))
      match store.get_table_row(source_table_id, source_row_index) {
        Some(value) => {
          // This is the GC-language equivalent of Bevy's owning row move. The
          // enclosing table migration immediately swap-removes the source row
          // without finalizing it, so ownership is transferred exactly once.
          store.set_table_row(target_table_id, target_row_index, value)
          true
        }
        None => false
      }
    },
    move_staged_to_table_row: fn(world, entity, table_id, row_index) {
      let store = get_store(world)
      match store.staged_by_entity.remove(entity) {
        Some(value) => {
          store.set_table_row(table_id, row_index, value)
          true
        }
        None => false
      }
    },
    swap_remove_table_row: fn(world, table_id, row_index) {
      get_store(world).swap_remove_table_row(table_id, row_index)
    },
    table_row_count: fn(world, table_id) {
      match get_store(world).dense_columns_by_table.get(table_id) {
        Some(column) => column.values.length()
        None => 0
      }
    },
    finalize_value: finalizer,
  }
}

///|
fn[T] ComponentKey::component_contains(
  self : ComponentKey[T],
  world : World,
  entity : @core.Entity,
) -> Bool {
  (self.access.contains)(world, entity)
}

///|
fn[T] ComponentKey::component_get(
  self : ComponentKey[T],
  world : World,
  entity : @core.Entity,
) -> T? {
  (self.access.get)(world, entity)
}

///|
fn[T] ComponentKey::component_set(
  self : ComponentKey[T],
  world : World,
  entity : @core.Entity,
  value : T,
) -> Unit {
  (self.access.set)(world, entity, value)
}

///|
fn[T] ComponentKey::component_remove(
  self : ComponentKey[T],
  world : World,
  entity : @core.Entity,
) -> Bool {
  (self.access.remove)(world, entity)
}

///|
fn[T] ComponentKey::component_take(
  self : ComponentKey[T],
  world : World,
  entity : @core.Entity,
) -> T? {
  (self.access.take)(world, entity)
}

///|
fn[T] ComponentKey::component_for_each(
  self : ComponentKey[T],
  world : World,
  visit : (@core.Entity, T) -> Unit,
) -> Unit {
  (self.access.for_each)(world, visit)
}

///|
fn[T] ComponentKey::component_get_table_row(
  self : ComponentKey[T],
  world : World,
  table_id : Int,
  row_index : Int,
) -> T? {
  (self.access.get_table_row)(world, table_id, row_index)
}

///|
fn[T] ComponentKey::component_get_table_row_unchecked(
  self : ComponentKey[T],
  world : World,
  table_id : Int,
  row_index : Int,
) -> T {
  (self.access.get_table_row_unchecked)(world, table_id, row_index)
}

///|
fn[T] ComponentKey::component_set_table_row(
  self : ComponentKey[T],
  world : World,
  table_id : Int,
  row_index : Int,
  value : T,
) -> Unit {
  (self.access.set_table_row)(world, table_id, row_index, value)
}

///|
fn[T] ComponentKey::component_move_table_row(
  self : ComponentKey[T],
  world : World,
  entity : @core.Entity,
  source_table_id : Int,
  source_row_index : Int,
  target_table_id : Int,
  target_row_index : Int,
) -> Bool {
  (self.access.move_table_row)(
    world, entity, source_table_id, source_row_index, target_table_id, target_row_index,
  )
}

///|
fn[T] ComponentKey::component_move_staged_to_table_row(
  self : ComponentKey[T],
  world : World,
  entity : @core.Entity,
  table_id : Int,
  row_index : Int,
) -> Bool {
  (self.access.move_staged_to_table_row)(world, entity, table_id, row_index)
}

///|
fn[T] ComponentKey::component_swap_remove_table_row(
  self : ComponentKey[T],
  world : World,
  table_id : Int,
  row_index : Int,
) -> Unit {
  (self.access.swap_remove_table_row)(world, table_id, row_index)
}

///|
fn[T] ComponentKey::component_table_row_count(
  self : ComponentKey[T],
  world : World,
  table_id : Int,
) -> Int {
  (self.access.table_row_count)(world, table_id)
}

///|
fn[T] ComponentKey::component_finalize_value(
  self : ComponentKey[T],
  value : T,
) -> Unit {
  (self.access.finalize_value)(value)
}

///|
fn[T] resource_access_ops_new(
  resource_id : Int,
  finalizer? : (T) -> Unit = fn(_value : T) { () },
) -> ResourceAccessOps[T] {
  let slots_by_world : Map[Int, TypedResourceSlot[T]] = Map([])
  let drop_world_id = fn(world_id : Int) -> Bool {
    guard slots_by_world.get(world_id) is Some(slot) else { return false }
    slots_by_world.remove(world_id)
    finalizer(slot.value)
    true
  }
  {
    contains: fn(world) { slots_by_world.contains(world.world_id()) },
    get: fn(world) {
      match slots_by_world.get(world.world_id()) {
        Some(slot) => Some(slot.value)
        None => None
      }
    },
    set: fn(world, value) {
      match slots_by_world.get(world.world_id()) {
        Some(slot) => {
          finalizer(slot.value)
          slot.value = value
        }
        None => {
          let world_id = world.world_id()
          world.register_cleanup_once(
            resource_storage_cleanup_key(resource_id),
            fn() { drop_world_id(world_id) |> ignore },
          )
          slots_by_world.set(world_id, {
            value,
            added_tick: None,
            changed_tick: None,
            changed_caller: None,
          })
        }
      }
    },
    remove: fn(world) {
      match slots_by_world.get(world.world_id()) {
        Some(slot) => {
          let value = slot.value
          slots_by_world.remove(world.world_id())
          Some(value)
        }
        None => None
      }
    },
    drop: fn(world) { drop_world_id(world.world_id()) },
    record_added: fn(world, tick, caller) {
      guard slots_by_world.get(world.world_id()) is Some(slot) else { return }
      slot.added_tick = Some(tick)
      if slot.changed_tick is None {
        slot.changed_tick = Some(tick)
      }
      slot.changed_caller = caller
    },
    record_changed: fn(world, tick, caller) {
      guard slots_by_world.get(world.world_id()) is Some(slot) else { return }
      slot.changed_tick = Some(tick)
      slot.changed_caller = caller
    },
    added_tick: fn(world) {
      match slots_by_world.get(world.world_id()) {
        Some(slot) => slot.added_tick
        None => None
      }
    },
    changed_tick: fn(world) {
      match slots_by_world.get(world.world_id()) {
        Some(slot) => slot.changed_tick
        None => None
      }
    },
    changed_caller: fn(world) {
      match slots_by_world.get(world.world_id()) {
        Some(slot) => slot.changed_caller
        None => None
      }
    },
    check_change_ticks: fn(world, present_tick) {
      guard slots_by_world.get(world.world_id()) is Some(slot) else { return }
      slot.added_tick = match slot.added_tick {
        Some(tick) => Some(@core.tick_check(tick, present_tick))
        None => None
      }
      slot.changed_tick = match slot.changed_tick {
        Some(tick) => Some(@core.tick_check(tick, present_tick))
        None => None
      }
    },
  }
}

///|
fn[T] ResourceKey::resource_contains(
  self : ResourceKey[T],
  world : World,
) -> Bool {
  (self.access.contains)(world)
}

///|
fn[T] ResourceKey::resource_get(self : ResourceKey[T], world : World) -> T? {
  (self.access.get)(world)
}

///|
fn[T] ResourceKey::resource_set(
  self : ResourceKey[T],
  world : World,
  value : T,
) -> Unit {
  (self.access.set)(world, value)
}

///|
fn[T] ResourceKey::resource_remove(self : ResourceKey[T], world : World) -> T? {
  (self.access.remove)(world)
}

///|
fn[T] ResourceKey::resource_drop(self : ResourceKey[T], world : World) -> Bool {
  (self.access.drop)(world)
}

///|
fn[T] ResourceKey::resource_record_added(
  self : ResourceKey[T],
  world : World,
  tick : @core.Tick,
  caller : String?,
) -> Unit {
  (self.access.record_added)(world, tick, caller)
}

///|
fn[T] ResourceKey::resource_record_changed(
  self : ResourceKey[T],
  world : World,
  tick : @core.Tick,
  caller : String?,
) -> Unit {
  (self.access.record_changed)(world, tick, caller)
}

///|
fn[T] ResourceKey::resource_added_tick(
  self : ResourceKey[T],
  world : World,
) -> @core.Tick? {
  (self.access.added_tick)(world)
}

///|
fn[T] ResourceKey::resource_changed_tick(
  self : ResourceKey[T],
  world : World,
) -> @core.Tick? {
  (self.access.changed_tick)(world)
}

///|
fn[T] ResourceKey::resource_changed_caller(
  self : ResourceKey[T],
  world : World,
) -> String? {
  (self.access.changed_caller)(world)
}

///|
fn[T] ResourceKey::resource_check_change_ticks(
  self : ResourceKey[T],
  world : World,
  present_tick : @core.Tick,
) -> Unit {
  (self.access.check_change_ticks)(world, present_tick)
}
