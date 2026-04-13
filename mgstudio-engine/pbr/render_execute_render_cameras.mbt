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
  let lighting = @pbr_render.render3d_collect_lighting(source_world)
  let camera_phase_items = match
    render3d_prepared_camera_phase_items(world, cameras) {
    Some(items) => items
    None => render3d_queue_camera_phase_items(cameras)
  }
  let cleared_targets_this_frame : Array[Int] = []
  let next_camera_motion_blur_history : Array[CameraMotionBlurHistoryEntry] = []
  for camera_phase_item in camera_phase_items {
    let extracted_camera = cameras[camera_phase_item.extracted_index]
    let prepared_camera_queue = if camera_phase_item.extracted_index >= 0 &&
      camera_phase_item.extracted_index < prepared_camera_queues.length() {
      prepared_camera_queues[camera_phase_item.extracted_index]
    } else {
      None
    }
    render3d_execute_camera(
      world, extracted_camera, meshes, point_light_shadow_map_size, prepass_enabled,
      deferred_lighting_enabled, default_opaque_renderer_method, wireframe_config,
      lighting, delta_seconds, cleared_targets_this_frame, next_camera_motion_blur_history,
      prepared_camera_queue,
    )
  }
  @app.timeline_trace_end_span(
    @app.TimelineTraceCategory::RenderQueue,
    "execute_3d_render_cameras",
    trace_render_cameras_start_us,
  )
  camera_motion_blur_history_sync(world, next_camera_motion_blur_history)
}

///|
fn render3d_sorted_camera_entities(world : @ecs.World) -> Array[@core.Entity] {
  let entries : Array[Render3dCameraOrderEntry] = []
  world.for_each_component(ecs_key_camera3d, fn(entity, _camera3d) {
    let order = match (try! world.get_by_key(entity, @sprite.ecs_key_camera)) {
      Some(camera) => camera.order
      None => @sprite.Camera::default().order
    }
    entries.push(Render3dCameraOrderEntry::{ entity, order })
  })
  entries.sort_by(fn(a, b) {
    let order_cmp = @pbr_render.cmp_int(a.order, b.order)
    if order_cmp != 0 {
      return order_cmp
    }
    let id_cmp = @pbr_render.cmp_int(a.entity.id, b.entity.id)
    if id_cmp != 0 {
      return id_cmp
    }
    @pbr_render.cmp_int(a.entity.generation, b.entity.generation)
  })
  let sorted : Array[@core.Entity] = []
  for entry in entries {
    sorted.push(entry.entity)
  }
  sorted
}

///|
fn render3d_camera_order_has_changes(world : @ecs.World) -> Bool {
  let changed_camera_query : @ecs.Query[
    @ecs.Comp[@sprite.Camera],
    @ecs.Changed[@sprite.Camera],
  ] = @ecs.query_filtered(world, @ecs.Changed::new(@sprite.ecs_key_camera))
  let mut changed = false
  try! changed_camera_query.view(fn(_entity, _camera) { changed = true })
  if changed {
    return true
  }
  let changed_camera3d_query : @ecs.Query[
    @ecs.Comp[Camera3d],
    @ecs.Changed[Camera3d],
  ] = @ecs.query_filtered(world, @ecs.Changed::new(ecs_key_camera3d))
  try! changed_camera3d_query.view(fn(_entity, _camera3d) { changed = true })
  changed
}

///|
fn render3d_refresh_prepared_camera_order_if_needed(
  source_world : @ecs.World,
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
) -> Unit {
  let camera3d_count = source_world.component_count(ecs_key_camera3d)
  let must_refresh = phase_state_ref.val.camera_order_needs_refresh ||
    phase_state_ref.val.prepared_camera_order.length() != camera3d_count ||
    phase_state_ref.val.last_camera3d_count != camera3d_count ||
    render3d_camera_order_has_changes(source_world)
  if !must_refresh {
    return
  }
  phase_state_ref.val.prepared_camera_order = render3d_sorted_camera_entities(
    source_world,
  )
  phase_state_ref.val.last_camera3d_count = camera3d_count
  phase_state_ref.val.camera_order_needs_refresh = false
}

///|
fn render3d_prepared_camera_phase_items(
  world : @ecs.World,
  cameras : Array[ExtractedCamera3d],
) -> Array[CameraPhaseItem3d]? {
  let prepared = @pbr_render.render3d_phase_state_or_default(world).prepared_camera_order
  if prepared.length() != cameras.length() {
    return None
  }
  let items : Array[CameraPhaseItem3d] = []
  for entity in prepared {
    let mut found_index = -1
    for i in 0..<cameras.length() {
      let camera = cameras[i]
      if camera.entity.main_entity.id == entity.id &&
        camera.entity.main_entity.generation == entity.generation {
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
