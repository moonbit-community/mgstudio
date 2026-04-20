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
pub(open) trait QueryFilter {
  matches(self : Self, world : World, entity : @core.Entity) -> Bool
  mentions_component(self : Self, component_id : Int) -> Bool
  matches_component_set(self : Self, set_contains_id : (Int) -> Bool) -> Bool
  collect_access(self : Self, access : QueryFilterAccess) -> Unit = _
  requires_entity_check(self : Self) -> Bool
  is_dense(self : Self, world : World) -> Bool = _
  iteration_anchor_component(self : Self) -> Int?
  iteration_anchor_components(self : Self) -> Array[Int] = _
  depends_on_sequence(self : Self) -> Bool
}

///|
pub(open) trait QueryFilterDisjunction {
  matches_any(self : Self, world : World, entity : @core.Entity) -> Bool
  mentions_component_any(self : Self, component_id : Int) -> Bool
  matches_component_set_any(self : Self, set_contains_id : (Int) -> Bool) -> Bool
  collect_access_any(self : Self, access : QueryFilterAccess) -> Unit = _
  requires_entity_check_any(self : Self) -> Bool
  is_dense_any(self : Self, world : World) -> Bool = _
  depends_on_sequence_any(self : Self) -> Bool
}

///|
impl QueryFilter with collect_access(_self, _access) {
  ()
}

///|
impl QueryFilter with is_dense(_self, _world) {
  false
}

///|
impl QueryFilter with iteration_anchor_components(self) {
  match QueryFilter::iteration_anchor_component(self) {
    Some(component_id) => [component_id]
    None => []
  }
}

///|
impl QueryFilterDisjunction with collect_access_any(_self, _access) {
  ()
}

///|
impl QueryFilterDisjunction with is_dense_any(_self, _world) {
  false
}

///|
pub struct QueryFilterAccess {
  read_components : Array[Int]
  with_components : Array[Int]
  without_components : Array[Int]
}

///|
pub fn QueryFilterAccess::new() -> QueryFilterAccess {
  { read_components: [], with_components: [], without_components: [] }
}

///|
pub fn QueryFilterAccess::add_read_component(
  self : QueryFilterAccess,
  component_id : Int,
) -> Unit {
  if !self.read_components.contains(component_id) {
    self.read_components.push(component_id)
  }
}

///|
pub fn QueryFilterAccess::add_with_component(
  self : QueryFilterAccess,
  component_id : Int,
) -> Unit {
  if !self.with_components.contains(component_id) {
    self.with_components.push(component_id)
  }
}

///|
pub fn QueryFilterAccess::add_without_component(
  self : QueryFilterAccess,
  component_id : Int,
) -> Unit {
  if !self.without_components.contains(component_id) {
    self.without_components.push(component_id)
  }
}

///|
pub fn QueryFilterAccess::read_components(
  self : QueryFilterAccess,
) -> Array[Int] {
  self.read_components
}

///|
pub fn QueryFilterAccess::with_components(
  self : QueryFilterAccess,
) -> Array[Int] {
  self.with_components
}

///|
pub fn QueryFilterAccess::without_components(
  self : QueryFilterAccess,
) -> Array[Int] {
  self.without_components
}

///|
fn query_filter_component_is_dense(world : World, component_id : Int) -> Bool {
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
fn query_filter_append_unique_anchor_components(
  out : Array[Int],
  component_ids : Array[Int],
) -> Unit {
  for component_id in component_ids {
    if !out.contains(component_id) {
      out.push(component_id)
    }
  }
}

///|
pub struct All {}

///|
pub fn All::new() -> All {
  All::{  }
}

///|
pub impl QueryFilter for All with matches(self, _world, _entity) {
  ignore(self)
  true
}

///|
pub impl QueryFilter for All with mentions_component(self, _component_id) {
  ignore(self)
  false
}

///|
pub impl QueryFilter for All with matches_component_set(self, _set_contains_id) {
  ignore(self)
  true
}

///|
pub impl QueryFilter for All with collect_access(self, _access) {
  ignore(self)
}

///|
pub impl QueryFilter for All with requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl QueryFilter for All with is_dense(self, _world) {
  ignore(self)
  true
}

///|
pub impl QueryFilter for All with iteration_anchor_component(self) {
  ignore(self)
  None
}

///|
pub impl QueryFilter for All with depends_on_sequence(self) {
  ignore(self)
  false
}

///|
pub struct With[T] {
  key : ComponentKey[T]
}

///|
pub fn[T] With::new(key : ComponentKey[T]) -> With[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for With[T] with matches(self, world, entity) {
  entity_has_component_id(world, self.key.id(), entity)
}

///|
pub impl[T] QueryFilter for With[T] with mentions_component(self, component_id) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for With[T] with matches_component_set(
  self,
  set_contains_id,
) {
  set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with collect_access(self, access) {
  access.add_with_component(self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for With[T] with is_dense(self, world) {
  query_filter_component_is_dense(world, self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with iteration_anchor_component(self) {
  Some(self.key.id())
}

///|
pub impl[T] QueryFilter for With[T] with depends_on_sequence(self) {
  ignore(self)
  false
}

///|
pub struct Without[T] {
  key : ComponentKey[T]
}

///|
pub fn[T] Without::new(key : ComponentKey[T]) -> Without[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Without[T] with matches(self, world, entity) {
  !entity_has_component_id(world, self.key.id(), entity)
}

///|
pub impl[T] QueryFilter for Without[T] with mentions_component(
  self,
  component_id,
) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Without[T] with matches_component_set(
  self,
  set_contains_id,
) {
  !set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for Without[T] with collect_access(self, access) {
  access.add_without_component(self.key.id())
}

///|
pub impl[T] QueryFilter for Without[T] with requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for Without[T] with is_dense(self, world) {
  query_filter_component_is_dense(world, self.key.id())
}

///|
pub impl[T] QueryFilter for Without[T] with iteration_anchor_component(self) {
  ignore(self)
  None
}

///|
pub impl[T] QueryFilter for Without[T] with depends_on_sequence(self) {
  ignore(self)
  false
}

///|
pub struct Allow[T] {
  key : ComponentKey[T]
}

///|
pub fn[T] Allow::new(key : ComponentKey[T]) -> Allow[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Allow[T] with matches(self, _world, _entity) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Allow[T] with mentions_component(self, component_id) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Allow[T] with matches_component_set(
  self,
  _set_contains_id,
) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Allow[T] with collect_access(self, _access) {
  ignore(self)
}

///|
pub impl[T] QueryFilter for Allow[T] with requires_entity_check(self) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for Allow[T] with is_dense(self, _world) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Allow[T] with iteration_anchor_component(self) {
  ignore(self)
  None
}

///|
pub impl[T] QueryFilter for Allow[T] with depends_on_sequence(self) {
  ignore(self)
  false
}

///|
pub struct Added[T] {
  key : ComponentKey[T]
}

///|
pub fn[T] Added::new(key : ComponentKey[T]) -> Added[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Added[T] with matches(self, world, entity) {
  world.is_added_by_key(
    entity,
    self.key,
    world.get_sequence_context().sequence(),
  )
}

///|
pub impl[T] QueryFilter for Added[T] with mentions_component(self, component_id) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Added[T] with matches_component_set(
  self,
  set_contains_id,
) {
  set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with collect_access(self, access) {
  access.add_with_component(self.key.id())
  access.add_read_component(self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with requires_entity_check(self) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Added[T] with is_dense(self, _world) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for Added[T] with iteration_anchor_component(self) {
  Some(self.key.id())
}

///|
pub impl[T] QueryFilter for Added[T] with depends_on_sequence(self) {
  ignore(self)
  true
}

///|
pub struct Changed[T] {
  key : ComponentKey[T]
}

///|
pub fn[T] Changed::new(key : ComponentKey[T]) -> Changed[T] {
  { key, }
}

///|
pub impl[T] QueryFilter for Changed[T] with matches(self, world, entity) {
  world.is_changed_by_key(
    entity,
    self.key,
    world.get_sequence_context().sequence(),
  )
}

///|
pub impl[T] QueryFilter for Changed[T] with mentions_component(
  self,
  component_id,
) {
  self.key.id() == component_id
}

///|
pub impl[T] QueryFilter for Changed[T] with matches_component_set(
  self,
  set_contains_id,
) {
  set_contains_id(self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with collect_access(self, access) {
  access.add_with_component(self.key.id())
  access.add_read_component(self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with requires_entity_check(self) {
  ignore(self)
  true
}

///|
pub impl[T] QueryFilter for Changed[T] with is_dense(self, _world) {
  ignore(self)
  false
}

///|
pub impl[T] QueryFilter for Changed[T] with iteration_anchor_component(self) {
  Some(self.key.id())
}

///|
pub impl[T] QueryFilter for Changed[T] with depends_on_sequence(self) {
  ignore(self)
  true
}

///|
pub struct Or[F] {
  filters : F
}

///|
pub fn[F] Or::new(filters : F) -> Or[F] {
  { filters, }
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with matches(
  self,
  world,
  entity,
) {
  QueryFilterDisjunction::matches_any(self.filters, world, entity)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with mentions_component(
  self,
  component_id,
) {
  QueryFilterDisjunction::mentions_component_any(self.filters, component_id)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilterDisjunction::matches_component_set_any(
    self.filters,
    set_contains_id,
  )
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with collect_access(
  self,
  access,
) {
  QueryFilterDisjunction::collect_access_any(self.filters, access)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with requires_entity_check(
  self,
) {
  QueryFilterDisjunction::requires_entity_check_any(self.filters)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with is_dense(
  self,
  world,
) {
  QueryFilterDisjunction::is_dense_any(self.filters, world)
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with iteration_anchor_component(
  self,
) {
  ignore(self)
  None
}

///|
pub impl[F : QueryFilterDisjunction] QueryFilter for Or[F] with depends_on_sequence(
  self,
) {
  QueryFilterDisjunction::depends_on_sequence_any(self.filters)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with matches(
  self,
  world,
  entity,
) {
  QueryFilter::matches(self.0, world, entity) &&
  QueryFilter::matches(self.1, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with mentions_component(
  self,
  component_id,
) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with matches_component_set(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(self.0, set_contains_id) &&
  QueryFilter::matches_component_set(self.1, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with collect_access(
  self,
  access,
) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with requires_entity_check(
  self,
) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with is_dense(
  self,
  world,
) {
  QueryFilter::is_dense(self.0, world) && QueryFilter::is_dense(self.1, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with iteration_anchor_component(
  self,
) {
  match QueryFilter::iteration_anchor_component(self.0) {
    Some(component_id) => Some(component_id)
    None => QueryFilter::iteration_anchor_component(self.1)
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with iteration_anchor_components(
  self,
) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.0),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.1),
  )
  component_ids
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilter for (A, B) with depends_on_sequence(
  self,
) {
  QueryFilter::depends_on_sequence(self.0) ||
  QueryFilter::depends_on_sequence(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with matches(self, world, entity) {
  QueryFilter::matches(self.0, world, entity) &&
  QueryFilter::matches(self.1, world, entity) &&
  QueryFilter::matches(self.2, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with mentions_component(self, component_id) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id) ||
  QueryFilter::mentions_component(self.2, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with matches_component_set(self, set_contains_id) {
  QueryFilter::matches_component_set(self.0, set_contains_id) &&
  QueryFilter::matches_component_set(self.1, set_contains_id) &&
  QueryFilter::matches_component_set(self.2, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with collect_access(self, access) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
  QueryFilter::collect_access(self.2, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with requires_entity_check(self) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1) ||
  QueryFilter::requires_entity_check(self.2)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with is_dense(self, world) {
  QueryFilter::is_dense(self.0, world) &&
  QueryFilter::is_dense(self.1, world) &&
  QueryFilter::is_dense(self.2, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with iteration_anchor_component(self) {
  match QueryFilter::iteration_anchor_component(self.0) {
    Some(component_id) => Some(component_id)
    None =>
      match QueryFilter::iteration_anchor_component(self.1) {
        Some(component_id) => Some(component_id)
        None => QueryFilter::iteration_anchor_component(self.2)
      }
  }
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with iteration_anchor_components(self) {
  let component_ids : Array[Int] = []
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.0),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.1),
  )
  query_filter_append_unique_anchor_components(
    component_ids,
    QueryFilter::iteration_anchor_components(self.2),
  )
  component_ids
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilter for (
  A,
  B,
  C,
) with depends_on_sequence(self) {
  QueryFilter::depends_on_sequence(self.0) ||
  QueryFilter::depends_on_sequence(self.1) ||
  QueryFilter::depends_on_sequence(self.2)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with matches_any(
  self,
  world,
  entity,
) {
  QueryFilter::matches(self.0, world, entity) ||
  QueryFilter::matches(self.1, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with mentions_component_any(
  self,
  component_id,
) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with matches_component_set_any(
  self,
  set_contains_id,
) {
  QueryFilter::matches_component_set(self.0, set_contains_id) ||
  QueryFilter::matches_component_set(self.1, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with collect_access_any(
  self,
  access,
) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with requires_entity_check_any(
  self,
) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with is_dense_any(
  self,
  world,
) {
  QueryFilter::is_dense(self.0, world) && QueryFilter::is_dense(self.1, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter] QueryFilterDisjunction for (A, B) with depends_on_sequence_any(
  self,
) {
  QueryFilter::depends_on_sequence(self.0) ||
  QueryFilter::depends_on_sequence(self.1)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with matches_any(self, world, entity) {
  QueryFilter::matches(self.0, world, entity) ||
  QueryFilter::matches(self.1, world, entity) ||
  QueryFilter::matches(self.2, world, entity)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with mentions_component_any(self, component_id) {
  QueryFilter::mentions_component(self.0, component_id) ||
  QueryFilter::mentions_component(self.1, component_id) ||
  QueryFilter::mentions_component(self.2, component_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with matches_component_set_any(self, set_contains_id) {
  QueryFilter::matches_component_set(self.0, set_contains_id) ||
  QueryFilter::matches_component_set(self.1, set_contains_id) ||
  QueryFilter::matches_component_set(self.2, set_contains_id)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with collect_access_any(self, access) {
  QueryFilter::collect_access(self.0, access)
  QueryFilter::collect_access(self.1, access)
  QueryFilter::collect_access(self.2, access)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with requires_entity_check_any(self) {
  QueryFilter::requires_entity_check(self.0) ||
  QueryFilter::requires_entity_check(self.1) ||
  QueryFilter::requires_entity_check(self.2)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with is_dense_any(self, world) {
  QueryFilter::is_dense(self.0, world) &&
  QueryFilter::is_dense(self.1, world) &&
  QueryFilter::is_dense(self.2, world)
}

///|
pub impl[A : QueryFilter, B : QueryFilter, C : QueryFilter] QueryFilterDisjunction for (
  A,
  B,
  C,
) with depends_on_sequence_any(self) {
  QueryFilter::depends_on_sequence(self.0) ||
  QueryFilter::depends_on_sequence(self.1) ||
  QueryFilter::depends_on_sequence(self.2)
}
