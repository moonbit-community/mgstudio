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
// Bevy source: `bevy/crates/bevy_gizmos/src/transform_gizmo.rs`.
//
// Implementation fragment of the same Bevy source owner as
// `mgstudio-engine/gizmos/transform_gizmo.mbt`. The data model, constants and
// pure helpers live in the parent `gizmos` package because `gizmos_render`
// needs them; the hover and drag systems live here because they need camera
// viewport projection, which reaches `pbr` and would otherwise close the
// `light -> gizmos -> camera -> pbr -> ... -> light` package cycle.

///|
const RING_SAMPLES : Int = 64

///|
const TAU : Float = 6.2831855

///|
const FLOAT_MAX : Float = 3.4028235e38

///|
fn camera_target_size(
  camera : @camera_camera.Camera,
  window_width : Int,
  window_height : Int,
) -> @math.IVec2 {
  match camera.physical_target_size() {
    Some(size) =>
      if size.x > 0 && size.y > 0 {
        size
      } else {
        @math.IVec2::new(window_width, window_height)
      }
    None => @math.IVec2::new(window_width, window_height)
  }
}

///|
fn camera_global_transform(
  world : @ecs.World,
  entity : @core.Entity,
) -> @transform.Transform {
  match (try! world.get_by_key(entity, @transform.ecs_key_global_transform)) {
    Some(global) => global.to_transform_approx()
    None =>
      match (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
        Some(value) => value
        None => @transform.Transform::identity()
      }
  }
}

///|
/// A resolved gizmo camera: entity, camera, projection and world transform.
pub(all) struct GizmoCamera {
  entity : @core.Entity
  camera : @camera_camera.Camera
  projection : @camera.Projection
  transform : @transform.Transform
}

///|
fn collect_cameras(
  world : @ecs.World,
  marked_only : Bool,
) -> Array[GizmoCamera] {
  let cameras : Array[GizmoCamera] = []
  world.for_each_component(@camera.ecs_key_camera3d, fn(entity, _camera3d) {
    if marked_only &&
      (try! world.get_by_key(entity, @gizmos.ecs_key_transform_gizmo_camera))
      is None {
      return
    }
    guard (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
      is Some(camera) else {
      return
    }
    if !camera.is_active {
      return
    }
    let projection = match
      (try! world.get_by_key(entity, @camera.ecs_key_projection)) {
      Some(value) => value
      None => @camera.Projection::default()
    }
    cameras.push({
      entity,
      camera,
      projection,
      transform: camera_global_transform(world, entity),
    })
  })
  cameras
}

///|
/// Resolve which camera the gizmo should use.
///
/// Prefers cameras marked with `TransformGizmoCamera`. Falls back to the sole
/// camera in the world when no marker is present, and gives up when ambiguous.
pub fn resolve_gizmo_camera(world : @ecs.World) -> GizmoCamera? {
  let marked = collect_cameras(world, true)
  if marked.length() > 0 {
    if marked.length() > 1 {
      @log.warn_once(
        "mgstudio.gizmos.transform_gizmo.multiple_marked_cameras", "Multiple cameras have the TransformGizmoCamera component; using the first one found.",
      )
    }
    return Some(marked[0])
  }
  let all = collect_cameras(world, false)
  match all.length() {
    1 => Some(all[0])
    0 => None
    _ => {
      @log.warn_once(
        "mgstudio.gizmos.transform_gizmo.ambiguous_camera", "Multiple cameras exist but none has the TransformGizmoCamera component. Add TransformGizmoCamera to the camera the gizmo should use.",
      )
      None
    }
  }
}

///|
fn transform_forward(transform : @transform.Transform) -> @math.Vec3 {
  transform.rotation.mul_vec3(@math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize()
}

///|
fn transform_right(transform : @transform.Transform) -> @math.Vec3 {
  transform.rotation.mul_vec3(@math.Vec3::new(1.0F, 0.0F, 0.0F)).normalize()
}

///|
fn world_to_viewport(
  gizmo_camera : GizmoCamera,
  target_size : @math.IVec2,
  scale_factor : Float,
  world_position : @math.Vec3,
) -> @math.Vec2? {
  @camera.camera_world_to_viewport(
    world_position,
    gizmo_camera.camera,
    gizmo_camera.projection,
    gizmo_camera.transform,
    target_size,
    scale_factor,
  )
}

///|
/// Minimum screen-space distance from a cursor position to a 3D ring projected
/// onto the screen.
pub fn point_to_ring_screen_dist(
  cursor : @math.Vec2,
  gizmo_camera : GizmoCamera,
  target_size : @math.IVec2,
  scale_factor : Float,
  center : @math.Vec3,
  normal : @math.Vec3,
  radius : Float,
) -> Float {
  // Quick reject: if the cursor is far from the ring center in screen space,
  // skip sampling.
  if world_to_viewport(gizmo_camera, target_size, scale_factor, center)
    is Some(center_screen) {
    let edge_world = center.add(
      transform_right(gizmo_camera.transform).mul_scalar(radius),
    )
    if world_to_viewport(gizmo_camera, target_size, scale_factor, edge_world)
      is Some(edge_screen) {
      let screen_radius = edge_screen.sub(center_screen).length()
      let cursor_dist = cursor.sub(center_screen).length()
      if (cursor_dist - screen_radius).abs() > screen_radius * 0.5F {
        return FLOAT_MAX
      }
    }
  }
  let rotation = @math.Quat::from_rotation_arc(
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    normal,
  )
  let mut min_dist = FLOAT_MAX
  let mut prev_screen : @math.Vec2? = None
  for i in 0..<=RING_SAMPLES {
    let angle = Float::from_int(i % RING_SAMPLES) *
      TAU /
      Float::from_int(RING_SAMPLES)
    let local_point = @math.Vec3::new(
      @math.cos(angle) * radius,
      @math.sin(angle) * radius,
      0.0F,
    )
    let world = center.add(rotation.mul_vec3(local_point))
    match world_to_viewport(gizmo_camera, target_size, scale_factor, world) {
      None => prev_screen = None
      Some(screen) => {
        if prev_screen is Some(prev) {
          let dist = @gizmos.point_to_segment_dist(cursor, prev, screen)
          if dist < min_dist {
            min_dist = dist
          }
        }
        prev_screen = Some(screen)
      }
    }
  }
  min_dist
}

///|
/// Bevy holds this in a `Local<CursorGrabMode>` on `transform_gizmo_drag`.
let saved_grab_mode : Ref[@window.CursorGrabMode] = Ref(GrabNone)

///|
fn current_grab_mode(world : @ecs.World) -> @window.CursorGrabMode {
  let mut mode : @window.CursorGrabMode = GrabNone
  world.for_each_component(@window.ecs_key_primary_window, fn(entity, _marker) {
    if (try! world.get_by_key(entity, @window.ecs_key_cursor_options))
      is Some(options) {
      mode = options.grab_mode
    }
  })
  mode
}

///|
fn primary_cursor_position(world : @ecs.World) -> @math.Vec2? {
  let mut found : @math.Vec2? = None
  world.for_each_component(@window.ecs_key_primary_window, fn(entity, _marker) {
    if found is Some(_) {
      return
    }
    if (try! world.get_by_key(entity, @window.ecs_key_window))
      is Some(window_value) {
      found = window_value.cursor_position()
    }
  })
  found
}

///|
fn focused_entity(world : @ecs.World) -> (@core.Entity, @transform.Transform)? {
  let mut found : (@core.Entity, @transform.Transform)? = None
  world.for_each_component(@gizmos.ecs_key_transform_gizmo_focus, fn(
    entity,
    _marker,
  ) {
    if found is Some(_) {
      return
    }
    found = Some((entity, camera_global_transform(world, entity)))
  })
  found
}

///|
fn gizmo_settings(world : @ecs.World) -> @gizmos.TransformGizmoSettings {
  match world.get_resource(@gizmos.ecs_res_key_transform_gizmo_settings) {
    Some(value) => value
    None => @gizmos.TransformGizmoSettings::TransformGizmoSettings()
  }
}

///|
fn gizmo_state(world : @ecs.World) -> @gizmos.TransformGizmoState {
  match world.get_resource(@gizmos.ecs_res_key_transform_gizmo_state) {
    Some(value) => value
    None => @gizmos.TransformGizmoState::TransformGizmoState()
  }
}

///|
fn set_gizmo_state(
  world : @ecs.World,
  state : @gizmos.TransformGizmoState,
) -> Unit {
  world.insert_resource(@gizmos.ecs_res_key_transform_gizmo_state, state)
}

///|
/// Screen-space scale factor applied to the gizmo so it keeps a constant size.
fn gizmo_screen_scale(
  settings : @gizmos.TransformGizmoSettings,
  camera_translation : @math.Vec3,
  gizmo_position : @math.Vec3,
) -> Float {
  if settings.screen_scale_factor > 0.0F {
    camera_translation.sub(gizmo_position).length() *
    settings.screen_scale_factor
  } else {
    1.0F
  }
}

///|
/// Update `TransformGizmoState::hovered_axis` from the cursor position.
pub fn transform_gizmo_hover(world : @ecs.World) -> Unit {
  let state = gizmo_state(world)
  let cleared = { ..state, hovered_axis: None }
  set_gizmo_state(world, cleared)
  if state.active {
    return
  }
  guard focused_entity(world) is Some((_, focus_transform)) else { return }
  guard resolve_gizmo_camera(world) is Some(gizmo_camera) else { return }
  guard primary_cursor_position(world) is Some(cursor) else { return }
  let settings = gizmo_settings(world)
  let target_size = camera_target_size(
    gizmo_camera.camera,
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()
  let gizmo_pos = focus_transform.translation
  let space = @gizmos.effective_space(settings)
  let rotation = @gizmos.gizmo_rotation(focus_transform.rotation, space)
  let scale = gizmo_screen_scale(
    settings,
    gizmo_camera.transform.translation,
    gizmo_pos,
  )
  let cam_forward = transform_forward(gizmo_camera.transform)
  let axes : Array[(@gizmos.TransformGizmoAxis, @math.Vec3)] = [
    (X, @gizmos.axis_direction(X, rotation, cam_forward)),
    (Y, @gizmos.axis_direction(Y, rotation, cam_forward)),
    (Z, @gizmos.axis_direction(Z, rotation, cam_forward)),
  ]
  let mut best_axis : @gizmos.TransformGizmoAxis? = None
  let mut best_dist = FLOAT_MAX
  let threshold = settings.axis_hit_distance
  for entry in axes {
    let axis = entry.0
    let dir = entry.1
    let dist = match settings.mode {
      Translate | Scale => {
        let start = gizmo_pos.add(
          dir.mul_scalar(@gizmos.AXIS_START_OFFSET * scale),
        )
        let endpoint = gizmo_pos.add(
          dir.mul_scalar(settings.axis_length * scale),
        )
        guard world_to_viewport(gizmo_camera, target_size, scale_factor, start)
          is Some(start_screen) else {
          continue
        }
        guard world_to_viewport(
            gizmo_camera, target_size, scale_factor, endpoint,
          )
          is Some(end_screen) else {
          continue
        }
        @gizmos.point_to_segment_dist(cursor, start_screen, end_screen)
      }
      Rotate =>
        point_to_ring_screen_dist(
          cursor,
          gizmo_camera,
          target_size,
          scale_factor,
          gizmo_pos,
          dir,
          settings.rotate_ring_radius * scale,
        )
    }
    if dist < threshold && dist < best_dist {
      best_dist = dist
      best_axis = Some(axis)
    }
  }

  // View handle hover detection.
  let view_dist = match settings.mode {
    Translate =>
      // Check whether the cursor lies on the view-circle ring in screen space.
      match
        world_to_viewport(gizmo_camera, target_size, scale_factor, gizmo_pos) {
        None => FLOAT_MAX
        Some(center_screen) => {
          let screen_radius = @gizmos.VIEW_CIRCLE_MAJOR * scale
          let edge_world = gizmo_pos.add(
            transform_right(gizmo_camera.transform).mul_scalar(screen_radius),
          )
          match
            world_to_viewport(
              gizmo_camera, target_size, scale_factor, edge_world,
            ) {
            None => FLOAT_MAX
            Some(edge_screen) => {
              let r = edge_screen.sub(center_screen).length()
              let d = cursor.sub(center_screen).length()
              (d - r).abs()
            }
          }
        }
      }
    Rotate =>
      point_to_ring_screen_dist(
        cursor,
        gizmo_camera,
        target_size,
        scale_factor,
        gizmo_pos,
        cam_forward,
        @gizmos.VIEW_RING_MAJOR * scale,
      )
    // No view handle for scale.
    Scale => FLOAT_MAX
  }
  if view_dist < threshold && view_dist < best_dist {
    best_axis = Some(View)
  }
  set_gizmo_state(world, { ..cleared, hovered_axis: best_axis })
}

///|
fn drag_start_point(
  mode : @gizmos.TransformGizmoMode,
  axis : @gizmos.TransformGizmoAxis,
  axis_dir : @math.Vec3,
  cam_forward : @math.Vec3,
  ray_origin : @math.Vec3,
  ray_direction : @math.Vec3,
  gizmo_pos : @math.Vec3,
) -> @math.Vec3? {
  match mode {
    Translate =>
      if axis is View {
        // View-plane translate: use camera forward as the plane normal.
        @gizmos.intersect_plane(
          ray_origin, ray_direction, cam_forward, gizmo_pos,
        )
      } else {
        let plane_normal = @gizmos.translation_plane_normal(
          ray_direction, axis_dir,
        )
        guard @gizmos.intersect_plane(
            ray_origin, ray_direction, plane_normal, gizmo_pos,
          )
          is Some(intersection) else {
          return None
        }
        let cursor_vec = intersection.sub(gizmo_pos)
        let axis_norm = axis_dir.normalize()
        Some(axis_norm.mul_scalar(cursor_vec.dot(axis_norm)).add(gizmo_pos))
      }
    Scale => {
      let plane_normal = @gizmos.translation_plane_normal(
        ray_direction, axis_dir,
      )
      guard @gizmos.intersect_plane(
          ray_origin, ray_direction, plane_normal, gizmo_pos,
        )
        is Some(intersection) else {
        return None
      }
      let cursor_vec = intersection.sub(gizmo_pos)
      let axis_norm = axis_dir.normalize()
      Some(axis_norm.mul_scalar(cursor_vec.dot(axis_norm)).add(gizmo_pos))
    }
    Rotate => {
      let rot_axis = if axis is View {
        cam_forward
      } else {
        axis_dir.normalize()
      }
      guard @gizmos.intersect_plane(
          ray_origin, ray_direction, rot_axis, gizmo_pos,
        )
        is Some(intersection) else {
        return None
      }
      Some(intersection.sub(gizmo_pos).normalize())
    }
  }
}

///|
/// Drive the transform gizmo drag: start, continue and end.
pub fn transform_gizmo_drag(world : @ecs.World) -> Unit {
  guard resolve_gizmo_camera(world) is Some(gizmo_camera) else { return }
  guard primary_cursor_position(world) is Some(cursor) else { return }
  let settings = gizmo_settings(world)
  let state = gizmo_state(world)
  let target_size = camera_target_size(
    gizmo_camera.camera,
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()
  let cam_forward = transform_forward(gizmo_camera.transform)
  guard @camera.camera_viewport_to_world_ray(
      cursor,
      gizmo_camera.camera,
      gizmo_camera.projection,
      gizmo_camera.transform,
      target_size,
      scale_factor,
    )
    is Some((ray_origin, ray_direction)) else {
    return
  }

  // Start drag.
  if @input.mouse_button_just_pressed(Left) && !state.active {
    guard state.hovered_axis is Some(axis) else { return }
    guard focused_entity(world) is Some((entity, global_transform)) else {
      return
    }
    guard (try! world.get_by_key(entity, @transform.ecs_key_transform))
      is Some(local_transform) else {
      return
    }
    let space = @gizmos.effective_space(settings)
    let rotation = @gizmos.gizmo_rotation(global_transform.rotation, space)
    let axis_dir = @gizmos.axis_direction(axis, rotation, cam_forward)
    let gizmo_pos = global_transform.translation
    guard drag_start_point(
        settings.mode,
        axis,
        axis_dir,
        cam_forward,
        ray_origin,
        ray_direction,
        gizmo_pos,
      )
      is Some(drag_start_world) else {
      return
    }
    set_gizmo_state(world, {
      ..state,
      active: true,
      axis: Some(axis),
      start_transform: local_transform,
      entity: Some(entity),
      drag_start_world,
      gizmo_origin: gizmo_pos,
    })
    if settings.confine_cursor {
      saved_grab_mode.val = current_grab_mode(world)
      @window.window_set_cursor_grab_mode(mode=GrabConfined)
    }
    return
  }

  // Continue drag.
  if state.active && @input.mouse_button_pressed(Left) {
    guard state.entity is Some(drag_entity) else { return }
    guard state.axis is Some(axis) else { return }
    guard (try! world.get_by_key(drag_entity, @transform.ecs_key_transform))
      is Some(current) else {
      return
    }
    let global_transform = camera_global_transform(world, drag_entity)
    let space = @gizmos.effective_space(settings)
    let rotation = @gizmos.gizmo_rotation(global_transform.rotation, space)
    let axis_dir = @gizmos.axis_direction(axis, rotation, cam_forward)
    let gizmo_origin = state.gizmo_origin
    let updated = match settings.mode {
      Translate => {
        let plane_normal = if axis is View {
          cam_forward
        } else {
          @gizmos.translation_plane_normal(ray_direction, axis_dir)
        }
        guard @gizmos.intersect_plane(
            ray_origin, ray_direction, plane_normal, gizmo_origin,
          )
          is Some(intersection) else {
          return
        }
        let new_pos = if axis is View {
          let delta = intersection.sub(state.drag_start_world)
          state.start_transform.translation.add(delta)
        } else {
          let cursor_vec = intersection.sub(gizmo_origin)
          let axis_norm = axis_dir.normalize()
          let new_projected = axis_norm
            .mul_scalar(cursor_vec.dot(axis_norm))
            .add(gizmo_origin)
          let delta = new_projected.sub(state.drag_start_world)
          state.start_transform.translation.add(delta)
        }
        let translation = match settings.snap_translate {
          Some(increment) =>
            if axis is View {
              @math.Vec3::new(
                snap_value(new_pos.x, increment),
                snap_value(new_pos.y, increment),
                snap_value(new_pos.z, increment),
              )
            } else {
              @gizmos.snap_axis(
                new_pos,
                state.start_transform.translation,
                axis,
                increment,
              )
            }
          None => new_pos
        }
        current.with_translation(translation)
      }
      Rotate => {
        let rot_axis = if axis is View {
          cam_forward
        } else {
          axis_dir.normalize()
        }
        guard @gizmos.intersect_plane(
            ray_origin, ray_direction, rot_axis, gizmo_origin,
          )
          is Some(intersection) else {
          return
        }
        let cursor_vector = intersection.sub(gizmo_origin).normalize()
        let drag_start = state.drag_start_world
        let dot = drag_start.dot(cursor_vector)
        let det = rot_axis.dot(drag_start.cross(cursor_vector))
        let raw_angle = @math.atan2(det, dot)
        let angle = match settings.snap_rotate {
          Some(increment) => snap_value(raw_angle, increment)
          None => raw_angle
        }
        let rotation_delta = @math.Quat::from_axis_angle(rot_axis, angle)
        current.with_rotation(
          rotation_delta.mul(state.start_transform.rotation),
        )
      }
      Scale => {
        let plane_normal = @gizmos.translation_plane_normal(
          ray_direction, axis_dir,
        )
        guard @gizmos.intersect_plane(
            ray_origin, ray_direction, plane_normal, gizmo_origin,
          )
          is Some(intersection) else {
          return
        }
        let axis_norm = axis_dir.normalize()
        let cursor_projected = intersection.sub(gizmo_origin).dot(axis_norm)
        let start_projected = state.drag_start_world
          .sub(gizmo_origin)
          .dot(axis_norm)
        let scale_factor_axis = if start_projected.abs() > FLOAT_EPSILON {
          cursor_projected / start_projected
        } else {
          1.0F
        }
        let start_scale = state.start_transform.scale
        let scaled = match axis {
          X =>
            @math.Vec3::new(
              max_float(start_scale.x * scale_factor_axis, @gizmos.MIN_SCALE),
              start_scale.y,
              start_scale.z,
            )
          Y =>
            @math.Vec3::new(
              start_scale.x,
              max_float(start_scale.y * scale_factor_axis, @gizmos.MIN_SCALE),
              start_scale.z,
            )
          Z =>
            @math.Vec3::new(
              start_scale.x,
              start_scale.y,
              max_float(start_scale.z * scale_factor_axis, @gizmos.MIN_SCALE),
            )
          // Uniform scale on the view axis.
          View =>
            @math.Vec3::new(
              max_float(start_scale.x * scale_factor_axis, @gizmos.MIN_SCALE),
              max_float(start_scale.y * scale_factor_axis, @gizmos.MIN_SCALE),
              max_float(start_scale.z * scale_factor_axis, @gizmos.MIN_SCALE),
            )
        }
        let final_scale = match settings.snap_scale {
          Some(increment) =>
            match axis {
              X =>
                @math.Vec3::new(
                  snap_value(scaled.x, increment),
                  start_scale.y,
                  start_scale.z,
                )
              Y =>
                @math.Vec3::new(
                  start_scale.x,
                  snap_value(scaled.y, increment),
                  start_scale.z,
                )
              Z =>
                @math.Vec3::new(
                  start_scale.x,
                  start_scale.y,
                  snap_value(scaled.z, increment),
                )
              View => {
                let uniform = snap_value(scaled.x, increment)
                @math.Vec3::new(uniform, uniform, uniform)
              }
            }
          None => scaled
        }
        current.with_scale(final_scale)
      }
    }
    try! (world.replace(drag_entity, @transform.ecs_key_transform, updated)
    |> ignore)
    return
  }

  // End drag. Bevy uses `!pressed` rather than `just_released` so the drag also
  // ends on focus loss.
  if state.active && !@input.mouse_button_pressed(Left) {
    set_gizmo_state(world, { ..state, active: false, axis: None, entity: None })
    if settings.confine_cursor {
      @window.window_set_cursor_grab_mode(mode=saved_grab_mode.val)
    }
  }
}

///|
const FLOAT_EPSILON : Float = 1.1920929e-7

///|
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn snap_value(value : Float, increment : Float) -> Float {
  (value / increment).round() * increment
}

///|
/// Opt-in plugin that adds the interactive transform gizmo.
///
/// Registers the interaction resources and the hover/drag systems. Pair it with
/// the render plugin in `gizmos_render` for mesh-based visualization.
pub struct TransformGizmoPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn TransformGizmoPlugin::TransformGizmoPlugin() -> TransformGizmoPlugin {
  TransformGizmoPlugin::{  }
}

///|
pub impl @app.Plugin for TransformGizmoPlugin with fn name(_self) {
  "mgstudio.gizmos.TransformGizmoPlugin"
}

///|
pub impl @app.Plugin for TransformGizmoPlugin with fn build(_self, app) {
  transform_gizmo_plugin(app)
}

///|
/// Bevy runs both systems in `PostUpdate` inside `TransformGizmoSystems`, with
/// drag before transform propagation and hover after it.
pub fn transform_gizmo_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @gizmos.transform_gizmo_init_resources(app)
  .add_post_update_system_config(
    @app.system(transform_gizmo_drag)
    .in_set(@gizmos.transform_gizmo_systems)
    .before(@transform.transform_set_propagate),
  )
  .add_post_update_system_config(
    @app.system(transform_gizmo_hover)
    .in_set(@gizmos.transform_gizmo_systems)
    .after(@transform.transform_set_propagate),
  )
}
