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
// Bevy source: `bevy/crates/bevy_a11y/src/lib.rs`.
// Crate-root plugin surface.
pub const A11Y_CRATE_ID : String = "bevy_a11y"

///|
pub const A11Y_DEFAULT_PLUGIN_ID : String = "bevy_a11y::AccessibilityPlugin"

///|
pub fn accessibility_plugin_default() -> AccessibilityPlugin {
  AccessibilityPlugin::default()
}

///|
pub fn accessibility_plugin_run(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  accessibility_plugin(app)
}

///|
pub fn a11y_lib_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  a11y_plugin(app)
}
