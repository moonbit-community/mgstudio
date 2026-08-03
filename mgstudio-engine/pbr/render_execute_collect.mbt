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
fn render3d_extract_ssao_settings(
  entity : @core.Entity,
  settings : ScreenSpaceAmbientOcclusion?,
  msaa : Msaa?,
) -> ScreenSpaceAmbientOcclusion? {
  guard settings is Some(ssao_settings) else { return None }
  let effective_msaa = match msaa {
    Some(value) => value
    None => Msaa::default()
  }
  if effective_msaa != Off {
    @app.log_error(
      "SSAO is being used which requires Msaa::Off, but camera \{entity.id} has Msaa::\{render3d_msaa_variant_name(effective_msaa)}",
    )
    return None
  }
  Some(ssao_settings)
}

///|
fn render3d_msaa_variant_name(msaa : Msaa) -> String {
  match msaa {
    Off => "Off"
    Sample2 => "Sample2"
    Sample4 => "Sample4"
    Sample8 => "Sample8"
  }
}

///|
priv struct Render3dEnvironmentLightProbeFound {
  mut value : Bool
}

///|
fn render3d_world_has_environment_light_probes(world : @ecs.World) -> Bool {
  let found = Render3dEnvironmentLightProbeFound::{ value: false }
  world.for_each_component(@light.ecs_key_environment_map_light, fn(
    entity,
    _environment_map_light,
  ) {
    if found.value {
      return
    }
    if (try! world.contains_by_key(entity, @light.ecs_key_light_probe)) {
      found.value = true
    }
  })
  found.value
}

///|
fn render3d_extracted_atmosphere_for_view(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> @pbr_atmosphere.ExtractedAtmosphere? {
  if !render_world.is_alive(render_entity) {
    return None
  }
  try! render_world.get_by_key(
    render_entity, @pbr_atmosphere.ecs_key_extracted_atmosphere,
  )
}

///|
fn render3d_gpu_atmosphere_settings_for_view(
  render_world : @ecs.World,
  render_entity : @core.Entity,
) -> @pbr_atmosphere.GpuAtmosphereSettings? {
  if !render_world.is_alive(render_entity) {
    return None
  }
  try! render_world.get_by_key(
    render_entity,
    @pbr_atmosphere.GpuAtmosphereSettings::component(),
  )
}

///|
fn render3d_execute_collect_cameras(
  source_world : @ecs.World,
  render_world : @ecs.World,
  world_transform_cache_value : @pbr_render.Render3dWorldTransformCache,
  gpu_instance_buffer_builder_requested : Bool,
  gpu_culling_supported : Bool,
  prepass_enabled : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
) -> Array[ExtractedCamera3d] {
  let trace_collect_cameras_start_us = @app.timeline_trace_begin_span(
    RenderQueue,
    "execute_3d_collect_cameras",
  )
  fn entity_key(entity : @core.Entity) -> UInt64 {
    let hi = entity.id.reinterpret_as_uint().to_uint64()
    let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
    (hi << 32) | lo
  }
  let projection_changed_entities = @hashset.HashSet([])
  let has_environment_light_probes = render3d_world_has_environment_light_probes(
    source_world,
  )
  let has_volumetric_fog_views = render3d_world_has_volumetric_fog_views(
    render_world,
  )
  let tick = source_world.get_tick_context().ticks()
  for entity in source_world.changed_components(ecs_key_projection, tick).read() {
    projection_changed_entities.add(entity_key(entity))
  }
  let cameras : Array[ExtractedCamera3d] = []
  let projection_updates : Array[
    (@core.Entity, Projection, ProjectionRuntime3d),
  ] = []
  let cluster_projection_updates : Array[
    (@core.Entity, @light_cluster.ClusterCameraProjection),
  ] = []
  let projection_runtime_removals : Array[@core.Entity] = []
  let camera_query : @ecs.Query[
    (
      @core.Entity,
      (
        @ecs.Read[Camera3d],
        @ecs.Optional[@camera_camera.Camera],
        @ecs.Optional[Projection],
      ),
      (
        @ecs.Optional[DistanceFog],
        @ecs.Optional[CameraDecalConfig3d],
        @ecs.Optional[CameraDeferredConfig3d],
        @ecs.Optional[AutoExposure],
      ),
      (
        @ecs.Optional[@camera_camera.RenderTarget],
        @ecs.Optional[@camera_render_layers.RenderLayers],
        @ecs.Optional[ProjectionRuntime3d],
        @ecs.Optional[@pbr_prepass.PreviousViewData],
      ),
    ),
    @ecs.All,
  ] = @ecs.query(source_world)
  try! camera_query.view(fn(_query_entity, data) {
    let (
      entity,
      (camera3d, camera_opt, projection_opt),
      (
        distance_fog_opt,
        decal_config_opt,
        deferred_config_opt,
        auto_exposure_opt,
      ),
      (target_opt, layers_opt, projection_runtime_opt, previous_view_data_opt),
    ) = data
    let camera = match camera_opt.value() {
      Some(v) => v
      None => Camera()
    }
    if !camera.is_active {
      return
    }
    let projection_component = projection_opt.value()
    let projection = match projection_component {
      Some(v) => v
      None => Projection::default()
    }
    let mut depth_texture_usages = render3d_prepare_view_depth_texture_usage_for_sampled_depth(
      camera3d.value(),
      has_volumetric_fog_views,
      false,
      false,
    )
    let projection_changed = projection_changed_entities.contains(
      entity_key(entity),
    )
    let sub_camera_view = camera.sub_camera_view
    let distance_fog = distance_fog_opt.value()
    let decal_config = decal_config_opt.value()
    let deferred_config = deferred_config_opt.value()
    let auto_exposure = auto_exposure_opt.value()
    let volumetric_fog = try! source_world.get_by_key(
      entity, ecs_key_volumetric_fog,
    )
    let phase_entity = phase_entity_ref3d_for_world_main(source_world, entity)
    let atmosphere = render3d_extracted_atmosphere_for_view(
      render_world,
      phase_entity.render_entity,
    )
    let atmosphere_settings = render3d_gpu_atmosphere_settings_for_view(
      render_world,
      phase_entity.render_entity,
    )
    if atmosphere is Some(_) {
      depth_texture_usages = depth_texture_usages.with_texture_binding()
    }
    let oit_settings = try! source_world.get_by_key(
      entity, ecs_key_order_independent_transparency_settings,
    )
    let screen_space_transmission = try! source_world.get_by_key(
      entity, ecs_key_screen_space_transmission,
    )
    let bloom = try! source_world.get_by_key(entity, ecs_key_bloom)
    let tonemapping = try! source_world.get_by_key(entity, ecs_key_tonemapping)
    let deband_dither = try! source_world.get_by_key(
      entity, ecs_key_deband_dither,
    )
    let chromatic_aberration = try! source_world.get_by_key(
      entity, ecs_key_chromatic_aberration,
    )
    let contrast_adaptive_sharpening = try! source_world.get_by_key(
      entity,
      @cas.ContrastAdaptiveSharpening::component(),
    )
    let custom_post_process3d = try! source_world.get_by_key(
      entity, ecs_key_custom_post_process3d,
    )
    let vignette = try! source_world.get_by_key(entity, ecs_key_vignette)
    let motion_blur = try! source_world.get_by_key(entity, ecs_key_motion_blur)
    let exposure = try! source_world.get_by_key(entity, ecs_key_exposure)
    let color_grading = try! source_world.get_by_key(
      entity, ecs_key_color_grading,
    )
    let environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_environment_map_light,
    )
    let generated_environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_generated_environment_map_light,
    )
    let atmosphere_environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_atmosphere_environment_map_light,
    )
    let irradiance_volume = try! source_world.get_by_key(
      entity, ecs_key_irradiance_volume,
    )
    let screen_space_reflections = try! source_world.get_by_key(
      entity, ecs_key_screen_space_reflections,
    )
    let contact_shadows = try! source_world.get_by_key(
      entity, ecs_key_contact_shadows,
    )
    let screen_space_ambient_occlusion_opt = try! source_world.get_by_key(
      entity, ecs_key_screen_space_ambient_occlusion,
    )
    let hdr_enabled = (try! source_world.get_by_key(entity, ecs_key_hdr))
      is Some(_)
    if @sys.get_env_var("MGSTUDIO_ATMOSPHERE_PARITY_DEBUG") is Some(_) &&
      atmosphere is Some(_) {
      println(
        "[DEBUG-atmosphere-parity] camera hdr=\{hdr_enabled} tonemapping=\{tonemapping is Some(_)} extracted_atmosphere=true ssr=\{screen_space_reflections is Some(_)}",
      )
    }
    let fxaa = try! source_world.get_by_key(entity, ecs_key_fxaa)
    let temporal_jitter = try! source_world.get_by_key(
      entity, ecs_key_temporal_jitter,
    )
    let deferred_prepass_enabled = prepass_enabled &&
      (
        (try! source_world.get_by_key(entity, ecs_key_deferred_prepass))
        is Some(_) ||
        default_opaque_renderer_method is Deferred ||
        screen_space_reflections is Some(_)
      )
    let depth_prepass_enabled = prepass_enabled &&
      (
        (try! source_world.get_by_key(entity, ecs_key_depth_prepass)) is Some(_) ||
        deferred_prepass_enabled ||
        screen_space_ambient_occlusion_opt is Some(_) ||
        contact_shadows is Some(_)
      )
    let normal_prepass_enabled = prepass_enabled &&
      (
        (try! source_world.get_by_key(entity, ecs_key_normal_prepass))
        is Some(_) ||
        screen_space_ambient_occlusion_opt is Some(_)
      )
    let no_indirect_drawing = (try! source_world.get_by_key(
        entity, ecs_key_no_indirect_drawing,
      ))
      is Some(_)
    let camera_indirect_enabled = @pbr_render.render3d_camera_indirect_enabled(
      gpu_instance_buffer_builder_requested, gpu_culling_supported, no_indirect_drawing,
    )
    let gpu_occlusion_culling_enabled = depth_prepass_enabled &&
      camera_indirect_enabled &&
      (try! source_world.get_by_key(entity, ecs_key_occlusion_culling))
      is Some(_)
    let motion_vector_prepass_enabled = prepass_enabled &&
      (
        (try! source_world.get_by_key(entity, ecs_key_motion_vector_prepass))
        is Some(_) ||
        gpu_occlusion_culling_enabled
      )
    let temporal_anti_aliasing = try! source_world.get_by_key(
      entity, ecs_key_temporal_anti_aliasing,
    )
    let shadow_filtering_method = try! source_world.get_by_key(
      entity, ecs_key_shadow_filtering_method,
    )
    let msaa = try! source_world.get_by_key(entity, ecs_key_msaa)
    let screen_space_ambient_occlusion = render3d_extract_ssao_settings(
      entity, screen_space_ambient_occlusion_opt, msaa,
    )
    if screen_space_ambient_occlusion is Some(_) {
      depth_texture_usages = depth_texture_usages.with_texture_binding()
    }
    let target = match target_opt.value() {
      Some(v) => v
      None => Screen
    }
    let layers = match layers_opt.value() {
      Some(v) => v
      None => RenderLayers()
    }
    let transform = @pbr_render.render3d_entity_world_transform_cached(
      source_world, entity, world_transform_cache_value,
    )
    let previous_view_data = previous_view_data_opt.value()
    let previous_transform = match previous_view_data {
      Some(v) => v.transform()
      None => transform
    }
    match @pbr_render.render3d_target_info(source_world, target) {
      Some(target_info) => {
        let mut camera_clamped = camera
        if camera.viewport is Some(viewport) {
          let clamped = @pbr_render.render3d_clamp_viewport(
            viewport,
            target_info.target_size,
          )
          camera_clamped = camera.with_viewport(clamped)
        }
        let projection = match projection_component {
          Some(component_projection) => {
            let (runtime_projection, runtime_update) = render3d_projection_runtime_update(
              component_projection,
              projection_runtime_opt.value(),
              projection_changed,
              camera_clamped,
              target_info.target_size,
              target_info.scale_factor,
            )
            if runtime_update is Some(runtime_state) {
              projection_updates.push(
                (entity, runtime_projection, runtime_state),
              )
            }
            runtime_projection
          }
          None =>
            render3d_projection_runtime_projection(
              projection,
              camera_clamped,
              target_info.target_size,
              target_info.scale_factor,
            )
        }
        cluster_projection_updates.push(
          (entity, render3d_cluster_camera_projection(projection)),
        )
        cameras.push({
          entity: phase_entity,
          payload: {
            decal_config,
            deferred_config,
            distance_fog,
            auto_exposure,
            volumetric_fog,
            atmosphere,
            atmosphere_settings,
            camera: camera_clamped,
            depth_texture_usages,
            depth_load_op: camera3d.value().depth_load_op(),
            projection,
            sub_camera_view,
            oit_settings,
            screen_space_transmission,
            bloom,
            tonemapping,
            deband_dither,
            chromatic_aberration,
            contrast_adaptive_sharpening,
            custom_post_process3d,
            vignette,
            motion_blur,
            exposure,
            color_grading,
            environment_map_light,
            generated_environment_map_light,
            atmosphere_environment_map_light,
            has_environment_light_probes,
            irradiance_volume,
            screen_space_ambient_occlusion,
            screen_space_reflections,
            contact_shadows,
            depth_prepass_enabled,
            normal_prepass_enabled,
            deferred_prepass_enabled,
            no_indirect_drawing,
            gpu_occlusion_culling_enabled,
            hdr_enabled,
            fxaa,
            temporal_jitter,
            temporal_anti_aliasing,
            shadow_filtering_method,
            motion_vector_prepass_enabled,
            msaa,
            transform,
            previous_transform,
            previous_clip_from_world: match previous_view_data {
              Some(v) => Some(v.clip_from_world())
              None => None
            },
            target_id: target_info.target_id,
            target_size: target_info.target_size,
            scale_factor: target_info.scale_factor,
            layers,
            invert_culling: camera.invert_culling,
          },
        })
      }
      None => ()
    }
    if projection_component is None &&
      (try! source_world.get_by_key(entity, ecs_key_projection_runtime3d))
      is Some(_) {
      projection_runtime_removals.push(entity)
    }
  })
  for update in projection_updates {
    try! source_world.set_by_key(update.0, ecs_key_projection, update.1)
    try! source_world.set_by_key(
      update.0,
      ecs_key_projection_runtime3d,
      update.2,
    )
  }
  for update in cluster_projection_updates {
    try! source_world.set_by_key(
      update.0,
      @light_cluster.ClusterCameraProjection::component(),
      update.1,
    )
  }
  for entity in projection_runtime_removals {
    try! (source_world.take(entity, ecs_key_projection_runtime3d) |> ignore)
  }
  @app.timeline_trace_end_span(
    RenderQueue,
    "execute_3d_collect_cameras",
    trace_collect_cameras_start_us,
  )
  cameras
}

///|
fn render3d_cluster_camera_projection(
  projection : Projection,
) -> @light_cluster.ClusterCameraProjection {
  let clip_from_view = projection.get_clip_from_view()
  let row_two = clip_from_view.row(2)
  let safe_row_two_z = if row_two.z.abs() <= 1.0e-6F {
    1.0e-6F
  } else {
    row_two.z
  }
  let is_orthographic = !projection.is_perspective()
  let orthographic_first_slice_depth = if is_orthographic {
    (row_two.w - 1.0F) / safe_row_two_z
  } else {
    0.0F
  }
  @light_cluster.ClusterCameraProjection::new(
    @light_cluster.ClusterProjectionMatrix3d::from_rows(
      clip_from_view.row(0),
      clip_from_view.row(1),
      row_two,
      clip_from_view.row(3),
    ),
    is_orthographic,
    projection.far(),
    orthographic_first_slice_depth,
  )
}

///|
fn render3d_set_mesh_motion_vector_flags(
  cameras : Array[ExtractedCamera3d],
) -> Bool {
  for camera in cameras {
    if camera.payload.motion_vector_prepass_enabled {
      return true
    }
  }
  false
}
