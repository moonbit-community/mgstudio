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
  aabb_center : @math.Vec3
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
  aabb_center? : @math.Vec3 = @math.Vec3::zero(),
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
  RenderMesh::{
    vertex_count,
    aabb_center,
    buffer_info,
    dimension,
    key_bits,
    layout,
  }
}

///|
fn render_mesh_aabb_center(mesh : @asset_mesh.Mesh) -> @math.Vec3 {
  match mesh.as_3d_geometry() {
    Some(geometry) => {
      let vertex_count = geometry.vertex_count()
      if vertex_count == 0 {
        return @math.Vec3::zero()
      }
      guard geometry.vertex_position(0) is Some(first) else {
        return @math.Vec3::zero()
      }
      let mut min = first
      let mut max = first
      for index in 1..<vertex_count {
        guard geometry.vertex_position(index) is Some(position) else {
          continue
        }
        min = min.min(position)
        max = max.max(position)
      }
      min.add(max).div_scalar(2.0F)
    }
    None =>
      match mesh.as_2d_geometry() {
        Some(geometry) => {
          let vertex_count = geometry.vertex_count()
          if vertex_count == 0 {
            return @math.Vec3::zero()
          }
          guard geometry.vertex_position(0) is Some(first) else {
            return @math.Vec3::zero()
          }
          let mut min_x = first.x
          let mut min_y = first.y
          let mut max_x = first.x
          let mut max_y = first.y
          for index in 1..<vertex_count {
            guard geometry.vertex_position(index) is Some(position) else {
              continue
            }
            if position.x < min_x {
              min_x = position.x
            }
            if position.y < min_y {
              min_y = position.y
            }
            if position.x > max_x {
              max_x = position.x
            }
            if position.y > max_y {
              max_y = position.y
            }
          }
          @math.Vec3::new((min_x + max_x) / 2.0F, (min_y + max_y) / 2.0F, 0.0F)
        }
        None => @math.Vec3::zero()
      }
  }
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
      let index_format = render_mesh_index_format_from_mesh(mesh, indices)
      RenderMeshBufferInfo::Indexed(indices.length(), index_format)
    }
    None => RenderMeshBufferInfo::NonIndexed
  }
  let primitive_topology = match mesh.primitive_topology() {
    Some(topology) => topology
    None => @asset_mesh.Mesh3dPrimitiveTopology::TriangleList
  }
  let strip_index_format = match buffer_info {
    Indexed(_, Uint16) => Some(@asset_mesh.Mesh3dIndexFormat::Uint16)
    Indexed(_, Uint32) => Some(@asset_mesh.Mesh3dIndexFormat::Uint32)
    NonIndexed => None
  }
  let base_key_bits = @asset_mesh.BaseMeshPipelineKey::from_primitive_topology_and_strip_index(
    primitive_topology, strip_index_format,
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
  RenderMesh::{
    vertex_count,
    aabb_center: render_mesh_aabb_center(mesh),
    buffer_info,
    dimension,
    key_bits,
    layout,
  }
}

///|
// Bevy source: `bevy_render/src/mesh/mod.rs::RenderAsset for RenderMesh::prepare_asset`.
pub fn RenderMesh::prepare_asset(
  mesh : @asset_mesh.Mesh,
  mesh_vertex_buffer_layouts : @asset_mesh.MeshVertexBufferLayouts,
  dimension? : RenderMeshDimension = Dim3,
) -> RenderMesh {
  RenderMesh::from_mesh(mesh, mesh_vertex_buffer_layouts, dimension~)
}

///|
fn render_mesh_index_format_from_mesh(
  mesh : @asset_mesh.Mesh,
  indices : Array[Int],
) -> RenderMeshIndexFormat {
  match mesh.index_format() {
    Some(Uint16) => RenderMeshIndexFormat::Uint16
    Some(Uint32) => RenderMeshIndexFormat::Uint32
    None =>
      if render_mesh_indices_use_u32(indices) {
        RenderMeshIndexFormat::Uint32
      } else {
        RenderMeshIndexFormat::Uint16
      }
  }
}

///|
fn render_mesh_indices_use_u32(indices : Array[Int]) -> Bool {
  for index in indices {
    if index >= 0xffff {
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
pub fn RenderMesh::aabb_center(self : RenderMesh) -> @math.Vec3 {
  self.aabb_center
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
pub fn RenderMesh::index_format(
  self : RenderMesh,
) -> @asset_mesh.Mesh3dIndexFormat? {
  match self.buffer_info {
    Indexed(_, Uint16) => Some(@asset_mesh.Mesh3dIndexFormat::Uint16)
    Indexed(_, Uint32) => Some(@asset_mesh.Mesh3dIndexFormat::Uint32)
    NonIndexed => None
  }
}

///|
pub fn RenderMesh::wireframe_index_count(self : RenderMesh) -> Int {
  match self.buffer_info {
    Indexed(count, _) => count
    NonIndexed => self.vertex_count
  }
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

///|
pub struct RenderMeshAssets {
  assets : Map[Int, RenderMesh]
}

///|
pub fn RenderMeshAssets::RenderMeshAssets() -> RenderMeshAssets {
  RenderMeshAssets::{ assets: Map([]) }
}

///|
pub let render_mesh_assets_resource_key : @ecs.ResourceKey[RenderMeshAssets] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderAssets<RenderMesh>",
)

///|
pub impl @app.Resource for RenderMeshAssets with fn resource() {
  render_mesh_assets_resource_key
}

///|
pub fn RenderMeshAssets::clear(self : RenderMeshAssets) -> Unit {
  self.assets.clear()
}

///|
pub fn RenderMeshAssets::insert(
  self : RenderMeshAssets,
  mesh_asset_id : Int,
  render_mesh : RenderMesh,
) -> Unit {
  self.assets.set(mesh_asset_id, render_mesh)
}

///|
pub struct ExtractedRenderMeshAsset {
  mesh_asset_id : Int
  mesh : @asset_mesh.Mesh
}

///|
pub struct PreparedRenderMeshAsset {
  mesh_asset_id : Int
  render_mesh : RenderMesh
}

///|
pub fn ExtractedRenderMeshAsset::new(
  mesh_asset_id : Int,
  mesh : @asset_mesh.Mesh,
) -> ExtractedRenderMeshAsset {
  ExtractedRenderMeshAsset::{ mesh_asset_id, mesh }
}

///|
pub fn ExtractedRenderMeshAsset::mesh_asset_id(
  self : ExtractedRenderMeshAsset,
) -> Int {
  self.mesh_asset_id
}

///|
pub fn ExtractedRenderMeshAsset::mesh(
  self : ExtractedRenderMeshAsset,
) -> @asset_mesh.Mesh {
  self.mesh
}

///|
pub fn PreparedRenderMeshAsset::new(
  mesh_asset_id : Int,
  render_mesh : RenderMesh,
) -> PreparedRenderMeshAsset {
  PreparedRenderMeshAsset::{ mesh_asset_id, render_mesh }
}

///|
pub fn PreparedRenderMeshAsset::mesh_asset_id(
  self : PreparedRenderMeshAsset,
) -> Int {
  self.mesh_asset_id
}

///|
pub fn PreparedRenderMeshAsset::render_mesh(
  self : PreparedRenderMeshAsset,
) -> RenderMesh {
  self.render_mesh
}

///|
pub fn prepare_render_mesh_assets(
  extracted_assets : Array[ExtractedRenderMeshAsset],
  mesh_vertex_buffer_layouts : @asset_mesh.MeshVertexBufferLayouts,
  dimension? : RenderMeshDimension = Dim3,
) -> Array[PreparedRenderMeshAsset] {
  let prepared_assets : Array[PreparedRenderMeshAsset] = []
  for extracted_asset in extracted_assets {
    prepared_assets.push(
      PreparedRenderMeshAsset::new(
        extracted_asset.mesh_asset_id(),
        RenderMesh::prepare_asset(
          extracted_asset.mesh(),
          mesh_vertex_buffer_layouts,
          dimension~,
        ),
      ),
    )
  }
  prepared_assets
}

///|
pub fn RenderMeshAssets::insert_prepared_assets(
  self : RenderMeshAssets,
  prepared_assets : Array[PreparedRenderMeshAsset],
) -> Unit {
  for prepared_asset in prepared_assets {
    self.insert(prepared_asset.mesh_asset_id(), prepared_asset.render_mesh())
  }
}

///|
// Bevy source: `bevy_render/src/render_asset.rs::prepare_assets<RenderMesh>`.
pub fn RenderMeshAssets::prepare_assets(
  self : RenderMeshAssets,
  extracted_assets : Array[ExtractedRenderMeshAsset],
  mesh_vertex_buffer_layouts : @asset_mesh.MeshVertexBufferLayouts,
  dimension? : RenderMeshDimension = Dim3,
) -> Unit {
  self.insert_prepared_assets(
    prepare_render_mesh_assets(
      extracted_assets,
      mesh_vertex_buffer_layouts,
      dimension~,
    ),
  )
}

///|
pub fn RenderMeshAssets::remove(
  self : RenderMeshAssets,
  mesh_asset_id : Int,
) -> RenderMesh? {
  let value = self.assets.get(mesh_asset_id)
  self.assets.remove(mesh_asset_id)
  value
}

///|
pub fn RenderMeshAssets::get(
  self : RenderMeshAssets,
  mesh_asset_id : Int,
) -> RenderMesh? {
  self.assets.get(mesh_asset_id)
}

///|
pub fn RenderMeshAssets::len(self : RenderMeshAssets) -> Int {
  self.assets.length()
}
