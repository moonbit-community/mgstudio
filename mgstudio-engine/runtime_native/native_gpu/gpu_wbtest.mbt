// Copyright 2025 International Digital Economy Academy
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
test "native_gpu: interleaved 2d mesh csv keeps original vertex count" {
  let backend = GpuBackend::new()
  backend.meshes.val.clear()
  let vertices = [
    -1.0F,
    -1.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
    -1.0F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    0.0F,
    1.0F,
    0.0F,
    1.0F,
    0.5F,
    1.0F,
    0.0F,
    0.0F,
    1.0F,
    1.0F,
  ]
  let mesh_id = backend.create_mesh_triangles_xyuvrgba(vertices)
  let ok = mesh_id > 0 &&
    backend.meshes.val.length() == 1 &&
    backend.meshes.val[0].id == mesh_id &&
    backend.meshes.val[0].vertex_count.reinterpret_as_int() == 3 &&
    backend.meshes.val[0].vertex_stride_bytes == 32UL
  inspect(ok, content="true")
}

///|
test "native_gpu: mesh2d uniform slot pool grows per draw slot" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh_pipeline_rgba8(backend)
  let ok = ensure_mesh_uniform_slot(backend, 0) is Some(_) &&
    ensure_mesh_uniform_slot(backend, 2) is Some(_) &&
    backend.mesh_uniform_slots.length() == 3
  inspect(ok, content="true")
}

///|
test "native_gpu: mesh3d uniform slot pool grows per draw slot" {
  let backend = GpuBackend::new(assets_base="assets")
  ensure_mesh3d_pipeline_rgba8(backend, MESH3D_TOPOLOGY_TRIANGLE_LIST, 0)
  let ok = ensure_mesh3d_uniform_slot(backend, 0) is Some(_) &&
    ensure_mesh3d_uniform_slot(backend, 1) is Some(_) &&
    backend.mesh3d_uniform_slots.length() == 2
  inspect(ok, content="true")
}
