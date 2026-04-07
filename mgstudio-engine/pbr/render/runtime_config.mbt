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
pub fn render3d_default_time_or_default(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in render3d systems")
  }
}

///|
pub fn render3d_gpu_preprocess_forced_disabled() -> Bool {
  @render_gpu.host_gpu_mesh3d_preprocess_disabled()
}

///|
pub fn render3d_use_gpu_instance_buffer_builder(
  use_gpu_instance_buffer_builder : Bool,
) -> Bool {
  use_gpu_instance_buffer_builder && !render3d_gpu_preprocess_forced_disabled()
}

///|
pub fn render3d_gpu_culling_supported() -> Bool {
  @render_gpu.host_gpu_mesh3d_gpu_culling_supported()
}

///|
pub fn render3d_camera_indirect_enabled(
  use_gpu_instance_buffer_builder : Bool,
  gpu_culling_supported : Bool,
  no_indirect_drawing : Bool,
) -> Bool {
  use_gpu_instance_buffer_builder &&
  gpu_culling_supported &&
  !no_indirect_drawing
}
