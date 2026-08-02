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
// Whitebox coverage for the pure helpers ported from
// `bevy/crates/bevy_gizmos/src/transform_gizmo.rs`.

///|
fn approx(actual : Float, expected : Float) -> Bool {
  (actual - expected).abs() < 1.0e-4F
}

///|
test "transform gizmo ray-plane intersection matches the Bevy formula" {
  // Ray from +Z looking down -Z hits the XY plane through the origin at Z = 0.
  let hit = intersect_plane(
    @math.Vec3::new(0.0F, 0.0F, 5.0F),
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    @math.Vec3::new(0.0F, 0.0F, 1.0F),
    @math.Vec3::zero(),
  )
  guard hit is Some(point) else { fail("expected an intersection") }
  debug_inspect(approx(point.x, 0.0F), content="true")
  debug_inspect(approx(point.y, 0.0F), content="true")
  debug_inspect(approx(point.z, 0.0F), content="true")
}

///|
test "transform gizmo ray parallel to the plane does not intersect" {
  // Bevy returns None when |denominator| <= f32::EPSILON.
  let hit = intersect_plane(
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec3::new(1.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
    @math.Vec3::zero(),
  )
  debug_inspect(hit is None, content="true")
}

///|
test "transform gizmo point-to-segment distance clamps to the endpoints" {
  let a = @math.Vec2::new(0.0F, 0.0F)
  let b = @math.Vec2::new(10.0F, 0.0F)
  // Perpendicular from above the middle of the segment.
  debug_inspect(
    approx(point_to_segment_dist(@math.Vec2::new(5.0F, 3.0F), a, b), 3.0F),
    content="true",
  )
  // Before `a`: clamps to `a`, so the distance is to the endpoint.
  debug_inspect(
    approx(point_to_segment_dist(@math.Vec2::new(-4.0F, 0.0F), a, b), 4.0F),
    content="true",
  )
  // After `b`: clamps to `b`.
  debug_inspect(
    approx(point_to_segment_dist(@math.Vec2::new(14.0F, 0.0F), a, b), 4.0F),
    content="true",
  )
}

///|
test "transform gizmo translation plane normal stays perpendicular to the axis" {
  let axis = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let normal = translation_plane_normal(
    @math.Vec3::new(0.0F, 0.0F, -1.0F),
    axis,
  )
  // The constraint plane must contain the drag axis.
  debug_inspect(approx(normal.dot(axis), 0.0F), content="true")
  debug_inspect(approx(normal.length(), 1.0F), content="true")
}

///|
test "transform gizmo translation plane normal falls back when ray is parallel" {
  // Bevy takes `axis.any_orthonormal_vector()` when the cross product vanishes.
  let axis = @math.Vec3::new(1.0F, 0.0F, 0.0F)
  let normal = translation_plane_normal(axis, axis)
  debug_inspect(approx(normal.dot(axis), 0.0F), content="true")
  debug_inspect(approx(normal.length(), 1.0F), content="true")
}

///|
test "transform gizmo axis directions follow the gizmo rotation" {
  let identity = @math.Quat::identity()
  let forward = @math.Vec3::new(0.0F, 0.0F, -1.0F)
  let x = axis_direction(X, identity, forward)
  debug_inspect(approx(x.x, 1.0F), content="true")
  let y = axis_direction(Y, identity, forward)
  debug_inspect(approx(y.y, 1.0F), content="true")
  let z = axis_direction(Z, identity, forward)
  debug_inspect(approx(z.z, 1.0F), content="true")
  // The view axis ignores the gizmo rotation and uses camera forward.
  let view = axis_direction(View, identity, forward)
  debug_inspect(approx(view.z, -1.0F), content="true")
}

///|
test "transform gizmo scale mode always uses local space" {
  // Bevy's `effective_space` overrides the setting for Scale.
  let settings = TransformGizmoSettings::TransformGizmoSettings()
  debug_inspect(effective_space(settings) is World, content="true")
  let scaling = { ..settings, mode: Scale, space: World }
  debug_inspect(effective_space(scaling) is Local, content="true")
  let rotating = { ..settings, mode: Rotate, space: Local }
  debug_inspect(effective_space(rotating) is Local, content="true")
}

///|
test "transform gizmo world space rotation is identity" {
  let rotation = @math.Quat::from_rotation_y(1.0F)
  let world = gizmo_rotation(rotation, World)
  debug_inspect(approx(world.w, 1.0F), content="true")
  let local_rotation = gizmo_rotation(rotation, Local)
  debug_inspect(approx(local_rotation.w, rotation.w), content="true")
}

///|
test "transform gizmo snapping rounds to the increment" {
  debug_inspect(approx(snap_value(0.34F, 0.25F), 0.25F), content="true")
  debug_inspect(approx(snap_value(0.4F, 0.25F), 0.5F), content="true")
  debug_inspect(approx(snap_value(-0.4F, 0.25F), -0.5F), content="true")
}

///|
test "transform gizmo axis snapping leaves the other components alone" {
  let position = @math.Vec3::new(1.4F, 2.6F, 3.9F)
  let original = @math.Vec3::new(9.0F, 8.0F, 7.0F)
  let snapped_x = snap_axis(position, original, X, 1.0F)
  debug_inspect(approx(snapped_x.x, 1.0F), content="true")
  debug_inspect(approx(snapped_x.y, 8.0F), content="true")
  debug_inspect(approx(snapped_x.z, 7.0F), content="true")
  // The view axis snaps every component.
  let snapped_view = snap_axis(position, original, View, 1.0F)
  debug_inspect(approx(snapped_view.x, 1.0F), content="true")
  debug_inspect(approx(snapped_view.y, 3.0F), content="true")
  debug_inspect(approx(snapped_view.z, 4.0F), content="true")
}

///|
test "transform gizmo settings carry the Bevy defaults" {
  let settings = TransformGizmoSettings::TransformGizmoSettings()
  debug_inspect(approx(settings.axis_length, AXIS_LENGTH), content="true")
  debug_inspect(
    approx(settings.rotate_ring_radius, ROTATE_RING_RADIUS),
    content="true",
  )
  debug_inspect(
    approx(settings.axis_hit_distance, AXIS_HIT_DISTANCE),
    content="true",
  )
  debug_inspect(approx(settings.screen_scale_factor, 0.1F), content="true")
  debug_inspect(settings.confine_cursor, content="true")
  debug_inspect(settings.snap_translate is None, content="true")
  // Bevy clamps scale handles to this floor during a drag.
  debug_inspect(approx(MIN_SCALE, 0.01F), content="true")
}

///|
test "transform gizmo state starts idle" {
  let state = TransformGizmoState::TransformGizmoState()
  debug_inspect(state.active, content="false")
  debug_inspect(state.hovered_axis is None, content="true")
  debug_inspect(state.axis is None, content="true")
  debug_inspect(state.entity is None, content="true")
}
