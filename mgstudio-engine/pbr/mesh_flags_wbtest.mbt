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
fn render3d_flags_approx_eq(lhs : Float, rhs : Float) -> Bool {
  let delta = lhs - rhs
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d: standard material flags pack current Bevy subset bits" {
  let material = @material.StandardMaterial::StandardMaterial()
    .with_unlit(true)
    .with_double_sided(true)
    .with_flip_normal_map_y(true)
    .with_alpha_mode(Mask(0.37F))
  let flags = @pbr_render.render3d_standard_material_flags(
    material,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    specular_texture_id=19,
  )
  let ok = (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_BASE_COLOR_TEXTURE_BIT) !=
    0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_EMISSIVE_TEXTURE_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_METALLIC_ROUGHNESS_TEXTURE_BIT) !=
    0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_OCCLUSION_TEXTURE_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_DOUBLE_SIDED_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_UNLIT_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_DEPTH_MAP_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_ANISOTROPY_TEXTURE_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TEXTURE_BIT) != 0U &&
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_SPECULAR_TINT_TEXTURE_BIT) !=
    0U &&
    (flags & (7U << 29)) == @pbr_render.STANDARD_MATERIAL_FLAGS_ALPHA_MODE_MASK
  debug_inspect(ok, content="true")
  debug_inspect(
    render3d_flags_approx_eq(
      @pbr_render.render3d_standard_material_alpha_cutoff(material.alpha_mode),
      0.37F,
    ),
    content="true",
  )
}

///|
test "render3d: forward decal specialization bit is carried into material flags" {
  let flags = @pbr_render.render3d_standard_material_flags(
    @material.StandardMaterial::StandardMaterial(),
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    forward_decal=true,
  )
  debug_inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_FORWARD_DECAL_BIT) != 0U,
    content="true",
  )
}

///|
test "render3d: standard material flags keep opaque default when maps are absent" {
  let flags = @pbr_render.render3d_standard_material_flags(
    @material.StandardMaterial::StandardMaterial(),
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
  )
  debug_inspect(
    flags ==
    (
      @pbr_render.STANDARD_MATERIAL_FLAGS_ALPHA_MODE_OPAQUE |
      @pbr_render.STANDARD_MATERIAL_FLAGS_FOG_ENABLED_BIT
    ),
    content="true",
  )
}

///|
test "render3d: normal map encoding bits stay host-minimal without bound texture" {
  let flags = @pbr_render.render3d_standard_material_flags(
    @material.StandardMaterial::StandardMaterial().with_flip_normal_map_y(true),
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
  )
  debug_inspect(
    (flags & @pbr_render.STANDARD_MATERIAL_FLAGS_FLIP_NORMAL_MAP_Y) == 0U &&
    (flags & (1U << 6)) == 0U,
    content="true",
  )
}

///|
test "render3d: preprocess indirect index maps preserve per-draw indexed slots" {
  let draw_items = [
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(1, 0)),
      extracted_index: 0,
      phase: RENDER3D_PHASE_OPAQUE,
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 1.0F,
    },
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(2, 0)),
      extracted_index: 1,
      phase: RENDER3D_PHASE_OPAQUE,
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 2.0F,
    },
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(3, 0)),
      extracted_index: 2,
      phase: RENDER3D_PHASE_ALPHA_MASK,
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 3.0F,
    },
  ]
  let (indexed, non_indexed) = render3d_gpu_preprocess_indirect_parameter_index_maps(
    draw_items,
    GpuPreprocessWorkItemBuffers3d::Indirect(
      [
        GpuPreprocessShaderWorkItem3d::{
          input_index: 0,
          output_or_indirect_parameters_index: 0,
        },
        GpuPreprocessShaderWorkItem3d::{
          input_index: 2,
          output_or_indirect_parameters_index: 1,
        },
      ],
      [
        GpuPreprocessShaderWorkItem3d::{
          input_index: 1,
          output_or_indirect_parameters_index: 0,
        },
      ],
      None,
    ),
  )
  debug_inspect(
    indexed.length() == 3 &&
    non_indexed.length() == 3 &&
    indexed[0] == 0 &&
    indexed[1] == -1 &&
    indexed[2] == 1 &&
    non_indexed[0] == -1 &&
    non_indexed[1] == 0 &&
    non_indexed[2] == -1,
    content="true",
  )
}

///|
test "render3d: shared phase work-item buffers convert to gpu preprocess payload" {
  let direct = @render_batching.preprocess_work_item_buffers_direct()
  direct.push(false, @render_batching.PreprocessWorkItem::new(4, 8))
  match render3d_build_gpu_preprocess_work_item_buffers_from_phase(direct) {
    Direct(items) => {
      debug_inspect(items.length(), content="1")
      debug_inspect(items[0].input_index, content="4")
      debug_inspect(items[0].output_or_indirect_parameters_index, content="8")
    }
    Indirect(_, _, _) => abort("expected direct work-item payload")
  }

  let indirect = @render_batching.preprocess_work_item_buffers_indirect(true)
  indirect.push(true, @render_batching.PreprocessWorkItem::new(5, 9))
  indirect.push(false, @render_batching.PreprocessWorkItem::new(6, 10))
  indirect.push_multiple_late_uninit(true, 1)
  match render3d_build_gpu_preprocess_work_item_buffers_from_phase(indirect) {
    Direct(_) => abort("expected indirect work-item payload")
    Indirect(indexed, non_indexed, culling) => {
      debug_inspect(indexed.length(), content="1")
      debug_inspect(non_indexed.length(), content="1")
      debug_inspect(culling is Some(_), content="true")
      debug_inspect(indexed[0].input_index, content="5")
      debug_inspect(
        non_indexed[0].output_or_indirect_parameters_index,
        content="10",
      )
    }
  }
}

///|
test "render3d: shared indirect parameter buffers convert to gpu preprocess metadata" {
  let buffers = @render_batching.UntypedPhaseIndirectParametersBuffers::new(
    false,
  )
  ignore(buffers.allocate(true, 2))
  buffers.set_cpu_metadata(
    true,
    0,
    @render_batching.IndirectParametersCpuMetadata::new(12, 3),
  )
  buffers.set_cpu_metadata(
    true,
    1,
    @render_batching.IndirectParametersCpuMetadata::new(14, 3),
  )
  buffers.add_batch_set(true, 2)
  let metadata = render3d_build_gpu_preprocess_indirect_metadata_from_phase(
    buffers,
  )
  debug_inspect(
    metadata.indexed.indirect_parameters_cpu_metadata.length(),
    content="2",
  )
  debug_inspect(
    metadata.indexed.indirect_parameters_gpu_metadata.length(),
    content="2",
  )
  debug_inspect(metadata.indexed.indirect_batch_sets.length(), content="1")
  debug_inspect(
    metadata.indexed.indirect_parameters_cpu_metadata[0].base_output_index,
    content="12",
  )
  debug_inspect(
    metadata.indexed.indirect_parameters_cpu_metadata[1].batch_set_index,
    content="3",
  )
  debug_inspect(
    metadata.indexed.indirect_batch_sets[0].indirect_parameters_base,
    content="2",
  )
}

///|
test "render3d: gpu preprocess queue entry can consume shared phase buffers" {
  let draw_items = [
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(41, 0)),
      extracted_index: -1,
      phase: RENDER3D_PHASE_OPAQUE,
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 1.0F,
    },
  ]
  let work_items = @render_batching.preprocess_work_item_buffers_indirect(false)
  work_items.push(true, @render_batching.PreprocessWorkItem::new(7, 0))
  let indirect_buffers = @render_batching.UntypedPhaseIndirectParametersBuffers::new(
    false,
  )
  ignore(indirect_buffers.allocate(true, 1))
  indirect_buffers.set_cpu_metadata(
    true,
    0,
    @render_batching.IndirectParametersCpuMetadata::new(3, 0),
  )
  indirect_buffers.add_batch_set(true, 0)
  let entry = render3d_build_gpu_preprocess_queue_entry_from_phase_buffers(
    draw_items,
    [],
    {},
    work_items,
    indirect_buffers,
  )
  debug_inspect(entry.phase_ranges.length(), content="1")
  debug_inspect(entry.mesh_culling_data.length(), content="1")
  match entry.work_item_buffers {
    Direct(_) => abort("expected indirect queue work items")
    Indirect(indexed, non_indexed, _) => {
      debug_inspect(indexed.length(), content="1")
      debug_inspect(non_indexed.length(), content="0")
      debug_inspect(indexed[0].input_index, content="7")
      debug_inspect(indexed[0].output_or_indirect_parameters_index, content="0")
    }
  }
  debug_inspect(
    entry.indirect_metadata.indexed.indirect_parameters_cpu_metadata[0].base_output_index,
    content="3",
  )
  debug_inspect(
    entry.indirect_metadata.indexed.indirect_batch_sets[0].indirect_parameters_base,
    content="0",
  )
}

///|
test "render3d: draw-item queue entry stores Bevy-shaped indirect metadata" {
  let mesh_preprocess_static_cache : Map[Int, MeshPreprocessStatic3d] = {}
  mesh_preprocess_static_cache.set(1, MeshPreprocessStatic3d::{
    topology_kind: 0,
    is_indexed: true,
    first_vertex_index: 0,
    first_index_index: 0,
    index_count: 3,
    has_local_aabb: false,
    aabb_center: @math.Vec3::zero(),
    aabb_half_extents: @math.Vec3::zero(),
  })
  let draw_items = [
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(42, 0)),
      extracted_index: 0,
      phase: RENDER3D_PHASE_OPAQUE,
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 1.0F,
    },
  ]
  let entry = render3d_build_gpu_preprocess_queue_entry(
    draw_items,
    [
      render3d_test_extracted_mesh_for_flags(
        false,
        false,
        false,
        @math.Vec3::new(1.0F, 1.0F, 1.0F),
      ),
    ],
    mesh_preprocess_static_cache,
    true,
    false,
  )
  match entry.work_item_buffers {
    Direct(_) => abort("expected indirect queue work items")
    Indirect(indexed, non_indexed, culling) => {
      debug_inspect(indexed.length(), content="1")
      debug_inspect(non_indexed.length(), content="0")
      debug_inspect(culling is None, content="true")
      debug_inspect(indexed[0].input_index, content="0")
      debug_inspect(indexed[0].output_or_indirect_parameters_index, content="0")
    }
  }
  debug_inspect(
    entry.indirect_metadata.indexed.indirect_parameters_cpu_metadata[0].base_output_index,
    content="0",
  )
  debug_inspect(
    entry.indirect_metadata.indexed.indirect_parameters_cpu_metadata[0].batch_set_index,
    content="-1",
  )
  debug_inspect(
    entry.indirect_metadata.indexed.indirect_parameters_gpu_metadata[0].mesh_index,
    content="0",
  )
  debug_inspect(
    entry.indirect_metadata.indexed.indirect_batch_sets[0].indirect_parameters_base,
    content="0",
  )
}

///|
test "render3d: camera indirect path requires feature support and no marker" {
  debug_inspect(
    @pbr_render.render3d_camera_indirect_enabled(true, true, false) &&
    !@pbr_render.render3d_camera_indirect_enabled(true, false, false) &&
    !@pbr_render.render3d_camera_indirect_enabled(true, true, true) &&
    !@pbr_render.render3d_camera_indirect_enabled(false, true, false),
    content="true",
  )
}

///|
fn render3d_test_extracted_mesh_for_flags(
  has_no_frustum_culling : Bool,
  has_not_shadow_receiver : Bool,
  has_transmitted_shadow_receiver : Bool,
  scale : @math.Vec3,
) -> ExtractedMesh3d {
  let transform = @transform.Transform::identity().with_scale(scale)
  let world_from_local = @math.Affine3::from_scale_rotation_translation(
    scale,
    @math.Quat::identity(),
    @math.Vec3::zero(),
  )
  ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(@core.Entity::new(1, 0)),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(1),
      mesh_id: 1,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material_draw_data: MaterialDrawData3d::Standard(
        @material.StandardMaterial::StandardMaterial(),
      ),
      material_extension: None,
      material_properties: @material.MaterialProperties::MaterialProperties(),
      material_bind_group_data: @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver,
      has_transmitted_shadow_receiver,
      has_no_frustum_culling,
      has_no_cpu_culling: false,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
      has_no_wireframe: false,
      wireframe_asset_id: None,
      wireframe_material: None,
      wireframe_color: None,
      wireframe_line_width: None,
      wireframe_topology: None,
      skinning_key_hi: -1,
      has_previous_skin: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
      motion_vector_enabled: false,
    },
  }
}

///|
fn render3d_test_transparent_mesh_for_queue(
  entity_id : Int,
  z : Float,
  depth_bias : Float,
) -> ExtractedMesh3d {
  let transform = @transform.Transform::from_xyz(0.0F, 0.0F, z)
  let world_from_local = @math.Affine3::from_translation(transform.translation)
  let material = @material.StandardMaterial::StandardMaterial().with_alpha_mode(
    @material.AlphaMode3d::Blend,
  )
  ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(@core.Entity::new(entity_id, 0)),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(entity_id),
      mesh_id: entity_id,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material_draw_data: MaterialDrawData3d::Standard(material),
      material_extension: None,
      material_properties: render3d_material_properties_for_standard_material(
        material,
        None,
        OpaqueRendererMethod::Forward,
        true,
      ).with_depth_bias(depth_bias),
      material_bind_group_data: @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_cpu_culling: false,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
      has_no_wireframe: false,
      wireframe_asset_id: None,
      wireframe_material: None,
      wireframe_color: None,
      wireframe_line_width: None,
      wireframe_topology: None,
      skinning_key_hi: -1,
      has_previous_skin: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
      motion_vector_enabled: false,
    },
  }
}

///|
fn render3d_test_queue_pipeline_cache(
  meshes : Array[ExtractedMesh3d],
) -> (@render_view.RetainedViewEntity, SpecializedMaterialPipelineCache) {
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(5000, 0))
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  for mesh in meshes {
    cache.insert(
      view,
      mesh.entity.main_entity,
      1,
      @material.CachedRenderPipelineId::new(77UL),
    )
  }
  (view, cache)
}

///|
fn render3d_test_queue_material_slots(
  meshes : Array[ExtractedMesh3d],
) -> RenderMaterial3dResolvedSlots {
  let slots = RenderMaterial3dResolvedSlots::new()
  for mesh in meshes {
    let payload = mesh.payload
    slots.set_resolved(
      mesh.entity.main_entity,
      Render3dResolvedMaterial::new(
        payload.material_draw_data,
        payload.material_properties,
        payload.material_bind_group_data,
        "StandardMaterial",
        material_extension=payload.material_extension,
      ),
    )
  }
  slots
}

///|
test "render3d: transparent phase ordering includes bevy material depth bias" {
  let meshes = [
    render3d_test_transparent_mesh_for_queue(1, -1.0F, 0.0F),
    render3d_test_transparent_mesh_for_queue(2, -1.0F, 2.0F),
  ]
  let (view, cache) = render3d_test_queue_pipeline_cache(meshes)
  let material_slots = render3d_test_queue_material_slots(meshes)
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let camera_transform = @transform.Transform::identity()
  let cpu_items = render3d_queue_mesh_phase_items(
    meshes,
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    camera_transform,
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    meshes,
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    camera_transform,
    [],
    false,
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(cpu_items[0].entity.main_entity.id, content="2")
  debug_inspect(cpu_items[0].distance, content="3")
  debug_inspect(gpu_items[0].entity.main_entity.id, content="2")
  debug_inspect(gpu_items[0].distance, content="3")
}

///|
test "render3d: queue phase uses bevy MaterialProperties render phase" {
  let base = render3d_test_extracted_mesh_for_flags(
    false,
    false,
    false,
    @math.Vec3::splat(1.0F),
  )
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_alpha_mode(@material.AlphaMode3d::Blend)
    .with_render_phase_type(@material.RenderPhaseType::Transparent)
  let mesh = ExtractedMesh3d::{
    ..base,
    payload: Mesh3dExtractedPayload::{
      ..base.payload,
      material_properties: properties,
    },
  }
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(cpu_items[0].phase, content="3")
  debug_inspect(gpu_items[0].phase, content="3")
}

///|
test "render3d: queue phase reads material properties from resolved material slots" {
  let payload_properties = @material.MaterialProperties::MaterialProperties()
    .with_alpha_mode(@material.AlphaMode3d::Opaque)
    .with_render_phase_type(@material.RenderPhaseType::Opaque)
  let slot_properties = @material.MaterialProperties::MaterialProperties()
    .with_alpha_mode(@material.AlphaMode3d::Blend)
    .with_render_phase_type(@material.RenderPhaseType::Transparent)
    .with_depth_bias(4.0F)
  let material = @material.StandardMaterial::StandardMaterial().with_alpha_mode(
    @material.AlphaMode3d::Blend,
  )
  let base = render3d_test_extracted_mesh_for_flags(
    false,
    false,
    false,
    @math.Vec3::splat(1.0F),
  )
  let mesh = ExtractedMesh3d::{
    ..base,
    payload: Mesh3dExtractedPayload::{
      ..base.payload,
      material_draw_data: MaterialDrawData3d::Standard(material),
      material_properties: payload_properties,
    },
  }
  let material_slots = RenderMaterial3dResolvedSlots::new()
  material_slots.set_resolved(
    mesh.entity.main_entity,
    Render3dResolvedMaterial::new(
      MaterialDrawData3d::Standard(material),
      slot_properties,
      @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
      "StandardMaterial",
    ),
  )
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(cpu_items[0].phase, content="3")
  debug_inspect(cpu_items[0].distance, content="4")
  debug_inspect(gpu_items[0].phase, content="3")
  debug_inspect(gpu_items[0].distance, content="4")
}

///|
test "render3d: queue phase returns missing resolved material slots to pending queue" {
  let mesh = render3d_test_transparent_mesh_for_queue(9, -1.0F, 0.0F)
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = RenderMaterial3dResolvedSlots::new()
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(items.length(), content="0")
  debug_inspect(pending_queues.current_len(view), content="1")
}

///|
test "render3d: volumetric_fog Cube material queues into Bevy opaque phase" {
  let cube_material = @material.StandardMaterial::StandardMaterial()
    .with_normal_map_texture(Some(@asset.Handle::new(1)))
    .with_cull_mode(None)
    .with_alpha_mode(@material.AlphaMode3d::Opaque)
    .with_metallic(0.0F)
    .with_perceptual_roughness(0.5F)
  let properties = render3d_material_properties_for_standard_material(
    cube_material,
    None,
    OpaqueRendererMethod::Forward,
    true,
  )
  let base = render3d_test_extracted_mesh_for_flags(
    false,
    false,
    false,
    @math.Vec3::splat(1.0F),
  )
  let mesh = ExtractedMesh3d::{
    ..base,
    payload: Mesh3dExtractedPayload::{
      ..base.payload,
      material_draw_data: MaterialDrawData3d::Standard(cube_material),
      material_properties: properties,
    },
  }
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(
    properties.render_phase_type is @material.RenderPhaseType::Opaque,
    content="true",
  )
  debug_inspect(cpu_items.length(), content="1")
  debug_inspect(cpu_items[0].phase, content="0")
  debug_inspect(cpu_items[0].phase == RENDER3D_PHASE_OPAQUE, content="true")
  debug_inspect(cpu_items[0].entity.main_entity.id, content="1")
  debug_inspect(cpu_items[0].extracted_index, content="0")
  debug_inspect(cpu_items[0].pipeline_id.id(), content="77")
  debug_inspect(gpu_items.length(), content="1")
  debug_inspect(gpu_items[0].phase, content="0")
  debug_inspect(gpu_items[0].phase == RENDER3D_PHASE_OPAQUE, content="true")
  debug_inspect(gpu_items[0].entity.main_entity.id, content="1")
  debug_inspect(gpu_items[0].extracted_index, content="0")
  debug_inspect(gpu_items[0].pipeline_id.id(), content="77")
}

///|
test "render3d: queue phase consumes RenderVisibleEntities main entity filter" {
  let meshes = [
    render3d_test_transparent_mesh_for_queue(1, -1.0F, 0.0F),
    render3d_test_transparent_mesh_for_queue(2, -1.0F, 2.0F),
  ]
  let visible : Map[UInt64, Bool] = {}
  visible.set(meshes[1].entity.main_entity.to_bits(), true)
  let (view, cache) = render3d_test_queue_pipeline_cache(meshes)
  let material_slots = render3d_test_queue_material_slots(meshes)
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    meshes,
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
    visible_main_entities=Some(visible),
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    meshes,
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
    visible_main_entities=Some(visible),
  )
  debug_inspect(cpu_items.length(), content="1")
  debug_inspect(cpu_items[0].entity.main_entity.id, content="2")
  debug_inspect(cpu_items[0].extracted_index, content="1")
  debug_inspect(gpu_items.length(), content="1")
  debug_inspect(gpu_items[0].entity.main_entity.id, content="2")
  debug_inspect(gpu_items[0].extracted_index, content="1")
}

///|
test "render3d: queue phase skips view cache misses" {
  let mesh = render3d_test_transparent_mesh_for_queue(5, -1.0F, 0.0F)
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(6, 0))
  let cache = SpecializedMaterialPipelineCache::SpecializedMaterialPipelineCache()
  let cpu_miss = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_miss = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(cpu_miss.length(), content="0")
  debug_inspect(gpu_miss.length(), content="0")

  cache.insert(
    view,
    mesh.entity.main_entity,
    1,
    @material.CachedRenderPipelineId::new(77UL),
  )
  let cpu_hit = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_hit = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(cpu_hit.length(), content="1")
  debug_inspect(gpu_hit.length(), content="1")
  debug_inspect(cpu_hit[0].pipeline_id.id(), content="77")
  debug_inspect(gpu_hit[0].pipeline_id.id(), content="77")
}

///|
test "render3d: transmissive materials use a distinct sorted phase" {
  let material = @material.StandardMaterial::StandardMaterial().with_specular_transmission(
    0.5F,
  )
  let transform = @transform.Transform::from_xyz(0.0F, 0.0F, -1.0F)
  let world_from_local = @math.Affine3::from_translation(transform.translation)
  let mesh = ExtractedMesh3d::{
    entity: phase_entity_ref3d_for_main(@core.Entity::new(3, 0)),
    payload: Mesh3dExtractedPayload::{
      mesh_handle: @asset.Handle::new(3),
      mesh_id: 3,
      mesh_is_indexed: true,
      mesh_preprocess_static: None,
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      visibility_range: None,
      aabb: None,
      aabb_center_world: None,
      material_draw_data: MaterialDrawData3d::Standard(material),
      material_extension: None,
      material_properties: render3d_material_properties_for_standard_material(
        material,
        None,
        OpaqueRendererMethod::Forward,
        true,
      ),
      material_bind_group_data: @render_resource.MaterialBindGroupResolvedData::MaterialBindGroupResolvedData(),
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_cpu_culling: false,
      layers: @camera_render_layers.RenderLayers::RenderLayers(),
      has_no_wireframe: false,
      wireframe_asset_id: None,
      wireframe_material: None,
      wireframe_color: None,
      wireframe_line_width: None,
      wireframe_topology: None,
      skinning_key_hi: -1,
      has_previous_skin: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
      motion_vector_enabled: false,
    },
  }
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    material_slots,
    pending_queues,
    @camera_render_layers.RenderLayers::RenderLayers(),
    @transform.Transform::identity(),
    [],
    false,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(items[0].phase, content="2")
  debug_inspect(
    items[0].phase != RENDER3D_PHASE_OPAQUE &&
    items[0].phase != RENDER3D_PHASE_ALPHA_MASK,
    content="true",
  )
}

///|
test "render3d: standard material pipeline key includes render mesh topology" {
  let line_key = @mesh.BaseMeshPipelineKey::from_primitive_topology(
    @mesh.Mesh3dPrimitiveTopology::LineList,
  )
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=2,
    key_bits=line_key,
  )
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    @material.MaterialProperties::MaterialProperties(),
    render_mesh,
  )
  let mesh_key_bits = pipeline_key.mesh_key().downcast_u64("MeshPipelineKey")
  debug_inspect(
    (mesh_key_bits & line_key.bits()) == line_key.bits(),
    content="true",
  )
}

///|
test "render3d: mesh flags default to shadow receiver and positive determinant" {
  let flags = render3d_mesh_flags(
    render3d_test_extracted_mesh_for_flags(
      false,
      false,
      false,
      @math.Vec3::splat(1.0F),
    ),
  )
  debug_inspect(
    flags ==
    (
      RENDER3D_MESH_FLAGS_LOD_INDEX_NONE |
      RENDER3D_MESH_FLAGS_SHADOW_RECEIVER |
      RENDER3D_MESH_FLAGS_SIGN_DETERMINANT_MODEL_3X3
    ),
    content="true",
  )
}

///|
test "render3d: mesh flags honor culling, receiver, transmission, and determinant bits" {
  let flags = render3d_mesh_flags(
    render3d_test_extracted_mesh_for_flags(
      true,
      true,
      true,
      @math.Vec3::new(-1.0F, 1.0F, 1.0F),
    ),
  )
  debug_inspect(
    flags ==
    (
      RENDER3D_MESH_FLAGS_LOD_INDEX_NONE |
      RENDER3D_MESH_FLAGS_NO_FRUSTUM_CULLING |
      RENDER3D_MESH_FLAGS_TRANSMITTED_SHADOW_RECEIVER
    ),
    content="true",
  )
}
