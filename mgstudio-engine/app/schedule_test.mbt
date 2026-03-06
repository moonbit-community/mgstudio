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
test "app: run_if evaluates with condition system ticks" {
  let observed : Array[(Int, Int)] = []
  let system_ran = Ref::new(false)
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { system_ran.val = true }).run_if(fn(
      _world : @ecs.World,
    ) {
      let ticks = current_system_ticks()
      observed.push((ticks.last_run, ticks.this_run))
      false
    }),
  )

  app.run_once() |> ignore
  app.run_once() |> ignore

  inspect(observed.length(), content="2")
  inspect(system_ran.val, content="false")
  inspect(observed[0].0 == 0 && observed[0].1 == 3, content="true")
  inspect(observed[1].0 == 3 && observed[1].1 == 5, content="true")
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
struct TickParam {
  ticks : @core.SystemTicks
}

///|
impl SystemParam for TickParam with init_state(_world) {
  Json::null()
}

///|
impl SystemParam for TickParam with get(_state) {
  { ticks: current_system_ticks() }
}

///|
impl SystemParam for TickParam with store(self, _state) {
  ignore(self)
}

///|
struct TestMessage {
  value : Int
}

///|
let test_messages_ref : Ref[@core.Messages[TestMessage]] = Ref::new(
  @core.Messages::new(),
)

///|
impl @core.Message for TestMessage with reader(ticks) {
  test_messages_ref.val.reader(ticks)
}

///|
impl @core.Message for TestMessage with writer(tick) {
  test_messages_ref.val.writer(tick)
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
test "app: system param can read current system ticks" {
  let log : Array[(Int, Int)] = []
  let app = App::new(@ecs.World::new())
  app
  .add_system_param(fn(param : TickParam) {
    log.push((param.ticks.last_run, param.ticks.this_run))
  })
  .add_system_param(fn(param : TickParam) {
    log.push((param.ticks.last_run, param.ticks.this_run))
  })
  .run_once()
  |> ignore
  inspect(log.length(), content="2")
  inspect(log[0].0 == 0 && log[0].1 == 3, content="true")
  inspect(log[1].0 == 0 && log[1].1 == 4, content="true")
}

///|
test "app: MessageWriter system param writes messages for MessageReader" {
  test_messages_ref.val.clear()
  let observed : Ref[Int] = Ref::new(-1)
  let app = App::new(@ecs.World::new())
    .add_system_param(fn(writer : @core.MessageWriter[TestMessage]) {
      writer.write({ value: 42 })
    })
    .add_system_param(fn(reader : @core.MessageReader[TestMessage]) {
      let messages = reader.read()
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
} derive(Eq, Show, ToJson, FromJson)

///|
struct EcsVelocity {
  x : Int
} derive(Eq, Show, ToJson, FromJson)

///|
test "app: add_system_query2_ecs injects key-based query into update system" {
  let world = @ecs.World::new()
  let comp_position : @ecs.ComponentKey[EcsPosition] = @ecs.register_component(
    debug_name="tests.app.ecs.position",
  )
  let comp_velocity : @ecs.ComponentKey[EcsVelocity] = @ecs.register_component(
    debug_name="tests.app.ecs.velocity",
  )

  let app = App::new(world)
    .add_startup_system(fn(startup_world) {
      let entity = startup_world.spawn()
      try! startup_world.set(entity, comp_position, EcsPosition::{ x: 1 })
      try! startup_world.set(entity, comp_velocity, EcsVelocity::{ x: 41 })
    })
    .add_system_query2_ecs(comp_position, comp_velocity, fn(
      query,
      _update_world,
    ) {
      try! query.for_each(fn(_entity, position, velocity) {
        position.x = position.x + velocity.x
      })
    })
    .run_startup()
    .run_once()

  let query_world = app.world()
  let value_ref : Ref[Int] = Ref::new(0)
  try! query_world
  .query1(comp_position)
  .view(fn(_entity, position) { value_ref.val = position.x })
  inspect(value_ref.val, content="42")
}
