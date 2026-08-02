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
// Interactive transform gizmo for translating, rotating, and scaling entities.
// The plugin does not handle keyboard input; callers set
// `TransformGizmoSettings::mode` however they like.

///|
/// Default length of each axis handle.
pub const AXIS_LENGTH : Float = 1.0

///|
/// Length of the arrow tip on translate handles.
pub const AXIS_TIP_LENGTH : Float = 0.2

///|
/// Gap between the gizmo center and the start of each axis handle.
pub const AXIS_START_OFFSET : Float = 0.2

///|
/// Default radius of the rotation rings.
pub const ROTATE_RING_RADIUS : Float = 1.0

///|
/// Half-size of the scale cube tip.
pub const SCALE_CUBE_SIZE : Float = 0.07

///|
/// Alpha value used for inactive (non-hovered) axes during a drag.
pub const INACTIVE_ALPHA : Float = 0.5

///|
/// Lower bound applied to scale handles during a drag.
///
/// Bevy keeps this private to `transform_gizmo.rs`; it is exposed here only
/// until `transform_gizmo_drag`, its sole consumer, is ported.
pub const MIN_SCALE : Float = 0.01

///|
/// Default screen-space pixel distance threshold for hover detection.
pub const AXIS_HIT_DISTANCE : Float = 35.0

///|
/// Radius of the cylinder mesh used for axis shafts.
pub const SHAFT_RADIUS : Float = 0.015

///|
/// Height of the cylinder mesh used for axis shafts.
pub const SHAFT_LENGTH : Float = 0.6

///|
/// Radius of the cone mesh used for translate arrow tips.
pub const CONE_RADIUS : Float = 0.05

///|
/// Height of the cone mesh used for translate arrow tips.
pub const CONE_HEIGHT : Float = 0.2

///|
/// Minor (tube) radius of the view-plane circle torus.
pub const VIEW_CIRCLE_MINOR : Float = 0.01

///|
/// Major (ring) radius of the view-plane circle torus.
pub const VIEW_CIRCLE_MAJOR : Float = 0.15

///|
/// Minor (tube) radius of the view-axis rotation ring torus.
pub const VIEW_RING_MINOR : Float = 0.01

///|
/// Major (ring) radius of the view-axis rotation ring torus.
pub const VIEW_RING_MAJOR : Float = 1.15

///|
const TRANSFORM_GIZMO_EPSILON : Float = 1.1920929e-7

///|
/// Color for the X axis (magenta-pink).
pub fn transform_gizmo_color_x() -> @color.Color {
  @color.Color::srgb(1.0F, 0.0F, 0.49F)
}

///|
/// Color for the Y axis (green).
pub fn transform_gizmo_color_y() -> @color.Color {
  @color.Color::srgb(0.0F, 1.0F, 0.49F)
}

///|
/// Color for the Z axis (blue).
pub fn transform_gizmo_color_z() -> @color.Color {
  @color.Color::srgb(0.0F, 0.49F, 1.0F)
}

///|
/// Color for the view-plane handle (white).
pub fn transform_gizmo_color_view() -> @color.Color {
  @color.Color::srgb(1.0F, 1.0F, 1.0F)
}

///|
/// Which manipulation mode the gizmo is in.
pub(all) enum TransformGizmoMode {
  Translate
  Rotate
  Scale
}

///|
pub impl Default for TransformGizmoMode with fn default() {
  Translate
}

///|
/// Whether the gizmo transforms the object using world or local space axes.
pub(all) enum TransformGizmoSpace {
  World
  Local
}

///|
pub impl Default for TransformGizmoSpace with fn default() {
  World
}

///|
/// Which axis the user is interacting with.
pub(all) enum TransformGizmoAxis {
  X
  Y
  Z
  View
}

///|
/// Component that marks the entity the transform gizmo operates on.
///
/// Only one entity should carry this at a time. If multiple entities have it,
/// the gizmo picks the first one returned by the query.
pub struct TransformGizmoFocus {}

///|
#warnings("-unnecessary_annotation")
pub fn TransformGizmoFocus::TransformGizmoFocus() -> TransformGizmoFocus {
  TransformGizmoFocus::{  }
}

///|
pub let ecs_key_transform_gizmo_focus : @ecs.ComponentKey[TransformGizmoFocus] = @ecs.register_component(
  debug_name="mgstudio_gizmos::TransformGizmoFocus",
)

///|
pub impl @ecs.Component for TransformGizmoFocus with fn component() {
  ecs_key_transform_gizmo_focus
}

///|
pub impl Default for TransformGizmoFocus with fn default() {
  TransformGizmoFocus::TransformGizmoFocus()
}

///|
/// Marker component for the camera the transform gizmo should use.
///
/// When exactly one camera exists, this marker is optional. When multiple
/// cameras exist, add this to the camera the gizmo should project through.
pub struct TransformGizmoCamera {}

///|
#warnings("-unnecessary_annotation")
pub fn TransformGizmoCamera::TransformGizmoCamera() -> TransformGizmoCamera {
  TransformGizmoCamera::{  }
}

///|
pub let ecs_key_transform_gizmo_camera : @ecs.ComponentKey[TransformGizmoCamera] = @ecs.register_component(
  debug_name="mgstudio_gizmos::TransformGizmoCamera",
)

///|
pub impl @ecs.Component for TransformGizmoCamera with fn component() {
  ecs_key_transform_gizmo_camera
}

///|
pub impl Default for TransformGizmoCamera with fn default() {
  TransformGizmoCamera::TransformGizmoCamera()
}

///|
/// Marker component for the root entity of the gizmo mesh hierarchy.
pub struct TransformGizmoRoot {}

///|
#warnings("-unnecessary_annotation")
pub fn TransformGizmoRoot::TransformGizmoRoot() -> TransformGizmoRoot {
  TransformGizmoRoot::{  }
}

///|
pub let ecs_key_transform_gizmo_root : @ecs.ComponentKey[TransformGizmoRoot] = @ecs.register_component(
  debug_name="mgstudio_gizmos::TransformGizmoRoot",
)

///|
pub impl @ecs.Component for TransformGizmoRoot with fn component() {
  ecs_key_transform_gizmo_root
}

///|
/// Marker component for individual gizmo mesh parts.
pub(all) struct TransformGizmoMeshMarker {
  axis : TransformGizmoAxis
  mode : TransformGizmoMode
}

///|
pub fn TransformGizmoMeshMarker::new(
  axis : TransformGizmoAxis,
  mode : TransformGizmoMode,
) -> TransformGizmoMeshMarker {
  { axis, mode }
}

///|
pub let ecs_key_transform_gizmo_mesh_marker : @ecs.ComponentKey[
  TransformGizmoMeshMarker,
] = @ecs.register_component(
  debug_name="mgstudio_gizmos::TransformGizmoMeshMarker",
)

///|
pub impl @ecs.Component for TransformGizmoMeshMarker with fn component() {
  ecs_key_transform_gizmo_mesh_marker
}

///|
/// Configuration and preferences for the transform gizmo.
pub(all) struct TransformGizmoSettings {
  mode : TransformGizmoMode
  space : TransformGizmoSpace
  axis_length : Float
  rotate_ring_radius : Float
  axis_hit_distance : Float
  snap_translate : Float?
  snap_rotate : Float?
  snap_scale : Float?
  confine_cursor : Bool
  screen_scale_factor : Float
}

///|
#warnings("-unnecessary_annotation")
pub fn TransformGizmoSettings::TransformGizmoSettings() -> TransformGizmoSettings {
  {
    mode: TransformGizmoMode::default(),
    space: TransformGizmoSpace::default(),
    axis_length: AXIS_LENGTH,
    rotate_ring_radius: ROTATE_RING_RADIUS,
    axis_hit_distance: AXIS_HIT_DISTANCE,
    snap_translate: None,
    snap_rotate: None,
    snap_scale: None,
    confine_cursor: true,
    screen_scale_factor: 0.1,
  }
}

///|
pub impl Default for TransformGizmoSettings with fn default() {
  TransformGizmoSettings::TransformGizmoSettings()
}

///|
pub let ecs_res_key_transform_gizmo_settings : @ecs.ResourceKey[
  TransformGizmoSettings,
] = @ecs.register_resource(debug_name="mgstudio_gizmos::TransformGizmoSettings")

///|
pub impl @app.Resource for TransformGizmoSettings with fn resource() {
  ecs_res_key_transform_gizmo_settings
}

///|
/// Runtime state of the transform gizmo (drag and hover).
pub(all) struct TransformGizmoState {
  hovered_axis : TransformGizmoAxis?
  active : Bool
  axis : TransformGizmoAxis?
  start_transform : @transform.Transform
  entity : @core.Entity?
  drag_start_world : @math.Vec3
  gizmo_origin : @math.Vec3
}

///|
#warnings("-unnecessary_annotation")
pub fn TransformGizmoState::TransformGizmoState() -> TransformGizmoState {
  {
    hovered_axis: None,
    active: false,
    axis: None,
    start_transform: @transform.Transform::identity(),
    entity: None,
    drag_start_world: @math.Vec3::zero(),
    gizmo_origin: @math.Vec3::zero(),
  }
}

///|
pub impl Default for TransformGizmoState with fn default() {
  TransformGizmoState::TransformGizmoState()
}

///|
pub let ecs_res_key_transform_gizmo_state : @ecs.ResourceKey[
  TransformGizmoState,
] = @ecs.register_resource(debug_name="mgstudio_gizmos::TransformGizmoState")

///|
pub impl @app.Resource for TransformGizmoState with fn resource() {
  ecs_res_key_transform_gizmo_state
}

///|
/// System set for the transform gizmo. All transform gizmo systems run in
/// `PostUpdate` within this set.
pub let transform_gizmo_systems : @app.SystemSet = @app.system_set(
  "mgstudio.gizmos.transform_gizmo",
)

///|
/// Get the world-space direction for a given axis.
///
/// `cam_forward` is the camera's forward direction, used for the view axis.
pub fn axis_direction(
  axis : TransformGizmoAxis,
  rotation : @math.Quat,
  cam_forward : @math.Vec3,
) -> @math.Vec3 {
  match axis {
    X => rotation.mul_vec3(@math.Vec3::new(1.0F, 0.0F, 0.0F))
    Y => rotation.mul_vec3(@math.Vec3::new(0.0F, 1.0F, 0.0F))
    Z => rotation.mul_vec3(@math.Vec3::new(0.0F, 0.0F, 1.0F))
    View => cam_forward
  }
}

///|
/// Construct the constraint plane normal for axis translation/scale.
///
/// The plane contains the drag axis and is oriented to face the camera as much
/// as possible.
pub fn translation_plane_normal(
  ray_direction : @math.Vec3,
  axis : @math.Vec3,
) -> @math.Vec3 {
  let vertical = ray_direction.cross(axis)
  if vertical.length_squared() < TRANSFORM_GIZMO_EPSILON {
    // Ray is nearly parallel to the axis: pick an arbitrary perpendicular.
    return axis.any_orthonormal_vector()
  }
  axis.cross(vertical.normalize()).normalize()
}

///|
/// Intersect a ray with a plane defined by a normal and a point on the plane.
pub fn intersect_plane(
  ray_origin : @math.Vec3,
  ray_direction : @math.Vec3,
  plane_normal : @math.Vec3,
  plane_origin : @math.Vec3,
) -> @math.Vec3? {
  let denominator = ray_direction.dot(plane_normal)
  if denominator.abs() > TRANSFORM_GIZMO_EPSILON {
    let point_to_point = plane_origin.sub(ray_origin)
    let intersect_dist = plane_normal.dot(point_to_point) / denominator
    Some(ray_direction.mul_scalar(intersect_dist).add(ray_origin))
  } else {
    None
  }
}

///|
/// Distance from a point to a line segment in 2D.
pub fn point_to_segment_dist(
  point : @math.Vec2,
  a : @math.Vec2,
  b : @math.Vec2,
) -> Float {
  let ab = b.sub(a)
  let ap = point.sub(a)
  let len_sq = ab.length_squared()
  let t = if len_sq <= 0.0F {
    0.0F
  } else {
    let raw = ap.dot(ab) / len_sq
    if raw < 0.0F {
      0.0F
    } else if raw > 1.0F {
      1.0F
    } else {
      raw
    }
  }
  let closest = a.add(ab.mul_scalar(t))
  point.sub(closest).length()
}

///|
/// Return the effective space for the gizmo: scale always uses local space.
pub fn effective_space(
  settings : TransformGizmoSettings,
) -> TransformGizmoSpace {
  match settings.mode {
    Scale => Local
    _ => settings.space
  }
}

///|
/// Compute the gizmo rotation based on the space setting.
pub fn gizmo_rotation(
  global_rotation : @math.Quat,
  space : TransformGizmoSpace,
) -> @math.Quat {
  match space {
    World => @math.Quat::identity()
    Local => global_rotation
  }
}

///|
fn snap_value(value : Float, increment : Float) -> Float {
  (value / increment).round() * increment
}

///|
/// Snap only the component along the dragged axis, leaving others unchanged.
///
/// Bevy keeps this private; it is exposed here only until
/// `transform_gizmo_drag`, its sole consumer, is ported.
pub fn snap_axis(
  position : @math.Vec3,
  original : @math.Vec3,
  axis : TransformGizmoAxis,
  increment : Float,
) -> @math.Vec3 {
  match axis {
    X =>
      @math.Vec3::new(snap_value(position.x, increment), original.y, original.z)
    Y =>
      @math.Vec3::new(original.x, snap_value(position.y, increment), original.z)
    Z =>
      @math.Vec3::new(original.x, original.y, snap_value(position.z, increment))
    // Snap all axes uniformly.
    View =>
      @math.Vec3::new(
        snap_value(position.x, increment),
        snap_value(position.y, increment),
        snap_value(position.z, increment),
      )
  }
}

///|
/// Initialise the transform gizmo resources.
///
/// `TransformGizmoPlugin` lives in the `gizmos/transform_gizmo` fragment
/// because the hover and drag systems need camera viewport projection.
pub fn transform_gizmo_init_resources(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .init_resource(fn() { TransformGizmoSettings::TransformGizmoSettings() })
  .init_resource(fn() { TransformGizmoState::TransformGizmoState() })
}

///|
// Bevy source: `bevy/crates/bevy_gizmos/src/transform_gizmo.rs` (hover, drag
// and camera resolution).

///|
const RING_SAMPLES : Int = 64

///|
const TRANSFORM_GIZMO_TAU : Float = 6.2831855

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
  projection : @camera_projection3d.Projection
  transform : @transform.Transform
}

///|
fn collect_cameras(
  world : @ecs.World,
  marked_only : Bool,
) -> Array[GizmoCamera] {
  let cameras : Array[GizmoCamera] = []
  world.for_each_component(@camera_components3d.ecs_key_camera3d, fn(
    entity,
    _camera3d,
  ) {
    if marked_only &&
      (try! world.get_by_key(entity, ecs_key_transform_gizmo_camera)) is None {
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
      (try! world.get_by_key(entity, @camera_projection3d.ecs_key_projection)) {
      Some(value) => value
      None => @camera_projection3d.Projection::default()
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
  @camera_projection_math.camera_world_to_viewport(
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
      TRANSFORM_GIZMO_TAU /
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
          let dist = point_to_segment_dist(cursor, prev, screen)
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
  world.for_each_component(ecs_key_transform_gizmo_focus, fn(entity, _marker) {
    if found is Some(_) {
      return
    }
    found = Some((entity, camera_global_transform(world, entity)))
  })
  found
}

///|
fn transform_gizmo_settings_of(world : @ecs.World) -> TransformGizmoSettings {
  match world.get_resource(ecs_res_key_transform_gizmo_settings) {
    Some(value) => value
    None => TransformGizmoSettings::TransformGizmoSettings()
  }
}

///|
fn transform_gizmo_state_of(world : @ecs.World) -> TransformGizmoState {
  match world.get_resource(ecs_res_key_transform_gizmo_state) {
    Some(value) => value
    None => TransformGizmoState::TransformGizmoState()
  }
}

///|
fn set_gizmo_state(world : @ecs.World, state : TransformGizmoState) -> Unit {
  world.insert_resource(ecs_res_key_transform_gizmo_state, state)
}

///|
/// Screen-space scale factor applied to the gizmo so it keeps a constant size.
fn gizmo_screen_scale(
  settings : TransformGizmoSettings,
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
  let state = transform_gizmo_state_of(world)
  let cleared = { ..state, hovered_axis: None }
  set_gizmo_state(world, cleared)
  if state.active {
    return
  }
  guard focused_entity(world) is Some((_, focus_transform)) else { return }
  guard resolve_gizmo_camera(world) is Some(gizmo_camera) else { return }
  guard primary_cursor_position(world) is Some(cursor) else { return }
  let settings = transform_gizmo_settings_of(world)
  let target_size = camera_target_size(
    gizmo_camera.camera,
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()
  let gizmo_pos = focus_transform.translation
  let space = effective_space(settings)
  let rotation = gizmo_rotation(focus_transform.rotation, space)
  let scale = gizmo_screen_scale(
    settings,
    gizmo_camera.transform.translation,
    gizmo_pos,
  )
  let cam_forward = transform_forward(gizmo_camera.transform)
  let axes : Array[(TransformGizmoAxis, @math.Vec3)] = [
    (X, axis_direction(X, rotation, cam_forward)),
    (Y, axis_direction(Y, rotation, cam_forward)),
    (Z, axis_direction(Z, rotation, cam_forward)),
  ]
  let mut best_axis : TransformGizmoAxis? = None
  let mut best_dist = FLOAT_MAX
  let threshold = settings.axis_hit_distance
  for entry in axes {
    let axis = entry.0
    let dir = entry.1
    let dist = match settings.mode {
      Translate | Scale => {
        let start = gizmo_pos.add(dir.mul_scalar(AXIS_START_OFFSET * scale))
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
        point_to_segment_dist(cursor, start_screen, end_screen)
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
          let screen_radius = VIEW_CIRCLE_MAJOR * scale
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
        VIEW_RING_MAJOR * scale,
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
  mode : TransformGizmoMode,
  axis : TransformGizmoAxis,
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
        intersect_plane(ray_origin, ray_direction, cam_forward, gizmo_pos)
      } else {
        let plane_normal = translation_plane_normal(ray_direction, axis_dir)
        guard intersect_plane(
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
      let plane_normal = translation_plane_normal(ray_direction, axis_dir)
      guard intersect_plane(ray_origin, ray_direction, plane_normal, gizmo_pos)
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
      guard intersect_plane(ray_origin, ray_direction, rot_axis, gizmo_pos)
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
  let settings = transform_gizmo_settings_of(world)
  let state = transform_gizmo_state_of(world)
  let target_size = camera_target_size(
    gizmo_camera.camera,
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()
  let cam_forward = transform_forward(gizmo_camera.transform)
  guard @camera_projection_math.camera_viewport_to_world_ray(
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
    let space = effective_space(settings)
    let rotation = gizmo_rotation(global_transform.rotation, space)
    let axis_dir = axis_direction(axis, rotation, cam_forward)
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
    let space = effective_space(settings)
    let rotation = gizmo_rotation(global_transform.rotation, space)
    let axis_dir = axis_direction(axis, rotation, cam_forward)
    let gizmo_origin = state.gizmo_origin
    let updated = match settings.mode {
      Translate => {
        let plane_normal = if axis is View {
          cam_forward
        } else {
          translation_plane_normal(ray_direction, axis_dir)
        }
        guard intersect_plane(
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
              snap_axis(
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
        guard intersect_plane(ray_origin, ray_direction, rot_axis, gizmo_origin)
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
        let plane_normal = translation_plane_normal(ray_direction, axis_dir)
        guard intersect_plane(
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
        let scale_factor_axis = if start_projected.abs() >
          TRANSFORM_GIZMO_EPSILON {
          cursor_projected / start_projected
        } else {
          1.0F
        }
        let start_scale = state.start_transform.scale
        let scaled = match axis {
          X =>
            @math.Vec3::new(
              max_float(start_scale.x * scale_factor_axis, MIN_SCALE),
              start_scale.y,
              start_scale.z,
            )
          Y =>
            @math.Vec3::new(
              start_scale.x,
              max_float(start_scale.y * scale_factor_axis, MIN_SCALE),
              start_scale.z,
            )
          Z =>
            @math.Vec3::new(
              start_scale.x,
              start_scale.y,
              max_float(start_scale.z * scale_factor_axis, MIN_SCALE),
            )
          // Uniform scale on the view axis.
          View =>
            @math.Vec3::new(
              max_float(start_scale.x * scale_factor_axis, MIN_SCALE),
              max_float(start_scale.y * scale_factor_axis, MIN_SCALE),
              max_float(start_scale.z * scale_factor_axis, MIN_SCALE),
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
  transform_gizmo_init_resources(app)
  .add_post_update_system_config(
    @app.system(transform_gizmo_drag)
    .in_set(transform_gizmo_systems)
    .before(@transform.transform_set_propagate),
  )
  .add_post_update_system_config(
    @app.system(transform_gizmo_hover)
    .in_set(transform_gizmo_systems)
    .after(@transform.transform_set_propagate),
  )
}
