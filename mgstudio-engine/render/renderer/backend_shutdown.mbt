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
fn GpuBackend::release_frame_surface_2d_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::release_mesh3d_pbr_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::release_preprocess_meshlet_motion_owners(
  _self : GpuBackend,
) -> Unit {

}

///|
fn GpuBackend::release_postprocess_feature_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::release_renderer_registry_owners(_self : GpuBackend) -> Unit {

}

///|
fn GpuBackend::shutdown(self : GpuBackend) -> Unit {
  if self.shutdown_complete {
    return
  }
  self.shutdown_complete = true
  ignore(self.device.poll(wait=true))
  self.release_frame_surface_2d_owners()
  self.release_mesh3d_pbr_owners()
  self.release_preprocess_meshlet_motion_owners()
  self.release_postprocess_feature_owners()
  self.release_renderer_registry_owners()
  self.queue.release()
  self.device.release()
  self.adapter.release()
  self.instance.release()
}
