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
  let app = App::new(TestWorld::new()).add_system_config(
    system(fn(_world : TestWorld) { log.push(1) }).run_if(fn(
      _world : TestWorld,
    ) {
      false
    }),
  )
  app.run_once() |> ignore
  inspect(log.length(), content="0")
}

///|
test "app: schedule sets order and preserve insertion within a set" {
  let log : Array[Int] = []
  let set_a = system_set("A")
  let set_b = system_set("B")
  let app = App::new(TestWorld::new())
  app
  .add_system_config(
    system(fn(_world : TestWorld) { log.push(1) }).in_set(set_a),
  )
  .add_system_config(
    system(fn(_world : TestWorld) { log.push(2) }).in_set(set_a),
  )
  .add_system_config(
    system(fn(_world : TestWorld) { log.push(3) }).in_set(set_b),
  )
  .configure_set(Update, set_a, before=[set_b])
  .run_once()
  |> ignore
  inspect(
    log.length() == 3 && log[0] == 1 && log[1] == 2 && log[2] == 3,
    content="true",
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
impl SystemParam for Param1 with get() {
  { value: 1 }
}

///|
impl SystemParam for Param2 with get() {
  { value: 2 }
}

///|
impl SystemParam for Param3 with get() {
  { value: 3 }
}

///|
impl SystemParam for Param4 with get() {
  { value: 4 }
}

///|
struct TickParam {
  ticks : @core.SystemTicks
}

///|
impl SystemParam for TickParam with get() {
  { ticks: current_system_ticks() }
}

///|
test "app: add_system_param4 injects parameters in order" {
  let log : Array[Int] = []
  let app = App::new(TestWorld::new()).add_system_param4(fn(
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
  let app = App::new(TestWorld::new())
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
  inspect(log[0].0 == 0 && log[0].1 == 1, content="true")
  inspect(log[1].0 == 0 && log[1].1 == 2, content="true")
}
