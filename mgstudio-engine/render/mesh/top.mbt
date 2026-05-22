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
pub const RENDER_MESH3D_HOST_VERTEX_BASE_FLOAT_STRIDE : Int = 12

///|
pub const RENDER_MESH3D_HOST_VERTEX_SKINNED_FLOAT_STRIDE : Int = 20

///|
pub const RENDER_MESH3D_HOST_VERTEX_STRIDE_BYTES : Int = 80

///|
fn render_mesh_default_layout_ref() -> @asset_mesh.MeshVertexBufferLayoutRef {
  let layouts = @asset_mesh.MeshVertexBufferLayouts::MeshVertexBufferLayouts()
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
fn render_mesh3d_host_vertex_push_attribute(
  source_layout : @asset_mesh.MeshVertexBufferLayout,
  attribute : @asset_mesh.MeshVertexAttribute,
  offset : Int,
  format : @asset_mesh.MeshVertexFormat,
  shader_location : Int,
  attribute_ids : Array[@asset_mesh.MeshVertexAttributeId],
  attributes : Array[@asset_mesh.VertexAttribute],
) -> Unit {
  if source_layout.contains(attribute.id()) {
    attribute_ids.push(attribute.id())
    attributes.push(
      @asset_mesh.VertexAttribute::new(offset~, format~, shader_location~),
    )
  }
}

///|
pub fn render_mesh3d_host_vertex_buffer_layout(
  mesh_vertex_buffer_layouts : @asset_mesh.MeshVertexBufferLayouts,
  source_layout_ref : @asset_mesh.MeshVertexBufferLayoutRef,
) -> @asset_mesh.MeshVertexBufferLayoutRef {
  let source_layout = source_layout_ref.layout()
  let attribute_ids : Array[@asset_mesh.MeshVertexAttributeId] = []
  let attributes : Array[@asset_mesh.VertexAttribute] = []
  render_mesh3d_host_vertex_push_attribute(
    source_layout,
    @asset_mesh.MeshVertexAttribute::position(),
    0,
    @asset_mesh.MeshVertexFormat::Float32x3,
    0,
    attribute_ids,
    attributes,
  )
  render_mesh3d_host_vertex_push_attribute(
    source_layout,
    @asset_mesh.MeshVertexAttribute::normal(),
    12,
    @asset_mesh.MeshVertexFormat::Float32x3,
    1,
    attribute_ids,
    attributes,
  )
  render_mesh3d_host_vertex_push_attribute(
    source_layout,
    @asset_mesh.MeshVertexAttribute::uv_0(),
    24,
    @asset_mesh.MeshVertexFormat::Float32x2,
    2,
    attribute_ids,
    attributes,
  )
  render_mesh3d_host_vertex_push_attribute(
    source_layout,
    @asset_mesh.MeshVertexAttribute::color(),
    32,
    @asset_mesh.MeshVertexFormat::Float32x4,
    5,
    attribute_ids,
    attributes,
  )
  render_mesh3d_host_vertex_push_attribute(
    source_layout,
    @asset_mesh.MeshVertexAttribute::joint_index(),
    48,
    @asset_mesh.MeshVertexFormat::Uint32x4,
    6,
    attribute_ids,
    attributes,
  )
  render_mesh3d_host_vertex_push_attribute(
    source_layout,
    @asset_mesh.MeshVertexAttribute::joint_weight(),
    64,
    @asset_mesh.MeshVertexFormat::Float32x4,
    7,
    attribute_ids,
    attributes,
  )
  mesh_vertex_buffer_layouts.insert(
    @asset_mesh.MeshVertexBufferLayout::new(
      attribute_ids~,
      layout=@asset_mesh.VertexBufferLayout::new(
        array_stride=RENDER_MESH3D_HOST_VERTEX_STRIDE_BYTES,
        step_mode=@asset_mesh.MeshVertexStepMode::Vertex,
        attributes~,
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
  let base_key_bits = @asset_mesh.BaseMeshPipelineKey::from_primitive_topology(
    primitive_topology,
  )
  let key_bits = if mesh.has_morph_targets() {
    @asset_mesh.BaseMeshPipelineKey::new(
      base_key_bits.bits() |
      @asset_mesh.BaseMeshPipelineKey::morph_targets().bits(),
    )
  } else {
    base_key_bits
  }
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
pub fn RenderMesh::host_vertex_buffer_layout(
  self : RenderMesh,
  mesh_vertex_buffer_layouts : @asset_mesh.MeshVertexBufferLayouts,
) -> @asset_mesh.MeshVertexBufferLayoutRef {
  render_mesh3d_host_vertex_buffer_layout(
    mesh_vertex_buffer_layouts,
    self.layout,
  )
}

///|
pub fn RenderMesh::primitive_topology(
  self : RenderMesh,
) -> @asset_mesh.Mesh3dPrimitiveTopology {
  self.key_bits.primitive_topology()
}
