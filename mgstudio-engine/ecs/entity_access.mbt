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
pub fn[T] Mut::get_ref(self : Mut[T]) -> Ref[T] {
  if self.world is Some(world) {
    if self.entity is Some(entity) {
      if self.key_id is Some(key_id) {
        world.record_component_changed(entity, key_id)
      }
    }
  }
  match self.value_ref {
    Some(value_ref) => value_ref
    None => abort("Mut::get_ref expected a fetched query item")
  }
}

///|
pub fn[T] Mut::value(self : Mut[T]) -> T {
  self.get_ref().val
}

///|
pub fn[T] Mut::set(self : Mut[T], value : T) -> Unit {
  self.get_ref().val = value
}

///|
fn[T] world_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Mut[T]? raise EcsError {
  world.ensure_entity_alive(entity)
  guard world.component_store(key.id()) is Some(store_ref) else { return None }
  guard store_ref.val.get(entity) is Some(payload) else { return None }
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
