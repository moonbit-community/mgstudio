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
pub fn host_gpu_prepare_mesh3d_skin_binding(
  key_hi~ : Int,
  key_lo~ : Int,
  skinning_matrices~ : Array[Float],
) -> Unit {
  @renderer.prepare_mesh3d_skin_binding(key_hi~, key_lo~, skinning_matrices~)
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
