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
/// Shared mesh lookup and index-buffer binding helpers.
///
/// Split from gpu_postprocess2d.mbt so bloom no longer owns generic mesh access.

///|
fn find_mesh(backend : GpuBackend, id : Int) -> GpuMeshInfo? {
  for m in backend.meshes {
    if m.id == id {
      return Some(m)
    }
  }
  None
}

///|
fn find_mesh_index(backend : GpuBackend, id : Int) -> Int? {
  for i in 0..<backend.meshes.length() {
    if backend.meshes[i].id == id {
      return Some(i)
    }
  }
  None
}

///|
fn gpu_mesh_bind_index_buffer(
  pass : @wgpu.RenderPass,
  mesh : GpuMeshInfo,
) -> Unit {
  let index_bytes = mesh.index_count.reinterpret_as_int().to_uint64() *
    mesh.index_stride_bytes
  if mesh.uses_u32_indices {
    pass.set_index_buffer_u32(mesh.index_buf, 0UL, index_bytes)
  } else {
    pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  }
}
