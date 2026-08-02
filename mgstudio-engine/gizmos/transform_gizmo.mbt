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
