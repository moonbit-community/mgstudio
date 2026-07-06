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
fn render3d_prewarm_prepass_material_pipeline(
  world : @ecs.World,
  prepass_mesh : Mesh3dExtractedPayload,
  normal_prepass_enabled : Bool,
  motion_vector_prepass_enabled : Bool,
  deferred_prepass_enabled : Bool,
) -> @material.CachedRenderPipelineId? {
  guard prepass_mesh.material_properties.prepass_specialize
    is Some(prepass_specialize) else {
    return None
  }
  guard @sprite.render_mesh_asset_get(prepass_mesh.mesh_handle)
    is Some(mesh_asset) else {
    return None
  }
  let state = @pbr_render.render3d_mesh_runtime_state_mut_or_abort(world)
  let render_mesh = @render_mesh.RenderMesh::from_mesh(
    mesh_asset,
    state.peek().mesh_vertex_buffer_layouts,
  )
  let layout = render_mesh.layout()
  let base_key = material_pipeline_key_for_standard_material_render_mesh(
    prepass_mesh.material_properties,
    render_mesh,
    lightmapped=match prepass_mesh.lightmap {
      Some(lightmap) => lightmap.image.id() >= 0
      None => false
    },
    lightmap_bicubic_sampling=false,
  )
  let mut prepass_bits = base_key.mesh_key().bits() |
    MESH_PIPELINE_KEY_DEPTH_PREPASS
  if normal_prepass_enabled {
    prepass_bits = prepass_bits | MESH_PIPELINE_KEY_NORMAL_PREPASS
  }
  if motion_vector_prepass_enabled {
    prepass_bits = prepass_bits | MESH_PIPELINE_KEY_MOTION_VECTOR_PREPASS
  }
  if deferred_prepass_enabled &&
    prepass_mesh.material_properties.render_method
    is OpaqueRendererMethod::Deferred {
    prepass_bits = prepass_bits | MESH_PIPELINE_KEY_DEFERRED_PREPASS
  }
  if motion_vector_prepass_enabled && prepass_mesh.has_previous_skin {
    prepass_bits = prepass_bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_SKIN
  }
  if motion_vector_prepass_enabled &&
    prepass_mesh.previous_morph_weights_index >= 0 {
    prepass_bits = prepass_bits | MESH_PIPELINE_KEY_HAS_PREVIOUS_MORPH
  }
  let motion_key = @material.ErasedMaterialPipelineKey::new(
    @material.ErasedMeshPipelineKey::new(prepass_bits, "MeshPipelineKey"),
    prepass_mesh.material_properties.material_key,
    "StandardMaterial",
  )
  let prepass_pipeline_id = @material.material_specialize_prepass(
    prepass_specialize,
    world,
    motion_key,
    layout,
    prepass_mesh.material_properties,
  ) catch {
    err =>
      abort(
        "failed to specialize pbr prepass material pipeline for mesh \{prepass_mesh.mesh_handle.id()}: \{err}",
      )
  }
  let runtime_pipeline_id = pbr_prepass_runtime_pipeline_id(prepass_pipeline_id)
  Some(runtime_pipeline_id)
}

///|
fn render3d_prewarm_motion_vector_material_pipeline(
  world : @ecs.World,
  motion_mesh : Mesh3dExtractedPayload,
) -> @material.CachedRenderPipelineId? {
  render3d_prewarm_prepass_material_pipeline(
    world, motion_mesh, false, true, false,
  )
}

///|
fn render3d_execute_camera_prepass_draw_phase(
  world : @ecs.World,
  camera_entity : @core.Entity,
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  opaque_alpha_draw_item_indices : Array[Int],
  indexed_indirect_parameter_indices : Array[Int],
  non_indexed_indirect_parameter_indices : Array[Int],
  view_deferred_prepass_enabled : Bool,
  phase_deferred_prepass : Bool,
  normal_prepass_enabled : Bool,
  motion_vector_prepass_enabled : Bool,
) -> Unit {
  let draw_items = draw_queue_entry.draw_items
  for draw_item_index in opaque_alpha_draw_item_indices {
    let draw_item = draw_items[draw_item_index]
    if draw_item.phase != RENDER3D_PHASE_OPAQUE &&
      draw_item.phase != RENDER3D_PHASE_ALPHA_MASK {
      continue
    }
    let extracted_mesh = meshes[draw_item.extracted_index]
    let mesh = extracted_mesh.payload
    let mesh_deferred_prepass = view_deferred_prepass_enabled &&
      mesh.material_properties.render_method is OpaqueRendererMethod::Deferred
    if phase_deferred_prepass {
      if !mesh_deferred_prepass {
        continue
      }
    } else if mesh_deferred_prepass {
      continue
    }
    guard render3d_prewarm_prepass_material_pipeline(
        world, mesh, normal_prepass_enabled, motion_vector_prepass_enabled, phase_deferred_prepass,
      )
      is Some(material_pipeline_id) else {
      continue
    }
    let motion_vector_indexed = mesh.mesh_is_indexed
    let motion_vector_indirect_parameters_index = if motion_vector_indexed {
      indexed_indirect_parameter_indices[draw_item_index]
    } else {
      non_indexed_indirect_parameter_indices[draw_item_index]
    }
    guard render3d_mesh_draw_alpha(
        mesh.material_properties.alpha_mode,
        mesh.material_draw_data.draw_alpha_source(),
      )
      is Some(draw_alpha) else {
      continue
    }
    let material_fields = render3d_resolve_mesh_draw_material_fields(
      world, extracted_mesh, draw_alpha,
    )
    @pbr_render.render3d_draw_mesh_gpu_payload(
      @pbr_render.render3d_build_mesh_gpu_draw_payload(
        mesh.mesh_id,
        camera_entity.id,
        camera_entity.generation,
        draw_item_index,
        if motion_vector_indirect_parameters_index >= 0 {
          if motion_vector_indexed {
            MESH3D_DRAW_INDIRECT_KIND_INDEXED
          } else {
            MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
          }
        } else {
          MESH3D_DRAW_INDIRECT_KIND_NONE
        },
        motion_vector_indirect_parameters_index,
        material_fields.draw_material_input,
        mesh.transform,
        mesh.previous_transform,
        material_fields.base_color_r,
        material_fields.base_color_g,
        material_fields.base_color_b,
        material_fields.draw_alpha,
        material_fields.texture_id,
        material_fields.normal_texture_id,
        material_fields.emissive_texture_id,
        material_fields.metallic_roughness_texture_id,
        material_fields.occlusion_texture_id,
        material_fields.depth_texture_id,
        material_fields.anisotropy_texture_id,
        material_fields.specular_tint_texture_id,
        material_fields.clearcoat_texture_id,
        material_fields.clearcoat_roughness_texture_id,
        material_fields.clearcoat_normal_texture_id,
        material_fields.surface_roughness,
        material_fields.reflectance,
        material_fields.diffuse_transmission,
        material_fields.specular_transmission,
        material_fields.thickness,
        material_fields.ior,
        -1,
        0.0F,
        0.0F,
        -1,
        0.0F,
        0.0F,
        -1,
        -1,
        0.0F,
        @math.Quat::identity(),
        @color.Color::white(),
        material_fields.anisotropy_strength,
        material_fields.max_relief_mapping_search_steps,
        render3d_mesh_flags(extracted_mesh),
        render3d_mesh_draw_flags(extracted_mesh),
        specular_texture_id=material_fields.specular_texture_id,
        forward_decal_inv_depth_fade_factor=material_fields.forward_decal_inv_depth_fade_factor,
        skinning_key_hi=mesh.skinning_key_hi,
        skinning_key_lo=if mesh.skinning_key_hi < 0 {
          -1
        } else if mesh.has_previous_skin {
          1
        } else {
          0
        },
        material_pipeline_id~,
        material_extension_bind_group_data=mesh.material_bind_group_data,
        morph_weights_index=mesh.morph_weights_index,
        previous_morph_weights_index=mesh.previous_morph_weights_index,
        morph_targets_texture_id=mesh.morph_targets_texture_id,
        lightmap_texture_id=material_fields.lightmap_texture_id,
        lightmap_slab_index=material_fields.lightmap_slab_index,
        lightmap_slot_index=material_fields.lightmap_slot_index,
        lightmap_slab_texture_ids=material_fields.lightmap_slab_texture_ids,
        lightmap_uv_min_x=material_fields.lightmap_uv_min_x,
        lightmap_uv_min_y=material_fields.lightmap_uv_min_y,
        lightmap_uv_max_x=material_fields.lightmap_uv_max_x,
        lightmap_uv_max_y=material_fields.lightmap_uv_max_y,
        world_from_local=Some(mesh.world_from_local),
        previous_world_from_local=Some(mesh.previous_world_from_local),
      ),
    )
  }
}

///|
priv struct Render3dCameraPrepassResult {
  scene_target_id : Int
  velocity_target_id : Int
  depth_texture_id : Int
  normal_texture_id : Int
  deferred_texture_id : Int
  deferred_lighting_pass_id_texture_id : Int
}

///|
fn render3d_execute_camera_prepass(
  world : @ecs.World,
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  opaque_alpha_draw_item_indices : Array[Int],
  indexed_indirect_parameter_indices : Array[Int],
  non_indexed_indirect_parameter_indices : Array[Int],
  depth_prepass_enabled : Bool,
  normal_prepass_enabled : Bool,
  motion_vector_prepass_enabled : Bool,
  deferred_prepass_enabled : Bool,
  motion_blur_active : Bool,
  scene_target_id : Int,
  velocity_target_id : Int,
  view_width : Int,
  view_height : Int,
  msaa_sample_count : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_pass_projection : @pbr_render.Render3dPassProjection,
  pass_lighting : Render3dLightingState,
  camera_exposure_value : Float,
  point_shadow_near : Float,
  motion_vector_pass_kind : Int,
  prepass_pass_kind : Int,
) -> Render3dCameraPrepassResult {
  if !depth_prepass_enabled &&
    !normal_prepass_enabled &&
    !motion_vector_prepass_enabled &&
    !deferred_prepass_enabled {
    return Render3dCameraPrepassResult::{
      scene_target_id,
      velocity_target_id,
      depth_texture_id: -1,
      normal_texture_id: -1,
      deferred_texture_id: -1,
      deferred_lighting_pass_id_texture_id: -1,
    }
  }
  let mut next_scene_target_id = scene_target_id
  let mut next_velocity_target_id = velocity_target_id
  let mut normal_target_id = -1
  let mut deferred_target_id = -1
  let mut deferred_lighting_pass_id_target_id = -1
  let (
    prepass_target_id,
    prepass_secondary_target_id,
    shared_depth_id,
    active_prepass_kind,
  ) = if motion_vector_prepass_enabled {
    let (
      shared_scene_id,
      shared_velocity_id,
      shared_depth_id,
      shared_normal_id,
      shared_deferred_id,
      shared_deferred_lighting_pass_id,
    ) = render3d_motion_blur_targets_get_or_create(
      world,
      camera_entity,
      view_width,
      view_height,
      msaa_sample_count,
      camera.depth_texture_usages.with_copy_src(),
      normal_prepass_enabled~,
      deferred_prepass_enabled~,
    )
    if motion_blur_active {
      next_scene_target_id = shared_scene_id
    }
    next_velocity_target_id = shared_velocity_id
    normal_target_id = shared_normal_id
    deferred_target_id = shared_deferred_id
    deferred_lighting_pass_id_target_id = shared_deferred_lighting_pass_id
    let color_target_id = if normal_target_id >= 0 {
      normal_target_id
    } else {
      shared_scene_id
    }
    (
      color_target_id, shared_velocity_id, shared_depth_id, motion_vector_pass_kind,
    )
  } else {
    let targets = render3d_prepass_targets_get_or_create(
      world,
      camera_entity,
      view_width,
      view_height,
      msaa_sample_count,
      camera.depth_texture_usages.with_copy_src(),
      normal_prepass_enabled,
      deferred_prepass_enabled,
    )
    normal_target_id = targets.normal_texture_id
    deferred_target_id = targets.deferred_texture_id
    deferred_lighting_pass_id_target_id = targets.deferred_lighting_pass_id_texture_id
    let color_target_id = if normal_target_id >= 0 {
      normal_target_id
    } else {
      targets.depth_texture_id
    }
    (color_target_id, -1, targets.depth_texture_id, prepass_pass_kind)
  }
  let deferred_phase_target_id = if normal_target_id >= 0 {
    normal_target_id
  } else if motion_vector_prepass_enabled {
    prepass_target_id
  } else if deferred_target_id >= 0 {
    deferred_target_id
  } else {
    shared_depth_id
  }
  let (
    motion_viewport_x,
    motion_viewport_y,
    motion_viewport_width,
    motion_viewport_height,
  ) = @pbr_render.render3d_pass_viewport_for_target(
    prepass_target_id,
    camera.target_id,
    viewport_x,
    viewport_y,
    viewport_width,
    viewport_height,
  )
  @pbr_render.render3d_begin_pass_3d(
    target_id=prepass_target_id,
    secondary_target_id=prepass_secondary_target_id,
    width=view_width_logical,
    height=view_height_logical,
    clear_r=0.0F,
    clear_g=0.0F,
    clear_b=0.0F,
    clear_a=0.0F,
    camera.transform,
    camera_pass_projection,
    viewport_x=motion_viewport_x,
    viewport_y=motion_viewport_y,
    viewport_width=motion_viewport_width,
    viewport_height=motion_viewport_height,
    pass_lighting,
    camera_exposure=camera_exposure_value,
    previous_clip_from_world=camera.previous_clip_from_world,
    prepass_depth_texture_id=shared_depth_id,
    prepass_normal_texture_id=normal_target_id,
    prepass_motion_vector_texture_id=prepass_secondary_target_id,
    prepass_deferred_texture_id=-1,
    prepass_deferred_lighting_pass_id_texture_id=-1,
    point_shadow_near~,
    pass_kind=active_prepass_kind,
    msaa_sample_count~,
    clear_enabled=1,
  )
  render3d_execute_camera_prepass_draw_phase(
    world, camera_entity, draw_queue_entry, meshes, opaque_alpha_draw_item_indices,
    indexed_indirect_parameter_indices, non_indexed_indirect_parameter_indices, deferred_prepass_enabled,
    false, normal_prepass_enabled, motion_vector_prepass_enabled,
  )
  @render.host_gpu_end_pass()
  if deferred_prepass_enabled {
    let (
      deferred_viewport_x,
      deferred_viewport_y,
      deferred_viewport_width,
      deferred_viewport_height,
    ) = @pbr_render.render3d_pass_viewport_for_target(
      deferred_phase_target_id,
      camera.target_id,
      viewport_x,
      viewport_y,
      viewport_width,
      viewport_height,
    )
    @pbr_render.render3d_begin_pass_3d(
      target_id=deferred_phase_target_id,
      secondary_target_id=prepass_secondary_target_id,
      width=view_width_logical,
      height=view_height_logical,
      clear_r=0.0F,
      clear_g=0.0F,
      clear_b=0.0F,
      clear_a=0.0F,
      camera.transform,
      camera_pass_projection,
      viewport_x=deferred_viewport_x,
      viewport_y=deferred_viewport_y,
      viewport_width=deferred_viewport_width,
      viewport_height=deferred_viewport_height,
      pass_lighting,
      camera_exposure=camera_exposure_value,
      previous_clip_from_world=camera.previous_clip_from_world,
      prepass_depth_texture_id=shared_depth_id,
      prepass_normal_texture_id=normal_target_id,
      prepass_motion_vector_texture_id=prepass_secondary_target_id,
      prepass_deferred_texture_id=deferred_target_id,
      prepass_deferred_lighting_pass_id_texture_id=deferred_lighting_pass_id_target_id,
      point_shadow_near~,
      pass_kind=active_prepass_kind,
      msaa_sample_count~,
      clear_enabled=1,
    )
    render3d_execute_camera_prepass_draw_phase(
      world, camera_entity, draw_queue_entry, meshes, opaque_alpha_draw_item_indices,
      indexed_indirect_parameter_indices, non_indexed_indirect_parameter_indices,
      deferred_prepass_enabled, true, normal_prepass_enabled, motion_vector_prepass_enabled,
    )
    @render.host_gpu_end_pass()
  }
  Render3dCameraPrepassResult::{
    scene_target_id: next_scene_target_id,
    velocity_target_id: next_velocity_target_id,
    depth_texture_id: shared_depth_id,
    normal_texture_id: normal_target_id,
    deferred_texture_id: deferred_target_id,
    deferred_lighting_pass_id_texture_id: deferred_lighting_pass_id_target_id,
  }
}
