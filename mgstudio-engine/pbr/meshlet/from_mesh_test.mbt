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
test "pbr meshlet: conversion reports native processor availability" {
  inspect(meshlet_processor_available(), content="true")
  let error = meshlet_conversion_error_for_counts(
    10,
    10,
    MeshToMeshletMeshConversionConfig::MeshToMeshletMeshConversionConfig(),
  )
  inspect(error is None, content="true")
}

///|
test "pbr meshlet: input summary validation checks topology and attributes" {
  let config = MeshToMeshletMeshConversionConfig::MeshToMeshletMeshConversionConfig()
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
  let config = MeshToMeshletMeshConversionConfig::MeshToMeshletMeshConversionConfig()
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
fn meshlet_test_triangle_geometry() -> @mesh.Mesh3dGeometry {
  @mesh.Mesh3dGeometry::new(
    [
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(1.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
    ],
    Some([0, 1, 2]),
  ).with_normals(
    Some([
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
      @math.Vec3::new(0.0F, 0.0F, 1.0F),
    ]),
  )
}

///|
test "pbr meshlet: mesh input extraction mirrors required Bevy attributes" {
  let mesh = @mesh.Mesh::from_3d_geometry(meshlet_test_triangle_geometry())
  let input = meshlet_extract_mesh_input(mesh) catch {
    _ => abort("expected meshlet input extraction to pass")
  }
  inspect(input.vertices.length(), content="3")
  inspect(input.indices.length(), content="3")
  inspect(input.indices[0], content="0")
  inspect(input.indices[2], content="2")
  inspect(input.triangle_count, content="1")
  inspect(input.vertices[1].position.x, content="1")
  inspect(input.vertices[2].uv.y, content="1")
  let summary = input.summary()
  inspect(summary.vertex_attributes.length(), content="3")
  inspect(summary.vertex_attributes[0], content="POSITION")
  inspect(summary.vertex_attributes[2], content="UV_0")
}

///|
test "pbr meshlet: mesh input extraction rejects wrong topology, attributes, and missing indices" {
  let wrong_topology = @mesh.Mesh::from_3d_geometry(
    meshlet_test_triangle_geometry().with_topology(
      @mesh.Mesh3dPrimitiveTopology::LineList,
    ),
  )
  let wrong_topology_rejected = try {
    ignore(meshlet_extract_mesh_input(wrong_topology))
    false
  } catch {
    MeshToMeshletMeshConversionError::WrongMeshPrimitiveTopology => true
    _ => false
  }
  inspect(wrong_topology_rejected, content="true")
  let missing_indices = @mesh.Mesh::from_3d_geometry(
    meshlet_test_triangle_geometry().with_indices(None),
  )
  let missing_indices_rejected = try {
    ignore(meshlet_extract_mesh_input(missing_indices))
    false
  } catch {
    MeshToMeshletMeshConversionError::MeshMissingIndices => true
    _ => false
  }
  inspect(missing_indices_rejected, content="true")
  let extra_attribute = @mesh.Mesh::from_3d_geometry(
    meshlet_test_triangle_geometry().with_colors(
      Some([
        @math.Vec4::splat(1.0F),
        @math.Vec4::splat(1.0F),
        @math.Vec4::splat(1.0F),
      ]),
    ),
  )
  let extra_attribute_rejected = try {
    ignore(meshlet_extract_mesh_input(extra_attribute))
    false
  } catch {
    MeshToMeshletMeshConversionError::WrongMeshVertexAttributes(_) => true
    _ => false
  }
  inspect(extra_attribute_rejected, content="true")
}

///|
test "pbr meshlet: from_mesh validates mesh before running processor" {
  let wrong_topology = @mesh.Mesh::from_3d_geometry(
    meshlet_test_triangle_geometry().with_topology(
      @mesh.Mesh3dPrimitiveTopology::LineList,
    ),
  )
  let wrong_topology_rejected = try {
    ignore(MeshletMesh::from_mesh(wrong_topology))
    false
  } catch {
    MeshToMeshletMeshConversionError::WrongMeshPrimitiveTopology => true
    _ => false
  }
  inspect(wrong_topology_rejected, content="true")
  let mesh = @mesh.Mesh::from_3d_geometry(meshlet_test_triangle_geometry())
  let meshlet_mesh = MeshletMesh::from_mesh(mesh) catch {
    _ => abort("expected native meshlet processor to build a meshlet mesh")
  }
  inspect(meshlet_mesh.meshlet_count() > 0, content="true")
  inspect(meshlet_mesh.index_count() > 0, content="true")
  inspect(meshlet_mesh.bvh_depth > 0, content="true")
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
  inspect(data.vertex_positions[0], content="272629760")
  inspect(data.vertex_positions[1], content="8")
}
