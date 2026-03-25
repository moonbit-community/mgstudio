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
pub(open) trait QueryData {
  matches(World, @core.Entity) -> Bool
  fetch(World, @core.Entity) -> Self raise EcsError
  mentions_component(Int) -> Bool
  iteration_anchor_component() -> Int?
  contiguous_compatible() -> Bool
}

///|
pub struct Comp[T] {
  value : T?
}

///|
pub struct QueryDataAccess {
  read_components : Array[Int]
  write_components : Array[Int]
}

///|
pub fn QueryDataAccess::new() -> QueryDataAccess {
  { read_components: [], write_components: [] }
}

///|
pub fn[T] Comp::new(key : ComponentKey[T]) -> Comp[T] {
  ignore(key)
  { value: None }
}

///|
pub fn[T : Component] Comp::key(self : Comp[T]) -> ComponentKey[T] {
  ignore(self)
  Component::component()
}

///|
pub fn[T] Comp::value(self : Comp[T]) -> T {
  match self.value {
    Some(value) => value
    None => abort("Comp::value expected a fetched query item")
  }
}

///|
pub fn QueryDataAccess::add_read_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Unit {
  if !self.read_components.contains(component_id) {
    self.read_components.push(component_id)
  }
}

///|
pub fn QueryDataAccess::add_write_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Unit {
  if !self.write_components.contains(component_id) {
    self.write_components.push(component_id)
  }
}

///|
pub fn[T] query_data_component_matches(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool {
  entity_has_component_id(world, key.id(), entity)
}

///|
fn[T] query_data_require_component(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T raise EcsError {
  match world.get(entity, key) {
    Some(value) => value
    None => abort("QueryData::fetch expected component to exist after matches")
  }
}

///|
pub fn[T] query_data_component_fetch(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T raise EcsError {
  query_data_require_component(world, entity, key)
}

///|
pub fn[T] query_data_component_optional(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> T? raise EcsError {
  world.get(entity, key)
}

///|
fn[T] query_data_require_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Mut[T] raise EcsError {
  match world_component_mut(world, entity, key) {
    Some(value) => value
    None => abort("QueryData::fetch expected component to exist after matches")
  }
}

///|
pub fn[T] query_data_component_has(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Bool {
  entity_has_component_id(world, key.id(), entity)
}

///|
pub impl QueryData for @core.Entity with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for @core.Entity with fetch(_world, entity) {
  entity
}

///|
pub impl QueryData for @core.Entity with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for @core.Entity with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for @core.Entity with contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Comp[T] with matches(world, entity) {
  query_data_component_matches(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Comp[T] with fetch(world, entity) {
  { value: Some(query_data_require_component(world, entity, T::component())) }
}

///|
pub impl[T : Component] QueryData for Comp[T] with mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Comp[T] with iteration_anchor_component() {
  Some(T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Mut[T] with matches(world, entity) {
  query_data_component_matches(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Mut[T] with fetch(world, entity) {
  query_data_require_component_mut(world, entity, T::component())
}

///|
pub impl[T : Component] QueryData for Mut[T] with mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Mut[T] with iteration_anchor_component() {
  Some(T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with contiguous_compatible() {
  true
}

///|
pub impl QueryData for EntityRef with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for EntityRef with fetch(world, entity) {
  try! world.entity(entity)
}

///|
pub impl QueryData for EntityRef with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for EntityRef with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for EntityRef with contiguous_compatible() {
  true
}

///|
pub impl QueryData for EntityMut with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for EntityMut with fetch(world, entity) {
  try! world.entity_mut(entity)
}

///|
pub impl QueryData for EntityMut with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for EntityMut with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for EntityMut with contiguous_compatible() {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with matches(_world, _entity) {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with fetch(world, entity) {
  if T::matches(world, entity) {
    Some(T::fetch(world, entity))
  } else {
    None
  }
}

///|
pub impl[T : QueryData] QueryData for T? with mentions_component(_component_id) {
  false
}

///|
pub impl[T : QueryData] QueryData for T? with iteration_anchor_component() {
  None
}

///|
pub impl[T : QueryData] QueryData for T? with contiguous_compatible() {
  T::contiguous_compatible()
}

///|
pub impl[T : Component] QueryData for Has[T] with matches(_world, _entity) {
  true
}

///|
pub impl[T : Component] QueryData for Has[T] with fetch(world, entity) {
  { present: entity_has_component_id(world, T::component().id(), entity) }
}

///|
pub impl[T : Component] QueryData for Has[T] with mentions_component(
  component_id,
) {
  component_id == T::component().id()
}

///|
pub impl[T : Component] QueryData for Has[T] with iteration_anchor_component() {
  None
}

///|
pub impl[T : Component] QueryData for Has[T] with contiguous_compatible() {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with matches(_world, _entity) {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with fetch(world, entity) {
  { value: world.get(entity, T::component()) }
}

///|
pub impl[T : Component] QueryData for Optional[T] with mentions_component(
  _component_id,
) {
  false
}

///|
pub impl[T : Component] QueryData for Optional[T] with iteration_anchor_component() {
  None
}

///|
pub impl[T : Component] QueryData for Optional[T] with contiguous_compatible() {
  true
}

///|
pub impl QueryData for Unit with matches(_world, _entity) {
  true
}

///|
pub impl QueryData for Unit with fetch(_world, _entity) {
  ()
}

///|
pub impl QueryData for Unit with mentions_component(_component_id) {
  false
}

///|
pub impl QueryData for Unit with iteration_anchor_component() {
  None
}

///|
pub impl QueryData for Unit with contiguous_compatible() {
  true
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with matches(
  world,
  entity,
) {
  A::matches(world, entity) && B::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with fetch(
  world,
  entity,
) {
  (A::fetch(world, entity), B::fetch(world, entity))
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with mentions_component(
  component_id,
) {
  A::mentions_component(component_id) || B::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None => B::iteration_anchor_component()
  }
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with contiguous_compatible() {
  A::contiguous_compatible() && B::contiguous_compatible()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with matches(
  world,
  entity,
) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with fetch(
  world,
  entity,
) {
  (A::fetch(world, entity), B::fetch(world, entity), C::fetch(world, entity))
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with mentions_component(
  component_id,
) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None => C::iteration_anchor_component()
      }
  }
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible()
}
