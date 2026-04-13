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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/mod.rs`.

///|
pub const MESHLET_MAX_CLUSTER_BUFFER_SLOTS : Int = 33_554_432

///|
pub fn meshlet_required_wgpu_features() -> UInt64 {
  @renderer.meshlet_required_rust_features_u64()
}

///|
pub fn meshlet_runtime_available() -> Bool {
  @renderer.meshlet_required_features_supported()
}

///|
pub(all) enum MeshletRuntimeStatus {
  Enabled
  Disabled
  RuntimeUnavailable
}

///|
pub fn meshlet_runtime_status() -> MeshletRuntimeStatus {
  if !meshlet_runtime_available() {
    return MeshletRuntimeStatus::RuntimeUnavailable
  }
  MeshletRuntimeStatus::Disabled
}

///|
pub struct MeshletPlugin {
  cluster_buffer_slots : Int
  status : MeshletRuntimeStatus
}

///|
fn meshlet_cluster_buffer_slots_sanitize(value : Int) -> Int {
  if value <= 0 {
    1
  } else if value > MESHLET_MAX_CLUSTER_BUFFER_SLOTS {
    MESHLET_MAX_CLUSTER_BUFFER_SLOTS
  } else {
    value
  }
}

///|
pub fn MeshletPlugin::new(cluster_buffer_slots : Int) -> MeshletPlugin {
  MeshletPlugin::{
    cluster_buffer_slots: meshlet_cluster_buffer_slots_sanitize(
      cluster_buffer_slots,
    ),
    status: meshlet_runtime_status(),
  }
}

///|
pub fn MeshletPlugin::required_wgpu_features() -> UInt64 {
  meshlet_required_wgpu_features()
}

///|
pub fn MeshletPlugin::cluster_buffer_slots(self : MeshletPlugin) -> Int {
  self.cluster_buffer_slots
}

///|
pub fn MeshletPlugin::default() -> MeshletPlugin {
  MeshletPlugin::new(1_048_576)
}

///|
pub fn meshlet_plugin() -> MeshletPlugin {
  MeshletPlugin::default()
}

///|
pub struct MeshletPluginState {
  runtime_status : MeshletRuntimeStatus
  adapter_supports_mesh_shader : Bool
}

///|
pub fn MeshletPluginState::default() -> MeshletPluginState {
  MeshletPluginState::{
    runtime_status: meshlet_runtime_status(),
    adapter_supports_mesh_shader: false,
  }
}

///|
pub struct MeshletMesh3d {
  meshlet_mesh_id : Int
}

///|
pub fn MeshletMesh3d::new(meshlet_mesh_id : Int) -> MeshletMesh3d {
  MeshletMesh3d::{ meshlet_mesh_id, }
}

///|
pub fn MeshletMesh3d::id(self : MeshletMesh3d) -> Int {
  self.meshlet_mesh_id
}
