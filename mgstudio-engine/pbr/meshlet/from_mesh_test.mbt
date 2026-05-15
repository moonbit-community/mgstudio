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
test "pbr meshlet: conversion reports runtime unavailable first" {
  let error = meshlet_conversion_error_for_counts(
    10,
    10,
    MeshToMeshletMeshConversionConfig::default(),
  )
  inspect(
    error is Some(MeshToMeshletMeshConversionError::RuntimeUnavailable),
    content="true",
  )
}

///|
test "pbr meshlet: input summary validation checks topology and attributes" {
  let config = MeshToMeshletMeshConversionConfig::default()
  let wrong_topology = MeshToMeshletInputMeshSummary::new(
    primitive_topology="TriangleStrip",
    vertex_attributes=meshlet_required_vertex_attributes(),
    has_indices=true,
    vertex_count=4,
    triangle_count=2,
  )
  inspect(
    meshlet_validate_input_mesh_summary(wrong_topology, config, true)
    is Some(MeshToMeshletMeshConversionError::WrongMeshPrimitiveTopology),
    content="true",
  )
  let wrong_attributes = MeshToMeshletInputMeshSummary::new(
    primitive_topology="TriangleList",
    vertex_attributes=["POSITION", "UV_0"],
    has_indices=true,
    vertex_count=4,
    triangle_count=2,
  )
  inspect(
    meshlet_validate_input_mesh_summary(wrong_attributes, config, true)
    is Some(MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(_)),
    content="true",
  )
}

///|
test "pbr meshlet: input summary validation checks indices and limits" {
  let config = MeshToMeshletMeshConversionConfig::default()
  let missing_indices = MeshToMeshletInputMeshSummary::new(
    primitive_topology="TriangleList",
    vertex_attributes=meshlet_required_vertex_attributes(),
    has_indices=false,
    vertex_count=4,
    triangle_count=2,
  )
  inspect(
    meshlet_validate_input_mesh_summary(missing_indices, config, true)
    is Some(MeshToMeshletMeshConversionError::MeshMissingIndices),
    content="true",
  )
  let over_limit = MeshToMeshletInputMeshSummary::new(
    primitive_topology="TriangleList",
    vertex_attributes=meshlet_required_vertex_attributes(),
    has_indices=true,
    vertex_count=65_536,
    triangle_count=2,
  )
  inspect(
    meshlet_validate_input_mesh_summary(over_limit, config, true)
    is Some(MeshToMeshletMeshConversionError::TooManyVertices),
    content="true",
  )
}

///|
test "pbr meshlet: octahedral normals and UVs are compressed per meshlet" {
  let data = meshlet_build_compressed_vertex_data(
    [
      MeshletSourceVertex::new(
        position=@math.Vec3::new(0.0F, 0.0F, 0.0F),
        normal=@math.Vec3::new(0.0F, 0.0F, 1.0F),
        uv=@math.Vec2::new(0.25F, 0.75F),
      ),
      MeshletSourceVertex::new(
        position=@math.Vec3::new(0.0F, 0.0F, 0.0F),
        normal=@math.Vec3::new(1.0F, 0.0F, 0.0F),
        uv=@math.Vec2::new(0.5F, 0.125F),
      ),
    ],
    start_index_id=12,
    triangle_count=1,
  )
  inspect(data.vertex_normals.length(), content="2")
  inspect(data.vertex_normals[0], content="0")
  inspect(data.vertex_normals[1], content="32767")
  inspect(data.vertex_uvs.length(), content="2")
  inspect(data.vertex_uvs[0].x, content="0.25")
  inspect(data.vertex_uvs[1].y, content="0.125")
  inspect(data.meshlet.start_index_id, content="12")
  inspect(data.meshlet.triangle_count, content="1")
}

///|
test "pbr meshlet: quantized positions are packed as LSB-first u32 words" {
  let data = meshlet_build_compressed_vertex_data(
    [
      MeshletSourceVertex::new(
        position=@math.Vec3::new(0.0F, 0.0F, 0.0F),
        normal=@math.Vec3::new(0.0F, 0.0F, 1.0F),
        uv=@math.Vec2::zero(),
      ),
      MeshletSourceVertex::new(
        position=@math.Vec3::new(0.01F, 0.02F, 0.04F),
        normal=@math.Vec3::new(0.0F, 1.0F, 0.0F),
        uv=@math.Vec2::zero(),
      ),
    ],
    start_index_id=0,
    triangle_count=1,
  )
  inspect(data.meshlet.bits_per_vertex_position_channel_x, content="5")
  inspect(data.meshlet.bits_per_vertex_position_channel_y, content="6")
  inspect(data.meshlet.bits_per_vertex_position_channel_z, content="7")
  inspect(data.meshlet.min_vertex_position_channel_x, content="0")
  inspect(data.vertex_position_bit_len, content="36")
  inspect(data.vertex_positions.length(), content="2")
  inspect(data.vertex_positions[0], content="8389120")
  inspect(data.vertex_positions[1], content="2")
}
