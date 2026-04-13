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
pub fn render3d_diagnostic_queued_visible_mesh_count() -> Int {
  @pbr_render.render3d_diagnostic_queued_visible_mesh_count()
}

///|
pub fn render3d_diagnostic_prepared_camera_count() -> Int {
  @pbr_render.render3d_diagnostic_prepared_camera_count()
}

///|
pub fn render3d_diagnostic_queue_cpu_ms() -> Float {
  @pbr_render.render3d_diagnostic_queue_cpu_ms()
}

///|
pub fn render3d_diagnostic_execute_cpu_ms() -> Float {
  @pbr_render.render3d_diagnostic_execute_cpu_ms()
}

///|
pub fn render3d_prepared_camera_count() -> Int? {
  @pbr_render.render3d_prepared_camera_count()
}

///|
pub fn render3d_queued_visible_mesh_count() -> Int? {
  @pbr_render.render3d_queued_visible_mesh_count()
}

///|
pub struct Render3dDiagnosticsSnapshot {
  prepared_camera_count : Int
  queued_visible_mesh_count : Int
  queue_cpu_ms : Float
  execute_cpu_ms : Float
}

///|
pub fn Render3dDiagnosticsSnapshot::default() -> Render3dDiagnosticsSnapshot {
  Render3dDiagnosticsSnapshot::{
    prepared_camera_count: 0,
    queued_visible_mesh_count: 0,
    queue_cpu_ms: 0.0F,
    execute_cpu_ms: 0.0F,
  }
}

///|
pub fn render3d_diagnostics_snapshot() -> Render3dDiagnosticsSnapshot {
  Render3dDiagnosticsSnapshot::{
    prepared_camera_count: render3d_diagnostic_prepared_camera_count(),
    queued_visible_mesh_count: render3d_diagnostic_queued_visible_mesh_count(),
    queue_cpu_ms: render3d_diagnostic_queue_cpu_ms(),
    execute_cpu_ms: render3d_diagnostic_execute_cpu_ms(),
  }
}
