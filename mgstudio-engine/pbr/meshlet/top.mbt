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
pub const HAS_MESHLET_RUNTIME : Bool = false

///|
pub fn meshlet_runtime_available() -> Bool {
  HAS_MESHLET_RUNTIME
}

///|
pub(all) enum MeshletRuntimeStatus {
  Disabled
  RuntimeUnavailable
}

///|
pub fn meshlet_runtime_status() -> MeshletRuntimeStatus {
  if meshlet_runtime_available() {
    MeshletRuntimeStatus::Disabled
  } else {
    MeshletRuntimeStatus::RuntimeUnavailable
  }
}

///|
pub struct MeshletPlugin {
  status : MeshletRuntimeStatus
}

///|
pub fn MeshletPlugin::default() -> MeshletPlugin {
  MeshletPlugin::{ status: meshlet_runtime_status() }
}

///|
pub fn meshlet_plugin() -> MeshletPlugin {
  MeshletPlugin::default()
}

///|
pub struct MeshletMesh3d {
  meshlet_mesh_id : Int
}

///|
pub fn MeshletMesh3d::new(meshlet_mesh_id : Int) -> MeshletMesh3d {
  MeshletMesh3d::{ meshlet_mesh_id, }
}
