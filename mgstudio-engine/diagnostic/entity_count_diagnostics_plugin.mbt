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
const ENTITY_COUNT_DIAGNOSTICS_PLUGIN_NAME : String = "mgstudio.diagnostic.EntityCountDiagnosticsPlugin"

///|
pub struct EntityCountDiagnosticsPlugin {
  max_history_length : Int
}

///|
pub fn EntityCountDiagnosticsPlugin::new(
  max_history_length : Int,
) -> EntityCountDiagnosticsPlugin {
  EntityCountDiagnosticsPlugin::{ max_history_length, }
}

///|
pub fn EntityCountDiagnosticsPlugin::default() -> EntityCountDiagnosticsPlugin {
  EntityCountDiagnosticsPlugin::new(DEFAULT_MAX_HISTORY_LENGTH)
}

///|
pub impl @app.Plugin for EntityCountDiagnosticsPlugin with name(_self) {
  ENTITY_COUNT_DIAGNOSTICS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for EntityCountDiagnosticsPlugin with build(self, app) {
  entity_count_diagnostics_plugin_with(app, self)
}

///|
pub let entity_count_diagnostic_path : DiagnosticPath = DiagnosticPath::const_new(
  "entity_count",
)

///|
pub fn entity_count_diagnostics_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  entity_count_diagnostics_plugin_with(
    app,
    EntityCountDiagnosticsPlugin::default(),
  )
}

///|
pub fn entity_count_diagnostics_plugin_with(
  app : @app.App[@ecs.World],
  plugin : EntityCountDiagnosticsPlugin,
) -> @app.App[@ecs.World] {
  register_diagnostic(
    app,
    Diagnostic::new(entity_count_diagnostic_path).with_max_history_length(
      plugin.max_history_length,
    ),
  ).add_system(entity_count_diagnostic_system)
}

///|
fn entity_count_diagnostic_system(world : @ecs.World) -> Unit {
  let sequence = @app.current_system_sequence().this_run
  match
    (try world.get_resource_ref_mut(DiagnosticsStore::resource()) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(store_ref) =>
      match store_ref.val.get_ref(entity_count_diagnostic_path) {
        Some(diagnostic_ref) => {
          if !diagnostic_ref.val.is_enabled {
            return
          }
          diagnostic_ref.val.add_measurement(
            DiagnosticMeasurement::{
              time: @core.Instant::now(),
              value: Float::from_int(world.entity_count()),
            },
            sequence,
          )
        }
        None => ()
      }
    None => ()
  }
}
