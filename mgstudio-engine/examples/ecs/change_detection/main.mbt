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
  value : Int
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
  query : @ecs.Query[@ecs.Mut[MyComponent], @ecs.All],
) -> Unit {
  try! query.view(fn(_entity, component) {
    if component.value().value != 1 {
      component.set(MyComponent::{ value: 1 })
    }
  })
}

///|
fn change_resource(resource : @app.ResMut[MyResource]) -> Unit {
  resource.modify(fn(value) { value.value = value.value + 1 })
}

///|
fn detect_added(
  added : @ecs.Query[@ecs.Comp[MyComponent], @ecs.Added[MyComponent]],
) -> Unit {
  try! added.view(fn(_entity, component) {
    println("Added MyComponent value=\{component.value().value.to_string()}")
  })
}

///|
fn detect_changed(
  changed : @ecs.Query[@ecs.Comp[MyComponent], @ecs.Changed[MyComponent]],
) -> Unit {
  try! changed.view(fn(_entity, component) {
    println("Changed MyComponent value=\{component.value().value.to_string()}")
  })
}

///|
fn detect_resource_change(resource : @app.ResMut[MyResource]) -> Unit {
  let current = resource.peek()
  if current.value != current.last_logged {
    resource.modify(fn(value) { value.last_logged = value.value })
    println("Resource changed to \{resource.peek().value.to_string()}")
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@app.ScheduleRunnerPlugin::run_once())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param(change_component)))
  .add_systems(@app.Update, @app.system(@app.system_param(change_resource)))
  .add_systems(@app.Update, @app.system(@app.system_param(detect_added)))
  .add_systems(@app.Update, @app.system(@app.system_param(detect_changed)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(detect_resource_change)),
  )
  .run()
}
