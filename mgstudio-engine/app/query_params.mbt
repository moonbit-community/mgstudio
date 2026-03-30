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
pub impl FromWorld for @ecs.All with from_world(_world) {
  @ecs.All::new()
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.With[T] with from_world(_world) {
  @ecs.With::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Without[T] with from_world(
  _world,
) {
  @ecs.Without::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Allow[T] with from_world(_world) {
  @ecs.Allow::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Added[T] with from_world(_world) {
  @ecs.Added::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Changed[T] with from_world(
  _world,
) {
  @ecs.Changed::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Has[T] with from_world(_world) {
  @ecs.Has::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Optional[T] with from_world(
  _world,
) {
  @ecs.Optional::new(@ecs.Component::component())
}

///|
pub impl[F : FromWorld] FromWorld for @ecs.Or[F] with from_world(world) {
  @ecs.Or::new(F::from_world(world))
}

///|
pub impl[A : FromWorld, B : FromWorld] FromWorld for (A, B) with from_world(
  world,
) {
  (A::from_world(world), B::from_world(world))
}

///|
pub impl[A : FromWorld, B : FromWorld, C : FromWorld] FromWorld for (A, B, C) with from_world(
  world,
) {
  (A::from_world(world), B::from_world(world), C::from_world(world))
}

///|
pub impl[D, F : FromWorld] SystemParam for @ecs.Query[D, F] with init_state(
  world,
) {
  system_param_empty_state(world)
}

///|
pub impl[D, F : FromWorld] SystemParam for @ecs.Query[D, F] with get(_state) {
  let world = system_param_abort_missing_world()
  @ecs.query_filtered(world, F::from_world(world))
}

///|
pub impl[D, F : FromWorld] SystemParam for @ecs.Query[D, F] with store(
  self,
  state,
) {
  system_param_store_no_state(self, state)
}

///|
pub struct Single[D, _] {
  value : D
}

///|
pub fn[D, F] Single::get(self : Single[D, F]) -> D {
  self.value
}

///|
pub struct Populated[D, F] {
  query : @ecs.Query[D, F]
}

///|
pub fn[D, F] Populated::query(self : Populated[D, F]) -> @ecs.Query[D, F] {
  self.query
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  let query : @ecs.Query[D, F] = @ecs.query_filtered(
    world,
    F::from_world(world),
  )
  let value = query.require_single()
  Single::{ value, }
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with init_state(world) {
  system_param_empty_state(world)
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with get(_state) {
  let world = system_param_abort_missing_world()
  let query : @ecs.Query[D, F] = @ecs.query_filtered(
    world,
    F::from_world(world),
  )
  if query.count() == 0 {
    raise @ecs.Skipped("Expected at least one matching entity")
  }
  Populated::{ query, }
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with store(self, state) {
  system_param_store_no_state(self, state)
}
