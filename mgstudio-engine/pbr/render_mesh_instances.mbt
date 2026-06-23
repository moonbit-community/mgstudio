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
// Bevy source: `bevy/crates/bevy_pbr/src/render/mesh.rs`.

///|
pub struct RenderMeshInstanceFlags {
  bits : UInt
} derive(Eq, Debug)

///|
pub fn RenderMeshInstanceFlags::empty() -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::{ bits: 0U }
}

///|
pub fn RenderMeshInstanceFlags::from_bits(
  bits : UInt,
) -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::{ bits, }
}

///|
pub fn RenderMeshInstanceFlags::bits(self : RenderMeshInstanceFlags) -> UInt {
  self.bits
}

///|
pub fn RenderMeshInstanceFlags::shadow_caster() -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::from_bits(1U << 0)
}

///|
pub fn RenderMeshInstanceFlags::automatic_batching() -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::from_bits(1U << 1)
}

///|
pub fn RenderMeshInstanceFlags::has_previous_transform() -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::from_bits(1U << 2)
}

///|
pub fn RenderMeshInstanceFlags::has_previous_skin() -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::from_bits(1U << 3)
}

///|
pub fn RenderMeshInstanceFlags::has_previous_morph() -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::from_bits(1U << 4)
}

///|
pub fn RenderMeshInstanceFlags::no_cpu_culling() -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::from_bits(1U << 5)
}

///|
pub fn RenderMeshInstanceFlags::contains(
  self : RenderMeshInstanceFlags,
  flag : RenderMeshInstanceFlags,
) -> Bool {
  (self.bits & flag.bits) == flag.bits
}

///|
pub fn RenderMeshInstanceFlags::or(
  self : RenderMeshInstanceFlags,
  flag : RenderMeshInstanceFlags,
) -> RenderMeshInstanceFlags {
  RenderMeshInstanceFlags::from_bits(self.bits | flag.bits)
}

///|
pub fn RenderMeshInstanceFlags::from_extraction_components(
  has_previous_transform : Bool,
  has_previous_skin : Bool,
  has_previous_morph : Bool,
  has_not_shadow_caster : Bool,
  has_no_automatic_batching : Bool,
  has_no_cpu_culling : Bool,
) -> RenderMeshInstanceFlags {
  let mut flags = RenderMeshInstanceFlags::empty()
  if !has_not_shadow_caster {
    flags = flags.or(RenderMeshInstanceFlags::shadow_caster())
  }
  if !has_no_automatic_batching {
    flags = flags.or(RenderMeshInstanceFlags::automatic_batching())
  }
  if has_previous_transform {
    flags = flags.or(RenderMeshInstanceFlags::has_previous_transform())
  }
  if has_previous_skin {
    flags = flags.or(RenderMeshInstanceFlags::has_previous_skin())
  }
  if has_previous_morph {
    flags = flags.or(RenderMeshInstanceFlags::has_previous_morph())
  }
  if has_no_cpu_culling {
    flags = flags.or(RenderMeshInstanceFlags::no_cpu_culling())
  }
  flags
}

///|
pub struct RenderMeshQueueData {
  mesh_asset_id : Int
  current_uniform_index : UInt
  should_batch : Bool
  flags : RenderMeshInstanceFlags
  render_layers : @camera_render_layers.RenderLayers?
}

///|
pub fn RenderMeshQueueData::new(
  mesh_asset_id : Int,
  current_uniform_index : UInt,
  should_batch : Bool,
  flags? : RenderMeshInstanceFlags = RenderMeshInstanceFlags::empty(),
  render_layers? : @camera_render_layers.RenderLayers? = None,
) -> RenderMeshQueueData {
  let flags = if should_batch {
    flags.or(RenderMeshInstanceFlags::automatic_batching())
  } else {
    flags
  }
  RenderMeshQueueData::{
    mesh_asset_id,
    current_uniform_index,
    should_batch,
    flags,
    render_layers,
  }
}

///|
pub fn RenderMeshQueueData::mesh_asset_id(self : RenderMeshQueueData) -> Int {
  self.mesh_asset_id
}

///|
pub fn RenderMeshQueueData::current_uniform_index(
  self : RenderMeshQueueData,
) -> UInt {
  self.current_uniform_index
}

///|
pub fn RenderMeshQueueData::should_batch(self : RenderMeshQueueData) -> Bool {
  self.should_batch
}

///|
pub fn RenderMeshQueueData::flags(
  self : RenderMeshQueueData,
) -> RenderMeshInstanceFlags {
  self.flags
}

///|
pub fn RenderMeshQueueData::render_layers(
  self : RenderMeshQueueData,
) -> @camera_render_layers.RenderLayers? {
  self.render_layers
}

///|
pub struct MeshTransforms {
  world_from_local : @math.Affine3
  previous_world_from_local : @math.Affine3
  flags : UInt
}

///|
pub fn MeshTransforms::new(
  world_from_local : @math.Affine3,
  previous_world_from_local : @math.Affine3,
  flags : UInt,
) -> MeshTransforms {
  MeshTransforms::{ world_from_local, previous_world_from_local, flags }
}

///|
pub fn MeshTransforms::world_from_local(self : MeshTransforms) -> @math.Affine3 {
  self.world_from_local
}

///|
pub fn MeshTransforms::previous_world_from_local(
  self : MeshTransforms,
) -> @math.Affine3 {
  self.previous_world_from_local
}

///|
pub fn MeshTransforms::flags(self : MeshTransforms) -> UInt {
  self.flags
}

///|
pub struct RenderMeshInstanceSharedFlat {
  mesh_asset_id : Int
  material_bindings_index : MaterialBindingId
  lightmap_slab_index : Int?
  tag : UInt
  current_uniform_index : UInt
  flags : RenderMeshInstanceFlags
}

///|
pub fn RenderMeshInstanceSharedFlat::new(
  mesh_asset_id : Int,
  material_bindings_index? : MaterialBindingId = MaterialBindingId::MaterialBindingId(),
  lightmap_slab_index? : Int? = None,
  tag? : UInt = 0U,
  current_uniform_index? : UInt = 0U,
  flags? : RenderMeshInstanceFlags = RenderMeshInstanceFlags::empty(),
) -> RenderMeshInstanceSharedFlat {
  RenderMeshInstanceSharedFlat::{
    mesh_asset_id,
    material_bindings_index,
    lightmap_slab_index,
    tag,
    current_uniform_index,
    flags,
  }
}

///|
pub fn RenderMeshInstanceSharedFlat::from_queue_data(
  data : RenderMeshQueueData,
) -> RenderMeshInstanceSharedFlat {
  RenderMeshInstanceSharedFlat::new(
    data.mesh_asset_id(),
    current_uniform_index=data.current_uniform_index(),
    flags=data.flags(),
  )
}

///|
pub fn RenderMeshInstanceSharedFlat::mesh_asset_id(
  self : RenderMeshInstanceSharedFlat,
) -> Int {
  self.mesh_asset_id
}

///|
pub fn RenderMeshInstanceSharedFlat::material_bindings_index(
  self : RenderMeshInstanceSharedFlat,
) -> MaterialBindingId {
  self.material_bindings_index
}

///|
pub fn RenderMeshInstanceSharedFlat::lightmap_slab_index(
  self : RenderMeshInstanceSharedFlat,
) -> Int? {
  self.lightmap_slab_index
}

///|
pub fn RenderMeshInstanceSharedFlat::tag(
  self : RenderMeshInstanceSharedFlat,
) -> UInt {
  self.tag
}

///|
pub fn RenderMeshInstanceSharedFlat::current_uniform_index(
  self : RenderMeshInstanceSharedFlat,
) -> UInt {
  self.current_uniform_index
}

///|
pub fn RenderMeshInstanceSharedFlat::flags(
  self : RenderMeshInstanceSharedFlat,
) -> RenderMeshInstanceFlags {
  self.flags
}

///|
pub fn RenderMeshInstanceSharedFlat::should_batch(
  self : RenderMeshInstanceSharedFlat,
) -> Bool {
  self.flags.contains(RenderMeshInstanceFlags::automatic_batching())
}

///|
pub fn RenderMeshInstanceSharedFlat::to_queue_data(
  self : RenderMeshInstanceSharedFlat,
  current_uniform_index? : UInt = self.current_uniform_index,
  render_layers? : @camera_render_layers.RenderLayers? = None,
) -> RenderMeshQueueData {
  RenderMeshQueueData::new(
    self.mesh_asset_id,
    current_uniform_index,
    self.should_batch(),
    flags=self.flags,
    render_layers~,
  )
}

///|
pub struct RenderMeshInstanceGpuFlat {
  current_uniform_index : UInt
}

///|
pub fn RenderMeshInstanceGpuFlat::RenderMeshInstanceGpuFlat(
  current_uniform_index? : UInt = 0U,
) -> RenderMeshInstanceGpuFlat {
  RenderMeshInstanceGpuFlat::{ current_uniform_index, }
}

///|
pub fn RenderMeshInstanceGpuFlat::current_uniform_index(
  self : RenderMeshInstanceGpuFlat,
) -> UInt {
  self.current_uniform_index
}

///|
pub struct RenderMeshInstanceCpu {
  shared : RenderMeshInstanceSharedFlat
  transforms : MeshTransforms?
  render_layers : @camera_render_layers.RenderLayers?
}

///|
pub fn RenderMeshInstanceCpu::new(
  shared : RenderMeshInstanceSharedFlat,
  transforms? : MeshTransforms? = None,
  render_layers? : @camera_render_layers.RenderLayers? = None,
) -> RenderMeshInstanceCpu {
  RenderMeshInstanceCpu::{ shared, transforms, render_layers }
}

///|
pub fn RenderMeshInstanceCpu::from_queue_data(
  data : RenderMeshQueueData,
) -> RenderMeshInstanceCpu {
  RenderMeshInstanceCpu::new(
    RenderMeshInstanceSharedFlat::from_queue_data(data),
    render_layers=data.render_layers(),
  )
}

///|
pub fn RenderMeshInstanceCpu::mesh_asset_id(
  self : RenderMeshInstanceCpu,
) -> Int {
  self.shared.mesh_asset_id()
}

///|
pub fn RenderMeshInstanceCpu::render_mesh_queue_data(
  self : RenderMeshInstanceCpu,
) -> RenderMeshQueueData {
  self.shared.to_queue_data(
    current_uniform_index=0U,
    render_layers=self.render_layers,
  )
}

///|
pub struct RenderMeshInstanceGpu {
  shared : RenderMeshInstanceSharedFlat
  gpu_specific : RenderMeshInstanceGpuFlat
  render_layers : @camera_render_layers.RenderLayers?
}

///|
pub fn RenderMeshInstanceGpu::new(
  shared : RenderMeshInstanceSharedFlat,
  gpu_specific? : RenderMeshInstanceGpuFlat = RenderMeshInstanceGpuFlat::RenderMeshInstanceGpuFlat(),
  render_layers? : @camera_render_layers.RenderLayers? = None,
) -> RenderMeshInstanceGpu {
  RenderMeshInstanceGpu::{ shared, gpu_specific, render_layers }
}

///|
pub fn RenderMeshInstanceGpu::from_queue_data(
  data : RenderMeshQueueData,
) -> RenderMeshInstanceGpu {
  RenderMeshInstanceGpu::new(
    RenderMeshInstanceSharedFlat::from_queue_data(data),
    gpu_specific=RenderMeshInstanceGpuFlat::RenderMeshInstanceGpuFlat(
      current_uniform_index=data.current_uniform_index(),
    ),
    render_layers=data.render_layers(),
  )
}

///|
pub fn RenderMeshInstanceGpu::mesh_asset_id(
  self : RenderMeshInstanceGpu,
) -> Int {
  self.shared.mesh_asset_id()
}

///|
pub fn RenderMeshInstanceGpu::render_mesh_queue_data(
  self : RenderMeshInstanceGpu,
) -> RenderMeshQueueData {
  self.shared.to_queue_data(
    current_uniform_index=self.gpu_specific.current_uniform_index(),
    render_layers=self.render_layers,
  )
}

///|
pub struct MeshInputUniform {
  world_from_local : @math.Affine3
  lightmap_uv_rect : @math.UVec2
  flags : UInt
  previous_input_index : UInt
  timestamp : UInt
  first_vertex_index : UInt
  first_index_index : UInt
  index_count : UInt
  current_skin_index : UInt
  material_and_lightmap_bind_group_slot : UInt
  tag : UInt
  morph_descriptor_index : UInt
}

///|
fn mesh_input_uniform_invalid_index() -> UInt {
  0xFFFF_FFFFU
}

///|
pub fn MeshInputUniform::new(
  world_from_local? : @math.Affine3 = @math.Affine3::identity(),
  lightmap_uv_rect? : @math.UVec2 = @math.UVec2::zero(),
  flags? : UInt = 0U,
  previous_input_index? : UInt = mesh_input_uniform_invalid_index(),
  timestamp? : UInt = 0U,
  first_vertex_index? : UInt = 0U,
  first_index_index? : UInt = 0U,
  index_count? : UInt = 0U,
  current_skin_index? : UInt = mesh_input_uniform_invalid_index(),
  material_and_lightmap_bind_group_slot? : UInt = 0U,
  tag? : UInt = 0U,
  morph_descriptor_index? : UInt = mesh_input_uniform_invalid_index(),
) -> MeshInputUniform {
  MeshInputUniform::{
    world_from_local,
    lightmap_uv_rect,
    flags,
    previous_input_index,
    timestamp,
    first_vertex_index,
    first_index_index,
    index_count,
    current_skin_index,
    material_and_lightmap_bind_group_slot,
    tag,
    morph_descriptor_index,
  }
}

///|
pub fn MeshInputUniform::from_shared(
  shared : RenderMeshInstanceSharedFlat,
  world_from_local? : @math.Affine3 = @math.Affine3::identity(),
  lightmap_uv_rect? : @math.UVec2 = @math.UVec2::zero(),
  flags? : UInt = 0U,
  timestamp? : UInt = 0U,
) -> MeshInputUniform {
  MeshInputUniform::new(
    world_from_local~,
    lightmap_uv_rect~,
    flags~,
    timestamp~,
    tag=shared.tag(),
  )
}

///|
pub fn MeshInputUniform::previous_input_index(self : MeshInputUniform) -> UInt {
  self.previous_input_index
}

///|
pub fn MeshInputUniform::tag(self : MeshInputUniform) -> UInt {
  self.tag
}

///|
pub fn MeshInputUniform::with_previous_input_index(
  self : MeshInputUniform,
  previous_input_index : UInt,
) -> MeshInputUniform {
  MeshInputUniform::{ ..self, previous_input_index, }
}

///|
pub struct MeshCullingData {
  aabb_center : @math.Vec4
  aabb_half_extents : @math.Vec4
} derive(Eq)

///|
pub fn MeshCullingData::new(aabb : @camera_primitives.Aabb?) -> MeshCullingData {
  match aabb {
    Some(aabb) => {
      let center = aabb.center()
      let half_extents = aabb.half_size()
      MeshCullingData::{
        aabb_center: @math.Vec4::new(center.x, center.y, center.z, 0.0F),
        aabb_half_extents: @math.Vec4::new(
          half_extents.x,
          half_extents.y,
          half_extents.z,
          0.0F,
        ),
      }
    }
    None => {
      let infinity = 1.0F / 0.0F
      MeshCullingData::{
        aabb_center: @math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F),
        aabb_half_extents: @math.Vec4::new(infinity, infinity, infinity, 0.0F),
      }
    }
  }
}

///|
pub fn MeshCullingData::aabb_center(self : MeshCullingData) -> @math.Vec4 {
  self.aabb_center
}

///|
pub fn MeshCullingData::aabb_half_extents(self : MeshCullingData) -> @math.Vec4 {
  self.aabb_half_extents
}

///|
pub struct RenderMeshInstanceGpuBuilder {
  shared : RenderMeshInstanceSharedFlat
  world_from_local : @math.Affine3
  lightmap_uv_rect : @math.UVec2
  previous_input_index : UInt?
  render_layers : @camera_render_layers.RenderLayers?
  mesh_flags : UInt
}

///|
pub fn RenderMeshInstanceGpuBuilder::new(
  queue_data : RenderMeshQueueData,
) -> RenderMeshInstanceGpuBuilder {
  RenderMeshInstanceGpuBuilder::{
    shared: RenderMeshInstanceSharedFlat::from_queue_data(queue_data),
    world_from_local: @math.Affine3::identity(),
    lightmap_uv_rect: @math.UVec2::zero(),
    previous_input_index: None,
    render_layers: queue_data.render_layers(),
    mesh_flags: 0U,
  }
}

///|
pub fn RenderMeshInstanceGpuBuilder::from_shared(
  shared : RenderMeshInstanceSharedFlat,
  world_from_local : @math.Affine3,
  lightmap_uv_rect : @math.UVec2,
  previous_input_index : UInt?,
  render_layers : @camera_render_layers.RenderLayers?,
  mesh_flags : UInt,
) -> RenderMeshInstanceGpuBuilder {
  RenderMeshInstanceGpuBuilder::{
    shared,
    world_from_local,
    lightmap_uv_rect,
    previous_input_index,
    render_layers,
    mesh_flags,
  }
}

///|
pub fn RenderMeshInstanceGpuBuilder::render_mesh_queue_data(
  self : RenderMeshInstanceGpuBuilder,
) -> RenderMeshQueueData {
  self.shared.to_queue_data(render_layers=self.render_layers)
}

///|
pub fn RenderMeshInstanceGpuBuilder::shared(
  self : RenderMeshInstanceGpuBuilder,
) -> RenderMeshInstanceSharedFlat {
  self.shared
}

///|
pub struct RenderMeshInstanceGpuPrepared {
  shared : RenderMeshInstanceSharedFlat
  mesh_input_uniform : MeshInputUniform
  render_layers : @camera_render_layers.RenderLayers?
}

///|
pub fn RenderMeshInstanceGpuPrepared::new(
  queue_data : RenderMeshQueueData,
) -> RenderMeshInstanceGpuPrepared {
  let shared = RenderMeshInstanceSharedFlat::from_queue_data(queue_data)
  RenderMeshInstanceGpuPrepared::{
    shared,
    mesh_input_uniform: MeshInputUniform::from_shared(shared),
    render_layers: queue_data.render_layers(),
  }
}

///|
pub fn RenderMeshInstanceGpuPrepared::from_shared(
  shared : RenderMeshInstanceSharedFlat,
  mesh_input_uniform : MeshInputUniform,
  render_layers : @camera_render_layers.RenderLayers?,
) -> RenderMeshInstanceGpuPrepared {
  RenderMeshInstanceGpuPrepared::{ shared, mesh_input_uniform, render_layers }
}

///|
pub fn RenderMeshInstanceGpuPrepared::render_mesh_queue_data(
  self : RenderMeshInstanceGpuPrepared,
) -> RenderMeshQueueData {
  self.shared.to_queue_data(render_layers=self.render_layers)
}

///|
pub fn RenderMeshInstanceGpuPrepared::mesh_input_uniform(
  self : RenderMeshInstanceGpuPrepared,
) -> MeshInputUniform {
  self.mesh_input_uniform
}

///|
pub fn RenderMeshInstanceGpuPrepared::update(
  self : RenderMeshInstanceGpuPrepared,
  entity : @render.MainEntity,
  render_mesh_instances : RenderMeshInstancesGpu,
  current_input_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ],
  previous_input_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ],
) -> UInt {
  let key = entity.id().to_bits()
  let current_uniform_index = match render_mesh_instances.entries.get(key) {
    Some(existing_instance) => {
      let index = existing_instance.gpu_specific.current_uniform_index()
      let previous_mesh_input_uniform = current_input_buffer.get_unchecked(
        index.reinterpret_as_int(),
      )
      let previous_input_index = previous_input_buffer
        .add(previous_mesh_input_uniform)
        .reinterpret_as_uint()
      current_input_buffer.set(
        index.reinterpret_as_int(),
        self.mesh_input_uniform.with_previous_input_index(previous_input_index),
      )
      index
    }
    None =>
      current_input_buffer.add(self.mesh_input_uniform).reinterpret_as_uint()
  }
  render_mesh_instances.entries.set(
    key,
    RenderMeshInstanceGpu::new(
      self.shared,
      gpu_specific=RenderMeshInstanceGpuFlat::RenderMeshInstanceGpuFlat(
        current_uniform_index~,
      ),
      render_layers=self.render_layers,
    ),
  )
  current_uniform_index
}

///|
pub fn remove_mesh_input_uniform(
  entity : @render.MainEntity,
  render_mesh_instances : RenderMeshInstancesGpu,
  current_input_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ],
) -> UInt? {
  let key = entity.id().to_bits()
  let removed_instance = render_mesh_instances.entries.get(key)
  render_mesh_instances.entries.remove(key)
  match removed_instance {
    Some(instance) => {
      let removed_uniform_index = instance.gpu_specific.current_uniform_index()
      current_input_buffer.remove(removed_uniform_index.reinterpret_as_int())
      Some(removed_uniform_index)
    }
    None => None
  }
}

///|
pub struct RenderMeshInstanceGpuCpuCullingQueue {
  changed : Array[(@render.MainEntity, RenderMeshInstanceGpuBuilder)]
  removed : Array[@render.MainEntity]
}

///|
pub fn RenderMeshInstanceGpuCpuCullingQueue::RenderMeshInstanceGpuCpuCullingQueue() -> RenderMeshInstanceGpuCpuCullingQueue {
  RenderMeshInstanceGpuCpuCullingQueue::{ changed: [], removed: [] }
}

///|
pub struct RenderMeshInstanceGpuGpuCullingQueue {
  changed_cpu_culling : Array[
    (@render.MainEntity, RenderMeshInstanceGpuBuilder, MeshCullingData),
  ]
  changed_gpu_culling : Array[
    (@render.MainEntity, RenderMeshInstanceGpuBuilder, MeshCullingData),
  ]
  removed : Array[@render.MainEntity]
}

///|
pub fn RenderMeshInstanceGpuGpuCullingQueue::RenderMeshInstanceGpuGpuCullingQueue() -> RenderMeshInstanceGpuGpuCullingQueue {
  RenderMeshInstanceGpuGpuCullingQueue::{
    changed_cpu_culling: [],
    changed_gpu_culling: [],
    removed: [],
  }
}

///|
pub enum RenderMeshInstanceGpuQueueState {
  NoQueue
  CpuCulling(RenderMeshInstanceGpuCpuCullingQueue)
  GpuCulling(RenderMeshInstanceGpuGpuCullingQueue)
}

///|
pub struct RenderMeshInstanceGpuQueue {
  mut state : RenderMeshInstanceGpuQueueState
}

///|
pub fn RenderMeshInstanceGpuQueue::RenderMeshInstanceGpuQueue() -> RenderMeshInstanceGpuQueue {
  RenderMeshInstanceGpuQueue::{ state: NoQueue }
}

///|
pub fn RenderMeshInstanceGpuQueue::state(
  self : RenderMeshInstanceGpuQueue,
) -> RenderMeshInstanceGpuQueueState {
  self.state
}

///|
pub fn RenderMeshInstanceGpuQueue::init(
  self : RenderMeshInstanceGpuQueue,
  any_gpu_culling : Bool,
) -> Unit {
  match (any_gpu_culling, self.state) {
    (true, GpuCulling(queue)) => {
      queue.changed_cpu_culling.clear()
      queue.changed_gpu_culling.clear()
      queue.removed.clear()
    }
    (true, _) =>
      self.state = GpuCulling(
        RenderMeshInstanceGpuGpuCullingQueue::RenderMeshInstanceGpuGpuCullingQueue(),
      )
    (false, CpuCulling(queue)) => {
      queue.changed.clear()
      queue.removed.clear()
    }
    (false, _) =>
      self.state = CpuCulling(
        RenderMeshInstanceGpuCpuCullingQueue::RenderMeshInstanceGpuCpuCullingQueue(),
      )
  }
}

///|
pub fn RenderMeshInstanceGpuQueue::push(
  self : RenderMeshInstanceGpuQueue,
  entity : @render.MainEntity,
  instance_builder : RenderMeshInstanceGpuBuilder,
  culling_data_builder : MeshCullingData?,
  no_cpu_culling : Bool,
) -> Unit {
  match (self.state, culling_data_builder, no_cpu_culling) {
    (CpuCulling(queue), None, _) =>
      queue.changed.push((entity, instance_builder))
    (GpuCulling(queue), Some(culling_data_builder), false) =>
      queue.changed_cpu_culling.push(
        (entity, instance_builder, culling_data_builder),
      )
    (GpuCulling(queue), Some(culling_data_builder), true) =>
      queue.changed_gpu_culling.push(
        (entity, instance_builder, culling_data_builder),
      )
    (_, None, _) => {
      let queue = RenderMeshInstanceGpuCpuCullingQueue::RenderMeshInstanceGpuCpuCullingQueue()
      queue.changed.push((entity, instance_builder))
      self.state = CpuCulling(queue)
    }
    (_, Some(culling_data_builder), false) => {
      let queue = RenderMeshInstanceGpuGpuCullingQueue::RenderMeshInstanceGpuGpuCullingQueue()
      queue.changed_cpu_culling.push(
        (entity, instance_builder, culling_data_builder),
      )
      self.state = GpuCulling(queue)
    }
    (_, Some(culling_data_builder), true) => {
      let queue = RenderMeshInstanceGpuGpuCullingQueue::RenderMeshInstanceGpuGpuCullingQueue()
      queue.changed_gpu_culling.push(
        (entity, instance_builder, culling_data_builder),
      )
      self.state = GpuCulling(queue)
    }
  }
}

///|
pub fn RenderMeshInstanceGpuQueue::remove(
  self : RenderMeshInstanceGpuQueue,
  entity : @render.MainEntity,
  gpu_culling : Bool,
) -> Unit {
  match (self.state, gpu_culling) {
    (NoQueue, false) => {
      let queue = RenderMeshInstanceGpuCpuCullingQueue::RenderMeshInstanceGpuCpuCullingQueue()
      queue.removed.push(entity)
      self.state = CpuCulling(queue)
    }
    (NoQueue, true) => {
      let queue = RenderMeshInstanceGpuGpuCullingQueue::RenderMeshInstanceGpuGpuCullingQueue()
      queue.removed.push(entity)
      self.state = GpuCulling(queue)
    }
    (CpuCulling(queue), _) => queue.removed.push(entity)
    (GpuCulling(queue), _) => queue.removed.push(entity)
  }
}

///|
pub fn RenderMeshInstanceGpuQueue::changed_len(
  self : RenderMeshInstanceGpuQueue,
) -> Int {
  match self.state {
    NoQueue => 0
    CpuCulling(queue) => queue.changed.length()
    GpuCulling(queue) =>
      queue.changed_cpu_culling.length() + queue.changed_gpu_culling.length()
  }
}

///|
pub fn RenderMeshInstanceGpuQueue::removed_len(
  self : RenderMeshInstanceGpuQueue,
) -> Int {
  match self.state {
    NoQueue => 0
    CpuCulling(queue) => queue.removed.length()
    GpuCulling(queue) => queue.removed.length()
  }
}

///|
pub fn RenderMeshInstanceGpuQueue::gpu_changed_cpu_culling_len(
  self : RenderMeshInstanceGpuQueue,
) -> Int {
  match self.state {
    GpuCulling(queue) => queue.changed_cpu_culling.length()
    _ => 0
  }
}

///|
pub fn RenderMeshInstanceGpuQueue::gpu_changed_gpu_culling_len(
  self : RenderMeshInstanceGpuQueue,
) -> Int {
  match self.state {
    GpuCulling(queue) => queue.changed_gpu_culling.length()
    _ => 0
  }
}

///|
pub struct RenderMeshInstanceGpuQueues {
  queues : Array[RenderMeshInstanceGpuQueue]
}

///|
pub fn RenderMeshInstanceGpuQueues::RenderMeshInstanceGpuQueues() -> RenderMeshInstanceGpuQueues {
  RenderMeshInstanceGpuQueues::{
    queues: [RenderMeshInstanceGpuQueue::RenderMeshInstanceGpuQueue()],
  }
}

///|
pub let ecs_key_render_mesh_instance_gpu_queues : @ecs.ResourceKey[
  RenderMeshInstanceGpuQueues,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::RenderMeshInstanceGpuQueues",
)

///|
pub impl @app.Resource for RenderMeshInstanceGpuQueues with fn resource() {
  ecs_key_render_mesh_instance_gpu_queues
}

///|
pub fn RenderMeshInstanceGpuQueues::iter(
  self : RenderMeshInstanceGpuQueues,
) -> Array[RenderMeshInstanceGpuQueue] {
  self.queues
}

///|
pub fn RenderMeshInstanceGpuQueues::borrow_local_mut(
  self : RenderMeshInstanceGpuQueues,
) -> RenderMeshInstanceGpuQueue {
  if self.queues.is_empty() {
    self.queues.push(RenderMeshInstanceGpuQueue::RenderMeshInstanceGpuQueue())
  }
  self.queues[0]
}

///|
pub fn RenderMeshInstanceGpuQueues::init(
  self : RenderMeshInstanceGpuQueues,
  any_gpu_culling : Bool,
) -> Unit {
  for queue in self.queues {
    queue.init(any_gpu_culling)
  }
}

///|
pub struct MeshesToReextractNextFrame {
  entries : Map[UInt64, @render.MainEntity]
}

///|
pub fn MeshesToReextractNextFrame::MeshesToReextractNextFrame() -> MeshesToReextractNextFrame {
  MeshesToReextractNextFrame::{ entries: {} }
}

///|
pub let ecs_key_meshes_to_reextract_next_frame : @ecs.ResourceKey[
  MeshesToReextractNextFrame,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::MeshesToReextractNextFrame",
)

///|
pub impl @app.Resource for MeshesToReextractNextFrame with fn resource() {
  ecs_key_meshes_to_reextract_next_frame
}

///|
pub fn MeshesToReextractNextFrame::insert(
  self : MeshesToReextractNextFrame,
  entity : @render.MainEntity,
) -> Unit {
  self.entries.set(entity.id().to_bits(), entity)
}

///|
pub fn MeshesToReextractNextFrame::extend(
  self : MeshesToReextractNextFrame,
  entities : Array[@render.MainEntity],
) -> Unit {
  for entity in entities {
    self.insert(entity)
  }
}

///|
pub fn MeshesToReextractNextFrame::contains(
  self : MeshesToReextractNextFrame,
  entity : @render.MainEntity,
) -> Bool {
  self.entries.contains(entity.id().to_bits())
}

///|
pub fn MeshesToReextractNextFrame::len(
  self : MeshesToReextractNextFrame,
) -> Int {
  self.entries.length()
}

///|
pub fn MeshesToReextractNextFrame::clear(
  self : MeshesToReextractNextFrame,
) -> Unit {
  self.entries.clear()
}

///|
pub fn MeshesToReextractNextFrame::entities(
  self : MeshesToReextractNextFrame,
) -> Array[@render.MainEntity] {
  let out : Array[@render.MainEntity] = []
  self.entries.each(fn(_, entity) { out.push(entity) })
  out
}

///|
pub struct RenderMeshInstancesCpu {
  entries : Map[UInt64, RenderMeshInstanceCpu]
}

///|
pub fn RenderMeshInstancesCpu::RenderMeshInstancesCpu() -> RenderMeshInstancesCpu {
  RenderMeshInstancesCpu::{ entries: {} }
}

///|
pub struct RenderMeshInstancesGpu {
  entries : Map[UInt64, RenderMeshInstanceGpu]
}

///|
pub fn RenderMeshInstancesGpu::RenderMeshInstancesGpu() -> RenderMeshInstancesGpu {
  RenderMeshInstancesGpu::{ entries: {} }
}

///|
pub enum RenderMeshInstances {
  CpuBuilding(RenderMeshInstancesCpu)
  GpuBuilding(RenderMeshInstancesGpu)
}

///|
pub fn RenderMeshInstances::new(
  use_gpu_instance_buffer_builder? : Bool = false,
) -> RenderMeshInstances {
  if use_gpu_instance_buffer_builder {
    GpuBuilding(RenderMeshInstancesGpu::RenderMeshInstancesGpu())
  } else {
    CpuBuilding(RenderMeshInstancesCpu::RenderMeshInstancesCpu())
  }
}

///|
pub let ecs_key_render_mesh_instances : @ecs.ResourceKey[RenderMeshInstances] = @ecs.register_resource(
  debug_name="mgstudio_pbr::RenderMeshInstances",
)

///|
pub impl @app.Resource for RenderMeshInstances with fn resource() {
  ecs_key_render_mesh_instances
}

///|
pub fn RenderMeshInstancesCpu::len(self : RenderMeshInstancesCpu) -> Int {
  self.entries.length()
}

///|
pub fn RenderMeshInstancesCpu::clear(self : RenderMeshInstancesCpu) -> Unit {
  self.entries.clear()
}

///|
pub fn RenderMeshInstancesCpu::keys(
  self : RenderMeshInstancesCpu,
) -> Array[@render.MainEntity] {
  let out : Array[@render.MainEntity] = []
  self.entries.each(fn(bits, _) {
    out.push(@render.MainEntity::new(@core.Entity::from_bits(bits)))
  })
  out
}

///|
pub fn RenderMeshInstancesCpu::insert(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
  data : RenderMeshQueueData,
) -> Unit {
  self.entries.set(
    entity.id().to_bits(),
    RenderMeshInstanceCpu::from_queue_data(data),
  )
}

///|
pub fn RenderMeshInstancesCpu::remove(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  let key = entity.id().to_bits()
  let value = self.entries.get(key)
  self.entries.remove(key)
  value.map(fn(instance) { instance.render_mesh_queue_data() })
}

///|
pub fn RenderMeshInstancesCpu::mesh_asset_id(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
) -> Int? {
  self.entries
  .get(entity.id().to_bits())
  .map(fn(instance) { instance.mesh_asset_id() })
}

///|
pub fn RenderMeshInstancesCpu::render_mesh_queue_data(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  self.entries
  .get(entity.id().to_bits())
  .map(fn(instance) { instance.render_mesh_queue_data() })
}

///|
pub fn RenderMeshInstancesGpu::len(self : RenderMeshInstancesGpu) -> Int {
  self.entries.length()
}

///|
pub fn RenderMeshInstancesGpu::clear(self : RenderMeshInstancesGpu) -> Unit {
  self.entries.clear()
}

///|
pub fn RenderMeshInstancesGpu::keys(
  self : RenderMeshInstancesGpu,
) -> Array[@render.MainEntity] {
  let out : Array[@render.MainEntity] = []
  self.entries.each(fn(bits, _) {
    out.push(@render.MainEntity::new(@core.Entity::from_bits(bits)))
  })
  out
}

///|
pub fn RenderMeshInstancesGpu::insert(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
  data : RenderMeshQueueData,
) -> Unit {
  self.entries.set(
    entity.id().to_bits(),
    RenderMeshInstanceGpu::from_queue_data(data),
  )
}

///|
pub fn RenderMeshInstancesGpu::remove(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  let key = entity.id().to_bits()
  let value = self.entries.get(key)
  self.entries.remove(key)
  value.map(fn(instance) { instance.render_mesh_queue_data() })
}

///|
pub fn RenderMeshInstancesGpu::mesh_asset_id(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
) -> Int? {
  self.entries
  .get(entity.id().to_bits())
  .map(fn(instance) { instance.mesh_asset_id() })
}

///|
pub fn RenderMeshInstancesGpu::render_mesh_queue_data(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  self.entries
  .get(entity.id().to_bits())
  .map(fn(instance) { instance.render_mesh_queue_data() })
}

///|
pub fn RenderMeshInstances::len(self : RenderMeshInstances) -> Int {
  match self {
    CpuBuilding(instances) => instances.len()
    GpuBuilding(instances) => instances.len()
  }
}

///|
pub fn RenderMeshInstances::clear(self : RenderMeshInstances) -> Unit {
  match self {
    CpuBuilding(instances) => instances.clear()
    GpuBuilding(instances) => instances.clear()
  }
}

///|
pub fn RenderMeshInstances::keys(
  self : RenderMeshInstances,
) -> Array[@render.MainEntity] {
  match self {
    CpuBuilding(instances) => instances.keys()
    GpuBuilding(instances) => instances.keys()
  }
}

///|
pub fn RenderMeshInstances::insert(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
  data : RenderMeshQueueData,
) -> Unit {
  match self {
    CpuBuilding(instances) => instances.insert(entity, data)
    GpuBuilding(instances) => instances.insert(entity, data)
  }
}

///|
pub fn RenderMeshInstances::remove(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  match self {
    CpuBuilding(instances) => instances.remove(entity)
    GpuBuilding(instances) => instances.remove(entity)
  }
}

///|
pub fn RenderMeshInstances::mesh_asset_id(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
) -> Int? {
  match self {
    CpuBuilding(instances) => instances.mesh_asset_id(entity)
    GpuBuilding(instances) => instances.mesh_asset_id(entity)
  }
}

///|
pub fn RenderMeshInstances::render_mesh_queue_data(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  match self {
    CpuBuilding(instances) => instances.render_mesh_queue_data(entity)
    GpuBuilding(instances) => instances.render_mesh_queue_data(entity)
  }
}

///|
pub fn mark_all_meshes_for_reextraction(
  render_mesh_instances : RenderMeshInstances,
  meshes_to_reextract : MeshesToReextractNextFrame,
) -> Unit {
  meshes_to_reextract.extend(render_mesh_instances.keys())
  render_mesh_instances.clear()
}

///|
fn render_mesh_queue_data_for_cpu_building(
  mesh : Mesh3dExtractedPayload,
) -> RenderMeshQueueData {
  let flags = RenderMeshInstanceFlags::from_extraction_components(
    mesh.has_previous_transform,
    mesh.has_previous_skin,
    mesh.has_previous_morph,
    mesh.has_not_shadow_caster,
    mesh.has_no_automatic_batching,
    false,
  )
  RenderMeshQueueData::new(
    mesh.mesh_id,
    0U,
    flags.contains(RenderMeshInstanceFlags::automatic_batching()),
    flags~,
  )
}

///|
fn render_mesh_instances_for_cpu_building(
  meshes : Array[ExtractedMesh3d],
) -> RenderMeshInstances {
  let instances = RenderMeshInstances::new()
  for mesh in meshes {
    let payload = mesh.payload
    if payload.mesh_id <= 0 {
      continue
    }
    instances.insert(
      @render.MainEntity::new(mesh.entity.main_entity),
      render_mesh_queue_data_for_cpu_building(payload),
    )
  }
  instances
}

///|
fn render_mesh_instances_update_cpu_building_resource(
  world : @ecs.World,
  meshes : Array[ExtractedMesh3d],
) -> Unit {
  world.insert_resource(
    RenderMeshInstances::resource(),
    render_mesh_instances_for_cpu_building(meshes),
  )
}

///|
fn render_mesh_instances_remove_cpu_building_resource(
  world : @ecs.World,
) -> Unit {
  ignore(world.remove_resource(RenderMeshInstances::resource()))
}
