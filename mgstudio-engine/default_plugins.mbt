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
pub struct DefaultPlugins {}

///|
fn default_plugins_marker() -> DefaultPlugins {
  DefaultPlugins::{  }
}

///|
pub fn DefaultPlugins::default() -> DefaultPlugins {
  default_plugins_marker()
}

///|
pub fn DefaultPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  @internal.DefaultPlugins::build()
}

///|
pub impl @app.Plugin for DefaultPlugins with name(_self) {
  "mgstudio.DefaultPlugins"
}

///|
pub impl @app.Plugin for DefaultPlugins with build(_self, app) {
  app.add_plugins(DefaultPlugins::build())
}

///|
pub fn[P : @app.Plugin] DefaultPlugins::set(
  replacement : P,
) -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  @internal.DefaultPlugins::set(replacement)
}

///|
pub fn DefaultPlugins::set_window(
  plugin : @window.WindowPlugin,
) -> @app.PluginGroupBuilder[@ecs.World] {
  DefaultPlugins::set(plugin)
}

///|
pub struct MinimalPlugins {}

///|
fn minimal_plugins_marker() -> MinimalPlugins {
  MinimalPlugins::{  }
}

///|
pub fn MinimalPlugins::default() -> MinimalPlugins {
  minimal_plugins_marker()
}

///|
pub fn MinimalPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  minimal_plugins_marker() |> ignore
  @internal.MinimalPlugins::build()
}

///|
pub impl @app.Plugin for MinimalPlugins with name(_self) {
  "mgstudio.MinimalPlugins"
}

///|
pub impl @app.Plugin for MinimalPlugins with build(_self, app) {
  app.add_plugins(MinimalPlugins::build())
}
