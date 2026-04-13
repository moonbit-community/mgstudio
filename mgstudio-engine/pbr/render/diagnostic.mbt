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
pub struct Render3dDiagnosticsState {
  mut runtime_initialized : Bool
  mut queued_visible_mesh_count : Int
  mut prepared_camera_count : Int
  mut queue_cpu_ms : Float
  mut execute_cpu_ms : Float
}

///|
fn render3d_diagnostics_state_default() -> Render3dDiagnosticsState {
  Render3dDiagnosticsState::{
    runtime_initialized: false,
    queued_visible_mesh_count: 0,
    prepared_camera_count: 0,
    queue_cpu_ms: 0.0F,
    execute_cpu_ms: 0.0F,
  }
}

///|
let render3d_diagnostics_state_key : @ecs.ResourceKey[Render3dDiagnosticsState] = @ecs.register_resource(
  debug_name="mgstudio.render3d.diagnostics_state",
)

///|
impl @app.Resource for Render3dDiagnosticsState with resource() {
  render3d_diagnostics_state_key
}

///|
fn render3d_diagnostics_state_ref_or_init(
  world : @ecs.World,
) -> Ref[Render3dDiagnosticsState] {
  if (try! world.get_resource(Render3dDiagnosticsState::resource())) is None {
    world.insert_resource(
      Render3dDiagnosticsState::resource(),
      render3d_diagnostics_state_default(),
    )
  }
  match (try! world.get_resource_ref_mut(Render3dDiagnosticsState::resource())) {
    Some(state) => state
    None => abort("Missing Render3dDiagnosticsState resource")
  }
}

///|
pub fn render3d_set_runtime_initialized(
  world : @ecs.World,
  runtime_initialized : Bool,
) -> Unit {
  render3d_diagnostics_state_ref_or_init(world).val.runtime_initialized = runtime_initialized
}

///|
pub fn render3d_set_diagnostic_queued_visible_mesh_count(
  world : @ecs.World,
  count : Int,
) -> Unit {
  render3d_diagnostics_state_ref_or_init(
    world,
  ).val.queued_visible_mesh_count = count
}

///|
pub fn render3d_set_diagnostic_prepared_camera_count(
  world : @ecs.World,
  count : Int,
) -> Unit {
  render3d_diagnostics_state_ref_or_init(world).val.prepared_camera_count = count
}

///|
pub fn render3d_set_diagnostic_queue_cpu_ms(
  world : @ecs.World,
  queue_cpu_ms : Float,
) -> Unit {
  render3d_diagnostics_state_ref_or_init(world).val.queue_cpu_ms = queue_cpu_ms
}

///|
pub fn render3d_set_diagnostic_execute_cpu_ms(
  world : @ecs.World,
  execute_cpu_ms : Float,
) -> Unit {
  render3d_diagnostics_state_ref_or_init(world).val.execute_cpu_ms = execute_cpu_ms
}

///|
pub fn render3d_diagnostic_queued_visible_mesh_count(world : @ecs.World) -> Int {
  render3d_diagnostics_state_ref_or_init(world).val.queued_visible_mesh_count
}

///|
pub fn render3d_diagnostic_prepared_camera_count(world : @ecs.World) -> Int {
  render3d_diagnostics_state_ref_or_init(world).val.prepared_camera_count
}

///|
pub fn render3d_diagnostic_queue_cpu_ms(world : @ecs.World) -> Float {
  render3d_diagnostics_state_ref_or_init(world).val.queue_cpu_ms
}

///|
pub fn render3d_diagnostic_execute_cpu_ms(world : @ecs.World) -> Float {
  render3d_diagnostics_state_ref_or_init(world).val.execute_cpu_ms
}

///|
pub fn render3d_prepared_camera_count(world : @ecs.World) -> Int? {
  let state = render3d_diagnostics_state_ref_or_init(world).val
  if !state.runtime_initialized {
    return Some(0)
  }
  Some(state.prepared_camera_count)
}

///|
pub fn render3d_queued_visible_mesh_count(world : @ecs.World) -> Int? {
  let state = render3d_diagnostics_state_ref_or_init(world).val
  if !state.runtime_initialized {
    return Some(0)
  }
  Some(state.queued_visible_mesh_count)
}
