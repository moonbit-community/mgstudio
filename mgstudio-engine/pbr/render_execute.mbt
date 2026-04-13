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

fn render3d_execute_impl(world : @ecs.World) -> Unit {
  let execute_start = @time.host_time_now()
  let execute_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d",
  )
  fn finish_execute() -> Unit {
    @pbr_render.render3d_set_diagnostic_execute_cpu_ms(
      world,
      (@time.host_time_now() - execute_start) * 1000.0F,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d",
      execute_trace_start_us,
    )
  }
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  guard render3d_queue_take_frame(world) is Some(queued_frame) else {
    phase_state_ref.val.prepared_camera_order.clear()
    phase_state_ref.val.last_camera3d_count = 0
    phase_state_ref.val.camera_order_needs_refresh = true
    finish_execute()
    return
  }
  let frame_config = queued_frame.frame_config
  render3d_execute_render_cameras(
    world,
    source_world,
    queued_frame.cameras,
    queued_frame.meshes,
    queued_frame.prepared_camera_queues,
    frame_config.point_light_shadow_map_size,
    frame_config.prepass_enabled,
    frame_config.deferred_lighting_enabled,
    frame_config.default_opaque_renderer_method,
    frame_config.wireframe_config,
    frame_config.delta_seconds,
  )
  render3d_sync_previous_frame_components(
    world,
    source_world,
    queued_frame.cameras,
    queued_frame.prepared_camera_queues,
  )
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  phase_state_ref.val.prepared_camera_order.clear()
  finish_execute()
}

///|
pub fn render3d_extract_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref(
    world,
  )
  @pbr_render.render3d_world_transform_cache_begin_frame(
    world_transform_cache_ref,
  )
  render3d_refresh_prepared_camera_order_if_needed(
    source_world, phase_state_ref,
  )
  render3d_extract_morphs(source_world, phase_state_ref)
  @pbr_render.render3d_extract_skin_bindings(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
  @pbr_render.render3d_set_diagnostic_prepared_camera_count(
    world,
    phase_state_ref.val.prepared_camera_order.length(),
  )
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
}

///|
pub fn render3d_prepare_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref(
    world,
  )
  render3d_prepare_morphs(source_world, phase_state_ref)
  @pbr_render.render3d_prepare_skin_bindings_upload(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
}

///|
pub fn render3d_prepare_resources_flush_system(world : @ecs.World) -> Unit {
  render3d_queue_clear_frame(world)
}

///|
pub fn render3d_prepare_meshes_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  if phase_state_ref.val.prepared_camera_order.length() == 0 {
    render3d_queue_clear_frame(world)
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
    return
  }
  let world_transform_cache_ref = @pbr_render.render3d_world_transform_cache_ref(
    world,
  )
  let frame_config = render3d_execute_frame_config(source_world)
  let cameras = render3d_execute_collect_cameras(
    source_world,
    world_transform_cache_ref,
    frame_config.gpu_instance_buffer_builder_requested,
    frame_config.gpu_culling_supported,
    frame_config.prepass_enabled,
  )
  let needs_mesh_previous_transform = render3d_set_mesh_motion_vector_flags(
    cameras,
  )
  if cameras.length() == 0 {
    phase_state_ref.val.prepared_camera_order.clear()
    phase_state_ref.val.last_camera3d_count = 0
    phase_state_ref.val.camera_order_needs_refresh = true
    render3d_queue_clear_frame(world)
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
    return
  }
  let meshes = render3d_execute_collect_meshes(
    world, source_world, phase_state_ref, world_transform_cache_ref, needs_mesh_previous_transform,
  )
  render3d_extract_material_instances(world, meshes)
  let prepared_camera_queues = render3d_prepare_camera_queue_entries(
    phase_state_ref,
    cameras,
    meshes,
    frame_config.gpu_instance_buffer_builder_enabled,
    frame_config.gpu_culling_supported,
  )
  render3d_queue_store_frame(world, frame_config, cameras, meshes)
  render3d_queue_update_prepared_camera_queues(world, prepared_camera_queues)
  @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(
    world,
    meshes.length(),
  )
}

///|
pub fn render3d_prepare_bind_groups_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  @pbr_prepass.prepass_update_pipeline_state(source_world)
  ignore(@pbr_render.render3d_mesh_layouts())
  match render3d_queue_take_frame(world) {
    Some(frame) => {
      let view_entities : Array[@core.Entity] = []
      for camera in frame.cameras {
        view_entities.push(camera.entity.main_entity)
      }
      let fog_meta_ref = @pbr_render.render3d_fog_meta_ref_or_init(world)
      let fog_offsets = render3d_prepare_camera_fog_uniforms(
        source_world,
        view_entities,
        fog_meta_ref.val,
      )
      @pbr_render.render3d_apply_view_fog_uniform_offsets(world, fog_offsets)
      let camera_count = if frame.cameras.length() <
        frame.prepared_camera_queues.length() {
        frame.cameras.length()
      } else {
        frame.prepared_camera_queues.length()
      }
      for camera_index in 0..<camera_count {
        let extracted_camera = frame.cameras[camera_index]
        match frame.prepared_camera_queues[camera_index] {
          Some(prepared_queue) =>
            render3d_upload_camera_queue_entry(
              extracted_camera.entity.main_entity,
              extracted_camera.payload,
              Render3dExecuteCameraQueueBuildResult::{
                draw_queue_entry: prepared_queue.draw_queue_entry,
                opaque_alpha_draw_item_indices: prepared_queue.opaque_alpha_draw_item_indices,
                indexed_indirect_parameter_indices: prepared_queue.indexed_indirect_parameter_indices,
                non_indexed_indirect_parameter_indices: prepared_queue.non_indexed_indirect_parameter_indices,
              },
              prepared_queue.camera_pass_projection,
              prepared_queue.viewport_state,
              prepared_queue.camera_exposure_value,
            )
          None => ()
        }
      }
      render3d_queue_store_frame(
        world,
        frame.frame_config,
        frame.cameras,
        frame.meshes,
      )
      render3d_queue_update_prepared_camera_queues(
        world,
        frame.prepared_camera_queues,
      )
    }
    None => ()
  }
}

///|
pub fn render3d_queue_system(world : @ecs.World) -> Unit {
  let queue_start = @time.host_time_now()
  let queue_trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_3d",
  )
  fn finish_queue() -> Unit {
    @pbr_render.render3d_set_diagnostic_queue_cpu_ms(
      world,
      (@time.host_time_now() - queue_start) * 1000.0F,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "queue_3d",
      queue_trace_start_us,
    )
  }
  if !render3d_queue_has_frame(world) {
    @pbr_render.render3d_set_diagnostic_queued_visible_mesh_count(world, 0)
  } else {
    match render3d_queue_take_frame(world) {
      Some(frame) => {
        let camera_count = if frame.cameras.length() <
          frame.prepared_camera_queues.length() {
          frame.cameras.length()
        } else {
          frame.prepared_camera_queues.length()
        }
        for camera_index in 0..<camera_count {
          let extracted_camera = frame.cameras[camera_index]
          match frame.prepared_camera_queues[camera_index] {
            Some(prepared_queue) =>
              render3d_dispatch_camera_queue_entry(
                extracted_camera.entity.main_entity,
                extracted_camera.payload,
                Render3dExecuteCameraQueueBuildResult::{
                  draw_queue_entry: prepared_queue.draw_queue_entry,
                  opaque_alpha_draw_item_indices: prepared_queue.opaque_alpha_draw_item_indices,
                  indexed_indirect_parameter_indices: prepared_queue.indexed_indirect_parameter_indices,
                  non_indexed_indirect_parameter_indices: prepared_queue.non_indexed_indirect_parameter_indices,
                },
              )
            None => ()
          }
        }
        render3d_queue_store_frame(
          world,
          frame.frame_config,
          frame.cameras,
          frame.meshes,
        )
        render3d_queue_update_prepared_camera_queues(
          world,
          frame.prepared_camera_queues,
        )
      }
      None => ()
    }
  }
  finish_queue()
}

///|
pub fn render3d_execute_system(world : @ecs.World) -> Unit {
  render3d_execute_impl(world)
}
