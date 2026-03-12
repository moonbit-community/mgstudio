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
struct CommandsTagA {} derive(Eq, Show)

///|
struct CommandsTagB {} derive(Eq, Show)

///|
struct CommandsTagC {} derive(Eq, Show)

///|
struct CommandsTagD {} derive(Eq, Show)

///|
struct CommandsTagE {} derive(Eq, Show)

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
let commands_tag_a_key : @ecs.ComponentKey[CommandsTagA] = @ecs.register_component(
  debug_name="tests.app.commands_tag_a",
)

///|
let commands_tag_b_key : @ecs.ComponentKey[CommandsTagB] = @ecs.register_component(
  debug_name="tests.app.commands_tag_b",
)

///|
let commands_tag_c_key : @ecs.ComponentKey[CommandsTagC] = @ecs.register_component(
  debug_name="tests.app.commands_tag_c",
)

///|
let commands_tag_d_key : @ecs.ComponentKey[CommandsTagD] = @ecs.register_component(
  debug_name="tests.app.commands_tag_d",
)

///|
let commands_tag_e_key : @ecs.ComponentKey[CommandsTagE] = @ecs.register_component(
  debug_name="tests.app.commands_tag_e",
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
pub impl @ecs.Component for CommandsTagA with component() {
  commands_tag_a_key
}

///|
pub impl @ecs.Component for CommandsTagB with component() {
  commands_tag_b_key
}

///|
pub impl @ecs.Component for CommandsTagC with component() {
  commands_tag_c_key
}

///|
pub impl @ecs.Component for CommandsTagD with component() {
  commands_tag_d_key
}

///|
pub impl @ecs.Component for CommandsTagE with component() {
  commands_tag_e_key
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

///|
test "app: Commands spawn supports eight-component tuples" {
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let mut app = App::new(@ecs.World::new()).add_system_param(fn(
    commands : Commands,
  ) {
    spawned.val = Some(
      commands.spawn(
        (
          CommandsPosition::{ x: 1, y: 2 },
          CommandsVelocity::{ dx: 3, dy: 4 },
          CommandsMarker::{  },
          CommandsTagA::{  },
          CommandsTagB::{  },
          CommandsTagC::{  },
          CommandsTagD::{  },
          CommandsTagE::{  },
        ),
      ),
    )
  })

  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(
    try! app.world().get(entity, commands_position_key),
    content="Some({x: 1, y: 2})",
  )
  inspect(
    try! app.world().get(entity, commands_velocity_key),
    content="Some({dx: 3, dy: 4})",
  )
  inspect(try! app.world().get(entity, commands_marker_key), content="Some({})")
  inspect(try! app.world().get(entity, commands_tag_a_key), content="Some({})")
  inspect(try! app.world().get(entity, commands_tag_b_key), content="Some({})")
  inspect(try! app.world().get(entity, commands_tag_c_key), content="Some({})")
  inspect(try! app.world().get(entity, commands_tag_d_key), content="Some({})")
  inspect(try! app.world().get(entity, commands_tag_e_key), content="Some({})")
}

///|
test "app: Commands entity insert defers component insertion until flush" {
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let counts : Array[Int] = []
  let mut app = App::new(@ecs.World::new())
    .add_system_param2(fn(
      commands : Commands,
      query : @ecs.Query1[CommandsVelocity],
    ) {
      let entity = commands.spawn(
        (CommandsPosition::{ x: 7, y: 8 }, CommandsMarker::{  }),
      )
      spawned.val = Some(entity)
      counts.push(query.count())
      commands
      .entity(entity)
      .insert((CommandsVelocity::{ dx: 9, dy: 10 }, CommandsTagA::{  }))
      counts.push(query.count())
    })
    .add_system_param(fn(query : @ecs.Query1[CommandsVelocity]) {
      counts.push(query.count())
    })

  app = app.run_once()

  inspect(counts, content="[0, 0, 1]")
  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(
    try! app.world().get(entity, commands_velocity_key),
    content="Some({dx: 9, dy: 10})",
  )
  inspect(try! app.world().get(entity, commands_tag_a_key), content="Some({})")
}

///|
test "app: Commands entity insert_component queues a single component" {
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let mut app = App::new(@ecs.World::new()).add_system_param(fn(
    commands : Commands,
  ) {
    let entity = commands.spawn(
      (CommandsPosition::{ x: 13, y: 14 }, CommandsMarker::{  }),
    )
    spawned.val = Some(entity)
    commands
    .entity(entity)
    .insert_component(CommandsVelocity::{ dx: 15, dy: 16 })
  })

  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(
    try! app.world().get(entity, commands_velocity_key),
    content="Some({dx: 15, dy: 16})",
  )
}

///|
test "app: Commands entity despawn defers entity removal until flush" {
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let alive_counts : Array[Int] = []
  let mut app = App::new(@ecs.World::new())
    .add_system_param(fn(commands : Commands) {
      let entity = commands.spawn(
        (CommandsPosition::{ x: 11, y: 12 }, CommandsMarker::{  }),
      )
      spawned.val = Some(entity)
      alive_counts.push(if commands.world.is_alive(entity) { 1 } else { 0 })
      commands.entity(entity).despawn()
      alive_counts.push(if commands.world.is_alive(entity) { 1 } else { 0 })
    })
    .add_system(fn(world : @ecs.World) {
      guard spawned.val is Some(entity) else {
        alive_counts.push(-1)
        return
      }
      alive_counts.push(if world.is_alive(entity) { 1 } else { 0 })
    })

  app = app.run_once()

  inspect(alive_counts, content="[1, 1, 0]")
  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(app.world().is_alive(entity), content="false")
}

///|
test "app: Commands entity remove and remove_component defer component removal until flush" {
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let mut app = App::new(@ecs.World::new()).add_system_param(fn(
    commands : Commands,
  ) {
    let entity = commands.spawn(
      (
        CommandsPosition::{ x: 21, y: 22 },
        CommandsVelocity::{ dx: 23, dy: 24 },
        CommandsMarker::{  },
      ),
    )
    spawned.val = Some(entity)
    commands.entity(entity).remove_component(commands_velocity_key)
    commands.entity(entity).remove(commands_marker_key)
  })

  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(
    try! app.world().get(entity, commands_position_key),
    content="Some({x: 21, y: 22})",
  )
  inspect(try! app.world().get(entity, commands_velocity_key), content="None")
  inspect(try! app.world().get(entity, commands_marker_key), content="None")
}
