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
// Bevy source: `bevy/crates/bevy_pbr/src/meshlet/from_mesh.rs`.

///|
pub(all) enum MeshToMeshletMeshConversionError {
  RuntimeUnavailable
  WrongMeshPrimitiveTopology
  WrongMeshVertexAttributes(Array[String])
  MeshMissingIndices
  MissingPositions
  UnsupportedTopology
  TooManyVertices
}

///|
pub const MESHLET_DEFAULT_VERTEX_POSITION_QUANTIZATION_FACTOR : Int = 4

///|
const MESHLET_BVH_INNER_CHILD_COUNT : Int = 255

///|
const MESHLET_TARGET_MESHLETS_PER_GROUP : Int = 8

///|
const MESHLET_SIMPLIFICATION_FAILURE_PERCENTAGE : Float = 0.60F

///|
pub struct MeshToMeshletMeshConversionConfig {
  max_vertices : Int
  max_triangles : Int
}

///|
pub struct MeshToMeshletInputMeshSummary {
  primitive_topology : String
  vertex_attributes : Array[String]
  has_indices : Bool
  vertex_count : Int
  triangle_count : Int
}

///|
pub fn MeshToMeshletInputMeshSummary::new(
  primitive_topology~ : String,
  vertex_attributes~ : Array[String],
  has_indices~ : Bool,
  vertex_count~ : Int,
  triangle_count~ : Int,
) -> MeshToMeshletInputMeshSummary {
  MeshToMeshletInputMeshSummary::{
    primitive_topology,
    vertex_attributes,
    has_indices,
    vertex_count,
    triangle_count,
  }
}

///|
pub fn MeshToMeshletMeshConversionConfig::default() -> MeshToMeshletMeshConversionConfig {
  MeshToMeshletMeshConversionConfig::{
    max_vertices: 65_535,
    max_triangles: 65_535,
  }
}

///|
pub fn meshlet_validate_conversion_config(
  config : MeshToMeshletMeshConversionConfig,
) -> MeshToMeshletMeshConversionConfig {
  MeshToMeshletMeshConversionConfig::{
    max_vertices: if config.max_vertices <= 0 {
      1
    } else {
      config.max_vertices
    },
    max_triangles: if config.max_triangles <= 0 {
      1
    } else {
      config.max_triangles
    },
  }
}

///|
pub fn meshlet_required_vertex_attributes() -> Array[String] {
  ["POSITION", "NORMAL", "UV_0"]
}

///|
fn meshlet_vertex_attributes_match(attributes : Array[String]) -> Bool {
  let required = meshlet_required_vertex_attributes()
  if attributes.length() != required.length() {
    return false
  }
  for index in 0..<required.length() {
    if attributes[index] != required[index] {
      return false
    }
  }
  true
}

///|
pub fn meshlet_validate_input_mesh_summary(
  summary : MeshToMeshletInputMeshSummary,
  config : MeshToMeshletMeshConversionConfig,
  runtime_available : Bool,
) -> MeshToMeshletMeshConversionError? {
  let safe = meshlet_validate_conversion_config(config)
  if !runtime_available {
    return Some(MeshToMeshletMeshConversionError::RuntimeUnavailable)
  }
  if summary.primitive_topology != "TriangleList" {
    return Some(MeshToMeshletMeshConversionError::WrongMeshPrimitiveTopology)
  }
  if !meshlet_vertex_attributes_match(summary.vertex_attributes) {
    return Some(
      MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
        summary.vertex_attributes,
      ),
    )
  }
  if !summary.has_indices {
    return Some(MeshToMeshletMeshConversionError::MeshMissingIndices)
  }
  if summary.vertex_count > safe.max_vertices ||
    summary.triangle_count > safe.max_triangles {
    return Some(MeshToMeshletMeshConversionError::TooManyVertices)
  }
  None
}

///|
pub fn meshlet_can_convert_from_mesh(
  vertex_count : Int,
  triangle_count : Int,
) -> Bool {
  meshlet_runtime_available() && vertex_count > 0 && triangle_count > 0
}

///|
pub fn meshlet_conversion_error_when_unavailable() -> MeshToMeshletMeshConversionError {
  MeshToMeshletMeshConversionError::RuntimeUnavailable
}

///|
pub struct MeshletSourceVertex {
  position : @math.Vec3
  normal : @math.Vec3
  uv : @math.Vec2
}

///|
pub fn MeshletSourceVertex::new(
  position~ : @math.Vec3,
  normal~ : @math.Vec3,
  uv~ : @math.Vec2,
) -> MeshletSourceVertex {
  MeshletSourceVertex::{ position, normal, uv }
}

///|
pub struct MeshletCompressedVertexData {
  vertex_positions : Array[Int]
  vertex_position_bit_len : Int
  vertex_normals : Array[Int]
  vertex_uvs : Array[MeshletVertexUv]
  meshlet : Meshlet
}

///|
pub fn MeshletCompressedVertexData::new(
  vertex_positions~ : Array[Int],
  vertex_position_bit_len~ : Int,
  vertex_normals~ : Array[Int],
  vertex_uvs~ : Array[MeshletVertexUv],
  meshlet~ : Meshlet,
) -> MeshletCompressedVertexData {
  MeshletCompressedVertexData::{
    vertex_positions,
    vertex_position_bit_len,
    vertex_normals,
    vertex_uvs,
    meshlet,
  }
}

///|
pub struct MeshletMeshInputData {
  vertices : Array[MeshletSourceVertex]
  indices : Array[Int]
  triangle_count : Int
}

///|
pub fn MeshletMeshInputData::new(
  vertices~ : Array[MeshletSourceVertex],
  indices~ : Array[Int],
) -> MeshletMeshInputData {
  MeshletMeshInputData::{
    vertices,
    indices,
    triangle_count: indices.length() / 3,
  }
}

///|
pub fn MeshletMeshInputData::summary(
  self : MeshletMeshInputData,
) -> MeshToMeshletInputMeshSummary {
  MeshToMeshletInputMeshSummary::new(
    primitive_topology="TriangleList",
    vertex_attributes=meshlet_required_vertex_attributes(),
    has_indices=true,
    vertex_count=self.vertices.length(),
    triangle_count=self.triangle_count,
  )
}

///|
fn meshlet_attribute_debug_name(
  attribute : @mesh.MeshVertexAttribute,
) -> String {
  let id = attribute.id().value()
  if id == @mesh.MeshVertexAttribute::position().id().value() {
    "POSITION"
  } else if id == @mesh.MeshVertexAttribute::normal().id().value() {
    "NORMAL"
  } else if id == @mesh.MeshVertexAttribute::uv_0().id().value() {
    "UV_0"
  } else if id == @mesh.MeshVertexAttribute::tangent().id().value() {
    "TANGENT"
  } else if id == @mesh.MeshVertexAttribute::color().id().value() {
    "COLOR"
  } else if id == @mesh.MeshVertexAttribute::joint_weight().id().value() {
    "JOINT_WEIGHT"
  } else if id == @mesh.MeshVertexAttribute::joint_index().id().value() {
    "JOINT_INDEX"
  } else {
    attribute.name()
  }
}

///|
fn meshlet_mesh_vertex_attribute_names(
  attributes : Array[@mesh.MeshAttributeData],
) -> Array[String] {
  let names : Array[String] = []
  for attribute in attributes {
    names.push(meshlet_attribute_debug_name(attribute.attribute()))
  }
  names
}

///|
fn meshlet_mesh_has_exact_required_attributes(
  attributes : Array[@mesh.MeshAttributeData],
) -> Bool {
  if attributes.length() != 3 {
    return false
  }
  attributes[0].attribute().id().value() ==
  @mesh.MeshVertexAttribute::position().id().value() &&
  attributes[1].attribute().id().value() ==
  @mesh.MeshVertexAttribute::normal().id().value() &&
  attributes[2].attribute().id().value() ==
  @mesh.MeshVertexAttribute::uv_0().id().value() &&
  attributes[0].values().len() == attributes[1].values().len() &&
  attributes[0].values().len() == attributes[2].values().len()
}

///|
pub fn meshlet_extract_mesh_input(
  mesh : @mesh.Mesh,
) -> Result[MeshletMeshInputData, MeshToMeshletMeshConversionError] {
  guard mesh.primitive_topology()
    is Some(@mesh.Mesh3dPrimitiveTopology::TriangleList) else {
    return Err(MeshToMeshletMeshConversionError::WrongMeshPrimitiveTopology)
  }
  let attributes = mesh.attributes()
  if !meshlet_mesh_has_exact_required_attributes(attributes) {
    return Err(
      MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
        meshlet_mesh_vertex_attribute_names(attributes),
      ),
    )
  }
  guard mesh.indices() is Some(indices) else {
    return Err(MeshToMeshletMeshConversionError::MeshMissingIndices)
  }
  guard attributes[0].values()
    is @mesh.VertexAttributeValues::Float32x3(positions) else {
    return Err(
      MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
        meshlet_mesh_vertex_attribute_names(attributes),
      ),
    )
  }
  guard attributes[1].values()
    is @mesh.VertexAttributeValues::Float32x3(normals) else {
    return Err(
      MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
        meshlet_mesh_vertex_attribute_names(attributes),
      ),
    )
  }
  guard attributes[2].values() is @mesh.VertexAttributeValues::Float32x2(uvs) else {
    return Err(
      MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
        meshlet_mesh_vertex_attribute_names(attributes),
      ),
    )
  }
  let vertices : Array[MeshletSourceVertex] = []
  for index in 0..<positions.length() {
    vertices.push(
      MeshletSourceVertex::new(
        position=positions[index],
        normal=normals[index],
        uv=uvs[index],
      ),
    )
  }
  Ok(MeshletMeshInputData::new(vertices~, indices~))
}

///|
fn meshlet_sign(value : Float) -> Float {
  if value >= 0.0F {
    1.0F
  } else {
    -1.0F
  }
}

///|
fn meshlet_octahedral_encode(normal : @math.Vec3) -> @math.Vec2 {
  let denominator = normal.x.abs() + normal.y.abs() + normal.z.abs()
  if denominator <= 0.0F {
    return @math.Vec2::zero()
  }
  let nx = normal.x / denominator
  let ny = normal.y / denominator
  let nz = normal.z / denominator
  if nz >= 0.0F {
    @math.Vec2::new(nx, ny)
  } else {
    @math.Vec2::new(
      (1.0F - ny.abs()) * meshlet_sign(nx),
      (1.0F - nx.abs()) * meshlet_sign(ny),
    )
  }
}

///|
fn meshlet_clamp_float(value : Float, min : Float, max : Float) -> Float {
  if value < min {
    min
  } else if value > max {
    max
  } else {
    value
  }
}

///|
fn meshlet_pack_snorm_16(value : Float) -> Int {
  let clamped = meshlet_clamp_float(value, -1.0F, 1.0F)
  let packed = (clamped * 32767.0F + 0.5F).floor().to_int()
  packed & 0xFFFF
}

///|
fn meshlet_pack2x16snorm(value : @math.Vec2) -> Int {
  let x = meshlet_pack_snorm_16(value.x).reinterpret_as_uint()
  let y = meshlet_pack_snorm_16(value.y).reinterpret_as_uint()
  (x | (y << 16)).reinterpret_as_int()
}

///|
fn meshlet_quantization_scale(factor : Int) -> Float {
  let mut scale = 1.0F
  let count = if factor < 0 { 0 } else { factor }
  for _ in 0..<count {
    scale = scale * 2.0F
  }
  scale * 100.0F
}

///|
fn meshlet_quantize_position_channel(value : Float, scale : Float) -> Int {
  (value * scale + 0.5F).to_int()
}

///|
fn meshlet_bits_needed(range : Int) -> Int {
  if range <= 1 {
    return 0
  }
  let mut bits = 0
  let mut capacity = 1
  while capacity < range {
    capacity = capacity << 1
    bits = bits + 1
  }
  bits
}

///|
fn meshlet_ensure_position_word(words : Array[Int], word_index : Int) -> Unit {
  while words.length() <= word_index {
    words.push(0)
  }
}

///|
fn meshlet_append_lsb_bits(
  words : Array[Int],
  start_bit : Int,
  value : Int,
  bit_count : Int,
) -> Int {
  let source = value.reinterpret_as_uint()
  let mut cursor = start_bit
  for bit in 0..<bit_count {
    let word_index = cursor / 32
    let bit_index = cursor % 32
    meshlet_ensure_position_word(words, word_index)
    if ((source >> bit) & 1U) != 0U {
      let current = words[word_index].reinterpret_as_uint()
      words[word_index] = (current | (1U << bit_index)).reinterpret_as_int()
    }
    cursor = cursor + 1
  }
  cursor
}

///|
pub fn meshlet_build_compressed_vertex_data(
  meshlet_vertices : Array[MeshletSourceVertex],
  start_index_id~ : Int,
  triangle_count~ : Int,
  vertex_position_quantization_factor? : Int = MESHLET_DEFAULT_VERTEX_POSITION_QUANTIZATION_FACTOR,
) -> MeshletCompressedVertexData {
  if meshlet_vertices.is_empty() || meshlet_vertices.length() > 256 {
    abort("meshlet vertex compression requires 1..256 source vertices")
  }
  if triangle_count < 0 || triangle_count > 255 {
    abort("meshlet vertex compression requires a u8 triangle count")
  }
  let vertex_positions : Array[Int] = []
  let vertex_normals : Array[Int] = []
  let vertex_uvs : Array[MeshletVertexUv] = []
  let quantized_x : Array[Int] = []
  let quantized_y : Array[Int] = []
  let quantized_z : Array[Int] = []
  let scale = meshlet_quantization_scale(vertex_position_quantization_factor)
  let mut min_x = 0
  let mut min_y = 0
  let mut min_z = 0
  let mut max_x = 0
  let mut max_y = 0
  let mut max_z = 0
  for index in 0..<meshlet_vertices.length() {
    let vertex = meshlet_vertices[index]
    vertex_uvs.push(MeshletVertexUv::new(vertex.uv.x, vertex.uv.y))
    vertex_normals.push(
      meshlet_pack2x16snorm(meshlet_octahedral_encode(vertex.normal)),
    )
    let qx = meshlet_quantize_position_channel(vertex.position.x, scale)
    let qy = meshlet_quantize_position_channel(vertex.position.y, scale)
    let qz = meshlet_quantize_position_channel(vertex.position.z, scale)
    quantized_x.push(qx)
    quantized_y.push(qy)
    quantized_z.push(qz)
    if index == 0 {
      min_x = qx
      max_x = qx
      min_y = qy
      max_y = qy
      min_z = qz
      max_z = qz
    } else {
      min_x = min_x.min(qx)
      max_x = max_x.max(qx)
      min_y = min_y.min(qy)
      max_y = max_y.max(qy)
      min_z = min_z.min(qz)
      max_z = max_z.max(qz)
    }
  }
  let bits_x = meshlet_bits_needed(max_x - min_x + 1)
  let bits_y = meshlet_bits_needed(max_y - min_y + 1)
  let bits_z = meshlet_bits_needed(max_z - min_z + 1)
  let mut bit_cursor = 0
  for index in 0..<meshlet_vertices.length() {
    bit_cursor = meshlet_append_lsb_bits(
      vertex_positions,
      bit_cursor,
      quantized_x[index] - min_x,
      bits_x,
    )
    bit_cursor = meshlet_append_lsb_bits(
      vertex_positions,
      bit_cursor,
      quantized_y[index] - min_y,
      bits_y,
    )
    bit_cursor = meshlet_append_lsb_bits(
      vertex_positions,
      bit_cursor,
      quantized_z[index] - min_z,
      bits_z,
    )
  }
  let meshlet = Meshlet::new(
      0,
      0,
      start_index_id,
      meshlet_vertices.length(),
      triangle_count,
    )
    .with_quantization(
      bits_x, bits_y, bits_z, vertex_position_quantization_factor,
    )
    .with_min_vertex_position_channels(
      Float::from_int(min_x),
      Float::from_int(min_y),
      Float::from_int(min_z),
    )
  MeshletCompressedVertexData::new(
    vertex_positions~,
    vertex_position_bit_len=bit_cursor,
    vertex_normals~,
    vertex_uvs~,
    meshlet~,
  )
}

///|
pub fn meshlet_conversion_error_for_counts(
  vertex_count : Int,
  triangle_count : Int,
  config : MeshToMeshletMeshConversionConfig,
) -> MeshToMeshletMeshConversionError? {
  if vertex_count <= 0 {
    return Some(MeshToMeshletMeshConversionError::MissingPositions)
  }
  if triangle_count <= 0 {
    return Some(MeshToMeshletMeshConversionError::UnsupportedTopology)
  }
  let summary = MeshToMeshletInputMeshSummary::new(
    primitive_topology="TriangleList",
    vertex_attributes=meshlet_required_vertex_attributes(),
    has_indices=true,
    vertex_count~,
    triangle_count~,
  )
  meshlet_validate_input_mesh_summary(
    summary,
    config,
    meshlet_runtime_available(),
  )
}

///|
priv struct MeshletBuildMeshlet {
  vertex_offset : Int
  triangle_offset : Int
  vertex_count : Int
  triangle_count : Int
}

///|
fn MeshletBuildMeshlet::new(
  vertex_offset~ : Int,
  triangle_offset~ : Int,
  vertex_count~ : Int,
  triangle_count~ : Int,
) -> MeshletBuildMeshlet {
  MeshletBuildMeshlet::{
    vertex_offset,
    triangle_offset,
    vertex_count,
    triangle_count,
  }
}

///|
priv struct MeshletBuildMeshlets {
  meshlets : Array[MeshletBuildMeshlet]
  vertices : Array[Int]
  triangles : Array[Int]
}

///|
fn MeshletBuildMeshlets::new(
  meshlets~ : Array[MeshletBuildMeshlet],
  vertices~ : Array[Int],
  triangles~ : Array[Int],
) -> MeshletBuildMeshlets {
  MeshletBuildMeshlets::{ meshlets, vertices, triangles }
}

///|
fn MeshletBuildMeshlets::len(self : MeshletBuildMeshlets) -> Int {
  self.meshlets.length()
}

///|
fn MeshletBuildMeshlets::meshlet_vertex(
  self : MeshletBuildMeshlets,
  meshlet : MeshletBuildMeshlet,
  local_vertex_index : Int,
) -> Int {
  self.vertices[meshlet.vertex_offset + local_vertex_index]
}

///|
fn MeshletBuildMeshlets::meshlet_triangle_index(
  self : MeshletBuildMeshlets,
  meshlet : MeshletBuildMeshlet,
  triangle_index : Int,
) -> Int {
  self.triangles[meshlet.triangle_offset + triangle_index]
}

///|
priv struct MeshletConnectedMeshlet {
  meshlet_id : Int
  shared_vertex_count : Int
}

///|
fn MeshletConnectedMeshlet::new(
  meshlet_id~ : Int,
  shared_vertex_count~ : Int,
) -> MeshletConnectedMeshlet {
  MeshletConnectedMeshlet::{ meshlet_id, shared_vertex_count }
}

///|
priv struct MeshletPairConnection {
  left : Int
  right : Int
  shared_vertex_count : Int
}

///|
fn meshlet_connected_meshlet_cmp(
  left : MeshletConnectedMeshlet,
  right : MeshletConnectedMeshlet,
) -> Int {
  if left.meshlet_id < right.meshlet_id {
    -1
  } else if left.meshlet_id > right.meshlet_id {
    1
  } else if left.shared_vertex_count < right.shared_vertex_count {
    -1
  } else if left.shared_vertex_count > right.shared_vertex_count {
    1
  } else {
    0
  }
}

///|
fn meshlet_increment_pair_connection(
  pairs : Array[MeshletPairConnection],
  left : Int,
  right : Int,
) -> Unit {
  let pair_left = left.min(right)
  let pair_right = left.max(right)
  for index in 0..<pairs.length() {
    let pair = pairs[index]
    if pair.left == pair_left && pair.right == pair_right {
      pairs[index] = MeshletPairConnection::{
        ..pair,
        shared_vertex_count: pair.shared_vertex_count + 1,
      }
      return
    }
  }
  pairs.push(MeshletPairConnection::{
    left: pair_left,
    right: pair_right,
    shared_vertex_count: 1,
  })
}

///|
fn meshlet_position_equal(left : @math.Vec3, right : @math.Vec3) -> Bool {
  left.x == right.x && left.y == right.y && left.z == right.z
}

///|
fn meshlet_generate_position_remap(
  vertices : Array[MeshletSourceVertex],
) -> Array[Int] {
  let remap : Array[Int] = []
  for index in 0..<vertices.length() {
    let mut remapped = index
    for previous in 0..<index {
      if meshlet_position_equal(
          vertices[previous].position,
          vertices[index].position,
        ) {
        remapped = remap[previous]
        break
      }
    }
    remap.push(remapped)
  }
  remap
}

///|
priv struct MeshletMetisPartitionGraph {
  xadj : Array[Int]
  adjncy : Array[Int]
  adjwgt : Array[Int]
  partition_count : Int
  seed : Int
  imbalance_factor : Int
}

///|
fn meshlet_build_triangle_partition_graph(
  indices : Array[Int],
  position_only_vertex_remap : Array[Int],
) -> MeshletMetisPartitionGraph {
  let vertices_to_triangles : Array[Array[Int]] = []
  for _ in 0..<position_only_vertex_remap.length() {
    vertices_to_triangles.push([])
  }
  for index in 0..<indices.length() {
    let vertex_id = position_only_vertex_remap[indices[index]]
    vertices_to_triangles[vertex_id].push(index / 3)
  }

  let pairs : Array[MeshletPairConnection] = []
  for vertex_triangles in vertices_to_triangles {
    for left_index in 0..<vertex_triangles.length() {
      for right_index in (left_index + 1)..<vertex_triangles.length() {
        meshlet_increment_pair_connection(
          pairs,
          vertex_triangles[left_index],
          vertex_triangles[right_index],
        )
      }
    }
  }

  let triangle_count = indices.length() / 3
  let connected_triangles_per_triangle : Array[Array[MeshletConnectedMeshlet]] = []
  for _ in 0..<triangle_count {
    connected_triangles_per_triangle.push([])
  }
  for pair in pairs {
    connected_triangles_per_triangle[pair.left].push(
      MeshletConnectedMeshlet::new(
        meshlet_id=pair.right,
        shared_vertex_count=pair.shared_vertex_count,
      ),
    )
    connected_triangles_per_triangle[pair.right].push(
      MeshletConnectedMeshlet::new(
        meshlet_id=pair.left,
        shared_vertex_count=pair.shared_vertex_count,
      ),
    )
  }
  for connected_triangles in connected_triangles_per_triangle {
    connected_triangles.sort_by(meshlet_connected_meshlet_cmp)
  }

  let xadj : Array[Int] = []
  let adjncy : Array[Int] = []
  let adjwgt : Array[Int] = []
  for connected_triangles in connected_triangles_per_triangle {
    xadj.push(adjncy.length())
    for connected_triangle in connected_triangles {
      adjncy.push(connected_triangle.meshlet_id)
      adjwgt.push(connected_triangle.shared_vertex_count)
    }
  }
  xadj.push(adjncy.length())
  MeshletMetisPartitionGraph::{
    xadj,
    adjncy,
    adjwgt,
    partition_count: (triangle_count + 125) / 126,
    seed: 17,
    imbalance_factor: 1,
  }
}

///|
fn meshlet_collect_indices_per_partition(
  indices : Array[Int],
  partition_per_triangle : Array[Int],
  partition_count : Int,
) -> Array[Array[Int]] {
  let indices_per_partition : Array[Array[Int]] = []
  for _ in 0..<partition_count {
    indices_per_partition.push([])
  }
  for triangle_id in 0..<partition_per_triangle.length() {
    let partition = partition_per_triangle[triangle_id]
    let base_index = triangle_id * 3
    indices_per_partition[partition].push(indices[base_index])
    indices_per_partition[partition].push(indices[base_index + 1])
    indices_per_partition[partition].push(indices[base_index + 2])
  }
  indices_per_partition
}

///|
fn MeshletTempGroup::default() -> MeshletTempGroup {
  MeshletTempGroup::{
    aabb: meshlet_bvh_default_aabb(),
    lod_bounds: meshlet_temp_sphere_zero(),
    parent_error: 1.0F / 0.0F,
    meshlets: [],
  }
}

///|
fn meshlet_groups_from_partitions(
  simplification_queue : Array[Int],
  meshlet_cull_data : Array[MeshletTempCullData],
  partition_per_meshlet : Array[Int],
  partition_count : Int,
) -> Array[MeshletTempGroup] {
  if partition_per_meshlet.length() != simplification_queue.length() {
    abort(
      "meshlet group partition output length must match simplification queue",
    )
  }
  let groups : Array[MeshletTempGroup] = []
  for _ in 0..<partition_count {
    groups.push(MeshletTempGroup::default())
  }
  for index in 0..<partition_per_meshlet.length() {
    let group_index = partition_per_meshlet[index]
    if group_index < 0 || group_index >= groups.length() {
      abort("meshlet group partition id out of range")
    }
    let meshlet_id = simplification_queue[index]
    let group = groups[group_index]
    group.meshlets.push(meshlet_id)
    let data = meshlet_cull_data[meshlet_id]
    groups[group_index] = MeshletTempGroup::{
      ..group,
      aabb: meshlet_bvh_merge_aabb(group.aabb, data.aabb),
      lod_bounds: meshlet_merge_spheres(group.lod_bounds, data.lod_group_sphere),
    }
  }
  groups
}

///|
fn meshlet_collect_group_indices(
  group : MeshletTempGroup,
  meshlets : MeshletBuildMeshlets,
) -> Array[Int] {
  let group_indices : Array[Int] = []
  for meshlet_id in group.meshlets {
    let meshlet = meshlets.meshlets[meshlet_id]
    let triangle_index_count = meshlet.triangle_count * 3
    for triangle_index in 0..<triangle_index_count {
      let local_vertex_index = meshlets.meshlet_triangle_index(
        meshlet, triangle_index,
      )
      group_indices.push(meshlets.meshlet_vertex(meshlet, local_vertex_index))
    }
  }
  group_indices
}

///|
fn meshlet_simplified_group_accepted(
  original_index_count : Int,
  simplified_index_count : Int,
) -> Bool {
  if original_index_count <= 0 {
    return false
  }
  Float::from_int(simplified_index_count) /
  Float::from_int(original_index_count) <=
  MESHLET_SIMPLIFICATION_FAILURE_PERCENTAGE
}

///|
fn meshlet_triangles_in_meshlets(
  meshlets : MeshletBuildMeshlets,
  ids : Array[Int],
) -> Int {
  let mut count = 0
  for id in ids {
    count = count + meshlets.meshlets[id].triangle_count
  }
  count
}

///|
fn meshlet_merge_build_meshlets(
  meshlets : MeshletBuildMeshlets,
  merge : MeshletBuildMeshlets,
) -> Unit {
  let vertex_offset = meshlets.vertices.length()
  let triangle_offset = meshlets.triangles.length()
  for vertex in merge.vertices {
    meshlets.vertices.push(vertex)
  }
  for triangle in merge.triangles {
    meshlets.triangles.push(triangle)
  }
  for meshlet in merge.meshlets {
    meshlets.meshlets.push(MeshletBuildMeshlet::{
      ..meshlet,
      vertex_offset: meshlet.vertex_offset + vertex_offset,
      triangle_offset: meshlet.triangle_offset + triangle_offset,
    })
  }
}

///|
fn meshlet_find_connected_meshlets(
  simplification_queue : Array[Int],
  meshlets : MeshletBuildMeshlets,
  position_only_vertex_remap : Array[Int],
) -> Array[Array[MeshletConnectedMeshlet]] {
  let vertices_to_meshlets : Array[Array[Int]] = []
  for _ in 0..<position_only_vertex_remap.length() {
    vertices_to_meshlets.push([])
  }
  for id_index in 0..<simplification_queue.length() {
    let meshlet_id = simplification_queue[id_index]
    let meshlet = meshlets.meshlets[meshlet_id]
    let triangle_index_count = meshlet.triangle_count * 3
    for triangle_index in 0..<triangle_index_count {
      let local_vertex_index = meshlets.meshlet_triangle_index(
        meshlet, triangle_index,
      )
      let source_vertex_id = meshlets.meshlet_vertex(
        meshlet, local_vertex_index,
      )
      let vertex_id = position_only_vertex_remap[source_vertex_id]
      let vertex_meshlets = vertices_to_meshlets[vertex_id]
      if vertex_meshlets.is_empty() ||
        vertex_meshlets[vertex_meshlets.length() - 1] != id_index {
        vertex_meshlets.push(id_index)
      }
    }
  }

  let pairs : Array[MeshletPairConnection] = []
  for vertex_meshlets in vertices_to_meshlets {
    for left_index in 0..<vertex_meshlets.length() {
      for right_index in (left_index + 1)..<vertex_meshlets.length() {
        meshlet_increment_pair_connection(
          pairs,
          vertex_meshlets[left_index],
          vertex_meshlets[right_index],
        )
      }
    }
  }

  let connected : Array[Array[MeshletConnectedMeshlet]] = []
  for _ in 0..<simplification_queue.length() {
    connected.push([])
  }
  for pair in pairs {
    connected[pair.left].push(
      MeshletConnectedMeshlet::new(
        meshlet_id=pair.right,
        shared_vertex_count=pair.shared_vertex_count,
      ),
    )
    connected[pair.right].push(
      MeshletConnectedMeshlet::new(
        meshlet_id=pair.left,
        shared_vertex_count=pair.shared_vertex_count,
      ),
    )
  }
  for list in connected {
    list.sort_by(meshlet_connected_meshlet_cmp)
  }
  connected
}

///|
priv struct MeshletPartitionGraph {
  xadj : Array[Int]
  adjncy : Array[Int]
  adjwgt : Array[Int]
  partition_count : Int
  imbalance_factor : Int
}

///|
fn meshlet_build_group_partition_graph(
  simplification_queue : Array[Int],
  connected_meshlets_per_meshlet : Array[Array[MeshletConnectedMeshlet]],
) -> MeshletPartitionGraph {
  let xadj : Array[Int] = []
  let adjncy : Array[Int] = []
  let adjwgt : Array[Int] = []
  for connected_meshlets in connected_meshlets_per_meshlet {
    xadj.push(adjncy.length())
    for connected_meshlet in connected_meshlets {
      adjncy.push(connected_meshlet.meshlet_id)
      adjwgt.push(connected_meshlet.shared_vertex_count)
    }
  }
  xadj.push(adjncy.length())
  let partition_count = (
      simplification_queue.length() + MESHLET_TARGET_MESHLETS_PER_GROUP - 1
    ) /
    MESHLET_TARGET_MESHLETS_PER_GROUP
  MeshletPartitionGraph::{
    xadj,
    adjncy,
    adjwgt,
    partition_count,
    imbalance_factor: 200,
  }
}

///|
fn meshlet_lock_group_borders(
  vertex_locks : Array[Bool],
  groups : Array[MeshletTempGroup],
  meshlets : MeshletBuildMeshlets,
  position_only_vertex_remap : Array[Int],
) -> Unit {
  let position_only_locks : Array[Int] = []
  for _ in 0..<position_only_vertex_remap.length() {
    position_only_locks.push(-1)
  }
  for group_id in 0..<groups.length() {
    let group = groups[group_id]
    for meshlet_id in group.meshlets {
      let meshlet = meshlets.meshlets[meshlet_id]
      let triangle_index_count = meshlet.triangle_count * 3
      for triangle_index in 0..<triangle_index_count {
        let local_vertex_index = meshlets.meshlet_triangle_index(
          meshlet, triangle_index,
        )
        let source_vertex_id = meshlets.meshlet_vertex(
          meshlet, local_vertex_index,
        )
        let vertex_id = position_only_vertex_remap[source_vertex_id]
        if position_only_locks[vertex_id] == -1 ||
          position_only_locks[vertex_id] == group_id {
          position_only_locks[vertex_id] = group_id
        } else {
          position_only_locks[vertex_id] = -2
        }
      }
    }
  }
  for index in 0..<vertex_locks.length() {
    let vertex_id = position_only_vertex_remap[index]
    vertex_locks[index] = position_only_locks[vertex_id] == -2
  }
}

///|
priv struct MeshletTempSphere {
  center : @math.Vec3
  radius : Float
}

///|
fn MeshletTempSphere::new(
  center : @math.Vec3,
  radius : Float,
) -> MeshletTempSphere {
  MeshletTempSphere::{ center, radius }
}

///|
fn meshlet_temp_sphere_zero() -> MeshletTempSphere {
  MeshletTempSphere::new(@math.Vec3::zero(), 0.0F)
}

///|
priv struct MeshletTempCullData {
  aabb : @math.Aabb3d
  lod_group_sphere : MeshletTempSphere
  error : Float
}

///|
priv struct MeshletTempGroup {
  aabb : @math.Aabb3d
  lod_bounds : MeshletTempSphere
  parent_error : Float
  meshlets : Array[Int]
}

///|
fn MeshletTempGroup::new(
  aabb~ : @math.Aabb3d,
  lod_bounds~ : MeshletTempSphere,
  parent_error~ : Float,
  meshlets~ : Array[Int],
) -> MeshletTempGroup {
  MeshletTempGroup::{ aabb, lod_bounds, parent_error, meshlets }
}

///|
priv struct MeshletTempBvhNode {
  group : Int
  aabb : @math.Aabb3d
  children : Array[Int]
}

///|
priv struct MeshletBvhBuildResult {
  bvh : Array[BvhNode]
  meshlets : Array[Meshlet]
  cull_data : Array[MeshletCullData]
  aabb : MeshletAabb
  bvh_depth : Int
}

///|
priv struct MeshletBvhLodRange {
  start : Int
  end : Int
}

///|
priv struct MeshletBvhBuilder {
  nodes : Array[MeshletTempBvhNode]
  lods : Array[MeshletBvhLodRange]
}

///|
fn meshlet_bvh_default_aabb() -> @math.Aabb3d {
  @math.Aabb3d::from_min_max(
    @math.Vec3::splat(1.0F / 0.0F),
    @math.Vec3::splat(-1.0F / 0.0F),
  )
}

///|
fn meshlet_bvh_aabb_valid(aabb : @math.Aabb3d) -> Bool {
  let half = aabb.half_size()
  half.x >= 0.0F && half.y >= 0.0F && half.z >= 0.0F
}

///|
fn meshlet_bvh_aabb_min(aabb : @math.Aabb3d) -> @math.Vec3 {
  aabb.center().sub(aabb.half_size())
}

///|
fn meshlet_bvh_aabb_max(aabb : @math.Aabb3d) -> @math.Vec3 {
  aabb.center().add(aabb.half_size())
}

///|
fn meshlet_bvh_min_float(lhs : Float, rhs : Float) -> Float {
  if lhs < rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn meshlet_bvh_max_float(lhs : Float, rhs : Float) -> Float {
  if lhs > rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn meshlet_bvh_merge_aabb(
  lhs : @math.Aabb3d,
  rhs : @math.Aabb3d,
) -> @math.Aabb3d {
  if !meshlet_bvh_aabb_valid(lhs) {
    return rhs
  }
  if !meshlet_bvh_aabb_valid(rhs) {
    return lhs
  }
  let lhs_min = meshlet_bvh_aabb_min(lhs)
  let lhs_max = meshlet_bvh_aabb_max(lhs)
  let rhs_min = meshlet_bvh_aabb_min(rhs)
  let rhs_max = meshlet_bvh_aabb_max(rhs)
  @math.Aabb3d::from_min_max(
    @math.Vec3::new(
      meshlet_bvh_min_float(lhs_min.x, rhs_min.x),
      meshlet_bvh_min_float(lhs_min.y, rhs_min.y),
      meshlet_bvh_min_float(lhs_min.z, rhs_min.z),
    ),
    @math.Vec3::new(
      meshlet_bvh_max_float(lhs_max.x, rhs_max.x),
      meshlet_bvh_max_float(lhs_max.y, rhs_max.y),
      meshlet_bvh_max_float(lhs_max.z, rhs_max.z),
    ),
  )
}

///|
fn meshlet_bvh_visible_area(aabb : @math.Aabb3d) -> Float {
  if !meshlet_bvh_aabb_valid(aabb) {
    return 0.0F
  }
  let size = aabb.half_size().mul_scalar(2.0F)
  2.0F * (size.x * size.y + size.y * size.z + size.z * size.x)
}

///|
fn meshlet_bvh_axis_value(aabb : @math.Aabb3d, axis : Int) -> Float {
  let center = aabb.center()
  if axis == 0 {
    center.x
  } else if axis == 1 {
    center.y
  } else {
    center.z
  }
}

///|
fn meshlet_bvh_float_cmp(lhs : Float, rhs : Float) -> Int {
  if lhs < rhs {
    -1
  } else if lhs > rhs {
    1
  } else {
    0
  }
}

///|
fn meshlet_merge_spheres(
  lhs : MeshletTempSphere,
  rhs : MeshletTempSphere,
) -> MeshletTempSphere {
  let small_radius = lhs.radius.min(rhs.radius)
  let big_radius = lhs.radius.max(rhs.radius)
  let distance = lhs.center.distance(rhs.center)
  if distance + small_radius <= big_radius ||
    small_radius == 0.0F ||
    distance == 0.0F {
    if lhs.radius > rhs.radius {
      lhs
    } else {
      rhs
    }
  } else {
    let radius = (small_radius + big_radius + distance) / 2.0F
    let center = lhs.center
      .add(rhs.center)
      .add(
        lhs.center
        .sub(rhs.center)
        .mul_scalar((lhs.radius - rhs.radius) / distance),
      )
      .mul_scalar(0.5F)
    MeshletTempSphere::new(center, radius)
  }
}

///|
fn meshlet_aabb_to_error_offset(
  aabb : @math.Aabb3d,
  error : Float,
  child_offset : Int,
) -> MeshletAabbErrorOffset {
  let center = aabb.center()
  let half = aabb.half_size()
  MeshletAabbErrorOffset::{
    center_x: center.x,
    center_y: center.y,
    center_z: center.z,
    error,
    half_extent_x: half.x,
    half_extent_y: half.y,
    half_extent_z: half.z,
    child_offset,
  }
}

///|
fn meshlet_sphere_to_asset(sphere : MeshletTempSphere) -> MeshletBoundingSphere {
  MeshletBoundingSphere::{
    center_x: sphere.center.x,
    center_y: sphere.center.y,
    center_z: sphere.center.z,
    radius: sphere.radius,
  }
}

///|
fn meshlet_asset_aabb_to_math(aabb : MeshletAabbErrorOffset) -> @math.Aabb3d {
  @math.Aabb3d::new(
    @math.Vec3::new(aabb.center_x, aabb.center_y, aabb.center_z),
    @math.Vec3::new(aabb.half_extent_x, aabb.half_extent_y, aabb.half_extent_z),
  )
}

///|
fn meshlet_asset_sphere_to_temp(
  sphere : MeshletBoundingSphere,
) -> MeshletTempSphere {
  MeshletTempSphere::new(
    @math.Vec3::new(sphere.center_x, sphere.center_y, sphere.center_z),
    sphere.radius,
  )
}

///|
fn meshlet_temp_cull_to_asset(
  cull_data : MeshletTempCullData,
) -> MeshletCullData {
  MeshletCullData::{
    aabb: meshlet_aabb_to_error_offset(cull_data.aabb, cull_data.error, 0),
    lod_group_sphere: meshlet_sphere_to_asset(cull_data.lod_group_sphere),
  }
}

///|
fn MeshletBvhBuilder::new() -> MeshletBvhBuilder {
  MeshletBvhBuilder::{ nodes: [], lods: [] }
}

///|
fn MeshletBvhBuilder::add_lod(
  self : MeshletBvhBuilder,
  offset : Int,
  all_groups : Array[MeshletTempGroup],
) -> Unit {
  let first = self.nodes.length()
  for index in offset..<all_groups.length() {
    let group = all_groups[index]
    self.nodes.push(MeshletTempBvhNode::{
      group: index,
      aabb: group.aabb,
      children: [],
    })
  }
  let end = self.nodes.length()
  if first != end {
    self.lods.push(MeshletBvhLodRange::{ start: first, end })
  }
}

///|
fn MeshletBvhBuilder::surface_area(
  self : MeshletBvhBuilder,
  nodes : Array[Int],
) -> Float {
  if nodes.is_empty() {
    abort("cannot find surface area of zero nodes")
  }
  let mut aabb = meshlet_bvh_default_aabb()
  for node_id in nodes {
    aabb = meshlet_bvh_merge_aabb(aabb, self.nodes[node_id].aabb)
  }
  meshlet_bvh_visible_area(aabb)
}

///|
fn MeshletBvhBuilder::sort_node_ids_by_axis(
  self : MeshletBvhBuilder,
  nodes : Array[Int],
  start : Int,
  count : Int,
  axis : Int,
) -> Unit {
  let segment : Array[Int] = []
  for index in start..<(start + count) {
    segment.push(nodes[index])
  }
  segment.sort_by(fn(left, right) {
    meshlet_bvh_float_cmp(
      meshlet_bvh_axis_value(self.nodes[left].aabb, axis),
      meshlet_bvh_axis_value(self.nodes[right].aabb, axis),
    )
  })
  for index in 0..<segment.length() {
    nodes[start + index] = segment[index]
  }
}

///|
fn meshlet_bvh_node_range_ids(
  nodes : Array[Int],
  start : Int,
  count : Int,
) -> Array[Int] {
  let ids : Array[Int] = []
  for index in start..<(start + count) {
    ids.push(nodes[index])
  }
  ids
}

///|
fn MeshletBvhBuilder::sort_nodes_by_sah(
  self : MeshletBvhBuilder,
  nodes : Array[Int],
  splits : Array[Int],
) -> Unit {
  for depth in 0..<3 {
    let parts = 1 << depth
    let nodes_per_split = 8 >> depth
    let half_count = nodes_per_split / 2
    let mut offset = 0
    for part in 0..<parts {
      let first = part * nodes_per_split
      let mut left_count = 0
      let mut right_count = 0
      for index in 0..<half_count {
        left_count = left_count + splits[first + index]
        right_count = right_count + splits[first + half_count + index]
      }
      let count = left_count + right_count
      let mut best_cost = 1.0F / 0.0F
      let mut best_axis = 0
      for axis in 0..<3 {
        self.sort_node_ids_by_axis(nodes, offset, count, axis)
        let left = meshlet_bvh_node_range_ids(nodes, offset, left_count)
        let right = meshlet_bvh_node_range_ids(
          nodes,
          offset + left_count,
          right_count,
        )
        let cost = self.surface_area(left) + self.surface_area(right)
        if cost < best_cost {
          best_axis = axis
          best_cost = cost
        }
      }
      if best_axis != 2 {
        self.sort_node_ids_by_axis(nodes, offset, count, best_axis)
      }
      offset = offset + count
    }
  }
}

///|
fn meshlet_bvh_largest_power_of_8_at_most(count : Int) -> Int {
  let mut value = 1
  while value * 8 <= count {
    value = value * 8
  }
  value
}

///|
fn MeshletBvhBuilder::build_temp_inner(
  self : MeshletBvhBuilder,
  nodes : Array[Int],
  optimize : Bool,
) -> Int {
  let count = nodes.length()
  if count == 1 {
    nodes[0]
  } else if count <= 8 {
    let index = self.nodes.length()
    self.nodes.push(MeshletTempBvhNode::{
      group: -1,
      aabb: meshlet_bvh_default_aabb(),
      children: nodes,
    })
    index
  } else {
    let max_child_size = meshlet_bvh_largest_power_of_8_at_most(count)
    let min_child_size = max_child_size / 8
    let max_extra_per_node = max_child_size - min_child_size
    let splits : Array[Int] = []
    let mut extra = count - max_child_size
    for _ in 0..<8 {
      let size = extra.min(max_extra_per_node)
      extra = extra - size
      splits.push(min_child_size + size)
    }
    if optimize {
      self.sort_nodes_by_sah(nodes, splits)
    }
    let children : Array[Int] = []
    let mut offset = 0
    for size in splits {
      let child_nodes = meshlet_bvh_node_range_ids(nodes, offset, size)
      children.push(self.build_temp_inner(child_nodes, optimize))
      offset = offset + size
    }
    let index = self.nodes.length()
    self.nodes.push(MeshletTempBvhNode::{
      group: -1,
      aabb: meshlet_bvh_default_aabb(),
      children,
    })
    index
  }
}

///|
fn MeshletBvhBuilder::build_temp(self : MeshletBvhBuilder) -> Int {
  let lod_roots : Array[Int] = []
  for lod in self.lods {
    let lod_nodes : Array[Int] = []
    for node_id in lod.start..<lod.end {
      lod_nodes.push(node_id)
    }
    let root = self.build_temp_inner(lod_nodes, true)
    let node = self.nodes[root]
    if node.group != -1 || node.children.length() == 8 {
      lod_roots.push(root)
    } else {
      for child in node.children {
        lod_roots.push(child)
      }
    }
  }
  self.build_temp_inner(lod_roots, false)
}

///|
fn meshlet_bvh_set_leaf_slot(
  node : BvhNode,
  index : Int,
  group : MeshletTempGroup,
) -> Unit {
  node.aabbs[index] = meshlet_aabb_to_error_offset(
    group.aabb,
    group.parent_error,
    group.meshlets[0],
  )
  node.lod_bounds[index] = meshlet_sphere_to_asset(group.lod_bounds)
  node.child_counts[index] = group.meshlets[1]
}

///|
fn MeshletBvhBuilder::build_inner(
  self : MeshletBvhBuilder,
  groups : Array[MeshletTempGroup],
  out : Array[BvhNode],
  max_depth : Ref[Int],
  node_id : Int,
  depth : Int,
) -> Int {
  max_depth.val = max_depth.val.max(depth)
  let node = self.nodes[node_id]
  let output_node = out.length()
  out.push(BvhNode::default())
  for child_index in 0..<node.children.length() {
    let child = self.nodes[node.children[child_index]]
    if child.group != -1 {
      meshlet_bvh_set_leaf_slot(
        out[output_node],
        child_index,
        groups[child.group],
      )
    } else {
      let child_output = self.build_inner(
        groups,
        out,
        max_depth,
        node.children[child_index],
        depth + 1,
      )
      let child_bvh = out[child_output]
      let mut aabb = meshlet_bvh_default_aabb()
      let mut parent_error = 0.0F
      let mut lod_bounds = meshlet_temp_sphere_zero()
      for index in 0..<8 {
        if child_bvh.child_counts[index] == 0 {
          break
        }
        aabb = meshlet_bvh_merge_aabb(
          aabb,
          meshlet_asset_aabb_to_math(child_bvh.aabbs[index]),
        )
        lod_bounds = meshlet_merge_spheres(
          lod_bounds,
          meshlet_asset_sphere_to_temp(child_bvh.lod_bounds[index]),
        )
        parent_error = parent_error.max(child_bvh.aabbs[index].error)
      }
      out[output_node].aabbs[child_index] = meshlet_aabb_to_error_offset(
        aabb, parent_error, child_output,
      )
      out[output_node].lod_bounds[child_index] = meshlet_sphere_to_asset(
        lod_bounds,
      )
      out[output_node].child_counts[child_index] = MESHLET_BVH_INNER_CHILD_COUNT
    }
  }
  output_node
}

///|
fn meshlet_verify_bvh(
  out : Array[BvhNode],
  cull_data : Array[MeshletTempCullData],
  reachable : Array[Bool],
  node_id : Int,
) -> Unit {
  let node = out[node_id]
  for index in 0..<8 {
    let child_count = node.child_counts[index]
    if child_count == 0 {
      break
    }
    let sphere = meshlet_asset_sphere_to_temp(node.lod_bounds[index])
    let error = node.aabbs[index].error
    if child_count == MESHLET_BVH_INNER_CHILD_COUNT {
      let child = out[node.aabbs[index].child_offset]
      for child_index in 0..<8 {
        if child.child_counts[child_index] == 0 {
          break
        }
        if child.aabbs[child_index].error > error {
          abort("BVH errors are not monotonic")
        }
        let child_sphere = meshlet_asset_sphere_to_temp(
          child.lod_bounds[child_index],
        )
        let sphere_error = sphere.center.distance(child_sphere.center) -
          (sphere.radius - child_sphere.radius)
        if sphere_error > 0.0001F {
          abort("BVH lod spheres are not monotonic")
        }
      }
      meshlet_verify_bvh(
        out,
        cull_data,
        reachable,
        node.aabbs[index].child_offset,
      )
    } else {
      for offset in 0..<child_count {
        let meshlet_id = node.aabbs[index].child_offset + offset
        let meshlet = cull_data[meshlet_id]
        if meshlet.error > error {
          abort("meshlet errors are not monotonic")
        }
        let sphere_error = sphere.center.distance(
            meshlet.lod_group_sphere.center,
          ) -
          (sphere.radius - meshlet.lod_group_sphere.radius)
        if sphere_error > 0.0001F {
          abort("meshlet lod spheres are not monotonic")
        }
        reachable[meshlet_id] = true
      }
    }
  }
}

///|
fn MeshletBvhBuilder::build(
  self : MeshletBvhBuilder,
  meshlets : Array[Meshlet],
  groups : Array[MeshletTempGroup],
  cull_data : Array[MeshletTempCullData],
) -> MeshletBvhBuildResult {
  let remapped_meshlets : Array[Meshlet] = []
  let remapped_cull_data : Array[MeshletTempCullData] = []
  for group_index in 0..<groups.length() {
    let group = groups[group_index]
    let first = remapped_meshlets.length()
    let count = group.meshlets.length()
    for meshlet_id in group.meshlets {
      remapped_meshlets.push(meshlets[meshlet_id])
      remapped_cull_data.push(cull_data[meshlet_id])
    }
    groups[group_index] = MeshletTempGroup::{
      ..group,
      meshlets: [first, count],
    }
  }
  let out : Array[BvhNode] = []
  let mut aabb = meshlet_bvh_default_aabb()
  let max_depth = Ref(0)
  if self.nodes.length() == 1 {
    let node = BvhNode::default()
    let group = groups[0]
    meshlet_bvh_set_leaf_slot(node, 0, group)
    out.push(node)
    aabb = group.aabb
    max_depth.val = 1
  } else {
    let root = self.build_temp()
    let output_root = self.build_inner(groups, out, max_depth, root, 1)
    if output_root != 0 {
      abort("root must be 0")
    }
    let root_node = out[0]
    for index in 0..<8 {
      if root_node.child_counts[index] == 0 {
        break
      }
      aabb = meshlet_bvh_merge_aabb(
        aabb,
        meshlet_asset_aabb_to_math(root_node.aabbs[index]),
      )
    }
  }
  let reachable : Array[Bool] = []
  for _ in 0..<remapped_meshlets.length() {
    reachable.push(false)
  }
  meshlet_verify_bvh(out, remapped_cull_data, reachable, 0)
  for reached in reachable {
    if !reached {
      abort("all meshlets must be reachable")
    }
  }
  let asset_cull : Array[MeshletCullData] = []
  for item in remapped_cull_data {
    asset_cull.push(meshlet_temp_cull_to_asset(item))
  }
  let center = aabb.center()
  let half = aabb.half_size()
  MeshletBvhBuildResult::{
    bvh: out,
    meshlets: remapped_meshlets,
    cull_data: asset_cull,
    aabb: MeshletAabb::new(
      center_x=center.x,
      center_y=center.y,
      center_z=center.z,
      half_extent_x=half.x,
      half_extent_y=half.y,
      half_extent_z=half.z,
    ),
    bvh_depth: max_depth.val,
  }
}
