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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/asset.rs`.

///|
pub struct MeshletMesh {
  meshlet_count : Int
  bvh_node_count : Int
}

///|
pub fn MeshletMesh::new(
  meshlet_count : Int,
  bvh_node_count : Int,
) -> MeshletMesh {
  MeshletMesh::{ meshlet_count, bvh_node_count }
}

///|
pub struct BvhNode {
  left_child : Int
  right_child : Int
  parent : Int
}

///|
pub fn BvhNode::leaf(index : Int) -> BvhNode {
  BvhNode::{ left_child: index, right_child: -1, parent: -1 }
}

///|
pub struct Meshlet {
  vertex_offset : Int
  vertex_count : Int
  triangle_offset : Int
  triangle_count : Int
}

///|
pub fn Meshlet::new(
  vertex_offset : Int,
  vertex_count : Int,
  triangle_offset : Int,
  triangle_count : Int,
) -> Meshlet {
  Meshlet::{ vertex_offset, vertex_count, triangle_offset, triangle_count }
}

///|
pub struct MeshletCullData {
  center_x : Float
  center_y : Float
  center_z : Float
  radius : Float
}

///|
pub fn MeshletCullData::default() -> MeshletCullData {
  MeshletCullData::{ center_x: 0.0, center_y: 0.0, center_z: 0.0, radius: 0.0 }
}

///|
pub struct MeshletAabb {
  min_x : Float
  min_y : Float
  min_z : Float
  max_x : Float
  max_y : Float
  max_z : Float
}

///|
pub fn MeshletAabb::default() -> MeshletAabb {
  MeshletAabb::{
    min_x: 0.0,
    min_y: 0.0,
    min_z: 0.0,
    max_x: 0.0,
    max_y: 0.0,
    max_z: 0.0,
  }
}

///|
pub struct MeshletAabbErrorOffset {
  x : Float
  y : Float
  z : Float
}

///|
pub fn MeshletAabbErrorOffset::default() -> MeshletAabbErrorOffset {
  MeshletAabbErrorOffset::{ x: 0.0, y: 0.0, z: 0.0 }
}

///|
pub struct MeshletBoundingSphere {
  center_x : Float
  center_y : Float
  center_z : Float
  radius : Float
}

///|
pub fn MeshletBoundingSphere::default() -> MeshletBoundingSphere {
  MeshletBoundingSphere::{
    center_x: 0.0,
    center_y: 0.0,
    center_z: 0.0,
    radius: 0.0,
  }
}

///|
pub struct MeshletMeshSaver {}

///|
pub fn meshlet_mesh_saver() -> MeshletMeshSaver {
  MeshletMeshSaver::{  }
}

///|
pub struct MeshletMeshLoader {}

///|
pub fn meshlet_mesh_loader() -> MeshletMeshLoader {
  MeshletMeshLoader::{  }
}

///|
pub(all) enum MeshletMeshSaveOrLoadError {
  RuntimeUnavailable
  InvalidFormat
  IoError(String)
}

///|
pub fn meshlet_asset_runtime_available() -> Bool {
  meshlet_runtime_available()
}
