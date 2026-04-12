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

///|
pub struct FeathersPlugin {}

///|
pub struct FeathersPlugins {}

///|
pub(all) struct FeathersPluginMarker {}

///|
let feathers_plugin_marker_key : @ecs.ResourceKey[FeathersPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio.feathers.plugin_marker",
)

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
  if app.contains_resource(feathers_plugin_marker_key) {
    app
  } else {
    app
    .world()
    .insert_resource(feathers_plugin_marker_key, FeathersPluginMarker::{  })
    app
    .init_resource(fn() { UiTheme::default() })
    .add_plugin(@ui_widgets.ui_widgets_plugin)
    .add_plugin(alpha_pattern_plugin)
    .add_plugin(@controls.controls_plugin)
    .add_plugin(cursor_icon_plugin)
  }
}

///|
pub fn feathers_plugins() -> @app.PluginGroup[@ecs.World] {
  fn() {
    let builder : @app.PluginGroupBuilder[@ecs.World] = @app.PluginGroupBuilder::start()
    builder.add(feathers_plugin)
  }
}
