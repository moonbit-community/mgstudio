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
// Bevy source: `bevy/crates/bevy_render/src/mesh/mod.rs`.

///|
pub(all) enum RenderMeshDimension {
  Dim2
  Dim3
} derive(Eq, Debug)

///|
pub(all) enum RenderMeshIndexFormat {
  Uint16
  Uint32
} derive(Eq, Debug)

///|
pub(all) enum RenderMeshBufferInfo {
  Indexed(Int, RenderMeshIndexFormat)
  NonIndexed
} derive(Eq, Debug)

///|
pub struct RenderMesh {
  vertex_count : Int
  buffer_info : RenderMeshBufferInfo
  dimension : RenderMeshDimension
  key_bits : @asset_mesh.BaseMeshPipelineKey
  layout : @asset_mesh.MeshVertexBufferLayoutRef
}

///|
fn render_mesh_default_layout_ref() -> @asset_mesh.MeshVertexBufferLayoutRef {
  let layouts = @asset_mesh.MeshVertexBufferLayouts::default()
  layouts.insert(
    @asset_mesh.MeshVertexBufferLayout::new(
      attribute_ids=[],
      layout=@asset_mesh.VertexBufferLayout::new(
        array_stride=0,
        step_mode=@asset_mesh.MeshVertexStepMode::Vertex,
        attributes=[],
      ),
    ),
  )
}

///|
pub fn RenderMesh::new(
  vertex_count~ : Int,
  indexed? : Bool = false,
  index_count? : Int = 0,
  index_format? : RenderMeshIndexFormat = Uint32,
  dimension? : RenderMeshDimension = Dim3,
  key_bits? : @asset_mesh.BaseMeshPipelineKey = @asset_mesh.BaseMeshPipelineKey::from_primitive_topology(
    @asset_mesh.Mesh3dPrimitiveTopology::TriangleList,
  ),
  layout? : @asset_mesh.MeshVertexBufferLayoutRef = render_mesh_default_layout_ref(),
) -> RenderMesh {
  let buffer_info = if indexed {
    Indexed(index_count, index_format)
  } else {
    NonIndexed
  }
  RenderMesh::{ vertex_count, buffer_info, dimension, key_bits, layout }
}

///|
pub fn RenderMesh::from_mesh(
  mesh : @asset_mesh.Mesh,
  mesh_vertex_buffer_layouts : @asset_mesh.MeshVertexBufferLayouts,
  dimension? : RenderMeshDimension = Dim3,
) -> RenderMesh {
  let vertex_count = mesh.count_vertices()
  let buffer_info = match mesh.indices() {
    Some(indices) => {
      let index_format = if render_mesh_indices_use_u32(indices) {
        RenderMeshIndexFormat::Uint32
      } else {
        RenderMeshIndexFormat::Uint16
      }
      RenderMeshBufferInfo::Indexed(indices.length(), index_format)
    }
    None => RenderMeshBufferInfo::NonIndexed
  }
  let primitive_topology = match mesh.primitive_topology() {
    Some(topology) => topology
    None => @asset_mesh.Mesh3dPrimitiveTopology::TriangleList
  }
  let key_bits = @asset_mesh.BaseMeshPipelineKey::from_primitive_topology(
    primitive_topology,
  )
  let layout = mesh.get_mesh_vertex_buffer_layout(mesh_vertex_buffer_layouts)
  RenderMesh::{ vertex_count, buffer_info, dimension, key_bits, layout }
}

///|
fn render_mesh_indices_use_u32(indices : Array[Int]) -> Bool {
  for index in indices {
    if index > 0xffff {
      return true
    }
  }
  false
}

///|
pub fn RenderMesh::vertex_count(self : RenderMesh) -> Int {
  self.vertex_count
}

///|
pub fn RenderMesh::dimension(self : RenderMesh) -> RenderMeshDimension {
  self.dimension
}

///|
pub fn RenderMesh::indexed(self : RenderMesh) -> Bool {
  match self.buffer_info {
    Indexed(_, _) => true
    NonIndexed => false
  }
}

///|
pub fn RenderMesh::buffer_info(self : RenderMesh) -> RenderMeshBufferInfo {
  self.buffer_info
}

///|
pub fn RenderMesh::key_bits(
  self : RenderMesh,
) -> @asset_mesh.BaseMeshPipelineKey {
  self.key_bits
}

///|
pub fn RenderMesh::layout(
  self : RenderMesh,
) -> @asset_mesh.MeshVertexBufferLayoutRef {
  self.layout
}

///|
pub fn RenderMesh::primitive_topology(
  self : RenderMesh,
) -> @asset_mesh.Mesh3dPrimitiveTopology {
  self.key_bits.primitive_topology()
}
