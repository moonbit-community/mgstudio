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
/// Port of `bevy/examples/app/plugin_group.rs`.

///|
fn print_hello_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_system(print_hello_system)
}

///|
fn print_world_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_system(print_world_system)
}

///|
fn hello_world_plugins() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start()
  .add(print_hello_plugin)
  .add(print_world_plugin)
}

///|
fn print_hello_system(_world : @ecs.World) -> Unit {
  println("hello")
}

///|
fn print_world_system(_world : @ecs.World) -> Unit {
  println("world")
}

///|
fn main {
  let default_plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(default_plugins)
  .add_plugin_group(hello_world_plugins)
  .run()
}
