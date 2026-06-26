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
  source_world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
  meshes : Array[ExtractedMesh3d],
  prepared_camera_queues : Array[Render3dPreparedCameraQueue?],
  point_light_shadow_map_size : Int,
  prepass_enabled : Bool,
  deferred_lighting_enabled : Bool,
  default_opaque_renderer_method : OpaqueRendererMethod,
  wireframe_config : WireframeConfig?,
  delta_seconds : Float,
) -> Unit {
  let trace_render_cameras_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
  )
  let trace_collect_lighting_start_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_lighting",
  )
  ignore(source_world)
  let lighting = render3d_lighting_with_clusterable_indices(
    world,
    @pbr_render.render3d_collect_lighting(world),
  )
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_collect_lighting",
    trace_collect_lighting_start_us,
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
  for camera_phase_item in camera_phase_items {
    let extracted_camera = cameras[camera_phase_item.extracted_index]
    let prepared_camera_queue = if camera_phase_item.extracted_index >= 0 &&
      camera_phase_item.extracted_index < prepared_camera_queues.length() {
      prepared_camera_queues[camera_phase_item.extracted_index]
    } else {
      None
    }
    let trace_camera_start_us = @app.timeline_trace_begin_span(
      @app.TimelineTraceCategory::RenderQueue,
      "execute_3d_camera",
    )
    render3d_execute_camera(
      world, extracted_camera, meshes, point_light_shadow_map_size, prepass_enabled,
      deferred_lighting_enabled, default_opaque_renderer_method, wireframe_config,
      lighting, delta_seconds, cleared_targets_this_frame, prepared_camera_queue,
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
