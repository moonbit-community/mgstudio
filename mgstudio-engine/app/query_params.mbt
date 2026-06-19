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
pub impl FromWorld for @ecs.All with fn from_world(_world) {
  @ecs.All::new()
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.With[T] with fn from_world(
  _world,
) {
  @ecs.With::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Without[T] with fn from_world(
  _world,
) {
  @ecs.Without::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Allow[T] with fn from_world(
  _world,
) {
  @ecs.Allow::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Added[T] with fn from_world(
  _world,
) {
  @ecs.Added::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Changed[T] with fn from_world(
  _world,
) {
  @ecs.Changed::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Has[T] with fn from_world(
  _world,
) {
  @ecs.Has::new(@ecs.Component::component())
}

///|
pub impl[T : @ecs.Component] FromWorld for @ecs.Optional[T] with fn from_world(
  _world,
) {
  @ecs.Optional::new(@ecs.Component::component())
}

///|
pub impl[F : FromWorld] FromWorld for @ecs.Or[F] with fn from_world(world) {
  @ecs.Or::new(F::from_world(world))
}

///|
pub impl[A : FromWorld, B : FromWorld] FromWorld for (A, B) with fn from_world(
  world,
) {
  (A::from_world(world), B::from_world(world))
}

///|
pub impl[A : FromWorld, B : FromWorld, C : FromWorld] FromWorld for (A, B, C) with fn from_world(
  world,
) {
  (A::from_world(world), B::from_world(world), C::from_world(world))
}

///|
pub impl[A : FromWorld, B : FromWorld, C : FromWorld, D : FromWorld] FromWorld for (
  A,
  B,
  C,
  D,
) with fn from_world(world) {
  (
    A::from_world(world),
    B::from_world(world),
    C::from_world(world),
    D::from_world(world),
  )
}

///|
pub impl[
  A : FromWorld,
  B : FromWorld,
  C : FromWorld,
  D : FromWorld,
  E : FromWorld,
] FromWorld for (A, B, C, D, E) with fn from_world(world) {
  (
    A::from_world(world),
    B::from_world(world),
    C::from_world(world),
    D::from_world(world),
    E::from_world(world),
  )
}

///|
pub impl[
  A : FromWorld,
  B : FromWorld,
  C : FromWorld,
  D : FromWorld,
  E : FromWorld,
  F : FromWorld,
] FromWorld for (A, B, C, D, E, F) with fn from_world(world) {
  (
    A::from_world(world),
    B::from_world(world),
    C::from_world(world),
    D::from_world(world),
    E::from_world(world),
    F::from_world(world),
  )
}

///|
pub impl[
  A : FromWorld,
  B : FromWorld,
  C : FromWorld,
  D : FromWorld,
  E : FromWorld,
  F : FromWorld,
  G : FromWorld,
] FromWorld for (A, B, C, D, E, F, G) with fn from_world(world) {
  (
    A::from_world(world),
    B::from_world(world),
    C::from_world(world),
    D::from_world(world),
    E::from_world(world),
    F::from_world(world),
    G::from_world(world),
  )
}

///|
pub impl[
  A : FromWorld,
  B : FromWorld,
  C : FromWorld,
  D : FromWorld,
  E : FromWorld,
  F : FromWorld,
  G : FromWorld,
  H : FromWorld,
] FromWorld for (A, B, C, D, E, F, G, H) with fn from_world(world) {
  (
    A::from_world(world),
    B::from_world(world),
    C::from_world(world),
    D::from_world(world),
    E::from_world(world),
    F::from_world(world),
    G::from_world(world),
    H::from_world(world),
  )
}

///|
priv struct QueryParamState {
  mut cache : @ecs.QueryCache
}

///|
fn query_param_state_new() -> QueryParamState {
  { cache: @ecs.QueryCache::new() }
}

///|
fn[D, F : FromWorld] query_param_query_from_state(
  state : QueryParamState,
) -> @ecs.Query[D, F] {
  let world = system_param_abort_missing_world()
  let filter = F::from_world(world)
  @ecs.query_filtered_with_cache(world, filter, state.cache)
}

///|
fn[D, F] query_param_store_query_state(
  query : @ecs.Query[D, F],
  state : QueryParamState,
) -> Unit {
  state.cache = query.cache_state()
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for @ecs.Query[
  D,
  F,
] with fn init_state(_world) {
  let state = query_param_state_new()
  SystemParamState::new(fn() { query_param_query_from_state(state) }, fn(
    query : @ecs.Query[D, F],
  ) {
    query_param_store_query_state(query, state)
  })
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for @ecs.Query[
  D,
  F,
] with fn get(state) {
  state.get()
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for @ecs.Query[
  D,
  F,
] with fn store(self, state) {
  state.store(self)
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for @ecs.Query[
  D,
  F,
] with fn access(world) {
  let access = SystemAccess::new()
  let filter = F::from_world(world)
  let (data_access, filter_access) = @ecs.query_access_descriptor(
    filter,
    fn(data_access : @ecs.QueryDataAccess) { D::collect_access(data_access) },
    collect_required_data_components=fn(data_access) {
      D::collect_required_components(data_access)
    },
  )
  access.add_query_access(data_access, filter_access)
  access
}

///|
pub struct Single[D, F] {
  value : D
  query : @ecs.Query[D, F]
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
] with fn init_state(world) {
  ignore(world)
  let state = query_param_state_new()
  SystemParamState::new(
    fn() raise {
      let query : @ecs.Query[D, F] = query_param_query_from_state(state)
      let value = query.require_single()
      Single::{ value, query }
    },
    fn(value : Single[D, F]) {
      query_param_store_query_state(value.query, state)
    },
  )
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with fn get(state) {
  state.get()
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with fn store(self, state) {
  state.store(self)
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with fn access(world) {
  let access = SystemAccess::new()
  let filter = F::from_world(world)
  let (data_access, filter_access) = @ecs.query_access_descriptor(
    filter,
    fn(data_access : @ecs.QueryDataAccess) { D::collect_access(data_access) },
    collect_required_data_components=fn(data_access) {
      D::collect_required_components(data_access)
    },
  )
  access.add_query_access(data_access, filter_access)
  access
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with fn init_state(world) {
  ignore(world)
  let state = query_param_state_new()
  SystemParamState::new(
    fn() raise {
      let query : @ecs.Query[D, F] = query_param_query_from_state(state)
      if query.count() == 0 {
        raise @ecs.Skipped("Expected at least one matching entity")
      }
      Populated::{ query, }
    },
    fn(value : Populated[D, F]) {
      query_param_store_query_state(value.query, state)
    },
  )
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with fn get(state) {
  state.get()
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with fn store(self, state) {
  state.store(self)
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with fn access(world) {
  let access = SystemAccess::new()
  let filter = F::from_world(world)
  let (data_access, filter_access) = @ecs.query_access_descriptor(
    filter,
    fn(data_access : @ecs.QueryDataAccess) { D::collect_access(data_access) },
    collect_required_data_components=fn(data_access) {
      D::collect_required_components(data_access)
    },
  )
  access.add_query_access(data_access, filter_access)
  access
}
