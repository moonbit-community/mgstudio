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
pub(all) suberror MeshToMeshletMeshConversionError {
  RuntimeUnavailable
  ProcessorError(String)
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
pub fn MeshToMeshletMeshConversionConfig::MeshToMeshletMeshConversionConfig() -> MeshToMeshletMeshConversionConfig {
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
  processor_available : Bool,
) -> MeshToMeshletMeshConversionError? {
  let safe = meshlet_validate_conversion_config(config)
  if !processor_available {
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
pub fn meshlet_processor_available() -> Bool {
  true
}

///|
pub fn meshlet_can_convert_from_mesh(
  vertex_count : Int,
  triangle_count : Int,
) -> Bool {
  meshlet_processor_available() && vertex_count > 0 && triangle_count > 0
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
) -> MeshletMeshInputData raise MeshToMeshletMeshConversionError {
  guard mesh.primitive_topology()
    is Some(@mesh.Mesh3dPrimitiveTopology::TriangleList) else {
    raise MeshToMeshletMeshConversionError::WrongMeshPrimitiveTopology
  }
  let attributes = mesh.attributes()
  if !meshlet_mesh_has_exact_required_attributes(attributes) {
    raise MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
      meshlet_mesh_vertex_attribute_names(attributes),
    )
  }
  guard mesh.indices() is Some(indices) else {
    raise MeshToMeshletMeshConversionError::MeshMissingIndices
  }
  guard attributes[0].values()
    is @mesh.VertexAttributeValues::Float32x3(positions) else {
    raise MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
      meshlet_mesh_vertex_attribute_names(attributes),
    )
  }
  guard attributes[1].values()
    is @mesh.VertexAttributeValues::Float32x3(normals) else {
    raise MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
      meshlet_mesh_vertex_attribute_names(attributes),
    )
  }
  guard attributes[2].values() is @mesh.VertexAttributeValues::Float32x2(uvs) else {
    raise MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(
      meshlet_mesh_vertex_attribute_names(attributes),
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
  MeshletMeshInputData::new(vertices~, indices~)
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
    meshlet_processor_available(),
  )
}

///|
pub fn MeshletMesh::from_mesh(
  mesh : @mesh.Mesh,
  vertex_position_quantization_factor? : Int = MESHLET_DEFAULT_VERTEX_POSITION_QUANTIZATION_FACTOR,
) -> MeshletMesh raise MeshToMeshletMeshConversionError {
  let input = meshlet_extract_mesh_input(mesh)
  if !meshlet_processor_available() {
    raise MeshToMeshletMeshConversionError::RuntimeUnavailable
  }
  meshlet_build_from_mesh_with_processor(
    input, vertex_position_quantization_factor,
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
fn meshlet_source_positions_fixed(
  vertices : Array[MeshletSourceVertex],
) -> FixedArray[Float] {
  if vertices.is_empty() {
    return []
  }
  let positions = FixedArray::make(vertices.length() * 3, 0.0F)
  for index in 0..<vertices.length() {
    let vertex = vertices[index]
    let offset = index * 3
    positions[offset] = vertex.position.x
    positions[offset + 1] = vertex.position.y
    positions[offset + 2] = vertex.position.z
  }
  positions
}

///|
fn meshlet_source_normals_fixed(
  vertices : Array[MeshletSourceVertex],
) -> FixedArray[Float] {
  if vertices.is_empty() {
    return []
  }
  let normals = FixedArray::make(vertices.length() * 3, 0.0F)
  for index in 0..<vertices.length() {
    let vertex = vertices[index]
    let offset = index * 3
    normals[offset] = vertex.normal.x
    normals[offset + 1] = vertex.normal.y
    normals[offset + 2] = vertex.normal.z
  }
  normals
}

///|
fn meshlet_int_array_to_fixed(values : Array[Int]) -> FixedArray[Int] {
  if values.is_empty() {
    return []
  }
  let fixed = FixedArray::make(values.length(), 0)
  for index in 0..<values.length() {
    fixed[index] = values[index]
  }
  fixed
}

///|
fn meshlet_fixed_int_to_array(values : FixedArray[Int]) -> Array[Int] {
  let out : Array[Int] = []
  for index in 0..<values.length() {
    out.push(values[index])
  }
  out
}

///|
fn meshlet_uint_indices_fixed(values : Array[Int]) -> FixedArray[UInt]? {
  if values.is_empty() {
    return Some([])
  }
  let fixed = FixedArray::make(values.length(), 0U)
  for index in 0..<values.length() {
    let value = values[index]
    if value < 0 {
      return None
    }
    fixed[index] = value.reinterpret_as_uint()
  }
  Some(fixed)
}

///|
fn meshlet_fixed_uint_to_int_array(
  values : FixedArray[UInt],
  length : Int,
) -> Array[Int] {
  let out : Array[Int] = []
  let count = length.min(values.length())
  for index in 0..<count {
    out.push(values[index].reinterpret_as_int())
  }
  out
}

///|
fn meshlet_fixed_uint_slice(
  values : FixedArray[UInt],
  start : Int,
  length : Int,
) -> FixedArray[UInt] {
  if length <= 0 {
    return []
  }
  let out = FixedArray::make(length, 0U)
  for index in 0..<length {
    out[index] = values[start + index]
  }
  out
}

///|
fn meshlet_bytes_slice(source : Bytes, start : Int, length : Int) -> Bytes {
  if length <= 0 {
    return Bytes::new(0)
  }
  Bytes::makei(length, index => source[start + index])
}

///|
fn meshlet_meshopt_error(message : String) -> MeshToMeshletMeshConversionError {
  MeshToMeshletMeshConversionError::ProcessorError(message)
}

///|
fn meshlet_source_aabb_from_vertices(
  input : MeshletMeshInputData,
  vertex_ids : FixedArray[UInt],
  vertex_count : Int,
) -> @math.Aabb3d {
  let points : Array[@math.Vec3] = []
  for index in 0..<vertex_count {
    points.push(input.vertices[vertex_ids[index].reinterpret_as_int()].position)
  }
  @math.Aabb3d::from_point_cloud(@math.Isometry3d::identity(), points)
}

///|
fn meshlet_generate_position_remap(
  vertices : Array[MeshletSourceVertex],
) -> Array[Int] {
  if vertices.is_empty() {
    return []
  }
  let remap = @meshopt.generate_position_remap(
    meshlet_source_positions_fixed(vertices),
    vertices.length(),
    12,
  ) catch {
    _ => abort("meshopt position remap failed")
  }
  meshlet_fixed_uint_to_int_array(remap, remap.length())
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
fn MeshletTempGroup::MeshletTempGroup() -> MeshletTempGroup {
  MeshletTempGroup::new(
    aabb=meshlet_bvh_default_aabb(),
    lod_bounds=meshlet_temp_sphere_zero(),
    parent_error=1.0F / 0.0F,
    meshlets=[],
  )
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
    groups.push(MeshletTempGroup::MeshletTempGroup())
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
priv enum MeshletLodSimplificationResult {
  MeshletLodSimplified(
    MeshletTempGroup,
    MeshletBuildMeshlets,
    Array[MeshletTempCullData]
  )
  MeshletLodStuck(MeshletTempGroup)
}

///|
priv struct MeshletLodIterationResult {
  first_group : Int
  passed_tris : Int
  stuck_tris : Int
  retried_stuck : Bool
}

///|
fn meshlet_lod_iteration_apply_results(
  meshlets : MeshletBuildMeshlets,
  cull_data : Array[MeshletTempCullData],
  all_groups : Array[MeshletTempGroup],
  simplification_queue : Array[Int],
  stuck : Array[MeshletTempGroup],
  bvh : MeshletBvhBuilder,
  simplified : Array[MeshletLodSimplificationResult],
) -> MeshletLodIterationResult {
  let first_group = all_groups.length()
  let mut passed_tris = 0
  let mut stuck_tris = 0
  simplification_queue.clear()
  for result in simplified {
    match result {
      MeshletLodSimplified(group, new_meshlets, new_cull_data) => {
        let start = meshlets.len()
        meshlet_merge_build_meshlets(meshlets, new_meshlets)
        for item in new_cull_data {
          cull_data.push(item)
        }
        let end = meshlets.len()
        let new_meshlet_ids : Array[Int] = []
        for meshlet_id in start..<end {
          new_meshlet_ids.push(meshlet_id)
          simplification_queue.push(meshlet_id)
        }
        passed_tris = passed_tris +
          meshlet_triangles_in_meshlets(meshlets, new_meshlet_ids)
        all_groups.push(group)
      }
      MeshletLodStuck(group) => {
        stuck_tris = stuck_tris +
          meshlet_triangles_in_meshlets(meshlets, group.meshlets)
        stuck.push(group)
      }
    }
  }
  let retried_stuck = passed_tris > stuck_tris / 3
  if retried_stuck {
    for group in stuck {
      for meshlet_id in group.meshlets {
        simplification_queue.push(meshlet_id)
      }
    }
    stuck.clear()
  }
  bvh.add_lod(first_group, all_groups)
  MeshletLodIterationResult::{
    first_group,
    passed_tris,
    stuck_tris,
    retried_stuck,
  }
}

///|
fn meshlet_lod_append_final_stuck_lod(
  all_groups : Array[MeshletTempGroup],
  stuck : Array[MeshletTempGroup],
  bvh : MeshletBvhBuilder,
) -> Bool {
  if stuck.is_empty() {
    return false
  }
  let first_group = all_groups.length()
  for group in stuck {
    all_groups.push(group)
  }
  stuck.clear()
  bvh.add_lod(first_group, all_groups)
  true
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
  meshlets : MeshletBuildMeshlets
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
  out.push(BvhNode::BvhNode())
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
  meshlets : MeshletBuildMeshlets,
  groups : Array[MeshletTempGroup],
  cull_data : Array[MeshletTempCullData],
) -> MeshletBvhBuildResult {
  let remapped_meshlets : Array[MeshletBuildMeshlet] = []
  let remapped_cull_data : Array[MeshletTempCullData] = []
  for group_index in 0..<groups.length() {
    let group = groups[group_index]
    let first = remapped_meshlets.length()
    let count = group.meshlets.length()
    for meshlet_id in group.meshlets {
      remapped_meshlets.push(meshlets.meshlets[meshlet_id])
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
    let node = BvhNode::BvhNode()
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
    meshlets: MeshletBuildMeshlets::{
      meshlets: remapped_meshlets,
      vertices: meshlets.vertices,
      triangles: meshlets.triangles,
    },
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

///|
fn meshlet_read_lsb_bit(words : Array[Int], bit : Int) -> Bool {
  let word_index = bit / 32
  let bit_index = bit % 32
  if word_index >= words.length() {
    false
  } else {
    ((words[word_index].reinterpret_as_uint() >> bit_index) & 1U) != 0U
  }
}

///|
fn meshlet_append_position_bitstream(
  words : Array[Int],
  start_bit : Int,
  source_words : Array[Int],
  source_bit_len : Int,
) -> Int {
  let mut cursor = start_bit
  for bit in 0..<source_bit_len {
    let word_index = cursor / 32
    let bit_index = cursor % 32
    meshlet_ensure_position_word(words, word_index)
    if meshlet_read_lsb_bit(source_words, bit) {
      let current = words[word_index].reinterpret_as_uint()
      words[word_index] = (current | (1U << bit_index)).reinterpret_as_int()
    }
    cursor = cursor + 1
  }
  cursor
}

///|
fn meshlet_source_vertices_for_build_meshlet(
  input : MeshletMeshInputData,
  meshlets : MeshletBuildMeshlets,
  meshlet : MeshletBuildMeshlet,
) -> Array[MeshletSourceVertex] {
  let source_vertices : Array[MeshletSourceVertex] = []
  for local_vertex_index in 0..<meshlet.vertex_count {
    let source_vertex_id = meshlets.meshlet_vertex(meshlet, local_vertex_index)
    source_vertices.push(input.vertices[source_vertex_id])
  }
  source_vertices
}

///|
fn meshlet_finalize_bvh_build(
  input : MeshletMeshInputData,
  built : MeshletBvhBuildResult,
  vertex_position_quantization_factor? : Int = MESHLET_DEFAULT_VERTEX_POSITION_QUANTIZATION_FACTOR,
) -> MeshletMesh {
  let vertex_positions : Array[Int] = []
  let vertex_normals : Array[Int] = []
  let vertex_uvs : Array[MeshletVertexUv] = []
  let meshlets : Array[Meshlet] = []
  let mut vertex_position_bit_len = 0
  for build_meshlet in built.meshlets.meshlets {
    let source_vertices = meshlet_source_vertices_for_build_meshlet(
      input,
      built.meshlets,
      build_meshlet,
    )
    let start_vertex_position_bit = vertex_position_bit_len
    let start_vertex_attribute_id = vertex_normals.length()
    let compressed = meshlet_build_compressed_vertex_data(
      source_vertices,
      start_index_id=build_meshlet.triangle_offset,
      triangle_count=build_meshlet.triangle_count,
      vertex_position_quantization_factor~,
    )
    vertex_position_bit_len = meshlet_append_position_bitstream(
      vertex_positions,
      vertex_position_bit_len,
      compressed.vertex_positions,
      compressed.vertex_position_bit_len,
    )
    for normal in compressed.vertex_normals {
      vertex_normals.push(normal)
    }
    for uv in compressed.vertex_uvs {
      vertex_uvs.push(uv)
    }
    meshlets.push(Meshlet::{
      ..compressed.meshlet,
      start_vertex_position_bit,
      start_vertex_attribute_id,
    })
  }
  MeshletMesh::from_parts(
    vertex_positions~,
    vertex_normals~,
    vertex_uvs~,
    indices=built.meshlets.triangles,
    bvh=built.bvh,
    meshlets~,
    meshlet_cull_data=built.cull_data,
    aabb=built.aabb,
    bvh_depth=built.bvh_depth,
  )
}

///|
priv struct MeshletGeneratedMeshlets {
  meshlets : MeshletBuildMeshlets
  cull_data : Array[MeshletTempCullData]
}

///|
priv struct MeshletTempLodData {
  lod_bounds : MeshletTempSphere
  parent_error : Float
}

///|
priv struct MeshletSimplifiedIndices {
  indices : Array[Int]
  error : Float
}

///|
fn meshlet_metis_graph_signature(graph : MeshletMetisPartitionGraph) -> Int {
  graph.xadj.length() +
  graph.adjncy.length() * 3 +
  graph.adjwgt.length() * 5 +
  graph.partition_count * 7 +
  graph.seed * 11 +
  graph.imbalance_factor * 13
}

///|
fn meshlet_group_graph_signature(graph : MeshletPartitionGraph) -> Int {
  graph.xadj.length() +
  graph.adjncy.length() * 3 +
  graph.adjwgt.length() * 5 +
  graph.partition_count * 7 +
  graph.imbalance_factor * 13
}

///|
fn meshlet_metis_partition_triangles(
  graph : MeshletMetisPartitionGraph,
) -> Array[Int] raise MeshToMeshletMeshConversionError {
  ignore(meshlet_metis_graph_signature(graph))
  if graph.partition_count <= 1 {
    let triangle_count = graph.xadj.length() - 1
    return Array::make(triangle_count, 0)
  }
  let csr = @metis.CsrGraph::new(
    graph.xadj.length() - 1,
    meshlet_int_array_to_fixed(graph.xadj),
    meshlet_int_array_to_fixed(graph.adjncy),
    adjwgt=meshlet_int_array_to_fixed(graph.adjwgt),
  ) catch {
    _ =>
      raise MeshToMeshletMeshConversionError::ProcessorError(
        "METIS graph error",
      )
  }
  let options = @metis.Options::default()
    .set_partitioning_scheme(@metis.PartitioningScheme::RecursiveBisection)
    .set_seed(graph.seed)
    .set_imbalance_factor(graph.imbalance_factor)
  let result = @metis.part_graph_recursive(csr, graph.partition_count, options~) catch {
    _ =>
      raise MeshToMeshletMeshConversionError::ProcessorError(
        "METIS partition error",
      )
  }
  meshlet_fixed_int_to_array(result.part)
}

///|
fn meshlet_metis_partition_meshlets(
  graph : MeshletPartitionGraph,
) -> Array[Int] raise MeshToMeshletMeshConversionError {
  ignore(meshlet_group_graph_signature(graph))
  if graph.partition_count <= 1 {
    let meshlet_count = graph.xadj.length() - 1
    return Array::make(meshlet_count, 0)
  }
  let csr = @metis.CsrGraph::new(
    graph.xadj.length() - 1,
    meshlet_int_array_to_fixed(graph.xadj),
    meshlet_int_array_to_fixed(graph.adjncy),
    adjwgt=meshlet_int_array_to_fixed(graph.adjwgt),
  ) catch {
    _ =>
      raise MeshToMeshletMeshConversionError::ProcessorError(
        "METIS graph error",
      )
  }
  let options = @metis.Options::default()
    .set_partitioning_scheme(@metis.PartitioningScheme::RecursiveBisection)
    .set_seed(17)
    .set_imbalance_factor(graph.imbalance_factor)
  let result = @metis.part_graph_recursive(csr, graph.partition_count, options~) catch {
    _ =>
      raise MeshToMeshletMeshConversionError::ProcessorError(
        "METIS partition error",
      )
  }
  meshlet_fixed_int_to_array(result.part)
}

///|
fn meshlet_meshopt_build_meshlets(
  input : MeshletMeshInputData,
  indices_per_partition : Array[Array[Int]],
  prev_lod_data : MeshletTempLodData?,
) -> MeshletGeneratedMeshlets raise MeshToMeshletMeshConversionError {
  let positions = meshlet_source_positions_fixed(input.vertices)
  let meshlets = MeshletBuildMeshlets::new(meshlets=[], vertices=[], triangles=[])
  let cull_data : Array[MeshletTempCullData] = []
  for partition_indices in indices_per_partition {
    if partition_indices.is_empty() {
      continue
    }
    guard meshlet_uint_indices_fixed(partition_indices) is Some(indices) else {
      raise meshlet_meshopt_error("meshopt indices must be non-negative")
    }
    let built = @meshopt.build_meshlets(
      indices,
      positions,
      input.vertices.length(),
      12,
      256,
      128,
      cone_weight=0.0F,
    ) catch {
      _ => raise meshlet_meshopt_error("meshopt build_meshlets error")
    }
    for meshlet_index in 0..<built.meshlet_count {
      let base = meshlet_index * 4
      let vertex_offset = built.meshlets[base].reinterpret_as_int()
      let triangle_offset = built.meshlets[base + 1].reinterpret_as_int()
      let vertex_count = built.meshlets[base + 2].reinterpret_as_int()
      let triangle_count = built.meshlets[base + 3].reinterpret_as_int()
      let meshlet_vertices = meshlet_fixed_uint_slice(
        built.vertices,
        vertex_offset,
        vertex_count,
      )
      let meshlet_triangles = meshlet_bytes_slice(
        built.triangles,
        triangle_offset,
        triangle_count * 3,
      )
      @meshopt.optimize_meshlet(
        meshlet_vertices, meshlet_triangles, triangle_count, vertex_count,
      ) catch {
        _ => raise meshlet_meshopt_error("meshopt optimize_meshlet error")
      }
      let bounds = @meshopt.compute_meshlet_bounds(
        meshlet_vertices,
        meshlet_triangles,
        triangle_count,
        positions,
        input.vertices.length(),
        12,
      ) catch {
        _ => raise meshlet_meshopt_error("meshopt compute_meshlet_bounds error")
      }
      let start_vertex = meshlets.vertices.length()
      let start_triangle = meshlets.triangles.length()
      for index in 0..<vertex_count {
        meshlets.vertices.push(meshlet_vertices[index].reinterpret_as_int())
      }
      for index in 0..<(triangle_count * 3) {
        meshlets.triangles.push(meshlet_triangles[index].to_int() & 0xFF)
      }
      meshlets.meshlets.push(
        MeshletBuildMeshlet::new(
          vertex_offset=start_vertex,
          triangle_offset=start_triangle,
          vertex_count~,
          triangle_count~,
        ),
      )
      let lod = match prev_lod_data {
        Some(data) => data
        None =>
          MeshletTempLodData::{
            lod_bounds: MeshletTempSphere::new(
              @math.Vec3::new(bounds.center_x, bounds.center_y, bounds.center_z),
              bounds.radius,
            ),
            parent_error: 0.0F,
          }
      }
      cull_data.push(MeshletTempCullData::{
        aabb: meshlet_source_aabb_from_vertices(
          input, meshlet_vertices, vertex_count,
        ),
        lod_group_sphere: lod.lod_bounds,
        error: lod.parent_error,
      })
    }
  }
  MeshletGeneratedMeshlets::{ meshlets, cull_data }
}

///|
fn meshlet_compute_meshlets_with_processor(
  input : MeshletMeshInputData,
  indices : Array[Int],
  position_only_vertex_remap : Array[Int],
  prev_lod_data : MeshletTempLodData?,
) -> MeshletGeneratedMeshlets raise MeshToMeshletMeshConversionError {
  let graph = meshlet_build_triangle_partition_graph(
    indices, position_only_vertex_remap,
  )
  let partition_per_triangle = meshlet_metis_partition_triangles(graph)
  let indices_per_partition = meshlet_collect_indices_per_partition(
    indices,
    partition_per_triangle,
    graph.partition_count,
  )
  meshlet_meshopt_build_meshlets(input, indices_per_partition, prev_lod_data)
}

///|
fn meshlet_meshopt_simplify_indices(
  group_indices : Array[Int],
  input : MeshletMeshInputData,
  vertex_locks : Array[Bool],
) -> MeshletSimplifiedIndices? raise MeshToMeshletMeshConversionError {
  guard meshlet_uint_indices_fixed(group_indices) is Some(indices) else {
    raise meshlet_meshopt_error("meshopt simplify indices must be non-negative")
  }
  let positions = meshlet_source_positions_fixed(input.vertices)
  let normals = meshlet_source_normals_fixed(input.vertices)
  let normal_weights : FixedArray[Float] = [0.5F, 0.5F, 0.5F]
  let lock_byte = @meshopt.VertexLockFlags::new(lock=true).byte()
  let locks = Bytes::makei(input.vertices.length(), index => {
    if index < vertex_locks.length() && vertex_locks[index] {
      lock_byte
    } else {
      (0).to_byte()
    }
  })
  let result = @meshopt.simplify_with_attributes(
    indices,
    positions,
    input.vertices.length(),
    12,
    normals,
    12,
    normal_weights,
    3,
    vertex_lock=locks,
    group_indices.length() / 2,
    3.4028235e38F,
    options=@meshopt.SimplifyOptions::new(sparse=true, error_absolute=true),
  ) catch {
    _ => raise meshlet_meshopt_error("meshopt simplify_with_attributes error")
  }
  Some(MeshletSimplifiedIndices::{
    indices: meshlet_fixed_uint_to_int_array(result.indices, result.index_count),
    error: result.error,
  })
}

///|
fn meshlet_simplify_group_with_processor(
  group : MeshletTempGroup,
  meshlets : MeshletBuildMeshlets,
  cull_data : Array[MeshletTempCullData],
  input : MeshletMeshInputData,
  position_only_vertex_remap : Array[Int],
  vertex_locks : Array[Bool],
) -> MeshletLodSimplificationResult raise MeshToMeshletMeshConversionError {
  if group.meshlets.length() == 1 {
    return MeshletLodStuck(group)
  }
  let group_indices = meshlet_collect_group_indices(group, meshlets)
  let simplified_or_error = meshlet_meshopt_simplify_indices(
    group_indices, input, vertex_locks,
  )
  let simplified = match simplified_or_error {
    Some(simplified) => simplified
    None => return MeshletLodStuck(group)
  }
  if !meshlet_simplified_group_accepted(
      group_indices.length(),
      simplified.indices.length(),
    ) {
    return MeshletLodStuck(group)
  }
  let mut group_error = simplified.error
  for meshlet_id in group.meshlets {
    group_error = group_error.max(cull_data[meshlet_id].error)
  }
  let next_group = MeshletTempGroup::{ ..group, parent_error: group_error }
  let generated = meshlet_compute_meshlets_with_processor(
    input,
    simplified.indices,
    position_only_vertex_remap,
    Some(MeshletTempLodData::{
      lod_bounds: next_group.lod_bounds,
      parent_error: next_group.parent_error,
    }),
  )
  MeshletLodSimplified(next_group, generated.meshlets, generated.cull_data)
}

///|
fn meshlet_build_from_mesh_with_processor(
  input : MeshletMeshInputData,
  vertex_position_quantization_factor : Int,
) -> MeshletMesh raise MeshToMeshletMeshConversionError {
  let position_only_vertex_remap = meshlet_generate_position_remap(
    input.vertices,
  )
  let generated = meshlet_compute_meshlets_with_processor(
    input,
    input.indices,
    position_only_vertex_remap,
    None,
  )
  let meshlets = generated.meshlets
  let cull_data = generated.cull_data
  let vertex_locks : Array[Bool] = []
  for _ in 0..<input.vertices.length() {
    vertex_locks.push(false)
  }
  let bvh = MeshletBvhBuilder::new()
  let all_groups : Array[MeshletTempGroup] = []
  let simplification_queue : Array[Int] = []
  let stuck : Array[MeshletTempGroup] = []
  for meshlet_id in 0..<meshlets.len() {
    simplification_queue.push(meshlet_id)
  }
  while !simplification_queue.is_empty() {
    let connected_meshlets_per_meshlet = meshlet_find_connected_meshlets(
      simplification_queue, meshlets, position_only_vertex_remap,
    )
    let graph = meshlet_build_group_partition_graph(
      simplification_queue, connected_meshlets_per_meshlet,
    )
    let partition_per_meshlet = meshlet_metis_partition_meshlets(graph)
    let groups = meshlet_groups_from_partitions(
      simplification_queue,
      cull_data,
      partition_per_meshlet,
      graph.partition_count,
    )
    meshlet_lock_group_borders(
      vertex_locks, groups, meshlets, position_only_vertex_remap,
    )
    let simplified : Array[MeshletLodSimplificationResult] = []
    for group in groups {
      let result = meshlet_simplify_group_with_processor(
        group, meshlets, cull_data, input, position_only_vertex_remap, vertex_locks,
      )
      simplified.push(result)
    }
    let result = meshlet_lod_iteration_apply_results(
      meshlets, cull_data, all_groups, simplification_queue, stuck, bvh, simplified,
    )
    ignore(result.first_group)
    ignore(result.passed_tris)
    ignore(result.stuck_tris)
    ignore(result.retried_stuck)
  }
  ignore(meshlet_lod_append_final_stuck_lod(all_groups, stuck, bvh))
  let built = bvh.build(meshlets, all_groups, cull_data)
  meshlet_finalize_bvh_build(input, built, vertex_position_quantization_factor~)
}
