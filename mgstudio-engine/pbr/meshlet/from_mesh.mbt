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
