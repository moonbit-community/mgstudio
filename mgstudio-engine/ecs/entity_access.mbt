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
  world : World
  entity : @core.Entity
}

///|
pub struct EntityMut {
  world : World
  entity : @core.Entity
}

///|
pub struct Mut[T] {
  value_ref : Ref[T]?
  world : World?
  entity : @core.Entity?
  key_id : Int?
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
fn[T] mut_value_ref_or_abort(item : Mut[T]) -> Ref[T] {
  match item.value_ref {
    Some(value_ref) => value_ref
    None => abort("Mut expected a fetched query item")
  }
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
  match item.key_id {
    Some(key_id) => key_id
    None => abort("Mut expected a fetched query item")
  }
}

///|
fn[T] mut_mark_changed(item : Mut[T], caller? : String? = None) -> Unit {
  if item.world is Some(world) {
    if item.entity is Some(entity) {
      if item.key_id is Some(key_id) {
        world.record_component_changed_with_caller(entity, key_id, caller)
      }
    }
  }
}

///|
pub fn[T] Mut::new(key : ComponentKey[T]) -> Mut[T] {
  ignore(key)
  { value_ref: None, world: None, entity: None, key_id: None }
}

///|
pub fn[T : Component] Mut::key(self : Mut[T]) -> ComponentKey[T] {
  ignore(self)
  Component::component()
}

///|
#callsite(autofill(loc))
pub fn[T] Mut::get_ref(self : Mut[T], loc~ : SourceLoc) -> Ref[T] {
  mut_mark_changed(self, caller=hook_caller_from_loc(loc))
  mut_value_ref_or_abort(self)
}

///|
pub fn[T] Mut::value(self : Mut[T]) -> T {
  mut_value_ref_or_abort(self).val
}

///|
pub fn[T : Component] Mut::is_added(self : Mut[T]) -> Bool {
  let world = mut_world_or_abort(self)
  world.is_added_by_key(
    mut_entity_or_abort(self),
    T::component(),
    world.get_sequence_context().sequence(),
  )
}

///|
pub fn[T : Component] Mut::is_changed(self : Mut[T]) -> Bool {
  let world = mut_world_or_abort(self)
  world.is_changed_by_key(
    mut_entity_or_abort(self),
    T::component(),
    world.get_sequence_context().sequence(),
  )
}

///|
pub fn[T : Component] Mut::added(self : Mut[T]) -> @core.Sequence {
  ignore(T::component())
  let world = mut_world_or_abort(self)
  match
    world.added_component_sequence(
      mut_key_id_or_abort(self),
      mut_entity_or_abort(self).id,
    ) {
    Some(sequence) => sequence
    None => abort("Mut::added expected component sequence metadata")
  }
}

///|
pub fn[T : Component] Mut::last_changed(self : Mut[T]) -> @core.Sequence {
  ignore(T::component())
  let world = mut_world_or_abort(self)
  match
    world.changed_component_sequence(
      mut_key_id_or_abort(self),
      mut_entity_or_abort(self).id,
    ) {
    Some(sequence) => sequence
    None => abort("Mut::last_changed expected component sequence metadata")
  }
}

///|
pub fn[T : Component] Mut::changed_by(self : Mut[T]) -> String? {
  ignore(T::component())
  let world = mut_world_or_abort(self)
  world.changed_component_caller(
    mut_key_id_or_abort(self),
    mut_entity_or_abort(self).id,
  )
}

///|
#callsite(autofill(loc))
pub fn[T : Component] Mut::set_changed(
  self : Mut[T],
  loc~ : SourceLoc,
) -> Unit {
  ignore(T::component())
  mut_mark_changed(self, caller=hook_caller_from_loc(loc))
}

///|
#callsite(autofill(loc))
pub fn[T : Component] Mut::set_added(
  self : Mut[T],
  loc~ : SourceLoc,
) -> Unit {
  ignore(T::component())
  let world = mut_world_or_abort(self)
  let entity = mut_entity_or_abort(self)
  let key_id = mut_key_id_or_abort(self)
  let caller = hook_caller_from_loc(loc)
  world.record_component_added_with_caller(entity, key_id, caller)
  world.ensure_added_component_messages(key_id).val.send(
    component_write_sequence(world),
    entity,
  )
  world.record_component_changed_with_caller(entity, key_id, caller)
}

///|
pub fn[T] Mut::bypass_change_detection(self : Mut[T]) -> Ref[T] {
  mut_value_ref_or_abort(self)
}

///|
#callsite(autofill(loc))
pub fn[T : Component + Eq] Mut::set_if_neq(
  self : Mut[T],
  value : T,
  loc~ : SourceLoc,
) -> Bool {
  let value_ref = self.bypass_change_detection()
  if value_ref.val != value {
    value_ref.val = value
    self.set_changed(loc~)
    true
  } else {
    false
  }
}

///|
#callsite(autofill(loc))
pub fn[T] Mut::set(self : Mut[T], value : T, loc~ : SourceLoc) -> Unit {
  mut_mark_changed(self, caller=hook_caller_from_loc(loc))
  mut_value_ref_or_abort(self).val = value
}

///|
fn[T] world_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Mut[T]? raise EcsError {
  world.ensure_entity_alive(entity)
  guard world.component_payload(key.id(), entity) is Some(payload) else {
    return None
  }
  let value_ref = try! world.component_ref(key, entity, payload)
  Some({
    value_ref: Some(value_ref),
    world: Some(world),
    entity: Some(entity),
    key_id: Some(key.id()),
  })
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
  try! world.set_by_key(entity, A::component(), a, loc~)
  try! world.set_by_key(entity, B::component(), b, loc~)
}

///|
pub impl[A : Component, B : Component, C : Component] Bundle for (A, B, C) with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b, c) = self
  try! world.set_by_key(entity, A::component(), a, loc~)
  try! world.set_by_key(entity, B::component(), b, loc~)
  try! world.set_by_key(entity, C::component(), c, loc~)
}

///|
pub impl[A : Component, B : Component, C : Component, D : Component] Bundle for (
  A,
  B,
  C,
  D,
) with insert_into(self, world, entity, loc~) {
  let (a, b, c, d) = self
  try! world.set_by_key(entity, A::component(), a, loc~)
  try! world.set_by_key(entity, B::component(), b, loc~)
  try! world.set_by_key(entity, C::component(), c, loc~)
  try! world.set_by_key(entity, D::component(), d, loc~)
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
  try! world.set_by_key(entity, A::component(), a, loc~)
  try! world.set_by_key(entity, B::component(), b, loc~)
  try! world.set_by_key(entity, C::component(), c, loc~)
  try! world.set_by_key(entity, D::component(), d, loc~)
  try! world.set_by_key(entity, E::component(), e, loc~)
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
  try! world.set_by_key(entity, A::component(), a, loc~)
  try! world.set_by_key(entity, B::component(), b, loc~)
  try! world.set_by_key(entity, C::component(), c, loc~)
  try! world.set_by_key(entity, D::component(), d, loc~)
  try! world.set_by_key(entity, E::component(), e, loc~)
  try! world.set_by_key(entity, F::component(), f, loc~)
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
] Bundle for (A, B, C, D, E, F, G) with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  let (a, b, c, d, e, f, g) = self
  try! world.set_by_key(entity, A::component(), a, loc~)
  try! world.set_by_key(entity, B::component(), b, loc~)
  try! world.set_by_key(entity, C::component(), c, loc~)
  try! world.set_by_key(entity, D::component(), d, loc~)
  try! world.set_by_key(entity, E::component(), e, loc~)
  try! world.set_by_key(entity, F::component(), f, loc~)
  try! world.set_by_key(entity, G::component(), g, loc~)
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
  try! world.set_by_key(entity, A::component(), a, loc~)
  try! world.set_by_key(entity, B::component(), b, loc~)
  try! world.set_by_key(entity, C::component(), c, loc~)
  try! world.set_by_key(entity, D::component(), d, loc~)
  try! world.set_by_key(entity, E::component(), e, loc~)
  try! world.set_by_key(entity, F::component(), f, loc~)
  try! world.set_by_key(entity, G::component(), g, loc~)
  try! world.set_by_key(entity, H::component(), h, loc~)
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
