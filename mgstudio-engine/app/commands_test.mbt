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
struct CommandsPosition {
  x : Int
  y : Int
} derive(Eq, Show)

///|
struct CommandsVelocity {
  dx : Int
  dy : Int
} derive(Eq, Show)

///|
struct CommandsMarker {} derive(Eq, Show)

///|
let commands_position_key : @ecs.ComponentKey[CommandsPosition] = @ecs.register_component(
  debug_name="tests.app.commands_position",
)

///|
let commands_velocity_key : @ecs.ComponentKey[CommandsVelocity] = @ecs.register_component(
  debug_name="tests.app.commands_velocity",
)

///|
let commands_marker_key : @ecs.ComponentKey[CommandsMarker] = @ecs.register_component(
  debug_name="tests.app.commands_marker",
)

///|
pub impl @ecs.Component for CommandsPosition with component() {
  commands_position_key
}

///|
pub impl @ecs.Component for CommandsVelocity with component() {
  commands_velocity_key
}

///|
pub impl @ecs.Component for CommandsMarker with component() {
  commands_marker_key
}

///|
test "app: Commands spawn defers component tuple insertion until after system" {
  let counts : Array[Int] = []
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let mut app = App::new(@ecs.World::new())
    .add_system_param2(fn(
      commands : Commands,
      query : @ecs.Query1[CommandsPosition],
    ) {
      counts.push(query.count())
      spawned.val = Some(
        commands.spawn(
          (
            CommandsPosition::{ x: 3, y: 4 },
            CommandsVelocity::{ dx: 5, dy: 6 },
            CommandsMarker::{  },
          ),
        ),
      )
      counts.push(query.count())
    })
    .add_system_param(fn(query : @ecs.Query1[CommandsPosition]) {
      counts.push(query.count())
    })

  app = app.run_once()

  inspect(counts, content="[0, 0, 1]")
  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(
    try! app.world().get(entity, commands_position_key),
    content="Some({x: 3, y: 4})",
  )
  inspect(
    try! app.world().get(entity, commands_velocity_key),
    content="Some({dx: 5, dy: 6})",
  )
  inspect(try! app.world().get(entity, commands_marker_key), content="Some({})")
}

///|
test "app: Commands spawn_empty reserves an entity without queued components" {
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let mut app = App::new(@ecs.World::new()).add_system_param(fn(
    commands : Commands,
  ) {
    spawned.val = Some(commands.spawn_empty())
  })

  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn_empty to return an entity")
  }
  inspect(app.world().is_alive(entity), content="true")
  inspect(try! app.world().get(entity, commands_position_key), content="None")
}
