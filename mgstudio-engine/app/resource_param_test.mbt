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
struct CounterResource {
  mut value : Int
}

///|
let counter_resource_key : @ecs.ResourceKey[CounterResource] = @ecs.register_resource(
  debug_name="app::resource_param_test::CounterResource",
)

///|
impl Resource for CounterResource with resource() {
  counter_resource_key
}

///|
fn read_counter_resource(world : @ecs.World) -> CounterResource? {
  try! world.get_resource(counter_resource_key)
}

///|
test "app: insert_resource and ResMut parameter updates value" {
  let app = App::new(@ecs.World::new())
    .insert_resource(CounterResource::{ value: 1 })
    .add_system_param(fn(resource : ResMut[CounterResource]) {
      let value_ref = resource.get_ref()
      value_ref.val.value = value_ref.val.value + 2
    })
  app.run_once() |> ignore

  let value = match read_counter_resource(app.world()) {
    Some(resource) => resource.value
    None => -1
  }
  inspect(value, content="3")
}

///|
test "app: Res parameter reads inserted resource value" {
  let observed : Ref[Int] = Ref::new(-1)
  let app = App::new(@ecs.World::new())
    .insert_resource(CounterResource::{ value: 7 })
    .add_system_param(fn(resource : Res[CounterResource]) {
      observed.val = resource.get().value
    })
  app.run_once() |> ignore
  inspect(observed.val, content="7")
}

///|
test "app: init_resource inserts only when missing" {
  let app = App::new(@ecs.World::new()).init_resource(fn() {
    CounterResource::{ value: 11 }
  })
  inspect(app.contains_resource(CounterResource::resource()), content="true")
  let inserted_value = match read_counter_resource(app.world()) {
    Some(resource) => resource.value
    None => -1
  }
  inspect(inserted_value, content="11")

  app
  .insert_resource(CounterResource::{ value: 4 })
  .init_resource(fn() { CounterResource::{ value: 99 } })
  |> ignore

  let kept_value = match read_counter_resource(app.world()) {
    Some(resource) => resource.value
    None => -1
  }
  inspect(kept_value, content="4")
}

///|
test "app: resource_remove clears custom resource" {
  let app = App::new(@ecs.World::new()).insert_resource(CounterResource::{
    value: 9,
  })
  inspect(app.contains_resource(CounterResource::resource()), content="true")
  inspect(
    app.remove_resource(CounterResource::resource()) is Some(_),
    content="true",
  )
  inspect(app.contains_resource(CounterResource::resource()), content="false")
}

///|
test "app: resource_exists gates system execution on resource presence" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { log.push(1) }).run_if(
      resource_exists(CounterResource::resource()),
    ),
  )

  app.run_once() |> ignore
  inspect(log.length(), content="0")

  app.insert_resource(CounterResource::{ value: 3 }) |> ignore
  app.run_once() |> ignore
  inspect(log.length(), content="1")
}

///|
test "app: resource_added only matches the frame a resource is inserted" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new()).add_system_config(
    system(fn(_world : @ecs.World) { log.push(log.length()) }).run_if(
      resource_added(CounterResource::resource()),
    ),
  )

  app.run_once() |> ignore
  inspect(log.length(), content="0")

  app.insert_resource(CounterResource::{ value: 5 }) |> ignore
  app.run_once() |> ignore
  inspect(log.length(), content="1")
  inspect(log[0], content="0")

  app.run_once() |> ignore
  inspect(log.length(), content="1")
}

///|
test "app: resource_exists_and_changed matches bevy change detection" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new())
    .insert_resource(CounterResource::{ value: 1 })
    .add_system_config(
      system(fn(world : @ecs.World) {
        match read_counter_resource(world) {
          Some(resource) => log.push(resource.value)
          None => log.push(-1)
        }
      }).run_if(resource_exists_and_changed(CounterResource::resource())),
    )

  app.run_once() |> ignore
  inspect(log.length(), content="1")
  inspect(log[0], content="1")

  app.run_once() |> ignore
  inspect(log.length(), content="1")

  app.insert_resource(CounterResource::{ value: 8 }) |> ignore
  app.run_once() |> ignore
  inspect(log.length(), content="2")
  inspect(log[1], content="8")
}

///|
test "app: resource_changed tracks changes when the resource exists" {
  let log : Array[Int] = []
  let app = App::new(@ecs.World::new())
    .insert_resource(CounterResource::{ value: 1 })
    .add_system_config(
      system(fn(world : @ecs.World) {
        match read_counter_resource(world) {
          Some(resource) => log.push(resource.value)
          None => log.push(-1)
        }
      }).run_if(resource_changed(CounterResource::resource())),
    )

  app.run_once() |> ignore
  inspect(log.length(), content="1")
  inspect(log[0], content="1")

  app.run_once() |> ignore
  inspect(log.length(), content="1")

  app.insert_resource(CounterResource::{ value: 9 }) |> ignore
  app.run_once() |> ignore
  inspect(log.length(), content="2")
  inspect(log[1], content="9")
}
