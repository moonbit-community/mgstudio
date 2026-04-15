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
fn print_hello_system(_world : @ecs.World) -> Unit {
  println("hello")
}

///|
fn print_world_system(_world : @ecs.World) -> Unit {
  println("world")
}

///|
struct PrintHelloPlugin {}

///|
fn PrintHelloPlugin::default() -> PrintHelloPlugin {
  PrintHelloPlugin::{  }
}

///|
impl @app.Plugin for PrintHelloPlugin with name(_self) {
  "examples.app.plugin_group.PrintHelloPlugin"
}

///|
impl @app.Plugin for PrintHelloPlugin with build(_self, app) {
  app.add_systems(@app.Update, @app.system(print_hello_system))
}

///|
struct PrintWorldPlugin {}

///|
fn PrintWorldPlugin::default() -> PrintWorldPlugin {
  PrintWorldPlugin::{  }
}

///|
impl @app.Plugin for PrintWorldPlugin with name(_self) {
  "examples.app.plugin_group.PrintWorldPlugin"
}

///|
impl @app.Plugin for PrintWorldPlugin with build(_self, app) {
  app.add_systems(@app.Update, @app.system(print_world_system))
}

///|
struct HelloWorldPlugins {}

///|
fn HelloWorldPlugins::default() -> HelloWorldPlugins {
  HelloWorldPlugins::{  }
}

///|
fn HelloWorldPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named("HelloWorldPlugins")
  .add(PrintHelloPlugin::default())
  .add(PrintWorldPlugin::default())
}

///|
impl @app.Plugin for HelloWorldPlugins with name(_self) {
  "examples.app.plugin_group.HelloWorldPlugins"
}

///|
impl @app.Plugin for HelloWorldPlugins with build(_self, app) {
  app.add_plugins(HelloWorldPlugins::build())
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_plugins(HelloWorldPlugins::default())
  .run()
}
