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
fn mesh3d_vertex_joint_index_word(value : Float) -> UInt {
  let index = value.round().to_int()
  if index <= 0 {
    0U
  } else {
    index.reinterpret_as_uint()
  }
}

///|
fn mesh3d_vertex_bytes(vertices : Array[Float]) -> Bytes {
  let vertex_count = vertices.length() / MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  let stride = MESH3D_VERTEX_STRIDE_BYTES.to_int()
  let bytes = Array::make(vertex_count * stride, (0).to_byte())
  for vertex_index in 0..<vertex_count {
    let src = vertex_index * MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
    let dst = vertex_index * stride
    for component in 0..<12 {
      u32le_write_into(
        bytes,
        dst + component * 4,
        f32_bits(vertices[src + component]),
      )
    }
    for component in 0..<4 {
      u32le_write_into(
        bytes,
        dst + 48 + component * 4,
        mesh3d_vertex_joint_index_word(vertices[src + 12 + component]),
      )
    }
    for component in 0..<4 {
      u32le_write_into(
        bytes,
        dst + 64 + component * 4,
        f32_bits(vertices[src + 16 + component]),
      )
    }
  }
  Bytes::from_array(bytes)
}

///|
fn mesh3d_pad_upload_bytes(bytes : Bytes, byte_len : Int) -> Bytes {
  if byte_len <= bytes.length() {
    return bytes
  }
  let out = bytes.to_array()
  for _ in 0..<(byte_len - bytes.length()) {
    out.push((0).to_byte())
  }
  Bytes::from_array(out)
}

///|
fn mesh3d_allocator_usage_kind(
  usage : @render_mesh.MeshAllocatorBufferUsage,
) -> Int {
  if usage.is_vertex_buffer() {
    0
  } else {
    1
  }
}

///|
fn mesh3d_allocator_buffer_usage(
  usage : @render_mesh.MeshAllocatorBufferUsage,
  copy_src~ : Bool,
) -> @wgpu.BufferUsage {
  let mut raw = @wgpu.BUFFER_USAGE_COPY_DST
  if copy_src {
    raw = raw | @wgpu.BUFFER_USAGE_COPY_SRC
  }
  if usage.is_vertex_buffer() {
    raw = raw | @wgpu.BUFFER_USAGE_VERTEX
  } else {
    raw = raw | @wgpu.BUFFER_USAGE_INDEX
  }
  bu(raw)
}

///|
fn mesh3d_allocator_buffer_index(
  buffers : Array[GpuMeshAllocatorBuffer],
  slab_id : Int,
  usage_kind : Int,
) -> Int? {
  for index in 0..<buffers.length() {
    let buffer = buffers[index]
    if buffer.slab_id == slab_id && buffer.usage_kind == usage_kind {
      return Some(index)
    }
  }
  None
}

///|
fn GpuBackend::mesh3d_update_mesh_infos_for_allocator_buffer(
  self : GpuBackend,
  slab_id : Int,
  usage_kind : Int,
  buffer : @wgpu.Buffer,
) -> Unit {
  for index in 0..<self.meshes.length() {
    let mesh = self.meshes[index]
    if usage_kind == 0 && mesh.vertex_slab_id == slab_id {
      self.meshes[index] = GpuMeshInfo::{ ..mesh, vertex_buf: buffer.add_ref() }
    } else if usage_kind == 1 && mesh.index_slab_id == slab_id {
      self.meshes[index] = GpuMeshInfo::{ ..mesh, index_buf: buffer.add_ref() }
    }
  }
}

///|
fn GpuBackend::mesh3d_store_allocator_buffer(
  self : GpuBackend,
  slab_id : Int,
  usage_kind : Int,
  buffer : @wgpu.Buffer,
) -> Unit {
  match
    mesh3d_allocator_buffer_index(
      self.mesh_allocator_buffers,
      slab_id,
      usage_kind,
    ) {
    Some(index) => {
      let old = self.mesh_allocator_buffers[index].buffer
      self.frame_retired_buffers.push(old)
      self.mesh_allocator_buffers[index] = GpuMeshAllocatorBuffer::{
        slab_id,
        usage_kind,
        buffer: buffer.add_ref(),
      }
    }
    None =>
      self.mesh_allocator_buffers.push(GpuMeshAllocatorBuffer::{
        slab_id,
        usage_kind,
        buffer: buffer.add_ref(),
      })
  }
  self.mesh3d_update_mesh_infos_for_allocator_buffer(
    slab_id, usage_kind, buffer,
  )
}

///|
fn GpuBackend::mesh3d_allocator_buffer(
  self : GpuBackend,
  slab_id : Int,
  usage_kind : Int,
) -> @wgpu.Buffer? {
  match
    mesh3d_allocator_buffer_index(
      self.mesh_allocator_buffers,
      slab_id,
      usage_kind,
    ) {
    Some(index) => Some(self.mesh_allocator_buffers[index].buffer)
    None => None
  }
}

///|
fn GpuBackend::mesh3d_reallocate_allocator_slab(
  self : GpuBackend,
  plan : @render_mesh.MeshAllocatorReallocateSlabPlan,
) -> Unit {
  let usage_kind = mesh3d_allocator_usage_kind(plan.usage())
  let slab_id = plan.slab_id()
  let new_buffer = self.device.create_buffer(
    size=plan.new_size().to_uint64(),
    usage=mesh3d_allocator_buffer_usage(plan.usage(), copy_src=true),
  )
  new_buffer.set_label(plan.label())
  match self.mesh3d_allocator_buffer(slab_id, usage_kind) {
    Some(old_buffer) =>
      if plan.old_copy_size() > 0 {
        let encoder = self.device.create_command_encoder()
        encoder.copy_buffer_to_buffer(
          old_buffer,
          0UL,
          new_buffer,
          0UL,
          plan.old_copy_size().to_uint64(),
        )
        let command_buffer = encoder.finish()
        self.queue.submit_one(command_buffer)
        command_buffer.release()
        encoder.release()
      }
    None => ()
  }
  self.mesh3d_store_allocator_buffer(slab_id, usage_kind, new_buffer)
}

///|
fn GpuBackend::mesh3d_execute_allocator_upload(
  self : GpuBackend,
  mesh_id : Int,
  upload : @render_mesh.MeshAllocatorUploadPlan,
  bytes : Bytes,
) -> @wgpu.Buffer? {
  let usage_kind = mesh3d_allocator_usage_kind(upload.usage())
  let slab_id = upload.slab_id()
  let buffer = match self.mesh3d_allocator_buffer(slab_id, usage_kind) {
    Some(buffer) => buffer
    None =>
      if upload.mapped_at_creation() {
        let created = self.device.create_buffer_init(
          usage=mesh3d_allocator_buffer_usage(upload.usage(), copy_src=false),
          mesh3d_pad_upload_bytes(bytes, upload.size()),
        )
        created.set_label(upload.label())
        self.mesh3d_store_allocator_buffer(slab_id, usage_kind, created)
        created
      } else {
        return None
      }
  }
  if upload.mapped_at_creation() {
    if buffer.size().to_int() != upload.size() {
      self.queue.write_buffer(buffer, 0UL, bytes)
    }
  } else {
    self.queue.write_buffer(
      buffer,
      upload.offset().to_uint64(),
      mesh3d_pad_upload_bytes(bytes, upload.size()),
    )
  }
  if upload.usage().is_vertex_buffer() {
    ignore(self.mesh_allocator.mark_vertex_resident(mesh_id))
  } else {
    ignore(self.mesh_allocator.mark_index_resident(mesh_id))
  }
  Some(buffer)
}

///|
fn mesh3d_usable_non_indexed_vertex_count(
  vertex_count : Int,
  primitive_topology : UInt,
) -> Int {
  if primitive_topology == MESH3D_TOPOLOGY_TRIANGLE_LIST {
    vertex_count - vertex_count % 3
  } else if primitive_topology == MESH3D_TOPOLOGY_LINE_LIST {
    vertex_count - vertex_count % 2
  } else if vertex_count < 2 {
    0
  } else {
    vertex_count
  }
}

///|
fn mesh3d_index_is_restart(primitive_topology : UInt, index : Int) -> Bool {
  primitive_topology == MESH3D_TOPOLOGY_LINE_STRIP && index == 0xffff
}

///|
fn mesh3d_indices_valid(
  indices : Array[Int],
  vertex_count : Int,
  primitive_topology : UInt,
) -> Bool {
  if indices.length() <= 0 || vertex_count <= 0 {
    return false
  }
  for index in indices {
    if mesh3d_index_is_restart(primitive_topology, index) {
      continue
    }
    if index < 0 || index >= vertex_count {
      return false
    }
  }
  true
}

///|
fn mesh3d_indices_use_u32(indices : Array[Int]) -> Bool {
  for index in indices {
    if index > 65535 {
      return true
    }
  }
  false
}

///|
fn mesh3d_index_bytes(indices : Array[Int], uses_u32_indices : Bool) -> Bytes {
  if uses_u32_indices {
    let indices_u32 : Array[UInt] = []
    for index in indices {
      indices_u32.push(index.reinterpret_as_uint())
    }
    u32le_pack(indices_u32)
  } else {
    u16le_pack(indices)
  }
}

///|
fn GpuBackend::create_mesh3d_empty_index_buffer(
  self : GpuBackend,
) -> @wgpu.Buffer {
  self.device.create_buffer_init(
    usage=bu(@wgpu.BUFFER_USAGE_INDEX),
    u16le_pack([0]),
  )
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
  let usable_vcount = mesh3d_usable_non_indexed_vertex_count(
    vcount, primitive_topology,
  )
  if usable_vcount <= 0 {
    return 0
  }
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
  let vertex_bytes = mesh3d_vertex_bytes(trimmed_vertices)
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=usable_vcount,
    indexed=false,
  )
  let plan = self.mesh_allocator.allocate_render_mesh(
    id,
    render_mesh,
    MESH3D_VERTEX_STRIDE_BYTES.to_int(),
  )
  if plan.vertex_reallocate() is Some(reallocate) {
    self.mesh3d_reallocate_allocator_slab(reallocate)
  }
  guard plan.vertex_upload() is Some(vertex_upload) else { return 0 }
  guard self.mesh3d_execute_allocator_upload(id, vertex_upload, vertex_bytes)
    is Some(vb) else {
    return 0
  }
  guard self.mesh_allocator.mesh_vertex_slice(id) is Some(vertex_slice) else {
    return 0
  }
  let info = GpuMeshInfo::{
    id,
    index_count: 0U,
    vertex_count: usable_vcount.reinterpret_as_uint(),
    index_start: 0U,
    vertex_start: vertex_slice.start().reinterpret_as_uint(),
    index_slab_id: -1,
    vertex_slab_id: vertex_slice.slab_id(),
    primitive_topology,
    vertex_stride_bytes: MESH3D_VERTEX_STRIDE_BYTES,
    mesh_vertex_layout: None,
    vertex_layout: None,
    index_stride_bytes: 2UL,
    uses_u32_indices: false,
    vertex_buf: vb,
    index_buf: self.create_mesh3d_empty_index_buffer(),
  }
  self.meshes.push(info)
  id
}

///|
pub fn GpuBackend::create_mesh3d_xyznuvrgba_indexed(
  self : GpuBackend,
  vertices : Array[Float],
  indices : Array[Int],
  primitive_topology_kind : Int,
) -> Int {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return 0
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vertex_count = expanded_vertices.length() /
    MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if !mesh3d_indices_valid(indices, vertex_count, primitive_topology) {
    return 0
  }
  let uses_u32_indices = mesh3d_indices_use_u32(indices)
  let id = alloc_id(self)
  let vertex_bytes = mesh3d_vertex_bytes(expanded_vertices)
  let index_layout = if uses_u32_indices {
    @render_mesh.MeshAllocatorElementLayout::index_u32()
  } else {
    @render_mesh.MeshAllocatorElementLayout::index_u16()
  }
  let index_bytes = mesh3d_index_bytes(indices, uses_u32_indices)
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count~,
    indexed=true,
    index_count=indices.length(),
  )
  let plan = self.mesh_allocator.allocate_render_mesh(
    id,
    render_mesh,
    MESH3D_VERTEX_STRIDE_BYTES.to_int(),
    index_layout~,
  )
  if plan.vertex_reallocate() is Some(reallocate) {
    self.mesh3d_reallocate_allocator_slab(reallocate)
  }
  if plan.index_reallocate() is Some(reallocate) {
    self.mesh3d_reallocate_allocator_slab(reallocate)
  }
  guard plan.vertex_upload() is Some(vertex_upload) else { return 0 }
  guard plan.index_upload() is Some(index_upload) else { return 0 }
  guard self.mesh3d_execute_allocator_upload(id, vertex_upload, vertex_bytes)
    is Some(vb) else {
    return 0
  }
  guard self.mesh3d_execute_allocator_upload(id, index_upload, index_bytes)
    is Some(ib) else {
    return 0
  }
  guard self.mesh_allocator.mesh_vertex_slice(id) is Some(vertex_slice) else {
    return 0
  }
  guard self.mesh_allocator.mesh_index_slice(id) is Some(index_slice) else {
    return 0
  }
  let info = GpuMeshInfo::{
    id,
    index_count: indices.length().reinterpret_as_uint(),
    vertex_count: vertex_count.reinterpret_as_uint(),
    index_start: index_slice.start().reinterpret_as_uint(),
    vertex_start: vertex_slice.start().reinterpret_as_uint(),
    index_slab_id: index_slice.slab_id(),
    vertex_slab_id: vertex_slice.slab_id(),
    primitive_topology,
    vertex_stride_bytes: MESH3D_VERTEX_STRIDE_BYTES,
    mesh_vertex_layout: None,
    vertex_layout: None,
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
  let usable_vcount = mesh3d_usable_non_indexed_vertex_count(
    vcount, primitive_topology,
  )
  if usable_vcount <= 0 {
    return false
  }
  guard find_mesh_index(self, mesh_id) is Some(mesh_index) else { return false }
  let mesh = self.meshes[mesh_index]
  if mesh.vertex_stride_bytes != MESH3D_VERTEX_STRIDE_BYTES ||
    mesh.primitive_topology != primitive_topology ||
    mesh.vertex_count.reinterpret_as_int() != usable_vcount ||
    mesh.index_count != 0U {
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
  self.queue.write_buffer(
    mesh.vertex_buf,
    mesh.vertex_start.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes,
    mesh3d_vertex_bytes(trimmed_vertices),
  )
  true
}

///|
pub fn GpuBackend::update_mesh3d_xyznuvrgba_indexed(
  self : GpuBackend,
  mesh_id : Int,
  vertices : Array[Float],
  indices : Array[Int],
  primitive_topology_kind : Int,
) -> Bool {
  guard mesh3d_expand_vertices_with_skinning_defaults(vertices)
    is Some(expanded_vertices) else {
    return false
  }
  let primitive_topology = mesh3d_topology_from_kind(primitive_topology_kind)
  let vertex_count = expanded_vertices.length() /
    MESH3D_VERTEX_SKINNED_FLOAT_STRIDE
  if !mesh3d_indices_valid(indices, vertex_count, primitive_topology) {
    return false
  }
  let uses_u32_indices = mesh3d_indices_use_u32(indices)
  guard find_mesh_index(self, mesh_id) is Some(mesh_index) else { return false }
  let mesh = self.meshes[mesh_index]
  if mesh.vertex_stride_bytes != MESH3D_VERTEX_STRIDE_BYTES ||
    mesh.primitive_topology != primitive_topology ||
    mesh.vertex_count.reinterpret_as_int() != vertex_count ||
    mesh.index_count.reinterpret_as_int() != indices.length() ||
    mesh.uses_u32_indices != uses_u32_indices {
    return false
  }
  self.queue.write_buffer(
    mesh.vertex_buf,
    mesh.vertex_start.reinterpret_as_int().to_uint64() *
    mesh.vertex_stride_bytes,
    mesh3d_vertex_bytes(expanded_vertices),
  )
  self.queue.write_buffer(
    mesh.index_buf,
    mesh.index_start.reinterpret_as_int().to_uint64() * mesh.index_stride_bytes,
    mesh3d_index_bytes(indices, uses_u32_indices),
  )
  true
}
