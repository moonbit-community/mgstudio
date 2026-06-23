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
}

///|
pub fn RenderMeshQueueData::new(
  mesh_asset_id : Int,
  current_uniform_index : UInt,
  should_batch : Bool,
  flags? : RenderMeshInstanceFlags = RenderMeshInstanceFlags::empty(),
) -> RenderMeshQueueData {
  RenderMeshQueueData::{
    mesh_asset_id,
    current_uniform_index,
    should_batch,
    flags,
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
  queue_data : RenderMeshQueueData
}

///|
pub fn RenderMeshInstanceGpuBuilder::new(
  queue_data : RenderMeshQueueData,
) -> RenderMeshInstanceGpuBuilder {
  RenderMeshInstanceGpuBuilder::{ queue_data, }
}

///|
pub fn RenderMeshInstanceGpuBuilder::render_mesh_queue_data(
  self : RenderMeshInstanceGpuBuilder,
) -> RenderMeshQueueData {
  self.queue_data
}

///|
pub struct RenderMeshInstanceGpuPrepared {
  queue_data : RenderMeshQueueData
}

///|
pub fn RenderMeshInstanceGpuPrepared::new(
  queue_data : RenderMeshQueueData,
) -> RenderMeshInstanceGpuPrepared {
  RenderMeshInstanceGpuPrepared::{ queue_data, }
}

///|
pub fn RenderMeshInstanceGpuPrepared::render_mesh_queue_data(
  self : RenderMeshInstanceGpuPrepared,
) -> RenderMeshQueueData {
  self.queue_data
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
  entries : Map[UInt64, RenderMeshQueueData]
}

///|
pub fn RenderMeshInstancesCpu::RenderMeshInstancesCpu() -> RenderMeshInstancesCpu {
  RenderMeshInstancesCpu::{ entries: {} }
}

///|
pub struct RenderMeshInstancesGpu {
  entries : Map[UInt64, RenderMeshQueueData]
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
  self.entries.set(entity.id().to_bits(), data)
}

///|
pub fn RenderMeshInstancesCpu::remove(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  let key = entity.id().to_bits()
  let value = self.entries.get(key)
  self.entries.remove(key)
  value
}

///|
pub fn RenderMeshInstancesCpu::mesh_asset_id(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
) -> Int? {
  self.render_mesh_queue_data(entity).map(fn(data) { data.mesh_asset_id() })
}

///|
pub fn RenderMeshInstancesCpu::render_mesh_queue_data(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  self.entries.get(entity.id().to_bits())
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
  self.entries.set(entity.id().to_bits(), data)
}

///|
pub fn RenderMeshInstancesGpu::remove(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  let key = entity.id().to_bits()
  let value = self.entries.get(key)
  self.entries.remove(key)
  value
}

///|
pub fn RenderMeshInstancesGpu::mesh_asset_id(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
) -> Int? {
  self.render_mesh_queue_data(entity).map(fn(data) { data.mesh_asset_id() })
}

///|
pub fn RenderMeshInstancesGpu::render_mesh_queue_data(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
) -> RenderMeshQueueData? {
  self.entries.get(entity.id().to_bits())
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
