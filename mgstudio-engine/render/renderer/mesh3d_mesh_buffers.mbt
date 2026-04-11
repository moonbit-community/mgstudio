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
fn mesh3d_expand_vertices_with_skinning_defaults(
  vertices : Array[Float],
) -> Array[Float]? {
  if vertices.length() % MESH3D_VERTEX_SKINNED_FLOAT_STRIDE == 0 {
    return Some(vertices)
  }
  if vertices.length() % MESH3D_VERTEX_BASE_FLOAT_STRIDE != 0 {
    return None
  }
  let vertex_count = vertices.length() / MESH3D_VERTEX_BASE_FLOAT_STRIDE
  let expanded : Array[Float] = []
  for vertex_index in 0..<vertex_count {
    let base = vertex_index * MESH3D_VERTEX_BASE_FLOAT_STRIDE
    for i in 0..<MESH3D_VERTEX_BASE_FLOAT_STRIDE {
      expanded.push(vertices[base + i])
    }
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
    expanded.push(0.0F)
  }
  Some(expanded)
}

///|
pub fn GpuBackend::create_mesh3d_xyznuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Int {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return 0
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = expanded_vertices.length() / MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if vcount <= 0 {
    return 0
  }
  let usable_vcount = if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vcount - vcount % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vcount - vcount % 2
  } else if vcount < 2 {
    0
  } else {
    vcount
  }
  if usable_vcount <= 0 {
    return 0
  }
  let uses_u32_indices = usable_vcount > 65535
  let id = alloc_id(self)
  let trimmed_vertices = if usable_vcount == vcount {
    expanded_vertices
  } else {
    let out : Array[Float] = []
    let limit = usable_vcount * MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
    for i in 0..<limit {
      out.push(expanded_vertices[i])
    }
    out
  }
  let vb_usage = bu(@wgpu.BUFFER_USAGE_VERTEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let vb = self.device.create_buffer_init(
    usage=vb_usage,
    f32le_pack(trimmed_vertices),
  )
  let ib_usage = bu(@wgpu.BUFFER_USAGE_INDEX | @wgpu.BUFFER_USAGE_COPY_DST)
  let ib = if uses_u32_indices {
    let indices_u32 : Array[UInt] = []
    for i in 0..<usable_vcount {
      indices_u32.push(i.reinterpret_as_uint())
    }
    self.device.create_buffer_init(usage=ib_usage, u32le_pack(indices_u32))
  } else {
    let indices_u16 : Array[Int] = []
    for i in 0..<usable_vcount {
      indices_u16.push(i)
    }
    self.device.create_buffer_init(usage=ib_usage, u16le_pack(indices_u16))
  }
  let info = GpuMeshInfo::{
    id,
    index_count: usable_vcount.reinterpret_as_uint(),
    vertex_count: usable_vcount.reinterpret_as_uint(),
    primitive_topology,
    vertex_stride_bytes: MESH3D_VERTEX_STRIDE_BYTES,
    index_stride_bytes: if uses_u32_indices {
      4UL
    } else {
      2UL
    },
    uses_u32_indices,
    vertex_buf: vb,
    index_buf: ib,
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh_triangles_xyznuvrgba(
  self : GpuBackend,
  vertices : Array[Float],
) -> Int {
  self.create_mesh3d_xyznuvrgba(vertices, 0)
}

///|
pub fn GpuBackend::update_mesh3d_xyznuvrgba(
  self : GpuBackend,
  mesh_id : Int,
  vertices : Array[Float],
  primitive_topology_kind : Int,
) -> Bool {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return false
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vcount = expanded_vertices.length() / MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if vcount <= 0 {
    return false
  }
  let usable_vcount = if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vcount - vcount % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vcount - vcount % 2
  } else if vcount < 2 {
    0
  } else {
    vcount
  }
  if usable_vcount <= 0 {
    return false
  }
  guard find_mesh_index(self, mesh_id) is Some(mesh_index) else { return false }
  let mesh = self.meshes[mesh_index]
  if mesh.vertex_stride_bytes != MESH3D_VERTEX_STRIDE_BYTES ||
    mesh.primitive_topology != primitive_topology ||
    mesh.vertex_count.reinterpret_as_int() != usable_vcount {
    return false
  }
  let trimmed_vertices = if usable_vcount == vcount {
    expanded_vertices
  } else {
    let out : Array[Float] = []
    let limit = usable_vcount * MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
    for i in 0..<limit {
      out.push(expanded_vertices[i])
    }
    out
  }
  self.queue.write_buffer(mesh.vertex_buf, 0UL, f32le_pack(trimmed_vertices))
  true
}
