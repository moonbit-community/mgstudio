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
let counter_resource_storage : Ref[@core.Resource[CounterResource]] = Ref::new(
  @core.Resource::new(),
)

///|
impl Resource for CounterResource with resource() {
  counter_resource_storage.val
}

///|
fn reset_counter_resource() -> Unit {
  counter_resource_storage.val.remove() |> ignore
}

///|
test "app: insert_resource and ResMut parameter updates value" {
  reset_counter_resource()
  let app = App::new(@ecs.World::new())
    .insert_resource(CounterResource::{ value: 1 })
    .add_system_param(fn(resource : ResMut[CounterResource]) {
      let value_ref = resource.get_ref()
      value_ref.val.value = value_ref.val.value + 2
    })
  app.run_once() |> ignore

  let value = match counter_resource_storage.val.get() {
    Some(resource) => resource.value
    None => -1
  }
  inspect(value, content="3")
}

///|
test "app: Res parameter reads inserted resource value" {
  reset_counter_resource()
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
  reset_counter_resource()
  let app = App::new(@ecs.World::new()).init_resource(fn() {
    CounterResource::{ value: 11 }
  })
  inspect(app.contains_resource(CounterResource::resource()), content="true")
  let inserted_value = match counter_resource_storage.val.get() {
    Some(resource) => resource.value
    None => -1
  }
  inspect(inserted_value, content="11")

  app
  .insert_resource(CounterResource::{ value: 4 })
  .init_resource(fn() { CounterResource::{ value: 99 } })
  |> ignore

  let kept_value = match counter_resource_storage.val.get() {
    Some(resource) => resource.value
    None => -1
  }
  inspect(kept_value, content="4")
}

///|
test "app: resource_remove clears custom resource" {
  reset_counter_resource()
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
