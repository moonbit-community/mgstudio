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
test "pbr: RenderMeshInstances exposes Bevy queue data by MainEntity" {
  let instances = RenderMeshInstances::new()
  let entity = @render.MainEntity::new(@core.Entity::new(10, 1))
  let flags = RenderMeshInstanceFlags::has_previous_skin().or(
    RenderMeshInstanceFlags::automatic_batching(),
  )
  instances.insert(entity, RenderMeshQueueData::new(33, 9U, true, flags~))

  let data = match instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing render mesh queue data")
  }
  debug_inspect(instances.len(), content="1")
  debug_inspect(instances.mesh_asset_id(entity), content="Some(33)")
  debug_inspect(data.mesh_asset_id(), content="33")
  debug_inspect(data.current_uniform_index(), content="0")
  debug_inspect(data.should_batch(), content="true")
  debug_inspect(
    data.flags().contains(RenderMeshInstanceFlags::has_previous_skin()),
    content="true",
  )
  debug_inspect(
    data.flags().contains(RenderMeshInstanceFlags::has_previous_morph()),
    content="false",
  )
  debug_inspect(instances.remove(entity) is Some(_), content="true")
  debug_inspect(
    instances.render_mesh_queue_data(entity) is None,
    content="true",
  )
}

///|
test "pbr: RenderMeshInstances has Bevy CPU and GPU building variants" {
  let entity = @render.MainEntity::new(@core.Entity::new(22, 1))
  let cpu_instances = RenderMeshInstances::new()
  cpu_instances.insert(entity, RenderMeshQueueData::new(41, 0U, false))
  match cpu_instances {
    CpuBuilding(_) => ()
    GpuBuilding(_) => abort("default should use CPU building")
  }
  debug_inspect(cpu_instances.mesh_asset_id(entity), content="Some(41)")

  let gpu_instances = RenderMeshInstances::new(
    use_gpu_instance_buffer_builder=true,
  )
  gpu_instances.insert(entity, RenderMeshQueueData::new(42, 7U, true))
  match gpu_instances {
    CpuBuilding(_) => abort("explicit GPU builder should use GPU building")
    GpuBuilding(_) => ()
  }
  let gpu_data = match gpu_instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing GPU render mesh queue data")
  }
  debug_inspect(gpu_instances.len(), content="1")
  debug_inspect(gpu_data.mesh_asset_id(), content="42")
  debug_inspect(gpu_data.current_uniform_index(), content="7")
  debug_inspect(gpu_data.should_batch(), content="true")
}

///|
test "pbr: RenderMeshInstances clear preserves persistent render resource variant" {
  let entity = @render.MainEntity::new(@core.Entity::new(222, 1))
  let cpu_world = @ecs.World::new()
  let cpu_instances = RenderMeshInstances::new()
  cpu_instances.insert(entity, RenderMeshQueueData::new(43, 0U, false))
  cpu_world.insert_resource(RenderMeshInstances::resource(), cpu_instances)

  render_mesh_instances_clear_resource(cpu_world)

  let cpu_after = match
    cpu_world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None => abort("missing CPU RenderMeshInstances")
  }
  match cpu_after {
    CpuBuilding(_) => ()
    GpuBuilding(_) => abort("CPU clear should preserve CPU variant")
  }
  debug_inspect(cpu_after.len(), content="0")

  let gpu_world = @ecs.World::new()
  let gpu_instances = RenderMeshInstances::new(
    use_gpu_instance_buffer_builder=true,
  )
  gpu_instances.insert(entity, RenderMeshQueueData::new(44, 3U, true))
  gpu_world.insert_resource(RenderMeshInstances::resource(), gpu_instances)

  render_mesh_instances_clear_resource(gpu_world)

  let gpu_after = match
    gpu_world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None => abort("missing GPU RenderMeshInstances")
  }
  match gpu_after {
    CpuBuilding(_) => abort("GPU clear should preserve GPU variant")
    GpuBuilding(_) => ()
  }
  debug_inspect(gpu_after.len(), content="0")
}

///|
test "pbr: RenderMeshInstances stores Bevy-shaped CPU and GPU instance records" {
  let entity = @render.MainEntity::new(@core.Entity::new(23, 1))
  let flags = RenderMeshInstanceFlags::has_previous_transform().or(
    RenderMeshInstanceFlags::automatic_batching(),
  )
  let cpu_instances = RenderMeshInstancesCpu::RenderMeshInstancesCpu()
  cpu_instances.insert(entity, RenderMeshQueueData::new(70, 9U, true, flags~))
  let cpu_data = match cpu_instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing CPU render mesh queue data")
  }
  debug_inspect(cpu_data.mesh_asset_id(), content="70")
  debug_inspect(cpu_data.current_uniform_index(), content="0")
  debug_inspect(
    cpu_data.flags().contains(RenderMeshInstanceFlags::has_previous_transform()),
    content="true",
  )

  let gpu_instances = RenderMeshInstancesGpu::RenderMeshInstancesGpu()
  gpu_instances.insert(entity, RenderMeshQueueData::new(71, 13U, true, flags~))
  let gpu_data = match gpu_instances.render_mesh_queue_data(entity) {
    Some(value) => value
    None => abort("missing GPU render mesh queue data")
  }
  debug_inspect(gpu_data.mesh_asset_id(), content="71")
  debug_inspect(gpu_data.current_uniform_index(), content="13")
  debug_inspect(gpu_data.should_batch(), content="true")
}

///|
test "pbr: RenderMeshInstanceGpuPrepared updates current and previous input buffers" {
  let entity = @render.MainEntity::new(@core.Entity::new(24, 1))
  let instances = RenderMeshInstancesGpu::RenderMeshInstancesGpu()
  let current_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ] = @render_batching.InstanceInputUniformBuffer::new()
  let previous_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ] = @render_batching.InstanceInputUniformBuffer::new()
  let first_shared = RenderMeshInstanceSharedFlat::new(80, tag=5U)
  let first_prepared = RenderMeshInstanceGpuPrepared::from_shared(
    first_shared,
    MeshInputUniform::from_shared(first_shared, timestamp=1U),
    None,
  )

  let first_index = first_prepared.update(
    entity, instances, current_buffer, previous_buffer,
  )
  debug_inspect(first_index, content="0")
  debug_inspect(current_buffer.len(), content="1")
  debug_inspect(previous_buffer.len(), content="0")
  debug_inspect(
    instances.render_mesh_queue_data(entity).unwrap().current_uniform_index(),
    content="0",
  )

  let second_shared = RenderMeshInstanceSharedFlat::new(80, tag=6U)
  let second_prepared = RenderMeshInstanceGpuPrepared::from_shared(
    second_shared,
    MeshInputUniform::from_shared(second_shared, timestamp=2U),
    None,
  )
  let second_index = second_prepared.update(
    entity, instances, current_buffer, previous_buffer,
  )
  let current_uniform = current_buffer.get_unchecked(
    second_index.reinterpret_as_int(),
  )

  debug_inspect(second_index, content="0")
  debug_inspect(current_buffer.len(), content="1")
  debug_inspect(previous_buffer.len(), content="1")
  debug_inspect(current_uniform.previous_input_index(), content="0")
  debug_inspect(current_uniform.tag(), content="6")
}

///|
test "pbr: remove_mesh_input_uniform removes GPU instance and frees buffer slot" {
  let entity = @render.MainEntity::new(@core.Entity::new(25, 1))
  let instances = RenderMeshInstancesGpu::RenderMeshInstancesGpu()
  let current_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ] = @render_batching.InstanceInputUniformBuffer::new()
  let previous_buffer : @render_batching.InstanceInputUniformBuffer[
    MeshInputUniform,
  ] = @render_batching.InstanceInputUniformBuffer::new()
  let shared = RenderMeshInstanceSharedFlat::new(81, tag=7U)
  let prepared = RenderMeshInstanceGpuPrepared::from_shared(
    shared,
    MeshInputUniform::from_shared(shared),
    None,
  )
  ignore(prepared.update(entity, instances, current_buffer, previous_buffer))

  debug_inspect(
    remove_mesh_input_uniform(entity, instances, current_buffer),
    content="Some(0)",
  )
  debug_inspect(
    instances.render_mesh_queue_data(entity) is None,
    content="true",
  )
  debug_inspect(current_buffer.get(0) is None, content="true")
}

///|
test "pbr: RenderMeshInstanceGpuBuilder prepare waits for non-dummy material bindings" {
  let entity = @render.MainEntity::new(@core.Entity::new(26, 1))
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    entity.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(12)),
  )
  let builder = RenderMeshInstanceGpuBuilder::new(
    RenderMeshQueueData::new(90, 0U, true),
  )

  debug_inspect(
    builder.prepare(
      entity,
      @render_mesh.MeshAllocator::new(),
      material_instances,
      RenderMaterialBindings::RenderMaterialBindings(),
      @lightmap.RenderLightmaps::RenderLightmaps(),
      @pbr_render.SkinUniforms::new(),
      @pbr_render.MorphIndices::new(),
      3U,
    )
    is None,
    content="true",
  )
}

///|
test "pbr: RenderMeshInstanceGpuBuilder prepare builds Bevy mesh input uniform" {
  let entity = @render.MainEntity::new(@core.Entity::new(27, 1))
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    entity.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(12)),
  )
  let material_bindings = RenderMaterialBindings::RenderMaterialBindings()
  material_bindings.set(
    12,
    MaterialBindingId::new(
      MaterialBindGroupIndex::new(2),
      MaterialBindGroupSlot::new(11),
    ),
  )
  let allocator = @render_mesh.MeshAllocator::new()
  ignore(
    allocator.allocate(
      90,
      96,
      @render_mesh.MeshAllocatorElementLayout::vertex(32),
    ),
  )
  ignore(
    allocator.allocate(
      90,
      24,
      @render_mesh.MeshAllocatorElementLayout::index_u32(),
    ),
  )
  let render_lightmaps = @lightmap.RenderLightmaps::RenderLightmaps()
  ignore(
    render_lightmaps.insert_lightmap(
      entity.id(),
      @lightmap.Lightmap::new(@asset.Handle::new(7)),
    ),
  )
  let morph_indices = @pbr_render.MorphIndices::new()
  morph_indices.current.set(entity.id().to_bits(), 33U)
  let flags = RenderMeshInstanceFlags::no_cpu_culling()
  let builder = RenderMeshInstanceGpuBuilder::from_shared(
    RenderMeshInstanceSharedFlat::new(90, tag=8U),
    @math.Affine3::identity(),
    @math.UVec2::new(4, 5),
    None,
    None,
    flags.bits(),
  )
  let prepared = match
    builder.prepare(
      entity,
      allocator,
      material_instances,
      material_bindings,
      render_lightmaps,
      @pbr_render.SkinUniforms::new(),
      morph_indices,
      44U,
    ) {
    Some(value) => value
    None => abort("expected prepared mesh instance")
  }
  let uniform = prepared.mesh_input_uniform()

  debug_inspect(
    prepared.shared.material_bindings_index().slot().to_int(),
    content="11",
  )
  debug_inspect(prepared.shared.lightmap_slab_index(), content="Some(0)")
  debug_inspect(uniform.timestamp, content="44")
  debug_inspect(uniform.flags, content="32")
  debug_inspect(uniform.first_vertex_index, content="0")
  debug_inspect(uniform.first_index_index, content="0")
  debug_inspect(uniform.index_count, content="6")
  debug_inspect(uniform.current_skin_index, content="4294967295")
  debug_inspect(uniform.material_and_lightmap_bind_group_slot, content="11")
  debug_inspect(uniform.tag(), content="8")
  debug_inspect(uniform.morph_descriptor_index, content="33")
}

///|
test "pbr: collect_meshes_for_gpu_building prepares ready CPU-culling queues and reextracts unready materials" {
  let ready = @render.MainEntity::new(@core.Entity::new(28, 1))
  let unready = @render.MainEntity::new(@core.Entity::new(29, 1))
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    ready.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(12)),
  )
  material_instances.extract_mesh_material(
    unready.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(13)),
  )
  let material_bindings = RenderMaterialBindings::RenderMaterialBindings()
  material_bindings.set(
    12,
    MaterialBindingId::new(
      MaterialBindGroupIndex::new(0),
      MaterialBindGroupSlot::new(3),
    ),
  )
  let allocator = @render_mesh.MeshAllocator::new()
  ignore(
    allocator.allocate(
      90,
      96,
      @render_mesh.MeshAllocatorElementLayout::vertex(32),
    ),
  )
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  let buffers : @render_batching.BatchedInstanceBuffers[Unit, MeshInputUniform] = @render_batching.BatchedInstanceBuffers::new()
  let culling_buffer = MeshCullingDataBuffer::MeshCullingDataBuffer()
  let queues = RenderMeshInstanceGpuQueues::RenderMeshInstanceGpuQueues()
  queues.init(false)
  let queue = queues.borrow_local_mut()
  queue.push(
    ready,
    RenderMeshInstanceGpuBuilder::from_shared(
      RenderMeshInstanceSharedFlat::new(90, tag=1U),
      @math.Affine3::identity(),
      @math.UVec2::zero(),
      None,
      None,
      0U,
    ),
    None,
    false,
  )
  queue.push(
    unready,
    RenderMeshInstanceGpuBuilder::new(RenderMeshQueueData::new(91, 0U, true)),
    None,
    false,
  )
  let render_gpu_culled_entities = RenderGpuCulledEntities::RenderGpuCulledEntities()
  let reextract = MeshesToReextractNextFrame::MeshesToReextractNextFrame()

  collect_meshes_for_gpu_building(
    instances,
    buffers,
    culling_buffer,
    queues,
    render_gpu_culled_entities,
    allocator,
    material_instances,
    material_bindings,
    @lightmap.RenderLightmaps::RenderLightmaps(),
    @pbr_render.SkinUniforms::new(),
    @pbr_render.MorphIndices::new(),
    55U,
    reextract,
  )

  debug_inspect(instances.len(), content="1")
  debug_inspect(
    instances.render_mesh_queue_data(ready).unwrap().mesh_asset_id(),
    content="90",
  )
  debug_inspect(buffers.current_input_buffer.len(), content="1")
  debug_inspect(buffers.previous_input_buffer.len(), content="1")
  debug_inspect(reextract.contains(unready), content="true")
  debug_inspect(queue.changed_len(), content="0")
  debug_inspect(render_gpu_culled_entities.added_len(), content="0")
}

///|
test "pbr: collect_meshes_for_gpu_building updates GPU-culling visibility and removals" {
  let entity = @render.MainEntity::new(@core.Entity::new(33, 1))
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    entity.id(),
    true,
    MeshMaterial3d::new(@asset.Handle::new(14)),
  )
  let material_bindings = RenderMaterialBindings::RenderMaterialBindings()
  material_bindings.set(
    14,
    MaterialBindingId::new(
      MaterialBindGroupIndex::new(0),
      MaterialBindGroupSlot::new(4),
    ),
  )
  let allocator = @render_mesh.MeshAllocator::new()
  ignore(
    allocator.allocate(
      92,
      96,
      @render_mesh.MeshAllocatorElementLayout::vertex(32),
    ),
  )
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  let buffers : @render_batching.BatchedInstanceBuffers[Unit, MeshInputUniform] = @render_batching.BatchedInstanceBuffers::new()
  let culling_buffer = MeshCullingDataBuffer::MeshCullingDataBuffer()
  let queues = RenderMeshInstanceGpuQueues::RenderMeshInstanceGpuQueues()
  queues.init(true)
  let queue = queues.borrow_local_mut()
  queue.push(
    entity,
    RenderMeshInstanceGpuBuilder::from_shared(
      RenderMeshInstanceSharedFlat::new(
        92,
        tag=2U,
        flags=RenderMeshInstanceFlags::no_cpu_culling(),
      ),
      @math.Affine3::identity(),
      @math.UVec2::zero(),
      None,
      None,
      RenderMeshInstanceFlags::no_cpu_culling().bits(),
    ),
    Some(MeshCullingData::new(None)),
    true,
  )
  let render_gpu_culled_entities = RenderGpuCulledEntities::RenderGpuCulledEntities()
  let reextract = MeshesToReextractNextFrame::MeshesToReextractNextFrame()

  collect_meshes_for_gpu_building(
    instances,
    buffers,
    culling_buffer,
    queues,
    render_gpu_culled_entities,
    allocator,
    material_instances,
    material_bindings,
    @lightmap.RenderLightmaps::RenderLightmaps(),
    @pbr_render.SkinUniforms::new(),
    @pbr_render.MorphIndices::new(),
    56U,
    reextract,
  )
  debug_inspect(instances.len(), content="1")
  debug_inspect(buffers.current_input_buffer.len(), content="1")
  debug_inspect(culling_buffer.len(), content="1")
  debug_inspect(render_gpu_culled_entities.added_len(), content="1")
  debug_inspect(render_gpu_culled_entities.contains(entity), content="true")

  queues.init(true)
  queue.remove(entity, true)
  collect_meshes_for_gpu_building(
    instances,
    buffers,
    culling_buffer,
    queues,
    render_gpu_culled_entities,
    allocator,
    material_instances,
    material_bindings,
    @lightmap.RenderLightmaps::RenderLightmaps(),
    @pbr_render.SkinUniforms::new(),
    @pbr_render.MorphIndices::new(),
    57U,
    reextract,
  )
  debug_inspect(instances.len(), content="0")
  debug_inspect(buffers.current_input_buffer.get(0) is None, content="true")
  debug_inspect(render_gpu_culled_entities.removed_len(), content="1")
  debug_inspect(render_gpu_culled_entities.contains(entity), content="false")
}

///|
test "pbr: RenderMeshInstanceGpuQueue mirrors Bevy CPU culling state" {
  let queue = RenderMeshInstanceGpuQueue::RenderMeshInstanceGpuQueue()
  let entity = @render.MainEntity::new(@core.Entity::new(30, 1))
  let builder = RenderMeshInstanceGpuBuilder::new(
    RenderMeshQueueData::new(51, 0U, true),
  )
  queue.init(false)
  queue.push(entity, builder, None, false)
  queue.remove(entity, false)
  match queue.state() {
    CpuCulling(cpu_queue) => {
      debug_inspect(cpu_queue.changed.length(), content="1")
      debug_inspect(cpu_queue.removed.length(), content="1")
    }
    _ => abort("queue should be in CPU culling mode")
  }

  queue.init(false)
  debug_inspect(queue.changed_len(), content="0")
  debug_inspect(queue.removed_len(), content="0")
}

///|
test "pbr: RenderMeshInstanceGpuQueue mirrors Bevy GPU culling split queues" {
  let queue = RenderMeshInstanceGpuQueue::RenderMeshInstanceGpuQueue()
  let cpu_entity = @render.MainEntity::new(@core.Entity::new(31, 1))
  let gpu_entity = @render.MainEntity::new(@core.Entity::new(32, 1))
  let builder = RenderMeshInstanceGpuBuilder::new(
    RenderMeshQueueData::new(52, 2U, true),
  )
  let culling_data = MeshCullingData::new(None)
  queue.init(true)
  queue.push(cpu_entity, builder, Some(culling_data), false)
  queue.push(gpu_entity, builder, Some(culling_data), true)
  queue.remove(gpu_entity, true)

  match queue.state() {
    GpuCulling(gpu_queue) => {
      debug_inspect(gpu_queue.changed_cpu_culling.length(), content="1")
      debug_inspect(gpu_queue.changed_gpu_culling.length(), content="1")
      debug_inspect(gpu_queue.removed.length(), content="1")
    }
    _ => abort("queue should be in GPU culling mode")
  }
  debug_inspect(queue.changed_len(), content="2")
  debug_inspect(queue.gpu_changed_cpu_culling_len(), content="1")
  debug_inspect(queue.gpu_changed_gpu_culling_len(), content="1")
}

///|
test "pbr: MeshesToReextractNextFrame drains all render mesh instances" {
  let first = @render.MainEntity::new(@core.Entity::new(40, 1))
  let second = @render.MainEntity::new(@core.Entity::new(41, 1))
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  instances.insert(first, RenderMeshQueueData::new(60, 0U, true))
  instances.insert(second, RenderMeshQueueData::new(61, 0U, true))
  let meshes_to_reextract = MeshesToReextractNextFrame::MeshesToReextractNextFrame()

  mark_all_meshes_for_reextraction(instances, meshes_to_reextract)

  debug_inspect(instances.len(), content="0")
  debug_inspect(meshes_to_reextract.len(), content="2")
  debug_inspect(meshes_to_reextract.contains(first), content="true")
  debug_inspect(meshes_to_reextract.contains(second), content="true")
}

///|
test "pbr: RenderMeshInstanceFlags preserves Bevy bit values" {
  let flags = RenderMeshInstanceFlags::shadow_caster()
    .or(RenderMeshInstanceFlags::automatic_batching())
    .or(RenderMeshInstanceFlags::has_previous_transform())
    .or(RenderMeshInstanceFlags::has_previous_skin())
    .or(RenderMeshInstanceFlags::has_previous_morph())
    .or(RenderMeshInstanceFlags::no_cpu_culling())

  debug_inspect(flags.bits(), content="63")
  debug_inspect(
    flags.contains(RenderMeshInstanceFlags::has_previous_skin()),
    content="true",
  )
  debug_inspect(
    RenderMeshInstanceFlags::empty().contains(
      RenderMeshInstanceFlags::shadow_caster(),
    ),
    content="false",
  )
}

///|
test "pbr: RenderMeshInstanceFlags mirrors Bevy extraction flags" {
  let default_flags = RenderMeshInstanceFlags::from_extraction_components(
    false, false, false, false, false, false,
  )
  debug_inspect(default_flags.bits(), content="3")
  debug_inspect(
    default_flags.contains(RenderMeshInstanceFlags::shadow_caster()),
    content="true",
  )
  debug_inspect(
    default_flags.contains(RenderMeshInstanceFlags::automatic_batching()),
    content="true",
  )

  let disabled_flags = RenderMeshInstanceFlags::from_extraction_components(
    true, true, true, true, true, true,
  )
  debug_inspect(disabled_flags.bits(), content="60")
  debug_inspect(
    disabled_flags.contains(RenderMeshInstanceFlags::shadow_caster()),
    content="false",
  )
  debug_inspect(
    disabled_flags.contains(RenderMeshInstanceFlags::automatic_batching()),
    content="false",
  )
}

///|
fn render_mesh_instances_test_mesh(
  entity_id : Int,
  mesh_id : Int,
  has_no_cpu_culling? : Bool = false,
  has_previous_transform? : Bool = false,
  lightmap? : Lightmap? = None,
) -> ExtractedMesh3d {
  render_mesh_instances_test_mesh_for_entity(
    @core.Entity::new(entity_id, 0),
    mesh_id,
    has_no_cpu_culling~,
    has_previous_transform~,
    lightmap~,
  )
}

///|
fn render_mesh_instances_test_mesh_for_entity(
  entity : @core.Entity,
  mesh_id : Int,
  has_no_cpu_culling? : Bool = false,
  has_previous_transform? : Bool = false,
  lightmap? : Lightmap? = None,
) -> ExtractedMesh3d {
  let transform = @transform.Transform::identity()
  let world_from_local = @math.Affine3::identity()
  ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(entity),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(mesh_id),
      mesh_id,
      mesh_topology_kind: 0,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material: @material.StandardMaterial::StandardMaterial(),
      material_extension: None,
      material_properties: @material.MaterialProperties::MaterialProperties(),
      material_bind_group_data: @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
      material_vertex_shader_path: None,
      material_fragment_shader_path: None,
      material_pipeline_id: None,
      lightmap,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_automatic_batching: false,
      has_no_cpu_culling,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
      has_no_wireframe: false,
      wireframe_asset_id: None,
      wireframe_material: None,
      wireframe_color: None,
      wireframe_line_width: None,
      wireframe_topology: None,
      skinning_key_hi: -1,
      has_previous_transform,
      has_previous_skin: false,
      has_previous_morph: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
      motion_vector_enabled: false,
    },
  }
}

///|
fn render_mesh_instances_test_insert_gpu_source_mesh(
  source_world : @ecs.World,
  entity : @core.Entity,
  mesh_id : Int,
  visible? : Bool = true,
) -> Unit {
  try! source_world.set_by_key(
    entity,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(mesh_id)),
  )
  try! source_world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    @visibility.ViewVisibility::new(visible),
  )
  try! source_world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::identity(),
  )
}

///|
test "pbr: GPU-building extraction does not remove stale meshes without source removal" {
  let world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let first = source_world.spawn()
  let second = source_world.spawn()
  render_mesh_instances_test_insert_gpu_source_mesh(source_world, first, 110)
  render_mesh_instances_test_insert_gpu_source_mesh(source_world, second, 111)
  try! source_world.set_by_key(
    second,
    @visibility.ecs_key_no_cpu_culling,
    @visibility.NoCpuCulling::NoCpuCulling(),
  )
  let stale_entity = @render.MainEntity::new(@core.Entity::new(99, 0))
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  instances.insert(stale_entity, RenderMeshQueueData::new(199, 3U, true))
  world.insert_resource(RenderMeshInstances::resource(), instances)

  render_mesh_instances_extract_gpu_building_resource(world, source_world, true)

  let queues = match
    world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(value) => value
    None => abort("missing GPU mesh queues")
  }
  let queue = queues.borrow_local_mut()
  match queue.state() {
    GpuCulling(gpu_queue) => {
      debug_inspect(gpu_queue.changed_cpu_culling.length(), content="1")
      debug_inspect(gpu_queue.changed_gpu_culling.length(), content="1")
      debug_inspect(gpu_queue.removed.length(), content="0")
    }
    _ => abort("expected GPU culling queue")
  }
}

///|
test "pbr: GPU-building extraction preserves previous input index and lightmap packing" {
  let world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let source_entity = source_world.spawn()
  let entity = @render.MainEntity::new(source_entity)
  render_mesh_instances_test_insert_gpu_source_mesh(
    source_world, source_entity, 212,
  )
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  instances.insert(entity, RenderMeshQueueData::new(212, 5U, true))
  world.insert_resource(RenderMeshInstances::resource(), instances)
  let reextract = MeshesToReextractNextFrame::MeshesToReextractNextFrame()
  reextract.insert(entity)
  world.insert_resource(MeshesToReextractNextFrame::resource(), reextract)
  let lightmap = Lightmap::new(@asset.Handle::new(7)).with_uv_rect(
    @math.Rect::new(@math.Vec2::new(0.25F, 0.5F), @math.Vec2::new(0.75F, 1.0F)),
  )
  try! source_world.set_by_key(source_entity, ecs_key_lightmap, lightmap)
  try! source_world.set_by_key(
    source_entity,
    ecs_key_previous_global_transform,
    @pbr_prepass.PreviousGlobalTransform::from_global_transform(
      @transform.GlobalTransform::identity(),
    ),
  )

  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )

  let queues = match
    world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(value) => value
    None => abort("missing GPU mesh queues")
  }
  match queues.borrow_local_mut().state() {
    CpuCulling(cpu_queue) => {
      debug_inspect(cpu_queue.changed.length(), content="1")
      let (_, builder) = cpu_queue.changed[0]
      debug_inspect(builder.previous_input_index, content="Some(5)")
      debug_inspect(builder.lightmap_uv_rect.x, content="-2147467264")
      debug_inspect(builder.lightmap_uv_rect.y, content="-16385")
    }
    _ => abort("expected CPU culling queue")
  }
}

///|
test "pbr: GPU-building extraction skips unchanged known meshes until reextract" {
  let world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let source_entity = source_world.spawn()
  let entity = @render.MainEntity::new(source_entity)
  render_mesh_instances_test_insert_gpu_source_mesh(
    source_world, source_entity, 213,
  )
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  instances.insert(entity, RenderMeshQueueData::new(213, 6U, true))
  world.insert_resource(RenderMeshInstances::resource(), instances)

  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )
  let queues = match
    world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(value) => value
    None => abort("missing GPU mesh queues")
  }
  debug_inspect(queues.borrow_local_mut().changed_len(), content="1")

  ignore(source_world.increment_change_tick())
  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )

  debug_inspect(queues.borrow_local_mut().changed_len(), content="0")

  let reextract = MeshesToReextractNextFrame::MeshesToReextractNextFrame()
  reextract.insert(entity)
  world.insert_resource(MeshesToReextractNextFrame::resource(), reextract)
  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )
  debug_inspect(queues.borrow_local_mut().changed_len(), content="1")
}

///|
test "pbr: GPU-building extraction queues source changed meshes" {
  let world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let entity = source_world.spawn()
  ignore(source_world.increment_change_tick())
  render_mesh_instances_test_insert_gpu_source_mesh(source_world, entity, 214)
  let main_entity = @render.MainEntity::new(entity)
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  instances.insert(main_entity, RenderMeshQueueData::new(214, 7U, true))
  world.insert_resource(RenderMeshInstances::resource(), instances)

  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )

  let queues = match
    world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(value) => value
    None => abort("missing GPU mesh queues")
  }
  debug_inspect(queues.borrow_local_mut().changed_len(), content="1")
}

///|
test "pbr: GPU-building extraction removes changed hidden meshes" {
  let world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let entity = source_world.spawn()
  render_mesh_instances_test_insert_gpu_source_mesh(
    source_world,
    entity,
    215,
    visible=false,
  )
  let main_entity = @render.MainEntity::new(entity)
  let instances = RenderMeshInstances::new(use_gpu_instance_buffer_builder=true)
  instances.insert(main_entity, RenderMeshQueueData::new(215, 8U, true))
  world.insert_resource(RenderMeshInstances::resource(), instances)

  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )

  let queues = match
    world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(value) => value
    None => abort("missing GPU mesh queues")
  }
  debug_inspect(queues.borrow_local_mut().removed_len(), content="1")
}

///|
test "pbr: GPU-building extraction keeps material-unready meshes for reextract" {
  let world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let entity = source_world.spawn()
  render_mesh_instances_test_insert_gpu_source_mesh(source_world, entity, 216)
  world.insert_resource(
    RenderMeshInstances::resource(),
    RenderMeshInstances::new(use_gpu_instance_buffer_builder=true),
  )
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    entity,
    true,
    MeshMaterial3d::new(@asset.Handle::new(2160)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  ignore(
    mesh_allocator.allocate_render_mesh(
      216,
      @render_mesh.RenderMesh::new(vertex_count=3, indexed=true, index_count=3),
      32,
    ),
  )
  world.insert_resource(@render_mesh.MeshAllocator::resource(), mesh_allocator)

  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )
  let queues = match
    world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(value) => value
    None => abort("missing GPU mesh queues")
  }
  debug_inspect(queues.borrow_local_mut().changed_len(), content="1")

  render_mesh_instances_collect_gpu_building_resource(world)

  let reextract = match
    world.get_resource(MeshesToReextractNextFrame::resource()) {
    Some(value) => value
    None => abort("missing reextract resource")
  }
  debug_inspect(reextract.len(), content="1")
  debug_inspect(
    reextract.contains(@render.MainEntity::new(entity)),
    content="true",
  )
  let instances = match world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None => abort("missing RenderMeshInstances")
  }
  debug_inspect(instances.len(), content="0")
}

///|
test "pbr: GPU-building extraction reads source removed Mesh3d entities" {
  let source_world = @ecs.World::new()
  let entity = source_world.spawn()
  try! source_world.set_by_key(
    entity,
    @mesh.ecs_key_mesh3d,
    @mesh.Mesh3d::new(@asset.Handle::new(313)),
  )
  ignore(source_world.increment_change_tick())
  debug_inspect(
    try! source_world.remove_by_key(entity, @mesh.ecs_key_mesh3d),
    content="true",
  )

  let removed = render_mesh_instances_gpu_removed_mesh3d_set(
    source_world,
    @core.SystemTicks::new(0, source_world.read_change_tick()),
  )
  debug_inspect(removed.length(), content="1")
  debug_inspect(removed.contains(entity.to_bits()), content="true")
}

///|
test "pbr: material bind group preparation records bindless material bindings" {
  let mesh = render_mesh_instances_test_mesh(20, 120)
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    mesh.entity.main_entity,
    true,
    MeshMaterial3d::new(@asset.Handle::new(21)),
  )
  let render_material_bindings = RenderMaterialBindings::RenderMaterialBindings()
  let material_bind_group_allocators = MaterialBindGroupAllocators::MaterialBindGroupAllocators()
  material_bind_group_allocators.insert(
    "StandardMaterial",
    MaterialBindGroupAllocator::Bindless(
      MaterialBindGroupBindlessAllocator::with_slab_capacity(4),
    ),
  )

  render3d_prepare_extracted_mesh_material_bind_group(
    mesh,
    {},
    Some(material_instances),
    Some(render_material_bindings),
    Some(material_bind_group_allocators),
  )

  match render_material_bindings.get(21) {
    Some(binding) => {
      debug_inspect(binding.group().to_int(), content="0")
      debug_inspect(binding.slot().to_int(), content="0")
    }
    None => abort("missing prepared material binding")
  }
}

///|
test "pbr: runtime GPU-building collect consumes queued meshes" {
  let world = @ecs.World::new()
  let source_world = @ecs.World::new()
  let entity = source_world.spawn()
  render_mesh_instances_test_insert_gpu_source_mesh(source_world, entity, 130)
  world.insert_resource(
    RenderMeshInstances::resource(),
    RenderMeshInstances::new(use_gpu_instance_buffer_builder=true),
  )
  let material_instances = RenderMaterialInstances::RenderMaterialInstances()
  material_instances.extract_mesh_material(
    entity,
    true,
    MeshMaterial3d::new(@asset.Handle::new(31)),
  )
  world.insert_resource(ecs_key_render_material_instances, material_instances)
  let render_material_bindings = RenderMaterialBindings::RenderMaterialBindings()
  render_material_bindings.set(
    31,
    MaterialBindingId::new(
      MaterialBindGroupIndex::new(0),
      MaterialBindGroupSlot::new(0),
    ),
  )
  world.insert_resource(
    RenderMaterialBindings::resource(),
    render_material_bindings,
  )
  let mesh_allocator = @render_mesh.MeshAllocator::new()
  ignore(
    mesh_allocator.allocate_render_mesh(
      130,
      @render_mesh.RenderMesh::new(vertex_count=3, indexed=true, index_count=3),
      32,
    ),
  )
  world.insert_resource(@render_mesh.MeshAllocator::resource(), mesh_allocator)

  render_mesh_instances_extract_gpu_building_resource(
    world, source_world, false,
  )
  render_mesh_instances_collect_gpu_building_resource(world)

  let instances = match world.get_resource(RenderMeshInstances::resource()) {
    Some(value) => value
    None => abort("missing RenderMeshInstances")
  }
  debug_inspect(instances.len(), content="1")
  let buffers = match
    world.get_resource(RenderMeshInstanceGpuBatchedInstanceBuffers::resource()) {
    Some(value) => value
    None => abort("missing GPU batched instance buffers")
  }
  debug_inspect(buffers.current_input_len(), content="1")
  let queues = match
    world.get_resource(RenderMeshInstanceGpuQueues::resource()) {
    Some(value) => value
    None => abort("missing GPU queues")
  }
  debug_inspect(queues.borrow_local_mut().changed_len(), content="0")
  let reextract = match
    world.get_resource(MeshesToReextractNextFrame::resource()) {
    Some(value) => value
    None => abort("missing reextract resource")
  }
  debug_inspect(reextract.len(), content="0")
}
