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
/// Feathers boundary aligned with Bevy's `bevy_feathers` crate.
/// Runtime mapping currently routes through `Milky2018/mgstudio/ui_widgets`.

///|
pub struct FeathersPlugin {}

///|
pub struct FeathersPlugins {}

///|
pub fn FeathersPlugin::default() -> FeathersPlugin {
  FeathersPlugin::{  }
}

///|
pub fn FeathersPlugins::default() -> FeathersPlugins {
  FeathersPlugins::{  }
}

///|
pub fn feathers_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @ui_widgets.ui_widgets_plugin(app)
}

///|
pub fn feathers_plugins() -> @app.PluginGroup[@ecs.World] {
  fn() {
    let builder : @app.PluginGroupBuilder[@ecs.World] = @app.PluginGroupBuilder::start()
    builder.add(feathers_plugin)
  }
}
