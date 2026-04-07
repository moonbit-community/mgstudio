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
fn render3d_execute_camera_main_pass(
  world : @ecs.World,
  camera_entity : @core.Entity,
  extracted_camera : ExtractedCamera3d,
  camera : Camera3dViewPayload,
  draw_queue_entry : GpuPreprocessResolvedCameraQueueEntry3d,
  meshes : Array[ExtractedMesh3d],
  indexed_indirect_parameter_indices : Array[Int],
  non_indexed_indirect_parameter_indices : Array[Int],
  scene_target_id : Int,
  view_width : Int,
  view_height : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  clear_color : @sprite.Color,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_pass_projection : Render3dPassProjection,
  pass_lighting : Render3dLightingState,
  camera_exposure_value : Float,
  point_shadow_texture_id : Int,
  point_shadow_enabled : Float,
  point_shadow_depth_bias : Float,
  environment_map_state : Render3dEnvironmentMapState,
  point_shadow_near : Float,
  scene_pass_kind : Int,
  clear_enabled : Bool,
  cleared_targets_this_frame : Array[Int],
  camera_forward_decal_enabled : Bool,
  camera_clustered_decal_enabled : Bool,
  camera_deferred_enabled : Bool,
  camera_deferred_mode : OpaqueRendererMethod,
  camera_near : Float,
  camera_far : Float,
  distance_fog : DistanceFog,
  fog_enabled : Bool,
  transmission_enabled : Bool,
  transmission_steps : Int,
  transmission_blur_taps : Int,
  wireframe_config : WireframeConfig?,
) -> Unit {
  let draw_items = draw_queue_entry.draw_items
  fn pass_viewport(target_id : Int) -> (Int, Int, Int, Int) {
    render3d_pass_viewport_for_target(
      target_id,
      camera.target_id,
      viewport_x,
      viewport_y,
      viewport_width,
      viewport_height,
    )
  }
  let (
    scene_viewport_x,
    scene_viewport_y,
    scene_viewport_width,
    scene_viewport_height,
  ) = pass_viewport(scene_target_id)
  render3d_begin_pass_3d(
    target_id=scene_target_id,
    width=view_width_logical,
    height=view_height_logical,
    clear_r=clear_color.r,
    clear_g=clear_color.g,
    clear_b=clear_color.b,
    clear_a=clear_color.a,
    camera.transform,
    camera_pass_projection,
    viewport_x=scene_viewport_x,
    viewport_y=scene_viewport_y,
    viewport_width=scene_viewport_width,
    viewport_height=scene_viewport_height,
    pass_lighting,
    camera_exposure=camera_exposure_value,
    previous_clip_from_world=camera.previous_clip_from_world,
    point_shadow_texture_id~,
    point_shadow_enabled~,
    point_shadow_depth_bias~,
    environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
    environment_specular_texture_id=environment_map_state.specular_texture_id,
    environment_map_intensity=environment_map_state.intensity,
    environment_map_rotation=environment_map_state.rotation,
    point_shadow_near~,
    pass_kind=scene_pass_kind,
    clear_enabled=render3d_pass_clear_enabled_for_target(
      cleared_targets_this_frame, scene_target_id, clear_enabled,
    ),
  )
  let main_pass_draws : Array[MeshGpuDrawPayload3d] = []
  let transmissive_phase_items : Array[TransmissivePhaseItem3d] = []
  let transparent_draws : Array[MeshGpuDrawPayload3d] = []
  for draw_item_index in 0..<draw_items.length() {
    let draw_item = draw_items[draw_item_index]
    let extracted_mesh = meshes[draw_item.extracted_index]
    let mesh = extracted_mesh.payload
    if mesh.is_forward_decal && !camera_forward_decal_enabled {
      continue
    }
    if mesh.clustered_decal is Some(_) && !camera_clustered_decal_enabled {
      continue
    }
    if mesh.material_extension is Some(extension) {
      if extension.requires_depth_prepass && !camera.depth_prepass_enabled {
        continue
      }
      if extension.requires_deferred_prepass && !camera_deferred_enabled {
        continue
      }
    }
    let mesh_opaque_mode = if mesh.material.opaque_render_method
      is OpaqueRendererMethod::Auto {
      camera_deferred_mode
    } else {
      mesh.material.opaque_render_method
    }
    if mesh_opaque_mode is OpaqueRendererMethod::Deferred &&
      !camera_deferred_enabled {
      continue
    }
    guard render3d_mesh_draw_alpha(
        mesh.material.alpha_mode,
        mesh.material.base_color.a,
      )
      is Some(base_draw_alpha) else {
      continue
    }
    let mut draw_material = mesh.material
    if mesh.lightmap is Some(lightmap) && lightmap.image.id() > 0 {
      draw_material = draw_material
        .with_base_color_texture(Some(lightmap.image))
        .with_uv_transform(render3d_lightmap_uv_transform(lightmap.uv_rect))
        .with_unlit(true)
    }
    let mut draw_alpha = base_draw_alpha
    let mut texture_id = match draw_material.base_color_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let mut normal_texture_id = match
      (draw_material.normal_map_texture, draw_material.clearcoat_normal_texture) {
      (Some(texture), _) => texture.id()
      (None, Some(texture)) => texture.id()
      (None, None) => -1
    }
    let mut emissive_texture_id = match draw_material.emissive_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let mut metallic_roughness_texture_id = match
      draw_material.metallic_roughness_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let occlusion_texture_id = match draw_material.occlusion_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let depth_texture_id = match draw_material.depth_map {
      Some(texture) => texture.id()
      None => -1
    }
    let anisotropy_texture_id = match draw_material.anisotropy_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let specular_tint_texture_id = match draw_material.specular_tint_texture {
      Some(texture) => texture.id()
      None => -1
    }
    if mesh.clustered_decal is Some(clustered_decal) {
      if clustered_decal.base_color_texture is Some(texture) {
        texture_id = texture.id()
      }
      if clustered_decal.normal_map_texture is Some(texture) {
        normal_texture_id = texture.id()
      }
      if clustered_decal.metallic_roughness_texture is Some(texture) {
        metallic_roughness_texture_id = texture.id()
      }
      if clustered_decal.emissive_texture is Some(texture) {
        emissive_texture_id = texture.id()
      }
    }
    let anisotropy_strength = maxf(
      0.0F,
      minf(1.0F, draw_material.anisotropy_strength),
    )
    let max_relief_mapping_search_steps = Float::from_double(
      draw_material.parallax_mapping_method.max_steps().to_double(),
    )
    let mut clearcoat_reflectance = maxf(
      0.0F,
      draw_material.reflectance + draw_material.clearcoat * 0.5F,
    )
    let clearcoat_roughness = minf(
      draw_material.perceptual_roughness,
      draw_material.clearcoat_perceptual_roughness,
    )
    let mut draw_roughness = if draw_material.clearcoat > 0.0F {
      clearcoat_roughness
    } else {
      draw_material.perceptual_roughness
    }
    let needs_mesh_distance = fog_enabled || mesh.is_forward_decal
    let mesh_distance = if needs_mesh_distance {
      mesh.transform.translation.sub(camera.transform.translation).length()
    } else {
      0.0F
    }
    if mesh.is_forward_decal {
      let depth_fade_factor = if mesh.forward_decal_material_ext
        is Some(extension) {
        extension.depth_fade_factor
      } else {
        8.0F
      }
      let safe_depth_fade_factor = if depth_fade_factor < 0.001F {
        0.001F
      } else {
        depth_fade_factor
      }
      let decal_alpha = safe_depth_fade_factor /
        (safe_depth_fade_factor + maxf(0.0F, mesh_distance - camera_near))
      draw_alpha = draw_alpha * render3d_float_clamp(decal_alpha, 0.0F, 1.0F)
      clearcoat_reflectance = 0.0F
      draw_roughness = maxf(draw_roughness, 0.85F)
    }
    let (fogged_r, fogged_g, fogged_b) = if fog_enabled {
      render3d_apply_distance_fog(
        distance_fog,
        mesh_distance,
        draw_material.base_color.r,
        draw_material.base_color.g,
        draw_material.base_color.b,
        camera.transform.translation,
        mesh.transform.translation,
        pass_lighting,
      )
    } else {
      (
        draw_material.base_color.r,
        draw_material.base_color.g,
        draw_material.base_color.b,
      )
    }
    let draw_color_r = fogged_r
    let draw_color_g = fogged_g
    let draw_color_b = fogged_b
    let draw_surface_roughness = draw_roughness
    let draw_reflectance = clearcoat_reflectance
    let draw_diffuse_transmission = clamp01(draw_material.diffuse_transmission)
    let draw_specular_transmission = clamp01(
      draw_material.specular_transmission,
    )
    let draw_thickness = maxf(0.0F, draw_material.thickness)
    let draw_ior = maxf(1.0F, draw_material.ior)
    if draw_item.phase == RENDER3D_PHASE_TRANSPARENT &&
      camera.oit_settings is Some(oit_settings) &&
      draw_alpha < oit_settings.alpha_threshold {
      continue
    }
    let mut draw_point_shadow_enabled = point_shadow_enabled
    if mesh.has_not_shadow_receiver {
      draw_point_shadow_enabled = 0.0F
    }
    if draw_point_shadow_enabled > 0.0F &&
      (draw_diffuse_transmission > 0.0F || draw_specular_transmission > 0.0F) &&
      !mesh.has_transmitted_shadow_receiver {
      draw_point_shadow_enabled = 0.0F
    }
    let draw_flags = render3d_mesh_draw_flags(extracted_mesh)
    let draw_indexed = mesh.mesh_is_indexed
    let draw_indirect_parameters_index = if draw_indexed {
      indexed_indirect_parameter_indices[draw_item_index]
    } else {
      non_indexed_indirect_parameter_indices[draw_item_index]
    }
    let draw_shader_path = match mesh.material_extension {
      Some(extension) => extension.shader_path
      None => None
    }
    let draw_payload = render3d_build_mesh_gpu_draw_payload(
      mesh.mesh_id,
      camera_entity.id,
      camera_entity.generation,
      draw_item_index,
      if draw_indirect_parameters_index >= 0 {
        if draw_indexed {
          MESH3D_DRAW_INDIRECT_KIND_INDEXED
        } else {
          MESH3D_DRAW_INDIRECT_KIND_NON_INDEXED
        }
      } else {
        MESH3D_DRAW_INDIRECT_KIND_NONE
      },
      draw_indirect_parameters_index,
      draw_material,
      mesh.transform,
      mesh.previous_transform,
      draw_color_r,
      draw_color_g,
      draw_color_b,
      draw_alpha,
      texture_id,
      normal_texture_id,
      emissive_texture_id,
      metallic_roughness_texture_id,
      occlusion_texture_id,
      depth_texture_id,
      anisotropy_texture_id,
      specular_tint_texture_id,
      draw_surface_roughness,
      draw_reflectance,
      draw_diffuse_transmission,
      draw_specular_transmission,
      draw_thickness,
      draw_ior,
      -1,
      0.0F,
      0.0F,
      point_shadow_texture_id,
      draw_point_shadow_enabled,
      point_shadow_depth_bias,
      environment_map_state.diffuse_texture_id,
      environment_map_state.specular_texture_id,
      environment_map_state.intensity,
      environment_map_state.rotation,
      draw_material.specular_tint,
      anisotropy_strength,
      max_relief_mapping_search_steps,
      draw_flags,
      shader_path=draw_shader_path,
      skinning_key_hi=mesh.skinning_key_hi,
      skinning_key_lo=mesh.skinning_key_lo,
    )
    if draw_item.phase == RENDER3D_PHASE_TRANSPARENT {
      transparent_draws.push(draw_payload)
      continue
    }
    if transmission_enabled && draw_specular_transmission > 0.0F {
      transmissive_phase_items.push(TransmissivePhaseItem3d::{
        entity: extracted_mesh.entity,
        distance: draw_item.distance,
        payload: draw_payload,
      })
      continue
    }
    main_pass_draws.push(draw_payload)
  }
  for draw_payload in main_pass_draws {
    render3d_draw_mesh_gpu_payload(draw_payload)
  }
  render3d_draw_gizmo_lines_3d(camera_entity, camera)
  render3d_draw_camera_skybox(
    world, extracted_camera, camera_far, camera_exposure_value, point_shadow_texture_id,
    point_shadow_enabled, point_shadow_depth_bias, environment_map_state,
  )
  @render.host_gpu_end_pass()
  let transmissive_draws = render3d_sort_transmissive_phase_items(
    transmissive_phase_items,
  )
  if transmissive_draws.length() > 0 {
    let transmission_source_target_id = render3d_transmission_source_target_get_or_create(
      camera_entity, view_width, view_height,
    )
    let transmission_ranges = if transmission_steps > 0 {
      render3d_split_phase_ranges(
        transmissive_draws.length(),
        transmission_steps,
      )
    } else {
      [(0, transmissive_draws.length())]
    }
    for transmission_range in transmission_ranges {
      if transmission_steps > 0 {
        render3d_blit_texture_to_target(
          scene_target_id, transmission_source_target_id, view_width_logical, view_height_logical,
        )
      }
      let (
        transmission_viewport_x,
        transmission_viewport_y,
        transmission_viewport_width,
        transmission_viewport_height,
      ) = pass_viewport(scene_target_id)
      render3d_begin_pass_3d(
        target_id=scene_target_id,
        width=view_width_logical,
        height=view_height_logical,
        clear_r=clear_color.r,
        clear_g=clear_color.g,
        clear_b=clear_color.b,
        clear_a=clear_color.a,
        camera.transform,
        camera_pass_projection,
        viewport_x=transmission_viewport_x,
        viewport_y=transmission_viewport_y,
        viewport_width=transmission_viewport_width,
        viewport_height=transmission_viewport_height,
        pass_lighting,
        camera_exposure=camera_exposure_value,
        previous_clip_from_world=camera.previous_clip_from_world,
        transmission_blur_taps=Float::from_double(
          transmission_blur_taps.to_double(),
        ),
        transmission_steps=Float::from_double(transmission_steps.to_double()),
        point_shadow_texture_id~,
        point_shadow_enabled~,
        point_shadow_depth_bias~,
        transmission_source_texture_id=if transmission_steps > 0 {
          transmission_source_target_id
        } else {
          -1
        },
        environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
        environment_specular_texture_id=environment_map_state.specular_texture_id,
        environment_map_intensity=environment_map_state.intensity,
        environment_map_rotation=environment_map_state.rotation,
        point_shadow_near~,
        pass_kind=scene_pass_kind,
        clear_enabled=0,
      )
      for i in transmission_range.0..<transmission_range.1 {
        let transmissive_draw = transmissive_draws[i]
        transmissive_draw.entity |> ignore
        render3d_draw_mesh_gpu_payload(MeshGpuDrawPayload3d::{
          ..transmissive_draw.payload,
          transmission_source_texture_id: if transmission_steps > 0 {
            transmission_source_target_id
          } else {
            -1
          },
          transmission_blur_taps: Float::from_double(
            transmission_blur_taps.to_double(),
          ),
          transmission_steps: Float::from_double(transmission_steps.to_double()),
          point_shadow_texture_id: transmissive_draw.payload.point_shadow_texture_id,
          point_shadow_enabled: transmissive_draw.payload.point_shadow_enabled,
          point_shadow_depth_bias: transmissive_draw.payload.point_shadow_depth_bias,
        })
      }
      @render.host_gpu_end_pass()
    }
  }
  let wireframe_draws : Array[MeshGpuDrawPayload3d] = []
  for draw_item_index in 0..<draw_items.length() {
    let draw_item = draw_items[draw_item_index]
    let extracted_mesh = meshes[draw_item.extracted_index]
    let mesh = extracted_mesh.payload
    if !render3d_mesh_should_draw_wireframe(extracted_mesh, wireframe_config) {
      continue
    }
    guard render3d_wireframe_mesh_id(mesh.mesh_handle)
      is Some(wireframe_mesh_id) else {
      continue
    }
    let wireframe_color = render3d_mesh_wireframe_color(
      extracted_mesh, wireframe_config,
    )
    let wireframe_material = StandardMaterial::from_color(wireframe_color)
      .with_unlit(true)
      .with_cull_mode(mesh.material.cull_mode)
    guard render3d_mesh_draw_alpha(
        wireframe_material.alpha_mode,
        wireframe_material.base_color.a,
      )
      is Some(wireframe_draw_alpha) else {
      continue
    }
    wireframe_draws.push(
      render3d_build_mesh_gpu_draw_payload(
        wireframe_mesh_id,
        camera_entity.id,
        camera_entity.generation,
        draw_item_index,
        MESH3D_DRAW_INDIRECT_KIND_NONE,
        -1,
        wireframe_material,
        mesh.transform,
        mesh.previous_transform,
        wireframe_material.base_color.r,
        wireframe_material.base_color.g,
        wireframe_material.base_color.b,
        wireframe_draw_alpha,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1,
        0.5F,
        0.5F,
        0.0F,
        0.0F,
        0.0F,
        1.5F,
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
        @sprite.Color::white(),
        0.0F,
        0.0F,
        render3d_mesh_draw_flags(extracted_mesh),
      ),
    )
  }
  if transparent_draws.length() > 0 || wireframe_draws.length() > 0 {
    let (
      transparent_viewport_x,
      transparent_viewport_y,
      transparent_viewport_width,
      transparent_viewport_height,
    ) = pass_viewport(scene_target_id)
    render3d_begin_pass_3d(
      target_id=scene_target_id,
      width=view_width_logical,
      height=view_height_logical,
      clear_r=clear_color.r,
      clear_g=clear_color.g,
      clear_b=clear_color.b,
      clear_a=clear_color.a,
      camera.transform,
      camera_pass_projection,
      viewport_x=transparent_viewport_x,
      viewport_y=transparent_viewport_y,
      viewport_width=transparent_viewport_width,
      viewport_height=transparent_viewport_height,
      pass_lighting,
      camera_exposure=camera_exposure_value,
      previous_clip_from_world=camera.previous_clip_from_world,
      point_shadow_texture_id~,
      point_shadow_enabled~,
      point_shadow_depth_bias~,
      environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
      environment_specular_texture_id=environment_map_state.specular_texture_id,
      environment_map_intensity=environment_map_state.intensity,
      environment_map_rotation=environment_map_state.rotation,
      point_shadow_near~,
      pass_kind=scene_pass_kind,
      clear_enabled=0,
    )
    for draw_payload in transparent_draws {
      render3d_draw_mesh_gpu_payload(draw_payload)
    }
    for wireframe_draw in wireframe_draws {
      render3d_draw_mesh_gpu_payload(wireframe_draw)
    }
    @render.host_gpu_end_pass()
  }
}
