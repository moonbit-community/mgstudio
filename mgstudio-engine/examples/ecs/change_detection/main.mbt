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
struct MyComponent {
  mut value : Int
}

///|
struct MyResource {
  mut value : Int
  mut last_logged : Int
}

///|
let my_component_key : @ecs.ComponentKey[MyComponent] = @ecs.register_component(
  debug_name="examples.ecs.change_detection.MyComponent",
)

///|
let my_resource_key : @ecs.ResourceKey[MyResource] = @ecs.register_resource(
  debug_name="examples.ecs.change_detection.MyResource",
)

///|
pub impl @ecs.Component for MyComponent with component() {
  my_component_key
}

///|
pub impl @app.Resource for MyResource with resource() {
  my_resource_key
}

///|
fn setup(commands : @app.Commands) -> Unit {
  commands.spawn_component(MyComponent::{ value: 0 }) |> ignore
  commands.insert_resource(MyResource::{ value: 0, last_logged: -1 })
}

///|
fn change_component(
  time : @app.Res[@time.Time[Unit]],
  query : @ecs.Query[@ecs.Mut[MyComponent], @ecs.All],
) -> Unit {
  let target = (time.get().elapsed_seconds() * 2.0F).to_int()
  try! query.view(fn(_entity, component) {
    if component.value().value != target {
      component.get_ref().val.value = target
    }
  })
}

///|
fn change_resource(
  time : @app.Res[@time.Time[Unit]],
  resource : @app.ResMut[MyResource],
) -> Unit {
  resource.get_ref().val.value = (time.get().elapsed_seconds() * 3.0F).to_int()
}

///|
fn detect_added(world : @ecs.World) -> Unit {
  let added : @ecs.Query[@ecs.Comp[MyComponent], @ecs.Added[MyComponent]] = @ecs.query_filtered(
    world,
    @ecs.Added::new(my_component_key),
  )
  try! added.view(fn(_entity, component) {
    println("Added MyComponent value=" + component.value().value.to_string())
  })
}

///|
fn detect_resource_change(resource : @app.ResMut[MyResource]) -> Unit {
  if resource.get_ref().val.value != resource.get_ref().val.last_logged {
    resource.get_ref().val.last_logged = resource.get_ref().val.value
    println("Resource changed to " + resource.get_ref().val.value.to_string())
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins([
    @app.schedule_runner_plugin(@app.ScheduleRunnerPlugin::run_once()),
  ])
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(change_component)))
  .add_systems(@app.Update, @app.system(@app.system_param2(change_resource)))
  .add_systems(@app.Update, @app.system(detect_added))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(detect_resource_change)),
  )
  .run()
}
