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
struct Name {
  value : String
}

///|
struct NameIndex {
  mut entries : Map[String, @core.Entity]
}

///|
let name_key : @ecs.ComponentKey[Name] = @ecs.register_component(
  debug_name="examples.ecs.immutable_components.Name",
)

///|
let name_index_key : @ecs.ResourceKey[NameIndex] = @ecs.register_resource(
  debug_name="examples.ecs.immutable_components.NameIndex",
)

///|
pub impl @ecs.Component for Name with component() {
  name_key
}

///|
pub impl @app.Resource for NameIndex with resource() {
  name_index_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.insert_resource(NameIndex::{ entries: {} })
  commands.spawn_component(Name::{ value: "Alyssa" }) |> ignore
  commands.spawn_component(Name::{ value: "Javier" }) |> ignore
}

///|
fn rebuild_name_index(
  names : @ecs.Query[(@core.Entity, @ecs.Comp[Name]), @ecs.All],
  index : @app.ResMut[NameIndex],
) -> Unit {
  index.get_ref().val.entries = {}
  try! names.view(fn(_query_entity, data) {
    let (entity, name) = data
    index.get_ref().val.entries[name.value().value] = entity
  })
}

///|
fn rename_one_entity(world : @ecs.World) -> Unit {
  let query : @ecs.Query[(@core.Entity, @ecs.Comp[Name]), @ecs.All] = @ecs.query(
    world,
  )
  let renamed : Ref[Bool] = Ref::new(false)
  try! query.view(fn(_query_entity, data) {
    if renamed.val {
      return
    }
    let (entity, name) = data
    if name.value().value == "Javier" {
      let entity_mut = try! world.entity_mut(entity)
      let removed : Name? = try! entity_mut.remove_component()
      ignore(removed)
      try! (entity_mut.insert_component(Name::{ value: "Steven" }) |> ignore)
      renamed.val = true
    }
  })
}

///|
fn print_index(index : @app.Res[NameIndex]) -> Unit {
  let alyssa = index.get().entries.get("Alyssa")
  let steven = index.get().entries.get("Steven")
  let alyssa_found = if alyssa is Some(_) { "true" } else { "false" }
  let steven_found = if steven is Some(_) { "true" } else { "false" }
  println("Alyssa indexed: \{alyssa_found}")
  println("Steven indexed: \{steven_found}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@app.ScheduleRunnerPlugin::run_once())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(rename_one_entity))
  .add_systems(@app.Update, @app.system(@app.system_param2(rebuild_name_index)))
  .add_systems(@app.Update, @app.system(@app.system_param(print_index)))
  .run()
}
