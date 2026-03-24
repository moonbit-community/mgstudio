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
pub struct SingleEntityFiltered[F] {
  entity : @core.Entity
}

///|
pub fn[F] SingleEntityFiltered::get(
  self : SingleEntityFiltered[F],
) -> @core.Entity {
  self.entity
}

///|
pub impl[F : FromWorld + @ecs.QueryFilter] SystemParam for SingleEntityFiltered[
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[F : FromWorld + @ecs.QueryFilter] SystemParam for SingleEntityFiltered[
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  let entity = world
    .query_entities_filtered(F::from_world(world))
    .require_single()
  SingleEntityFiltered::{ entity, }
}

///|
pub impl[F : FromWorld + @ecs.QueryFilter] SystemParam for SingleEntityFiltered[
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub struct SingleQuery1[A] {
  value : A
}

///|
pub fn[A] SingleQuery1::get(self : SingleQuery1[A]) -> A {
  self.value
}

///|
pub impl[A : @ecs.Component] SystemParam for SingleQuery1[A] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component] SystemParam for SingleQuery1[A] with get(_state) {
  let world = system_param_abort_missing_world()
  let value = world.query1(@ecs.Component::component()).require_single()
  SingleQuery1::{ value, }
}

///|
pub impl[A : @ecs.Component] SystemParam for SingleQuery1[A] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub struct SingleQuery1Filtered[A, F] {
  value : A
}

///|
pub fn[A, F] SingleQuery1Filtered::get(self : SingleQuery1Filtered[A, F]) -> A {
  self.value
}

///|
pub impl[A : @ecs.Component, F : FromWorld + @ecs.QueryFilter] SystemParam for SingleQuery1Filtered[
  A,
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, F : FromWorld + @ecs.QueryFilter] SystemParam for SingleQuery1Filtered[
  A,
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  let value = world
    .query1_filtered(@ecs.Component::component(), F::from_world(world))
    .require_single()
  SingleQuery1Filtered::{ value, }
}

///|
pub impl[A : @ecs.Component, F : FromWorld + @ecs.QueryFilter] SystemParam for SingleQuery1Filtered[
  A,
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub struct SingleQuery2MutRef[A, B] {
  value : (@ecs.ComponentMut[A], @ecs.ComponentRef[B])
}

///|
pub fn[A, B] SingleQuery2MutRef::get(
  self : SingleQuery2MutRef[A, B],
) -> (@ecs.ComponentMut[A], @ecs.ComponentRef[B]) {
  self.value
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for SingleQuery2MutRef[
  A,
  B,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for SingleQuery2MutRef[
  A,
  B,
] with get(_state) {
  let world = system_param_abort_missing_world()
  let value = world
    .query2_mut_ref_filtered(
      @ecs.Component::component(),
      @ecs.Component::component(),
      @ecs.All::new(),
    )
    .require_single()
  SingleQuery2MutRef::{ value, }
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for SingleQuery2MutRef[
  A,
  B,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub struct SingleQuery2MutRefFiltered[A, B, F] {
  value : (@ecs.ComponentMut[A], @ecs.ComponentRef[B])
}

///|
pub fn[A, B, F] SingleQuery2MutRefFiltered::get(
  self : SingleQuery2MutRefFiltered[A, B, F],
) -> (@ecs.ComponentMut[A], @ecs.ComponentRef[B]) {
  self.value
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  F : FromWorld + @ecs.QueryFilter,
] SystemParam for SingleQuery2MutRefFiltered[A, B, F] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  F : FromWorld + @ecs.QueryFilter,
] SystemParam for SingleQuery2MutRefFiltered[A, B, F] with get(_state) {
  let world = system_param_abort_missing_world()
  let value = world
    .query2_mut_ref_filtered(
      @ecs.Component::component(),
      @ecs.Component::component(),
      F::from_world(world),
    )
    .require_single()
  SingleQuery2MutRefFiltered::{ value, }
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  F : FromWorld + @ecs.QueryFilter,
] SystemParam for SingleQuery2MutRefFiltered[A, B, F] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub struct PopulatedQuery2MutMut[A, B] {
  query : @ecs.Query2MutMutFiltered[A, B, @ecs.All]
}

///|
pub fn[A, B] PopulatedQuery2MutMut::query(
  self : PopulatedQuery2MutMut[A, B],
) -> @ecs.Query2MutMutFiltered[A, B, @ecs.All] {
  self.query
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for PopulatedQuery2MutMut[
  A,
  B,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for PopulatedQuery2MutMut[
  A,
  B,
] with get(_state) {
  let world = system_param_abort_missing_world()
  let query = world.query2_mut_mut_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    @ecs.All::new(),
  )
  if query.count() == 0 {
    raise @ecs.Skipped("Expected at least one matching entity")
  }
  PopulatedQuery2MutMut::{ query, }
}

///|
pub impl[A : @ecs.Component, B : @ecs.Component] SystemParam for PopulatedQuery2MutMut[
  A,
  B,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub struct PopulatedQuery2MutMutFiltered[A, B, F] {
  query : @ecs.Query2MutMutFiltered[A, B, F]
}

///|
pub fn[A, B, F] PopulatedQuery2MutMutFiltered::query(
  self : PopulatedQuery2MutMutFiltered[A, B, F],
) -> @ecs.Query2MutMutFiltered[A, B, F] {
  self.query
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  F : FromWorld + @ecs.QueryFilter,
] SystemParam for PopulatedQuery2MutMutFiltered[A, B, F] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  F : FromWorld + @ecs.QueryFilter,
] SystemParam for PopulatedQuery2MutMutFiltered[A, B, F] with get(_state) {
  let world = system_param_abort_missing_world()
  let query = world.query2_mut_mut_filtered(
    @ecs.Component::component(),
    @ecs.Component::component(),
    F::from_world(world),
  )
  if query.count() == 0 {
    raise @ecs.Skipped("Expected at least one matching entity")
  }
  PopulatedQuery2MutMutFiltered::{ query, }
}

///|
pub impl[
  A : @ecs.Component,
  B : @ecs.Component,
  F : FromWorld + @ecs.QueryFilter,
] SystemParam for PopulatedQuery2MutMutFiltered[A, B, F] with store(self, state) {
  system_param_store_no_state(self, state)
}
