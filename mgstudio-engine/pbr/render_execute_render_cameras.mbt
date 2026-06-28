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
fn render3d_execute_render_cameras(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?],
  camera_execution_plans : Array[Render3dCameraExecutionPlan?],
  wireframe_config : WireframeConfig?,
  delta_seconds : Float,
) -> Unit {
  let trace_render_cameras_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
  )
  let trace_camera_phase_items_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_phase_items",
  )
  let camera_phase_items = match
    render3d_prepared_camera_phase_items(world, cameras) {
    Some(items) => items
    None => render3d_queue_camera_phase_items(cameras)
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_camera_phase_items",
    trace_camera_phase_items_start_us,
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_camera_count",
    cameras.length(),
  )
  @app.timeline_trace_emit_counter_int(
    "render_3d_camera_phase_items",
    camera_phase_items.length(),
  )
  render3d_reset_volumetric_fog_uniform_buffer(world)
  let cleared_targets_this_frame : Array[Int] = []
  let ordered_cameras : Array[ExtractedCamera3d] = []
  let ordered_prepared_camera_queues : Array[Render3dPreparedCameraQueue] = []
  let ordered_camera_execution_plans : Array[Render3dCameraExecutionPlan] = []
  for camera_phase_item in camera_phase_items {
    guard camera_phase_item.extracted_index >= 0 &&
      camera_phase_item.extracted_index < cameras.length() &&
      camera_phase_item.extracted_index < prepared_camera_queues.length() &&
      camera_phase_item.extracted_index < camera_execution_plans.length() else {
      continue
    }
    let extracted_camera = cameras[camera_phase_item.extracted_index]
    guard prepared_camera_queues[camera_phase_item.extracted_index]
      is Some(prepared_camera_queue) else {
      continue
    }
    guard camera_execution_plans[camera_phase_item.extracted_index]
      is Some(execution_plan) else {
      continue
    }
    ordered_cameras.push(extracted_camera)
    ordered_prepared_camera_queues.push(prepared_camera_queue)
    ordered_camera_execution_plans.push(execution_plan)
  }
  for i in 0..<ordered_cameras.length() {
    let extracted_camera = ordered_cameras[i]
    let prepared_camera_queue = ordered_prepared_camera_queues[i]
    let execution_plan = ordered_camera_execution_plans[i]
    let trace_camera_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera",
    )
    render3d_execute_camera(
      world, extracted_camera, meshes, wireframe_config, delta_seconds, cleared_targets_this_frame,
      prepared_camera_queue, execution_plan,
    )
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera",
      trace_camera_start_us,
    )
  }
  @sprite.gizmos_clear_3d()
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
    trace_render_cameras_start_us,
  )
}

///|
fn render3d_prepare_camera_execution_plans_for_queued_frame(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?],
  frame_config : Render3dExecuteFrameConfig,
) -> (Array[Render3dCameraExecutionPlan?], Array[Render3dQueuedShadowPhaseView]) {
  let trace_collect_lighting_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_3d_collect_lighting",
  )
  let lighting = render3d_lighting_with_clusterable_indices(
    world,
    @pbr_render.render3d_collect_lighting(world),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "queue_3d_collect_lighting",
    trace_collect_lighting_start_us,
  )
  let camera_execution_plans : Array[Render3dCameraExecutionPlan?] = []
  let queued_shadow_phase_views : Array[Render3dQueuedShadowPhaseView] = []
  for index in 0..<cameras.length() {
    if index >= prepared_camera_queues.length() {
      camera_execution_plans.push(None)
      continue
    }
    guard prepared_camera_queues[index] is Some(_) else {
      camera_execution_plans.push(None)
      continue
    }
    let execution_plan = render3d_prepare_camera_execution_plan(
      world,
      cameras[index],
      meshes,
      frame_config.point_light_shadow_map_size,
      frame_config.prepass_enabled,
      frame_config.deferred_lighting_enabled,
      frame_config.default_opaque_renderer_method,
      lighting,
    )
    for queued_phase_view in execution_plan.shadow_pass_plan.queued_phase_views {
      queued_shadow_phase_views.push(queued_phase_view)
    }
    camera_execution_plans.push(Some(execution_plan))
  }
  (camera_execution_plans, queued_shadow_phase_views)
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::prepare_lights`.
pub fn render3d_prepare_shadow_phase_views_system(world : @ecs.World) -> Unit {
  let trace_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_shadow_phase_views",
  )
  let lighting = render3d_lighting_with_clusterable_indices(
    world,
    @pbr_render.render3d_collect_lighting(world),
  )
  let (cameras, point_light_shadow_map_size) = match
    render3d_pending_frame_snapshot(world) {
    Some(frame) =>
      (frame.cameras, frame.frame_config.point_light_shadow_map_size)
    None => ([], 0)
  }
  ignore(
    render3d_prepare_shadow_phase_views_for_cameras(
      world, cameras, lighting, point_light_shadow_map_size,
    ),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "prepare_3d_shadow_phase_views",
    trace_start_us,
  )
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::prepare_lights`.
fn render3d_shadow_phase_light_entities_for_camera(
  camera_entity : @core.Entity,
  lighting : Render3dLightingState,
  point_light_shadow_map_size : Int,
) -> Array[Render3dLightEntity] {
  let light_entities : Array[Render3dLightEntity] = []
  if lighting.point_shadow_maps_enabled &&
    lighting.point_entity is Some(point_entity) &&
    lighting.point_render_entity is Some(point_render_entity) &&
    lighting.point_range > 0.0F &&
    point_light_shadow_map_size > 0 {
    for face_index in 0..<6 {
      light_entities.push(
        Render3dLightEntity::Point(
          light_entity=point_render_entity,
          main_entity=point_entity,
          face_index~,
        ),
      )
    }
  }
  if lighting.directional_shadow_maps_enabled &&
    lighting.directional_entity is Some(light_entity) &&
    lighting.directional_render_entity is Some(directional_render_entity) {
    let cascades = render3d_directional_shadow_cascades(camera_entity, lighting)
    for cascade_index in 0..<cascades.length() {
      light_entities.push(
        Render3dLightEntity::Directional(
          light_entity=directional_render_entity,
          main_entity=light_entity,
          cascade_index~,
        ),
      )
    }
  }
  if lighting.spot_shadow_maps_enabled &&
    lighting.spot_entity is Some(light_entity) &&
    lighting.spot_render_entity is Some(spot_render_entity) &&
    lighting.spot_range > 0.0F {
    light_entities.push(
      Render3dLightEntity::Spot(
        light_entity=spot_render_entity,
        main_entity=light_entity,
      ),
    )
  }
  light_entities
}

///|
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs::prepare_lights`.
fn render3d_prepare_shadow_phase_views_for_cameras(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  lighting : Render3dLightingState,
  point_light_shadow_map_size : Int,
) -> @hashset.HashSet[@render_view.RetainedViewEntity] {
  let live_shadow_mapping_lights : @hashset.HashSet[
    @render_view.RetainedViewEntity,
  ] = @hashset.HashSet([])
  let gpu_preprocessing_mode = match
    world.get_resource(@render_batching.GpuPreprocessingSupport::resource()) {
    Some(value) => value.min(@render_batching.GpuPreprocessingMode::Culling)
    None => @render_batching.GpuPreprocessingMode::None
  }
  for camera in cameras {
    let extracted_retained_view = @render_view.RetainedViewEntity::new(
      camera.entity.main_entity,
    )
    for
      light_entity in render3d_shadow_phase_light_entities_for_camera(
        camera.entity.main_entity,
        lighting,
        point_light_shadow_map_size,
      ) {
      live_shadow_mapping_lights.add(
        light_entity.shadow_phase_retained_view(extracted_retained_view),
      )
    }
  }
  let shadow_render_phases = match
    world.get_resource_mut(Render3dShadowPhasesData::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing ViewBinnedRenderPhases<Shadow> resource during pbr shadow phase preparation",
      )
  }
  shadow_render_phases.modify(fn(phases) {
    for retained_view_entity in live_shadow_mapping_lights.iter() {
      ignore(
        phases.prepare_for_new_frame(
          retained_view_entity,
          gpu_preprocessing_mode~,
        ),
      )
    }
    phases.retain(live_shadow_mapping_lights)
  })
  let pending_shadow_queues = match
    world.get_resource_mut(@pbr_render.PendingShadowQueues::resource()) {
    Some(value) => value
    None =>
      abort(
        "missing PendingShadowQueues resource during pbr shadow phase preparation",
      )
  }
  pending_shadow_queues.modify(fn(queues) {
    for retained_view_entity in live_shadow_mapping_lights.iter() {
      ignore(queues.queues().prepare_for_new_frame(retained_view_entity))
    }
    queues.queues().expire_stale_views(live_shadow_mapping_lights)
  })
  live_shadow_mapping_lights
}

///|
fn render3d_lighting_with_clusterable_indices(
  world : @ecs.World,
  lighting : Render3dLightingState,
) -> Render3dLightingState {
  let point_light_index = match lighting.point_entity {
    Some(entity) =>
      match world.get_resource(ecs_key_global_clusterable_object_meta) {
        Some(meta) =>
          match meta.entity_index(entity) {
            Some(index) => if index < 0 { 0 } else { index }
            None => lighting.point_light_index
          }
        None => lighting.point_light_index
      }
    None => lighting.point_light_index
  }
  let point_light_count = render3d_clusterable_point_light_count(world)
  let spot_light_index = match lighting.spot_entity {
    Some(entity) =>
      match world.get_resource(ecs_key_global_clusterable_object_meta) {
        Some(meta) =>
          match meta.entity_index(entity) {
            Some(index) =>
              render3d_spot_light_index_from_global_index(
                index, point_light_count,
              )
            None => lighting.spot_light_index
          }
        None => lighting.spot_light_index
      }
    None => lighting.spot_light_index
  }
  Render3dLightingState::{ ..lighting, point_light_index, spot_light_index }
}

///|
fn render3d_spot_light_index_from_global_index(
  global_light_index : Int,
  point_light_count : Int,
) -> Int {
  let spot_index = global_light_index - point_light_count
  if spot_index < 0 {
    0
  } else {
    spot_index
  }
}

///|
fn render3d_clusterable_point_light_count(world : @ecs.World) -> Int {
  let mut point_light_count = 0
  for
    item in @pbr_render.render3d_collect_extracted_clusterable_point_lights(
      world,
    ) {
    if item.is_point_light() {
      point_light_count += 1
    }
  }
  point_light_count
}

///|
fn render3d_normalized_render_target(
  target : @camera_camera.RenderTarget,
) -> @camera_render_target.NormalizedRenderTarget? {
  match target {
    Screen =>
      Some(
        @camera_render_target.NormalizedRenderTarget::Window(
          @window.WindowRef::Primary,
        ),
      )
    Window(window_ref) =>
      Some(@camera_render_target.NormalizedRenderTarget::Window(window_ref))
    Image(handle) =>
      Some(
        @camera_render_target.NormalizedRenderTarget::Image(
          @camera_render_target.ImageRenderTarget::from_handle(handle),
        ),
      )
  }
}

///|
fn render3d_sorted_camera_target_rank(
  target : @camera_render_target.NormalizedRenderTarget?,
) -> Int {
  match target {
    Some(Window(_)) => 0
    Some(Image(_)) => 1
    Some(TextureView(_)) => 2
    Some(None(_, _)) => 3
    None => 4
  }
}

///|
fn render3d_sorted_camera_target_key(
  target : @camera_render_target.NormalizedRenderTarget?,
) -> Int {
  match target {
    Some(Window(@window.WindowRef::Primary)) => -1
    Some(Window(@window.WindowRef::Entity(entity))) => entity.id
    Some(Image(handle)) => handle.handle_id()
    Some(TextureView(handle)) => handle.value()
    Some(None(width, height)) => width * 65536 + height
    None => 0
  }
}

///|
fn render3d_sorted_camera_entries(
  world : @ecs.World,
) -> Array[@render.SortedCamera] {
  let entries : Array[Render3dCameraOrderEntry] = []
  world.for_each_component(ecs_key_camera3d, fn(entity, _camera3d) {
    let camera = match
      (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)) {
      Some(value) => value
      None => @camera_camera.Camera::Camera()
    }
    if !camera.is_active {
      return
    }
    guard (try! world.get_by_key(entity, @render.ecs_key_render_entity))
      is Some(render_entity) else {
      return
    }
    let order = camera.order
    let target = match
      (try! world.get_by_key(entity, @camera_camera.ecs_key_render_target)) {
      Some(value) => value
      None => @camera_camera.RenderTarget::Screen
    }
    entries.push(Render3dCameraOrderEntry::{
      entity: render_entity.id(),
      order,
      target: render3d_normalized_render_target(target),
    })
  })
  entries.sort_by(fn(a, b) {
    let order_cmp = @pbr_render.cmp_int(a.order, b.order)
    if order_cmp != 0 {
      return order_cmp
    }
    let target_rank_cmp = @pbr_render.cmp_int(
      render3d_sorted_camera_target_rank(a.target),
      render3d_sorted_camera_target_rank(b.target),
    )
    if target_rank_cmp != 0 {
      return target_rank_cmp
    }
    let target_key_cmp = @pbr_render.cmp_int(
      render3d_sorted_camera_target_key(a.target),
      render3d_sorted_camera_target_key(b.target),
    )
    if target_key_cmp != 0 {
      return target_key_cmp
    }
    let id_cmp = @pbr_render.cmp_int(a.entity.id, b.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    @pbr_render.cmp_int(a.entity.generation, b.entity.generation)
  })
  let sorted : Array[@render.SortedCamera] = []
  for entry in entries {
    sorted.push(
      @render.SortedCamera::new(
        entry.entity,
        entry.order,
        entry.target,
        false,
        @render.CameraOutputMode::Write,
      ),
    )
  }
  sorted
}

///|
fn render3d_refresh_sorted_cameras(
  source_world : @ecs.World,
  sorted_cameras_ref : @ecs.ResourceMut[@render.SortedCameras],
) -> Unit {
  @render.sorted_cameras_replace(
    sorted_cameras_ref,
    render3d_sorted_camera_entries(source_world),
  )
}

///|
fn render3d_prepared_camera_phase_items(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Array[CameraPhaseItem3d]? {
  let prepared = @render.sorted_cameras_or_default(world).cameras()
  if prepared.length() != cameras.length() {
    return None
  }
  let items : Array[CameraPhaseItem3d] = []
  for sorted_camera in prepared {
    let entity = sorted_camera.entity()
    let mut found_index = -1
    for i in 0..<cameras.length() {
      let camera = cameras[i]
      if camera.entity.render_entity.id == entity.id &&
        camera.entity.render_entity.generation == entity.generation {
        found_index = i
        break
      }
    }
    if found_index < 0 {
      return None
    }
    let camera = cameras[found_index]
    items.push(CameraPhaseItem3d::{
      entity: camera.entity,
      extracted_index: found_index,
      order: camera.payload.camera.order,
    })
  }
  Some(items)
}
