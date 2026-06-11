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
pub struct Wireframe3dThinImmediates {
  color : @color.Color
}

///|
pub fn Wireframe3dThinImmediates::from_material(
  material : RenderWireframeMaterial,
) -> Wireframe3dThinImmediates {
  Wireframe3dThinImmediates::{ color: material.color }
}

///|
pub fn Wireframe3dThinImmediates::color(
  self : Wireframe3dThinImmediates,
) -> @color.Color {
  self.color
}

///|
pub fn Wireframe3dThinImmediates::float_count(
  self : Wireframe3dThinImmediates,
) -> Int {
  ignore(self)
  4
}

///|
pub suberror WireframeRenderCommandError {
  NoWireframeMaterialFoundForEntity
}

///|
pub const WIREFRAME_INDIRECT_PARAMETERS_NON_INDEXED_SIZE_BYTES : Int = 16

///|
pub const WIREFRAME_INDIRECT_BATCH_SET_SIZE_BYTES : Int = 8

///|
fn wireframe_render_command_material(
  item : Wireframe3d,
  wireframe_instances : RenderWireframeInstances,
  wireframe_assets : RenderWireframeAssets,
) -> RenderWireframeMaterial raise WireframeRenderCommandError {
  guard wireframe_instances.get(item.main_entity()) is Some(material_asset_id) else {
    raise WireframeRenderCommandError::NoWireframeMaterialFoundForEntity
  }
  guard wireframe_assets.get(material_asset_id) is Some(material) else {
    raise WireframeRenderCommandError::NoWireframeMaterialFoundForEntity
  }
  material
}

///|
pub fn set_wireframe_3d_thin_immediates(
  item : Wireframe3d,
  wireframe_instances : RenderWireframeInstances,
  wireframe_assets : RenderWireframeAssets,
) -> Wireframe3dThinImmediates raise WireframeRenderCommandError {
  Wireframe3dThinImmediates::from_material(
    wireframe_render_command_material(
      item, wireframe_instances, wireframe_assets,
    ),
  )
}

///|
pub struct Wireframe3dWideImmediates {
  color : @color.Color
  line_width : Float
  smoothing : Float
}

///|
pub fn Wireframe3dWideImmediates::from_material(
  material : RenderWireframeMaterial,
) -> Wireframe3dWideImmediates {
  Wireframe3dWideImmediates::{
    color: material.color,
    line_width: material.line_width,
    smoothing: if material.line_width <= 1.0F {
      0.5F
    } else {
      1.0F
    },
  }
}

///|
pub fn Wireframe3dWideImmediates::color(
  self : Wireframe3dWideImmediates,
) -> @color.Color {
  self.color
}

///|
pub fn Wireframe3dWideImmediates::line_width(
  self : Wireframe3dWideImmediates,
) -> Float {
  self.line_width
}

///|
pub fn Wireframe3dWideImmediates::smoothing(
  self : Wireframe3dWideImmediates,
) -> Float {
  self.smoothing
}

///|
pub fn Wireframe3dWideImmediates::float_count(
  self : Wireframe3dWideImmediates,
) -> Int {
  ignore(self)
  8
}

///|
pub fn set_wireframe_3d_wide_immediates(
  item : Wireframe3d,
  wireframe_instances : RenderWireframeInstances,
  wireframe_assets : RenderWireframeAssets,
) -> Wireframe3dWideImmediates raise WireframeRenderCommandError {
  Wireframe3dWideImmediates::from_material(
    wireframe_render_command_material(
      item, wireframe_instances, wireframe_assets,
    ),
  )
}

///|
pub struct WireframeVertexPullParams {
  index_offset : UInt
  vertex_stride_u32s : UInt
  position_offset_u32s : UInt
} derive(Eq, Debug)

///|
pub fn WireframeVertexPullParams::new(
  index_offset : UInt,
  vertex_stride_u32s : UInt,
  position_offset_u32s : UInt,
) -> WireframeVertexPullParams {
  WireframeVertexPullParams::{
    index_offset,
    vertex_stride_u32s,
    position_offset_u32s,
  }
}

///|
pub fn WireframeVertexPullParams::index_offset(
  self : WireframeVertexPullParams,
) -> UInt {
  self.index_offset
}

///|
pub fn WireframeVertexPullParams::vertex_stride_u32s(
  self : WireframeVertexPullParams,
) -> UInt {
  self.vertex_stride_u32s
}

///|
pub fn WireframeVertexPullParams::position_offset_u32s(
  self : WireframeVertexPullParams,
) -> UInt {
  self.position_offset_u32s
}

///|
pub fn set_wireframe_3d_wide_bind_group_dynamic_offset(
  item : Wireframe3d,
  render_mesh_instances : RenderMeshInstances,
  wide_bind_groups : WireframeWideBindGroups,
) -> Int? {
  guard render_mesh_instances.render_mesh_queue_data(item.main_entity())
    is Some(mesh_instance) else {
    return None
  }
  wide_bind_groups.dynamic_offset(mesh_instance.mesh_asset_id())
}

///|
pub struct DrawWireframeMeshPulledDirectRange {
  first_vertex : Int
  vertex_end : Int
  batch_start : Int
  batch_end : Int
} derive(Eq, Debug)

///|
pub fn DrawWireframeMeshPulledDirectRange::new(
  first_vertex : Int,
  vertex_end : Int,
  batch_start : Int,
  batch_end : Int,
) -> DrawWireframeMeshPulledDirectRange {
  DrawWireframeMeshPulledDirectRange::{
    first_vertex,
    vertex_end,
    batch_start,
    batch_end,
  }
}

///|
pub fn DrawWireframeMeshPulledDirectRange::first_vertex(
  self : DrawWireframeMeshPulledDirectRange,
) -> Int {
  self.first_vertex
}

///|
pub fn DrawWireframeMeshPulledDirectRange::vertex_end(
  self : DrawWireframeMeshPulledDirectRange,
) -> Int {
  self.vertex_end
}

///|
pub fn DrawWireframeMeshPulledDirectRange::batch_start(
  self : DrawWireframeMeshPulledDirectRange,
) -> Int {
  self.batch_start
}

///|
pub fn DrawWireframeMeshPulledDirectRange::batch_end(
  self : DrawWireframeMeshPulledDirectRange,
) -> Int {
  self.batch_end
}

///|
pub fn draw_wireframe_mesh_pulled_direct_range(
  item : Wireframe3d,
  render_mesh_instances : RenderMeshInstances,
  render_meshes : @render_mesh.RenderMeshAssets,
  mesh_allocator : @render_mesh.MeshAllocator,
) -> DrawWireframeMeshPulledDirectRange? {
  guard render_mesh_instances.mesh_asset_id(item.main_entity())
    is Some(mesh_asset_id) else {
    return None
  }
  guard render_meshes.get(mesh_asset_id) is Some(render_mesh) else {
    return None
  }
  guard mesh_allocator.mesh_vertex_slice(mesh_asset_id) is Some(vertex_slice) else {
    return None
  }
  let first_vertex = vertex_slice.start()
  let index_count = render_mesh.wireframe_index_count()
  let batch_range = item.batch_range()
  Some(
    DrawWireframeMeshPulledDirectRange::new(
      first_vertex,
      first_vertex + index_count,
      batch_range.start(),
      batch_range.end(),
    ),
  )
}

///|
pub struct DrawWireframeMeshPulledIndirectPlan {
  indirect_parameters_offset : Int
  indirect_parameters_count : Int
  batch_set_count_offset : Int?
} derive(Eq, Debug)

///|
pub fn DrawWireframeMeshPulledIndirectPlan::new(
  indirect_parameters_offset : Int,
  indirect_parameters_count : Int,
  batch_set_count_offset? : Int? = None,
) -> DrawWireframeMeshPulledIndirectPlan {
  DrawWireframeMeshPulledIndirectPlan::{
    indirect_parameters_offset,
    indirect_parameters_count,
    batch_set_count_offset,
  }
}

///|
pub fn DrawWireframeMeshPulledIndirectPlan::indirect_parameters_offset(
  self : DrawWireframeMeshPulledIndirectPlan,
) -> Int {
  self.indirect_parameters_offset
}

///|
pub fn DrawWireframeMeshPulledIndirectPlan::indirect_parameters_count(
  self : DrawWireframeMeshPulledIndirectPlan,
) -> Int {
  self.indirect_parameters_count
}

///|
pub fn DrawWireframeMeshPulledIndirectPlan::batch_set_count_offset(
  self : DrawWireframeMeshPulledIndirectPlan,
) -> Int? {
  self.batch_set_count_offset
}

///|
pub fn draw_wireframe_mesh_pulled_indirect_plan(
  item : Wireframe3d,
) -> DrawWireframeMeshPulledIndirectPlan? {
  guard item.extra_index().indirect_parameters_range()
    is Some((range_start, range_end, batch_set_index)) else {
    return None
  }
  let batch_set_count_offset = match batch_set_index {
    Some(index) => Some(index * WIREFRAME_INDIRECT_BATCH_SET_SIZE_BYTES)
    None => None
  }
  Some(
    DrawWireframeMeshPulledIndirectPlan::new(
      range_start * WIREFRAME_INDIRECT_PARAMETERS_NON_INDEXED_SIZE_BYTES,
      range_end - range_start,
      batch_set_count_offset~,
    ),
  )
}
