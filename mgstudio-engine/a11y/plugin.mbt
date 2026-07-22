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
pub(all) struct AccessibilityPlugin {}

///|
const ACCESSIBILITY_PLUGIN_NAME : String = "mgstudio.a11y.AccessibilityPlugin"

///|
#warnings("-unnecessary_annotation")
pub fn AccessibilityPlugin::AccessibilityPlugin() -> AccessibilityPlugin {
  AccessibilityPlugin::{  }
}

///|
pub impl @app.Plugin for AccessibilityPlugin with fn name(_self) {
  ACCESSIBILITY_PLUGIN_NAME
}

///|
pub impl @app.Plugin for AccessibilityPlugin with fn build(self, app) {
  accessibility_plugin_with(app, self)
}

///|
pub fn accessibility_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  accessibility_plugin_with(app, AccessibilityPlugin())
}

///|
pub fn accessibility_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : AccessibilityPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { AccessibilityRequested::AccessibilityRequested() })
  .init_resource(fn() {
    ManageAccessibilityUpdates::ManageAccessibilityUpdates()
  })
  .allow_ambiguous_component(key=ecs_key_accessibility_node)
}

///|
pub fn a11y_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  accessibility_plugin(app)
}
