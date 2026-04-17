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
/// Bevy-like transform propagation.
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
  affine : @math.Affine3
}

///|
pub fn GlobalTransform::identity() -> GlobalTransform {
  GlobalTransform::{ affine: @math.Affine3::identity() }
}

///|
pub impl Default for GlobalTransform with default() {
  GlobalTransform::identity()
}

///|
pub impl ToJson for GlobalTransform with to_json(self) {
  (
    self.affine.matrix3.x_axis.x,
    self.affine.matrix3.x_axis.y,
    self.affine.matrix3.x_axis.z,
    self.affine.matrix3.y_axis.x,
    self.affine.matrix3.y_axis.y,
    self.affine.matrix3.y_axis.z,
    self.affine.matrix3.z_axis.x,
    self.affine.matrix3.z_axis.y,
    self.affine.matrix3.z_axis.z,
    self.affine.translation.x,
    self.affine.translation.y,
    self.affine.translation.z,
  ).to_json()
}

///|
pub impl @json.FromJson for GlobalTransform with from_json(json, path) {
  let (
    x_axis_x,
    x_axis_y,
    x_axis_z,
    y_axis_x,
    y_axis_y,
    y_axis_z,
    z_axis_x,
    z_axis_y,
    z_axis_z,
    tx,
    ty,
    tz,
  ) : (
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
    Float,
  ) = @json.from_json(json, path~)
  GlobalTransform::{
    affine: @math.Affine3::from_mat3_translation(
      @math.Mat3::from_cols(
        @math.Vec3::new(x_axis_x, x_axis_y, x_axis_z),
        @math.Vec3::new(y_axis_x, y_axis_y, y_axis_z),
        @math.Vec3::new(z_axis_x, z_axis_y, z_axis_z),
      ),
      @math.Vec3::new(tx, ty, tz),
    ),
  }
}

///|
pub fn GlobalTransform::from_transform(
  transform : Transform,
) -> GlobalTransform {
  GlobalTransform::{
    affine: @math.Affine3::from_scale_rotation_translation(
      transform.scale,
      transform.rotation,
      transform.translation,
    ),
  }
}

///|
pub fn GlobalTransform::mul(
  self : GlobalTransform,
  other : GlobalTransform,
) -> GlobalTransform {
  GlobalTransform::{ affine: self.affine.mul(other.affine) }
}

///|
pub fn GlobalTransform::mul_transform(
  self : GlobalTransform,
  transform : Transform,
) -> GlobalTransform {
  GlobalTransform::{
    affine: self.affine.mul_transform(
      transform.scale,
      transform.rotation,
      transform.translation,
    ),
  }
}

///|
pub fn GlobalTransform::affine(self : GlobalTransform) -> @math.Affine3 {
  self.affine
}

///|
pub fn GlobalTransform::to_scale_rotation_translation(
  self : GlobalTransform,
) -> (@math.Vec3, @math.Quat, @math.Vec3) {
  self.affine.to_scale_rotation_translation()
}

///|
pub fn GlobalTransform::translation(self : GlobalTransform) -> @math.Vec3 {
  self.affine.translation
}

///|
pub fn GlobalTransform::to_transform_approx(
  self : GlobalTransform,
) -> Transform {
  let (scale, rotation, translation) = self.to_scale_rotation_translation()
  Transform::new(translation, rotation, scale)
}

///|
pub fn GlobalTransform::inverse(self : GlobalTransform) -> GlobalTransform {
  GlobalTransform::{ affine: self.affine.inverse() }
}

///|
pub fn GlobalTransform::reparented_to(
  self : GlobalTransform,
  parent : GlobalTransform,
) -> Transform {
  let (scale, rotation, translation) = parent
    .inverse()
    .mul(self)
    .to_scale_rotation_translation()
  Transform::new(translation, rotation, scale)
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
    debug_name="mgstudio_transform::StaticTransformOptimizations",
  )
}

///|
pub impl @app.Resource for StaticTransformOptimizations with resource() {
  static_transform_optimizations_resource_key()
}
