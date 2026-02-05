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
/// Conversions between mgstudio math types and moon_rapier core types.
///
/// Note: mgstudio bakes `@math.Transform.scale` into collider shapes (best-effort),
/// but Rapier poses (`Isometry2`) never include scaling.

///|
fn absf(x : Float) -> Float {
  if x < 0.0F {
    -x
  } else {
    x
  }
}

///|
pub fn mg_vec2_to_rapier(v : @math.Vec2) -> @rapier_core.Vec2 {
  @rapier_core.Vec2::new(v.x, v.y)
}

///|
pub fn rapier_vec2_to_mg(v : @rapier_core.Vec2) -> @math.Vec2 {
  @math.Vec2::new(v.x, v.y)
}

///|
pub fn mg_transform_to_iso2(t : @math.Transform) -> @rapier_core.Isometry2 {
  let translation = @rapier_core.Vec2::new(t.translation.x, t.translation.y)
  let rot = @rapier_core.Rot2::from_angle(t.rotation_z())
  @rapier_core.Isometry2::new(translation, rot)
}

///|
pub fn mg_transform_scale2d_abs(t : @math.Transform) -> @math.Vec2 {
  let mut sx = absf(t.scale.x)
  let mut sy = absf(t.scale.y)
  // Avoid generating degenerate shapes.
  if sx < 1.0e-6F {
    sx = 1.0e-6F
  }
  if sy < 1.0e-6F {
    sy = 1.0e-6F
  }
  @math.Vec2::new(sx, sy)
}

///|
pub fn iso2_to_mg_transform(
  iso : @rapier_core.Isometry2,
  z : Float,
) -> @math.Transform {
  let angle = iso.rotation.angle()
  @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(iso.translation.x, iso.translation.y),
    angle,
    @math.Vec2::new(1.0F, 1.0F),
    z~,
  )
}

///|
fn scale_vec2_abs(v : @math.Vec2, s : @math.Vec2) -> @math.Vec2 {
  @math.Vec2::new(v.x * s.x, v.y * s.y)
}

///|
fn scale_iso2_translation_abs(
  iso : @rapier_core.Isometry2,
  s : @math.Vec2,
) -> @rapier_core.Isometry2 {
  @rapier_core.Isometry2::new(
    @rapier_core.Vec2::new(iso.translation.x * s.x, iso.translation.y * s.y),
    iso.rotation,
  )
}

///|
/// Convert mgstudio's 2D collider shape to Rapier's shape.
pub fn collider_shape2d_to_rapier(shape : ColliderShape2d) -> @collision.Shape {
  collider_shape2d_to_rapier_scaled(shape, @math.Vec2::new(1.0F, 1.0F))
}

///|
/// Convert mgstudio's 2D collider shape to Rapier's shape, baking the given scale.
///
/// Note: Negative scale is treated as its absolute value (sprite flipping should not
/// mirror physics geometry). Some primitives (ball/capsule) are only approximate for
/// non-uniform scaling.
pub fn collider_shape2d_to_rapier_scaled(
  shape : ColliderShape2d,
  scale : @math.Vec2,
) -> @collision.Shape {
  let sx = absf(scale.x)
  let sy = absf(scale.y)
  let s = @math.Vec2::new(sx, sy)
  let max_s = if sx > sy { sx } else { sy }
  match shape {
    Ball(radius) => @collision.Shape::Ball(radius * max_s)
    Cuboid(hx, hy) => @collision.Shape::Cuboid(hx * sx, hy * sy)
    CapsuleX(half_height, radius) =>
      @collision.Shape::CapsuleX(half_height * sx, radius * max_s)
    CapsuleY(half_height, radius) =>
      @collision.Shape::CapsuleY(half_height * sy, radius * max_s)
    Segment(a, b) => {
      let a2 = scale_vec2_abs(a, s)
      let b2 = scale_vec2_abs(b, s)
      @collision.Shape::Segment(mg_vec2_to_rapier(a2), mg_vec2_to_rapier(b2))
    }
    Polyline(vertices, indices) => {
      let vs : Array[@rapier_core.Vec2] = []
      for v in vertices {
        vs.push(mg_vec2_to_rapier(scale_vec2_abs(v, s)))
      }
      @collision.Shape::Polyline(vs, indices)
    }
    ConvexPolygon(vertices) => {
      let vs : Array[@rapier_core.Vec2] = []
      for v in vertices {
        vs.push(mg_vec2_to_rapier(scale_vec2_abs(v, s)))
      }
      @collision.Shape::ConvexPolygon(vs)
    }
    TriMesh(vertices, indices) => {
      let vs : Array[@rapier_core.Vec2] = []
      for v in vertices {
        vs.push(mg_vec2_to_rapier(scale_vec2_abs(v, s)))
      }
      @collision.Shape::TriMesh(vs, indices)
    }
    Compound(parts) => {
      let out : Array[(@rapier_core.Isometry2, @collision.Shape)] = []
      for part in parts {
        let (t, sub) = part
        let part_scale = mg_transform_scale2d_abs(t)
        let sub_scale = @math.Vec2::new(sx * part_scale.x, sy * part_scale.y)
        let part_iso = scale_iso2_translation_abs(mg_transform_to_iso2(t), s)
        out.push((part_iso, collider_shape2d_to_rapier_scaled(sub, sub_scale)))
      }
      @collision.Shape::Compound(out)
    }
    Raw(s0) => s0
  }
}
