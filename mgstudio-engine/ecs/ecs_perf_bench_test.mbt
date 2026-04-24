// Copyright 2026 International Digital Economy Academy
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
struct BenchPosition {
  x : Int
  y : Int
}

///|
struct BenchVelocity {
  dx : Int
  dy : Int
}

///|
struct BenchHealth {
  hp : Int
}

///|
struct BenchMass {
  value : Int
}

///|
struct BenchSparseTag {
  id : Int
}

///|
let bench_position_key : ComponentKey[BenchPosition] = register_component(
  debug_name="bench.ecs.Position",
)

///|
let bench_velocity_key : ComponentKey[BenchVelocity] = register_component(
  debug_name="bench.ecs.Velocity",
)

///|
let bench_health_key : ComponentKey[BenchHealth] = register_component(
  debug_name="bench.ecs.Health",
)

///|
let bench_mass_key : ComponentKey[BenchMass] = register_component(
  debug_name="bench.ecs.Mass",
)

///|
let bench_sparse_tag_key : ComponentKey[BenchSparseTag] = register_component(
  debug_name="bench.ecs.SparseTag",
)

///|
pub impl Component for BenchPosition with component() {
  bench_position_key
}

///|
pub impl Component for BenchVelocity with component() {
  bench_velocity_key
}

///|
pub impl Component for BenchHealth with component() {
  bench_health_key
}

///|
pub impl Component for BenchMass with component() {
  bench_mass_key
}

///|
pub impl Component for BenchSparseTag with component() {
  bench_sparse_tag_key
}

///|
let bench_sparse_tag_metadata_initialized : Ref[Bool] = Ref::new(false)

///|
fn ecs_bench_ensure_sparse_tag_metadata_registered() -> Unit {
  if bench_sparse_tag_metadata_initialized.val {
    return
  }
  ignore(component_metadata_builder(bench_sparse_tag_key).storage_sparse_set())
  bench_sparse_tag_metadata_initialized.val = true
}

///|
fn ecs_bench_make_position(index : Int) -> BenchPosition {
  { x: index, y: index + 1 }
}

///|
fn ecs_bench_make_velocity(index : Int) -> BenchVelocity {
  { dx: index + 2, dy: index + 3 }
}

///|
fn ecs_bench_make_health(index : Int) -> BenchHealth {
  { hp: 100 - index % 13 }
}

///|
fn ecs_bench_make_mass(index : Int) -> BenchMass {
  { value: 1 + index % 7 }
}

///|
fn ecs_bench_make_sparse_tag(index : Int) -> BenchSparseTag {
  { id: index }
}

///|
fn ecs_bench_seed_dense_world(entity_count : Int) -> World raise EcsError {
  let world = World::new()
  for index = 0; index < entity_count; index = index + 1 {
    ignore(
      world.spawn_bundle(
        (
          ecs_bench_make_position(index),
          ecs_bench_make_velocity(index),
          ecs_bench_make_health(index),
          ecs_bench_make_mass(index),
        ),
      ),
    )
  }
  world
}

///|
fn ecs_bench_seed_insert_world(
  entity_count : Int,
) -> (World, Array[@core.Entity]) raise EcsError {
  let world = World::new()
  let entities = []
  for index = 0; index < entity_count; index = index + 1 {
    let entity = world.spawn_bundle(
      (
        ecs_bench_make_position(index),
        ecs_bench_make_health(index),
        ecs_bench_make_mass(index),
      ),
    )
    entities.push(entity)
  }
  (world, entities)
}

///|
fn ecs_bench_seed_sparse_world(entity_count : Int) -> World raise EcsError {
  ecs_bench_ensure_sparse_tag_metadata_registered()
  let world = World::new()
  for index = 0; index < entity_count; index = index + 1 {
    let entity = world.spawn_bundle(
      (
        ecs_bench_make_position(index),
        ecs_bench_make_velocity(index),
        ecs_bench_make_health(index),
      ),
    )
    if index % 4 == 0 {
      world.set(entity, ecs_bench_make_sparse_tag(index))
    }
  }
  world
}

///|
fn ecs_bench_dense_query_sum(
  world : World,
  cache : QueryCache,
) -> Int raise EcsError {
  let query : Query[
    (
      Comp[BenchPosition],
      Comp[BenchVelocity],
      Comp[BenchHealth],
      Comp[BenchMass],
    ),
    All,
  ] = query_filtered_with_cache(world, All::new(), cache)
  let total = Ref::new(0)
  query.for_each(fn(_entity, data) {
    let (position, velocity, health, mass) = data
    total.val = total.val +
      position.value().x +
      position.value().y +
      velocity.value().dx +
      velocity.value().dy +
      health.value().hp +
      mass.value().value
  })
  total.val
}

///|
fn ecs_bench_dense_query_state_iter_sum(
  world : World,
  state : QueryState[
    (
      Comp[BenchPosition],
      Comp[BenchVelocity],
      Comp[BenchHealth],
      Comp[BenchMass],
    ),
    All,
  ],
) -> Int {
  let total = Ref::new(0)
  let iter = state.iter(world)
  while (try! iter.fetch_next()) is Some((_entity, data)) {
    let (position, velocity, health, mass) = data
    total.val = total.val +
      position.value().x +
      position.value().y +
      velocity.value().dx +
      velocity.value().dy +
      health.value().hp +
      mass.value().value
  }
  total.val
}

///|
fn ecs_bench_sparse_query_sum(
  world : World,
  cache : QueryCache,
) -> Int raise EcsError {
  let query : Query[
    (Comp[BenchPosition], Comp[BenchSparseTag]),
    With[BenchSparseTag],
  ] = query_filtered_with_cache(world, With::new(bench_sparse_tag_key), cache)
  let total = Ref::new(0)
  query.for_each(fn(_entity, data) {
    let (position, sparse_tag) = data
    total.val = total.val +
      position.value().x +
      position.value().y +
      sparse_tag.value().id
  })
  total.val
}

///|
test "bench ecs: spawn dense bundle" (b : @bench.T) {
  let entity_count = 5_000
  b.bench(name="spawn_bundle dense x5000", count=10U, () => {
    let world = try! ecs_bench_seed_dense_world(entity_count)
    b.keep(world.entity_count())
    b.keep(world.structural_generation())
  })
}

///|
test "bench ecs: insert component migration" (b : @bench.T) {
  let entity_count = 5_000
  b.bench(name="insert velocity migration x5000", count=10U, () => {
    let (world, entities) = try! ecs_bench_seed_insert_world(entity_count)
    for index = 0; index < entities.length(); index = index + 1 {
      let entity = entities[index]
      let entity_mut = try! world.entity_mut(entity)
      ignore(try! entity_mut.insert_component(ecs_bench_make_velocity(index)))
    }
    b.keep(world.entity_count())
    b.keep(world.structural_generation())
  })
}

///|
test "bench ecs: query dense cached" (b : @bench.T) {
  let world = try! ecs_bench_seed_dense_world(20_000)
  let cache = QueryCache::new()
  b.bench(name="query dense cached x20000", count=100U, () => {
    b.keep(try! ecs_bench_dense_query_sum(world, cache))
  })
}

///|
test "bench ecs: query dense state iter cached" (b : @bench.T) {
  let world = try! ecs_bench_seed_dense_world(20_000)
  let state : QueryState[
    (
      Comp[BenchPosition],
      Comp[BenchVelocity],
      Comp[BenchHealth],
      Comp[BenchMass],
    ),
    All,
  ] = world.query()
  b.bench(name="query dense state iter cached x20000", count=100U, () => {
    b.keep(ecs_bench_dense_query_state_iter_sum(world, state))
  })
}

///|
test "bench ecs: query sparse filter cached" (b : @bench.T) {
  let world = try! ecs_bench_seed_sparse_world(20_000)
  let cache = QueryCache::new()
  b.bench(name="query sparse filter cached x20000", count=100U, () => {
    b.keep(try! ecs_bench_sparse_query_sum(world, cache))
  })
}
