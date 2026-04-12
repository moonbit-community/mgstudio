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
// Bevy source: `bevy/crates/bevy_gizmos/src/primitives/dim3.rs`.

///|
const GIZMO_DIM3_SEGMENTS : Int = 24

///|
const GIZMO_DIM3_TAU : Float = 6.283185307179586F

///|
fn gizmo_dim3_local_ring_points(
  radius_x : Float,
  radius_z : Float,
  y : Float,
  segments : Int,
) -> Array[@math.Vec3] {
  let steps = if segments < 3 { 3 } else { segments }
  let points : Array[@math.Vec3] = []
  let denom = Float::from_double(steps.to_double())
  for i in 0..<=steps {
    let angle = GIZMO_DIM3_TAU * Float::from_double(i.to_double()) / denom
    points.push(
      @math.Vec3::new(
        @math.cos(angle) * radius_x,
        y,
        @math.sin(angle) * radius_z,
      ),
    )
  }
  points
}

///|
pub fn[Config] gizmo_draw_sphere_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  sphere : @math.Sphere,
  color : @sprite.Color,
) -> Unit {
  gizmos.sphere_3d(isometry, sphere.radius, color)
}

///|
pub fn[Config] gizmo_draw_capsule_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  capsule : @math.Capsule3d,
  color : @sprite.Color,
) -> Unit {
  let top_center = isometry.transform_point3(
    @math.Vec3::new(0.0F, capsule.half_length, 0.0F),
  )
  let bottom_center = isometry.transform_point3(
    @math.Vec3::new(0.0F, -capsule.half_length, 0.0F),
  )
  gizmos.sphere_3d(
    @math.Isometry3d::new(top_center, isometry.rotation),
    capsule.radius,
    color,
  )
  gizmos.sphere_3d(
    @math.Isometry3d::new(bottom_center, isometry.rotation),
    capsule.radius,
    color,
  )
  let offsets = [
    @math.Vec3::new(capsule.radius, 0.0F, 0.0F),
    @math.Vec3::new(-capsule.radius, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 0.0F, capsule.radius),
    @math.Vec3::new(0.0F, 0.0F, -capsule.radius),
  ]
  for offset in offsets {
    let start = isometry.transform_point3(
      @math.Vec3::new(offset.x, capsule.half_length, offset.z),
    )
    let end = isometry.transform_point3(
      @math.Vec3::new(offset.x, -capsule.half_length, offset.z),
    )
    gizmos.line_3d(start, end, color)
  }
}

///|
pub fn[Config] gizmo_draw_cone_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  cone : @math.Cone,
  color : @sprite.Color,
) -> Unit {
  let half_height = cone.height * 0.5F
  let tip = isometry.transform_point3(@math.Vec3::new(0.0F, half_height, 0.0F))
  let ring_local = gizmo_dim3_local_ring_points(
    cone.radius,
    cone.radius,
    -half_height,
    GIZMO_DIM3_SEGMENTS,
  )
  let ring_world = @transform.transform_points(isometry, ring_local)
  gizmos.linestrip_3d(ring_world, color)
  let base_cardinal = [
    @math.Vec3::new(cone.radius, -half_height, 0.0F),
    @math.Vec3::new(-cone.radius, -half_height, 0.0F),
    @math.Vec3::new(0.0F, -half_height, cone.radius),
    @math.Vec3::new(0.0F, -half_height, -cone.radius),
  ]
  for point in base_cardinal {
    gizmos.line_3d(tip, isometry.transform_point3(point), color)
  }
}

///|
pub fn[Config] gizmo_draw_torus_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  torus : @math.Torus,
  color : @sprite.Color,
) -> Unit {
  let major_ring_local = gizmo_dim3_local_ring_points(
    torus.major_radius,
    torus.major_radius,
    0.0F,
    GIZMO_DIM3_SEGMENTS,
  )
  gizmos.linestrip_3d(
    @transform.transform_points(isometry, major_ring_local),
    color,
  )
  let minor_x = gizmo_dim3_local_ring_points(
    torus.minor_radius,
    torus.minor_radius,
    0.0F,
    GIZMO_DIM3_SEGMENTS,
  )
  let minor_x_world : Array[@math.Vec3] = []
  for point in minor_x {
    let local_point = @math.Vec3::new(
      point.x + torus.major_radius,
      point.y,
      point.z,
    )
    minor_x_world.push(isometry.transform_point3(local_point))
  }
  gizmos.linestrip_3d(minor_x_world, color)
}
