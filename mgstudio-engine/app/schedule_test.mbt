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
test "app: run_if skips system execution" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { log.push(1) }).run_if(fn(
      _world : @ecs.World,
    ) {
      false
    }),
  )
  app.run_once() |> ignore
  inspect(log.length(), content="0")
}

///|
test "app: run_if evaluates with condition system sequence" {
  let observed : Array[(Int, Int)] = []
  let system_ran = Ref::new(false)
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { system_ran.val = true }).run_if(fn(
      _world : @ecs.World,
    ) {
      let sequence = current_system_sequence()
      observed.push((sequence.last_run, sequence.this_run))
      false
    }),
  )

  app.run_once() |> ignore
  app.run_once() |> ignore

  inspect(observed.length(), content="2")
  inspect(system_ran.val, content="false")
  inspect(observed[0].0 == 0 && observed[0].1 == 3, content="true")
  inspect(observed[1].0 == 3 && observed[1].1 == 6, content="true")
}

///|
test "app: repeated run_if composes and short-circuits" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { log.push("system") })
    .run_if(fn(_world : @ecs.World) {
      log.push("first")
      false
    })
    .run_if(fn(_world : @ecs.World) {
      log.push("second")
      true
    }),
  )

  app.run_once() |> ignore

  inspect(log.join(","), content="first")
}

///|
test "app: repeated run_if_stateful keeps independent condition state" {
  let first_seen : Array[Int] = []
  let second_seen : Array[Int] = []
  let system_runs = Ref::new(0)
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { system_runs.val = system_runs.val + 1 })
    .run_if_stateful((0).to_json(), fn(_world : @ecs.World, state : Ref[Json]) {
      let value : Int = try! @json.from_json(state.val)
      first_seen.push(value)
      state.val = (value + 1).to_json()
      true
    })
    .run_if_stateful((100).to_json(), fn(
      _world : @ecs.World,
      state : Ref[Json],
    ) {
      let value : Int = try! @json.from_json(state.val)
      second_seen.push(value)
      state.val = (value + 10).to_json()
      true
    }),
  )

  app.run_once() |> ignore
  app.run_once() |> ignore

  inspect(system_runs.val, content="2")
  inspect(first_seen[0] == 0 && first_seen[1] == 1, content="true")
  inspect(second_seen[0] == 100 && second_seen[1] == 110, content="true")
}

///|
test "app: add_plugin_group registers grouped plugins" {
  let log : Array[Int] = []
  fn plugin_1(app : App[@ecs.World]) -> App[@ecs.World] {
    app.add_system(fn(_world : @ecs.World) { log.push(1) })
  }
  fn plugin_2(app : App[@ecs.World]) -> App[@ecs.World] {
    app.add_system(fn(_world : @ecs.World) { log.push(2) })
  }
  fn group() -> PluginGroupBuilder[@ecs.World] {
    PluginGroupBuilder::start().add(plugin_1).add(plugin_2)
  }
  let app = App::new(@ecs.World::new()).add_plugin_group(group)
  app.run_once() |> ignore
  inspect(log.length() == 2 && log[0] == 1 && log[1] == 2, content="true")
}

///|
test "app: plugin group set_plugin and disable preserve configured plugins" {
  let log : Array[Int] = []
  fn plugin_1(app : App[@ecs.World]) -> App[@ecs.World] {
    app.add_system(fn(_world : @ecs.World) { log.push(1) })
  }
  fn plugin_1_override(app : App[@ecs.World]) -> App[@ecs.World] {
    app.add_system(fn(_world : @ecs.World) { log.push(10) })
  }
  fn plugin_2(app : App[@ecs.World]) -> App[@ecs.World] {
    app.add_system(fn(_world : @ecs.World) { log.push(2) })
  }

  let group = PluginGroupBuilder::start_named("TestPlugins")
    .add_named(id="plugin_1", plugin_1)
    .add_named(id="plugin_2", plugin_2)
  inspect(group.contains("plugin_1"), content="true")
  inspect(group.enabled("plugin_2"), content="true")

  let app = App::new(@ecs.World::new()).add_plugin_group(fn() {
    group.set_plugin(id="plugin_1", plugin_1_override).disable("plugin_2")
  })
  app.run_once() |> ignore

  inspect(log.length(), content="1")
  inspect(log[0], content="10")
}

///|
test "app: plugin group try_set_plugin raises when id is missing" {
  fn plugin_1(app : App[@ecs.World]) -> App[@ecs.World] {
    app
  }

  let missing_plugin_id = try {
    ignore(
      PluginGroupBuilder::start_named("TestPlugins").try_set_plugin(
        id="missing",
        plugin_1,
      ),
    )
    "ok"
  } catch {
    MissingPlugin(id) => id
  }

  inspect(missing_plugin_id, content="missing")
}

///|
test "app: schedule sets order and preserve insertion within a set" {
  let log : Array[Int] = []
  let set_a = system_set("A")
  let set_b = system_set("B")
  let app = App::new(@ecs.World::new())
  app
  .add_systems(
    Update,
    system(fn(_world : @ecs.World) { log.push(1) }).in_set(set_a),
  )
  .add_systems(
    Update,
    system(fn(_world : @ecs.World) { log.push(2) }).in_set(set_a),
  )
  .add_systems(
    Update,
    system(fn(_world : @ecs.World) { log.push(3) }).in_set(set_b),
  )
  .configure_sets(Update, set_a, before=[set_b])
  .run_once()
  |> ignore
  inspect(
    log.length() == 3 && log[0] == 1 && log[1] == 2 && log[2] == 3,
    content="true",
  )
}

///|
test "app: chained tuple system configs run in declared order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_systems(
    Update,
    (
      system(fn(_world : @ecs.World) { log.push(1) }),
      system(fn(_world : @ecs.World) { log.push(2) }),
      system(fn(_world : @ecs.World) { log.push(3) }),
    )
    |> chain(),
  )
  app.run_once() |> ignore
  inspect(log, content="[1, 2, 3]")
}

///|
test "app: chained tuple preserves per-system run_if evaluation" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new()).add_systems(
    Update,
    (
      system(fn(_world : @ecs.World) { log.push("first") }).run_if(fn(
        _world : @ecs.World,
      ) {
        false
      }),
      system(fn(_world : @ecs.World) { log.push("second") }).run_if(fn(
        _world : @ecs.World,
      ) {
        true
      }),
    )
    |> chain(),
  )
  app.run_once() |> ignore
  inspect(log.join(","), content="second")
}

///|
test "app: Last stage runs after PostUpdate" {
  let log : Array[String] = []
  let app = App::new(@ecs.World::new())
    .add_pre_update_system(fn(_world : @ecs.World) { log.push("pre") })
    .add_system(fn(_world : @ecs.World) { log.push("update") })
    .add_post_update_system(fn(_world : @ecs.World) { log.push("post") })
    .add_last_system(fn(_world : @ecs.World) { log.push("last") })
  app.run_once() |> ignore
  inspect(log.join(","), content="pre,update,post,last")
}

///|
test "app: update runs startup once and update every frame" {
  let log : Array[String] = []
  let mut app = App::new(@ecs.World::new())
    .add_systems(
      PreStartup,
      system(fn(_world : @ecs.World) { log.push("pre_startup") }),
    )
    .add_systems(
      Startup,
      system(fn(_world : @ecs.World) { log.push("startup") }),
    )
    .add_systems(
      PostStartup,
      system(fn(_world : @ecs.World) { log.push("post_startup") }),
    )
    .add_systems(Update, system(fn(_world : @ecs.World) { log.push("update") }))

  app = app.update()
  app = app.update()

  inspect(
    log.join(","),
    content="pre_startup,startup,post_startup,update,update",
  )
}

///|
struct Param1 {
  value : Int
}

///|
struct Param2 {
  value : Int
}

///|
struct Param3 {
  value : Int
}

///|
struct Param4 {
  value : Int
}

///|
struct Param5 {
  value : Int
}

///|
struct Param6 {
  value : Int
}

///|
impl SystemParam for Param1 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param1 with get(_state) {
  { value: 1 }
}

///|
impl SystemParam for Param1 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param2 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param2 with get(_state) {
  { value: 2 }
}

///|
impl SystemParam for Param2 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param3 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param3 with get(_state) {
  { value: 3 }
}

///|
impl SystemParam for Param3 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param4 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param4 with get(_state) {
  { value: 4 }
}

///|
impl SystemParam for Param4 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param5 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param5 with get(_state) {
  { value: 5 }
}

///|
impl SystemParam for Param5 with store(self, _state) {
  ignore(self)
}

///|
impl SystemParam for Param6 with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for Param6 with get(_state) {
  { value: 6 }
}

///|
impl SystemParam for Param6 with store(self, _state) {
  ignore(self)
}

///|
struct SequenceParam {
  sequence : @core.SystemSequence
}

///|
impl SystemParam for SequenceParam with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for SequenceParam with get(_state) {
  { sequence: current_system_sequence() }
}

///|
impl SystemParam for SequenceParam with store(self, _state) {
  ignore(self)
}

///|
struct TestMessage {
  value : Int
}

///|
let test_message_key : @ecs.MessageKey[TestMessage] = @ecs.register_message(
  debug_name="tests.app.TestMessage",
)

///|
impl @ecs.Message for TestMessage with message() {
  test_message_key
}

///|
test "app: add_system_param4 injects parameters in order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system_param4(fn(
    p1 : Param1,
    p2 : Param2,
    p3 : Param3,
    p4 : Param4,
  ) {
    log.push(p1.value)
    log.push(p2.value)
    log.push(p3.value)
    log.push(p4.value)
  })
  app.run_once() |> ignore
  inspect(
    log.length() == 4 &&
    log[0] == 1 &&
    log[1] == 2 &&
    log[2] == 3 &&
    log[3] == 4,
    content="true",
  )
}

///|
test "app: system_param5 injects parameters in order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system(
    system_param5(fn(
      p1 : Param1,
      p2 : Param2,
      p3 : Param3,
      p4 : Param4,
      p5 : Param5,
    ) {
      log.push(p1.value)
      log.push(p2.value)
      log.push(p3.value)
      log.push(p4.value)
      log.push(p5.value)
    }),
  )
  app.run_once() |> ignore
  inspect(
    log.length() == 5 &&
    log[0] == 1 &&
    log[1] == 2 &&
    log[2] == 3 &&
    log[3] == 4 &&
    log[4] == 5,
    content="true",
  )
}

///|
test "app: system_param6 injects parameters in order" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system(
    system_param6(fn(
      p1 : Param1,
      p2 : Param2,
      p3 : Param3,
      p4 : Param4,
      p5 : Param5,
      p6 : Param6,
    ) {
      log.push(p1.value)
      log.push(p2.value)
      log.push(p3.value)
      log.push(p4.value)
      log.push(p5.value)
      log.push(p6.value)
    }),
  )
  app.run_once() |> ignore
  inspect(
    log.length() == 6 &&
    log[0] == 1 &&
    log[1] == 2 &&
    log[2] == 3 &&
    log[3] == 4 &&
    log[4] == 5 &&
    log[5] == 6,
    content="true",
  )
}

///|
test "app: system param can read current system sequence" {
  let log : Array[(Int, Int)] = []
  let app = App::new(@ecs.World::new())
  app
  .add_system_param(fn(param : SequenceParam) {
    log.push((param.sequence.last_run, param.sequence.this_run))
  })
  .add_system_param(fn(param : SequenceParam) {
    log.push((param.sequence.last_run, param.sequence.this_run))
  })
  .run_once()
  |> ignore
  inspect(log.length(), content="2")
  inspect(log[0].0 == 0 && log[0].1 == 3, content="true")
  inspect(log[1].0 == 0 && log[1].1 == 4, content="true")
}

///|
test "app: MessageWriter system param writes messages for MessageReader" {
  let observed : Ref[Int] = Ref::new(-1)
  let app = App::new(@ecs.World::new())
    .add_message(test_message_key)
    .add_system_param(fn(writer : @ecs.MessageWriter[TestMessage]) {
      ignore(writer.write({ value: 42 }))
    })
    .add_system_param(fn(reader : @ecs.MessageReader[TestMessage]) {
      let messages = try! reader.read()
      if messages.length() > 0 {
        observed.val = messages[0].value
      }
    })
  app.run_once() |> ignore
  inspect(observed.val, content="42")
}

///|
struct EcsPosition {
  mut x : Int
} derive(Eq, Show)

///|
struct EcsVelocity {
  x : Int
} derive(Eq, Show)

///|
let ecs_position_key : @ecs.ComponentKey[EcsPosition] = @ecs.register_component(
  debug_name="tests.app.ecs.position",
)

///|
let ecs_velocity_key : @ecs.ComponentKey[EcsVelocity] = @ecs.register_component(
  debug_name="tests.app.ecs.velocity",
)

///|
pub impl @ecs.Component for EcsPosition with component() {
  ecs_position_key
}

///|
pub impl @ecs.Component for EcsVelocity with component() {
  ecs_velocity_key
}

///|
test "app: SystemParam Query2 injects typed query into update system" {
  let world = @ecs.World::new()

  let app = App::new(world)
    .add_startup_system(fn(startup_world) {
      let entity = startup_world.spawn()
      try! startup_world.set_by_key(entity, ecs_position_key, EcsPosition::{
        x: 1,
      })
      try! startup_world.set_by_key(entity, ecs_velocity_key, EcsVelocity::{
        x: 41,
      })
    })
    .add_system_param(fn(
      query : @ecs.Query[
        (@ecs.Mut[EcsPosition], @ecs.Comp[EcsVelocity]),
        @ecs.All,
      ],
    ) {
      try! query.for_each(fn(_entity, data) {
        let (position, velocity) = data
        position.get_ref().val.x = position.get_ref().val.x + velocity.value().x
      })
    })
    .run_startup()
    .run_once()

  let query_world = app.world()
  let value_ref : Ref[Int] = Ref::new(0)
  let query : @ecs.Query[@ecs.Comp[EcsPosition], @ecs.All] = @ecs.query(
    query_world,
  )
  try! query.view(fn(_entity, position) { value_ref.val = position.value().x })
  inspect(value_ref.val, content="42")
}
