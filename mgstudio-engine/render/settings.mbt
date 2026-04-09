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
// Bevy source: `bevy/crates/bevy_render/src/settings.rs`.

///|
pub fn host_gpu_set_mesh3d_gpu_instance_builder_enabled(enabled : Bool) -> Unit {
  @renderer.set_mesh3d_gpu_instance_builder_enabled(enabled)
}

///|
pub fn host_gpu_mesh3d_indirect_first_instance_supported() -> Bool {
  @renderer.mesh3d_indirect_first_instance_supported()
}

///|
pub fn host_gpu_mesh3d_gpu_culling_supported() -> Bool {
  @renderer.mesh3d_gpu_culling_supported()
}

///|
pub fn host_gpu_mesh3d_preprocess_disabled() -> Bool {
  @renderer.mesh3d_preprocess_disabled()
}
