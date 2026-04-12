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
pub const MESHLET_MESH_ASSET_MAGIC : Int = 1717551717

///|
pub const MESHLET_MESH_ASSET_VERSION : Int = 3

///|
pub struct MeshletMesh {
  meshlet_count : Int
  bvh_node_count : Int
  vertex_position_word_count : Int
  vertex_normal_word_count : Int
  vertex_uv_count : Int
  index_count : Int
  bvh_depth : Int
}

///|
pub fn MeshletMesh::new(
  meshlet_count : Int,
  bvh_node_count : Int,
) -> MeshletMesh {
  MeshletMesh::{
    meshlet_count: meshlet_non_negative(meshlet_count),
    bvh_node_count: meshlet_non_negative(bvh_node_count),
    vertex_position_word_count: 0,
    vertex_normal_word_count: 0,
    vertex_uv_count: 0,
    index_count: 0,
    bvh_depth: 0,
  }
}

///|
fn meshlet_non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub fn MeshletMesh::with_vertex_buffers(
  self : MeshletMesh,
  vertex_position_word_count : Int,
  vertex_normal_word_count : Int,
  vertex_uv_count : Int,
  index_count : Int,
) -> MeshletMesh {
  MeshletMesh::{
    ..self,
    vertex_position_word_count: meshlet_non_negative(vertex_position_word_count),
    vertex_normal_word_count: meshlet_non_negative(vertex_normal_word_count),
    vertex_uv_count: meshlet_non_negative(vertex_uv_count),
    index_count: meshlet_non_negative(index_count),
  }
}

///|
pub fn MeshletMesh::with_bvh_depth(
  self : MeshletMesh,
  bvh_depth : Int,
) -> MeshletMesh {
  MeshletMesh::{ ..self, bvh_depth: meshlet_non_negative(bvh_depth) }
}

///|
pub fn MeshletMesh::vertex_count_estimate(self : MeshletMesh) -> Int {
  self.vertex_uv_count
}

///|
pub fn MeshletMesh::is_empty(self : MeshletMesh) -> Bool {
  self.meshlet_count <= 0 || self.index_count <= 0
}

///|
pub fn meshlet_mesh_asset_magic() -> Int {
  MESHLET_MESH_ASSET_MAGIC
}

///|
pub fn meshlet_mesh_asset_version() -> Int {
  MESHLET_MESH_ASSET_VERSION
}

///|
pub struct BvhNode {
  left_child : Int
  right_child : Int
  parent : Int
  child_count : Int
}

///|
pub fn BvhNode::leaf(index : Int) -> BvhNode {
  BvhNode::{
    left_child: index,
    right_child: -1,
    parent: -1,
    child_count: if index < 0 {
      0
    } else {
      1
    },
  }
}

///|
pub fn BvhNode::with_children(
  self : BvhNode,
  left_child : Int,
  right_child : Int,
) -> BvhNode {
  BvhNode::{
    ..self,
    left_child,
    right_child,
    child_count: if right_child < 0 {
      1
    } else {
      2
    },
  }
}

///|
pub struct Meshlet {
  start_vertex_position_bit : Int
  start_vertex_attribute_id : Int
  start_index_id : Int
  vertex_count_minus_one : Int
  triangle_count : Int
  bits_per_vertex_position_channel_x : Int
  bits_per_vertex_position_channel_y : Int
  bits_per_vertex_position_channel_z : Int
  vertex_position_quantization_factor : Int
}

///|
pub fn Meshlet::new(
  start_vertex_position_bit : Int,
  start_vertex_attribute_id : Int,
  start_index_id : Int,
  vertex_count : Int,
  triangle_count : Int,
) -> Meshlet {
  Meshlet::{
    start_vertex_position_bit: meshlet_non_negative(start_vertex_position_bit),
    start_vertex_attribute_id: meshlet_non_negative(start_vertex_attribute_id),
    start_index_id: meshlet_non_negative(start_index_id),
    vertex_count_minus_one: if vertex_count <= 0 {
      0
    } else {
      vertex_count - 1
    },
    triangle_count: meshlet_non_negative(triangle_count),
    bits_per_vertex_position_channel_x: 0,
    bits_per_vertex_position_channel_y: 0,
    bits_per_vertex_position_channel_z: 0,
    vertex_position_quantization_factor: 0,
  }
}

///|
pub fn Meshlet::vertex_count(self : Meshlet) -> Int {
  self.vertex_count_minus_one + 1
}

///|
pub fn Meshlet::with_quantization(
  self : Meshlet,
  bits_x : Int,
  bits_y : Int,
  bits_z : Int,
  factor : Int,
) -> Meshlet {
  Meshlet::{
    ..self,
    bits_per_vertex_position_channel_x: meshlet_non_negative(bits_x),
    bits_per_vertex_position_channel_y: meshlet_non_negative(bits_y),
    bits_per_vertex_position_channel_z: meshlet_non_negative(bits_z),
    vertex_position_quantization_factor: meshlet_non_negative(factor),
  }
}

///|
pub struct MeshletCullData {
  aabb : MeshletAabbErrorOffset
  lod_group_sphere : MeshletBoundingSphere
}

///|
pub fn MeshletCullData::default() -> MeshletCullData {
  MeshletCullData::{
    aabb: MeshletAabbErrorOffset::default(),
    lod_group_sphere: MeshletBoundingSphere::default(),
  }
}

///|
pub struct MeshletAabb {
  center_x : Float
  center_y : Float
  center_z : Float
  half_extent_x : Float
  half_extent_y : Float
  half_extent_z : Float
}

///|
pub fn MeshletAabb::default() -> MeshletAabb {
  MeshletAabb::{
    center_x: 0.0,
    center_y: 0.0,
    center_z: 0.0,
    half_extent_x: 0.0,
    half_extent_y: 0.0,
    half_extent_z: 0.0,
  }
}

///|
pub struct MeshletAabbErrorOffset {
  center_x : Float
  center_y : Float
  center_z : Float
  error : Float
  half_extent_x : Float
  half_extent_y : Float
  half_extent_z : Float
  child_offset : Int
}

///|
pub fn MeshletAabbErrorOffset::default() -> MeshletAabbErrorOffset {
  MeshletAabbErrorOffset::{
    center_x: 0.0,
    center_y: 0.0,
    center_z: 0.0,
    error: 0.0,
    half_extent_x: 0.0,
    half_extent_y: 0.0,
    half_extent_z: 0.0,
    child_offset: 0,
  }
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
  WrongFileType
  WrongVersion(Int)
  CompressionOrDecompression(String)
  IoError(String)
}

///|
pub fn meshlet_mesh_save_or_load_error_debug_message(
  error : MeshletMeshSaveOrLoadError,
) -> String {
  match error {
    WrongFileType => "wrong file type"
    WrongVersion(found) => "wrong version: \{found}"
    CompressionOrDecompression(reason) =>
      "compression/decompression failed: \{reason}"
    IoError(reason) => "io error: \{reason}"
  }
}

///|
pub fn meshlet_mesh_asset_version_matches(version : Int) -> Bool {
  version == MESHLET_MESH_ASSET_VERSION
}

///|
pub fn meshlet_asset_runtime_available() -> Bool {
  meshlet_runtime_available()
}
