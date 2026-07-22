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
fn mesh3d_allocator_buffer_used_by_meshes(
  meshes : Array[GpuMeshInfo],
  slab_id : Int,
  usage_kind : Int,
) -> Bool {
  for mesh in meshes {
    if usage_kind == 0 && mesh.vertex_slab_id == slab_id {
      return true
    }
    if usage_kind == 1 && mesh.index_slab_id == slab_id {
      return true
    }
  }
  false
}

///|
fn GpuBackend::delete_unused_mesh3d_allocator_buffers(
  self : GpuBackend,
) -> Unit {
  let mut index = 0
  while index < self.mesh_allocator_buffers.length() {
    let allocator_buffer = self.mesh_allocator_buffers[index]
    if mesh3d_allocator_buffer_used_by_meshes(
        self.meshes,
        allocator_buffer.slab_id,
        allocator_buffer.usage_kind,
      ) {
      index = index + 1
    } else {
      let removed = self.mesh_allocator_buffers.remove(index)
      removed.buffer.release()
    }
  }
}

///|
fn GpuBackend::delete_mesh(self : GpuBackend, mesh_id : Int) -> Bool {
  guard find_mesh_index(self, mesh_id) is Some(mesh_index) else { return false }
  let mesh = self.meshes[mesh_index]
  ignore(self.meshes.remove(mesh_index))
  if mesh.vertex_slab_id >= 0 || mesh.index_slab_id >= 0 {
    self.mesh_allocator.free_mesh(mesh_id)
    self.delete_unused_mesh3d_allocator_buffers()
    if mesh.index_slab_id < 0 {
      mesh.index_buf.release()
    }
  } else {
    mesh.vertex_buf.release()
    mesh.index_buf.release()
  }
  true
}

///|
pub struct HostGpuMeshInfo {
  id : Int
  index_count : Int
  vertex_count : Int
  index_start : Int
  vertex_start : Int
  index_slab_id : Int
  vertex_slab_id : Int
  primitive_topology : UInt
  uses_u32_indices : Bool
} derive(Eq, Debug)

///|
pub fn HostGpuMeshInfo::index_count(self : HostGpuMeshInfo) -> Int {
  self.index_count
}

///|
pub fn HostGpuMeshInfo::vertex_count(self : HostGpuMeshInfo) -> Int {
  self.vertex_count
}

///|
pub fn HostGpuMeshInfo::index_start(self : HostGpuMeshInfo) -> Int {
  self.index_start
}

///|
pub fn HostGpuMeshInfo::vertex_start(self : HostGpuMeshInfo) -> Int {
  self.vertex_start
}

///|
pub fn HostGpuMeshInfo::uses_u32_indices(self : HostGpuMeshInfo) -> Bool {
  self.uses_u32_indices
}

///|
pub fn HostGpuMeshInfo::primitive_topology(self : HostGpuMeshInfo) -> UInt {
  self.primitive_topology
}

///|
fn host_gpu_mesh_info_from_gpu(mesh : GpuMeshInfo) -> HostGpuMeshInfo {
  {
    id: mesh.id,
    index_count: mesh.index_count.reinterpret_as_int(),
    vertex_count: mesh.vertex_count.reinterpret_as_int(),
    index_start: mesh.index_start.reinterpret_as_int(),
    vertex_start: mesh.vertex_start.reinterpret_as_int(),
    index_slab_id: mesh.index_slab_id,
    vertex_slab_id: mesh.vertex_slab_id,
    primitive_topology: mesh.primitive_topology,
    uses_u32_indices: mesh.uses_u32_indices,
  }
}

///|
pub fn mesh_info(mesh_id : Int) -> HostGpuMeshInfo? {
  if ensure_backend() is Some(backend) {
    match find_mesh(backend, mesh_id) {
      Some(mesh) => Some(host_gpu_mesh_info_from_gpu(mesh))
      None => None
    }
  } else {
    None
  }
}

///|
pub fn mesh2d_vertex_layout(mesh_id : Int) -> @mesh.MeshVertexBufferLayout? {
  guard ensure_backend() is Some(backend) else { return None }
  guard find_mesh(backend, mesh_id) is Some(mesh) else { return None }
  mesh.mesh_vertex_layout
}

///|
pub fn mesh_allocator_snapshot() -> @render_mesh.MeshAllocator? {
  match ensure_backend() {
    Some(backend) => Some(backend.mesh_allocator)
    None => None
  }
}

///|
pub fn delete_mesh(mesh_id : Int) -> Bool {
  if ensure_backend() is Some(backend) {
    backend.delete_mesh(mesh_id)
  } else {
    false
  }
}

///|
fn gpu_mesh_bind_index_buffer(
  pass : @wgpu.RenderPass,
  mesh : GpuMeshInfo,
) -> Unit {
  let index_bytes = mesh.index_buf.size()
  if mesh.uses_u32_indices {
    pass.set_index_buffer_u32(mesh.index_buf, 0UL, index_bytes)
  } else {
    pass.set_index_buffer_u16(mesh.index_buf, 0UL, index_bytes)
  }
}

///|
fn parse_f32_csv(csv : String) -> Array[Float]? {
  let trimmed = csv.trim().to_owned()
  if trimmed == "" {
    return Some([])
  }
  let values : Array[Float] = []
  for part in csv.split(",") {
    let token = part.trim().to_owned()
    if token == "" {
      continue
    }
    let parsed = @string.parse_double(token) catch { _ => return None }
    values.push(Float::from_double(parsed))
  }
  Some(values)
}

///|
pub fn create_mesh_capsule(
  radius~ : Float,
  half_length~ : Float,
  segments~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_mesh_capsule(radius, half_length, segments)
  }
  0
}

///|
pub fn create_mesh_rectangle(width~ : Float, height~ : Float) -> Int {
  if ensure_backend() is Some(backend) {
    return backend.create_mesh_rectangle(width, height)
  }
  0
}

///|
pub fn create_mesh_triangles(vertices_xy_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xy_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      let mesh_id = backend.create_mesh_triangles_xy(vertices)
      if mesh_id <= 0 {
        debug(
          "[renderer] create_mesh_triangles failed: parsed_values=\{vertices.length().to_string()}",
        )
      }
      return mesh_id
    }
  } else {
    debug(
      "[renderer] create_mesh_triangles parse failed: csv_len=\{vertices_xy_csv.length().to_string()}",
    )
  }
  0
}

///|
pub fn create_mesh_triangles_xyuvrgba(vertices_xyuvrgba_csv~ : String) -> Int {
  if parse_f32_csv(vertices_xyuvrgba_csv) is Some(vertices) {
    if ensure_backend() is Some(backend) {
      let mesh_id = backend.create_mesh_triangles_xyuvrgba(vertices)
      if mesh_id <= 0 {
        debug(
          "[renderer] create_mesh_triangles_xyuvrgba failed: parsed_values=\{vertices.length().to_string()}",
        )
      }
      return mesh_id
    }
  } else {
    debug(
      "[renderer] create_mesh_triangles_xyuvrgba parse failed: csv_len=\{vertices_xyuvrgba_csv.length().to_string()}",
    )
  }
  0
}

///|
pub fn create_mesh2d_vertex_buffer(
  vertex_bytes~ : Bytes,
  vertex_count~ : Int,
  indices~ : Array[Int],
  primitive_topology~ : Int,
  mesh_vertex_layout~ : @mesh.MeshVertexBufferLayout,
) -> Int {
  if ensure_backend() is Some(backend) {
    let mesh_id = backend.create_mesh2d_vertex_buffer(
      vertex_bytes, vertex_count, indices, primitive_topology, mesh_vertex_layout,
    )
    if mesh_id <= 0 {
      debug(
        "[renderer] create_mesh2d_vertex_buffer failed: bytes=\{vertex_bytes.length().to_string()}, vertices=\{vertex_count.to_string()}, indices=\{indices.length().to_string()}, topology=\{primitive_topology.to_string()}",
      )
    }
    return mesh_id
  }
  0
}

///|
pub fn create_mesh3d(
  vertices_xyzuvrgba_csv~ : String,
  primitive_topology~ : Int,
) -> Int {
  if parse_f32_csv(vertices_xyzuvrgba_csv) is Some(vertices) {
    return create_mesh3d_xyznuvrgba(
      vertices_xyznuvrgba=vertices,
      primitive_topology~,
    )
  } else {
    debug(
      "[renderer] create_mesh3d parse failed: csv_len=\{vertices_xyzuvrgba_csv.length().to_string()}, topology=\{primitive_topology.to_string()}",
    )
  }
  0
}

///|
pub fn create_mesh3d_xyznuvrgba(
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    let mesh_id = backend.create_mesh3d_xyznuvrgba(
      vertices_xyznuvrgba, primitive_topology,
    )
    if mesh_id <= 0 {
      debug(
        "[renderer] create_mesh3d_xyznuvrgba failed: values=\{vertices_xyznuvrgba.length().to_string()}, topology=\{primitive_topology.to_string()}",
      )
    }
    return mesh_id
  }
  0
}

///|
pub fn create_mesh3d_xyznuvrgba_indexed(
  vertices_xyznuvrgba~ : Array[Float],
  indices~ : Array[Int],
  primitive_topology~ : Int,
) -> Int {
  if ensure_backend() is Some(backend) {
    let mesh_id = backend.create_mesh3d_xyznuvrgba_indexed(
      vertices_xyznuvrgba, indices, primitive_topology,
    )
    if mesh_id <= 0 {
      debug(
        "[renderer] create_mesh3d_xyznuvrgba_indexed failed: values=\{vertices_xyznuvrgba.length().to_string()}, indices=\{indices.length().to_string()}, topology=\{primitive_topology.to_string()}",
      )
    }
    return mesh_id
  }
  0
}

///|
pub fn prepare_mesh3d_allocator_asset(
  mesh_id~ : Int,
  plan~ : @render_mesh.MeshAllocatorRenderMeshPlan,
  vertex_bytes~ : Bytes,
  vertex_count~ : Int,
  indices~ : Array[Int],
  uses_u32_indices~ : Bool,
  primitive_topology~ : Int,
  mesh_vertex_layout~ : @mesh.MeshVertexBufferLayout,
  vertex_start~ : Int,
  index_start~ : Int,
  extra_buffer_usages? : UInt64 = 0UL,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.prepare_mesh3d_allocator_asset(
        mesh_id,
        plan,
        vertex_bytes,
        vertex_count,
        indices,
        uses_u32_indices,
        primitive_topology,
        mesh_vertex_layout,
        vertex_start,
        index_start,
        extra_buffer_usages~,
      )
    None => false
  }
}

///|
pub fn update_mesh3d_xyznuvrgba(
  mesh_id~ : Int,
  vertices_xyznuvrgba~ : Array[Float],
  primitive_topology~ : Int,
) -> Bool {
  if ensure_backend() is Some(backend) {
    return backend.update_mesh3d_xyznuvrgba(
      mesh_id, vertices_xyznuvrgba, primitive_topology,
    )
  }
  false
}

///|
pub fn update_mesh3d_xyznuvrgba_indexed(
  mesh_id~ : Int,
  vertices_xyznuvrgba~ : Array[Float],
  indices~ : Array[Int],
  primitive_topology~ : Int,
) -> Bool {
  if ensure_backend() is Some(backend) {
    return backend.update_mesh3d_xyznuvrgba_indexed(
      mesh_id, vertices_xyznuvrgba, indices, primitive_topology,
    )
  }
  false
}
