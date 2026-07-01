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
pub struct MeshCullingDataBuffer {
  data : Array[MeshCullingData]
}

///|
pub fn MeshCullingDataBuffer::MeshCullingDataBuffer() -> MeshCullingDataBuffer {
  MeshCullingDataBuffer::{ data: [] }
}

///|
pub fn MeshCullingDataBuffer::len(self : MeshCullingDataBuffer) -> Int {
  self.data.length()
}

///|
pub fn MeshCullingDataBuffer::grow(
  self : MeshCullingDataBuffer,
  len : UInt,
) -> Unit {
  let target = len.reinterpret_as_int()
  while self.data.length() < target {
    self.data.push(MeshCullingData::new(None))
  }
}

///|
pub fn MeshCullingDataBuffer::set(
  self : MeshCullingDataBuffer,
  index : UInt,
  data : MeshCullingData,
) -> Unit {
  let int_index = index.reinterpret_as_int()
  self.grow((int_index + 1).reinterpret_as_uint())
  self.data[int_index] = data
}

///|
pub fn MeshCullingDataBuffer::get(
  self : MeshCullingDataBuffer,
  index : UInt,
) -> MeshCullingData? {
  let int_index = index.reinterpret_as_int()
  if int_index < 0 || int_index >= self.data.length() {
    None
  } else {
    Some(self.data[int_index])
  }
}

///|
pub let ecs_key_mesh_culling_data_buffer : @ecs.ResourceKey[
  MeshCullingDataBuffer,
] = @ecs.register_resource(debug_name="mgstudio_pbr::MeshCullingDataBuffer")

///|
pub impl @app.Resource for MeshCullingDataBuffer with fn resource() {
  ecs_key_mesh_culling_data_buffer
}

///|
pub fn MeshCullingData::update(
  self : MeshCullingData,
  mesh_culling_data_buffer : MeshCullingDataBuffer,
  instance_data_index : UInt,
) -> Unit {
  mesh_culling_data_buffer.set(instance_data_index, self)
}

///|
pub struct RenderGpuCulledEntities {
  entities : Map[UInt64, @camera_render_layers.RenderLayers]
  added : Array[@render.MainEntity]
  removed : Array[@render.MainEntity]
  changed_layers : Array[@render.MainEntity]
}

///|
pub fn RenderGpuCulledEntities::RenderGpuCulledEntities() -> RenderGpuCulledEntities {
  RenderGpuCulledEntities::{
    entities: {},
    added: [],
    removed: [],
    changed_layers: [],
  }
}

///|
pub let ecs_key_render_gpu_culled_entities : @ecs.ResourceKey[
  RenderGpuCulledEntities,
] = @ecs.register_resource(debug_name="mgstudio_pbr::RenderGpuCulledEntities")

///|
pub impl @app.Resource for RenderGpuCulledEntities with fn resource() {
  ecs_key_render_gpu_culled_entities
}

///|
pub fn RenderGpuCulledEntities::prepare_for_new_frame(
  self : RenderGpuCulledEntities,
) -> Unit {
  self.added.clear()
  self.removed.clear()
  self.changed_layers.clear()
}

///|
pub fn RenderGpuCulledEntities::update(
  self : RenderGpuCulledEntities,
  new_entity : @render.MainEntity,
  render_layers : @camera_render_layers.RenderLayers,
  no_cpu_culling : Bool,
) -> Unit {
  let key = new_entity.id().to_bits()
  if self.entities.contains(key) {
    if no_cpu_culling {
      self.entities.set(key, render_layers)
    } else {
      self.entities.remove(key)
      self.removed.push(new_entity)
    }
  } else if no_cpu_culling {
    self.entities.set(key, render_layers)
    self.added.push(new_entity)
  }
}

///|
pub fn RenderGpuCulledEntities::remove(
  self : RenderGpuCulledEntities,
  old_entity : @render.MainEntity,
) -> Unit {
  self.removed.push(old_entity)
  self.entities.remove(old_entity.id().to_bits())
}

///|
pub fn RenderGpuCulledEntities::contains(
  self : RenderGpuCulledEntities,
  entity : @render.MainEntity,
) -> Bool {
  self.entities.contains(entity.id().to_bits())
}

///|
pub fn RenderGpuCulledEntities::added_len(
  self : RenderGpuCulledEntities,
) -> Int {
  self.added.length()
}

///|
pub fn RenderGpuCulledEntities::removed_len(
  self : RenderGpuCulledEntities,
) -> Int {
  self.removed.length()
}

///|
fn render_gpu_culled_entity_layers_match(
  view_render_layers : @camera_render_layers.RenderLayers?,
  entity_render_layers : @camera_render_layers.RenderLayers?,
) -> Bool {
  match (view_render_layers, entity_render_layers) {
    (Some(view_layers), Some(entity_layers)) =>
      view_layers.matches(entity_layers)
    _ => true
  }
}

///|
fn render_mesh_instances_collect_gpu_culled_meshes_for_subview(
  view_render_layers : @camera_render_layers.RenderLayers?,
  render_visible_entities : @render_visibility.RenderVisibleEntities,
  render_gpu_culled_entities : RenderGpuCulledEntities,
) -> Unit {
  let render_view_visible_mesh_entities = render_visible_entities.class_or_insert(
    @mesh.ecs_key_mesh3d.id().to_string(),
  )
  for main_entity in render_gpu_culled_entities.removed {
    match
      render_view_visible_mesh_entities.remove_gpu_culled_entity(main_entity) {
      Some(_) =>
        render_view_visible_mesh_entities
        .removed_entities()
        .push((@core.Entity::placeholder(), main_entity))
      None => ()
    }
  }
  let mut any_added = false
  for main_entity in render_gpu_culled_entities.added {
    let entity_layers = render_gpu_culled_entities.entities.get(
      main_entity.id().to_bits(),
    )
    if !render_gpu_culled_entity_layers_match(view_render_layers, entity_layers) {
      continue
    }
    render_view_visible_mesh_entities.insert_gpu_culled_entity(
      main_entity,
      @core.Entity::placeholder(),
    )
    render_view_visible_mesh_entities.add_entity(
      (@core.Entity::placeholder(), main_entity),
    )
    any_added = true
  }
  for main_entity in render_gpu_culled_entities.changed_layers {
    let entity_layers = match
      render_gpu_culled_entities.entities.get(main_entity.id().to_bits()) {
      Some(value) => value
      None => continue
    }
    let entity_was_visible = render_view_visible_mesh_entities.gpu_culled_entity_is_visible(
      main_entity,
    )
    let entity_is_visible = render_gpu_culled_entity_layers_match(
      view_render_layers,
      Some(entity_layers),
    )
    match (entity_was_visible, entity_is_visible) {
      (false, false) | (true, true) => ()
      (false, true) => {
        render_view_visible_mesh_entities.insert_gpu_culled_entity(
          main_entity,
          @core.Entity::placeholder(),
        )
        render_view_visible_mesh_entities.add_entity(
          (@core.Entity::placeholder(), main_entity),
        )
        any_added = true
      }
      (true, false) =>
        match
          render_view_visible_mesh_entities.remove_gpu_culled_entity(
            main_entity,
          ) {
          Some(_) =>
            render_view_visible_mesh_entities
            .removed_entities()
            .push((@core.Entity::placeholder(), main_entity))
          None => ()
        }
    }
  }
  if any_added {
    render_view_visible_mesh_entities.sort_added_entities()
  }
}

///|
fn render_mesh_instances_collect_gpu_culled_meshes(world : @ecs.World) -> Unit {
  let render_gpu_culled_entities = match
    world.get_resource(RenderGpuCulledEntities::resource()) {
    Some(value) => value
    None => return
  }
  let cameras : Array[
    (
      @core.Entity,
      @camera_render_layers.RenderLayers?,
      @render_visibility.RenderVisibleEntities,
    ),
  ] = []
  let camera_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Optional[@camera_render_layers.RenderLayers],
        @ecs.Read[@render_visibility.RenderVisibleEntities],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! camera_query.view(fn(_query_entity, data) {
    let (entity, (layers, visible_entities)) = data
    cameras.push((entity, layers.value(), visible_entities.value()))
  })
  for camera in cameras {
    let (entity, layers, visible_entities) = camera
    render_mesh_instances_collect_gpu_culled_meshes_for_subview(
      layers, visible_entities, render_gpu_culled_entities,
    )
    try! world.set_by_key(
      entity,
      @render_visibility.RenderVisibleEntities::component(),
      visible_entities,
    )
  }
  let shadow_maps : Array[
    (
      @core.Entity,
      @camera_render_layers.RenderLayers?,
      @render_visibility.RenderShadowMapVisibleEntities,
    ),
  ] = []
  let shadow_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Optional[@camera_render_layers.RenderLayers],
        @ecs.Read[@render_visibility.RenderShadowMapVisibleEntities],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! shadow_query.view(fn(_query_entity, data) {
    let (entity, (layers, visible_entities)) = data
    shadow_maps.push((entity, layers.value(), visible_entities.value()))
  })
  for shadow_map in shadow_maps {
    let (entity, layers, visible_entities) = shadow_map
    visible_entities.for_each_subview(fn(_, subview_visible_entities) {
      render_mesh_instances_collect_gpu_culled_meshes_for_subview(
        layers, subview_visible_entities, render_gpu_culled_entities,
      )
    })
    try! world.set_by_key(
      entity,
      @render_visibility.RenderShadowMapVisibleEntities::component(),
      visible_entities,
    )
  }
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
pub fn RenderMeshInstanceGpuBuilder::prepare(
  self : RenderMeshInstanceGpuBuilder,
  entity : @render.MainEntity,
  mesh_allocator : @render_mesh.MeshAllocator,
  mesh_material_ids : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  render_lightmaps : @lightmap.RenderLightmaps,
  skin_uniforms : @pbr_render.SkinUniforms,
  morph_indices : @pbr_render.MorphIndices,
  timestamp : UInt,
) -> RenderMeshInstanceGpuPrepared? {
  let material_id = mesh_material_ids.mesh_material(entity.id())
  let material_binding_id = if material_id != DUMMY_MESH_MATERIAL_ID {
    match render_material_bindings.get(material_id) {
      Some(binding) => binding
      None => return None
    }
  } else {
    MaterialBindingId::MaterialBindingId()
  }
  let (first_vertex_index, vertex_count) = match
    mesh_allocator.mesh_vertex_slice(self.shared.mesh_asset_id()) {
    Some(vertex_slice) =>
      (
        vertex_slice.start().reinterpret_as_uint(),
        (vertex_slice.end() - vertex_slice.start()).reinterpret_as_uint(),
      )
    None => (0U, 0U)
  }
  let (mesh_is_indexed, first_index_index, index_count) = match
    mesh_allocator.mesh_index_slice(self.shared.mesh_asset_id()) {
    Some(index_slice) =>
      (
        true,
        index_slice.start().reinterpret_as_uint(),
        (index_slice.end() - index_slice.start()).reinterpret_as_uint(),
      )
    None => (false, 0U, 0U)
  }
  let current_skin_index = match skin_uniforms.skin_byte_offset(entity.id()) {
    Some(index) => index
    None => mesh_input_uniform_invalid_index()
  }
  let render_lightmap = render_lightmaps.get(entity.id())
  let lightmap_slot = match render_lightmap {
    Some(lightmap) => lightmap.slot_index.to_int().reinterpret_as_uint()
    None => 0xFFFFU
  }
  let lightmap_slab_index = match render_lightmap {
    Some(lightmap) => Some(lightmap.slab_index.to_int())
    None => None
  }
  let morph_descriptor_index = match
    morph_indices.morph_descriptor_index(entity.id()) {
    Some(index) => index
    None => mesh_input_uniform_invalid_index()
  }
  let material_slot = material_binding_id.slot().to_int().reinterpret_as_uint()
  let material_and_lightmap_bind_group_slot = material_slot |
    (lightmap_slot << 16)
  let shared = RenderMeshInstanceSharedFlat::{
    ..self.shared,
    material_bindings_index: material_binding_id,
    lightmap_slab_index,
  }
  let mesh_input_uniform = MeshInputUniform::new(
    world_from_local=self.world_from_local,
    lightmap_uv_rect=self.lightmap_uv_rect,
    flags=self.mesh_flags,
    timestamp~,
    first_vertex_index~,
    first_index_index~,
    index_count=if mesh_is_indexed { index_count } else { vertex_count },
    current_skin_index~,
    material_and_lightmap_bind_group_slot~,
    tag=shared.tag(),
    morph_descriptor_index~,
  )
  Some(RenderMeshInstanceGpuPrepared::{
    shared,
    mesh_input_uniform,
    render_layers: self.render_layers,
  })
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
fn render_mesh_instance_gpu_layers_equal(
  a : @camera_render_layers.RenderLayers?,
  b : @camera_render_layers.RenderLayers?,
) -> Bool {
  match (a, b) {
    (None, None) => true
    (Some(a), Some(b)) => a.mask() == b.mask()
    _ => false
  }
}

///|
fn render_mesh_instance_gpu_layers_or_default(
  layers : @camera_render_layers.RenderLayers?,
) -> @camera_render_layers.RenderLayers {
  match layers {
    Some(value) => value
    None => @camera_render_layers.RenderLayers::RenderLayers()
  }
}

///|
fn render_mesh_instance_gpu_no_cpu_culling(
  instance : RenderMeshInstanceGpu,
) -> Bool {
  instance.shared.flags().contains(RenderMeshInstanceFlags::no_cpu_culling())
}

///|
fn collect_meshes_for_gpu_building_accept_prepared(
  entity : @render.MainEntity,
  prepared : RenderMeshInstanceGpuPrepared,
  mesh_culling_data : MeshCullingData?,
  render_mesh_instances : RenderMeshInstancesGpu,
  current_input_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ],
  previous_input_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ],
  mesh_culling_data_buffer : MeshCullingDataBuffer,
  render_gpu_culled_entities : RenderGpuCulledEntities,
) -> Unit {
  let instance_data_index = prepared.update(
    entity, render_mesh_instances, current_input_buffer, previous_input_buffer,
  )
  match mesh_culling_data {
    Some(value) => value.update(mesh_culling_data_buffer, instance_data_index)
    None => ()
  }
  match render_mesh_instances.entries.get(entity.id().to_bits()) {
    Some(instance) =>
      render_gpu_culled_entities.update(
        entity,
        render_mesh_instance_gpu_layers_or_default(instance.render_layers),
        render_mesh_instance_gpu_no_cpu_culling(instance),
      )
    None => ()
  }
}

///|
fn collect_meshes_for_gpu_building_try_fast_gpu_culling_update(
  entity : @render.MainEntity,
  prepared : RenderMeshInstanceGpuPrepared,
  mesh_culling_data : MeshCullingData,
  render_mesh_instances : RenderMeshInstancesGpu,
  current_input_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ],
  previous_input_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ],
  mesh_culling_data_buffer : MeshCullingDataBuffer,
) -> Bool {
  let key = entity.id().to_bits()
  let existing_instance = match render_mesh_instances.entries.get(key) {
    Some(value) => value
    None => return false
  }
  guard render_mesh_instance_gpu_layers_equal(
    prepared.render_layers,
    existing_instance.render_layers,
  ) else {
    return false
  }
  guard prepared.shared
    .flags()
    .contains(RenderMeshInstanceFlags::no_cpu_culling()) ==
    render_mesh_instance_gpu_no_cpu_culling(existing_instance) else {
    return false
  }
  let current_uniform_index = existing_instance.gpu_specific.current_uniform_index()
  let previous_mesh_input_uniform = current_input_buffer.get_unchecked(
    current_uniform_index.reinterpret_as_int(),
  )
  let previous_input_index = previous_input_buffer
    .add(previous_mesh_input_uniform)
    .reinterpret_as_uint()
  current_input_buffer.set(
    current_uniform_index.reinterpret_as_int(),
    prepared.mesh_input_uniform.with_previous_input_index(previous_input_index),
  )
  render_mesh_instances.entries.set(
    key,
    RenderMeshInstanceGpu::new(
      prepared.shared,
      gpu_specific=existing_instance.gpu_specific,
      render_layers=existing_instance.render_layers,
    ),
  )
  mesh_culling_data.update(mesh_culling_data_buffer, current_uniform_index)
  true
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
priv struct RenderMeshInstanceGpuExtractionState {
  mut last_source_change_tick : @core.Tick
}

///|
let ecs_key_render_mesh_instance_gpu_extraction_state : @ecs.ResourceKey[
  RenderMeshInstanceGpuExtractionState,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::RenderMeshInstanceGpuExtractionState",
)

///|
fn render_mesh_instance_gpu_extraction_source_this_run(
  source_world : @ecs.World,
) -> @core.Tick {
  let tick = source_world.read_change_tick()
  if tick > 0 {
    tick
  } else {
    1
  }
}

///|
fn render_mesh_instance_gpu_extraction_system_ticks(
  render_world : @ecs.World,
  source_world : @ecs.World,
) -> @core.SystemTicks {
  let this_run = render_mesh_instance_gpu_extraction_source_this_run(
    source_world,
  )
  let last_run = match
    render_world.get_resource(ecs_key_render_mesh_instance_gpu_extraction_state) {
    Some(state) => state.last_source_change_tick
    None => 0
  }
  @core.SystemTicks::new(last_run, this_run)
}

///|
fn render_mesh_instance_gpu_extraction_set_last_source_change_tick(
  render_world : @ecs.World,
  tick : @core.Tick,
) -> Unit {
  match
    render_world.get_resource_mut(
      ecs_key_render_mesh_instance_gpu_extraction_state,
    ) {
    Some(state) =>
      state.modify(fn(value) { value.last_source_change_tick = tick })
    None =>
      render_world.insert_resource(
        ecs_key_render_mesh_instance_gpu_extraction_state,
        RenderMeshInstanceGpuExtractionState::{ last_source_change_tick: tick },
      )
  }
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
fn collect_meshes_for_gpu_building_prepare(
  entity : @render.MainEntity,
  builder : RenderMeshInstanceGpuBuilder,
  mesh_allocator : @render_mesh.MeshAllocator,
  mesh_material_ids : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  render_lightmaps : @lightmap.RenderLightmaps,
  skin_uniforms : @pbr_render.SkinUniforms,
  morph_indices : @pbr_render.MorphIndices,
  timestamp : UInt,
  meshes_to_reextract_next_frame : MeshesToReextractNextFrame,
) -> RenderMeshInstanceGpuPrepared? {
  match
    builder.prepare(
      entity, mesh_allocator, mesh_material_ids, render_material_bindings, render_lightmaps,
      skin_uniforms, morph_indices, timestamp,
    ) {
    Some(prepared) => Some(prepared)
    None => {
      meshes_to_reextract_next_frame.insert(entity)
      None
    }
  }
}

///|
pub fn[BD] collect_meshes_for_gpu_building(
  render_mesh_instances : RenderMeshInstances,
  batched_instance_buffers : @render_batching.BatchedInstanceBuffers[
    BD,
    MeshInputUniform,
  ],
  mesh_culling_data_buffer : MeshCullingDataBuffer,
  render_mesh_instance_queues : RenderMeshInstanceGpuQueues,
  render_gpu_culled_entities : RenderGpuCulledEntities,
  mesh_allocator : @render_mesh.MeshAllocator,
  mesh_material_ids : RenderMaterialInstances,
  render_material_bindings : RenderMaterialBindings,
  render_lightmaps : @lightmap.RenderLightmaps,
  skin_uniforms : @pbr_render.SkinUniforms,
  morph_indices : @pbr_render.MorphIndices,
  timestamp : UInt,
  meshes_to_reextract_next_frame : MeshesToReextractNextFrame,
) -> Unit {
  let gpu_instances = match render_mesh_instances {
    GpuBuilding(instances) => instances
    CpuBuilding(_) => return
  }
  meshes_to_reextract_next_frame.clear()
  let current_input_buffer = batched_instance_buffers.current_input_buffer
  let previous_input_buffer = batched_instance_buffers.previous_input_buffer
  if !current_input_buffer.is_empty() {
    mesh_culling_data_buffer.grow(
      current_input_buffer.len().reinterpret_as_uint(),
    )
  }
  render_gpu_culled_entities.prepare_for_new_frame()
  for queue in render_mesh_instance_queues.iter() {
    match queue.state {
      NoQueue => ()
      CpuCulling(cpu_queue) => {
        for item in cpu_queue.changed {
          let (entity, builder) = item
          match
            collect_meshes_for_gpu_building_prepare(
              entity, builder, mesh_allocator, mesh_material_ids, render_material_bindings,
              render_lightmaps, skin_uniforms, morph_indices, timestamp, meshes_to_reextract_next_frame,
            ) {
            Some(prepared) =>
              collect_meshes_for_gpu_building_accept_prepared(
                entity,
                prepared,
                None,
                gpu_instances,
                current_input_buffer,
                previous_input_buffer,
                mesh_culling_data_buffer,
                render_gpu_culled_entities,
              )
            None => ()
          }
        }
        for entity in cpu_queue.removed {
          ignore(
            remove_mesh_input_uniform(
              entity, gpu_instances, current_input_buffer,
            ),
          )
          render_gpu_culled_entities.remove(entity)
        }
        cpu_queue.changed.clear()
        cpu_queue.removed.clear()
      }
      GpuCulling(gpu_queue) => {
        for item in gpu_queue.changed_cpu_culling {
          let (entity, builder, culling_data) = item
          match
            collect_meshes_for_gpu_building_prepare(
              entity, builder, mesh_allocator, mesh_material_ids, render_material_bindings,
              render_lightmaps, skin_uniforms, morph_indices, timestamp, meshes_to_reextract_next_frame,
            ) {
            Some(prepared) =>
              if !collect_meshes_for_gpu_building_try_fast_gpu_culling_update(
                  entity, prepared, culling_data, gpu_instances, current_input_buffer,
                  previous_input_buffer, mesh_culling_data_buffer,
                ) {
                collect_meshes_for_gpu_building_accept_prepared(
                  entity,
                  prepared,
                  Some(culling_data),
                  gpu_instances,
                  current_input_buffer,
                  previous_input_buffer,
                  mesh_culling_data_buffer,
                  render_gpu_culled_entities,
                )
              }
            None => ()
          }
        }
        for item in gpu_queue.changed_gpu_culling {
          let (entity, builder, culling_data) = item
          match
            collect_meshes_for_gpu_building_prepare(
              entity, builder, mesh_allocator, mesh_material_ids, render_material_bindings,
              render_lightmaps, skin_uniforms, morph_indices, timestamp, meshes_to_reextract_next_frame,
            ) {
            Some(prepared) =>
              if !collect_meshes_for_gpu_building_try_fast_gpu_culling_update(
                  entity, prepared, culling_data, gpu_instances, current_input_buffer,
                  previous_input_buffer, mesh_culling_data_buffer,
                ) {
                collect_meshes_for_gpu_building_accept_prepared(
                  entity,
                  prepared,
                  Some(culling_data),
                  gpu_instances,
                  current_input_buffer,
                  previous_input_buffer,
                  mesh_culling_data_buffer,
                  render_gpu_culled_entities,
                )
              }
            None => ()
          }
        }
        for entity in gpu_queue.removed {
          ignore(
            remove_mesh_input_uniform(
              entity, gpu_instances, current_input_buffer,
            ),
          )
          render_gpu_culled_entities.remove(entity)
        }
        gpu_queue.changed_cpu_culling.clear()
        gpu_queue.changed_gpu_culling.clear()
        gpu_queue.removed.clear()
      }
    }
  }
  previous_input_buffer.ensure_nonempty(MeshInputUniform::new())
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
pub fn MeshesToReextractNextFrame::insert_all(
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
pub struct RenderMeshInstanceGpuBatchedInstanceBuffers {
  buffers : @render_batching.BatchedInstanceBuffers[Unit, MeshInputUniform]
}

///|
pub fn RenderMeshInstanceGpuBatchedInstanceBuffers::RenderMeshInstanceGpuBatchedInstanceBuffers() -> RenderMeshInstanceGpuBatchedInstanceBuffers {
  RenderMeshInstanceGpuBatchedInstanceBuffers::{
    buffers: @render_batching.BatchedInstanceBuffers::new(),
  }
}

///|
pub let ecs_key_render_mesh_instance_gpu_batched_instance_buffers : @ecs.ResourceKey[
  RenderMeshInstanceGpuBatchedInstanceBuffers,
] = @ecs.register_resource(
  debug_name="mgstudio_pbr::RenderMeshInstanceGpuBatchedInstanceBuffers",
)

///|
pub impl @app.Resource for RenderMeshInstanceGpuBatchedInstanceBuffers with fn resource() {
  ecs_key_render_mesh_instance_gpu_batched_instance_buffers
}

///|
pub fn RenderMeshInstanceGpuBatchedInstanceBuffers::current_input_len(
  self : RenderMeshInstanceGpuBatchedInstanceBuffers,
) -> Int {
  self.buffers.current_input_buffer.len()
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
  self.insert_instance(entity, RenderMeshInstanceCpu::from_queue_data(data))
}

///|
fn RenderMeshInstancesCpu::insert_instance(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
  instance : RenderMeshInstanceCpu,
) -> Unit {
  self.entries.set(entity.id().to_bits(), instance)
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
fn RenderMeshInstancesCpu::insert_mesh_instance_flags(
  self : RenderMeshInstancesCpu,
  entity : @render.MainEntity,
  flags : RenderMeshInstanceFlags,
) -> Unit {
  let key = entity.id().to_bits()
  match self.entries.get(key) {
    Some(instance) => {
      let shared = RenderMeshInstanceSharedFlat::{
        ..instance.shared,
        flags: instance.shared.flags().or(flags),
      }
      self.entries.set(key, RenderMeshInstanceCpu::{ ..instance, shared, })
    }
    None => ()
  }
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
fn RenderMeshInstancesGpu::insert_mesh_instance_flags(
  self : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
  flags : RenderMeshInstanceFlags,
) -> Unit {
  let key = entity.id().to_bits()
  match self.entries.get(key) {
    Some(instance) => {
      let shared = RenderMeshInstanceSharedFlat::{
        ..instance.shared,
        flags: instance.shared.flags().or(flags),
      }
      self.entries.set(key, RenderMeshInstanceGpu::{ ..instance, shared, })
    }
    None => ()
  }
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
fn RenderMeshInstances::insert_mesh_instance_flags(
  self : RenderMeshInstances,
  entity : @render.MainEntity,
  flags : RenderMeshInstanceFlags,
) -> Unit {
  match self {
    CpuBuilding(instances) =>
      instances.insert_mesh_instance_flags(entity, flags)
    GpuBuilding(instances) =>
      instances.insert_mesh_instance_flags(entity, flags)
  }
}

///|
pub fn mark_all_meshes_for_reextraction(
  render_mesh_instances : RenderMeshInstances,
  meshes_to_reextract : MeshesToReextractNextFrame,
) -> Unit {
  meshes_to_reextract.insert_all(render_mesh_instances.keys())
  render_mesh_instances.clear()
}

///|
fn render_mesh_instances_unorm16(value : Float) -> UInt {
  let rounded = (value * 65535.0F).round().to_int()
  if rounded <= 0 {
    0U
  } else if rounded >= 0xFFFF {
    0xFFFFU
  } else {
    rounded.reinterpret_as_uint()
  }
}

///|
fn render_mesh_instances_pack_lightmap_uv_rect(
  lightmap : Lightmap?,
) -> @math.UVec2 {
  match lightmap {
    Some(lightmap) => {
      let rect_min = lightmap.uv_rect.min()
      let rect_max = lightmap.uv_rect.max()
      let x = render_mesh_instances_unorm16(rect_min.x)
      let y = render_mesh_instances_unorm16(rect_min.y)
      let z = render_mesh_instances_unorm16(rect_max.x)
      let w = render_mesh_instances_unorm16(rect_max.y)
      @math.UVec2::new(
        (x | (y << 16)).reinterpret_as_int(),
        (z | (w << 16)).reinterpret_as_int(),
      )
    }
    None => @math.UVec2::zero()
  }
}

///|
priv struct RenderMeshInstanceGpuExtractionRow {
  entity : @core.Entity
  view_visibility : @visibility.ViewVisibility
  world_from_local : @math.Affine3
  previous_global_transform : @pbr_prepass.PreviousGlobalTransform?
  lightmap : Lightmap?
  aabb : @camera_primitives.Aabb?
  mesh : @mesh.Mesh3d
  tag : @mesh.MeshTag?
  has_no_frustum_culling : Bool
  has_not_shadow_receiver : Bool
  has_transmitted_shadow_receiver : Bool
  has_not_shadow_caster : Bool
  has_no_automatic_batching : Bool
  has_no_cpu_culling : Bool
  visibility_range : @visibility.VisibilityRange?
  render_layers : @camera_render_layers.RenderLayers?
}

///|
priv struct RenderMeshInstanceCpuExtractionRow {
  entity : @core.Entity
  world_from_local : @math.Affine3
  previous_global_transform : @pbr_prepass.PreviousGlobalTransform?
  mesh : @mesh.Mesh3d
  tag : @mesh.MeshTag?
  has_no_frustum_culling : Bool
  has_not_shadow_receiver : Bool
  has_transmitted_shadow_receiver : Bool
  has_not_shadow_caster : Bool
  has_no_automatic_batching : Bool
  visibility_range : @visibility.VisibilityRange?
  render_layers : @camera_render_layers.RenderLayers?
}

///|
fn render_mesh_instance_gpu_extraction_row_from_source(
  source_world : @ecs.World,
  entity : @core.Entity,
) -> RenderMeshInstanceGpuExtractionRow? {
  guard source_world.is_alive(entity) else { return None }
  let view_visibility = match
    (try! source_world.get_by_key(entity, @visibility.ecs_key_view_visibility)) {
    Some(value) => value
    None => return None
  }
  let global_transform = match
    (try! source_world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(value) => value
    None => return None
  }
  let mesh = match
    (try! source_world.get_by_key(entity, @mesh.ecs_key_mesh3d)) {
    Some(value) => value
    None => return None
  }
  Some(RenderMeshInstanceGpuExtractionRow::{
    entity,
    view_visibility,
    world_from_local: global_transform.affine(),
    previous_global_transform: try! source_world.get_by_key(
      entity, ecs_key_previous_global_transform,
    ),
    lightmap: try! source_world.get_by_key(entity, ecs_key_lightmap),
    aabb: try! source_world.get_by_key(entity, @camera_primitives.ecs_key_aabb),
    mesh,
    tag: try! source_world.get_by_key(entity, @mesh.ecs_key_mesh_tag),
    has_no_frustum_culling: (try! source_world.get_by_key(
      entity, @visibility.ecs_key_no_frustum_culling,
    ))
    is Some(_),
    has_not_shadow_receiver: (try! source_world.get_by_key(
      entity, ecs_key_not_shadow_receiver,
    ))
    is Some(_),
    has_transmitted_shadow_receiver: (try! source_world.get_by_key(
      entity, ecs_key_transmitted_shadow_receiver,
    ))
    is Some(_),
    has_not_shadow_caster: (try! source_world.get_by_key(
      entity, ecs_key_not_shadow_caster,
    ))
    is Some(_),
    has_no_automatic_batching: (try! source_world.get_by_key(
      entity, @render_batching.ecs_key_no_automatic_batching,
    ))
    is Some(_),
    has_no_cpu_culling: (try! source_world.get_by_key(
      entity, @visibility.ecs_key_no_cpu_culling,
    ))
    is Some(_),
    visibility_range: try! source_world.get_by_key(
      entity, @visibility.ecs_key_visibility_range,
    ),
    render_layers: try! source_world.get_by_key(
      entity, @camera_render_layers.ecs_key_render_layers,
    ),
  })
}

///|
fn render_mesh_instance_shared_for_gpu_extraction_row(
  row : RenderMeshInstanceGpuExtractionRow,
) -> RenderMeshInstanceSharedFlat {
  let flags = RenderMeshInstanceFlags::from_extraction_components(
    row.previous_global_transform is Some(_),
    false,
    false,
    row.has_not_shadow_caster,
    row.has_no_automatic_batching,
    row.has_no_cpu_culling,
  )
  let tag = match row.tag {
    Some(value) => value.value()
    None => 0U
  }
  RenderMeshInstanceSharedFlat::new(row.mesh.mesh().id(), tag~, flags~)
}

///|
fn render_mesh_instance_extraction_lod_index(
  entity : @core.Entity,
  visibility_range : @visibility.VisibilityRange?,
  render_visibility_ranges : @render_visibility.RenderVisibilityRanges?,
) -> Int? {
  guard visibility_range is Some(_) else { return None }
  guard render_visibility_ranges is Some(ranges) else { return None }
  ranges.lod_index_for_entity(entity.id)
}

///|
fn render_mesh_instance_extraction_mesh_flags(
  entity : @core.Entity,
  world_from_local : @math.Affine3,
  visibility_range : @visibility.VisibilityRange?,
  has_no_frustum_culling : Bool,
  has_not_shadow_receiver : Bool,
  has_transmitted_shadow_receiver : Bool,
  render_visibility_ranges : @render_visibility.RenderVisibilityRanges?,
) -> UInt {
  let mut flags = match
    render_mesh_instance_extraction_lod_index(
      entity, visibility_range, render_visibility_ranges,
    ) {
    Some(lod_index) =>
      if lod_index >= 0 && lod_index < 0xFFFF {
        lod_index.reinterpret_as_uint()
      } else {
        RENDER3D_MESH_FLAGS_LOD_INDEX_NONE
      }
    None => RENDER3D_MESH_FLAGS_LOD_INDEX_NONE
  }
  match visibility_range {
    Some(range) =>
      if range.use_aabb() {
        flags = flags | RENDER3D_MESH_FLAGS_AABB_BASED_VISIBILITY_RANGE
      }
    None => ()
  }
  if has_no_frustum_culling {
    flags = flags | RENDER3D_MESH_FLAGS_NO_FRUSTUM_CULLING
  }
  if !has_not_shadow_receiver {
    flags = flags | RENDER3D_MESH_FLAGS_SHADOW_RECEIVER
  }
  if has_transmitted_shadow_receiver {
    flags = flags | RENDER3D_MESH_FLAGS_TRANSMITTED_SHADOW_RECEIVER
  }
  if world_from_local.matrix3.determinant() >= 0.0F {
    flags = flags | RENDER3D_MESH_FLAGS_SIGN_DETERMINANT_MODEL_3X3
  }
  flags
}

///|
fn render_mesh_instance_gpu_builder_from_extraction_row(
  instances : RenderMeshInstancesGpu,
  row : RenderMeshInstanceGpuExtractionRow,
  render_visibility_ranges : @render_visibility.RenderVisibilityRanges?,
) -> RenderMeshInstanceGpuBuilder {
  let entity = @render.MainEntity::new(row.entity)
  let shared = render_mesh_instance_shared_for_gpu_extraction_row(row)
  RenderMeshInstanceGpuBuilder::from_shared(
    shared,
    row.world_from_local,
    render_mesh_instances_pack_lightmap_uv_rect(row.lightmap),
    render_mesh_instances_gpu_previous_input_index(instances, entity, shared),
    row.render_layers,
    render_mesh_instance_extraction_mesh_flags(
      row.entity,
      row.world_from_local,
      row.visibility_range,
      row.has_no_frustum_culling,
      row.has_not_shadow_receiver,
      row.has_transmitted_shadow_receiver,
      render_visibility_ranges,
    ),
  )
}

///|
fn render_mesh_instance_cpu_material_binding_id(
  row : RenderMeshInstanceCpuExtractionRow,
  mesh_material_ids : RenderMaterialInstances?,
  render_material_bindings : RenderMaterialBindings?,
) -> MaterialBindingId {
  guard mesh_material_ids is Some(material_ids) else {
    return MaterialBindingId::MaterialBindingId()
  }
  let material_id = material_ids.mesh_material(row.entity)
  guard material_id != DUMMY_MESH_MATERIAL_ID else {
    return MaterialBindingId::MaterialBindingId()
  }
  match render_material_bindings {
    Some(bindings) =>
      match bindings.get(material_id) {
        Some(binding) => binding
        None => MaterialBindingId::MaterialBindingId()
      }
    None => MaterialBindingId::MaterialBindingId()
  }
}

///|
fn render_mesh_instance_cpu_from_extraction_row(
  row : RenderMeshInstanceCpuExtractionRow,
  mesh_material_ids : RenderMaterialInstances?,
  render_material_bindings : RenderMaterialBindings?,
  render_visibility_ranges : @render_visibility.RenderVisibilityRanges?,
) -> RenderMeshInstanceCpu {
  let shared_flags = RenderMeshInstanceFlags::from_extraction_components(
    row.previous_global_transform is Some(_),
    false,
    false,
    row.has_not_shadow_caster,
    row.has_no_automatic_batching,
    false,
  )
  let tag = match row.tag {
    Some(value) => value.value()
    None => 0U
  }
  let shared = RenderMeshInstanceSharedFlat::new(
    row.mesh.mesh().id(),
    material_bindings_index=render_mesh_instance_cpu_material_binding_id(
      row, mesh_material_ids, render_material_bindings,
    ),
    tag~,
    flags=shared_flags,
  )
  let previous_world_from_local = match row.previous_global_transform {
    Some(value) => value.affine()
    None => row.world_from_local
  }
  let transforms = MeshTransforms::new(
    row.world_from_local,
    previous_world_from_local,
    render_mesh_instance_extraction_mesh_flags(
      row.entity,
      row.world_from_local,
      row.visibility_range,
      row.has_no_frustum_culling,
      row.has_not_shadow_receiver,
      row.has_transmitted_shadow_receiver,
      render_visibility_ranges,
    ),
  )
  RenderMeshInstanceCpu::new(
    shared,
    transforms=Some(transforms),
    render_layers=row.render_layers,
  )
}

///|
fn render_mesh_instances_gpu_previous_input_index(
  instances : RenderMeshInstancesGpu,
  entity : @render.MainEntity,
  shared : RenderMeshInstanceSharedFlat,
) -> UInt? {
  if !shared.flags().contains(RenderMeshInstanceFlags::has_previous_transform()) {
    return None
  }
  match instances.entries.get(entity.id().to_bits()) {
    Some(instance) => Some(instance.gpu_specific.current_uniform_index())
    None => None
  }
}

///|
fn[T] render_mesh_instances_gpu_extend_changed_component_entities(
  source_world : @ecs.World,
  key : @ecs.ComponentKey[T],
  system_ticks : @core.SystemTicks,
  entities : Map[UInt64, @render.MainEntity],
) -> Unit {
  for entity in source_world.changed_components(key, system_ticks).read() {
    entities.set(entity.to_bits(), @render.MainEntity::new(entity))
  }
}

///|
fn render_mesh_instances_gpu_changed_mesh_set(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Map[UInt64, @render.MainEntity] {
  let entities : Map[UInt64, @render.MainEntity] = {}
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @visibility.ecs_key_view_visibility, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @transform.ecs_key_global_transform, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, ecs_key_previous_global_transform, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, ecs_key_lightmap, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @camera_primitives.ecs_key_aabb, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @mesh.ecs_key_mesh3d, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @mesh.ecs_key_mesh_tag, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @visibility.ecs_key_no_frustum_culling, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, ecs_key_not_shadow_receiver, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, ecs_key_transmitted_shadow_receiver, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, ecs_key_not_shadow_caster, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @render_batching.ecs_key_no_automatic_batching, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @visibility.ecs_key_no_cpu_culling, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @visibility.ecs_key_visibility_range, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_changed_component_entities(
    source_world, @mesh.ecs_key_skinned_mesh, system_ticks, entities,
  )
  entities
}

///|
fn[T] render_mesh_instances_gpu_extend_removed_component_entities(
  source_world : @ecs.World,
  key : @ecs.ComponentKey[T],
  system_ticks : @core.SystemTicks,
  entities : Map[UInt64, @render.MainEntity],
) -> Unit {
  for entity in source_world.removed_components(key, system_ticks).read() {
    entities.set(entity.to_bits(), @render.MainEntity::new(entity))
  }
}

///|
fn render_mesh_instances_gpu_potential_reextraction_set(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
  meshes_to_reextract : MeshesToReextractNextFrame,
) -> Map[UInt64, @render.MainEntity] {
  let entities : Map[UInt64, @render.MainEntity] = {}
  for entity in meshes_to_reextract.entities() {
    entities.set(entity.id().to_bits(), entity)
  }
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, ecs_key_previous_global_transform, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, ecs_key_lightmap, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, @camera_primitives.ecs_key_aabb, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, @mesh.ecs_key_mesh_tag, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, @visibility.ecs_key_no_frustum_culling, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, ecs_key_not_shadow_receiver, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, ecs_key_transmitted_shadow_receiver, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, ecs_key_not_shadow_caster, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, @render_batching.ecs_key_no_automatic_batching, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, @visibility.ecs_key_no_cpu_culling, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, @visibility.ecs_key_visibility_range, system_ticks, entities,
  )
  render_mesh_instances_gpu_extend_removed_component_entities(
    source_world, @mesh.ecs_key_skinned_mesh, system_ticks, entities,
  )
  entities
}

///|
fn render_mesh_instances_gpu_removed_mesh3d_set(
  source_world : @ecs.World,
  system_ticks : @core.SystemTicks,
) -> Map[UInt64, @render.MainEntity] {
  let entities : Map[UInt64, @render.MainEntity] = {}
  for
    entity in source_world
    .removed_components(@mesh.ecs_key_mesh3d, system_ticks)
    .read() {
    entities.set(entity.to_bits(), @render.MainEntity::new(entity))
  }
  entities
}

///|
fn render_mesh_instances_gpu_queue_extraction_row(
  queue : RenderMeshInstanceGpuQueue,
  gpu_instances : RenderMeshInstancesGpu,
  row : RenderMeshInstanceGpuExtractionRow,
  render_visibility_ranges : @render_visibility.RenderVisibilityRanges?,
  any_gpu_culling : Bool,
) -> Unit {
  let entity = @render.MainEntity::new(row.entity)
  if !row.view_visibility.is_visible() {
    queue.remove(entity, any_gpu_culling)
    return
  }
  let builder = render_mesh_instance_gpu_builder_from_extraction_row(
    gpu_instances, row, render_visibility_ranges,
  )
  let culling_data = if any_gpu_culling {
    Some(MeshCullingData::new(row.aabb))
  } else {
    None
  }
  queue.push(entity, builder, culling_data, row.has_no_cpu_culling)
}

///|
fn render_mesh_instances_gpu_resource_or_insert(
  world : @ecs.World,
) -> RenderMeshInstances {
  match world.get_resource(RenderMeshInstances::resource()) {
    Some(instances) =>
      match instances {
        GpuBuilding(_) => instances
        CpuBuilding(_) => {
          let next = RenderMeshInstances::new(
            use_gpu_instance_buffer_builder=true,
          )
          world.insert_resource(RenderMeshInstances::resource(), next)
          match world.get_resource(RenderMeshInstances::resource()) {
            Some(value) => value
            None => abort("RenderMeshInstances resource missing after insert")
          }
        }
      }
    None => {
      let next = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
      world.insert_resource(RenderMeshInstances::resource(), next)
      match world.get_resource(RenderMeshInstances::resource()) {
        Some(value) => value
        None => abort("RenderMeshInstances resource missing after insert")
      }
    }
  }
}

///|
fn render_mesh_instance_gpu_queues_or_insert(
  world : @ecs.World,
) -> RenderMeshInstanceGpuQueues {
  match world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(queues) => queues
    None => {
      let queues = RenderMeshInstanceGpuQueues::RenderMeshInstanceGpuQueues()
      world.insert_resource(RenderMeshInstanceGpuQueues::resource(), queues)
      queues
    }
  }
}

///|
fn meshes_to_reextract_next_frame_or_insert(
  world : @ecs.World,
) -> MeshesToReextractNextFrame {
  match world.get_resource(MeshesToReextractNextFrame::resource()) {
    Some(value) => value
    None => {
      let value = MeshesToReextractNextFrame::MeshesToReextractNextFrame()
      world.insert_resource(MeshesToReextractNextFrame::resource(), value)
      value
    }
  }
}

///|
fn render_mesh_instance_gpu_batched_instance_buffers_or_insert(
  world : @ecs.World,
) -> RenderMeshInstanceGpuBatchedInstanceBuffers {
  match
    world.get_resource(RenderMeshInstanceGpuBatchedInstanceBuffers::resource()) {
    Some(value) => value
    None => {
      let value = RenderMeshInstanceGpuBatchedInstanceBuffers::RenderMeshInstanceGpuBatchedInstanceBuffers()
      world.insert_resource(
        RenderMeshInstanceGpuBatchedInstanceBuffers::resource(),
        value,
      )
      value
    }
  }
}

///|
fn mesh_culling_data_buffer_or_insert(
  world : @ecs.World,
) -> MeshCullingDataBuffer {
  match world.get_resource(MeshCullingDataBuffer::resource()) {
    Some(value) => value
    None => {
      let value = MeshCullingDataBuffer::MeshCullingDataBuffer()
      world.insert_resource(MeshCullingDataBuffer::resource(), value)
      value
    }
  }
}

///|
fn render_gpu_culled_entities_or_insert(
  world : @ecs.World,
) -> RenderGpuCulledEntities {
  match world.get_resource(RenderGpuCulledEntities::resource()) {
    Some(value) => value
    None => {
      let value = RenderGpuCulledEntities::RenderGpuCulledEntities()
      world.insert_resource(RenderGpuCulledEntities::resource(), value)
      value
    }
  }
}

///|
fn render_material_bindings_or_insert(
  world : @ecs.World,
) -> RenderMaterialBindings {
  match world.get_resource(RenderMaterialBindings::resource()) {
    Some(value) => value
    None => {
      let value = RenderMaterialBindings::RenderMaterialBindings()
      world.insert_resource(RenderMaterialBindings::resource(), value)
      value
    }
  }
}

///|
fn render_lightmaps_or_insert(world : @ecs.World) -> @lightmap.RenderLightmaps {
  match world.get_resource(@lightmap.RenderLightmaps::resource()) {
    Some(value) => value
    None => {
      let value = @lightmap.RenderLightmaps::RenderLightmaps()
      world.insert_resource(@lightmap.RenderLightmaps::resource(), value)
      value
    }
  }
}

///|
fn render_mesh_instances_frame_timestamp(world : @ecs.World) -> UInt {
  ignore(world)
  @render.host_gpu_frame_count()
}

///|
fn render_mesh_instances_collect_gpu_building_resource(
  world : @ecs.World,
) -> Unit {
  let render_mesh_instances = match
    world.get_resource(RenderMeshInstances::resource()) {
    Some(GpuBuilding(_) as instances) => instances
    _ => return
  }
  guard world.get_resource(@render_mesh.MeshAllocator::resource())
    is Some(mesh_allocator) else {
    return
  }
  guard world.get_resource(ecs_key_render_material_instances)
    is Some(mesh_material_ids) else {
    return
  }
  @pbr_render.ensure_skin_uniforms_resource(world)
  @pbr_render.ensure_morph_resources(world)
  let batched_instance_buffers = render_mesh_instance_gpu_batched_instance_buffers_or_insert(
    world,
  )
  let mesh_culling_data_buffer = mesh_culling_data_buffer_or_insert(world)
  let render_mesh_instance_queues = render_mesh_instance_gpu_queues_or_insert(
    world,
  )
  let render_gpu_culled_entities = render_gpu_culled_entities_or_insert(world)
  let render_material_bindings = render_material_bindings_or_insert(world)
  let render_lightmaps = render_lightmaps_or_insert(world)
  guard world.get_resource(@pbr_render.SkinUniforms::resource())
    is Some(skin_uniforms) else {
    return
  }
  guard world.get_resource(@pbr_render.MorphIndices::resource())
    is Some(morph_indices) else {
    return
  }
  let timestamp = render_mesh_instances_frame_timestamp(world)
  let meshes_to_reextract_next_frame = meshes_to_reextract_next_frame_or_insert(
    world,
  )
  collect_meshes_for_gpu_building(
    render_mesh_instances,
    batched_instance_buffers.buffers,
    mesh_culling_data_buffer,
    render_mesh_instance_queues,
    render_gpu_culled_entities,
    mesh_allocator,
    mesh_material_ids,
    render_material_bindings,
    render_lightmaps,
    skin_uniforms,
    morph_indices,
    timestamp,
    meshes_to_reextract_next_frame,
  )
  render_mesh_instances_collect_gpu_culled_meshes(world)
}

///|
fn render_mesh_instances_extract_gpu_building_resource(
  world : @ecs.World,
  source_world : @ecs.World,
  any_gpu_culling : Bool,
) -> Unit {
  let system_ticks = render_mesh_instance_gpu_extraction_system_ticks(
    world, source_world,
  )
  let instances = render_mesh_instances_gpu_resource_or_insert(world)
  let gpu_instances = match instances {
    GpuBuilding(value) => value
    CpuBuilding(_) => return
  }
  let queues = render_mesh_instance_gpu_queues_or_insert(world)
  let meshes_to_reextract = meshes_to_reextract_next_frame_or_insert(world)
  let potential_reextraction_set = render_mesh_instances_gpu_potential_reextraction_set(
    source_world, system_ticks, meshes_to_reextract,
  )
  let removed_mesh3d_set = render_mesh_instances_gpu_removed_mesh3d_set(
    source_world, system_ticks,
  )
  let render_visibility_ranges = world.get_resource(
    @render_visibility.ecs_key_render_visibility_ranges,
  )
  queues.init(any_gpu_culling)
  let changed_meshes_query = render_mesh_instances_gpu_changed_mesh_set(
    source_world, system_ticks,
  )
  let changed_entities : Map[UInt64, @render.MainEntity] = {}
  let queue = queues.borrow_local_mut()
  for item in changed_meshes_query.values() {
    let bits = item.id().to_bits()
    match
      render_mesh_instance_gpu_extraction_row_from_source(
        source_world,
        item.id(),
      ) {
      Some(row) => {
        render_mesh_instances_gpu_queue_extraction_row(
          queue, gpu_instances, row, render_visibility_ranges, any_gpu_culling,
        )
        changed_entities.set(bits, item)
      }
      None => ()
    }
  }
  for item in potential_reextraction_set.values() {
    let bits = item.id().to_bits()
    if !changed_entities.contains(bits) {
      match
        render_mesh_instance_gpu_extraction_row_from_source(
          source_world,
          item.id(),
        ) {
        Some(row) =>
          render_mesh_instances_gpu_queue_extraction_row(
            queue, gpu_instances, row, render_visibility_ranges, any_gpu_culling,
          )
        None => ()
      }
    }
  }
  for item in removed_mesh3d_set.values() {
    let bits = item.id().to_bits()
    if !changed_entities.contains(bits) && !meshes_to_reextract.contains(item) {
      queue.remove(item, any_gpu_culling)
    }
  }
  render_mesh_instance_gpu_extraction_set_last_source_change_tick(
    world,
    render_mesh_instance_gpu_extraction_source_this_run(source_world),
  )
}

///|
fn render_mesh_instances_cpu_resource_or_insert(
  world : @ecs.World,
) -> RenderMeshInstances {
  match world.get_resource(RenderMeshInstances::resource()) {
    Some(instances) =>
      match instances {
        CpuBuilding(_) => instances
        GpuBuilding(_) => {
          let next = RenderMeshInstances::new()
          world.insert_resource(RenderMeshInstances::resource(), next)
          match world.get_resource(RenderMeshInstances::resource()) {
            Some(value) => value
            None => abort("RenderMeshInstances resource missing after insert")
          }
        }
      }
    None => {
      let next = RenderMeshInstances::new()
      world.insert_resource(RenderMeshInstances::resource(), next)
      match world.get_resource(RenderMeshInstances::resource()) {
        Some(value) => value
        None => abort("RenderMeshInstances resource missing after insert")
      }
    }
  }
}

///|
fn render_mesh_instances_update_cpu_building_resource(
  world : @ecs.World,
  source_world : @ecs.World,
) -> Unit {
  let instances = render_mesh_instances_cpu_resource_or_insert(world)
  let cpu_instances = match instances {
    CpuBuilding(value) => value
    GpuBuilding(_) => return
  }
  cpu_instances.clear()
  let mesh_material_ids = world.get_resource(ecs_key_render_material_instances)
  let render_material_bindings = world.get_resource(
    RenderMaterialBindings::resource(),
  )
  let render_visibility_ranges = world.get_resource(
    @render_visibility.ecs_key_render_visibility_ranges,
  )
  let mesh_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[@mesh.Mesh3d],
        @ecs.Read[@visibility.ViewVisibility],
        @ecs.Read[@transform.GlobalTransform],
      ),
      (
        @ecs.Optional[@pbr_prepass.PreviousGlobalTransform],
        @ecs.Optional[@mesh.MeshTag],
        @ecs.Optional[@visibility.VisibilityRange],
        @ecs.Optional[@camera_render_layers.RenderLayers],
      ),
      (
        (
          @ecs.Has[@visibility.NoFrustumCulling],
          @ecs.Has[NotShadowReceiver],
          @ecs.Has[TransmittedShadowReceiver],
        ),
        (
          @ecs.Has[NotShadowCaster],
          @ecs.Has[@render_batching.NoAutomaticBatching],
        ),
      ),
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! mesh_query.view(fn(_query_entity, data) {
    let (
      entity,
      (mesh, view_visibility, global_transform),
      (previous_global_transform, tag, visibility_range, render_layers),
      (
        (no_frustum_culling, not_shadow_receiver, transmitted_shadow_receiver),
        (not_shadow_caster, no_automatic_batching),
      ),
    ) = data
    if !view_visibility.value().is_visible() {
      return
    }
    let row = RenderMeshInstanceCpuExtractionRow::{
      entity,
      world_from_local: global_transform.value().affine(),
      previous_global_transform: previous_global_transform.value(),
      mesh: mesh.value(),
      tag: tag.value(),
      has_no_frustum_culling: no_frustum_culling.present(),
      has_not_shadow_receiver: not_shadow_receiver.present(),
      has_transmitted_shadow_receiver: transmitted_shadow_receiver.present(),
      has_not_shadow_caster: not_shadow_caster.present(),
      has_no_automatic_batching: no_automatic_batching.present(),
      visibility_range: visibility_range.value(),
      render_layers: render_layers.value(),
    }
    cpu_instances.insert_instance(
      @render.MainEntity::new(entity),
      render_mesh_instance_cpu_from_extraction_row(
        row, mesh_material_ids, render_material_bindings, render_visibility_ranges,
      ),
    )
  })
}

///|
fn render_mesh_instances_clear_resource(world : @ecs.World) -> Unit {
  match world.get_resource(RenderMeshInstances::resource()) {
    Some(instances) => instances.clear()
    None => ()
  }
}

///|
fn render_mesh_instances_set_mesh_motion_vector_flags(
  world : @ecs.World,
) -> Unit {
  let instances = match world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None => return
  }
  match world.get_resource(@pbr_render.SkinUniforms::resource()) {
    Some(skin_uniforms) =>
      for skin_key in skin_uniforms.previous_skins.iter() {
        instances.insert_mesh_instance_flags(
          @render.MainEntity::new(@core.Entity::from_bits(skin_key)),
          RenderMeshInstanceFlags::has_previous_skin(),
        )
      }
    None => ()
  }
  match world.get_resource(@pbr_render.MorphIndices::resource()) {
    Some(morph_indices) =>
      morph_indices.prev.each(fn(entity_key, _) {
        instances.insert_mesh_instance_flags(
          @render.MainEntity::new(@core.Entity::from_bits(entity_key)),
          RenderMeshInstanceFlags::has_previous_morph(),
        )
      })
    None => ()
  }
}
