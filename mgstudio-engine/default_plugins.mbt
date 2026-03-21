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
pub fn DefaultPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  default_plugins_marker() |> ignore
  @internal.DefaultPlugins::build()
}

///|
pub fn[P : @app.PluginReplacement] DefaultPlugins::set(
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
pub fn MinimalPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  minimal_plugins_marker() |> ignore
  @internal.MinimalPlugins::build()
}

///|
/// Default plugin bundle, aligned with Bevy's `DefaultPlugins` concept.
///
/// Implementation lives in `Milky2018/mgstudio/internal` (similar to Bevy's
/// `bevy_internal`) and is forwarded here for a stable user-facing API.
pub fn default_plugins() -> Array[@app.Plugin[@ecs.World]] {
  @internal.default_plugins()
}

///|
/// Default plugin bundle with "nearest" sampling for textures (useful for pixel art).
pub fn default_plugins_nearest() -> Array[@app.Plugin[@ecs.World]] {
  DefaultPlugins::set(@asset.AssetPlugin::default_nearest()).build()
}

///|
/// Minimal plugin bundle, aligned with Bevy's `MinimalPlugins` concept.
pub fn minimal_plugins() -> Array[@app.Plugin[@ecs.World]] {
  @internal.minimal_plugins()
}
