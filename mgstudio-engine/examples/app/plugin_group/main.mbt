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
fn print_hello_system() -> Unit {
  println("hello")
}

///|
fn print_world_system() -> Unit {
  println("world")
}

///|
struct PrintHelloPlugin {}

///|
fn PrintHelloPlugin::PrintHelloPlugin() -> PrintHelloPlugin {
  PrintHelloPlugin::{  }
}

///|
impl @app.Plugin for PrintHelloPlugin with fn name(_self) {
  "examples.app.plugin_group.PrintHelloPlugin"
}

///|
impl @app.Plugin for PrintHelloPlugin with fn build(_self, app) {
  app.add_systems_fn(@app.Update, print_hello_system)
}

///|
struct PrintWorldPlugin {}

///|
fn PrintWorldPlugin::PrintWorldPlugin() -> PrintWorldPlugin {
  PrintWorldPlugin::{  }
}

///|
impl @app.Plugin for PrintWorldPlugin with fn name(_self) {
  "examples.app.plugin_group.PrintWorldPlugin"
}

///|
impl @app.Plugin for PrintWorldPlugin with fn build(_self, app) {
  app.add_systems_fn(@app.Update, print_world_system)
}

///|
struct HelloWorldPlugins {}

///|
fn HelloWorldPlugins::HelloWorldPlugins() -> HelloWorldPlugins {
  HelloWorldPlugins::{  }
}

///|
fn HelloWorldPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named("HelloWorldPlugins")
  .add(PrintHelloPlugin::PrintHelloPlugin())
  .add(PrintWorldPlugin::PrintWorldPlugin())
}

///|
impl @app.Plugin for HelloWorldPlugins with fn name(_self) {
  "examples.app.plugin_group.HelloWorldPlugins"
}

///|
impl @app.Plugin for HelloWorldPlugins with fn build(_self, app) {
  app.add_plugins(HelloWorldPlugins::build())
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(HelloWorldPlugins::HelloWorldPlugins())
  .run()
}
