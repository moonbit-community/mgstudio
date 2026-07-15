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
pub struct EntityRef {
  priv world : World
  priv entity : @core.Entity
}

///|
pub struct EntityMut {
  priv world : World
  priv entity : @core.Entity
}

///|
pub struct Write[T] {
  priv world : World
  priv entity : @core.Entity
  priv key : ComponentKey[T]
  priv table_id : Int
  priv row_index : Int
  priv local_component_id : Int
  priv bound_table_values : Array[T]?
}

///|
pub(open) trait Bundle {
  fn insert_into(
    self : Self,
    world : World,
    entity : @core.Entity,
    loc~ : SourceLoc,
  ) -> Unit raise EcsError
}

///|
fn[T] mut_value_or_abort(item : Write[T]) -> T {
  match item.bound_table_values {
    Some(values) if item.table_id >= 0 && item.row_index >= 0 => {
      if item.row_index >= values.length() {
        abort("Write expected bound table component row")
      }
      return values[item.row_index]
    }
    _ => ()
  }
  match item.world.local_component_storage_type(item.local_component_id) {
    Some(Table) => {
      if item.table_id >= 0 && item.row_index >= 0 {
        return item.world.component_value_by_table_row_unchecked(
          item.key,
          item.local_component_id,
          item.table_id,
          item.row_index,
        )
      }
      guard item.world.component_write_transaction_contains(
        item.entity,
        item.local_component_id,
      ) else {
        abort("Write expected table component location")
      }
      match item.world.component_value_by_key(item.entity, item.key) {
        Some(value) => value
        None => abort("Write expected staged table component value")
      }
    }
    Some(SparseSet) =>
      match item.world.component_value_by_key(item.entity, item.key) {
        Some(value) => value
        None => abort("Write expected sparse component value")
      }
    None => abort("Write expected component storage type")
  }
}

///|
fn[T] mut_write_value_or_abort(item : Write[T], value : T) -> Unit {
  match item.world.local_component_storage_type(item.local_component_id) {
    Some(Table) => {
      if item.table_id >= 0 && item.row_index >= 0 {
        if !item.world.replace_component_value_at_table_row(
            item.key,
            item.local_component_id,
            item.table_id,
            item.row_index,
            value,
          ) {
          abort("Write expected writable table component row")
        }
        return
      }
      guard item.world.component_write_transaction_contains(
        item.entity,
        item.local_component_id,
      ) else {
        abort("Write expected writable table component location")
      }
      if !item.world.replace_component_value_by_key(
          item.entity,
          item.key,
          value,
        ) {
        abort("Write expected writable staged table component value")
      }
    }
    Some(SparseSet) =>
      if !item.world.replace_component_value_by_key(
          item.entity,
          item.key,
          value,
        ) {
        abort("Write expected writable sparse component value")
      }
    None => abort("Write expected component storage type")
  }
}

///|
fn[T] mut_assign_value_or_abort(item : Write[T], value : T) -> Unit {
  mut_write_value_or_abort(item, value)
}

///|
fn[T] mut_mark_changed(item : Write[T], caller? : String? = None) -> Unit {
  let tick = component_write_tick(item.world)
  let recorded = if item.table_id >= 0 && item.row_index >= 0 {
    item.world.record_table_component_changed_at_table_row(
      item.local_component_id,
      item.table_id,
      item.row_index,
      tick,
      caller,
    )
  } else {
    false
  }
  if !recorded {
    item.world.record_component_changed_by_local_id_with_tick(
      item.entity,
      item.local_component_id,
      tick,
      caller,
    )
  }
}

///|
pub fn[T] Write::key(self : Write[T]) -> ComponentKey[T] {
  self.key
}

///|
/// Returns the current component value for read-only use.
///
/// This method does not mark the component as changed. If the returned value
/// contains mutable fields, mutating them directly bypasses ECS change
/// detection. Use `Write::modify` or `Write::set` for writes.
#callsite(autofill(loc))
pub fn[T] Write::peek(self : Write[T], loc~ : SourceLoc) -> T {
  ignore(loc)
  mut_value_or_abort(self)
}

///|
/// Alias for `Write::peek`; it has the same read-only contract.
///
/// Do not mutate the returned value directly if changed ticks, changed
/// messages, filters, or observers should observe the write.
#callsite(autofill(loc))
pub fn[T] Write::value(self : Write[T], loc~ : SourceLoc) -> T {
  self.peek(loc~)
}

///|
pub fn[T] Write::is_added(self : Write[T]) -> Bool {
  self.world.is_added_by_local_id(
    self.entity,
    self.local_component_id,
    self.world.get_tick_context().ticks(),
  )
}

///|
pub fn[T] Write::is_changed(self : Write[T]) -> Bool {
  self.world.is_changed_by_local_id(
    self.entity,
    self.local_component_id,
    self.world.get_tick_context().ticks(),
  )
}

///|
pub fn[T] Write::added(self : Write[T]) -> @core.Tick {
  match
    self.world.added_component_tick_by_local_id(
      self.local_component_id,
      self.entity.id,
    ) {
    Some(tick) => tick
    None => abort("Write::added expected component tick metadata")
  }
}

///|
pub fn[T] Write::last_changed(self : Write[T]) -> @core.Tick {
  match
    self.world.changed_component_tick_by_local_id(
      self.local_component_id,
      self.entity.id,
    ) {
    Some(tick) => tick
    None => abort("Write::last_changed expected component tick metadata")
  }
}

///|
pub fn[T] Write::changed_by(self : Write[T]) -> String? {
  self.world.changed_component_caller_by_local_id(
    self.local_component_id,
    self.entity.id,
  )
}

///|
#callsite(autofill(loc))
pub fn[T : Component] Write::set_changed(
  self : Write[T],
  loc~ : SourceLoc,
) -> Unit {
  ignore(T::component())
  mut_mark_changed(self, caller=hook_caller_from_loc(self.world, loc))
}

///|
#callsite(autofill(loc))
pub fn[T : Component] Write::set_added(
  self : Write[T],
  loc~ : SourceLoc,
) -> Unit {
  ignore(T::component())
  let world = self.world
  let entity = self.entity
  let key_id = self.key.id()
  let caller = hook_caller_from_loc(world, loc)
  world.record_component_added_with_caller(entity, key_id, caller)
  world
  .ensure_added_component_messages(key_id)
  .send(component_write_tick(world), entity)
  world.record_component_changed_with_caller(entity, key_id, caller)
}

///|
/// Runs an in-place mutation closure and marks the component changed.
///
/// Use this when the component value has mutable fields and the write should be
/// visible to ECS change detection. The closure receives the current value; the
/// caller must not keep using values obtained from read-only APIs as a write
/// path.
#callsite(autofill(loc))
pub fn[T, R] Write::modify(
  self : Write[T],
  f : (T) -> R,
  loc~ : SourceLoc,
) -> R {
  let value = self.peek(loc~)
  let result = f(value)
  mut_mark_changed(self, caller=hook_caller_from_loc(self.world, loc))
  result
}

///|
/// Replaces the component through an update closure without marking it changed.
///
/// This is the MoonBit equivalent of Bevy's
/// `DetectChangesMut::bypass_change_detection`. Use it only for internal state
/// changes that must not be observed as a semantic component change. The
/// closure returns the value to store so this works for both reference and
/// value types.
pub fn[T] Write::bypass_change_detection(
  self : Write[T],
  update : (T) -> T,
) -> Unit {
  let value = mut_value_or_abort(self)
  mut_assign_value_or_abort(self, update(value))
}

///|
#callsite(autofill(loc))
pub fn[T : Eq] Write::set_if_neq(
  self : Write[T],
  value : T,
  loc~ : SourceLoc,
) -> Bool {
  let current = self.peek(loc~)
  if current != value {
    self.set(value, loc~)
    true
  } else {
    false
  }
}

///|
/// Replaces the component and marks it changed.
///
/// Prefer `Write::set` over mutating values returned by read-only APIs. This
/// keeps change ticks in sync with the stored value.
#callsite(autofill(loc))
pub fn[T] Write::set(self : Write[T], value : T, loc~ : SourceLoc) -> Unit {
  mut_mark_changed(self, caller=hook_caller_from_loc(self.world, loc))
  mut_assign_value_or_abort(self, value)
}

///|
fn[T] mut_from_component_location(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
  local_component_id : Int,
  table_id : Int,
  row_index : Int,
  bound_table_values? : Array[T]? = None,
) -> Write[T] {
  {
    world,
    entity,
    key,
    table_id,
    row_index,
    local_component_id,
    bound_table_values,
  }
}

///|
fn[T] world_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Write[T]? raise EcsError {
  world.ensure_entity_alive(entity)
  guard world.component_present(key.id(), entity) else { return None }
  guard world.local_component_id(key.id()) is Some(local_component_id) else {
    abort("component is present but has no local component id")
  }
  let (table_id, row_index) = match world.entity_table_location(entity) {
    Some(location) => location
    None => (-1, -1)
  }
  Some(
    mut_from_component_location(
      world, entity, key, local_component_id, table_id, row_index,
    ),
  )
}

///|
fn[T : Component] component_bundle_writer(value : T) -> (Int, ComponentWriter) {
  let key = T::component()
  (key.id(), component_writer_for_key(key, value))
}

///|
pub fn[T] World::contains_by_key(
  self : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool raise EcsError {
  self.ensure_entity_alive(entity)
  entity_has_component_id(self, key.id(), entity)
}

///|
pub fn[T : Component] World::contains(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
) -> Bool raise EcsError {
  self.contains_by_key(entity, key)
}

///|
/// Returns a mutable ECS access handle for an existing component.
///
/// Use this API, rather than `World::get`, when the caller may mutate the
/// component. Mutating values returned by read-only APIs bypasses ECS change
/// detection in MoonBit.
pub fn[T : Component] World::get_mut(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
) -> Write[T]? raise EcsError {
  world_component_mut(self, entity, key)
}

///|
pub fn World::entity(
  self : World,
  entity : @core.Entity,
) -> EntityRef raise EcsError {
  self.ensure_entity_alive(entity)
  { world: self, entity }
}

///|
pub fn World::entity_mut(
  self : World,
  entity : @core.Entity,
) -> EntityMut raise EcsError {
  self.ensure_entity_alive(entity)
  { world: self, entity }
}

///|
pub fn EntityRef::id(self : EntityRef) -> @core.Entity {
  self.entity
}

///|
pub fn[T : Component] EntityRef::contains(
  self : EntityRef,
  key? : ComponentKey[T] = T::component(),
) -> Bool raise EcsError {
  self.world.contains_by_key(self.entity, key)
}

///|
pub fn[T : Component] EntityRef::get(self : EntityRef) -> T? raise EcsError {
  self.world.get_by_key(self.entity, T::component())
}

///|
pub fn[D : QueryData] EntityRef::get_components(
  self : EntityRef,
) -> D? raise EcsError {
  if D::matches(self.world, self.entity) {
    Some(D::fetch(self.world, self.entity))
  } else {
    None
  }
}

///|
pub fn EntityMut::id(self : EntityMut) -> @core.Entity {
  self.entity
}

///|
pub fn[T : Component] EntityMut::contains(
  self : EntityMut,
  key? : ComponentKey[T] = T::component(),
) -> Bool raise EcsError {
  self.world.contains_by_key(self.entity, key)
}

///|
pub fn[T : Component] EntityMut::get(self : EntityMut) -> T? raise EcsError {
  self.world.get_by_key(self.entity, T::component())
}

///|
pub fn[T : Component] EntityMut::get_mut(
  self : EntityMut,
  key? : ComponentKey[T] = T::component(),
) -> Write[T]? raise EcsError {
  world_component_mut(self.world, self.entity, key)
}

///|
pub fn[E : TriggerEvent] EntityMut::observe(
  self : EntityMut,
  observer : (On[E]) -> Unit,
) -> EntityMut {
  ignore(self.world.add_entity_observer(self.entity, observer))
  self
}

///|
pub impl Bundle for Unit with fn insert_into(_self, _world, _entity, loc~) {
  ignore(loc)
  ()
}

///|
pub impl[A : Component, B : Component] Bundle for (A, B) with fn insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b) = self
  let writes : Array[(Int, ComponentWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
  ]
  try! world.insert_component_writes_with_requirements(
    entity,
    writes,
    caller=hook_caller_from_loc(world, loc),
  )
}

///|
pub impl[A : Component, B : Component, C : Component] Bundle for (A, B, C) with fn insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b, c) = self
  let writes : Array[(Int, ComponentWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
  ]
  try! world.insert_component_writes_with_requirements(
    entity,
    writes,
    caller=hook_caller_from_loc(world, loc),
  )
}

///|
pub impl[A : Component, B : Component, C : Component, D : Component] Bundle for (
  A,
  B,
  C,
  D,
) with fn insert_into(self, world, entity, loc~) {
  let (a, b, c, d) = self
  let writes : Array[(Int, ComponentWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
  ]
  try! world.insert_component_writes_with_requirements(
    entity,
    writes,
    caller=hook_caller_from_loc(world, loc),
  )
}

///|
pub impl[
  A : Component,
  B : Component,
  C : Component,
  D : Component,
  E : Component,
] Bundle for (A, B, C, D, E) with fn insert_into(self, world, entity, loc~) {
  let (a, b, c, d, e) = self
  let writes : Array[(Int, ComponentWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
  ]
  try! world.insert_component_writes_with_requirements(
    entity,
    writes,
    caller=hook_caller_from_loc(world, loc),
  )
}

///|
pub impl[
  A : Component,
  B : Component,
  C : Component,
  D : Component,
  E : Component,
  F : Component,
] Bundle for (A, B, C, D, E, F) with fn insert_into(self, world, entity, loc~) {
  let (a, b, c, d, e, f) = self
  let writes : Array[(Int, ComponentWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
    component_bundle_writer(f),
  ]
  try! world.insert_component_writes_with_requirements(
    entity,
    writes,
    caller=hook_caller_from_loc(world, loc),
  )
}

///|
pub impl[
  A : Component,
  B : Component,
  C : Component,
  D : Component,
  E : Component,
  F : Component,
  G : Component,
] Bundle for (A, B, C, D, E, F, G) with fn insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b, c, d, e, f, g) = self
  let writes : Array[(Int, ComponentWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
    component_bundle_writer(f),
    component_bundle_writer(g),
  ]
  try! world.insert_component_writes_with_requirements(
    entity,
    writes,
    caller=hook_caller_from_loc(world, loc),
  )
}

///|
pub impl[
  A : Component,
  B : Component,
  C : Component,
  D : Component,
  E : Component,
  F : Component,
  G : Component,
  H : Component,
] Bundle for (A, B, C, D, E, F, G, H) with fn insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b, c, d, e, f, g, h) = self
  let writes : Array[(Int, ComponentWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
    component_bundle_writer(f),
    component_bundle_writer(g),
    component_bundle_writer(h),
  ]
  try! world.insert_component_writes_with_requirements(
    entity,
    writes,
    caller=hook_caller_from_loc(world, loc),
  )
}

///|
#callsite(autofill(loc))
pub fn[B : Bundle] World::spawn_bundle(
  self : World,
  bundle : B,
  loc~ : SourceLoc,
) -> @core.Entity raise EcsError {
  let entity = self.spawn_empty()
  B::insert_into(bundle, self, entity, loc~)
  entity
}

///|
#callsite(autofill(loc))
pub fn[B : Bundle] EntityMut::insert(
  self : EntityMut,
  bundle : B,
  loc~ : SourceLoc,
) -> EntityMut raise EcsError {
  B::insert_into(bundle, self.world, self.entity, loc~)
  self
}

///|
#callsite(autofill(loc))
pub fn[T : Component] EntityMut::insert_component(
  self : EntityMut,
  component : T,
  loc~ : SourceLoc,
) -> EntityMut raise EcsError {
  self.world.set_by_key(self.entity, T::component(), component, loc~)
  self
}

///|
#callsite(autofill(loc))
pub fn[T : Component] EntityMut::remove_component(
  self : EntityMut,
  loc~ : SourceLoc,
) -> T? raise EcsError {
  self.world.take(self.entity, T::component(), loc~)
}

///|
#callsite(autofill(loc))
pub fn EntityMut::despawn(
  self : EntityMut,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.world.despawn(self.entity, loc~)
}
