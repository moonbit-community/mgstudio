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
test "diagnostics: render snapshot records render measurements" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([
    diagnostics_plugin, render_diagnostics_plugin,
  ])
  let tick = 7
  ignore(tick)
  let store_ref = try! app
    .world()
    .get_resource_ref_mut(DiagnosticsStore::resource())
    .unwrap()
  render_diagnostics_record_snapshot(store_ref.val, tick, RenderDiagnosticsMeasurements::{
    prepared_cameras_2d: Some(2),
    queued_draw_items_2d: Some(14),
    prepared_cameras_3d: Some(1),
    visible_meshes_3d: Some(6),
    mesh2d_draw_calls: 3,
    mesh2d_executed_draw_calls: 2,
    mesh3d_draw_calls: 4,
    mesh3d_executed_draw_calls: 1,
  })
  inspect(
    store_ref.val
    .get(render_diagnostic_prepared_cameras_2d)
    .unwrap()
    .value()
    .unwrap(),
    content="2",
  )
  inspect(
    store_ref.val
    .get(render_diagnostic_queued_draw_items_2d)
    .unwrap()
    .value()
    .unwrap(),
    content="14",
  )
  inspect(
    store_ref.val
    .get(render_diagnostic_prepared_cameras_3d)
    .unwrap()
    .value()
    .unwrap(),
    content="1",
  )
  inspect(
    store_ref.val
    .get(render_diagnostic_visible_meshes_3d)
    .unwrap()
    .value()
    .unwrap(),
    content="6",
  )
  inspect(
    store_ref.val
    .get(render_diagnostic_mesh2d_draw_calls)
    .unwrap()
    .value()
    .unwrap(),
    content="3",
  )
  inspect(
    store_ref.val
    .get(render_diagnostic_mesh2d_executed_draw_calls)
    .unwrap()
    .value()
    .unwrap(),
    content="2",
  )
  inspect(
    store_ref.val
    .get(render_diagnostic_mesh3d_draw_calls)
    .unwrap()
    .value()
    .unwrap(),
    content="4",
  )
  inspect(
    store_ref.val
    .get(render_diagnostic_mesh3d_executed_draw_calls)
    .unwrap()
    .value()
    .unwrap(),
    content="1",
  )
}
