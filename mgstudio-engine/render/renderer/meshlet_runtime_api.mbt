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
pub(all) struct MeshletViewVisibilityBuffer {
  buffer : @wgpu.Buffer
  capacity : UInt64
  view_width : Int
  view_height : Int
  not_shadow_view : Bool
}

///|
fn meshlet_visibility_buffer_pixel_count(
  view_width : Int,
  view_height : Int,
) -> UInt64 {
  let width = if view_width <= 0 { 1 } else { view_width }
  let height = if view_height <= 0 { 1 } else { view_height }
  width.to_uint64() * height.to_uint64()
}

///|
fn meshlet_visibility_buffer_size(
  view_width : Int,
  view_height : Int,
) -> UInt64 {
  meshlet_visibility_buffer_pixel_count(view_width, view_height) * 4UL
}

///|
fn meshlet_create_visibility_buffer(
  backend : GpuBackend,
  required_size : UInt64,
  label : String,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=meshlet_non_zero_u64(required_size),
    usage=bu(
      @wgpu.BUFFER_USAGE_STORAGE |
      @wgpu.BUFFER_USAGE_COPY_DST |
      @wgpu.BUFFER_USAGE_COPY_SRC,
    ),
  )
  buffer.set_label(label)
  buffer
}

///|
pub fn GpuBackend::prepare_meshlet_view_visibility_buffer(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
  view_width~ : Int,
  view_height~ : Int,
  not_shadow_view~ : Bool,
) -> Unit {
  let required_size = meshlet_visibility_buffer_size(view_width, view_height)
  let label = if not_shadow_view {
    "mgstudio_meshlet_visibility_buffer"
  } else {
    "mgstudio_meshlet_shadow_visibility_buffer"
  }
  let next = match self.meshlet_view_visibility_buffers.get(view_entity_bits) {
    Some(existing) if existing.capacity >= required_size =>
      MeshletViewVisibilityBuffer::{
        buffer: existing.buffer,
        capacity: existing.capacity,
        view_width,
        view_height,
        not_shadow_view,
      }
    Some(existing) => {
      existing.buffer.release()
      MeshletViewVisibilityBuffer::{
        buffer: meshlet_create_visibility_buffer(self, required_size, label),
        capacity: required_size,
        view_width,
        view_height,
        not_shadow_view,
      }
    }
    None =>
      MeshletViewVisibilityBuffer::{
        buffer: meshlet_create_visibility_buffer(self, required_size, label),
        capacity: required_size,
        view_width,
        view_height,
        not_shadow_view,
      }
  }
  self.meshlet_view_visibility_buffers.set(view_entity_bits, next)
  self.meshlet_view_visibility_buffer_revision = self.meshlet_view_visibility_buffer_revision +
    1
}

///|
pub fn prepare_meshlet_view_visibility_buffer(
  view_entity_bits~ : UInt64,
  view_width~ : Int,
  view_height~ : Int,
  not_shadow_view~ : Bool,
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.prepare_meshlet_view_visibility_buffer(
      view_entity_bits~,
      view_width~,
      view_height~,
      not_shadow_view~,
    )
  }
}

///|
pub fn GpuBackend::clear_stale_meshlet_view_visibility_buffers(
  self : GpuBackend,
  active_view_bits : Array[UInt64],
) -> Unit {
  let active : Map[UInt64, Bool] = {}
  for view_bits in active_view_bits {
    active.set(view_bits, true)
  }
  let stale : Array[UInt64] = []
  for view_bits in self.meshlet_view_visibility_buffers.keys() {
    if active.get(view_bits) is None {
      stale.push(view_bits)
    }
  }
  for view_bits in stale {
    match self.meshlet_view_visibility_buffers.get(view_bits) {
      Some(resources) => resources.buffer.release()
      None => ()
    }
    self.meshlet_view_visibility_buffers.remove(view_bits)
  }
}

///|
pub fn clear_stale_meshlet_view_visibility_buffers(
  active_view_bits : Array[UInt64],
) -> Unit {
  if ensure_backend() is Some(backend) {
    backend.clear_stale_meshlet_view_visibility_buffers(active_view_bits)
  }
}

///|
pub fn meshlet_view_visibility_buffer_revision() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_view_visibility_buffer_revision
    None => 0
  }
}

///|
pub fn meshlet_view_visibility_buffer_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_view_visibility_buffers.length()
    None => 0
  }
}

///|
fn meshlet_dispatch_group_count_16(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    ((value + 15) / 16).reinterpret_as_uint()
  }
}

///|
fn meshlet_positive_u32(value : Int) -> UInt {
  if value <= 0 {
    1U
  } else {
    value.reinterpret_as_uint()
  }
}

///|
fn meshlet_clear_visibility_buffer_defines() -> @hashmap.HashMap[String, Bool] {
  let defines = @hashmap.HashMap([])
  defines.set("MESHLET_VISIBILITY_BUFFER_RASTER_PASS_OUTPUT", true)
  defines
}

///|
fn meshlet_create_clear_visibility_buffer_bgl(
  backend : GpuBackend,
) -> @wgpu.BindGroupLayout raise GpuBackendError {
  let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=2UL)
  let ok = builder.add_buffer(
      0U,
      ss(@wgpu.SHADER_STAGE_COMPUTE),
      @wgpu.BUFFER_BINDING_TYPE_STORAGE,
    ) &&
    builder.add_buffer(
      1U,
      ss(@wgpu.SHADER_STAGE_COMPUTE),
      @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
    )
  if !ok {
    builder.free()
    fatal("wgpu: failed to build meshlet clear visibility buffer layout")
  }
  builder.finish(
    backend.device,
    label="mgstudio_meshlet_clear_visibility_buffer_bind_group_layout",
  )
}

///|
fn meshlet_create_clear_visibility_buffer_constants_buf(
  backend : GpuBackend,
) -> @wgpu.Buffer {
  let buffer = backend.device.create_buffer(
    size=16UL,
    usage=bu(@wgpu.BUFFER_USAGE_UNIFORM | @wgpu.BUFFER_USAGE_COPY_DST),
  )
  buffer.set_label("mgstudio_meshlet_clear_visibility_buffer_constants")
  buffer
}

///|
fn ensure_meshlet_clear_visibility_buffer_resources(
  backend : GpuBackend,
) -> Bool raise GpuBackendError {
  if backend.meshlet_clear_visibility_buffer_bgl is Some(_) &&
    backend.meshlet_clear_visibility_buffer_pipeline_layout is Some(_) &&
    backend.meshlet_clear_visibility_buffer_pipeline is Some(_) &&
    backend.meshlet_clear_visibility_buffer_constants_buf is Some(_) {
    return true
  }
  let bgl = meshlet_create_clear_visibility_buffer_bgl(backend)
  let pipeline_layout = backend.device.create_pipeline_layout_1(bgl)
  let wgsl = load_wgsl_preprocessed(
    backend.assets_base,
    "pbr/meshlet/clear_visibility_buffer.wgsl",
    meshlet_clear_visibility_buffer_defines(),
    default_wgsl_value_defines(),
  )
  let shader = backend.device.create_shader_module_wgsl(wgsl)
  let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
    pipeline_layout, shader, "clear_visibility_buffer",
  ) catch {
    err =>
      fatal(
        "wgpu: failed to build meshlet clear visibility buffer pipeline: \{err.message()}",
      )
  }
  shader.release()
  let constants_buf = meshlet_create_clear_visibility_buffer_constants_buf(
    backend,
  )
  backend.meshlet_clear_visibility_buffer_bgl = Some(bgl)
  backend.meshlet_clear_visibility_buffer_pipeline_layout = Some(
    pipeline_layout,
  )
  backend.meshlet_clear_visibility_buffer_pipeline = Some(pipeline)
  backend.meshlet_clear_visibility_buffer_constants_buf = Some(constants_buf)
  true
}

///|
fn meshlet_create_clear_visibility_buffer_bind_group(
  backend : GpuBackend,
  visibility_buffer : @wgpu.Buffer,
  constants_buf : @wgpu.Buffer,
  bgl : @wgpu.BindGroupLayout,
) -> @wgpu.BindGroup? {
  let builder = @wgpu.BindGroupBuilder::new(max_entries=2UL)
  let ok = builder.add_buffer(0U, visibility_buffer) &&
    builder.add_buffer(1U, constants_buf)
  if !ok {
    builder.free()
    return None
  }
  Some(
    builder.finish(
      backend.device,
      bgl,
      label="mgstudio_meshlet_clear_visibility_buffer_bind_group",
    ),
  )
}

///|
fn meshlet_end_active_render_pass_for_compute(backend : GpuBackend) -> Bool {
  guard backend.frame is Some(frame) else { return false }
  if frame.pass is Some(pass) {
    render_pass_timing_end_active_pass()
    pass.end()
    pass.release()
    frame.pass = None
  }
  true
}

///|
pub fn GpuBackend::execute_meshlet_clear_visibility_buffer(
  self : GpuBackend,
  view_entity_bits~ : UInt64,
) -> Bool raise GpuBackendError {
  guard self.meshlet_view_visibility_buffers.get(view_entity_bits)
    is Some(view_resources) else {
    return false
  }
  if self.frame is None && self.active_surface_target_id < 0 {
    activate_surface_frame_for_target(self, self.active_surface_target_id)
    |> ignore
  }
  guard meshlet_end_active_render_pass_for_compute(self) else { return false }
  guard ensure_meshlet_clear_visibility_buffer_resources(self) else {
    return false
  }
  guard self.frame is Some(frame) else { return false }
  guard self.meshlet_clear_visibility_buffer_bgl is Some(bgl) else {
    return false
  }
  guard self.meshlet_clear_visibility_buffer_pipeline is Some(pipeline) else {
    return false
  }
  guard self.meshlet_clear_visibility_buffer_constants_buf
    is Some(constants_buf) else {
    return false
  }
  self.queue.write_buffer(
    constants_buf,
    0UL,
    u32le_pack([
      meshlet_positive_u32(view_resources.view_width),
      meshlet_positive_u32(view_resources.view_height),
      0U,
      0U,
    ]),
  )
  guard meshlet_create_clear_visibility_buffer_bind_group(
      self,
      view_resources.buffer,
      constants_buf,
      bgl,
    )
    is Some(bind_group) else {
    return false
  }
  let compute_pass = frame.encoder.begin_compute_pass()
  compute_pass.set_pipeline(pipeline)
  compute_pass.set_bind_group(0U, bind_group, [])
  compute_pass.dispatch_workgroups(
    meshlet_dispatch_group_count_16(view_resources.view_width),
    meshlet_dispatch_group_count_16(view_resources.view_height),
    1U,
  )
  compute_pass.end()
  compute_pass.release()
  bind_group.release()
  self.meshlet_clear_visibility_buffer_dispatch_count = self.meshlet_clear_visibility_buffer_dispatch_count +
    1
  true
}

///|
pub fn execute_meshlet_clear_visibility_buffer(
  view_entity_bits~ : UInt64,
) -> Bool {
  match ensure_backend() {
    Some(backend) =>
      backend.execute_meshlet_clear_visibility_buffer(view_entity_bits~) catch {
        err => {
          debug_runtime_error("execute_meshlet_clear_visibility_buffer", err)
          false
        }
      }
    None => false
  }
}

///|
pub fn meshlet_clear_visibility_buffer_dispatch_count() -> Int {
  match ensure_backend() {
    Some(backend) => backend.meshlet_clear_visibility_buffer_dispatch_count
    None => 0
  }
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
