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
fn render3d_main_pass_tonemapping_mode_to_int(mode : Tonemapping) -> Int {
  match mode {
    None => 0
    Reinhard => 1
    ReinhardLuminance => 2
    AcesFitted => 3
    AgX => 4
    SomewhatBoringDisplayTransform => 5
    TonyMcMapface => 6
    BlenderFilmic => 7
    PbrNeutral => 8
  }
}

///|
fn render3d_main_pass_tonemap_in_shader(camera : Camera3dViewPayload) -> Bool {
  !camera.hdr_enabled && camera.tonemapping is Some(_)
}

///|
fn render3d_main_pass_tonemapping_mode(camera : Camera3dViewPayload) -> Int {
  match camera.tonemapping {
    Some(mode) => render3d_main_pass_tonemapping_mode_to_int(mode)
    None => 0
  }
}

///|
fn render3d_main_pass_tonemapping_lut_ids(
  world : @ecs.World,
  camera : Camera3dViewPayload,
) -> (Int, Int, Int) {
  if !render3d_main_pass_tonemap_in_shader(camera) {
    return (-1, -1, -1)
  }
  let luts = render3d_tonemapping_lut_handles(world)
  (luts.agx.id(), luts.tony_mc_mapface.id(), luts.blender_filmic.id())
}

///|
fn render3d_main_pass_pbr_internal_lut_ids(
  world : @ecs.World,
) -> (Int, Int, Int) {
  pbr_ensure_render_world_internal_luts(
    world,
    @render.render_source_world(world),
  )
  let blue_noise_texture_id = match world.get_resource(ecs_key_bluenoise) {
    Some(resource) => resource.texture.id()
    None => -1
  }
  let area_light_luts_texture_id = match
    world.get_resource(ecs_key_area_light_luts) {
    Some(resource) => resource.image.id()
    None => -1
  }
  let dfg_lut_texture_id = match world.get_resource(ecs_key_dfg_lut) {
    Some(resource) => resource.texture.id()
    None => -1
  }
  (blue_noise_texture_id, area_light_luts_texture_id, dfg_lut_texture_id)
}

///|
fn render3d_main_pass_deband_dither_enabled(
  camera : Camera3dViewPayload,
) -> Bool {
  render3d_main_pass_tonemap_in_shader(camera) &&
  camera.deband_dither is Some(Enabled)
}

///|
fn render3d_ssao_quality_level_to_int(
  quality_level : ScreenSpaceAmbientOcclusionQualityLevel,
) -> Int {
  match quality_level {
    Low => 0
    Medium => 1
    High => 2
    Ultra => 3
    Custom(_, _) => 4
  }
}

///|
fn render3d_prepare_camera_screen_space_reflections_settings(
  camera : Camera3dViewPayload,
) -> Unit {
  match camera.screen_space_reflections {
    Some(settings) =>
      @render.host_gpu_prepare_mesh3d_screen_space_reflections_settings(
        min_perceptual_roughness_start=settings.min_perceptual_roughness_start,
        min_perceptual_roughness_end=settings.min_perceptual_roughness_end,
        max_perceptual_roughness_start=settings.max_perceptual_roughness_start,
        max_perceptual_roughness_end=settings.max_perceptual_roughness_end,
        edge_fadeout_start=settings.edge_fadeout_start,
        edge_fadeout_end=settings.edge_fadeout_end,
        thickness=settings.thickness,
        linear_steps=settings.linear_steps,
        linear_march_exponent=settings.linear_march_exponent,
        bisection_steps=settings.bisection_steps,
        use_secant=settings.use_secant,
      )
    None => ()
  }
}

///|
fn render3d_main_pass_skips_deferred_opaque(
  material_properties : @material.MaterialProperties,
) -> Bool {
  material_properties.render_phase_type is @material.RenderPhaseType::Opaque &&
  material_properties.render_method is OpaqueRendererMethod::Deferred
}

///|
fn render3d_draw_gizmo_lines_3d(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
) -> Unit {
  ignore(camera_entity)
  ignore(camera)
  ignore(
    @render.host_gpu_execute_queued_line_gizmo_phase_draws(
      phase_kind=@render.HOST_GPU_LINE_GIZMO_PHASE_3D,
      view_layers_mask=camera.layers.mask(),
    ),
  )
}

///|
fn render3d_resolve_scattering_medium(
  world : @ecs.World,
  handle : @asset.Handle[ScatteringMedium],
) -> ScatteringMedium? {
  let source_world = @render.render_source_world(world)
  let medium_assets_key : @ecs.ResourceKey[@asset.Assets[ScatteringMedium]] = @asset.assets_resource_key()
  match source_world.get_resource(medium_assets_key) {
    Some(assets) => assets.get(handle)
    None => None
  }
}

///|
fn render3d_prepare_camera_atmosphere_resources(
  world : @ecs.World,
  camera : Camera3dViewPayload,
) -> Unit {
  guard camera.atmosphere is Some(extracted_atmosphere) else { return }
  guard render3d_resolve_scattering_medium(world, extracted_atmosphere.medium)
    is Some(medium) else {
    return
  }
  let settings = match camera.atmosphere_settings {
    Some(value) => value
    None => @pbr_atmosphere.pbr_atmosphere_settings_default()
  }
  let gpu_medium = GpuScatteringMedium::new(
    medium,
    ScatteringMediumSampler::ScatteringMediumSampler(),
  )
  @render.host_gpu_prepare_mesh3d_scattering_medium_resources(
    density_width=gpu_medium.density_lut_width(),
    density_height=gpu_medium.density_lut_height(),
    density_bytes=gpu_medium.density_lut_rgba32f_bytes(),
    scattering_width=gpu_medium.scattering_lut_width(),
    scattering_height=gpu_medium.scattering_lut_height(),
    scattering_bytes=gpu_medium.scattering_lut_rgba32f_bytes(),
  )
  let gpu_settings = @pbr_atmosphere.pbr_gpu_atmosphere_settings(settings)
  let gpu_atmosphere = @pbr_atmosphere.pbr_gpu_atmosphere_from_extracted(
    extracted_atmosphere.inner_radius,
    extracted_atmosphere.outer_radius,
    extracted_atmosphere.ground_albedo,
    extracted_atmosphere.world_to_atmosphere,
  )
  let textures = @pbr_atmosphere.AtmosphereTextures::from_settings(gpu_settings)
  let world_to_atmosphere = gpu_atmosphere.world_to_atmosphere
  @render.host_gpu_prepare_mesh3d_atmosphere_resources(
    ground_albedo_x=gpu_atmosphere.ground_albedo.x,
    ground_albedo_y=gpu_atmosphere.ground_albedo.y,
    ground_albedo_z=gpu_atmosphere.ground_albedo.z,
    inner_radius=gpu_atmosphere.inner_radius,
    outer_radius=gpu_atmosphere.outer_radius,
    camera_world_x=camera.transform.translation.x,
    camera_world_y=camera.transform.translation.y,
    camera_world_z=camera.transform.translation.z,
    world_to_atmosphere_x_axis_x=world_to_atmosphere.matrix3.x_axis.x,
    world_to_atmosphere_x_axis_y=world_to_atmosphere.matrix3.x_axis.y,
    world_to_atmosphere_x_axis_z=world_to_atmosphere.matrix3.x_axis.z,
    world_to_atmosphere_y_axis_x=world_to_atmosphere.matrix3.y_axis.x,
    world_to_atmosphere_y_axis_y=world_to_atmosphere.matrix3.y_axis.y,
    world_to_atmosphere_y_axis_z=world_to_atmosphere.matrix3.y_axis.z,
    world_to_atmosphere_z_axis_x=world_to_atmosphere.matrix3.z_axis.x,
    world_to_atmosphere_z_axis_y=world_to_atmosphere.matrix3.z_axis.y,
    world_to_atmosphere_z_axis_z=world_to_atmosphere.matrix3.z_axis.z,
    world_to_atmosphere_translation_x=world_to_atmosphere.translation.x,
    world_to_atmosphere_translation_y=world_to_atmosphere.translation.y,
    world_to_atmosphere_translation_z=world_to_atmosphere.translation.z,
    transmittance_width=textures.transmittance_lut.width,
    transmittance_height=textures.transmittance_lut.height,
    transmittance_lut_samples=gpu_settings.transmittance_lut_samples,
    multiscattering_width=textures.multiscattering_lut.width,
    multiscattering_height=textures.multiscattering_lut.height,
    multiscattering_lut_dirs=gpu_settings.multiscattering_lut_dirs,
    multiscattering_lut_samples=gpu_settings.multiscattering_lut_samples,
    sky_view_width=textures.sky_view_lut.width,
    sky_view_height=textures.sky_view_lut.height,
    sky_view_lut_samples=gpu_settings.sky_view_lut_samples,
    aerial_view_width=textures.aerial_view_lut.width,
    aerial_view_height=textures.aerial_view_lut.height,
    aerial_view_depth=textures.aerial_view_lut.depth_or_array_layers,
    aerial_view_lut_samples=gpu_settings.aerial_view_lut_samples,
    aerial_view_lut_max_distance=gpu_settings.aerial_view_lut_max_distance,
    sky_max_samples=gpu_settings.sky_max_samples,
    rendering_method=gpu_settings.rendering_method,
  )
}

///|
fn render3d_dispatch_camera_atmosphere_environment(
  camera_entity : @core.Entity,
  camera : Camera3dViewPayload,
) -> Unit {
  guard camera.atmosphere is Some(_) else { return }
  guard camera.atmosphere_environment_map_light
    is Some(atmosphere_environment_map_light) else {
    return
  }
  guard camera.generated_environment_map_light
    is Some(generated_environment_map_light) else {
    return
  }
  guard generated_environment_map_light.environment_map is Some(environment_map) else {
    return
  }
  let environment_texture_id = environment_map.id()
  if environment_texture_id < 0 ||
    !@render.asset_is_texture_loaded(texture_id=environment_texture_id) {
    return
  }
  let size = @pbr_atmosphere.pbr_validate_atmosphere_environment_map_size(
    atmosphere_environment_map_light.size,
  )
  @render.host_gpu_dispatch_mesh3d_atmosphere_environment(
    camera_key_hi=camera_entity.id,
    camera_key_lo=camera_entity.generation,
    environment_texture_id~,
    environment_width=size.x,
    environment_height=size.y,
  )
}

///|
fn render3d_generate_camera_environment_map_light(
  camera : Camera3dViewPayload,
  blue_noise_texture_id : Int,
) -> Unit {
  guard camera.generated_environment_map_light
    is Some(generated_environment_map_light) else {
    return
  }
  guard camera.environment_map_light is Some(environment_map_light) else {
    return
  }
  guard render3d_loaded_image_texture_id(
      generated_environment_map_light.environment_map,
    )
    is Some(source_texture_id) else {
    return
  }
  guard render3d_loaded_image_texture_id(environment_map_light.diffuse_map)
    is Some(diffuse_texture_id) else {
    return
  }
  guard render3d_loaded_image_texture_id(environment_map_light.specular_map)
    is Some(specular_texture_id) else {
    return
  }
  if blue_noise_texture_id < 0 {
    return
  }
  @render.host_gpu_generate_environment_map_light(
    source_texture_id~,
    diffuse_texture_id~,
    specular_texture_id~,
    blue_noise_texture_id~,
  )
}

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
  msaa_sample_count : Int,
  view_width_logical : Int,
  view_height_logical : Int,
  clear_color : @color.Color,
  viewport_x : Int,
  viewport_y : Int,
  viewport_width : Int,
  viewport_height : Int,
  camera_pass_projection : @pbr_render.Render3dPassProjection,
  pass_lighting : Render3dLightingState,
  camera_exposure_value : Float,
  shadow_bindings : Render3dViewShadowBindings,
  environment_map_state : Render3dEnvironmentMapState,
  light_probe_state : Render3dLightProbeState,
  point_shadow_near : Float,
  scene_pass_kind : Int,
  clear_enabled : Bool,
  cleared_targets_this_frame : Array[Int],
  camera_forward_decal_enabled : Bool,
  camera_clustered_decal_enabled : Bool,
  camera_deferred_enabled : Bool,
  distance_fog : DistanceFog,
  fog_enabled : Bool,
  transmission_enabled : Bool,
  transmission_steps : Int,
  transmission_blur_taps : Int,
  wireframe_config : WireframeConfig?,
  prepass_depth_texture_id~ : Int,
  prepass_normal_texture_id~ : Int,
  prepass_motion_vector_texture_id~ : Int,
  prepass_deferred_texture_id~ : Int,
  prepass_deferred_lighting_pass_id_texture_id~ : Int,
) -> Unit {
  let draw_items = draw_queue_entry.draw_items
  let lightmap_bindless_supported = @render.host_gpu_mesh3d_binding_arrays_are_usable(
    required_storage_textures_per_shader_stage=(@pbr_light_probe.STANDARD_MATERIAL_FRAGMENT_SHADER_MIN_TEXTURE_BINDINGS +
    @pbr_light_probe.MAX_VIEW_LIGHT_PROBES).reinterpret_as_uint(),
    required_binding_array_sampler_elements_per_shader_stage=@pbr_render.RENDER3D_LIGHTMAPS_PER_SLAB.reinterpret_as_uint(),
  )
  match world.get_resource_mut(@lightmap.ecs_key_render_lightmaps) {
    Some(render_lightmaps) =>
      render_lightmaps.modify(fn(value) {
        value.set_bindless_supported(lightmap_bindless_supported)
        value.clear()
      })
    None => ()
  }
  let point_shadow_binding = shadow_bindings.point
  let directional_shadow_binding = shadow_bindings.directional
  let render_decals = match
    world.get_resource(@pbr_decal.ecs_key_render_clustered_decals) {
    Some(decals) => decals
    None => @pbr_decal.RenderClusteredDecals::RenderClusteredDecals()
  }
  let decals_buffer = match
    world.get_resource(@pbr_decal.DecalsBuffer::resource()) {
    Some(buffer) => buffer
    None => @pbr_decal.DecalsBuffer::DecalsBuffer()
  }
  @render.host_gpu_prepare_mesh3d_clustered_decals(
    decal_words=decals_buffer.gpu_words(),
    texture_ids=render_decals.texture_ids(),
  )
  fn prepare_light_probe_bindings() -> Unit {
    @render.host_gpu_prepare_mesh3d_light_probes(
      light_probes_uniform_bytes=light_probe_state.uniform_bytes,
      uniform_offset=light_probe_state.uniform_offset,
      diffuse_texture_ids=light_probe_state.diffuse_texture_ids,
      specular_texture_ids=light_probe_state.specular_texture_ids,
      irradiance_volume_texture_ids=light_probe_state.irradiance_volume_texture_ids,
    )
  }
  fn prepare_view_bind_group(transmission_source_texture_id : Int) -> Unit {
    @render.host_gpu_prepare_mesh3d_view_bind_group(
      transmission_source_texture_id~,
      point_shadow_texture_id=point_shadow_binding.texture_id,
      directional_shadow_texture_id=directional_shadow_binding.texture_id,
      environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
      environment_specular_texture_id=environment_map_state.specular_texture_id,
      prepass_depth_texture_id~,
      prepass_normal_texture_id~,
      prepass_motion_vector_texture_id~,
      prepass_deferred_texture_id~,
    )
  }
  render3d_prepare_camera_atmosphere_resources(world, camera)
  let scene_view_bind_group_prepared = point_shadow_binding.texture_id >= 0 ||
    directional_shadow_binding.texture_id >= 0
  if directional_shadow_binding.texture_id >= 0 &&
    directional_shadow_binding.cascade_count > 0 {
    @app.timeline_trace_emit_counter_int(
      "render_3d_main_pass_directional_shadow_resources", 1,
    )
  }
  if scene_view_bind_group_prepared {
    prepare_view_bind_group(-1)
  }
  fn pass_viewport(target_id : Int) -> (Int, Int, Int, Int) {
    @pbr_render.render3d_pass_viewport_for_target(
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
  if camera.screen_space_ambient_occlusion is Some(ssao_settings) {
    let (slice_count, samples_per_slice_side) = @pbr_ssao.ssao_quality_sample_counts(
      ssao_settings.quality_level,
    )
    @render.host_gpu_prepare_mesh3d_ssao_resources(
      width=viewport_width,
      height=viewport_height,
      constant_object_thickness=ssao_settings.constant_object_thickness,
    )
    @render.host_gpu_prepare_mesh3d_ssao_pipeline(
      quality_level=render3d_ssao_quality_level_to_int(
        ssao_settings.quality_level,
      ),
      custom_slice_count=slice_count,
      custom_samples_per_slice_side=samples_per_slice_side,
      temporal_jitter=camera.temporal_jitter is Some(_),
    )
  }
  let (agx_lut_texture_id, tony_lut_texture_id, blender_lut_texture_id) = render3d_main_pass_tonemapping_lut_ids(
    world, camera,
  )
  let (blue_noise_texture_id, area_light_luts_texture_id, dfg_lut_texture_id) = render3d_main_pass_pbr_internal_lut_ids(
    world,
  )
  @pbr_render.render3d_begin_pass_3d(
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
    point_shadow_texture_id=point_shadow_binding.texture_id,
    point_shadow_enabled=point_shadow_binding.enabled,
    point_shadow_depth_bias=point_shadow_binding.depth_bias,
    directional_shadow_texture_id=directional_shadow_binding.texture_id,
    directional_shadow_enabled=directional_shadow_binding.enabled,
    directional_shadow_depth_bias=pass_lighting.directional_shadow_depth_bias,
    directional_shadow_normal_bias=pass_lighting.directional_shadow_normal_bias,
    directional_shadow_soft_size=pass_lighting.directional_shadow_soft_size,
    directional_shadow_cascade_count=directional_shadow_binding.cascade_count,
    directional_shadow_cascade_overlap=pass_lighting.directional_cascade_overlap_proportion,
    directional_shadow_cascade_data=directional_shadow_binding.cascade_data,
    environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
    environment_specular_texture_id=environment_map_state.specular_texture_id,
    environment_map_intensity=environment_map_state.intensity,
    environment_map_rotation=environment_map_state.rotation,
    tonemap_in_shader=render3d_main_pass_tonemap_in_shader(camera),
    tonemapping_mode=render3d_main_pass_tonemapping_mode(camera),
    tonemapping_agx_lut_texture_id=agx_lut_texture_id,
    tonemapping_tony_lut_texture_id=tony_lut_texture_id,
    tonemapping_blender_lut_texture_id=blender_lut_texture_id,
    pbr_blue_noise_texture_id=blue_noise_texture_id,
    pbr_area_light_luts_texture_id=area_light_luts_texture_id,
    pbr_dfg_lut_texture_id=dfg_lut_texture_id,
    deband_dither_enabled=render3d_main_pass_deband_dither_enabled(camera),
    prepass_depth_texture_id~,
    prepass_normal_texture_id~,
    prepass_motion_vector_texture_id~,
    prepass_deferred_texture_id~,
    prepass_deferred_lighting_pass_id_texture_id~,
    screen_space_reflections=camera.screen_space_reflections is Some(_),
    msaa_sample_count~,
    point_shadow_near~,
    pass_kind=scene_pass_kind,
    clear_enabled=@pbr_render.render3d_pass_clear_enabled_for_target(
      cleared_targets_this_frame, scene_target_id, clear_enabled,
    ),
  )
  prepare_light_probe_bindings()
  render3d_prepare_camera_screen_space_reflections_settings(camera)
  prepare_view_bind_group(-1)
  if camera.atmosphere is Some(_) {
    @render.host_gpu_dispatch_mesh3d_atmosphere_luts(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
    )
    render3d_dispatch_camera_atmosphere_environment(camera_entity, camera)
  }
  render3d_generate_camera_environment_map_light(camera, blue_noise_texture_id)
  if camera_deferred_enabled {
    @render.host_gpu_draw_mesh3d_deferred_lighting(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
      screen_space_ambient_occlusion=camera.screen_space_ambient_occlusion
        is Some(_),
      screen_space_reflections=camera.screen_space_reflections is Some(_),
      distance_fog=fog_enabled,
      atmosphere=camera.atmosphere is Some(_),
    )
  }
  if camera.screen_space_reflections is Some(_) {
    let ssr_ping_target_id = render3d_postprocess_ping_target_get_or_create(
      world, camera_entity, view_width, view_height,
    )
    @render.host_gpu_draw_mesh3d_screen_space_reflections(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
      source_texture_id=scene_target_id,
      ping_target_id=ssr_ping_target_id,
      atmosphere=camera.atmosphere is Some(_),
    )
  }
  let main_phase_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_main_pass_construction",
  )
  let main_phase = render3d_mesh_gpu_binned_phase_new()
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
    let material_properties = mesh.material_properties
    if render3d_main_pass_skips_deferred_opaque(material_properties) {
      continue
    }
    guard render3d_mesh_draw_alpha(
        mesh.material.alpha_mode,
        mesh.material.base_color.a,
      )
      is Some(base_draw_alpha) else {
      continue
    }
    let draw_material = mesh.material
    let (
      lightmap_texture_id,
      lightmap_slab_index,
      lightmap_slot_index,
      lightmap_slab_texture_ids,
      lightmap_uv_min_x,
      lightmap_uv_min_y,
      lightmap_uv_max_x,
      lightmap_uv_max_y,
    ) = match mesh.lightmap {
      Some(lightmap) if lightmap.image.id() >= 0 => {
        let uv_min = lightmap.uv_rect.min()
        let uv_max = lightmap.uv_rect.max()
        let (slab_index, slot_index, slab_texture_ids) = match
          world.get_resource_mut(@lightmap.ecs_key_render_lightmaps) {
          Some(render_lightmaps) =>
            render_lightmaps.modify(fn(value) {
              let render_lightmap = value.insert_lightmap(
                extracted_mesh.entity.main_entity,
                lightmap,
              )
              (
                render_lightmap.slab_index.to_int(),
                render_lightmap.slot_index.to_int(),
                value.slab_texture_ids(render_lightmap.slab_index),
              )
            })
          None => (-1, 0, [lightmap.image.id()])
        }
        (
          lightmap.image.id(),
          slab_index,
          slot_index,
          slab_texture_ids,
          uv_min.x,
          uv_min.y,
          uv_max.x,
          uv_max.y,
        )
      }
      _ => (-1, -1, -1, [], 0.0F, 0.0F, 0.0F, 0.0F)
    }
    let draw_alpha = base_draw_alpha
    let mut texture_id = match draw_material.base_color_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let mut normal_texture_id = match draw_material.normal_map_texture {
      Some(texture) => texture.id()
      None => -1
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
    let specular_texture_id = match draw_material.specular_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let specular_tint_texture_id = match draw_material.specular_tint_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let clearcoat_texture_id = match draw_material.clearcoat_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let clearcoat_roughness_texture_id = match
      draw_material.clearcoat_roughness_texture {
      Some(texture) => texture.id()
      None => -1
    }
    let clearcoat_normal_texture_id = match
      draw_material.clearcoat_normal_texture {
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
    let anisotropy_strength = @pbr_render.maxf(
      0.0F,
      @pbr_render.minf(1.0F, draw_material.anisotropy_strength),
    )
    let max_relief_mapping_search_steps = Float::from_double(
      draw_material.parallax_mapping_method.max_steps().to_double(),
    )
    let clearcoat_reflectance = @pbr_render.maxf(
      0.0F,
      draw_material.reflectance + draw_material.clearcoat * 0.5F,
    )
    let clearcoat_roughness = @pbr_render.minf(
      draw_material.perceptual_roughness,
      draw_material.clearcoat_perceptual_roughness,
    )
    let draw_roughness = if draw_material.clearcoat > 0.0F {
      clearcoat_roughness
    } else {
      draw_material.perceptual_roughness
    }
    let needs_mesh_distance = fog_enabled
    let mesh_distance = if needs_mesh_distance {
      mesh.transform.translation.sub(camera.transform.translation).length()
    } else {
      0.0F
    }
    let forward_decal_inv_depth_fade_factor = if mesh.is_forward_decal {
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
      1.0F / safe_depth_fade_factor
    } else {
      1.0F / 8.0F
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
    let draw_diffuse_transmission = @pbr_render.clamp01(
      draw_material.diffuse_transmission,
    )
    let draw_specular_transmission = @pbr_render.clamp01(
      draw_material.specular_transmission,
    )
    let draw_render_phase_type = material_properties.render_phase_type
    let draw_thickness = @pbr_render.maxf(0.0F, draw_material.thickness)
    let draw_ior = @pbr_render.maxf(1.0F, draw_material.ior)
    if draw_render_phase_type is @material.RenderPhaseType::Transparent &&
      camera.oit_settings is Some(oit_settings) &&
      draw_alpha < oit_settings.alpha_threshold {
      continue
    }
    let mut draw_point_shadow_enabled = point_shadow_binding.enabled
    if !material_properties.shadows_enabled {
      draw_point_shadow_enabled = 0.0F
    }
    if mesh.has_not_shadow_receiver {
      draw_point_shadow_enabled = 0.0F
    }
    if draw_point_shadow_enabled > 0.0F &&
      (draw_diffuse_transmission > 0.0F || draw_specular_transmission > 0.0F) &&
      !mesh.has_transmitted_shadow_receiver {
      draw_point_shadow_enabled = 0.0F
    }
    let mesh_flags = render3d_mesh_flags(extracted_mesh)
    let draw_flags = render3d_mesh_draw_flags(extracted_mesh)
    let draw_indexed = mesh.mesh_is_indexed
    let draw_indirect_parameters_index = if draw_indexed {
      indexed_indirect_parameter_indices[draw_item_index]
    } else {
      non_indexed_indirect_parameter_indices[draw_item_index]
    }
    let draw_vertex_shader_path = material_properties.get_shader(
      @material.MATERIAL_VERTEX_SHADER_LABEL,
    )
    let draw_fragment_shader_path = match
      material_properties.get_shader(@material.MATERIAL_FRAGMENT_SHADER_LABEL) {
      Some(shader_path) => Some(shader_path)
      None =>
        match mesh.material_extension {
          Some(extension) => extension.fragment_shader_path
          None => None
        }
    }
    let draw_payload = @pbr_render.render3d_build_mesh_gpu_draw_payload(
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
      clearcoat_texture_id,
      clearcoat_roughness_texture_id,
      clearcoat_normal_texture_id,
      draw_surface_roughness,
      draw_reflectance,
      draw_diffuse_transmission,
      draw_specular_transmission,
      draw_thickness,
      draw_ior,
      -1,
      0.0F,
      0.0F,
      point_shadow_binding.texture_id,
      draw_point_shadow_enabled,
      point_shadow_binding.depth_bias,
      environment_map_state.diffuse_texture_id,
      environment_map_state.specular_texture_id,
      environment_map_state.intensity,
      environment_map_state.rotation,
      draw_material.specular_tint,
      anisotropy_strength,
      max_relief_mapping_search_steps,
      mesh_flags,
      draw_flags,
      specular_texture_id~,
      forward_decal=mesh.is_forward_decal,
      forward_decal_inv_depth_fade_factor~,
      vertex_shader_path=draw_vertex_shader_path,
      fragment_shader_path=draw_fragment_shader_path,
      material_extension_bind_group_data=mesh.material_bind_group_data,
      material_pipeline_id=draw_item.pipeline_id,
      skinning_key_hi=mesh.skinning_key_hi,
      skinning_key_lo=if mesh.skinning_key_hi >= 0 { 0 } else { -1 },
      morph_weights_index=mesh.morph_weights_index,
      previous_morph_weights_index=mesh.previous_morph_weights_index,
      morph_targets_texture_id=mesh.morph_targets_texture_id,
      lightmap_texture_id~,
      lightmap_slab_index~,
      lightmap_slot_index~,
      lightmap_slab_texture_ids~,
      lightmap_uv_min_x~,
      lightmap_uv_min_y~,
      lightmap_uv_max_x~,
      lightmap_uv_max_y~,
      world_from_local=Some(mesh.world_from_local),
      previous_world_from_local=Some(mesh.previous_world_from_local),
      instance_vertex_buffer_id=mesh.instance_vertex_buffer_id,
    )
    if draw_render_phase_type is @material.RenderPhaseType::Transparent {
      transparent_draws.push(draw_payload)
      continue
    }
    if transmission_enabled &&
      draw_render_phase_type is @material.RenderPhaseType::Transmissive {
      transmissive_phase_items.push(TransmissivePhaseItem3d::{
        entity: extracted_mesh.entity,
        distance: draw_item.distance,
        payload: draw_payload,
      })
      continue
    }
    render3d_mesh_gpu_binned_phase_push(main_phase, draw_payload)
  }
  let wireframe_draws : Array[MeshGpuDrawPayload3d] = []
  for draw_item_index in 0..<draw_items.length() {
    let draw_item = draw_items[draw_item_index]
    let extracted_mesh = meshes[draw_item.extracted_index]
    let mesh = extracted_mesh.payload
    if !render3d_mesh_should_draw_wireframe(extracted_mesh, wireframe_config) {
      continue
    }
    guard render3d_wireframe_mesh_id(world, mesh.mesh_handle)
      is Some(wireframe_mesh_id) else {
      continue
    }
    let wireframe_color = render3d_mesh_wireframe_color(
      extracted_mesh, wireframe_config,
    )
    let _wireframe_line_width = render3d_mesh_wireframe_line_width(
      extracted_mesh, wireframe_config,
    )
    let _wireframe_topology = render3d_mesh_wireframe_topology(
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
      @pbr_render.render3d_build_mesh_gpu_draw_payload(
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
        @color.Color::white(),
        0.0F,
        0.0F,
        render3d_mesh_flags(extracted_mesh),
        render3d_mesh_draw_flags(extracted_mesh),
        material_pipeline_id=@material.CachedRenderPipelineId::invalid(),
        world_from_local=Some(mesh.world_from_local),
        previous_world_from_local=Some(mesh.previous_world_from_local),
      ),
    )
  }
  let batched_draw_entries = render3d_mesh_gpu_binned_phase_entries(main_phase)
  @app.timeline_trace_emit_counter_int(
    "render_3d_main_pass_input_draw_items",
    draw_items.length(),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_main_pass_binned_items",
    render3d_mesh_gpu_binned_phase_entries(main_phase).length(),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_main_pass_binned_batches",
    render3d_mesh_gpu_binned_phase_batch_count(main_phase),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_main_pass_transmissive_items",
    transmissive_phase_items.length(),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_main_pass_transparent_items",
    transparent_draws.length(),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_main_pass_wireframe_items",
    wireframe_draws.length(),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_main_pass_draw_entries",
    batched_draw_entries.length(),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "render_3d_main_pass_construction",
    main_phase_trace_start_us,
  )
  @render.host_gpu_prepare_mesh3d_main_pass_draw_batch(
    preprocess_camera_key_hi=camera_entity.id,
    preprocess_camera_key_lo=camera_entity.generation,
    pass_kind=scene_pass_kind,
    entries=batched_draw_entries,
  )
  render3d_draw_mesh_gpu_binned_phase(main_phase)
  render3d_draw_gizmo_lines_3d(camera_entity, camera)
  let skybox_drawn = @core_pipeline.main_opaque_pass_3d_draw_skybox(
    world,
    extracted_camera.entity.render_entity,
  )
  if skybox_drawn {
    @app.timeline_trace_emit_counter_int(
      "render_3d_main_pass_skybox_drawn_before_volumetric_fog", 1,
    )
  }
  if camera.atmosphere is Some(_) {
    @render.host_gpu_draw_mesh3d_atmosphere_sky(
      camera_key_hi=camera_entity.id,
      camera_key_lo=camera_entity.generation,
    )
  }
  @render.host_gpu_end_active_pass_preserving_state()
  let transmissive_draws = render3d_sort_transmissive_phase_items(
    transmissive_phase_items,
  )
  if transmissive_draws.length() > 0 {
    let transmission_source_target_id = render3d_transmission_source_target_get_or_create(
      world, camera_entity, view_width, view_height,
    )
    let transmission_source_texture_id = if transmission_steps > 0 {
      transmission_source_target_id
    } else {
      -1
    }
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
        render3d_copy_texture_to_texture(
          scene_target_id, transmission_source_target_id,
        )
      }
      let (
        transmission_viewport_x,
        transmission_viewport_y,
        transmission_viewport_width,
        transmission_viewport_height,
      ) = pass_viewport(scene_target_id)
      @pbr_render.render3d_begin_pass_3d(
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
        point_shadow_texture_id=point_shadow_binding.texture_id,
        point_shadow_enabled=point_shadow_binding.enabled,
        point_shadow_depth_bias=point_shadow_binding.depth_bias,
        directional_shadow_texture_id=directional_shadow_binding.texture_id,
        directional_shadow_enabled=directional_shadow_binding.enabled,
        directional_shadow_depth_bias=pass_lighting.directional_shadow_depth_bias,
        directional_shadow_normal_bias=pass_lighting.directional_shadow_normal_bias,
        directional_shadow_soft_size=pass_lighting.directional_shadow_soft_size,
        directional_shadow_cascade_count=directional_shadow_binding.cascade_count,
        directional_shadow_cascade_overlap=pass_lighting.directional_cascade_overlap_proportion,
        directional_shadow_cascade_data=directional_shadow_binding.cascade_data,
        transmission_source_texture_id~,
        environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
        environment_specular_texture_id=environment_map_state.specular_texture_id,
        environment_map_intensity=environment_map_state.intensity,
        environment_map_rotation=environment_map_state.rotation,
        tonemap_in_shader=render3d_main_pass_tonemap_in_shader(camera),
        tonemapping_mode=render3d_main_pass_tonemapping_mode(camera),
        tonemapping_agx_lut_texture_id=agx_lut_texture_id,
        tonemapping_tony_lut_texture_id=tony_lut_texture_id,
        tonemapping_blender_lut_texture_id=blender_lut_texture_id,
        pbr_blue_noise_texture_id=blue_noise_texture_id,
        pbr_area_light_luts_texture_id=area_light_luts_texture_id,
        pbr_dfg_lut_texture_id=dfg_lut_texture_id,
        deband_dither_enabled=render3d_main_pass_deband_dither_enabled(camera),
        prepass_depth_texture_id~,
        prepass_normal_texture_id~,
        prepass_motion_vector_texture_id~,
        prepass_deferred_texture_id~,
        prepass_deferred_lighting_pass_id_texture_id~,
        msaa_sample_count~,
        point_shadow_near~,
        pass_kind=scene_pass_kind,
        clear_enabled=0,
      )
      prepare_light_probe_bindings()
      prepare_view_bind_group(transmission_source_texture_id)
      for i in transmission_range.0..<transmission_range.1 {
        let transmissive_draw = transmissive_draws[i]
        transmissive_draw.entity |> ignore
        @pbr_render.render3d_draw_mesh_gpu_payload(MeshGpuDrawPayload3d::{
          ..transmissive_draw.payload,
          transmission_source_texture_id,
          transmission_blur_taps: Float::from_double(
            transmission_blur_taps.to_double(),
          ),
          transmission_steps: Float::from_double(transmission_steps.to_double()),
          point_shadow_texture_id: transmissive_draw.payload.point_shadow_texture_id,
          point_shadow_enabled: transmissive_draw.payload.point_shadow_enabled,
          point_shadow_depth_bias: transmissive_draw.payload.point_shadow_depth_bias,
        })
      }
      @render.host_gpu_end_active_pass_preserving_state()
    }
  }
  if transparent_draws.length() > 0 || wireframe_draws.length() > 0 {
    let (
      transparent_viewport_x,
      transparent_viewport_y,
      transparent_viewport_width,
      transparent_viewport_height,
    ) = pass_viewport(scene_target_id)
    @pbr_render.render3d_begin_pass_3d(
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
      point_shadow_texture_id=point_shadow_binding.texture_id,
      point_shadow_enabled=point_shadow_binding.enabled,
      point_shadow_depth_bias=point_shadow_binding.depth_bias,
      directional_shadow_texture_id=directional_shadow_binding.texture_id,
      directional_shadow_enabled=directional_shadow_binding.enabled,
      directional_shadow_depth_bias=pass_lighting.directional_shadow_depth_bias,
      directional_shadow_normal_bias=pass_lighting.directional_shadow_normal_bias,
      directional_shadow_soft_size=pass_lighting.directional_shadow_soft_size,
      directional_shadow_cascade_count=directional_shadow_binding.cascade_count,
      directional_shadow_cascade_overlap=pass_lighting.directional_cascade_overlap_proportion,
      directional_shadow_cascade_data=directional_shadow_binding.cascade_data,
      environment_diffuse_texture_id=environment_map_state.diffuse_texture_id,
      environment_specular_texture_id=environment_map_state.specular_texture_id,
      environment_map_intensity=environment_map_state.intensity,
      environment_map_rotation=environment_map_state.rotation,
      tonemap_in_shader=render3d_main_pass_tonemap_in_shader(camera),
      tonemapping_mode=render3d_main_pass_tonemapping_mode(camera),
      tonemapping_agx_lut_texture_id=agx_lut_texture_id,
      tonemapping_tony_lut_texture_id=tony_lut_texture_id,
      tonemapping_blender_lut_texture_id=blender_lut_texture_id,
      pbr_blue_noise_texture_id=blue_noise_texture_id,
      pbr_area_light_luts_texture_id=area_light_luts_texture_id,
      pbr_dfg_lut_texture_id=dfg_lut_texture_id,
      deband_dither_enabled=render3d_main_pass_deband_dither_enabled(camera),
      prepass_depth_texture_id~,
      prepass_normal_texture_id~,
      prepass_motion_vector_texture_id~,
      prepass_deferred_texture_id~,
      prepass_deferred_lighting_pass_id_texture_id~,
      msaa_sample_count~,
      point_shadow_near~,
      pass_kind=scene_pass_kind,
      clear_enabled=0,
    )
    prepare_light_probe_bindings()
    prepare_view_bind_group(-1)
    for draw_payload in transparent_draws {
      @pbr_render.render3d_draw_mesh_gpu_payload(draw_payload)
    }
    for wireframe_draw in wireframe_draws {
      @pbr_render.render3d_draw_mesh_gpu_payload(wireframe_draw)
    }
    @render.host_gpu_end_active_pass_preserving_state()
  }
}
