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
/// Bevy-like transform propagation (2D-first).
///
/// This package provides:
/// - `GlobalTransform` component (computed world-space transform)
/// - systems to maintain `Children` from `Parent` and propagate transforms

///|
pub struct Affine2 {
  a : Float
  b : Float
  c : Float
  d : Float
  tx : Float
  ty : Float
}

///|
pub fn Affine2::identity() -> Affine2 {
  Affine2::{ a: 1.0F, b: 0.0F, c: 0.0F, d: 1.0F, tx: 0.0F, ty: 0.0F }
}

///|
pub fn Affine2::from_scale(scale : @math.Vec2) -> Affine2 {
  Affine2::{ a: scale.x, b: 0.0F, c: 0.0F, d: scale.y, tx: 0.0F, ty: 0.0F }
}

///|
pub fn Affine2::from_translation(translation : @math.Vec2) -> Affine2 {
  Affine2::{
    a: 1.0F,
    b: 0.0F,
    c: 0.0F,
    d: 1.0F,
    tx: translation.x,
    ty: translation.y,
  }
}

///|
pub fn Affine2::from_scale_translation(
  scale : @math.Vec2,
  translation : @math.Vec2,
) -> Affine2 {
  Affine2::{
    a: scale.x,
    b: 0.0F,
    c: 0.0F,
    d: scale.y,
    tx: translation.x,
    ty: translation.y,
  }
}

///|
pub fn Affine2::mul(self : Affine2, other : Affine2) -> Affine2 {
  // (A, t) * (B, u) = (A*B, A*u + t)
  let a = self.a * other.a + self.c * other.b
  let b = self.b * other.a + self.d * other.b
  let c = self.a * other.c + self.c * other.d
  let d = self.b * other.c + self.d * other.d
  let tx = self.a * other.tx + self.c * other.ty + self.tx
  let ty = self.b * other.tx + self.d * other.ty + self.ty
  Affine2::{ a, b, c, d, tx, ty }
}

///|
pub fn Affine2::transform_point2(
  self : Affine2,
  point : @math.Vec2,
) -> @math.Vec2 {
  @math.Vec2::new(
    self.a * point.x + self.c * point.y + self.tx,
    self.b * point.x + self.d * point.y + self.ty,
  )
}

///|
pub struct GlobalTransform {
  affine : Affine2
  z : Float
}

///|
pub fn GlobalTransform::identity() -> GlobalTransform {
  GlobalTransform::{ affine: Affine2::identity(), z: 0.0F }
}

///|
pub impl Default for GlobalTransform with default() {
  GlobalTransform::identity()
}

///|
pub impl ToJson for GlobalTransform with to_json(self) {
  (
    self.affine.a,
    self.affine.b,
    self.affine.c,
    self.affine.d,
    self.affine.tx,
    self.affine.ty,
    self.z,
  ).to_json()
}

///|
pub impl @json.FromJson for GlobalTransform with from_json(json, path) {
  let (a, b, c, d, tx, ty, z) : (
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
  ) = @json.from_json(json, path~)
  GlobalTransform::{ affine: Affine2::{ a, b, c, d, tx, ty }, z }
}

///|
pub fn GlobalTransform::from_transform(
  transform : Transform,
) -> GlobalTransform {
  let rot_z = transform.rotation_z()
  let cosv = @math.cos(rot_z)
  let sinv = @math.sin(rot_z)
  let sx = transform.scale.x
  let sy = transform.scale.y
  let a = cosv * sx
  let b = sinv * sx
  let c = -sinv * sy
  let d = cosv * sy
  GlobalTransform::{
    affine: Affine2::{
      a,
      b,
      c,
      d,
      tx: transform.translation.x,
      ty: transform.translation.y,
    },
    z: transform.translation.z,
  }
}

///|
pub fn GlobalTransform::mul(
  self : GlobalTransform,
  other : GlobalTransform,
) -> GlobalTransform {
  GlobalTransform::{
    affine: self.affine.mul(other.affine),
    z: self.z + other.z,
  }
}

///|
pub fn GlobalTransform::to_transform_approx(
  self : GlobalTransform,
) -> Transform {
  // Best-effort TRS decomposition for a 2D affine matrix.
  // This ignores shear in the returned Transform, but preserves translation.
  let a = self.affine.a
  let b = self.affine.b
  let c = self.affine.c
  let d = self.affine.d
  let scale_x = @math.sqrt(a * a + b * b)
  let rotation = if scale_x == 0.0F { 0.0F } else { @math.atan2(b, a) }
  let det = a * d - b * c
  let scale_y = if scale_x == 0.0F { 0.0F } else { det / scale_x }
  Transform::from_xy_rotation_scale(
    @math.Vec2::new(self.affine.tx, self.affine.ty),
    rotation,
    @math.Vec2::new(scale_x, scale_y),
    z=self.z,
  )
}

///|
pub fn GlobalTransform::inverse(self : GlobalTransform) -> GlobalTransform {
  let det = self.affine.a * self.affine.d - self.affine.b * self.affine.c
  if det <= 1.0e-12F && det >= -1.0e-12F {
    return GlobalTransform::identity()
  }
  let inv_det = 1.0F / det
  let a = self.affine.d * inv_det
  let b = -self.affine.b * inv_det
  let c = -self.affine.c * inv_det
  let d = self.affine.a * inv_det
  let tx = -(a * self.affine.tx + c * self.affine.ty)
  let ty = -(b * self.affine.tx + d * self.affine.ty)
  GlobalTransform::{ affine: Affine2::{ a, b, c, d, tx, ty }, z: -self.z }
}

///|
pub fn GlobalTransform::reparented_to(
  self : GlobalTransform,
  parent : GlobalTransform,
) -> GlobalTransform {
  parent.inverse().mul(self)
}

///|
pub fn GlobalTransform::compute_transform(self : GlobalTransform) -> Transform {
  self.to_transform_approx()
}

///|
pub struct TransformTreeChanged {} derive(Eq, Debug, ToJson, FromJson)

///|
pub impl Default for TransformTreeChanged with default() {
  TransformTreeChanged::{  }
}

///|
pub struct StaticTransformOptimizations {
  threshold : Float
  mut enabled : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn StaticTransformOptimizations::from_threshold(
  threshold : Float,
) -> StaticTransformOptimizations {
  { threshold, enabled: true }
}

///|
pub fn StaticTransformOptimizations::disabled() -> StaticTransformOptimizations {
  { threshold: 0.0F, enabled: false }
}

///|
pub fn StaticTransformOptimizations::enabled() -> StaticTransformOptimizations {
  { threshold: 1.0F, enabled: true }
}

///|
pub impl Default for StaticTransformOptimizations with default() {
  { threshold: 0.3F, enabled: true }
}

///|
pub fn static_transform_optimizations_resource_key() -> @ecs.ResourceKey[
  StaticTransformOptimizations,
] {
  @ecs.register_resource(
    debug_name="bevy_transform::StaticTransformOptimizations",
  )
}

///|
pub impl @app.Resource for StaticTransformOptimizations with resource() {
  static_transform_optimizations_resource_key()
}
