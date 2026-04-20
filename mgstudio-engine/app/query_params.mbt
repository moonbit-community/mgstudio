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
let query_param_next_slot_ref : Ref[Int] = Ref::new(1)

///|
let query_param_cache_by_slot : @hashmap.HashMap[Int, @ecs.QueryCache] = @hashmap.HashMap::new()

///|
fn query_param_allocate_slot() -> Int {
  let slot = query_param_next_slot_ref.val
  query_param_next_slot_ref.val = slot + 1
  query_param_cache_by_slot.set(slot, @ecs.QueryCache::new())
  slot
}

///|
fn query_param_slot_from_state(state : Ref[Json]) -> Int {
  try @json.from_json(state.val) catch {
    _ => {
      let slot = query_param_allocate_slot()
      state.val = slot.to_json()
      slot
    }
  } noraise {
    value => value
  }
}

///|
fn query_param_cache_for_slot(slot : Int) -> @ecs.QueryCache {
  match query_param_cache_by_slot.get(slot) {
    Some(cache) => cache
    None => {
      let cache = @ecs.QueryCache::new()
      query_param_cache_by_slot.set(slot, cache)
      cache
    }
  }
}

///|
fn[D, F : FromWorld] query_param_query_from_state(
  state : Ref[Json],
) -> @ecs.Query[D, F] {
  let world = system_param_abort_missing_world()
  let filter = F::from_world(world)
  let slot = query_param_slot_from_state(state)
  @ecs.query_filtered_with_cache(
    world,
    filter,
    query_param_cache_for_slot(slot),
  )
}

///|
fn[D, F] query_param_store_query_state(
  query : @ecs.Query[D, F],
  state : Ref[Json],
) -> Unit {
  let slot = query_param_slot_from_state(state)
  query_param_cache_by_slot.set(slot, query.cache_snapshot())
}

///|
pub impl[D, F : FromWorld] SystemParam for @ecs.Query[D, F] with init_state(
  _world,
) {
  query_param_allocate_slot().to_json()
}

///|
pub impl[D, F : FromWorld] SystemParam for @ecs.Query[D, F] with get(state) {
  query_param_query_from_state(state)
}

///|
pub impl[D, F : FromWorld] SystemParam for @ecs.Query[D, F] with store(
  self,
  state,
) {
  query_param_store_query_state(self, state)
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
] with init_state(world) {
  ignore(world)
  query_param_allocate_slot().to_json()
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with get(state) {
  let query : @ecs.Query[D, F] = query_param_query_from_state(state)
  let value = query.require_single()
  Single::{ value, query }
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Single[
  D,
  F,
] with store(self, state) {
  query_param_store_query_state(self.query, state)
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with init_state(world) {
  ignore(world)
  query_param_allocate_slot().to_json()
}

///|
pub impl[D : @ecs.QueryData, F : FromWorld + @ecs.QueryFilter] SystemParam for Populated[
  D,
  F,
] with get(state) {
  let query : @ecs.Query[D, F] = query_param_query_from_state(state)
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
  query_param_store_query_state(self.query, state)
}
