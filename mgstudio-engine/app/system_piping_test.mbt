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
struct SystemPipingMessage {
  value : String
} derive(Eq, Show)

///|
struct SystemPipingCounter {
  mut value : Int
} derive(Eq, Show)

///|
struct SystemPipingMarker {} derive(Eq, Show)

///|
let system_piping_message_key : @ecs.ResourceKey[SystemPipingMessage] = @ecs.register_resource(
  debug_name="tests.app.system_piping.message",
)

///|
let system_piping_counter_key : @ecs.ResourceKey[SystemPipingCounter] = @ecs.register_resource(
  debug_name="tests.app.system_piping.counter",
)

///|
let system_piping_marker_key : @ecs.ComponentKey[SystemPipingMarker] = @ecs.register_component(
  debug_name="tests.app.system_piping.marker",
)

///|
pub impl Resource for SystemPipingMessage with resource() {
  system_piping_message_key
}

///|
pub impl Resource for SystemPipingCounter with resource() {
  system_piping_counter_key
}

///|
pub impl @ecs.Component for SystemPipingMarker with component() {
  system_piping_marker_key
}

///|
fn touch_system_piping_types() -> Unit {
  ignore(SystemPipingMarker::{  })
}

///|
fn parse_piped_message(text : String) -> Result[Int, String] {
  try @strconv.parse_int(text[:], base=10) catch {
    _ => Err("invalid integer: " + text)
  } noraise {
    value => Ok(value)
  }
}

///|
fn parse_piped_message_system(
  message : Res[SystemPipingMessage],
) -> Result[Int, String] {
  parse_piped_message(message.get().value)
}

///|
fn clone_piped_message_system(message : Res[SystemPipingMessage]) -> String {
  message.get().value
}

///|
test "app system piping: pipe passes output into handler" {
  let log : Array[String] = []
  let mut app = App::new(@ecs.World::new())
  app.world().insert_resource(system_piping_message_key, { value: "42" })
  app = app.add_systems(
    Update,
    system_param_output(parse_piped_message_system).pipe(fn(
      input : In[Result[Int, String]],
    ) {
      match input.get() {
        Ok(value) => log.push("parsed " + value.to_string())
        Err(message) => log.push(message)
      }
    }),
  )

  app = app.run_once()

  inspect(log, content="[\"parsed 42\"]")
}

///|
test "app system piping: map and pipe_param can use additional system params" {
  let log : Array[String] = []
  let map_config : SystemConfig[@ecs.World] = system_param_output(
    clone_piped_message_system,
  ).map(fn(output : String) { log.push("map:" + output) })
  let pipe_config : SystemConfig[@ecs.World] = system_param_output(
    clone_piped_message_system,
  ).pipe_param(fn(input : In[String], counter : ResMut[SystemPipingCounter]) {
    let output = input.get()
    counter.get_ref().val.value = counter.get_ref().val.value + output.length()
    log.push("pipe:" + output)
  })
  let mut app = App::new(@ecs.World::new())
  app.world().insert_resource(system_piping_message_key, { value: "hello" })
  app.world().insert_resource(system_piping_counter_key, { value: 0 })
  app = app.add_systems(Update, (map_config, pipe_config) |> chain())

  app = app.run_once()

  inspect(log, content="[\"map:hello\", \"pipe:hello\"]")
  inspect(
    try! app.world().get_resource(system_piping_counter_key),
    content="Some({value: 5})",
  )
}

///|
test "app system piping: source validation skip prevents downstream handler" {
  touch_system_piping_types()
  let ran = Ref::new(false)
  let errors : Array[String] = []
  let mut app = App::new(@ecs.World::new())
    .set_error_handler(fn(error, _context) { errors.push(error.to_string()) })
    .add_systems(
      Update,
      system_param_output(fn(
        _marker : Single[@ecs.Comp[SystemPipingMarker], @ecs.All],
      ) -> Int {
        1
      }).pipe(fn(_input : In[Int]) { ran.val = true }),
    )

  app = app.run_once()

  inspect(ran.val, content="false")
  inspect(errors.length(), content="0")
}
