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
pub struct GltfSceneIndex {
  scene_index : Int
}

///|
let gltf_scene_index_component_key : @ecs.ComponentKey[GltfSceneIndex] = @ecs.register_component(
  debug_name="gltf.scene_index",
)

///|
pub impl @ecs.Component for GltfSceneIndex with component() {
  gltf_scene_index_component_key
}

///|
pub fn GltfSceneIndex::new(scene_index : Int) -> GltfSceneIndex {
  { scene_index, }
}

///|
pub fn GltfSceneIndex::index(self : GltfSceneIndex) -> Int {
  self.scene_index
}

///|
pub struct GltfNodeIndex {
  node_index : Int
}

///|
let gltf_node_index_component_key : @ecs.ComponentKey[GltfNodeIndex] = @ecs.register_component(
  debug_name="gltf.node_index",
)

///|
pub impl @ecs.Component for GltfNodeIndex with component() {
  gltf_node_index_component_key
}

///|
pub fn GltfNodeIndex::new(node_index : Int) -> GltfNodeIndex {
  { node_index, }
}

///|
pub fn GltfNodeIndex::index(self : GltfNodeIndex) -> Int {
  self.node_index
}

///|
pub struct GltfMeshIndex {
  mesh_index : Int
}

///|
let gltf_mesh_index_component_key : @ecs.ComponentKey[GltfMeshIndex] = @ecs.register_component(
  debug_name="gltf.mesh_index",
)

///|
pub impl @ecs.Component for GltfMeshIndex with component() {
  gltf_mesh_index_component_key
}

///|
pub fn GltfMeshIndex::new(mesh_index : Int) -> GltfMeshIndex {
  { mesh_index, }
}

///|
pub fn GltfMeshIndex::index(self : GltfMeshIndex) -> Int {
  self.mesh_index
}

///|
pub struct GltfPrimitiveIndex {
  mesh_index : Int
  primitive_index : Int
}

///|
let gltf_primitive_index_component_key : @ecs.ComponentKey[GltfPrimitiveIndex] = @ecs.register_component(
  debug_name="gltf.primitive_index",
)

///|
pub impl @ecs.Component for GltfPrimitiveIndex with component() {
  gltf_primitive_index_component_key
}

///|
pub fn GltfPrimitiveIndex::new(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfPrimitiveIndex {
  { mesh_index, primitive_index }
}

///|
pub fn GltfPrimitiveIndex::mesh_index(self : GltfPrimitiveIndex) -> Int {
  self.mesh_index
}

///|
pub fn GltfPrimitiveIndex::primitive_index(self : GltfPrimitiveIndex) -> Int {
  self.primitive_index
}
