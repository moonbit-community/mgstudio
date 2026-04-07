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
  render3d_diagnostic_queued_visible_mesh_count_ref.val
}

///|
pub fn render3d_diagnostic_prepared_camera_count() -> Int {
  render3d_diagnostic_prepared_camera_count_ref.val
}

///|
pub fn render3d_diagnostic_queue_cpu_ms() -> Float {
  render3d_diagnostic_queue_cpu_ms_ref.val
}

///|
pub fn render3d_diagnostic_execute_cpu_ms() -> Float {
  render3d_diagnostic_execute_cpu_ms_ref.val
}

///|
pub fn render3d_prepared_camera_count() -> Int? {
  if !render3d_runtime_initialized_ref.val {
    return Some(0)
  }
  Some(render3d_diagnostic_prepared_camera_count_ref.val)
}

///|
pub fn render3d_queued_visible_mesh_count() -> Int? {
  if !render3d_runtime_initialized_ref.val {
    return Some(0)
  }
  Some(render3d_diagnostic_queued_visible_mesh_count_ref.val)
}
