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
//
// Adapted from Bevy's `bevy_diagnostic` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub struct DiagnosticsPlugin {}

///|
const DIAGNOSTICS_PLUGIN_NAME : String = "mgstudio.diagnostic.DiagnosticsPlugin"

///|
pub fn DiagnosticsPlugin::default() -> DiagnosticsPlugin {
  DiagnosticsPlugin::{  }
}

///|
pub impl @app.Plugin for DiagnosticsPlugin with name(_self) {
  DIAGNOSTICS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DiagnosticsPlugin with build(self, app) {
  diagnostics_plugin_with(app, self)
}

///|
pub fn diagnostics_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  diagnostics_plugin_with(app, DiagnosticsPlugin::default())
}

///|
pub fn diagnostics_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : DiagnosticsPlugin,
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { DiagnosticsStore::default() })
  .init_resource(fn() { SystemInfo::default() })
}

///|
const DEFAULT_MAX_HISTORY_LENGTH : Int = 120
