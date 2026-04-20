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
  matches_component_set((Int) -> Bool) -> Bool
  collect_access(QueryDataAccess) -> Unit = _
  requires_entity_check() -> Bool
  is_dense(World) -> Bool = _
  iteration_anchor_component() -> Int?
  contiguous_compatible() -> Bool
}

///|
impl QueryData with collect_access(_access) {
  ()
}

///|
impl QueryData with is_dense(_world) {
  false
}

///|
pub struct Comp[T] {
  value : T?
}

///|
pub struct QueryDataAccess {
  read_components : Array[Int]
  write_components : Array[Int]
  mut has_read_write_conflict : Bool
  mut has_duplicate_write : Bool
}

///|
pub fn QueryDataAccess::new() -> QueryDataAccess {
  {
    read_components: [],
    write_components: [],
    has_read_write_conflict: false,
    has_duplicate_write: false,
  }
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
  if self.write_components.contains(component_id) {
    self.has_read_write_conflict = true
  }
  if !self.read_components.contains(component_id) {
    self.read_components.push(component_id)
  }
}

///|
pub fn QueryDataAccess::add_write_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Unit {
  if self.write_components.contains(component_id) {
    self.has_duplicate_write = true
  }
  if self.read_components.contains(component_id) {
    self.has_read_write_conflict = true
  }
  if !self.write_components.contains(component_id) {
    self.write_components.push(component_id)
  }
}

///|
pub fn QueryDataAccess::read_components(self : QueryDataAccess) -> Array[Int] {
  self.read_components
}

///|
pub fn QueryDataAccess::write_components(self : QueryDataAccess) -> Array[Int] {
  self.write_components
}

///|
pub fn QueryDataAccess::accesses_component(
  self : QueryDataAccess,
  component_id : Int,
) -> Bool {
  self.read_components.contains(component_id) ||
  self.write_components.contains(component_id)
}

///|
pub fn QueryDataAccess::has_conflict(self : QueryDataAccess) -> Bool {
  self.has_read_write_conflict || self.has_duplicate_write
}

///|
fn query_data_component_is_dense(world : World, component_id : Int) -> Bool {
  guard world.local_component_id(component_id) is Some(local_component_id) else {
    return true
  }
  match world.local_component_storage_type(local_component_id) {
    Some(Table) => true
    Some(SparseSet) => false
    None => true
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
  guard world.component_store(key.id()) is Some(store_ref) else {
    abort("QueryData::fetch expected component store to exist after matches")
  }
  match store_ref.val.get(entity) {
    Some(payload) => world.component_value(key, entity, payload)
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
  guard world.component_store(key.id()) is Some(store_ref) else { return None }
  match store_ref.val.get(entity) {
    Some(payload) => Some(world.component_value(key, entity, payload))
    None => None
  }
}

///|
fn[T] query_data_require_component_mut(
  world : World,
  entity : @core.Entity,
  key : ComponentKey[T],
) -> Mut[T] raise EcsError {
  guard world.component_store(key.id()) is Some(store_ref) else {
    abort("QueryData::fetch expected component store to exist after matches")
  }
  guard store_ref.val.get(entity) is Some(payload) else {
    abort("QueryData::fetch expected component to exist after matches")
  }
  let value_ref = world.component_ref(key, entity, payload)
  {
    value_ref: Some(value_ref),
    world: Some(world),
    entity: Some(entity),
    key_id: Some(key.id()),
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
pub impl QueryData for @core.Entity with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for @core.Entity with collect_access(_access) {
  ()
}

///|
pub impl QueryData for @core.Entity with requires_entity_check() {
  false
}

///|
pub impl QueryData for @core.Entity with is_dense(_world) {
  true
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
pub impl[T : Component] QueryData for Comp[T] with matches_component_set(
  set_contains_id,
) {
  set_contains_id(T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with collect_access(access) {
  access.add_read_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Comp[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Comp[T] with is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
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
pub impl[T : Component] QueryData for Mut[T] with matches_component_set(
  set_contains_id,
) {
  set_contains_id(T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with collect_access(access) {
  access.add_write_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Mut[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Mut[T] with is_dense(world) {
  query_data_component_is_dense(world, T::component().id())
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
pub impl QueryData for EntityRef with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for EntityRef with collect_access(_access) {
  ()
}

///|
pub impl QueryData for EntityRef with requires_entity_check() {
  false
}

///|
pub impl QueryData for EntityRef with is_dense(_world) {
  true
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
pub impl QueryData for EntityMut with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for EntityMut with collect_access(_access) {
  ()
}

///|
pub impl QueryData for EntityMut with requires_entity_check() {
  false
}

///|
pub impl QueryData for EntityMut with is_dense(_world) {
  true
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
pub impl[T : QueryData] QueryData for T? with mentions_component(component_id) {
  T::mentions_component(component_id)
}

///|
pub impl[T : QueryData] QueryData for T? with matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : QueryData] QueryData for T? with collect_access(access) {
  T::collect_access(access)
}

///|
pub impl[T : QueryData] QueryData for T? with requires_entity_check() {
  false
}

///|
pub impl[T : QueryData] QueryData for T? with is_dense(world) {
  T::is_dense(world)
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
pub impl[T : Component] QueryData for Has[T] with matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : Component] QueryData for Has[T] with collect_access(_access) {
  ()
}

///|
pub impl[T : Component] QueryData for Has[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Has[T] with is_dense(_world) {
  true
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
  { value: world.get_by_key(entity, T::component()) }
}

///|
pub impl[T : Component] QueryData for Optional[T] with mentions_component(
  _component_id,
) {
  false
}

///|
pub impl[T : Component] QueryData for Optional[T] with matches_component_set(
  _set_contains_id,
) {
  true
}

///|
pub impl[T : Component] QueryData for Optional[T] with collect_access(access) {
  access.add_read_component(T::component().id())
}

///|
pub impl[T : Component] QueryData for Optional[T] with requires_entity_check() {
  false
}

///|
pub impl[T : Component] QueryData for Optional[T] with is_dense(_world) {
  true
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
pub impl QueryData for Unit with matches_component_set(_set_contains_id) {
  true
}

///|
pub impl QueryData for Unit with collect_access(_access) {
  ()
}

///|
pub impl QueryData for Unit with requires_entity_check() {
  false
}

///|
pub impl QueryData for Unit with is_dense(_world) {
  true
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
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with collect_access(
  access,
) {
  A::collect_access(access)
  B::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with requires_entity_check() {
  A::requires_entity_check() || B::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData] QueryData for (A, B) with is_dense(world) {
  A::is_dense(world) && B::is_dense(world)
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
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with matches_component_set(
  set_contains_id,
) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with collect_access(
  access,
) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData] QueryData for (A, B, C) with is_dense(
  world,
) {
  A::is_dense(world) && B::is_dense(world) && C::is_dense(world)
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

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with matches(world, entity) {
  A::matches(world, entity) &&
  B::matches(world, entity) &&
  C::matches(world, entity) &&
  D::matches(world, entity)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with fetch(world, entity) {
  (
    A::fetch(world, entity),
    B::fetch(world, entity),
    C::fetch(world, entity),
    D::fetch(world, entity),
  )
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with mentions_component(component_id) {
  A::mentions_component(component_id) ||
  B::mentions_component(component_id) ||
  C::mentions_component(component_id) ||
  D::mentions_component(component_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with matches_component_set(set_contains_id) {
  A::matches_component_set(set_contains_id) &&
  B::matches_component_set(set_contains_id) &&
  C::matches_component_set(set_contains_id) &&
  D::matches_component_set(set_contains_id)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with collect_access(access) {
  A::collect_access(access)
  B::collect_access(access)
  C::collect_access(access)
  D::collect_access(access)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with requires_entity_check() {
  A::requires_entity_check() ||
  B::requires_entity_check() ||
  C::requires_entity_check() ||
  D::requires_entity_check()
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with is_dense(world) {
  A::is_dense(world) &&
  B::is_dense(world) &&
  C::is_dense(world) &&
  D::is_dense(world)
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with iteration_anchor_component() {
  match A::iteration_anchor_component() {
    Some(component_id) => Some(component_id)
    None =>
      match B::iteration_anchor_component() {
        Some(component_id) => Some(component_id)
        None =>
          match C::iteration_anchor_component() {
            Some(component_id) => Some(component_id)
            None => D::iteration_anchor_component()
          }
      }
  }
}

///|
pub impl[A : QueryData, B : QueryData, C : QueryData, D : QueryData] QueryData for (
  A,
  B,
  C,
  D,
) with contiguous_compatible() {
  A::contiguous_compatible() &&
  B::contiguous_compatible() &&
  C::contiguous_compatible() &&
  D::contiguous_compatible()
}
