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

// Bevy-aligned render module anchor.

///|
pub fn render3d_gpu_preprocess_enabled() -> Bool {
  !render3d_gpu_preprocess_forced_disabled()
}

///|
pub fn render3d_gpu_preprocess_builder_enabled(
  use_gpu_instance_buffer_builder : Bool,
) -> Bool {
  render3d_use_gpu_instance_buffer_builder(use_gpu_instance_buffer_builder)
}

///|
pub fn render3d_gpu_preprocess_camera_indirect_enabled(
  use_gpu_instance_buffer_builder : Bool,
  no_indirect_drawing : Bool,
) -> Bool {
  let gpu_culling_supported = render3d_gpu_culling_supported()
  render3d_camera_indirect_enabled(
    use_gpu_instance_buffer_builder, gpu_culling_supported, no_indirect_drawing,
  )
}
