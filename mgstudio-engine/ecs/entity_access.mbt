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
pub struct Mut[T] {
  priv world : World?
  priv entity : @core.Entity?
  priv key : ComponentKey[T]?
  priv table_id : Int?
  priv row_index : Int?
  priv local_component_id : Int?
}

///|
/// Types that opt in to whole-value assignment through `Mut::set`.
///
/// ECS mutation should prefer `Mut::modify`, which mutates the stored component
/// in place. Implement this trait only when a component has a well-defined
/// assignment from a replacement value. The default implementation replaces the
/// provided storage reference; types that need custom in-place assignment can
/// override it.
pub(open) trait Mutable {
  set(Self, Ref[Self]) -> Unit = _
}

///|
impl Mutable with set(self, value) {
  value.val = self
}

///|
pub(open) trait Bundle {
  insert_into(
    self : Self,
    world : World,
    entity : @core.Entity,
    loc~ : SourceLoc,
  ) -> Unit raise EcsError
}

///|
fn[T] mut_world_or_abort(item : Mut[T]) -> World {
  match item.world {
    Some(world) => world
    None => abort("Mut expected a fetched query item")
  }
}

///|
fn[T] mut_entity_or_abort(item : Mut[T]) -> @core.Entity {
  match item.entity {
    Some(entity) => entity
    None => abort("Mut expected a fetched query item")
  }
}

///|
fn[T] mut_key_id_or_abort(item : Mut[T]) -> Int {
  match item.key {
    Some(key) => key.id()
    None => abort("Mut expected a fetched query item")
  }
}

///|
fn[T] mut_local_component_id_or_abort(item : Mut[T]) -> Int {
  match item.local_component_id {
    Some(local_component_id) => local_component_id
    None => abort("Mut expected a fetched query item")
  }
}

///|
fn[T] mut_key_or_abort(item : Mut[T]) -> ComponentKey[T] {
  match item.key {
    Some(key) => key
    None => abort("Mut expected a fetched query item")
  }
}

///|
fn[T : EcsPayloadCodec] mut_value_or_abort(item : Mut[T]) -> T {
  let world = mut_world_or_abort(item)
  let key = mut_key_or_abort(item)
  match (item.table_id, item.row_index, item.local_component_id) {
    (Some(table_id), Some(row_index), Some(local_component_id)) =>
      match
        world.component_value_by_table_row_fast(
          local_component_id, table_id, row_index,
        ) {
        Some(value) => return value
        None => ()
      }
    _ => ()
  }
  let entity = mut_entity_or_abort(item)
  let result : Result[T?, EcsError] = try? world.component_value_by_key(
    entity, key,
  )
  match result {
    Ok(Some(value)) => value
    Ok(None) => abort("Mut expected a fetched query item")
    _ => abort("Mut expected a fetched query item")
  }
}

///|
fn[T : EcsPayloadCodec] mut_write_value_or_abort(
  item : Mut[T],
  value : T,
) -> Unit {
  let world = mut_world_or_abort(item)
  let key = mut_key_or_abort(item)
  match (item.table_id, item.row_index, item.local_component_id) {
    (Some(table_id), Some(row_index), Some(local_component_id)) =>
      if world.replace_component_value_at_table_row(
          key, local_component_id, table_id, row_index, value,
        ) {
        return
      }
    _ => ()
  }
  let entity = mut_entity_or_abort(item)
  if !world.replace_component_value_by_key(entity, key, value) {
    abort("Mut expected a fetched query item")
  }
}

///|
fn[T : EcsPayloadCodec + Mutable] mut_assign_value_or_abort(
  item : Mut[T],
  value : T,
) -> Unit {
  let current = Ref(mut_value_or_abort(item))
  Mutable::set(value, current)
  mut_write_value_or_abort(item, current.val)
}

///|
fn[T] mut_mark_changed(item : Mut[T], caller? : String? = None) -> Unit {
  guard item.world is Some(world) else { return }
  guard item.entity is Some(entity) else { return }
  match item.local_component_id {
    Some(local_component_id) => {
      let tick = component_write_tick(world)
      let recorded = match (item.table_id, item.row_index) {
        (Some(table_id), Some(row_index)) =>
          world.record_table_component_changed_at_table_row(
            local_component_id, table_id, row_index, tick, caller,
          )
        _ => false
      }
      if !recorded {
        world.record_component_changed_by_local_id_with_tick(
          entity, local_component_id, tick, caller,
        )
      }
      world.ensure_changed_component_messages_by_local_id(local_component_id).val.send(
        tick, entity,
      )
    }
    None =>
      if item.key is Some(key) {
        world.record_component_changed_with_caller(entity, key.id(), caller)
      }
  }
}

///|
pub fn[T] Mut::new(key : ComponentKey[T]) -> Mut[T] {
  ignore(key)
  {
    world: None,
    entity: None,
    key: None,
    table_id: None,
    row_index: None,
    local_component_id: None,
  }
}

///|
pub fn[T : Component] Mut::key(self : Mut[T]) -> ComponentKey[T] {
  ignore(self)
  Component::component()
}

///|
pub fn[T : EcsPayloadCodec] Mut::peek(self : Mut[T]) -> T {
  mut_value_or_abort(self)
}

///|
pub fn[T : EcsPayloadCodec] Mut::value(self : Mut[T]) -> T {
  self.peek()
}

///|
pub fn[T] Mut::is_added(self : Mut[T]) -> Bool {
  let world = mut_world_or_abort(self)
  world.is_added_by_local_id(
    mut_entity_or_abort(self),
    mut_local_component_id_or_abort(self),
    world.get_tick_context().ticks(),
  )
}

///|
pub fn[T] Mut::is_changed(self : Mut[T]) -> Bool {
  let world = mut_world_or_abort(self)
  world.is_changed_by_local_id(
    mut_entity_or_abort(self),
    mut_local_component_id_or_abort(self),
    world.get_tick_context().ticks(),
  )
}

///|
pub fn[T] Mut::added(self : Mut[T]) -> @core.Tick {
  let world = mut_world_or_abort(self)
  match
    world.added_component_tick_by_local_id(
      mut_local_component_id_or_abort(self),
      mut_entity_or_abort(self).id,
    ) {
    Some(tick) => tick
    None => abort("Mut::added expected component tick metadata")
  }
}

///|
pub fn[T] Mut::last_changed(self : Mut[T]) -> @core.Tick {
  let world = mut_world_or_abort(self)
  match
    world.changed_component_tick_by_local_id(
      mut_local_component_id_or_abort(self),
      mut_entity_or_abort(self).id,
    ) {
    Some(tick) => tick
    None => abort("Mut::last_changed expected component tick metadata")
  }
}

///|
pub fn[T] Mut::changed_by(self : Mut[T]) -> String? {
  let world = mut_world_or_abort(self)
  world.changed_component_caller_by_local_id(
    mut_local_component_id_or_abort(self),
    mut_entity_or_abort(self).id,
  )
}

///|
#callsite(autofill(loc))
pub fn[T : Component] Mut::set_changed(self : Mut[T], loc~ : SourceLoc) -> Unit {
  ignore(T::component())
  mut_mark_changed(self, caller=hook_caller_from_loc(loc))
}

///|
#callsite(autofill(loc))
pub fn[T : Component] Mut::set_added(self : Mut[T], loc~ : SourceLoc) -> Unit {
  ignore(T::component())
  let world = mut_world_or_abort(self)
  let entity = mut_entity_or_abort(self)
  let key_id = mut_key_id_or_abort(self)
  let caller = hook_caller_from_loc(loc)
  world.record_component_added_with_caller(entity, key_id, caller)
  world.ensure_added_component_messages(key_id).val.send(
    component_write_tick(world),
    entity,
  )
  world.record_component_changed_with_caller(entity, key_id, caller)
}

///|

///|
#callsite(autofill(loc))
pub fn[T : EcsPayloadCodec, R] Mut::modify(
  self : Mut[T],
  f : (T) -> R,
  loc~ : SourceLoc,
) -> R {
  let value = self.peek()
  let result = f(value)
  mut_mark_changed(self, caller=hook_caller_from_loc(loc))
  result
}

///|
#callsite(autofill(loc))
pub fn[T : EcsPayloadCodec + Mutable] Mut::update(
  self : Mut[T],
  f : (T) -> T,
  loc~ : SourceLoc,
) -> Unit {
  self.set(f(self.peek()), loc~)
}

///|
#callsite(autofill(loc))
pub fn[T : Eq + EcsPayloadCodec + Mutable] Mut::set_if_neq(
  self : Mut[T],
  value : T,
  loc~ : SourceLoc,
) -> Bool {
  let current = self.peek()
  if current != value {
    self.set(value, loc~)
    true
  } else {
    false
  }
}

///|
#callsite(autofill(loc))
pub fn[T : EcsPayloadCodec + Mutable] Mut::set(
  self : Mut[T],
  value : T,
  loc~ : SourceLoc,
) -> Unit {
  mut_mark_changed(self, caller=hook_caller_from_loc(loc))
  mut_assign_value_or_abort(self, value)
}

///|
fn[T] world_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Mut[T]? raise EcsError {
  world.ensure_entity_alive(entity)
  guard world.component_payload(key.id(), entity) is Some(_) else {
    return None
  }
  let local_component_id = world.local_component_id(key.id())
  let table_id = world.table_id_for_entity(entity)
  let row_index = match world.entity_table_row(entity) {
    Some(row) => Some(row.index())
    None => None
  }
  Some({
    world: Some(world),
    entity: Some(entity),
    key: Some(key),
    table_id,
    row_index,
    local_component_id,
  })
}

///|
fn[T : Component] component_bundle_writer(value : T) -> (Int, EcsPayloadWriter) {
  let key = T::component()
  (key.id(), ecs_payload_writer(key, value))
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
pub fn[T : Component] World::get_mut(
  self : World,
  entity : @core.Entity,
  key? : ComponentKey[T] = T::component(),
) -> Mut[T]? raise EcsError {
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
) -> Mut[T]? raise EcsError {
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
pub impl Bundle for Unit with insert_into(_self, _world, _entity, loc~) {
  ignore(loc)
  ()
}

///|
pub impl[A : Component, B : Component] Bundle for (A, B) with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b) = self
  let payloads : Array[(Int, EcsPayloadWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
  ]
  try! world.insert_component_payloads_with_requirements(
    entity,
    payloads,
    caller=hook_caller_from_loc(loc),
  )
}

///|
pub impl[A : Component, B : Component, C : Component] Bundle for (A, B, C) with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b, c) = self
  let payloads : Array[(Int, EcsPayloadWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
  ]
  try! world.insert_component_payloads_with_requirements(
    entity,
    payloads,
    caller=hook_caller_from_loc(loc),
  )
}

///|
pub impl[A : Component, B : Component, C : Component, D : Component] Bundle for (
  A,
  B,
  C,
  D,
) with insert_into(self, world, entity, loc~) {
  let (a, b, c, d) = self
  let payloads : Array[(Int, EcsPayloadWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
  ]
  try! world.insert_component_payloads_with_requirements(
    entity,
    payloads,
    caller=hook_caller_from_loc(loc),
  )
}

///|
pub impl[
  A : Component,
  B : Component,
  C : Component,
  D : Component,
  E : Component,
] Bundle for (A, B, C, D, E) with insert_into(self, world, entity, loc~) {
  let (a, b, c, d, e) = self
  let payloads : Array[(Int, EcsPayloadWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
  ]
  try! world.insert_component_payloads_with_requirements(
    entity,
    payloads,
    caller=hook_caller_from_loc(loc),
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
] Bundle for (A, B, C, D, E, F) with insert_into(self, world, entity, loc~) {
  let (a, b, c, d, e, f) = self
  let payloads : Array[(Int, EcsPayloadWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
    component_bundle_writer(f),
  ]
  try! world.insert_component_payloads_with_requirements(
    entity,
    payloads,
    caller=hook_caller_from_loc(loc),
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
] Bundle for (A, B, C, D, E, F, G) with insert_into(self, world, entity, loc~) {
  let (a, b, c, d, e, f, g) = self
  let payloads : Array[(Int, EcsPayloadWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
    component_bundle_writer(f),
    component_bundle_writer(g),
  ]
  try! world.insert_component_payloads_with_requirements(
    entity,
    payloads,
    caller=hook_caller_from_loc(loc),
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
] Bundle for (A, B, C, D, E, F, G, H) with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b, c, d, e, f, g, h) = self
  let payloads : Array[(Int, EcsPayloadWriter)] = [
    component_bundle_writer(a),
    component_bundle_writer(b),
    component_bundle_writer(c),
    component_bundle_writer(d),
    component_bundle_writer(e),
    component_bundle_writer(f),
    component_bundle_writer(g),
    component_bundle_writer(h),
  ]
  try! world.insert_component_payloads_with_requirements(
    entity,
    payloads,
    caller=hook_caller_from_loc(loc),
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
  let previous = self.world.get_by_key(self.entity, T::component())
  if previous is Some(_) {
    self.world.remove_by_key(self.entity, T::component(), loc~) |> ignore
  }
  previous
}

///|
#callsite(autofill(loc))
pub fn EntityMut::despawn(
  self : EntityMut,
  loc~ : SourceLoc,
) -> Unit raise EcsError {
  self.world.despawn(self.entity, loc~)
}
