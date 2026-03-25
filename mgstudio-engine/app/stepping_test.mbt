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
const PRE_UPDATE_SYSTEM_NAME : String = "tests.app.stepping.pre_update"

///|
const UPDATE_SYSTEM_ONE_NAME : String = "tests.app.stepping.update_one"

///|
const UPDATE_SYSTEM_TWO_NAME : String = "tests.app.stepping.update_two"

///|
const UPDATE_SYSTEM_THREE_NAME : String = "tests.app.stepping.update_three"

///|
const UPDATE_SYSTEM_FOUR_NAME : String = "tests.app.stepping.update_four"

///|
fn stepping_system_config(
  name : String,
  log : Array[String],
  message : String,
) -> SystemConfig[@ecs.World] {
  system(fn(_world : @ecs.World) { log.push(message) })
  .named(name)
  .in_set(system_set(name))
}

///|
fn stepping_test_app(log : Array[String]) -> App[@ecs.World] {
  let one = stepping_system_config(UPDATE_SYSTEM_ONE_NAME, log, "one")
  let two = stepping_system_config(UPDATE_SYSTEM_TWO_NAME, log, "two").after(
    system_set(UPDATE_SYSTEM_ONE_NAME),
  )
  let three = stepping_system_config(UPDATE_SYSTEM_THREE_NAME, log, "three").after(
    system_set(UPDATE_SYSTEM_TWO_NAME),
  )
  let four = stepping_system_config(UPDATE_SYSTEM_FOUR_NAME, log, "four")
  App::new(@ecs.World::new())
  .add_systems(
    PreUpdate,
    stepping_system_config(PRE_UPDATE_SYSTEM_NAME, log, "pre"),
  )
  .add_systems(Update, one)
  .add_systems(Update, two)
  .add_systems(Update, three)
  .add_systems(Update, four)
  .insert_resource(Stepping::new())
}

///|
fn stepping_ref(app : App[@ecs.World]) -> Ref[Stepping] {
  match (try! app.world().get_resource_ref_mut(Stepping::resource())) {
    Some(resource_ref) => resource_ref
    None => abort("Stepping resource should exist")
  }
}

///|
test "app: stepping waits then steps and continues through a schedule" {
  let log : Array[String] = []
  let mut app = stepping_test_app(log)
  let stepping = stepping_ref(app)

  stepping.val = stepping.val.add_schedule(Update).enable()
  app = app.update()
  inspect(log.join(","), content="pre")

  stepping.val = stepping.val.step_frame()
  app = app.update()
  inspect(log.join(","), content="pre,pre,one")

  app = app.update()
  inspect(log.join(","), content="pre,pre,one,pre")

  stepping.val = stepping.val.continue_frame()
  app = app.update()
  inspect(log.join(","), content="pre,pre,one,pre,pre,two,three,four")
}

///|
test "app: stepping always_run and never_run affect gated systems only" {
  let log : Array[String] = []
  let mut app = stepping_test_app(log)
  let stepping = stepping_ref(app)

  stepping.val = stepping.val
    .add_schedule(Update)
    .always_run(Update, UPDATE_SYSTEM_TWO_NAME)
    .never_run(Update, UPDATE_SYSTEM_THREE_NAME)
    .enable()

  app = app.update()
  inspect(log.join(","), content="pre,two")

  stepping.val = stepping.val.step_frame()
  app = app.update()
  inspect(log.join(","), content="pre,two,pre,one,two")

  stepping.val = stepping.val.continue_frame()
  app = app.update()
  inspect(log.join(","), content="pre,two,pre,one,two,pre,two,four")
}

///|
test "app: stepping breakpoint stops continue before the marked system" {
  let log : Array[String] = []
  let mut app = stepping_test_app(log)
  let stepping = stepping_ref(app)

  stepping.val = stepping.val
    .add_schedule(Update)
    .set_breakpoint(Update, UPDATE_SYSTEM_TWO_NAME)
    .enable()

  stepping.val = stepping.val.continue_frame()
  app = app.update()
  inspect(log.join(","), content="pre,one")

  stepping.val = stepping.val.step_frame()
  app = app.update()
  inspect(log.join(","), content="pre,one,pre,two")

  stepping.val = stepping.val.continue_frame()
  app = app.update()
  inspect(log.join(","), content="pre,one,pre,two,pre,three,four")

  stepping.val = stepping.val.clear_breakpoint(Update, UPDATE_SYSTEM_TWO_NAME)
  stepping.val = stepping.val.continue_frame()
  app = app.update()
  inspect(
    log.join(","),
    content="pre,one,pre,two,pre,three,four,pre,one,two,three,four",
  )
}
