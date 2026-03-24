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
struct QueryPosition {
  mut x : Int
  y : Int
} derive(Eq, Show)

///|
struct QueryVelocity {
  mut dx : Int
  mut dy : Int
} derive(Eq, Show)

///|
struct QueryMarker {} derive(Eq, Show)

///|
let query_position_key : @ecs.ComponentKey[QueryPosition] = @ecs.register_component(
  debug_name="tests.app.query_position",
)

///|
let query_velocity_key : @ecs.ComponentKey[QueryVelocity] = @ecs.register_component(
  debug_name="tests.app.query_velocity",
)

///|
let query_marker_key : @ecs.ComponentKey[QueryMarker] = @ecs.register_component(
  debug_name="tests.app.query_marker",
)

///|
pub impl @ecs.Component for QueryPosition with component() {
  query_position_key
}

///|
pub impl @ecs.Component for QueryVelocity with component() {
  query_velocity_key
}

///|
pub impl @ecs.Component for QueryMarker with component() {
  query_marker_key
}

///|
test "app: Query1 system param exposes plain mutable query" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  try! world.set(e0, query_position_key, QueryPosition::{ x: 1, y: 2 })
  try! world.set(e1, query_position_key, QueryPosition::{ x: 3, y: 4 })

  let counts : Array[Int] = []
  let mut app = App::new(world).add_system_param(fn(
    query : @ecs.Query1[QueryPosition],
  ) {
    counts.push(query.count())
    try! query.view_mut(fn(_entity, position) {
      position.get_ref().val.x = position.get_ref().val.x + 10
    })
  })

  app = app.run_once()
  app = app.run_once()

  inspect(counts, content="[2, 2]")
  inspect(
    try! app.world().get(e0, query_position_key),
    content="Some({x: 21, y: 2})",
  )
  inspect(
    try! app.world().get(e1, query_position_key),
    content="Some({x: 23, y: 4})",
  )
}

///|
test "app: filtered query system param builds filters from component owners" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, query_position_key, QueryPosition::{ x: 1, y: 1 })
  try! world.set(e0, query_velocity_key, QueryVelocity::{ dx: 10, dy: 20 })
  try! world.set(e1, query_position_key, QueryPosition::{ x: 2, y: 2 })
  try! world.set(e1, query_velocity_key, QueryVelocity::{ dx: 30, dy: 40 })
  try! world.set(e1, query_marker_key, QueryMarker::{  })

  let hit_counts : Array[Int] = []
  let mut app = App::new(world).add_system_param(fn(
    query : @ecs.Query2ValueMutFiltered[
      QueryPosition,
      QueryVelocity,
      @ecs.Without[QueryMarker],
    ],
  ) {
    hit_counts.push(query.count())
    try! query
    .par_iter_mut()
    .for_each(fn(_entity, position, velocity) {
      velocity.get_ref().val.dx = velocity.get_ref().val.dx + position.x
    })
  })

  app = app.run_once()

  inspect(hit_counts, content="[1]")
  inspect(
    try! app.world().get(e0, query_velocity_key),
    content="Some({dx: 11, dy: 20})",
  )
  inspect(
    try! app.world().get(e1, query_velocity_key),
    content="Some({dx: 30, dy: 40})",
  )
}

///|
test "app: optional query system param preserves some and none branches" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, query_position_key, QueryPosition::{ x: 1, y: 2 })
  try! world.set(e0, query_velocity_key, QueryVelocity::{ dx: 3, dy: 4 })
  try! world.set(e0, query_marker_key, QueryMarker::{  })
  try! world.set(e1, query_position_key, QueryPosition::{ x: 5, y: 6 })
  try! world.set(e1, query_velocity_key, QueryVelocity::{ dx: 7, dy: 8 })

  let seen : Array[(Int, Bool)] = []
  let counts : Array[Int] = []
  let mut app = App::new(world).add_system_param(fn(
    query : @ecs.Query3RefMutOptionalFiltered[
      QueryPosition,
      QueryVelocity,
      QueryMarker,
      @ecs.All,
    ],
  ) {
    counts.push(query.count())
    try! query.view_mut(fn(entity, position, velocity, marker) {
      seen.push((entity.id, marker is Some(_)))
      velocity.get_ref().val.dy = velocity.get_ref().val.dy + position.value().y
    })
  })

  app = app.run_once()

  inspect(counts, content="[2]")
  inspect(seen, content="[(0, true), (1, false)]")
  inspect(
    try! app.world().get(e0, query_velocity_key),
    content="Some({dx: 3, dy: 6})",
  )
  inspect(
    try! app.world().get(e1, query_velocity_key),
    content="Some({dx: 7, dy: 14})",
  )
}

///|
test "app: Allow, Query2Has and Query2Optional system params honor disabling semantics" {
  let world = @ecs.World::new()
  let enabled = world.spawn()
  let disabled = world.spawn()

  try! world.set(enabled, query_position_key, QueryPosition::{ x: 1, y: 1 })
  try! world.set(disabled, query_position_key, QueryPosition::{ x: 2, y: 2 })
  try! world.set(disabled, @ecs.ecs_key_disabled, @ecs.Disabled::new())

  let entity_counts : Array[Int] = []
  let has_seen : Array[(Int, Bool)] = []
  let optional_seen : Array[(Int, Bool)] = []

  let mut app = App::new(world).add_systems(
    Update,
    system(
      system_param3(fn(
        visible_entities : @ecs.EntityQuery[@ecs.Allow[@ecs.Disabled]],
        has_query : @ecs.Query2Has[QueryPosition, @ecs.Disabled],
        optional_query : @ecs.Query2Optional[QueryPosition, @ecs.Disabled],
      ) {
        entity_counts.push(visible_entities.count())
        try! has_query.view(fn(entity, _position, has_disabled) {
          has_seen.push((entity.id, has_disabled))
        })
        try! optional_query.view(fn(entity, _position, maybe_disabled) {
          optional_seen.push((entity.id, maybe_disabled is Some(_)))
        })
      }),
    ),
  )

  app = app.run_once()

  inspect(entity_counts, content="[2]")
  inspect(has_seen, content="[(0, false), (1, true)]")
  inspect(optional_seen, content="[(0, false)]")
}

///|
test "app: validated single query params expose strict single access" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  let other = world.spawn()

  try! world.set(entity, query_position_key, QueryPosition::{ x: 1, y: 2 })
  try! world.set(entity, query_velocity_key, QueryVelocity::{ dx: 3, dy: 4 })
  try! world.set(other, query_position_key, QueryPosition::{ x: 10, y: 20 })

  let entity_ids : Array[Int] = []
  let xs : Array[Int] = []
  let mut app = App::new(world).add_systems(
    Update,
    system(
      system_param3(fn(
        single_entity : SingleEntityFiltered[
          (@ecs.With[QueryPosition], @ecs.With[QueryVelocity]),
        ],
        single_position : SingleQuery1Filtered[
          QueryPosition,
          @ecs.With[QueryVelocity],
        ],
        single_pair : SingleQuery2MutRef[QueryPosition, QueryVelocity],
      ) {
        entity_ids.push(single_entity.get().id)
        xs.push(single_position.get().x)
        let (position_mut, velocity_ref) = single_pair.get()
        position_mut.get_ref().val.x = position_mut.get_ref().val.x +
          velocity_ref.value().dx
      }),
    ),
  )

  app = app.run_once()

  inspect(entity_ids, content="[0]")
  inspect(xs, content="[1]")
  inspect(
    try! app.world().get(entity, query_position_key),
    content="Some({x: 4, y: 2})",
  )
  inspect(
    try! app.world().get(other, query_position_key),
    content="Some({x: 10, y: 20})",
  )
}

///|
test "app: PopulatedQuery2MutMut exposes a guaranteed non-empty mutable query" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set(e0, query_position_key, QueryPosition::{ x: 1, y: 2 })
  try! world.set(e0, query_velocity_key, QueryVelocity::{ dx: 3, dy: 4 })
  try! world.set(e1, query_position_key, QueryPosition::{ x: 5, y: 6 })
  try! world.set(e1, query_velocity_key, QueryVelocity::{ dx: 7, dy: 8 })

  let counts : Array[Int] = []
  let mut app = App::new(world).add_systems(
    Update,
    system(
      fallible_system_param(fn(
        query_param : PopulatedQuery2MutMut[QueryPosition, QueryVelocity],
      ) raise {
        let query = query_param.query()
        counts.push(query.count())
        try! query.view_mut(fn(_entity, position_mut, velocity_mut) {
          velocity_mut.get_ref().val.dx = velocity_mut.get_ref().val.dx +
            position_mut.get_ref().val.x
        })
      }),
    ),
  )

  app = app.run_once()

  inspect(counts, content="[2]")
  inspect(
    try! app.world().get(e0, query_velocity_key),
    content="Some({dx: 4, dy: 4})",
  )
  inspect(
    try! app.world().get(e1, query_velocity_key),
    content="Some({dx: 12, dy: 8})",
  )
}
