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

// Bevy-aligned `pbr/render` entrypoint container.

///|
pub fn render3d_queue_diagnostics_snapshot() -> (Int, Int, Float, Float) {
  (
    render3d_diagnostic_prepared_camera_count(),
    render3d_diagnostic_queued_visible_mesh_count(),
    render3d_diagnostic_queue_cpu_ms(),
    render3d_diagnostic_execute_cpu_ms(),
  )
}

///|
pub fn render3d_camera_depth_for_mesh(
  camera_transform : @transform.Transform,
  mesh_transform : @transform.Transform,
) -> Float {
  render3d_mesh_view_depth(mesh_transform, camera_transform)
}

///|
pub fn render3d_build_mesh_view_bindings(
  target_info : RenderTargetComputed3d,
  camera_transform : @transform.Transform,
) -> MeshViewBindings3d {
  render3d_mesh_view_bindings(target_info, camera_transform)
}
