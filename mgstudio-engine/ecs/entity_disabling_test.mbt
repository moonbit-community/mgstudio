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
struct Dummy {
  label : String
} derive(Eq, Debug, ToJson, FromJson)

///|
struct CustomDisabled {} derive(Eq, Debug, ToJson, FromJson)

///|
let dummy_key : ComponentKey[Dummy] = register_component(
  debug_name="tests.ecs.entity_disabling.Dummy",
)

///|
let custom_disabled_key : ComponentKey[CustomDisabled] = register_component(
  debug_name="tests.ecs.entity_disabling.CustomDisabled",
)

///|
pub impl Component for Dummy with component() {
  dummy_key
}

///|
pub impl Component for CustomDisabled with component() {
  custom_disabled_key
}

///|
test "ecs entity disabling: default queries skip disabled entities" {
  let world = World::new()
  let enabled = world.spawn()
  let disabled = world.spawn()

  try! world.set_by_key(enabled, dummy_key, Dummy::{ label: "enabled" })
  try! world.set_by_key(disabled, dummy_key, Dummy::{ label: "disabled" })
  try! world.set_by_key(disabled, ecs_key_disabled, Disabled::new())

  let dummy_query : @ecs.Query[@ecs.Comp[Dummy], @ecs.All] = @ecs.query(world)
  debug_inspect(dummy_query.count(), content="1")
  debug_inspect(
    match (try! dummy_query.get(enabled)) {
      Some(dummy) => Some(dummy.value())
      None => None
    },
    content="Some({label: \"enabled\"})",
  )
  debug_inspect(
    match (try! dummy_query.get(disabled)) {
      Some(dummy) => Some(dummy.value())
      None => None
    },
    content="None",
  )
  debug_inspect(
    (
      @ecs.query_filtered(world, With::new(ecs_key_disabled)) :
      @ecs.Query[@ecs.Comp[Dummy], @ecs.With[Disabled]]).count(),
    content="1",
  )
  debug_inspect(
    (
      @ecs.query_filtered(world, Allow::new(ecs_key_disabled)) :
      @ecs.Query[@ecs.Comp[Dummy], @ecs.Allow[Disabled]]).count(),
    content="2",
  )
  debug_inspect(world.query_entities_filtered(All::new()).count(), content="1")
  debug_inspect(
    world.query_entities_filtered(With::new(ecs_key_disabled)).count(),
    content="1",
  )
}

///|
test "ecs entity disabling: has counts as explicit mention but optional does not" {
  let world = World::new()
  let enabled = world.spawn()
  let disabled = world.spawn()

  try! world.set_by_key(enabled, dummy_key, Dummy::{ label: "enabled" })
  try! world.set_by_key(disabled, dummy_key, Dummy::{ label: "disabled" })
  try! world.set_by_key(disabled, ecs_key_disabled, Disabled::new())

  let has_query : @ecs.Query[(@ecs.Comp[Dummy], @ecs.Has[Disabled]), @ecs.All] = @ecs.query(
    world,
  )
  let has_disabled : Array[(Int, Bool)] = []
  try! has_query.view(fn(entity, entry) {
    has_disabled.push((entity.id, entry.1.present()))
  })
  debug_inspect(has_disabled, content="[(0, false), (1, true)]")

  let optional_query : @ecs.Query[
    (@ecs.Comp[Dummy], @ecs.Optional[Disabled]),
    @ecs.All,
  ] = @ecs.query(world)
  let optional_disabled : Array[(Int, Bool)] = []
  try! optional_query.view(fn(entity, entry) {
    optional_disabled.push((entity.id, entry.1.value() is Some(_)))
  })
  debug_inspect(optional_disabled, content="[(0, false)]")
}

///|
test "ecs entity disabling: multiple disabling components require explicit mention of all" {
  let world = World::new()
  try! world.register_disabling_component(custom_disabled_key)

  let plain = world.spawn()
  let disabled_only = world.spawn()
  let custom_only = world.spawn()
  let both = world.spawn()

  try! world.set_by_key(plain, dummy_key, Dummy::{ label: "plain" })
  try! world.set_by_key(disabled_only, dummy_key, Dummy::{ label: "disabled" })
  try! world.set_by_key(custom_only, dummy_key, Dummy::{ label: "custom" })
  try! world.set_by_key(both, dummy_key, Dummy::{ label: "both" })

  try! world.set_by_key(disabled_only, ecs_key_disabled, Disabled::new())
  try! world.set_by_key(custom_only, custom_disabled_key, CustomDisabled::{  })
  try! world.set_by_key(both, ecs_key_disabled, Disabled::new())
  try! world.set_by_key(both, custom_disabled_key, CustomDisabled::{  })

  let dummy_query : @ecs.Query[@ecs.Comp[Dummy], @ecs.All] = @ecs.query(world)
  debug_inspect(dummy_query.count(), content="1")
  debug_inspect(
    (
      @ecs.query_filtered(world, With::new(ecs_key_disabled)) :
      @ecs.Query[@ecs.Comp[Dummy], @ecs.With[Disabled]]).count(),
    content="1",
  )
  debug_inspect(
    (
      @ecs.query(world) :
      @ecs.Query[(@ecs.Comp[Dummy], @ecs.Has[Disabled]), @ecs.All]).count(),
    content="2",
  )
  debug_inspect(
    (
      @ecs.query_filtered(world, With::new(custom_disabled_key)) :
      @ecs.Query[@ecs.Comp[Dummy], @ecs.With[CustomDisabled]]).count(),
    content="1",
  )
  debug_inspect(
    (
      @ecs.query(world) :
      @ecs.Query[(@ecs.Comp[Dummy], @ecs.Has[CustomDisabled]), @ecs.All]).count(),
    content="2",
  )
  debug_inspect(
    (
      @ecs.query_filtered(
        world,
        (Allow::new(ecs_key_disabled), Allow::new(custom_disabled_key)),
      ) :
      @ecs.Query[
        @ecs.Comp[Dummy],
        (@ecs.Allow[Disabled], @ecs.Allow[CustomDisabled]),
      ]).count(),
    content="4",
  )
  debug_inspect(
    (
      @ecs.query_filtered(
        world,
        (With::new(ecs_key_disabled), With::new(custom_disabled_key)),
      ) :
      @ecs.Query[
        @ecs.Comp[Dummy],
        (@ecs.With[Disabled], @ecs.With[CustomDisabled]),
      ]).count(),
    content="1",
  )
}
