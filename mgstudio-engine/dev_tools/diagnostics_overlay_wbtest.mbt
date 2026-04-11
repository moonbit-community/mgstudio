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
fn diagnostics_overlay_test_app_with_overlay(
  overlay : DiagnosticsOverlay,
) -> (@app.App[@ecs.World], @core.Entity) {
  let app = @app.App::new(@ecs.World::new()).add_plugins([
    @time.time_plugin,
    fn(app_) {
      diagnostics_overlay_plugin_with(app_, DiagnosticsOverlayPlugin::{
        refresh_interval_seconds: 0.01F,
      })
    },
  ])
  let overlay_entity = app.world().spawn_empty()
  try! (app.world().entity_mut(overlay_entity).insert_component(overlay)
  |> ignore)
  (app, overlay_entity)
}

///|
test "dev_tools: diagnostics overlay creates plane and window for overlay entity" {
  let (app, overlay_entity) = diagnostics_overlay_test_app_with_overlay(
    DiagnosticsOverlay::fps(),
  )
  let app = app.run_startup().update()
  let runtime_state = try! app
    .world()
    .get_resource(diagnostics_overlay_runtime_state_resource_key)
    .unwrap()
  guard runtime_state.plane_entity is Some(plane_entity) else {
    abort("missing diagnostics overlay plane")
  }
  debug_inspect(
    try! (app.world().get_by_key(plane_entity, @ui.ecs_key_ui_root) is Some(_)),
    content="true",
  )
  debug_inspect(
    try! (app
    .world()
    .get_by_key(overlay_entity, ecs_key_diagnostics_overlay_window)
    is Some(_)),
    content="true",
  )
}

///|
test "dev_tools: diagnostics overlay uses Missing text for absent diagnostics" {
  let missing_item = DiagnosticsOverlayItem::default_with_path(
    @diagnostic.DiagnosticPath::const_new("missing.path"),
  )
  let store = @diagnostic.DiagnosticsStore::default()
  debug_inspect(
    diagnostics_overlay_measurement_text(missing_item, store),
    content="\"Missing\"",
  )
}

///|
test "dev_tools: diagnostics overlay precision rounding is stable" {
  debug_inspect(diagnostics_overlay_round_precision(12.3456F, 0), content="\"12\"")
  debug_inspect(
    diagnostics_overlay_round_precision(12.3456F, 2),
    content="\"12.35\"",
  )
}
