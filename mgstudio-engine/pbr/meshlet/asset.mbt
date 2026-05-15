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
pub const MESHLET_MESH_ASSET_MAGIC : UInt64 = 1717551717668UL

///|
pub const MESHLET_MESH_ASSET_VERSION : UInt64 = 3UL

///|
const MESHLET_MESH_U32_MAX_AS_INT : UInt64 = 2147483647UL

///|
const MESHLET_LZ4_FRAME_MAGIC : UInt = 0x184D2204U

///|
const MESHLET_LZ4_BLOCK_UNCOMPRESSED_MASK : UInt = 0x80000000U

///|
const MESHLET_LZ4_DEFAULT_BLOCK_SIZE : Int = 65536

///|
const MESHLET_XXH32_PRIME1 : UInt = 0x9E3779B1U

///|
const MESHLET_XXH32_PRIME2 : UInt = 0x85EBCA77U

///|
const MESHLET_XXH32_PRIME3 : UInt = 0xC2B2AE3DU

///|
const MESHLET_XXH32_PRIME4 : UInt = 0x27D4EB2FU

///|
const MESHLET_XXH32_PRIME5 : UInt = 0x165667B1U

///|
pub struct MeshletMesh {
  vertex_positions : Array[Int]
  vertex_normals : Array[Int]
  vertex_uvs : Array[MeshletVertexUv]
  indices : Array[Int]
  bvh : Array[BvhNode]
  meshlets : Array[Meshlet]
  meshlet_cull_data : Array[MeshletCullData]
  aabb : MeshletAabb
  bvh_depth : Int
}

///|
pub fn MeshletMesh::new(
  meshlet_count : Int,
  bvh_node_count : Int,
) -> MeshletMesh {
  MeshletMesh::{
    vertex_positions: [],
    vertex_normals: [],
    vertex_uvs: [],
    indices: [],
    bvh: meshlet_default_bvh_nodes(bvh_node_count),
    meshlets: meshlet_default_meshlets(meshlet_count),
    meshlet_cull_data: meshlet_default_cull_data(meshlet_count),
    aabb: MeshletAabb::default(),
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
fn meshlet_zero_words(word_count : Int) -> Array[Int] {
  let values : Array[Int] = []
  for _ in 0..<meshlet_non_negative(word_count) {
    values.push(0)
  }
  values
}

///|
fn meshlet_default_uvs(uv_count : Int) -> Array[MeshletVertexUv] {
  let values : Array[MeshletVertexUv] = []
  for _ in 0..<meshlet_non_negative(uv_count) {
    values.push(MeshletVertexUv::default())
  }
  values
}

///|
fn meshlet_default_bvh_nodes(node_count : Int) -> Array[BvhNode] {
  let values : Array[BvhNode] = []
  for _ in 0..<meshlet_non_negative(node_count) {
    values.push(BvhNode::default())
  }
  values
}

///|
fn meshlet_default_meshlets(meshlet_count : Int) -> Array[Meshlet] {
  let values : Array[Meshlet] = []
  for _ in 0..<meshlet_non_negative(meshlet_count) {
    values.push(Meshlet::new(0, 0, 0, 3, 1))
  }
  values
}

///|
fn meshlet_default_cull_data(meshlet_count : Int) -> Array[MeshletCullData] {
  let values : Array[MeshletCullData] = []
  for _ in 0..<meshlet_non_negative(meshlet_count) {
    values.push(MeshletCullData::default())
  }
  values
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
    vertex_positions: meshlet_zero_words(vertex_position_word_count),
    vertex_normals: meshlet_zero_words(vertex_normal_word_count),
    vertex_uvs: meshlet_default_uvs(vertex_uv_count),
    indices: meshlet_zero_words(index_count),
  }
}

///|
pub fn MeshletMesh::from_parts(
  vertex_positions~ : Array[Int],
  vertex_normals~ : Array[Int],
  vertex_uvs~ : Array[MeshletVertexUv],
  indices~ : Array[Int],
  bvh~ : Array[BvhNode],
  meshlets~ : Array[Meshlet],
  meshlet_cull_data~ : Array[MeshletCullData],
  aabb? : MeshletAabb = MeshletAabb::default(),
  bvh_depth? : Int = 0,
) -> MeshletMesh {
  MeshletMesh::{
    vertex_positions,
    vertex_normals,
    vertex_uvs,
    indices,
    bvh,
    meshlets,
    meshlet_cull_data,
    aabb,
    bvh_depth: meshlet_non_negative(bvh_depth),
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
pub fn MeshletMesh::with_aabb(
  self : MeshletMesh,
  aabb : MeshletAabb,
) -> MeshletMesh {
  MeshletMesh::{ ..self, aabb, }
}

///|
pub fn MeshletMesh::meshlet_count(self : MeshletMesh) -> Int {
  self.meshlets.length()
}

///|
pub fn MeshletMesh::bvh_node_count(self : MeshletMesh) -> Int {
  self.bvh.length()
}

///|
pub fn MeshletMesh::vertex_position_word_count(self : MeshletMesh) -> Int {
  self.vertex_positions.length()
}

///|
pub fn MeshletMesh::vertex_normal_word_count(self : MeshletMesh) -> Int {
  self.vertex_normals.length()
}

///|
pub fn MeshletMesh::vertex_uv_count(self : MeshletMesh) -> Int {
  self.vertex_uvs.length()
}

///|
pub fn MeshletMesh::index_count(self : MeshletMesh) -> Int {
  self.indices.length()
}

///|
pub fn MeshletMesh::vertex_count_estimate(self : MeshletMesh) -> Int {
  self.vertex_uvs.length()
}

///|
pub fn MeshletMesh::is_empty(self : MeshletMesh) -> Bool {
  self.meshlets.is_empty() || self.indices.is_empty()
}

///|
pub fn meshlet_mesh_asset_magic() -> UInt64 {
  MESHLET_MESH_ASSET_MAGIC
}

///|
pub fn meshlet_mesh_asset_version() -> Int {
  MESHLET_MESH_ASSET_VERSION.to_int()
}

///|
pub struct BvhNode {
  aabbs : Array[MeshletAabbErrorOffset]
  lod_bounds : Array[MeshletBoundingSphere]
  child_counts : Array[Int]
  padding : Array[Int]
}

///|
pub fn BvhNode::default() -> BvhNode {
  let aabbs : Array[MeshletAabbErrorOffset] = []
  let lod_bounds : Array[MeshletBoundingSphere] = []
  let child_counts : Array[Int] = []
  for _ in 0..<8 {
    aabbs.push(MeshletAabbErrorOffset::default())
    lod_bounds.push(MeshletBoundingSphere::default())
    child_counts.push(0)
  }
  BvhNode::{ aabbs, lod_bounds, child_counts, padding: [0, 0] }
}

///|
pub fn BvhNode::with_child_count(
  self : BvhNode,
  child_index : Int,
  child_count : Int,
) -> BvhNode {
  let child_counts = self.child_counts
  if child_index >= 0 && child_index < child_counts.length() {
    child_counts[child_index] = meshlet_non_negative(child_count)
  }
  BvhNode::{ ..self, child_counts, }
}

///|
pub struct Meshlet {
  start_vertex_position_bit : Int
  start_vertex_attribute_id : Int
  start_index_id : Int
  vertex_count_minus_one : Int
  triangle_count : Int
  padding : Int
  bits_per_vertex_position_channel_x : Int
  bits_per_vertex_position_channel_y : Int
  bits_per_vertex_position_channel_z : Int
  vertex_position_quantization_factor : Int
  min_vertex_position_channel_x : Float
  min_vertex_position_channel_y : Float
  min_vertex_position_channel_z : Float
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
    padding: 0,
    bits_per_vertex_position_channel_x: 0,
    bits_per_vertex_position_channel_y: 0,
    bits_per_vertex_position_channel_z: 0,
    vertex_position_quantization_factor: 0,
    min_vertex_position_channel_x: 0.0,
    min_vertex_position_channel_y: 0.0,
    min_vertex_position_channel_z: 0.0,
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
pub fn Meshlet::with_min_vertex_position_channels(
  self : Meshlet,
  x : Float,
  y : Float,
  z : Float,
) -> Meshlet {
  Meshlet::{
    ..self,
    min_vertex_position_channel_x: x,
    min_vertex_position_channel_y: y,
    min_vertex_position_channel_z: z,
  }
}

///|
pub struct MeshletVertexUv {
  x : Float
  y : Float
}

///|
pub fn MeshletVertexUv::new(x : Float, y : Float) -> MeshletVertexUv {
  MeshletVertexUv::{ x, y }
}

///|
pub fn MeshletVertexUv::default() -> MeshletVertexUv {
  MeshletVertexUv::{ x: 0.0, y: 0.0 }
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
pub fn MeshletAabb::new(
  center_x~ : Float,
  center_y~ : Float,
  center_z~ : Float,
  half_extent_x~ : Float,
  half_extent_y~ : Float,
  half_extent_z~ : Float,
) -> MeshletAabb {
  MeshletAabb::{
    center_x,
    center_y,
    center_z,
    half_extent_x,
    half_extent_y,
    half_extent_z,
  }
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
  WrongVersion(UInt64)
  CompressionOrDecompression(String)
  IoError(String)
}

///|
pub(all) enum MeshletMeshLoadResult {
  MeshletMeshLoadOk(MeshletMesh)
  MeshletMeshLoadErr(MeshletMeshSaveOrLoadError)
}

///|
priv enum MeshletLz4FrameResult {
  MeshletLz4FrameOk(Bytes)
  MeshletLz4FrameErr(String)
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
  version.to_uint64() == MESHLET_MESH_ASSET_VERSION
}

///|
pub fn meshlet_mesh_asset_extensions() -> Array[String] {
  ["meshlet_mesh"]
}

///|
pub fn MeshletMeshSaver::save_bytes(
  self : MeshletMeshSaver,
  mesh : MeshletMesh,
) -> Bytes {
  ignore(self)
  meshlet_mesh_encode_bevy_bytes(mesh)
}

///|
pub fn MeshletMeshLoader::load_bytes(
  self : MeshletMeshLoader,
  bytes : Bytes,
) -> MeshletMeshLoadResult {
  ignore(self)
  meshlet_mesh_decode_bevy_bytes(bytes)
}

///|
pub fn MeshletMeshLoader::extensions(self : MeshletMeshLoader) -> Array[String] {
  ignore(self)
  meshlet_mesh_asset_extensions()
}

///|
fn meshlet_push_bytes(out : Array[Byte], bytes : Bytes) -> Unit {
  for index in 0..<bytes.length() {
    match bytes.get(index) {
      Some(value) => out.push(value)
      None => ()
    }
  }
}

///|
fn meshlet_push_u8(out : Array[Byte], value : Int) -> Unit {
  out.push((value & 0xFF).to_byte())
}

///|
fn meshlet_push_u16_le(out : Array[Byte], value : UInt) -> Unit {
  out.push(value.to_byte())
  out.push((value >> 8).to_byte())
}

///|
fn meshlet_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push(value.to_byte())
  out.push((value >> 8).to_byte())
  out.push((value >> 16).to_byte())
  out.push((value >> 24).to_byte())
}

///|
fn meshlet_push_u64_le(out : Array[Byte], value : UInt64) -> Unit {
  meshlet_push_bytes(out, value.to_le_bytes())
}

///|
fn meshlet_push_f32_le(out : Array[Byte], value : Float) -> Unit {
  meshlet_push_u32_le(out, value.reinterpret_as_uint())
}

///|
fn meshlet_push_aabb(out : Array[Byte], aabb : MeshletAabb) -> Unit {
  meshlet_push_f32_le(out, aabb.center_x)
  meshlet_push_f32_le(out, aabb.center_y)
  meshlet_push_f32_le(out, aabb.center_z)
  meshlet_push_f32_le(out, aabb.half_extent_x)
  meshlet_push_f32_le(out, aabb.half_extent_y)
  meshlet_push_f32_le(out, aabb.half_extent_z)
}

///|
fn meshlet_push_aabb_error_offset(
  out : Array[Byte],
  aabb : MeshletAabbErrorOffset,
) -> Unit {
  meshlet_push_f32_le(out, aabb.center_x)
  meshlet_push_f32_le(out, aabb.center_y)
  meshlet_push_f32_le(out, aabb.center_z)
  meshlet_push_f32_le(out, aabb.error)
  meshlet_push_f32_le(out, aabb.half_extent_x)
  meshlet_push_f32_le(out, aabb.half_extent_y)
  meshlet_push_f32_le(out, aabb.half_extent_z)
  meshlet_push_u32_le(out, aabb.child_offset.reinterpret_as_uint())
}

///|
fn meshlet_push_bounding_sphere(
  out : Array[Byte],
  sphere : MeshletBoundingSphere,
) -> Unit {
  meshlet_push_f32_le(out, sphere.center_x)
  meshlet_push_f32_le(out, sphere.center_y)
  meshlet_push_f32_le(out, sphere.center_z)
  meshlet_push_f32_le(out, sphere.radius)
}

///|
fn meshlet_push_bvh_node(out : Array[Byte], node : BvhNode) -> Unit {
  for index in 0..<8 {
    if index < node.aabbs.length() {
      meshlet_push_aabb_error_offset(out, node.aabbs[index])
    } else {
      meshlet_push_aabb_error_offset(out, MeshletAabbErrorOffset::default())
    }
  }
  for index in 0..<8 {
    if index < node.lod_bounds.length() {
      meshlet_push_bounding_sphere(out, node.lod_bounds[index])
    } else {
      meshlet_push_bounding_sphere(out, MeshletBoundingSphere::default())
    }
  }
  for index in 0..<8 {
    if index < node.child_counts.length() {
      meshlet_push_u8(out, node.child_counts[index])
    } else {
      meshlet_push_u8(out, 0)
    }
  }
  for index in 0..<2 {
    if index < node.padding.length() {
      meshlet_push_u32_le(out, node.padding[index].reinterpret_as_uint())
    } else {
      meshlet_push_u32_le(out, 0U)
    }
  }
}

///|
fn meshlet_push_meshlet(out : Array[Byte], meshlet : Meshlet) -> Unit {
  meshlet_push_u32_le(
    out,
    meshlet.start_vertex_position_bit.reinterpret_as_uint(),
  )
  meshlet_push_u32_le(
    out,
    meshlet.start_vertex_attribute_id.reinterpret_as_uint(),
  )
  meshlet_push_u32_le(out, meshlet.start_index_id.reinterpret_as_uint())
  meshlet_push_u8(out, meshlet.vertex_count_minus_one)
  meshlet_push_u8(out, meshlet.triangle_count)
  meshlet_push_u16_le(out, meshlet.padding.reinterpret_as_uint())
  meshlet_push_u8(out, meshlet.bits_per_vertex_position_channel_x)
  meshlet_push_u8(out, meshlet.bits_per_vertex_position_channel_y)
  meshlet_push_u8(out, meshlet.bits_per_vertex_position_channel_z)
  meshlet_push_u8(out, meshlet.vertex_position_quantization_factor)
  meshlet_push_f32_le(out, meshlet.min_vertex_position_channel_x)
  meshlet_push_f32_le(out, meshlet.min_vertex_position_channel_y)
  meshlet_push_f32_le(out, meshlet.min_vertex_position_channel_z)
}

///|
fn meshlet_push_cull_data(
  out : Array[Byte],
  cull_data : MeshletCullData,
) -> Unit {
  meshlet_push_aabb_error_offset(out, cull_data.aabb)
  meshlet_push_bounding_sphere(out, cull_data.lod_group_sphere)
}

///|
fn meshlet_push_slice_len(out : Array[Byte], length : Int) -> Unit {
  meshlet_push_u64_le(out, meshlet_non_negative(length).to_uint64())
}

///|
fn meshlet_push_u32_slice(out : Array[Byte], values : Array[Int]) -> Unit {
  meshlet_push_slice_len(out, values.length())
  for value in values {
    meshlet_push_u32_le(out, value.reinterpret_as_uint())
  }
}

///|
fn meshlet_push_u8_slice(out : Array[Byte], values : Array[Int]) -> Unit {
  meshlet_push_slice_len(out, values.length())
  for value in values {
    meshlet_push_u8(out, value)
  }
}

///|
fn meshlet_push_uv_slice(
  out : Array[Byte],
  values : Array[MeshletVertexUv],
) -> Unit {
  meshlet_push_slice_len(out, values.length())
  for value in values {
    meshlet_push_f32_le(out, value.x)
    meshlet_push_f32_le(out, value.y)
  }
}

///|
fn meshlet_push_bvh_slice(out : Array[Byte], values : Array[BvhNode]) -> Unit {
  meshlet_push_slice_len(out, values.length())
  for value in values {
    meshlet_push_bvh_node(out, value)
  }
}

///|
fn meshlet_push_meshlet_slice(
  out : Array[Byte],
  values : Array[Meshlet],
) -> Unit {
  meshlet_push_slice_len(out, values.length())
  for value in values {
    meshlet_push_meshlet(out, value)
  }
}

///|
fn meshlet_push_cull_data_slice(
  out : Array[Byte],
  values : Array[MeshletCullData],
) -> Unit {
  meshlet_push_slice_len(out, values.length())
  for value in values {
    meshlet_push_cull_data(out, value)
  }
}

///|
fn meshlet_mesh_encode_uncompressed_payload(mesh : MeshletMesh) -> Bytes {
  let out : Array[Byte] = []
  meshlet_push_u32_slice(out, mesh.vertex_positions)
  meshlet_push_u32_slice(out, mesh.vertex_normals)
  meshlet_push_uv_slice(out, mesh.vertex_uvs)
  meshlet_push_u8_slice(out, mesh.indices)
  meshlet_push_bvh_slice(out, mesh.bvh)
  meshlet_push_meshlet_slice(out, mesh.meshlets)
  meshlet_push_cull_data_slice(out, mesh.meshlet_cull_data)
  Bytes::from_array(out)
}

///|
pub fn meshlet_mesh_encode_bevy_bytes(mesh : MeshletMesh) -> Bytes {
  let out : Array[Byte] = []
  meshlet_push_u64_le(out, MESHLET_MESH_ASSET_MAGIC)
  meshlet_push_u64_le(out, MESHLET_MESH_ASSET_VERSION)
  meshlet_push_aabb(out, mesh.aabb)
  meshlet_push_u32_le(out, mesh.bvh_depth.reinterpret_as_uint())
  meshlet_push_bytes(
    out,
    meshlet_lz4_frame_encode_uncompressed_blocks(
      meshlet_mesh_encode_uncompressed_payload(mesh),
    ),
  )
  Bytes::from_array(out)
}

///|
priv struct MeshletByteReader {
  bytes : Bytes
  mut offset : Int
}

///|
fn MeshletByteReader::remaining(self : MeshletByteReader) -> Int {
  self.bytes.length() - self.offset
}

///|
fn MeshletByteReader::read_u8(self : MeshletByteReader) -> Int? {
  if self.remaining() < 1 {
    return None
  }
  let index = self.offset
  self.offset = self.offset + 1
  match self.bytes.get(index) {
    Some(value) => Some(value.to_int() & 0xFF)
    None => None
  }
}

///|
fn MeshletByteReader::read_u16_le(self : MeshletByteReader) -> UInt? {
  guard self.read_u8() is Some(b0) else { return None }
  guard self.read_u8() is Some(b1) else { return None }
  Some(
    (b0 & 0xFF).reinterpret_as_uint() | ((b1 & 0xFF).reinterpret_as_uint() << 8),
  )
}

///|
fn MeshletByteReader::read_u32_le(self : MeshletByteReader) -> UInt? {
  guard self.read_u8() is Some(b0) else { return None }
  guard self.read_u8() is Some(b1) else { return None }
  guard self.read_u8() is Some(b2) else { return None }
  guard self.read_u8() is Some(b3) else { return None }
  Some(
    (b0 & 0xFF).reinterpret_as_uint() |
    ((b1 & 0xFF).reinterpret_as_uint() << 8) |
    ((b2 & 0xFF).reinterpret_as_uint() << 16) |
    ((b3 & 0xFF).reinterpret_as_uint() << 24),
  )
}

///|
fn MeshletByteReader::read_u64_le(self : MeshletByteReader) -> UInt64? {
  guard self.read_u8() is Some(b0) else { return None }
  guard self.read_u8() is Some(b1) else { return None }
  guard self.read_u8() is Some(b2) else { return None }
  guard self.read_u8() is Some(b3) else { return None }
  guard self.read_u8() is Some(b4) else { return None }
  guard self.read_u8() is Some(b5) else { return None }
  guard self.read_u8() is Some(b6) else { return None }
  guard self.read_u8() is Some(b7) else { return None }
  Some(
    (b0 & 0xFF).to_uint64() |
    ((b1 & 0xFF).to_uint64() << 8) |
    ((b2 & 0xFF).to_uint64() << 16) |
    ((b3 & 0xFF).to_uint64() << 24) |
    ((b4 & 0xFF).to_uint64() << 32) |
    ((b5 & 0xFF).to_uint64() << 40) |
    ((b6 & 0xFF).to_uint64() << 48) |
    ((b7 & 0xFF).to_uint64() << 56),
  )
}

///|
fn MeshletByteReader::read_bytes(self : MeshletByteReader, len : Int) -> Bytes? {
  if len < 0 || self.remaining() < len {
    return None
  }
  let start = self.offset
  self.offset = self.offset + len
  Some(
    Bytes::makei(len, index => {
      match self.bytes.get(start + index) {
        Some(value) => value
        None => (0).to_byte()
      }
    }),
  )
}

///|
fn MeshletByteReader::read_f32_le(self : MeshletByteReader) -> Float? {
  match self.read_u32_le() {
    Some(bits) => Some(Float::reinterpret_from_uint(bits))
    None => None
  }
}

///|
fn MeshletByteReader::read_slice_len(self : MeshletByteReader) -> Int? {
  match self.read_u64_le() {
    Some(len) =>
      if len > MESHLET_MESH_U32_MAX_AS_INT {
        None
      } else {
        Some(len.to_int())
      }
    None => None
  }
}

///|
fn MeshletByteReader::read_aabb(self : MeshletByteReader) -> MeshletAabb? {
  guard self.read_f32_le() is Some(center_x) else { return None }
  guard self.read_f32_le() is Some(center_y) else { return None }
  guard self.read_f32_le() is Some(center_z) else { return None }
  guard self.read_f32_le() is Some(half_extent_x) else { return None }
  guard self.read_f32_le() is Some(half_extent_y) else { return None }
  guard self.read_f32_le() is Some(half_extent_z) else { return None }
  Some(
    MeshletAabb::new(
      center_x~,
      center_y~,
      center_z~,
      half_extent_x~,
      half_extent_y~,
      half_extent_z~,
    ),
  )
}

///|
fn MeshletByteReader::read_aabb_error_offset(
  self : MeshletByteReader,
) -> MeshletAabbErrorOffset? {
  guard self.read_f32_le() is Some(center_x) else { return None }
  guard self.read_f32_le() is Some(center_y) else { return None }
  guard self.read_f32_le() is Some(center_z) else { return None }
  guard self.read_f32_le() is Some(error) else { return None }
  guard self.read_f32_le() is Some(half_extent_x) else { return None }
  guard self.read_f32_le() is Some(half_extent_y) else { return None }
  guard self.read_f32_le() is Some(half_extent_z) else { return None }
  guard self.read_u32_le() is Some(child_offset) else { return None }
  Some(MeshletAabbErrorOffset::{
    center_x,
    center_y,
    center_z,
    error,
    half_extent_x,
    half_extent_y,
    half_extent_z,
    child_offset: child_offset.reinterpret_as_int(),
  })
}

///|
fn MeshletByteReader::read_bounding_sphere(
  self : MeshletByteReader,
) -> MeshletBoundingSphere? {
  guard self.read_f32_le() is Some(center_x) else { return None }
  guard self.read_f32_le() is Some(center_y) else { return None }
  guard self.read_f32_le() is Some(center_z) else { return None }
  guard self.read_f32_le() is Some(radius) else { return None }
  Some(MeshletBoundingSphere::{ center_x, center_y, center_z, radius })
}

///|
fn MeshletByteReader::read_bvh_node(self : MeshletByteReader) -> BvhNode? {
  let aabbs : Array[MeshletAabbErrorOffset] = []
  let lod_bounds : Array[MeshletBoundingSphere] = []
  let child_counts : Array[Int] = []
  for _ in 0..<8 {
    guard self.read_aabb_error_offset() is Some(aabb) else { return None }
    aabbs.push(aabb)
  }
  for _ in 0..<8 {
    guard self.read_bounding_sphere() is Some(sphere) else { return None }
    lod_bounds.push(sphere)
  }
  for _ in 0..<8 {
    guard self.read_u8() is Some(child_count) else { return None }
    child_counts.push(child_count)
  }
  guard self.read_u32_le() is Some(padding0) else { return None }
  guard self.read_u32_le() is Some(padding1) else { return None }
  Some(BvhNode::{
    aabbs,
    lod_bounds,
    child_counts,
    padding: [padding0.reinterpret_as_int(), padding1.reinterpret_as_int()],
  })
}

///|
fn MeshletByteReader::read_meshlet(self : MeshletByteReader) -> Meshlet? {
  guard self.read_u32_le() is Some(start_vertex_position_bit) else {
    return None
  }
  guard self.read_u32_le() is Some(start_vertex_attribute_id) else {
    return None
  }
  guard self.read_u32_le() is Some(start_index_id) else { return None }
  guard self.read_u8() is Some(vertex_count_minus_one) else { return None }
  guard self.read_u8() is Some(triangle_count) else { return None }
  guard self.read_u16_le() is Some(padding) else { return None }
  guard self.read_u8() is Some(bits_per_vertex_position_channel_x) else {
    return None
  }
  guard self.read_u8() is Some(bits_per_vertex_position_channel_y) else {
    return None
  }
  guard self.read_u8() is Some(bits_per_vertex_position_channel_z) else {
    return None
  }
  guard self.read_u8() is Some(vertex_position_quantization_factor) else {
    return None
  }
  guard self.read_f32_le() is Some(min_vertex_position_channel_x) else {
    return None
  }
  guard self.read_f32_le() is Some(min_vertex_position_channel_y) else {
    return None
  }
  guard self.read_f32_le() is Some(min_vertex_position_channel_z) else {
    return None
  }
  Some(Meshlet::{
    start_vertex_position_bit: start_vertex_position_bit.reinterpret_as_int(),
    start_vertex_attribute_id: start_vertex_attribute_id.reinterpret_as_int(),
    start_index_id: start_index_id.reinterpret_as_int(),
    vertex_count_minus_one,
    triangle_count,
    padding: padding.reinterpret_as_int(),
    bits_per_vertex_position_channel_x,
    bits_per_vertex_position_channel_y,
    bits_per_vertex_position_channel_z,
    vertex_position_quantization_factor,
    min_vertex_position_channel_x,
    min_vertex_position_channel_y,
    min_vertex_position_channel_z,
  })
}

///|
fn MeshletByteReader::read_cull_data(
  self : MeshletByteReader,
) -> MeshletCullData? {
  guard self.read_aabb_error_offset() is Some(aabb) else { return None }
  guard self.read_bounding_sphere() is Some(lod_group_sphere) else {
    return None
  }
  Some(MeshletCullData::{ aabb, lod_group_sphere })
}

///|
fn MeshletByteReader::read_u32_slice(self : MeshletByteReader) -> Array[Int]? {
  guard self.read_slice_len() is Some(len) else { return None }
  let values : Array[Int] = []
  for _ in 0..<len {
    guard self.read_u32_le() is Some(value) else { return None }
    values.push(value.reinterpret_as_int())
  }
  Some(values)
}

///|
fn MeshletByteReader::read_u8_slice(self : MeshletByteReader) -> Array[Int]? {
  guard self.read_slice_len() is Some(len) else { return None }
  let values : Array[Int] = []
  for _ in 0..<len {
    guard self.read_u8() is Some(value) else { return None }
    values.push(value)
  }
  Some(values)
}

///|
fn MeshletByteReader::read_uv_slice(
  self : MeshletByteReader,
) -> Array[MeshletVertexUv]? {
  guard self.read_slice_len() is Some(len) else { return None }
  let values : Array[MeshletVertexUv] = []
  for _ in 0..<len {
    guard self.read_f32_le() is Some(x) else { return None }
    guard self.read_f32_le() is Some(y) else { return None }
    values.push(MeshletVertexUv::new(x, y))
  }
  Some(values)
}

///|
fn MeshletByteReader::read_bvh_slice(
  self : MeshletByteReader,
) -> Array[BvhNode]? {
  guard self.read_slice_len() is Some(len) else { return None }
  let values : Array[BvhNode] = []
  for _ in 0..<len {
    guard self.read_bvh_node() is Some(value) else { return None }
    values.push(value)
  }
  Some(values)
}

///|
fn MeshletByteReader::read_meshlet_slice(
  self : MeshletByteReader,
) -> Array[Meshlet]? {
  guard self.read_slice_len() is Some(len) else { return None }
  let values : Array[Meshlet] = []
  for _ in 0..<len {
    guard self.read_meshlet() is Some(value) else { return None }
    values.push(value)
  }
  Some(values)
}

///|
fn MeshletByteReader::read_cull_data_slice(
  self : MeshletByteReader,
) -> Array[MeshletCullData]? {
  guard self.read_slice_len() is Some(len) else { return None }
  let values : Array[MeshletCullData] = []
  for _ in 0..<len {
    guard self.read_cull_data() is Some(value) else { return None }
    values.push(value)
  }
  Some(values)
}

///|
fn meshlet_xxh32_rotl(value : UInt, count : Int) -> UInt {
  (value << count) | (value >> (32 - count))
}

///|
fn meshlet_xxh32_round(acc : UInt, input : UInt) -> UInt {
  meshlet_xxh32_rotl(acc + input * MESHLET_XXH32_PRIME2, 13) *
  MESHLET_XXH32_PRIME1
}

///|
fn meshlet_xxh32_u32_at(bytes : Bytes, index : Int) -> UInt {
  guard bytes.get(index) is Some(b0) else { return 0U }
  guard bytes.get(index + 1) is Some(b1) else { return 0U }
  guard bytes.get(index + 2) is Some(b2) else { return 0U }
  guard bytes.get(index + 3) is Some(b3) else { return 0U }
  b0.to_uint() |
  (b1.to_uint() << 8) |
  (b2.to_uint() << 16) |
  (b3.to_uint() << 24)
}

///|
fn meshlet_xxh32(bytes : Bytes) -> UInt {
  let len = bytes.length()
  let mut index = 0
  let mut hash = 0U
  if len >= 16 {
    let mut v1 = MESHLET_XXH32_PRIME1 + MESHLET_XXH32_PRIME2
    let mut v2 = MESHLET_XXH32_PRIME2
    let mut v3 = 0U
    let mut v4 = 0U - MESHLET_XXH32_PRIME1
    while index <= len - 16 {
      v1 = meshlet_xxh32_round(v1, meshlet_xxh32_u32_at(bytes, index))
      v2 = meshlet_xxh32_round(v2, meshlet_xxh32_u32_at(bytes, index + 4))
      v3 = meshlet_xxh32_round(v3, meshlet_xxh32_u32_at(bytes, index + 8))
      v4 = meshlet_xxh32_round(v4, meshlet_xxh32_u32_at(bytes, index + 12))
      index = index + 16
    }
    hash = meshlet_xxh32_rotl(v1, 1) +
      meshlet_xxh32_rotl(v2, 7) +
      meshlet_xxh32_rotl(v3, 12) +
      meshlet_xxh32_rotl(v4, 18)
  } else {
    hash = MESHLET_XXH32_PRIME5
  }
  hash = hash + len.reinterpret_as_uint()
  while index <= len - 4 {
    hash = meshlet_xxh32_rotl(
        hash + meshlet_xxh32_u32_at(bytes, index) * MESHLET_XXH32_PRIME3,
        17,
      ) *
      MESHLET_XXH32_PRIME4
    index = index + 4
  }
  while index < len {
    guard bytes.get(index) is Some(byte) else { return hash }
    hash = meshlet_xxh32_rotl(hash + byte.to_uint() * MESHLET_XXH32_PRIME5, 11) *
      MESHLET_XXH32_PRIME1
    index = index + 1
  }
  hash = hash ^ (hash >> 15)
  hash = hash * MESHLET_XXH32_PRIME2
  hash = hash ^ (hash >> 13)
  hash = hash * MESHLET_XXH32_PRIME3
  hash ^ (hash >> 16)
}

///|
fn meshlet_lz4_frame_header_checksum(flg : Int, bd : Int) -> Byte {
  let header = Bytes::from_array([(flg & 0xFF).to_byte(), (bd & 0xFF).to_byte()])
  (meshlet_xxh32(header) >> 8).to_byte()
}

///|
fn meshlet_lz4_frame_encode_uncompressed_blocks(payload : Bytes) -> Bytes {
  let out : Array[Byte] = []
  meshlet_push_u32_le(out, MESHLET_LZ4_FRAME_MAGIC)
  meshlet_push_u8(out, 0x60)
  meshlet_push_u8(out, 0x40)
  out.push(meshlet_lz4_frame_header_checksum(0x60, 0x40))
  let mut offset = 0
  while offset < payload.length() {
    let remaining = payload.length() - offset
    let len = if remaining > MESHLET_LZ4_DEFAULT_BLOCK_SIZE {
      MESHLET_LZ4_DEFAULT_BLOCK_SIZE
    } else {
      remaining
    }
    meshlet_push_u32_le(
      out,
      len.reinterpret_as_uint() | MESHLET_LZ4_BLOCK_UNCOMPRESSED_MASK,
    )
    for index in 0..<len {
      match payload.get(offset + index) {
        Some(value) => out.push(value)
        None => ()
      }
    }
    offset = offset + len
  }
  meshlet_push_u32_le(out, 0U)
  Bytes::from_array(out)
}

///|
fn meshlet_lz4_decode_len_extension(
  reader : MeshletByteReader,
  base : Int,
) -> Int? {
  let mut len = base
  if base == 15 {
    let mut next = 255
    while next == 255 {
      guard reader.read_u8() is Some(extra) else { return None }
      len = len + extra
      next = extra
    }
  }
  Some(len)
}

///|
fn meshlet_lz4_block_decompress(block : Bytes) -> MeshletLz4FrameResult {
  let reader = MeshletByteReader::{ bytes: block, offset: 0 }
  let out : Array[Byte] = []
  while reader.remaining() > 0 {
    guard reader.read_u8() is Some(token) else {
      return MeshletLz4FrameErr("truncated LZ4 token")
    }
    guard meshlet_lz4_decode_len_extension(reader, token >> 4)
      is Some(literal_len) else {
      return MeshletLz4FrameErr("truncated LZ4 literal length")
    }
    guard reader.read_bytes(literal_len) is Some(literals) else {
      return MeshletLz4FrameErr("truncated LZ4 literals")
    }
    meshlet_push_bytes(out, literals)
    if reader.remaining() == 0 {
      return MeshletLz4FrameOk(Bytes::from_array(out))
    }
    guard reader.read_u16_le() is Some(offset_word) else {
      return MeshletLz4FrameErr("truncated LZ4 match offset")
    }
    let offset = offset_word.reinterpret_as_int()
    if offset <= 0 || offset > out.length() {
      return MeshletLz4FrameErr("invalid LZ4 match offset")
    }
    guard meshlet_lz4_decode_len_extension(reader, token & 0x0F)
      is Some(match_len_base) else {
      return MeshletLz4FrameErr("truncated LZ4 match length")
    }
    let match_len = match_len_base + 4
    for _ in 0..<match_len {
      let source_index = out.length() - offset
      if source_index < 0 || source_index >= out.length() {
        return MeshletLz4FrameErr("invalid LZ4 match copy")
      }
      out.push(out[source_index])
    }
  }
  MeshletLz4FrameOk(Bytes::from_array(out))
}

///|
fn meshlet_lz4_frame_decode(frame : Bytes) -> MeshletLz4FrameResult {
  let reader = MeshletByteReader::{ bytes: frame, offset: 0 }
  guard reader.read_u32_le() is Some(magic) else {
    return MeshletLz4FrameErr("truncated LZ4 frame magic")
  }
  if magic != MESHLET_LZ4_FRAME_MAGIC {
    return MeshletLz4FrameErr("wrong LZ4 frame magic")
  }
  guard reader.read_u8() is Some(flg) else {
    return MeshletLz4FrameErr("truncated LZ4 FLG")
  }
  guard reader.read_u8() is Some(bd) else {
    return MeshletLz4FrameErr("truncated LZ4 BD")
  }
  if (flg & 0xC0) != 0x40 {
    return MeshletLz4FrameErr("unsupported LZ4 frame version")
  }
  if (flg & 0x02) != 0 || (bd & 0x8F) != 0 {
    return MeshletLz4FrameErr("reserved LZ4 frame bits are set")
  }
  if (flg & 0x20) == 0 {
    return MeshletLz4FrameErr("linked LZ4 blocks are not supported")
  }
  let block_size_code = (bd & 0x70) >> 4
  if block_size_code < 4 || block_size_code > 7 {
    return MeshletLz4FrameErr("unsupported LZ4 block size")
  }
  let block_checksums = (flg & 0x10) != 0
  let content_size_present = (flg & 0x08) != 0
  let content_checksum = (flg & 0x04) != 0
  let dictionary_id_present = (flg & 0x01) != 0
  if content_size_present {
    guard reader.read_u64_le() is Some(_) else {
      return MeshletLz4FrameErr("truncated LZ4 content size")
    }
  }
  if dictionary_id_present {
    guard reader.read_u32_le() is Some(_) else {
      return MeshletLz4FrameErr("truncated LZ4 dictionary id")
    }
    return MeshletLz4FrameErr("LZ4 dictionaries are not supported")
  }
  guard reader.read_u8() is Some(_) else {
    return MeshletLz4FrameErr("truncated LZ4 header checksum")
  }
  let out : Array[Byte] = []
  while true {
    guard reader.read_u32_le() is Some(block_info) else {
      return MeshletLz4FrameErr("truncated LZ4 block header")
    }
    if block_info == 0U {
      break
    }
    let is_uncompressed = (block_info & MESHLET_LZ4_BLOCK_UNCOMPRESSED_MASK) !=
      0U
    let block_len = (block_info & 0x7FFFFFFFU).reinterpret_as_int()
    guard reader.read_bytes(block_len) is Some(block) else {
      return MeshletLz4FrameErr("truncated LZ4 block data")
    }
    if is_uncompressed {
      meshlet_push_bytes(out, block)
    } else {
      match meshlet_lz4_block_decompress(block) {
        MeshletLz4FrameOk(decoded) => meshlet_push_bytes(out, decoded)
        MeshletLz4FrameErr(reason) => return MeshletLz4FrameErr(reason)
      }
    }
    if block_checksums {
      guard reader.read_u32_le() is Some(_) else {
        return MeshletLz4FrameErr("truncated LZ4 block checksum")
      }
    }
  }
  if content_checksum {
    guard reader.read_u32_le() is Some(_) else {
      return MeshletLz4FrameErr("truncated LZ4 content checksum")
    }
  }
  if reader.remaining() != 0 {
    return MeshletLz4FrameErr("trailing bytes after LZ4 frame")
  }
  MeshletLz4FrameOk(Bytes::from_array(out))
}

///|
fn meshlet_mesh_decode_uncompressed_payload(
  payload : Bytes,
  aabb : MeshletAabb,
  bvh_depth : Int,
) -> MeshletMeshLoadResult {
  let reader = MeshletByteReader::{ bytes: payload, offset: 0 }
  guard reader.read_u32_slice() is Some(vertex_positions) else {
    return MeshletMeshLoadErr(IoError("truncated vertex_positions slice"))
  }
  guard reader.read_u32_slice() is Some(vertex_normals) else {
    return MeshletMeshLoadErr(IoError("truncated vertex_normals slice"))
  }
  guard reader.read_uv_slice() is Some(vertex_uvs) else {
    return MeshletMeshLoadErr(IoError("truncated vertex_uvs slice"))
  }
  guard reader.read_u8_slice() is Some(indices) else {
    return MeshletMeshLoadErr(IoError("truncated indices slice"))
  }
  guard reader.read_bvh_slice() is Some(bvh) else {
    return MeshletMeshLoadErr(IoError("truncated bvh slice"))
  }
  guard reader.read_meshlet_slice() is Some(meshlets) else {
    return MeshletMeshLoadErr(IoError("truncated meshlets slice"))
  }
  guard reader.read_cull_data_slice() is Some(meshlet_cull_data) else {
    return MeshletMeshLoadErr(IoError("truncated meshlet_cull_data slice"))
  }
  if reader.remaining() != 0 {
    return MeshletMeshLoadErr(IoError("trailing bytes after meshlet payload"))
  }
  MeshletMeshLoadOk(
    MeshletMesh::from_parts(
      vertex_positions~,
      vertex_normals~,
      vertex_uvs~,
      indices~,
      bvh~,
      meshlets~,
      meshlet_cull_data~,
      aabb~,
      bvh_depth~,
    ),
  )
}

///|
pub fn meshlet_mesh_decode_bevy_bytes(bytes : Bytes) -> MeshletMeshLoadResult {
  let reader = MeshletByteReader::{ bytes, offset: 0 }
  guard reader.read_u64_le() is Some(magic) else {
    return MeshletMeshLoadErr(IoError("truncated meshlet header"))
  }
  if magic != MESHLET_MESH_ASSET_MAGIC {
    return MeshletMeshLoadErr(WrongFileType)
  }
  guard reader.read_u64_le() is Some(version) else {
    return MeshletMeshLoadErr(IoError("truncated meshlet version"))
  }
  if version != MESHLET_MESH_ASSET_VERSION {
    return MeshletMeshLoadErr(WrongVersion(version))
  }
  let aabb = reader.read_aabb()
  guard aabb is Some(aabb) else {
    return MeshletMeshLoadErr(IoError("truncated meshlet aabb"))
  }
  guard reader.read_u32_le() is Some(bvh_depth) else {
    return MeshletMeshLoadErr(IoError("truncated meshlet bvh depth"))
  }
  guard reader.read_bytes(reader.remaining()) is Some(frame) else {
    return MeshletMeshLoadErr(IoError("truncated meshlet payload"))
  }
  match meshlet_lz4_frame_decode(frame) {
    MeshletLz4FrameOk(payload) =>
      meshlet_mesh_decode_uncompressed_payload(
        payload,
        aabb,
        bvh_depth.reinterpret_as_int(),
      )
    MeshletLz4FrameErr(reason) =>
      MeshletMeshLoadErr(CompressionOrDecompression(reason))
  }
}
