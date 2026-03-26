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
}

///|
pub(open) trait QueryFilterDisjunction {
  matches_any(self : Self, world : World, entity : @core.Entity) -> Bool
  mentions_component_any(self : Self, component_id : Int) -> Bool
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
