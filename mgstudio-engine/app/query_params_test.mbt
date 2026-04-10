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
} derive(Eq, Debug)

///|
struct QueryVelocity {
  mut dx : Int
  mut dy : Int
} derive(Eq, Debug)

///|
struct QueryMarker {} derive(Eq, Debug)

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
struct QueryGenericData {
  entity : @core.Entity
  position : QueryPosition
  has_disabled : Bool
}

///|
pub impl @ecs.QueryData for QueryGenericData with matches(world, entity) {
  @ecs.query_data_component_matches(world, entity, query_position_key)
}

///|
pub impl @ecs.QueryData for QueryGenericData with fetch(world, entity) {
  {
    entity,
    position: try! @ecs.query_data_component_fetch(
      world, entity, query_position_key,
    ),
    has_disabled: @ecs.query_data_component_has(
      world, entity, @ecs.ecs_key_disabled,
    ),
  }
}

///|
pub impl @ecs.QueryData for QueryGenericData with mentions_component(
  component_id,
) {
  component_id == query_position_key.id() ||
  component_id == @ecs.ecs_key_disabled.id()
}

///|
pub impl @ecs.QueryData for QueryGenericData with iteration_anchor_component() {
  Some(query_position_key.id())
}

///|
pub impl @ecs.QueryData for QueryGenericData with contiguous_compatible() {
  true
}

///|
struct QueryMarkerFilter {}

///|
pub impl @ecs.QueryFilter for QueryMarkerFilter with matches(
  self,
  world,
  entity,
) {
  ignore(self)
  try! world.contains_by_key(entity, query_marker_key)
}

///|
pub impl @ecs.QueryFilter for QueryMarkerFilter with mentions_component(
  self,
  component_id,
) {
  ignore(self)
  component_id == query_marker_key.id()
}

///|
pub impl @ecs.QueryFilter for QueryMarkerFilter with iteration_anchor_component(
  self,
) {
  ignore(self)
  Some(query_marker_key.id())
}

///|
pub impl FromWorld for QueryMarkerFilter with from_world(_world) {
  QueryMarkerFilter::{  }
}

///|
test "app: Query1 system param exposes plain mutable query" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  try! world.set_by_key(e0, query_position_key, QueryPosition::{ x: 1, y: 2 })
  try! world.set_by_key(e1, query_position_key, QueryPosition::{ x: 3, y: 4 })

  let counts : Array[Int] = []
  let mut app = App::new(world).add_system_param(fn(
    query : @ecs.Query[@ecs.Mut[QueryPosition], @ecs.All],
  ) {
    counts.push(query.count())
    try! query.view(fn(_entity, position) {
      position.get_ref().val.x = position.get_ref().val.x + 10
    })
  })

  app = app.run_once()
  app = app.run_once()

  debug_inspect(counts, content="[2, 2]")
  debug_inspect(
    try! app.world().get_by_key(e0, query_position_key),
    content="Some({x: 21, y: 2})",
  )
  debug_inspect(
    try! app.world().get_by_key(e1, query_position_key),
    content="Some({x: 23, y: 4})",
  )
}

///|
test "app: filtered query system param builds filters from component owners" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set_by_key(e0, query_position_key, QueryPosition::{ x: 1, y: 1 })
  try! world.set_by_key(e0, query_velocity_key, QueryVelocity::{
    dx: 10,
    dy: 20,
  })
  try! world.set_by_key(e1, query_position_key, QueryPosition::{ x: 2, y: 2 })
  try! world.set_by_key(e1, query_velocity_key, QueryVelocity::{
    dx: 30,
    dy: 40,
  })
  try! world.set_by_key(e1, query_marker_key, QueryMarker::{  })

  let hit_counts : Array[Int] = []
  let mut app = App::new(world).add_system_param(fn(
    query : @ecs.Query[
      (@ecs.Comp[QueryPosition], @ecs.Mut[QueryVelocity]),
      @ecs.Without[QueryMarker],
    ],
  ) {
    hit_counts.push(query.count())
    try! query
    .par_iter()
    .for_each(fn(_entity, data) {
      let (position, velocity) = data
      velocity.get_ref().val.dx = velocity.get_ref().val.dx + position.value().x
    })
  })

  app = app.run_once()

  debug_inspect(hit_counts, content="[1]")
  debug_inspect(
    try! app.world().get_by_key(e0, query_velocity_key),
    content="Some({dx: 11, dy: 20})",
  )
  debug_inspect(
    try! app.world().get_by_key(e1, query_velocity_key),
    content="Some({dx: 30, dy: 40})",
  )
}

///|
test "app: optional query system param preserves some and none branches" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set_by_key(e0, query_position_key, QueryPosition::{ x: 1, y: 2 })
  try! world.set_by_key(e0, query_velocity_key, QueryVelocity::{ dx: 3, dy: 4 })
  try! world.set_by_key(e0, query_marker_key, QueryMarker::{  })
  try! world.set_by_key(e1, query_position_key, QueryPosition::{ x: 5, y: 6 })
  try! world.set_by_key(e1, query_velocity_key, QueryVelocity::{ dx: 7, dy: 8 })

  let seen : Array[(Int, Bool)] = []
  let counts : Array[Int] = []
  let mut app = App::new(world).add_system_param(fn(
    query : @ecs.Query[
      (
        @ecs.Comp[QueryPosition],
        @ecs.Mut[QueryVelocity],
        @ecs.Comp[QueryMarker]?,
      ),
      @ecs.All,
    ],
  ) {
    counts.push(query.count())
    try! query.view(fn(entity, data) {
      let (position, velocity, marker) = data
      seen.push((entity.id, marker is Some(_)))
      velocity.get_ref().val.dy = velocity.get_ref().val.dy + position.value().y
    })
  })

  app = app.run_once()

  debug_inspect(counts, content="[2]")
  debug_inspect(seen, content="[(0, true), (1, false)]")
  debug_inspect(
    try! app.world().get_by_key(e0, query_velocity_key),
    content="Some({dx: 3, dy: 6})",
  )
  debug_inspect(
    try! app.world().get_by_key(e1, query_velocity_key),
    content="Some({dx: 7, dy: 14})",
  )
}

///|
test "app: Allow, Query2Has and Query2Optional system params honor disabling semantics" {
  let world = @ecs.World::new()
  let enabled = world.spawn()
  let disabled = world.spawn()

  try! world.set_by_key(enabled, query_position_key, QueryPosition::{
    x: 1,
    y: 1,
  })
  try! world.set_by_key(disabled, query_position_key, QueryPosition::{
    x: 2,
    y: 2,
  })
  try! world.set_by_key(disabled, @ecs.ecs_key_disabled, @ecs.Disabled::new())

  let entity_counts : Array[Int] = []
  let has_seen : Array[(Int, Bool)] = []
  let optional_seen : Array[(Int, Bool)] = []

  let mut app = App::new(world).add_systems(
    Update,
    system(
      system_param3(fn(
        visible_entities : @ecs.Query[@core.Entity, @ecs.Allow[@ecs.Disabled]],
        has_query : @ecs.Query[
          (@ecs.Comp[QueryPosition], @ecs.Has[@ecs.Disabled]),
          @ecs.All,
        ],
        optional_query : @ecs.Query[
          (@ecs.Comp[QueryPosition], @ecs.Comp[@ecs.Disabled]?),
          @ecs.All,
        ],
      ) {
        entity_counts.push(visible_entities.count())
        try! has_query.view(fn(entity, data) {
          let (_, has_disabled) = data
          has_seen.push((entity.id, has_disabled.present()))
        })
        try! optional_query.view(fn(entity, data) {
          let (_, maybe_disabled) = data
          optional_seen.push((entity.id, maybe_disabled is Some(_)))
        })
      }),
    ),
  )

  app = app.run_once()

  debug_inspect(entity_counts, content="[2]")
  debug_inspect(has_seen, content="[(0, false), (1, true)]")
  debug_inspect(optional_seen, content="[(0, false)]")
}

///|
test "app: validated single query params expose strict single access" {
  let world = @ecs.World::new()
  let entity = world.spawn()
  let other = world.spawn()

  try! world.set_by_key(entity, query_position_key, QueryPosition::{
    x: 1,
    y: 2,
  })
  try! world.set_by_key(entity, query_velocity_key, QueryVelocity::{
    dx: 3,
    dy: 4,
  })
  try! world.set_by_key(other, query_position_key, QueryPosition::{
    x: 10,
    y: 20,
  })

  let entity_ids : Array[Int] = []
  let xs : Array[Int] = []
  let mut app = App::new(world).add_systems(
    Update,
    system(
      system_param3(fn(
        single_entity : Single[
          @core.Entity,
          (@ecs.With[QueryPosition], @ecs.With[QueryVelocity]),
        ],
        single_position : Single[
          @ecs.Comp[QueryPosition],
          @ecs.With[QueryVelocity],
        ],
        single_pair : Single[
          (@ecs.Mut[QueryPosition], @ecs.Comp[QueryVelocity]),
          @ecs.All,
        ],
      ) {
        entity_ids.push(single_entity.get().id)
        xs.push(single_position.get().value().x)
        let (position_mut, velocity_ref) = single_pair.get()
        position_mut.get_ref().val.x = position_mut.get_ref().val.x +
          velocity_ref.value().dx
      }),
    ),
  )

  app = app.run_once()

  debug_inspect(entity_ids, content="[0]")
  debug_inspect(xs, content="[1]")
  debug_inspect(
    try! app.world().get_by_key(entity, query_position_key),
    content="Some({x: 4, y: 2})",
  )
  debug_inspect(
    try! app.world().get_by_key(other, query_position_key),
    content="Some({x: 10, y: 20})",
  )
}

///|
test "app: generic Query[D, F] system param supports named data and named filters" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()
  let e2 = world.spawn()

  try! world.set_by_key(e0, query_position_key, QueryPosition::{ x: 1, y: 1 })
  try! world.set_by_key(e1, query_position_key, QueryPosition::{ x: 2, y: 2 })
  try! world.set_by_key(e2, query_position_key, QueryPosition::{ x: 3, y: 3 })
  try! world.set_by_key(e0, query_marker_key, QueryMarker::{  })
  try! world.set_by_key(e1, query_marker_key, QueryMarker::{  })
  try! world.set_by_key(e1, @ecs.ecs_key_disabled, @ecs.Disabled::new())

  let counts : Array[Int] = []
  let seen : Array[(Int, Bool, Int)] = []

  let mut app = App::new(world).add_system_param(fn(
    query : @ecs.Query[QueryGenericData, QueryMarkerFilter],
  ) {
    counts.push(query.count())
    try! query.view(fn(_entity, value) {
      seen.push((value.entity.id, value.has_disabled, value.position.x))
    })
  })

  app = app.run_once()

  debug_inspect(counts, content="[2]")
  debug_inspect(seen, content="[(0, false, 1), (1, true, 2)]")
}

///|
test "app: PopulatedQuery2MutMut exposes a guaranteed non-empty mutable query" {
  let world = @ecs.World::new()
  let e0 = world.spawn()
  let e1 = world.spawn()

  try! world.set_by_key(e0, query_position_key, QueryPosition::{ x: 1, y: 2 })
  try! world.set_by_key(e0, query_velocity_key, QueryVelocity::{ dx: 3, dy: 4 })
  try! world.set_by_key(e1, query_position_key, QueryPosition::{ x: 5, y: 6 })
  try! world.set_by_key(e1, query_velocity_key, QueryVelocity::{ dx: 7, dy: 8 })

  let counts : Array[Int] = []
  let mut app = App::new(world).add_systems(
    Update,
    system(
      fallible_system_param(fn(
        query_param : Populated[
          (@ecs.Mut[QueryPosition], @ecs.Mut[QueryVelocity]),
          @ecs.All,
        ],
      ) {
        let query = query_param.query()
        counts.push(query.count())
        try! query.view(fn(_entity, data) {
          let (position_mut, velocity_mut) = data
          velocity_mut.get_ref().val.dx = velocity_mut.get_ref().val.dx +
            position_mut.get_ref().val.x
        })
      }),
    ),
  )

  app = app.run_once()

  debug_inspect(counts, content="[2]")
  debug_inspect(
    try! app.world().get_by_key(e0, query_velocity_key),
    content="Some({dx: 4, dy: 4})",
  )
  debug_inspect(
    try! app.world().get_by_key(e1, query_velocity_key),
    content="Some({dx: 12, dy: 8})",
  )
}
