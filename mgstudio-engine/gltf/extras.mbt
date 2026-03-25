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
pub struct GltfExtras {
  value : String
}

///|
let gltf_extras_component_key : @ecs.ComponentKey[GltfExtras] = @ecs.register_component(
  debug_name="gltf.extras",
)

///|
pub impl @ecs.Component for GltfExtras with component() {
  gltf_extras_component_key
}

///|
pub fn GltfExtras::new(value : String) -> GltfExtras {
  { value, }
}

///|
pub fn GltfExtras::as_str(self : GltfExtras) -> String {
  self.value
}

///|
pub struct GltfSceneExtras {
  value : String
}

///|
let gltf_scene_extras_component_key : @ecs.ComponentKey[GltfSceneExtras] = @ecs.register_component(
  debug_name="gltf.scene_extras",
)

///|
pub impl @ecs.Component for GltfSceneExtras with component() {
  gltf_scene_extras_component_key
}

///|
pub fn GltfSceneExtras::new(value : String) -> GltfSceneExtras {
  { value, }
}

///|
pub fn GltfSceneExtras::as_str(self : GltfSceneExtras) -> String {
  self.value
}

///|
pub struct GltfMeshExtras {
  value : String
}

///|
let gltf_mesh_extras_component_key : @ecs.ComponentKey[GltfMeshExtras] = @ecs.register_component(
  debug_name="gltf.mesh_extras",
)

///|
pub impl @ecs.Component for GltfMeshExtras with component() {
  gltf_mesh_extras_component_key
}

///|
pub fn GltfMeshExtras::new(value : String) -> GltfMeshExtras {
  { value, }
}

///|
pub fn GltfMeshExtras::as_str(self : GltfMeshExtras) -> String {
  self.value
}

///|
pub struct GltfMaterialExtras {
  value : String
}

///|
let gltf_material_extras_component_key : @ecs.ComponentKey[GltfMaterialExtras] = @ecs.register_component(
  debug_name="gltf.material_extras",
)

///|
pub impl @ecs.Component for GltfMaterialExtras with component() {
  gltf_material_extras_component_key
}

///|
pub fn GltfMaterialExtras::new(value : String) -> GltfMaterialExtras {
  { value, }
}

///|
pub fn GltfMaterialExtras::as_str(self : GltfMaterialExtras) -> String {
  self.value
}
