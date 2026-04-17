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
pub(all) enum RenderMeshBufferInfo {
  Indexed(Int)
  NonIndexed
} derive(Eq, Debug)

///|
pub struct RenderMesh {
  vertex_count : Int
  buffer_info : RenderMeshBufferInfo
  dimension : RenderMeshDimension
} derive(Eq, Debug)

///|
pub fn RenderMesh::new(
  vertex_count~ : Int,
  indexed? : Bool = false,
  index_count? : Int = 0,
  dimension? : RenderMeshDimension = Dim3,
) -> RenderMesh {
  let buffer_info = if indexed { Indexed(index_count) } else { NonIndexed }
  RenderMesh::{ vertex_count, buffer_info, dimension }
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
    Indexed(_) => true
    NonIndexed => false
  }
}

///|
pub fn RenderMesh::buffer_info(self : RenderMesh) -> RenderMeshBufferInfo {
  self.buffer_info
}

///|
pub fn host_gpu_prepare_mesh3d_skin_bindings(
  skinning_rows~ : Array[Float],
) -> Unit {
  @renderer.prepare_mesh3d_skin_bindings(skinning_rows~)
}

///|
pub fn host_gpu_create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  @renderer.create_mesh_capsule(radius~, half_length~, segments~)
}

///|
pub fn host_gpu_create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  @renderer.create_mesh_rectangle(width~, height~)
}

///|
pub fn host_gpu_create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  @renderer.create_mesh_triangles(vertices_xy_csv~)
}

///|
pub fn host_gpu_create_mesh_triangles_xyuvrgba(
  vertices_xyuvrgba_csv~ : String,
) -> Int {
  @renderer.create_mesh_triangles_xyuvrgba(vertices_xyuvrgba_csv~)
}

///|
pub fn host_gpu_create_mesh_triangles3d(
  vertices_xyzuvrgba_csv~ : String,
) -> Int {
  host_gpu_create_mesh3d(vertices_xyzuvrgba_csv~, primitive_topology=0)
}

///|
pub fn host_gpu_create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  @renderer.create_mesh3d(vertices_xyzuvrgba_csv~, primitive_topology~)
}

///|
pub fn host_gpu_create_mesh3d_xyznuvrgba(
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Int {
  @renderer.create_mesh3d_xyznuvrgba(vertices_xyznuvrgba~, primitive_topology~)
}

///|
pub fn host_gpu_update_mesh3d_xyznuvrgba(
  mesh_id~ : Int,
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Bool {
  @renderer.update_mesh3d_xyznuvrgba(
    mesh_id~,
    vertices_xyznuvrgba~,
    primitive_topology~,
  )
}
