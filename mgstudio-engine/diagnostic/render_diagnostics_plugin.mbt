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
// Adapted from Bevy's `bevy_render::diagnostic` module.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
const RENDER_DIAGNOSTICS_PLUGIN_NAME : String = "mgstudio.diagnostic.RenderDiagnosticsPlugin"

///|
pub struct RenderDiagnosticsPlugin {
  max_history_length : Int
}

///|
pub fn RenderDiagnosticsPlugin::new(
  max_history_length : Int,
) -> RenderDiagnosticsPlugin {
  RenderDiagnosticsPlugin::{ max_history_length, }
}

///|
pub fn RenderDiagnosticsPlugin::default() -> RenderDiagnosticsPlugin {
  RenderDiagnosticsPlugin::new(DEFAULT_MAX_HISTORY_LENGTH)
}

///|
pub impl @app.Plugin for RenderDiagnosticsPlugin with name(_self) {
  RENDER_DIAGNOSTICS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for RenderDiagnosticsPlugin with build(self, app) {
  render_diagnostics_plugin_with(app, self)
}

///|
pub let render_diagnostic_prepared_cameras_2d : DiagnosticPath = DiagnosticPath::const_new(
  "render/2d/prepared_cameras",
)

///|
pub let render_diagnostic_queued_draw_items_2d : DiagnosticPath = DiagnosticPath::const_new(
  "render/2d/queued_draw_items",
)

///|
pub let render_diagnostic_queue_cpu_ms_2d : DiagnosticPath = DiagnosticPath::const_new(
  "render/2d/queue_cpu_ms",
)

///|
pub let render_diagnostic_execute_cpu_ms_2d : DiagnosticPath = DiagnosticPath::const_new(
  "render/2d/execute_cpu_ms",
)

///|
pub let render_diagnostic_prepared_cameras_3d : DiagnosticPath = DiagnosticPath::const_new(
  "render/3d/prepared_cameras",
)

///|
pub let render_diagnostic_visible_meshes_3d : DiagnosticPath = DiagnosticPath::const_new(
  "render/3d/visible_meshes",
)

///|
pub let render_diagnostic_queue_cpu_ms_3d : DiagnosticPath = DiagnosticPath::const_new(
  "render/3d/queue_cpu_ms",
)

///|
pub let render_diagnostic_execute_cpu_ms_3d : DiagnosticPath = DiagnosticPath::const_new(
  "render/3d/execute_cpu_ms",
)

///|
pub let render_diagnostic_pass_total_count : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/total_count",
)

///|
pub let render_diagnostic_pass_2d_count : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/2d_count",
)

///|
pub let render_diagnostic_pass_3d_main_count : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/3d_main_count",
)

///|
pub let render_diagnostic_pass_3d_motion_vector_count : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/3d_motion_vector_count",
)

///|
pub let render_diagnostic_pass_3d_point_shadow_count : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/3d_point_shadow_count",
)

///|
pub let render_diagnostic_pass_total_cpu_ms : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/total_cpu_ms",
)

///|
pub let render_diagnostic_pass_2d_cpu_ms : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/2d_cpu_ms",
)

///|
pub let render_diagnostic_pass_3d_main_cpu_ms : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/3d_main_cpu_ms",
)

///|
pub let render_diagnostic_pass_3d_motion_vector_cpu_ms : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/3d_motion_vector_cpu_ms",
)

///|
pub let render_diagnostic_pass_3d_point_shadow_cpu_ms : DiagnosticPath = DiagnosticPath::const_new(
  "render/pass/3d_point_shadow_cpu_ms",
)

///|
pub let render_diagnostic_mesh2d_draw_calls : DiagnosticPath = DiagnosticPath::const_new(
  "render/mesh2d_draw_calls",
)

///|
pub let render_diagnostic_mesh2d_executed_draw_calls : DiagnosticPath = DiagnosticPath::const_new(
  "render/mesh2d_executed_draw_calls",
)

///|
pub let render_diagnostic_mesh3d_draw_calls : DiagnosticPath = DiagnosticPath::const_new(
  "render/mesh3d_draw_calls",
)

///|
pub let render_diagnostic_mesh3d_executed_draw_calls : DiagnosticPath = DiagnosticPath::const_new(
  "render/mesh3d_executed_draw_calls",
)

///|
priv struct RenderDiagnosticsMeasurements {
  prepared_cameras_2d : Int?
  queued_draw_items_2d : Int?
  queue_cpu_ms_2d : Float?
  execute_cpu_ms_2d : Float?
  prepared_cameras_3d : Int?
  visible_meshes_3d : Int?
  queue_cpu_ms_3d : Float?
  execute_cpu_ms_3d : Float?
  pass_total_count : Int
  pass_2d_count : Int
  pass_3d_main_count : Int
  pass_3d_motion_vector_count : Int
  pass_3d_point_shadow_count : Int
  pass_total_cpu_ms : Float
  pass_2d_cpu_ms : Float
  pass_3d_main_cpu_ms : Float
  pass_3d_motion_vector_cpu_ms : Float
  pass_3d_point_shadow_cpu_ms : Float
  mesh2d_draw_calls : Int
  mesh2d_executed_draw_calls : Int
  mesh3d_draw_calls : Int
  mesh3d_executed_draw_calls : Int
}

///|
pub fn render_diagnostics_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_diagnostics_plugin_with(app, RenderDiagnosticsPlugin::default())
}

///|
pub fn render_diagnostics_plugin_with(
  app : @app.App[@ecs.World],
  plugin : RenderDiagnosticsPlugin,
) -> @app.App[@ecs.World] {
  let mut app_ = app
  let diagnostics = [
    render_diagnostic_prepared_cameras_2d, render_diagnostic_queued_draw_items_2d,
    render_diagnostic_queue_cpu_ms_2d, render_diagnostic_execute_cpu_ms_2d, render_diagnostic_prepared_cameras_3d,
    render_diagnostic_visible_meshes_3d, render_diagnostic_queue_cpu_ms_3d, render_diagnostic_execute_cpu_ms_3d,
    render_diagnostic_pass_total_count, render_diagnostic_pass_2d_count, render_diagnostic_pass_3d_main_count,
    render_diagnostic_pass_3d_motion_vector_count, render_diagnostic_pass_3d_point_shadow_count,
    render_diagnostic_pass_total_cpu_ms, render_diagnostic_pass_2d_cpu_ms, render_diagnostic_pass_3d_main_cpu_ms,
    render_diagnostic_pass_3d_motion_vector_cpu_ms, render_diagnostic_pass_3d_point_shadow_cpu_ms,
    render_diagnostic_mesh2d_draw_calls, render_diagnostic_mesh2d_executed_draw_calls,
    render_diagnostic_mesh3d_draw_calls, render_diagnostic_mesh3d_executed_draw_calls,
  ]
  for path in diagnostics {
    app_ = register_diagnostic(
      app_,
      render_diagnostic_with_history(path, plugin.max_history_length),
    )
  }
  app_.add_post_update_system_config(
    @app.system(render_diagnostics_system)
    .after(@sprite_render.render2d_set_render)
    .after(@pbr.render3d_set_render),
  )
}

///|
fn render_diagnostic_with_history(
  path : DiagnosticPath,
  max_history_length : Int,
) -> Diagnostic {
  Diagnostic::new(path)
  .with_max_history_length(max_history_length)
  .with_smoothing_factor(0.0F)
}

///|
fn render_diagnostics_store_ref_mut(
  world : @ecs.World,
) -> Ref[DiagnosticsStore]? {
  try world.get_resource_ref_mut(DiagnosticsStore::resource()) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn render_diagnostics_record_measurement(
  store : DiagnosticsStore,
  tick : Int,
  path : DiagnosticPath,
  value : Int,
) -> Unit {
  match store.get_ref(path) {
    Some(diagnostic_ref) => {
      if !diagnostic_ref.val.is_enabled() {
        return
      }
      diagnostic_ref.val.add_measurement(
        DiagnosticMeasurement::new(@core.Instant::now(), Float::from_int(value)),
        tick,
      )
    }
    None => ()
  }
}

///|
fn render_diagnostics_record_measurement_float(
  store : DiagnosticsStore,
  tick : Int,
  path : DiagnosticPath,
  value : Float,
) -> Unit {
  match store.get_ref(path) {
    Some(diagnostic_ref) => {
      if !diagnostic_ref.val.is_enabled() {
        return
      }
      diagnostic_ref.val.add_measurement(
        DiagnosticMeasurement::new(@core.Instant::now(), value),
        tick,
      )
    }
    None => ()
  }
}

///|
fn render_diagnostics_record_snapshot(
  store : DiagnosticsStore,
  tick : Int,
  snapshot : RenderDiagnosticsMeasurements,
) -> Unit {
  if snapshot.prepared_cameras_2d is Some(value) {
    render_diagnostics_record_measurement(
      store, tick, render_diagnostic_prepared_cameras_2d, value,
    )
  }
  if snapshot.queued_draw_items_2d is Some(value) {
    render_diagnostics_record_measurement(
      store, tick, render_diagnostic_queued_draw_items_2d, value,
    )
  }
  if snapshot.queue_cpu_ms_2d is Some(value) {
    render_diagnostics_record_measurement_float(
      store, tick, render_diagnostic_queue_cpu_ms_2d, value,
    )
  }
  if snapshot.execute_cpu_ms_2d is Some(value) {
    render_diagnostics_record_measurement_float(
      store, tick, render_diagnostic_execute_cpu_ms_2d, value,
    )
  }
  if snapshot.prepared_cameras_3d is Some(value) {
    render_diagnostics_record_measurement(
      store, tick, render_diagnostic_prepared_cameras_3d, value,
    )
  }
  if snapshot.visible_meshes_3d is Some(value) {
    render_diagnostics_record_measurement(
      store, tick, render_diagnostic_visible_meshes_3d, value,
    )
  }
  if snapshot.queue_cpu_ms_3d is Some(value) {
    render_diagnostics_record_measurement_float(
      store, tick, render_diagnostic_queue_cpu_ms_3d, value,
    )
  }
  if snapshot.execute_cpu_ms_3d is Some(value) {
    render_diagnostics_record_measurement_float(
      store, tick, render_diagnostic_execute_cpu_ms_3d, value,
    )
  }
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_pass_total_count,
    snapshot.pass_total_count,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_pass_2d_count,
    snapshot.pass_2d_count,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_pass_3d_main_count,
    snapshot.pass_3d_main_count,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_pass_3d_motion_vector_count,
    snapshot.pass_3d_motion_vector_count,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_pass_3d_point_shadow_count,
    snapshot.pass_3d_point_shadow_count,
  )
  render_diagnostics_record_measurement_float(
    store,
    tick,
    render_diagnostic_pass_total_cpu_ms,
    snapshot.pass_total_cpu_ms,
  )
  render_diagnostics_record_measurement_float(
    store,
    tick,
    render_diagnostic_pass_2d_cpu_ms,
    snapshot.pass_2d_cpu_ms,
  )
  render_diagnostics_record_measurement_float(
    store,
    tick,
    render_diagnostic_pass_3d_main_cpu_ms,
    snapshot.pass_3d_main_cpu_ms,
  )
  render_diagnostics_record_measurement_float(
    store,
    tick,
    render_diagnostic_pass_3d_motion_vector_cpu_ms,
    snapshot.pass_3d_motion_vector_cpu_ms,
  )
  render_diagnostics_record_measurement_float(
    store,
    tick,
    render_diagnostic_pass_3d_point_shadow_cpu_ms,
    snapshot.pass_3d_point_shadow_cpu_ms,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_mesh2d_draw_calls,
    snapshot.mesh2d_draw_calls,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_mesh2d_executed_draw_calls,
    snapshot.mesh2d_executed_draw_calls,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_mesh3d_draw_calls,
    snapshot.mesh3d_draw_calls,
  )
  render_diagnostics_record_measurement(
    store,
    tick,
    render_diagnostic_mesh3d_executed_draw_calls,
    snapshot.mesh3d_executed_draw_calls,
  )
}

///|
fn render_diagnostics_collect_snapshot(
  world : @ecs.World,
) -> RenderDiagnosticsMeasurements {
  let gpu_snapshot = @render.render_diagnostics_snapshot()
  RenderDiagnosticsMeasurements::{
    prepared_cameras_2d: Some(
      @sprite_render.render2d_diagnostic_prepared_camera_count(),
    ),
    queued_draw_items_2d: Some(
      @sprite_render.render2d_diagnostic_queued_draw_item_count(),
    ),
    queue_cpu_ms_2d: Some(@sprite_render.render2d_diagnostic_queue_cpu_ms()),
    execute_cpu_ms_2d: Some(@sprite_render.render2d_diagnostic_execute_cpu_ms()),
    prepared_cameras_3d: Some(
      @pbr.render3d_diagnostic_prepared_camera_count(world),
    ),
    visible_meshes_3d: Some(
      @pbr.render3d_diagnostic_queued_visible_mesh_count(world),
    ),
    queue_cpu_ms_3d: Some(@pbr.render3d_diagnostic_queue_cpu_ms(world)),
    execute_cpu_ms_3d: Some(@pbr.render3d_diagnostic_execute_cpu_ms(world)),
    pass_total_count: gpu_snapshot.pass_total_count,
    pass_2d_count: gpu_snapshot.pass_2d_count,
    pass_3d_main_count: gpu_snapshot.pass_3d_main_count,
    pass_3d_motion_vector_count: gpu_snapshot.pass_3d_motion_vector_count,
    pass_3d_point_shadow_count: gpu_snapshot.pass_3d_point_shadow_count,
    pass_total_cpu_ms: gpu_snapshot.pass_total_cpu_ms,
    pass_2d_cpu_ms: gpu_snapshot.pass_2d_cpu_ms,
    pass_3d_main_cpu_ms: gpu_snapshot.pass_3d_main_cpu_ms,
    pass_3d_motion_vector_cpu_ms: gpu_snapshot.pass_3d_motion_vector_cpu_ms,
    pass_3d_point_shadow_cpu_ms: gpu_snapshot.pass_3d_point_shadow_cpu_ms,
    mesh2d_draw_calls: gpu_snapshot.mesh2d_draw_calls,
    mesh2d_executed_draw_calls: gpu_snapshot.mesh2d_executed_draw_calls,
    mesh3d_draw_calls: gpu_snapshot.mesh3d_draw_calls,
    mesh3d_executed_draw_calls: gpu_snapshot.mesh3d_executed_draw_calls,
  }
}

///|
fn render_diagnostics_system(world : @ecs.World) -> Unit {
  let sequence = @app.current_system_sequence().this_run
  guard render_diagnostics_store_ref_mut(world) is Some(store_ref) else {
    return
  }
  render_diagnostics_record_snapshot(
    store_ref.val,
    sequence,
    render_diagnostics_collect_snapshot(world),
  )
}
