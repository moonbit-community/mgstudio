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
  let config = MeshToMeshletMeshConversionConfig::{
    max_vertices: 8,
    max_triangles: 8,
  }
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
    vertex_count=9,
    triangle_count=2,
  )
  inspect(
    meshlet_validate_input_mesh_summary(over_limit, config, true)
    is Some(MeshToMeshletMeshConversionError::TooManyVertices),
    content="true",
  )
}
