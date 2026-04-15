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
const FEATHERS_PLUGIN_NAME : String = "mgstudio.feathers.FeathersPlugin"

///|
const FEATHERS_PLUGINS_NAME : String = "mgstudio.feathers.FeathersPlugins"

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
pub fn FeathersPlugins::build() -> @app.PluginGroupBuilder[@ecs.World] {
  @app.PluginGroupBuilder::start_named("FeathersPlugins").add(
    FeathersPlugin::default(),
  )
}

///|
pub impl @app.Plugin for FeathersPlugin with name(_self) {
  FEATHERS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for FeathersPlugin with build(_self, app) {
  feathers_plugin(app)
}

///|
pub impl @app.Plugin for FeathersPlugins with name(_self) {
  FEATHERS_PLUGINS_NAME
}

///|
pub impl @app.Plugin for FeathersPlugins with build(_self, app) {
  app.add_plugins(FeathersPlugins::build())
}

///|
pub fn feathers_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  if app.contains_resource(feathers_plugin_marker_key) {
    app
  } else {
    app
    .world()
    .insert_resource(feathers_plugin_marker_key, FeathersPluginMarker::{  })
    let app = app.init_resource(fn() { UiTheme::default() })
    let app = app.add_plugins(@ui_widgets.UiWidgetsPlugins::default())
    let app = alpha_pattern_plugin(app)
    let app = @controls.controls_plugin(app)
    cursor_icon_plugin(app)
  }
}

///|
pub fn feathers_plugins() -> FeathersPlugins {
  FeathersPlugins::default()
}
