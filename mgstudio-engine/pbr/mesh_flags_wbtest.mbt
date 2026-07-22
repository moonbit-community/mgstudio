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
test "render3d: alpha-mask phase queueing does not evaluate shader cutoff" {
  let properties = @material.MaterialProperties::MaterialProperties()
    .with_render_phase_type(AlphaMask)
    .with_alpha_mode(Mask(0.9F))
  debug_inspect(render3d_mesh_phase_kind(properties), content="1")
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
    StandardMaterial(),
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
    StandardMaterial(),
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
      current_uniform_index: 0U,
      phase: RENDER3D_PHASE_OPAQUE,
      draw_function: @material.DrawFunctionId::new(0U),
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 1.0F,
      mesh_asset_id: 1,
      slabs: @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
      material_bind_group_index: 0,
      material_bind_group_slot: 0,
    },
    {
      entity: phase_entity_ref3d_for_main(@core.Entity::new(2, 0)),
      extracted_index: 1,
      current_uniform_index: 1U,
      phase: RENDER3D_PHASE_OPAQUE,
      draw_function: @material.DrawFunctionId::new(0U),
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 2.0F,
      mesh_asset_id: 2,
      slabs: @render_mesh.MeshSlabs::new(1),
      material_bind_group_index: 0,
      material_bind_group_slot: 0,
    },
    {
      entity: phase_entity_ref3d_for_main(@core.Entity::new(3, 0)),
      extracted_index: 2,
      current_uniform_index: 2U,
      phase: RENDER3D_PHASE_ALPHA_MASK,
      draw_function: @material.DrawFunctionId::new(0U),
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 3.0F,
      mesh_asset_id: 3,
      slabs: @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
      material_bind_group_index: 0,
      material_bind_group_slot: 0,
    },
  ]
  let (indexed, non_indexed) = render3d_gpu_preprocess_indirect_parameter_index_maps(
    draw_items,
    Indirect(
      [
        { input_index: 0, output_or_indirect_parameters_index: 0 },
        { input_index: 2, output_or_indirect_parameters_index: 1 },
      ],
      [{ input_index: 1, output_or_indirect_parameters_index: 0 }],
      None,
    ),
    {
      indexed: {
        indirect_parameters_cpu_metadata: [
          { base_output_index: 0, batch_set_index: -1 },
          { base_output_index: 2, batch_set_index: -1 },
        ],
        indirect_parameters_gpu_metadata: [],
        indirect_batch_sets: [],
      },
      non_indexed: {
        indirect_parameters_cpu_metadata: [
          { base_output_index: 1, batch_set_index: -1 },
        ],
        indirect_parameters_gpu_metadata: [],
        indirect_batch_sets: [],
      },
    },
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
test "render3d: direct phase preprocessing uploads mesh inputs and output capacity" {
  let work_items = @render_batching.preprocess_work_item_buffers_direct()
  work_items.push(false, @render_batching.PreprocessWorkItem::new(0, 2))
  let batched_instance_buffers = RenderMeshInstanceGpuBatchedInstanceBuffers::RenderMeshInstanceGpuBatchedInstanceBuffers()
  ignore(
    batched_instance_buffers.buffers.current_input_buffer.add(
      MeshInputUniform::new(flags=37U),
    ),
  )
  let entry = render3d_build_gpu_preprocess_queue_entry_from_phase_buffers(
    [],
    Some(batched_instance_buffers),
    None,
    work_items,
    @render_batching.UntypedPhaseIndirectParametersBuffers::new(false),
    output_count=3,
  )
  debug_inspect(entry.output_count, content="3")
  debug_inspect(entry.mesh_inputs.length(), content="1")
  debug_inspect(entry.mesh_inputs[0].flags, content="37")
  debug_inspect(entry.mesh_culling_data.length(), content="0")
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
      current_uniform_index: 0U,
      phase: RENDER3D_PHASE_OPAQUE,
      draw_function: @material.DrawFunctionId::new(0U),
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 1.0F,
      mesh_asset_id: 41,
      slabs: @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
      material_bind_group_index: 0,
      material_bind_group_slot: 0,
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
  let batched_instance_buffers = RenderMeshInstanceGpuBatchedInstanceBuffers::RenderMeshInstanceGpuBatchedInstanceBuffers()
  for _ in 0..<8 {
    ignore(
      batched_instance_buffers.buffers.current_input_buffer.add(
        MeshInputUniform::new(),
      ),
    )
  }
  let mesh_culling_data_buffer = MeshCullingDataBuffer::MeshCullingDataBuffer()
  mesh_culling_data_buffer.grow(8U)
  let entry = render3d_build_gpu_preprocess_queue_entry_from_phase_buffers(
    draw_items,
    Some(batched_instance_buffers),
    Some(mesh_culling_data_buffer),
    work_items,
    indirect_buffers,
  )
  debug_inspect(entry.phase_ranges.length(), content="1")
  debug_inspect(entry.mesh_culling_data.length(), content="8")
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
  let draw_items = [
    MeshPhaseItem3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(42, 0)),
      extracted_index: 0,
      current_uniform_index: 1U,
      phase: RENDER3D_PHASE_OPAQUE,
      draw_function: @material.DrawFunctionId::new(0U),
      pipeline_id: @material.CachedRenderPipelineId::new(1UL),
      distance: 1.0F,
      mesh_asset_id: 1,
      slabs: @render_mesh.MeshSlabs::new(1, index_slab_id=Some(2)),
      material_bind_group_index: 0,
      material_bind_group_slot: 0,
    },
  ]
  let previous_world_from_local = @math.Affine3::from_translation(
    @math.Vec3::new(-1.0F, -2.0F, -3.0F),
  )
  let world_from_local = @math.Affine3::from_scale_rotation_translation(
    @math.Vec3::new(2.0F, 3.0F, 4.0F),
    @math.Quat::identity(),
    @math.Vec3::new(3.0F, 4.0F, 5.0F),
  )
  let batched_instance_buffers = RenderMeshInstanceGpuBatchedInstanceBuffers::RenderMeshInstanceGpuBatchedInstanceBuffers()
  ignore(
    batched_instance_buffers.buffers.current_input_buffer.add(
      MeshInputUniform::new(),
    ),
  )
  let previous_input_index = batched_instance_buffers.buffers.previous_input_buffer
    .add(MeshInputUniform::new(world_from_local=previous_world_from_local))
    .reinterpret_as_uint()
  ignore(
    batched_instance_buffers.buffers.current_input_buffer.add(
      MeshInputUniform::new(
        world_from_local~,
        previous_input_index~,
        flags=91U,
        first_vertex_index=7U,
        first_index_index=11U,
        index_count=13U,
        tag=17U,
      ),
    ),
  )
  let mesh_culling_data_buffer = MeshCullingDataBuffer::MeshCullingDataBuffer()
  mesh_culling_data_buffer.set(
    1U,
    MeshCullingData::new(
      Some(
        @camera_primitives.Aabb::from_min_max(
          @math.Vec3::new(-3.0F, -3.0F, -3.0F),
          @math.Vec3::new(5.0F, 7.0F, 9.0F),
        ),
      ),
    ),
  )
  let entry = render3d_build_gpu_preprocess_queue_entry(
    draw_items,
    Some(batched_instance_buffers),
    Some(mesh_culling_data_buffer),
    true,
    false,
  )
  match entry.work_item_buffers {
    Direct(_) => abort("expected indirect queue work items")
    Indirect(indexed, non_indexed, culling) => {
      debug_inspect(indexed.length(), content="1")
      debug_inspect(non_indexed.length(), content="0")
      debug_inspect(culling is None, content="true")
      debug_inspect(indexed[0].input_index, content="1")
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
  debug_inspect(entry.mesh_inputs.length(), content="2")
  debug_inspect(entry.mesh_inputs[1].translation_x, content="3")
  debug_inspect(entry.mesh_inputs[1].translation_y, content="4")
  debug_inspect(entry.mesh_inputs[1].translation_z, content="5")
  debug_inspect(entry.mesh_inputs[1].previous_translation_x, content="-1")
  debug_inspect(entry.mesh_inputs[1].previous_translation_y, content="-2")
  debug_inspect(entry.mesh_inputs[1].previous_translation_z, content="-3")
  debug_inspect(entry.mesh_inputs[1].scale_x, content="2")
  debug_inspect(entry.mesh_inputs[1].scale_y, content="3")
  debug_inspect(entry.mesh_inputs[1].scale_z, content="4")
  debug_inspect(entry.mesh_inputs[1].flags, content="91")
  debug_inspect(entry.mesh_inputs[1].first_vertex_index, content="7")
  debug_inspect(entry.mesh_inputs[1].first_index_index, content="11")
  debug_inspect(entry.mesh_inputs[1].index_count, content="13")
  debug_inspect(entry.mesh_inputs[1].tag, content="17")
  debug_inspect(entry.mesh_culling_data[1].aabb_center_x, content="1")
  debug_inspect(entry.mesh_culling_data[1].aabb_center_y, content="2")
  debug_inspect(entry.mesh_culling_data[1].aabb_center_z, content="3")
  debug_inspect(entry.mesh_culling_data[1].aabb_half_extents_x, content="4")
  debug_inspect(entry.mesh_culling_data[1].aabb_half_extents_y, content="5")
  debug_inspect(entry.mesh_culling_data[1].aabb_half_extents_z, content="6")
}

///|
test "render3d: GPU preprocess includes every Bevy main mesh phase" {
  let phases = [
    RENDER3D_PHASE_OPAQUE,
    RENDER3D_PHASE_ALPHA_MASK,
    RENDER3D_PHASE_TRANSMISSIVE,
    RENDER3D_PHASE_TRANSPARENT,
  ]
  let draw_items : Array[MeshPhaseItem3d] = []
  for index in 0..<phases.length() {
    draw_items.push({
      entity: phase_entity_ref3d_for_main(@core.Entity::new(50 + index, 0)),
      extracted_index: index,
      current_uniform_index: (10 + index).reinterpret_as_uint(),
      phase: phases[index],
      draw_function: @material.DrawFunctionId::new(index.reinterpret_as_uint()),
      pipeline_id: @material.CachedRenderPipelineId::new(
        (index + 1).to_uint64(),
      ),
      distance: Float::from_int(index),
      mesh_asset_id: 50 + index,
      slabs: @render_mesh.MeshSlabs::new(
        1,
        index_slab_id=if index % 2 == 0 { Some(2) } else { None },
      ),
      material_bind_group_index: 0,
      material_bind_group_slot: 0,
    })
  }
  let phase_buffers = render3d_build_gpu_preprocess_phase_buffers_from_draw_items(
    draw_items, true, false,
  )
  let indexed = phase_buffers.work_item_buffers.indexed_items()
  let non_indexed = phase_buffers.work_item_buffers.non_indexed_items()
  debug_inspect(indexed.length(), content="2")
  debug_inspect(non_indexed.length(), content="2")
  debug_inspect(indexed[0].input_index, content="10")
  debug_inspect(indexed[1].input_index, content="12")
  debug_inspect(non_indexed[0].input_index, content="11")
  debug_inspect(non_indexed[1].input_index, content="13")
  debug_inspect(
    phase_buffers.indirect_parameters_buffers.indexed
    .cpu_metadata_at(1)
    .unwrap()
    .base_output_index(),
    content="2",
  )
  debug_inspect(
    phase_buffers.indirect_parameters_buffers.non_indexed
    .cpu_metadata_at(1)
    .unwrap()
    .base_output_index(),
    content="3",
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
  {
    entity: phase_entity_ref3d_for_main(@core.Entity::new(1, 0)),
    payload: {
      mesh_handle: @asset.Handle::new(1),
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      aabb: None,
      material_draw_data: Standard(StandardMaterial()),
      material_extension: None,
      material_properties: pbr_material_apply_draw_functions(
        MaterialProperties(),
        pbr_material_default_draw_function_ids(),
      ),
      material_bind_group_data: MaterialBindGroupResolvedData(),
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver,
      has_transmitted_shadow_receiver,
      has_no_frustum_culling,
      has_no_cpu_culling: false,
      layers: RenderLayers(),
      skinning_key_hi: -1,
      has_previous_skin: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
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
    Blend,
  )
  {
    entity: phase_entity_ref3d_for_main(@core.Entity::new(entity_id, 0)),
    payload: {
      mesh_handle: @asset.Handle::new(entity_id),
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      aabb: None,
      material_draw_data: Standard(material),
      material_extension: None,
      material_properties: render3d_material_properties_for_standard_material(
        material,
        None,
        Forward,
        true,
      ).with_depth_bias(depth_bias),
      material_bind_group_data: MaterialBindGroupResolvedData(),
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_cpu_culling: false,
      layers: RenderLayers(),
      skinning_key_hi: -1,
      has_previous_skin: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
    },
  }
}

///|
fn render3d_extracted_render_mesh_assets_from_extracted_meshes(
  meshes : Array[ExtractedMesh3d],
) -> Array[@render_mesh.ExtractedRenderMeshAsset] {
  let extracted_assets : Array[@render_mesh.ExtractedRenderMeshAsset] = []
  let seen_mesh_assets : Map[Int, Unit] = Map([])
  for extracted_mesh in meshes {
    let mesh_handle = extracted_mesh.payload.mesh_handle
    if seen_mesh_assets.contains(mesh_handle.id()) {
      continue
    }
    guard @sprite.render_mesh_asset_get(mesh_handle) is Some(source_mesh) else {
      continue
    }
    seen_mesh_assets.set(mesh_handle.id(), ())
    extracted_assets.push(
      @render_mesh.ExtractedRenderMeshAsset::new(mesh_handle.id(), source_mesh),
    )
  }
  extracted_assets
}

///|
test "render3d: render asset preparation deduplicates shared mesh instances" {
  let world = @ecs.World::new()
  defer world.close()
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  world.insert_resource(mesh_assets_key, @asset.Assets::new())
  let extracted_asset_count = Ref(-1)
  let preserved_asset_id = Ref(false)
  let app = @app.App::new(world).add_system(fn(_world) {
    let mesh_handle = @sprite.render_mesh_asset_add(
      @mesh.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(
          [
            @math.Vec3::new(0.0F, 0.0F, 0.0F),
            @math.Vec3::new(1.0F, 0.0F, 0.0F),
            @math.Vec3::new(0.0F, 1.0F, 0.0F),
          ],
          [
            @math.Vec2::new(0.0F, 0.0F),
            @math.Vec2::new(1.0F, 0.0F),
            @math.Vec2::new(0.0F, 1.0F),
          ],
          Some([0, 1, 2]),
        ),
      ),
    )
    let base = render3d_test_extracted_mesh_for_flags(
      false,
      false,
      false,
      @math.Vec3::splat(1.0F),
    )
    let first = ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(301, 0)),
      payload: { ..base.payload, mesh_handle, },
    }
    let second = ExtractedMesh3d::{
      entity: phase_entity_ref3d_for_main(@core.Entity::new(302, 0)),
      payload: { ..base.payload, mesh_handle, },
    }
    let extracted_assets = render3d_extracted_render_mesh_assets_from_extracted_meshes([
        first, second,
      ],
    )
    extracted_asset_count.val = extracted_assets.length()
    preserved_asset_id.val = extracted_assets[0].mesh_asset_id() ==
      mesh_handle.id()
  })
  ignore(app.run_once())
  debug_inspect(extracted_asset_count.val, content="1")
  debug_inspect(preserved_asset_id.val, content="true")
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
fn render3d_test_queue_mesh_instances(
  meshes : Array[ExtractedMesh3d],
) -> RenderMeshInstances {
  let instances = RenderMeshInstances::new()
  let cpu_instances = match instances {
    CpuBuilding(value) => value
    GpuBuilding(_) => abort("expected CPU-building RenderMeshInstances")
  }
  for mesh in meshes {
    let queue_data = RenderMeshQueueData::new(
      mesh.payload.mesh_handle.id(),
      0U,
      true,
      render_layers=Some(mesh.payload.layers),
    )
    cpu_instances.insert_instance(
      @render.MainEntity::new(mesh.entity.main_entity),
      RenderMeshInstanceCpu::new(
        RenderMeshInstanceSharedFlat::from_queue_data(queue_data),
        transforms=Some(
          MeshTransforms::new(
            mesh.payload.world_from_local,
            mesh.payload.previous_world_from_local,
            0U,
          ),
        ),
        render_layers=Some(mesh.payload.layers),
      ),
    )
  }
  instances
}

///|
fn render3d_test_queue_render_mesh_assets(
  meshes : Array[ExtractedMesh3d],
) -> @render_mesh.RenderMeshAssets {
  let assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  for mesh in meshes {
    let aabb_center = match mesh.payload.aabb {
      Some(aabb) => aabb.center()
      None => @math.Vec3::zero()
    }
    assets.insert(
      mesh.payload.mesh_handle.id(),
      @render_mesh.RenderMesh::new(vertex_count=3, aabb_center~),
    )
  }
  assets
}

///|
fn render3d_test_queue_mesh_allocator(
  meshes : Array[ExtractedMesh3d],
) -> @render_mesh.MeshAllocator {
  let allocator = @render_mesh.MeshAllocator::MeshAllocator()
  for mesh in meshes {
    let render_mesh = @render_mesh.RenderMesh::new(
      vertex_count=3,
      indexed=true,
      index_count=3,
    )
    ignore(
      allocator.allocate_render_mesh(
        mesh.payload.mesh_handle.id(),
        render_mesh,
        80,
      ),
    )
  }
  allocator
}

///|
fn render3d_test_queue_material_id(mesh : ExtractedMesh3d) -> Int {
  mesh.entity.main_entity.id + 1000
}

///|
fn render3d_test_queue_material_instances(
  meshes : Array[ExtractedMesh3d],
) -> RenderMaterialInstances {
  let instances = RenderMaterialInstances::RenderMaterialInstances()
  for mesh in meshes {
    instances.extract_mesh_material_id(
      mesh.entity.main_entity,
      true,
      render3d_test_queue_material_id(mesh),
    )
  }
  instances
}

///|
fn render3d_test_queue_material_bindings(
  meshes : Array[ExtractedMesh3d],
) -> RenderMaterialBindings {
  let bindings = RenderMaterialBindings::RenderMaterialBindings()
  for i in 0..<meshes.length() {
    bindings.set(
      render3d_test_queue_material_id(meshes[i]),
      MaterialBindingId::new(
        MaterialBindGroupIndex::new(7),
        MaterialBindGroupSlot::new(30 + i),
      ),
    )
  }
  bindings
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
    render3d_test_queue_mesh_instances(meshes),
    render3d_test_queue_render_mesh_assets(meshes),
    None,
    render3d_test_queue_mesh_allocator(meshes),
    render3d_test_queue_material_instances(meshes),
    render3d_test_queue_material_bindings(meshes),
    material_slots,
    pending_queues,
    camera_transform,
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    meshes,
    render3d_test_queue_mesh_instances(meshes),
    render3d_test_queue_render_mesh_assets(meshes),
    None,
    render3d_test_queue_mesh_allocator(meshes),
    render3d_test_queue_material_instances(meshes),
    render3d_test_queue_material_bindings(meshes),
    material_slots,
    pending_queues,
    camera_transform,
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
test "render3d: transparent sorting uses render mesh center and CPU or GPU instance transform" {
  let mesh = render3d_test_transparent_mesh_for_queue(3, -100.0F, 0.0F)
  let meshes = [mesh]
  let visible_entity = @render.MainEntity::new(mesh.entity.main_entity)
  let (view, cache) = render3d_test_queue_pipeline_cache(meshes)
  let material_slots = render3d_test_queue_material_slots(meshes)
  let render_mesh_assets = @render_mesh.RenderMeshAssets::RenderMeshAssets()
  render_mesh_assets.insert(
    mesh.payload.mesh_handle.id(),
    @render_mesh.RenderMesh::new(
      vertex_count=3,
      aabb_center=@math.Vec3::new(0.0F, 0.0F, -3.0F),
    ),
  )
  let queue_data = RenderMeshQueueData::new(
    mesh.payload.mesh_handle.id(),
    0U,
    true,
    render_layers=Some(mesh.payload.layers),
  )

  let cpu_storage = RenderMeshInstancesCpu::RenderMeshInstancesCpu()
  let cpu_transform = @math.Affine3::from_translation(
    @math.Vec3::new(0.0F, 0.0F, -2.0F),
  )
  cpu_storage.insert_instance(
    visible_entity,
    RenderMeshInstanceCpu::new(
      RenderMeshInstanceSharedFlat::from_queue_data(queue_data),
      transforms=Some(MeshTransforms::new(cpu_transform, cpu_transform, 0U)),
      render_layers=Some(mesh.payload.layers),
    ),
  )
  let cpu_items = render3d_queue_mesh_phase_items(
    meshes,
    CpuBuilding(cpu_storage),
    render_mesh_assets,
    None,
    render3d_test_queue_mesh_allocator(meshes),
    render3d_test_queue_material_instances(meshes),
    render3d_test_queue_material_bindings(meshes),
    material_slots,
    PendingMeshMaterialQueues(),
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  inspect(cpu_items[0].distance, content="5")

  let gpu_storage = RenderMeshInstancesGpu::RenderMeshInstancesGpu()
  gpu_storage.insert(visible_entity, queue_data)
  let gpu_buffers = RenderMeshInstanceGpuBatchedInstanceBuffers::RenderMeshInstanceGpuBatchedInstanceBuffers()
  ignore(
    gpu_buffers.buffers.current_input_buffer.add(
      MeshInputUniform::new(
        world_from_local=@math.Affine3::from_translation(
          @math.Vec3::new(0.0F, 0.0F, -4.0F),
        ),
      ),
    ),
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    meshes,
    GpuBuilding(gpu_storage),
    render_mesh_assets,
    Some(gpu_buffers),
    render3d_test_queue_mesh_allocator(meshes),
    render3d_test_queue_material_instances(meshes),
    render3d_test_queue_material_bindings(meshes),
    material_slots,
    PendingMeshMaterialQueues(),
    @transform.Transform::identity(),
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  inspect(gpu_items[0].distance, content="7")
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
    .with_alpha_mode(Blend)
    .with_render_phase_type(Transparent)
    .add_draw_function(
      MAIN_PASS_TRANSPARENT_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(70U),
    )
  let mesh = ExtractedMesh3d::{
    ..base,
    payload: { ..base.payload, material_properties: properties },
  }
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(cpu_items[0].phase, content="3")
  debug_inspect(cpu_items[0].draw_function.id(), content="70")
  debug_inspect(gpu_items[0].phase, content="3")
  debug_inspect(gpu_items[0].draw_function.id(), content="70")
}

///|
test "render3d: queue phase reads material properties from resolved material slots" {
  let payload_properties = @material.MaterialProperties::MaterialProperties()
    .with_alpha_mode(Opaque)
    .with_render_phase_type(Opaque)
  let slot_properties = @material.MaterialProperties::MaterialProperties()
    .with_alpha_mode(Blend)
    .with_render_phase_type(Transparent)
    .with_depth_bias(4.0F)
    .add_draw_function(
      MAIN_PASS_TRANSPARENT_DRAW_FUNCTION_LABEL,
      @material.DrawFunctionId::new(71U),
    )
  let material = @material.StandardMaterial::StandardMaterial().with_alpha_mode(
    Blend,
  )
  let base = render3d_test_extracted_mesh_for_flags(
    false,
    false,
    false,
    @math.Vec3::splat(1.0F),
  )
  let mesh = ExtractedMesh3d::{
    ..base,
    payload: {
      ..base.payload,
      material_draw_data: Standard(material),
      material_properties: payload_properties,
    },
  }
  let material_slots = RenderMaterial3dResolvedSlots::new()
  material_slots.set_resolved(
    mesh.entity.main_entity,
    Render3dResolvedMaterial::new(
      Standard(material),
      slot_properties,
      MaterialBindGroupResolvedData(),
      "StandardMaterial",
    ),
  )
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(cpu_items[0].phase, content="3")
  debug_inspect(cpu_items[0].draw_function.id(), content="71")
  debug_inspect(cpu_items[0].distance, content="4")
  debug_inspect(gpu_items[0].phase, content="3")
  debug_inspect(gpu_items[0].draw_function.id(), content="71")
  debug_inspect(gpu_items[0].distance, content="4")
}

///|
test "render3d: queue phase skips material without its main pass draw function" {
  let mesh = render3d_test_transparent_mesh_for_queue(8, -1.0F, 0.0F)
  let material = @material.StandardMaterial::StandardMaterial().with_alpha_mode(
    Blend,
  )
  let material_slots = RenderMaterial3dResolvedSlots::new()
  material_slots.set_resolved(
    mesh.entity.main_entity,
    Render3dResolvedMaterial::new(
      Standard(material),
      @material.MaterialProperties::MaterialProperties()
      .with_alpha_mode(Blend)
      .with_render_phase_type(Transparent),
      MaterialBindGroupResolvedData(),
      "StandardMaterial",
    ),
  )
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(items.length(), content="0")
  debug_inspect(pending_queues.current_len(view), content="0")
}

///|
test "render3d: queue phase returns missing resolved material slots to pending queue" {
  let mesh = render3d_test_transparent_mesh_for_queue(9, -1.0F, 0.0F)
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = RenderMaterial3dResolvedSlots::new()
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(items.length(), content="0")
  debug_inspect(pending_queues.current_len(view), content="1")
}

///|
test "render3d: queue phase reads mesh layers from RenderMeshInstances" {
  let base = render3d_test_transparent_mesh_for_queue(11, -1.0F, 0.0F)
  let payload_layer = @camera_render_layers.RenderLayers::layer(2)
  let camera_layer = @camera_render_layers.RenderLayers::layer(1)
  let mesh = ExtractedMesh3d::{
    ..base,
    payload: { ..base.payload, layers: payload_layer },
  }
  let mesh_instances = RenderMeshInstances::new()
  mesh_instances.insert(
    @render.MainEntity::new(mesh.entity.main_entity),
    RenderMeshQueueData::new(
      mesh.payload.mesh_handle.id(),
      0U,
      true,
      render_layers=Some(camera_layer),
    ),
  )
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    mesh_instances,
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(payload_layer.matches(camera_layer), content="false")
  debug_inspect(cpu_items.length(), content="1")
  debug_inspect(cpu_items[0].mesh_asset_id, content="11")
  debug_inspect(cpu_items[0].slabs.index_slab_id() is Some(_), content="true")
  debug_inspect(cpu_items[0].material_bind_group_index, content="7")
  debug_inspect(cpu_items[0].material_bind_group_slot, content="30")
}

///|
test "render3d: queue phase returns missing RenderMeshInstances rows to pending queue" {
  let mesh = render3d_test_transparent_mesh_for_queue(12, -1.0F, 0.0F)
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    RenderMeshInstances::new(),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(items.length(), content="0")
  debug_inspect(pending_queues.current_len(view), content="1")
}

///|
test "render3d: queue phase returns missing material bindings to pending queue" {
  let mesh = render3d_test_transparent_mesh_for_queue(14, -1.0F, 0.0F)
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    RenderMaterialBindings(),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(items.length(), content="0")
  debug_inspect(pending_queues.current_len(view), content="1")
}

///|
test "render3d: queue phase skips missing MeshAllocator slabs without pending retry" {
  let mesh = render3d_test_transparent_mesh_for_queue(13, -1.0F, 0.0F)
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    MeshAllocator(),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(items.length(), content="0")
  debug_inspect(pending_queues.current_len(view), content="0")
}

///|
test "render3d: queue phase checks prepared binding before allocator slabs" {
  let mesh = render3d_test_transparent_mesh_for_queue(15, -1.0F, 0.0F)
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    MeshAllocator(),
    render3d_test_queue_material_instances([mesh]),
    RenderMaterialBindings(),
    render3d_test_queue_material_slots([mesh]),
    pending_queues,
    @transform.Transform::identity(),
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
    .with_alpha_mode(Opaque)
    .with_metallic(0.0F)
    .with_perceptual_roughness(0.5F)
  let properties = render3d_material_properties_for_standard_material(
    cube_material,
    None,
    Forward,
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
    payload: {
      ..base.payload,
      material_draw_data: Standard(cube_material),
      material_properties: properties,
    },
  }
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  debug_inspect(properties.render_phase_type is Opaque, content="true")
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
  let visible = @render_visibility.RenderVisibleEntitiesClass::RenderVisibleEntitiesClass()
  visible.update_cpu_culled_entities([
    (
      meshes[1].entity.render_entity,
      @render.MainEntity::new(meshes[1].entity.main_entity),
    ),
  ])
  let candidate_indices = render3d_queue_mesh_candidate_indices(
    meshes,
    Some(visible),
  )
  debug_inspect(candidate_indices.length(), content="1")
  debug_inspect(candidate_indices[0], content="1")
  let (view, cache) = render3d_test_queue_pipeline_cache(meshes)
  let material_slots = render3d_test_queue_material_slots(meshes)
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let cpu_items = render3d_queue_mesh_phase_items(
    meshes,
    render3d_test_queue_mesh_instances(meshes),
    render3d_test_queue_render_mesh_assets(meshes),
    None,
    render3d_test_queue_mesh_allocator(meshes),
    render3d_test_queue_material_instances(meshes),
    render3d_test_queue_material_bindings(meshes),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
    visible_mesh_entities=Some(visible),
  )
  let gpu_items = render3d_queue_mesh_phase_items(
    meshes,
    render3d_test_queue_mesh_instances(meshes),
    render3d_test_queue_render_mesh_assets(meshes),
    None,
    render3d_test_queue_mesh_allocator(meshes),
    render3d_test_queue_material_instances(meshes),
    render3d_test_queue_material_bindings(meshes),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    true,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
    visible_mesh_entities=Some(visible),
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
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_miss = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
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
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=cache,
  )
  let gpu_hit = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
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
test "render3d: queue phase checks pipeline cache before pending resources" {
  let mesh = render3d_test_transparent_mesh_for_queue(7, -1.0F, 0.0F)
  let view = @render_view.RetainedViewEntity::new(@core.Entity::new(8, 0))
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    RenderMeshInstances::new(),
    RenderMeshAssets(),
    None,
    MeshAllocator(),
    RenderMaterialInstances(),
    RenderMaterialBindings(),
    RenderMaterial3dResolvedSlots::new(),
    pending_queues,
    @transform.Transform::identity(),
    false,
    retained_view_entity=view,
    specialized_material_pipeline_cache=SpecializedMaterialPipelineCache(),
  )
  debug_inspect(items.length(), content="0")
  debug_inspect(pending_queues.current_len(view), content="0")
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
    payload: {
      mesh_handle: @asset.Handle::new(3),
      world_from_local,
      previous_world_from_local: world_from_local,
      transform,
      previous_transform: transform,
      aabb: None,
      material_draw_data: Standard(material),
      material_extension: None,
      material_properties: render3d_material_properties_for_standard_material(
        material,
        None,
        Forward,
        true,
      ),
      material_bind_group_data: MaterialBindGroupResolvedData(),
      lightmap: None,
      is_forward_decal: false,
      forward_decal_material_ext: None,
      clustered_decal: None,
      has_not_shadow_caster: false,
      has_not_shadow_receiver: false,
      has_transmitted_shadow_receiver: false,
      has_no_frustum_culling: false,
      has_no_cpu_culling: false,
      layers: RenderLayers(),
      skinning_key_hi: -1,
      has_previous_skin: false,
      morph_weights_index: -1,
      previous_morph_weights_index: -1,
      morph_targets_texture_id: -1,
      instance_vertex_buffer_id: -1,
    },
  }
  let (view, cache) = render3d_test_queue_pipeline_cache([mesh])
  let material_slots = render3d_test_queue_material_slots([mesh])
  let pending_queues = PendingMeshMaterialQueues::PendingMeshMaterialQueues()
  let items = render3d_queue_mesh_phase_items(
    [mesh],
    render3d_test_queue_mesh_instances([mesh]),
    render3d_test_queue_render_mesh_assets([mesh]),
    None,
    render3d_test_queue_mesh_allocator([mesh]),
    render3d_test_queue_material_instances([mesh]),
    render3d_test_queue_material_bindings([mesh]),
    material_slots,
    pending_queues,
    @transform.Transform::identity(),
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
  let line_key = @mesh.BaseMeshPipelineKey::from_primitive_topology(LineList)
  let render_mesh = @render_mesh.RenderMesh::new(
    vertex_count=2,
    key_bits=line_key,
  )
  let pipeline_key = material_pipeline_key_for_standard_material_render_mesh(
    MaterialProperties(),
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
