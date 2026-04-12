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
pub struct Render3dGpuPreprocessState {
  enabled : Bool
  use_gpu_instance_buffer_builder : Bool
  indirect_enabled : Bool
  last_dispatch_count : Int
}

///|
pub fn Render3dGpuPreprocessState::default() -> Render3dGpuPreprocessState {
  Render3dGpuPreprocessState::{
    enabled: true,
    use_gpu_instance_buffer_builder: true,
    indirect_enabled: true,
    last_dispatch_count: 0,
  }
}

///|
pub fn render3d_gpu_preprocess_state(
  use_gpu_instance_buffer_builder : Bool,
  no_indirect_drawing : Bool,
) -> Render3dGpuPreprocessState {
  let enabled = render3d_gpu_preprocess_enabled()
  let builder_enabled = render3d_gpu_preprocess_builder_enabled(
    use_gpu_instance_buffer_builder,
  )
  let indirect_enabled = render3d_gpu_preprocess_camera_indirect_enabled(
    use_gpu_instance_buffer_builder, no_indirect_drawing,
  )
  Render3dGpuPreprocessState::{
    enabled,
    use_gpu_instance_buffer_builder: builder_enabled,
    indirect_enabled,
    last_dispatch_count: 0,
  }
}

///|
pub fn render3d_gpu_preprocess_state_with_dispatch_count(
  state : Render3dGpuPreprocessState,
  dispatch_count : Int,
) -> Render3dGpuPreprocessState {
  Render3dGpuPreprocessState::{
    ..state,
    last_dispatch_count: if dispatch_count < 0 {
      0
    } else {
      dispatch_count
    },
  }
}

///|
pub fn Render3dGpuPreprocessState::enabled(
  self : Render3dGpuPreprocessState,
) -> Bool {
  self.enabled
}

///|
pub fn Render3dGpuPreprocessState::indirect_enabled(
  self : Render3dGpuPreprocessState,
) -> Bool {
  self.indirect_enabled
}

///|
pub fn Render3dGpuPreprocessState::dispatch_count(
  self : Render3dGpuPreprocessState,
) -> Int {
  self.last_dispatch_count
}

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
