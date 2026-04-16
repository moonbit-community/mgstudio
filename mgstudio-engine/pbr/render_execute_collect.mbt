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
fn render3d_execute_collect_cameras(
  source_world : @ecs.World,
  world_transform_cache_ref : Ref[@pbr_render.Render3dWorldTransformCache],
  gpu_instance_buffer_builder_requested : Bool,
  gpu_culling_supported : Bool,
  prepass_enabled : Bool,
) -> Array[ExtractedCamera3d] {
  let trace_collect_cameras_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_cameras",
  )
  fn entity_key(entity : @core.Entity) -> UInt64 {
    let hi = entity.id.reinterpret_as_uint().to_uint64()
    let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
    (hi << 32) | lo
  }
  let projection_changed_entities : Map[UInt64, Bool] = {}
  let sequence = source_world.get_sequence_context().sequence()
  for
    entity in source_world
    .changed_components(ecs_key_projection, sequence)
    .read() {
    projection_changed_entities.set(entity_key(entity), true)
  }
  let cameras : Array[ExtractedCamera3d] = []
  let projection_updates : Array[
    (@core.Entity, Projection, ProjectionRuntime3d),
  ] = []
  let projection_runtime_removals : Array[@core.Entity] = []
  let has_no_cpu_culling_components = source_world.component_count(
      @visibility.ecs_key_no_cpu_culling,
    ) >
    0
  source_world.for_each_component(ecs_key_camera3d, fn(entity, camera3d) {
    let camera = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_camera)) {
      Some(v) => v
      None => @sprite.Camera::default()
    }
    if !camera.is_active {
      return
    }
    let projection_component = try! source_world.get_by_key(
      entity, ecs_key_projection,
    )
    let projection = match projection_component {
      Some(v) => v
      None => Projection::default()
    }
    let projection_changed = projection_changed_entities.contains(
      entity_key(entity),
    )
    let sub_camera_view = try! source_world.get_by_key(
      entity, ecs_key_sub_camera_view3d,
    )
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
    let custom_post_process3d = try! source_world.get_by_key(
      entity, ecs_key_custom_post_process3d,
    )
    let vignette = try! source_world.get_by_key(entity, ecs_key_vignette)
    let motion_blur = try! source_world.get_by_key(entity, ecs_key_motion_blur)
    let exposure = try! source_world.get_by_key(entity, ecs_key_exposure)
    let color_grading = try! source_world.get_by_key(
      entity, ecs_key_color_grading,
    )
    let skybox = try! source_world.get_by_key(entity, ecs_key_skybox)
    let environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_environment_map_light,
    )
    let generated_environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_generated_environment_map_light,
    )
    let atmosphere_environment_map_light = try! source_world.get_by_key(
      entity, ecs_key_atmosphere_environment_map_light,
    )
    let hdr_enabled = (try! source_world.get_by_key(entity, ecs_key_hdr))
      is Some(_)
    let fxaa = try! source_world.get_by_key(entity, ecs_key_fxaa)
    let temporal_jitter = try! source_world.get_by_key(
      entity, ecs_key_temporal_jitter,
    )
    let depth_prepass_enabled = prepass_enabled &&
      (try! source_world.get_by_key(entity, ecs_key_depth_prepass)) is Some(_)
    let deferred_prepass_enabled = prepass_enabled &&
      (try! source_world.get_by_key(entity, ecs_key_deferred_prepass))
      is Some(_)
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
    let msaa = try! source_world.get_by_key(entity, ecs_key_msaa)
    let target = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_render_target)) {
      Some(v) => v
      None => @sprite.RenderTarget::Screen
    }
    let layers = match
      (try! source_world.get_by_key(entity, @sprite.ecs_key_render_layers)) {
      Some(v) => v
      None => @sprite.RenderLayers::default()
    }
    let has_no_cpu_culling = if has_no_cpu_culling_components {
      (try! source_world.get_by_key(entity, @visibility.ecs_key_no_cpu_culling))
      is Some(_)
    } else {
      false
    }
    let transform = @pbr_render.render3d_entity_world_transform_cached(
      source_world, entity, world_transform_cache_ref,
    )
    let previous_view_data : @pbr_prepass.PreviousViewData? = try! source_world.get_by_key(
      entity, ecs_key_previous_view_data,
    )
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
              try! source_world.get_by_key(entity, ecs_key_projection_runtime3d),
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
        cameras.push(ExtractedCamera3d::{
          entity: phase_entity_ref3d_for_main(entity),
          payload: Camera3dViewPayload::{
            camera3d,
            camera: camera_clamped,
            projection,
            sub_camera_view,
            oit_settings,
            screen_space_transmission,
            bloom,
            tonemapping,
            deband_dither,
            chromatic_aberration,
            custom_post_process3d,
            vignette,
            motion_blur,
            exposure,
            color_grading,
            skybox,
            environment_map_light,
            generated_environment_map_light,
            atmosphere_environment_map_light,
            depth_prepass_enabled,
            deferred_prepass_enabled,
            no_indirect_drawing,
            gpu_occlusion_culling_enabled,
            hdr_enabled,
            fxaa,
            temporal_jitter,
            temporal_anti_aliasing,
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
            has_no_cpu_culling,
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
  for entity in projection_runtime_removals {
    try! (source_world.take(entity, ecs_key_projection_runtime3d) |> ignore)
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_cameras",
    trace_collect_cameras_start_us,
  )
  cameras
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
