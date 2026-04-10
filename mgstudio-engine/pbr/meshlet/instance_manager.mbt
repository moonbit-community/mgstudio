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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/instance_manager.rs`.

///|
pub struct InstanceManager {
  mut instance_count : Int
}

///|
pub fn InstanceManager::default() -> InstanceManager {
  InstanceManager::{ instance_count: 0 }
}

///|
fn non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub fn InstanceManager::set_instance_count(
  self : InstanceManager,
  count : Int,
) -> Unit {
  self.instance_count = non_negative(count)
}

///|
pub fn InstanceManager::instance_count(self : InstanceManager) -> Int {
  self.instance_count
}

///|
pub fn extract_meshlet_mesh_entities(instance_count : Int) -> InstanceManager {
  InstanceManager::{ instance_count: non_negative(instance_count) }
}

///|
pub fn queue_material_meshlet_meshes(instance_manager : InstanceManager) -> Int {
  instance_manager.instance_count()
}

///|
pub fn meshlet_instance_manager_runtime_available() -> Bool {
  meshlet_runtime_available()
}
