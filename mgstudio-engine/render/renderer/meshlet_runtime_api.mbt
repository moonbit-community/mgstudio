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
fn meshlet_buffer_size_for_bytes(bytes : Bytes) -> UInt64 {
  let byte_len = bytes.length()
  if byte_len <= 0 {
    4UL
  } else {
    byte_len.to_uint64()
  }
}

///|
fn meshlet_storage_buffer_update(
  backend : GpuBackend,
  current_buffer : @wgpu.Buffer?,
  current_capacity : UInt64,
  bytes : Bytes,
  label : String,
) -> (@wgpu.Buffer, UInt64) {
  let required_size = meshlet_buffer_size_for_bytes(bytes)
  let (buffer, capacity) = match current_buffer {
    Some(existing) if current_capacity >= required_size =>
      (existing, current_capacity)
    Some(existing) => {
      existing.release()
      let next = backend.device.create_buffer(
        size=required_size,
        usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
      )
      next.set_label(label)
      (next, required_size)
    }
    None => {
      let next = backend.device.create_buffer(
        size=required_size,
        usage=bu(@wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST),
      )
      next.set_label(label)
      (next, required_size)
    }
  }
  if bytes.length() > 0 {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  (buffer, capacity)
}

///|
fn meshlet_non_zero_u64(value : UInt64) -> UInt64 {
  if value == 0UL {
    4UL
  } else {
    value
  }
}

///|
fn meshlet_reuse_or_create_buffer(
  backend : GpuBackend,
  current_buffer : @wgpu.Buffer?,
  current_capacity : UInt64,
  required_size : UInt64,
  usage_bits : UInt64,
  label : String,
) -> (@wgpu.Buffer, UInt64) {
  let safe_size = meshlet_non_zero_u64(required_size)
  match current_buffer {
    Some(existing) if current_capacity >= safe_size =>
      (existing, current_capacity)
    Some(existing) => {
      existing.release()
      let next = backend.device.create_buffer(
        size=safe_size,
        usage=bu(usage_bits),
      )
      next.set_label(label)
      (next, safe_size)
    }
    None => {
      let next = backend.device.create_buffer(
        size=safe_size,
        usage=bu(usage_bits),
      )
      next.set_label(label)
      (next, safe_size)
    }
  }
}

///|
fn meshlet_fixed_buffer_write(
  backend : GpuBackend,
  current_buffer : @wgpu.Buffer?,
  required_size : UInt64,
  usage_bits : UInt64,
  label : String,
  bytes : Bytes,
) -> @wgpu.Buffer {
  let buffer = match current_buffer {
    Some(existing) => existing
    None => {
      let next = backend.device.create_buffer(
        size=meshlet_non_zero_u64(required_size),
        usage=bu(usage_bits),
      )
      next.set_label(label)
      next
    }
  }
  if bytes.length() > 0 {
    backend.queue.write_buffer(buffer, 0UL, bytes)
  }
  buffer
}

///|
fn meshlet_cull_queue_size(cluster_buffer_slots : Int) -> UInt64 {
  let slots = if cluster_buffer_slots <= 0 { 1 } else { cluster_buffer_slots }
  2UL * slots.to_uint64() * 4UL
}

///|
fn meshlet_second_pass_candidate_size(scene_instance_count : Int) -> UInt64 {
  let count = if scene_instance_count <= 0 { 1 } else { scene_instance_count }
  4UL * count.to_uint64()
}

///|
pub fn GpuBackend::prepare_meshlet_frame_resources(
  self : GpuBackend,
  cluster_buffer_slots~ : Int,
  scene_instance_count~ : Int,
) -> Unit {
  let cull_queue_size = meshlet_cull_queue_size(cluster_buffer_slots)
  let storage = @wgpu.BUFFER_USAGE_STORAGE
  let storage_copy = @wgpu.BUFFER_USAGE_STORAGE | @wgpu.BUFFER_USAGE_COPY_DST
  let (raster_clusters, raster_clusters_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_visibility_buffer_raster_clusters_buf,
    self.meshlet_visibility_buffer_raster_clusters_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_visibility_buffer_raster_clusters",
  )
  self.meshlet_visibility_buffer_raster_clusters_buf = Some(raster_clusters)
  self.meshlet_visibility_buffer_raster_clusters_capacity = raster_clusters_capacity
  self.meshlet_visibility_buffer_raster_cluster_prev_counts_buf = Some(
    meshlet_fixed_buffer_write(
      self,
      self.meshlet_visibility_buffer_raster_cluster_prev_counts_buf,
      8UL,
      storage_copy,
      "mgstudio_meshlet_visibility_buffer_raster_cluster_prev_counts",
      u32le_pack([0U, 0U]),
    ),
  )
  self.meshlet_software_raster_cluster_count_buf = Some(
    meshlet_fixed_buffer_write(
      self,
      self.meshlet_software_raster_cluster_count_buf,
      4UL,
      storage,
      "mgstudio_meshlet_software_raster_cluster_count",
      u32le_pack([0U]),
    ),
  )
  let (bvh_queue_0, bvh_queue_0_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_bvh_traversal_queue_0_buf,
    self.meshlet_bvh_traversal_queue_0_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_bvh_traversal_queue_0",
  )
  self.meshlet_bvh_traversal_queue_0_buf = Some(bvh_queue_0)
  self.meshlet_bvh_traversal_queue_0_capacity = bvh_queue_0_capacity
  let (bvh_queue_1, bvh_queue_1_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_bvh_traversal_queue_1_buf,
    self.meshlet_bvh_traversal_queue_1_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_bvh_traversal_queue_1",
  )
  self.meshlet_bvh_traversal_queue_1_buf = Some(bvh_queue_1)
  self.meshlet_bvh_traversal_queue_1_capacity = bvh_queue_1_capacity
  let (cluster_candidates, cluster_candidates_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_cluster_cull_candidate_queue_buf,
    self.meshlet_cluster_cull_candidate_queue_capacity,
    cull_queue_size,
    storage,
    "mgstudio_meshlet_cluster_cull_candidate_queue",
  )
  self.meshlet_cluster_cull_candidate_queue_buf = Some(cluster_candidates)
  self.meshlet_cluster_cull_candidate_queue_capacity = cluster_candidates_capacity
  let second_pass_size = meshlet_second_pass_candidate_size(
    scene_instance_count,
  )
  let (second_pass_candidates, second_pass_candidates_capacity) = meshlet_reuse_or_create_buffer(
    self,
    self.meshlet_second_pass_candidates_buf,
    self.meshlet_second_pass_candidates_capacity,
    second_pass_size,
    storage,
    "mgstudio_meshlet_second_pass_candidates",
  )
  self.meshlet_second_pass_candidates_buf = Some(second_pass_candidates)
  self.meshlet_second_pass_candidates_capacity = second_pass_candidates_capacity
  self.meshlet_frame_resource_revision = self.meshlet_frame_resource_revision +
    1
}

///|
pub fn prepare_meshlet_frame_resources(
  cluster_buffer_slots~ : Int,
  scene_instance_count~ : Int,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_meshlet_frame_resources(
      cluster_buffer_slots~,
      scene_instance_count~,
    )
  }
}

///|
pub fn meshlet_frame_resource_revision() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_frame_resource_revision
    None => 0
  }
}

///|
pub fn GpuBackend::prepare_meshlet_storage_buffers(
  self : GpuBackend,
  vertex_positions~ : Bytes,
  vertex_normals~ : Bytes,
  vertex_uvs~ : Bytes,
  indices~ : Bytes,
  bvh_nodes~ : Bytes,
  meshlets~ : Bytes,
  cull_data~ : Bytes,
  instance_uniforms~ : Bytes,
  instance_aabbs~ : Bytes,
  instance_material_ids~ : Bytes,
  instance_bvh_root_nodes~ : Bytes,
) -> Unit {
  let (vertex_positions_buf, vertex_positions_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_vertex_positions_buf,
    self.meshlet_vertex_positions_capacity,
    vertex_positions,
    "mgstudio_meshlet_vertex_positions",
  )
  self.meshlet_vertex_positions_buf = Some(vertex_positions_buf)
  self.meshlet_vertex_positions_capacity = vertex_positions_capacity
  let (vertex_normals_buf, vertex_normals_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_vertex_normals_buf,
    self.meshlet_vertex_normals_capacity,
    vertex_normals,
    "mgstudio_meshlet_vertex_normals",
  )
  self.meshlet_vertex_normals_buf = Some(vertex_normals_buf)
  self.meshlet_vertex_normals_capacity = vertex_normals_capacity
  let (vertex_uvs_buf, vertex_uvs_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_vertex_uvs_buf,
    self.meshlet_vertex_uvs_capacity,
    vertex_uvs,
    "mgstudio_meshlet_vertex_uvs",
  )
  self.meshlet_vertex_uvs_buf = Some(vertex_uvs_buf)
  self.meshlet_vertex_uvs_capacity = vertex_uvs_capacity
  let (indices_buf, indices_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_indices_buf,
    self.meshlet_indices_capacity,
    indices,
    "mgstudio_meshlet_indices",
  )
  self.meshlet_indices_buf = Some(indices_buf)
  self.meshlet_indices_capacity = indices_capacity
  let (bvh_nodes_buf, bvh_nodes_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_bvh_nodes_buf,
    self.meshlet_bvh_nodes_capacity,
    bvh_nodes,
    "mgstudio_meshlet_bvh_nodes",
  )
  self.meshlet_bvh_nodes_buf = Some(bvh_nodes_buf)
  self.meshlet_bvh_nodes_capacity = bvh_nodes_capacity
  let (meshlets_buf, meshlets_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_meshlets_buf,
    self.meshlet_meshlets_capacity,
    meshlets,
    "mgstudio_meshlets",
  )
  self.meshlet_meshlets_buf = Some(meshlets_buf)
  self.meshlet_meshlets_capacity = meshlets_capacity
  let (cull_data_buf, cull_data_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_cull_data_buf,
    self.meshlet_cull_data_capacity,
    cull_data,
    "mgstudio_meshlet_cull_data",
  )
  self.meshlet_cull_data_buf = Some(cull_data_buf)
  self.meshlet_cull_data_capacity = cull_data_capacity
  let (instance_uniforms_buf, instance_uniforms_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_uniforms_buf,
    self.meshlet_instance_uniforms_capacity,
    instance_uniforms,
    "mgstudio_meshlet_instance_uniforms",
  )
  self.meshlet_instance_uniforms_buf = Some(instance_uniforms_buf)
  self.meshlet_instance_uniforms_capacity = instance_uniforms_capacity
  let (instance_aabbs_buf, instance_aabbs_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_aabbs_buf,
    self.meshlet_instance_aabbs_capacity,
    instance_aabbs,
    "mgstudio_meshlet_instance_aabbs",
  )
  self.meshlet_instance_aabbs_buf = Some(instance_aabbs_buf)
  self.meshlet_instance_aabbs_capacity = instance_aabbs_capacity
  let (instance_material_ids_buf, instance_material_ids_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_material_ids_buf,
    self.meshlet_instance_material_ids_capacity,
    instance_material_ids,
    "mgstudio_meshlet_instance_material_ids",
  )
  self.meshlet_instance_material_ids_buf = Some(instance_material_ids_buf)
  self.meshlet_instance_material_ids_capacity = instance_material_ids_capacity
  let (instance_bvh_root_nodes_buf, instance_bvh_root_nodes_capacity) = meshlet_storage_buffer_update(
    self,
    self.meshlet_instance_bvh_root_nodes_buf,
    self.meshlet_instance_bvh_root_nodes_capacity,
    instance_bvh_root_nodes,
    "mgstudio_meshlet_instance_bvh_root_nodes",
  )
  self.meshlet_instance_bvh_root_nodes_buf = Some(instance_bvh_root_nodes_buf)
  self.meshlet_instance_bvh_root_nodes_capacity = instance_bvh_root_nodes_capacity
  self.meshlet_gpu_buffer_revision = self.meshlet_gpu_buffer_revision + 1
}

///|
pub fn prepare_meshlet_storage_buffers(
  vertex_positions~ : Bytes,
  vertex_normals~ : Bytes,
  vertex_uvs~ : Bytes,
  indices~ : Bytes,
  bvh_nodes~ : Bytes,
  meshlets~ : Bytes,
  cull_data~ : Bytes,
  instance_uniforms~ : Bytes,
  instance_aabbs~ : Bytes,
  instance_material_ids~ : Bytes,
  instance_bvh_root_nodes~ : Bytes,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_meshlet_storage_buffers(
      vertex_positions~,
      vertex_normals~,
      vertex_uvs~,
      indices~,
      bvh_nodes~,
      meshlets~,
      cull_data~,
      instance_uniforms~,
      instance_aabbs~,
      instance_material_ids~,
      instance_bvh_root_nodes~,
    )
  }
}

///|
pub fn meshlet_gpu_buffer_revision() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_gpu_buffer_revision
    None => 0
  }
}
