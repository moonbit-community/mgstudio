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
pub struct Vec2 {
  x : Float
  y : Float
}

///|
pub fn Vec2::new(x : Float, y : Float) -> Vec2 {
  Vec2::{ x, y }
}

///|
pub struct Vec3 {
  x : Float
  y : Float
  z : Float
}

///|
pub fn Vec3::new(x : Float, y : Float, z : Float) -> Vec3 {
  Vec3::{ x, y, z }
}

///|
pub fn Vec3::splat(v : Float) -> Vec3 {
  Vec3::new(v, v, v)
}

///|
pub fn Vec3::zero() -> Vec3 {
  Vec3::splat(0.0F)
}

///|
pub fn Vec3::add(self : Vec3, other : Vec3) -> Vec3 {
  Vec3::new(self.x + other.x, self.y + other.y, self.z + other.z)
}

///|
pub fn Vec3::sub(self : Vec3, other : Vec3) -> Vec3 {
  Vec3::new(self.x - other.x, self.y - other.y, self.z - other.z)
}

///|
pub fn Vec3::neg(self : Vec3) -> Vec3 {
  Vec3::new(-self.x, -self.y, -self.z)
}

///|
pub fn Vec3::mul(self : Vec3, other : Vec3) -> Vec3 {
  Vec3::new(self.x * other.x, self.y * other.y, self.z * other.z)
}

///|
pub fn Vec3::mul_scalar(self : Vec3, scalar : Float) -> Vec3 {
  Vec3::new(self.x * scalar, self.y * scalar, self.z * scalar)
}

///|
pub fn Vec3::dot(self : Vec3, other : Vec3) -> Float {
  self.x * other.x + self.y * other.y + self.z * other.z
}

///|
pub fn Vec3::cross(self : Vec3, other : Vec3) -> Vec3 {
  Vec3::new(
    self.y * other.z - self.z * other.y,
    self.z * other.x - self.x * other.z,
    self.x * other.y - self.y * other.x,
  )
}

///|
pub fn Vec3::length_squared(self : Vec3) -> Float {
  self.dot(self)
}

///|
pub fn Vec3::length(self : Vec3) -> Float {
  sqrt(self.length_squared())
}

///|
pub fn Vec3::normalize_or_zero(self : Vec3) -> Vec3 {
  let len_sq = self.length_squared()
  if len_sq <= 1.0e-12F {
    return Vec3::zero()
  }
  let inv_len = 1.0F / sqrt(len_sq)
  self.mul_scalar(inv_len)
}

///|
pub struct Vec4 {
  x : Float
  y : Float
  z : Float
  w : Float
}

///|
pub fn Vec4::new(x : Float, y : Float, z : Float, w : Float) -> Vec4 {
  Vec4::{ x, y, z, w }
}

///|
pub fn Vec4::splat(v : Float) -> Vec4 {
  Vec4::new(v, v, v, v)
}

///|
pub struct IVec2 {
  x : Int
  y : Int
}

///|
pub fn IVec2::new(x : Int, y : Int) -> IVec2 {
  IVec2::{ x, y }
}

///|
pub struct UVec2 {
  x : Int
  y : Int
}

///|
pub fn UVec2::new(x : Int, y : Int) -> UVec2 {
  UVec2::{ x, y }
}

///|
pub fn UVec2::splat(value : Int) -> UVec2 {
  UVec2::new(value, value)
}

///|
pub fn UVec2::zero() -> UVec2 {
  UVec2::splat(0)
}

///|
pub fn UVec2::to_vec2(self : UVec2) -> Vec2 {
  Vec2::new(
    Float::from_double(self.x.to_double()),
    Float::from_double(self.y.to_double()),
  )
}

///|
pub fn UVec2::add(self : UVec2, other : UVec2) -> UVec2 {
  UVec2::new(self.x + other.x, self.y + other.y)
}

///|
pub fn UVec2::saturating_sub(self : UVec2, other : UVec2) -> UVec2 {
  let x = if self.x - other.x < 0 { 0 } else { self.x - other.x }
  let y = if self.y - other.y < 0 { 0 } else { self.y - other.y }
  UVec2::new(x, y)
}

///|
pub struct URect {
  min : UVec2
  max : UVec2
}

///|
pub fn URect::new(min : UVec2, max : UVec2) -> URect {
  URect::{ min, max }
}

///|
pub fn URect::size(self : URect) -> UVec2 {
  UVec2::new(self.max.x - self.min.x, self.max.y - self.min.y)
}

///|
pub fn URect::as_rect(self : URect) -> Rect {
  Rect::new(self.min.to_vec2(), self.max.to_vec2())
}

///|
pub struct Rect {
  min : Vec2
  max : Vec2
}

///|
pub fn Rect::new(min : Vec2, max : Vec2) -> Rect {
  Rect::{ min, max }
}

///|
pub fn Rect::size(self : Rect) -> Vec2 {
  Vec2::new(self.max.x - self.min.x, self.max.y - self.min.y)
}

///|
pub fn Rect::center(self : Rect) -> Vec2 {
  Vec2::new((self.min.x + self.max.x) / 2.0F, (self.min.y + self.max.y) / 2.0F)
}

///|
pub fn Rect::contains(self : Rect, value : Vec2) -> Bool {
  value.x >= self.min.x &&
  value.y >= self.min.y &&
  value.x <= self.max.x &&
  value.y <= self.max.y
}

///|
pub fn IVec2::add(self : IVec2, other : IVec2) -> IVec2 {
  IVec2::new(self.x + other.x, self.y + other.y)
}

///|
pub fn IVec2::min(self : IVec2, other : IVec2) -> IVec2 {
  let x = if self.x < other.x { self.x } else { other.x }
  let y = if self.y < other.y { self.y } else { other.y }
  IVec2::new(x, y)
}

///|
pub fn IVec2::max(self : IVec2, other : IVec2) -> IVec2 {
  let x = if self.x > other.x { self.x } else { other.x }
  let y = if self.y > other.y { self.y } else { other.y }
  IVec2::new(x, y)
}

///|
pub fn IVec2::saturating_sub(self : IVec2, other : IVec2) -> IVec2 {
  let x = if self.x - other.x < 0 { 0 } else { self.x - other.x }
  let y = if self.y - other.y < 0 { 0 } else { self.y - other.y }
  IVec2::new(x, y)
}

///|
pub fn IVec2::to_vec2(self : IVec2) -> Vec2 {
  Vec2::new(
    Float::from_double(self.x.to_double()),
    Float::from_double(self.y.to_double()),
  )
}

///|
pub fn Vec2::sub(self : Vec2, other : Vec2) -> Vec2 {
  Vec2::new(self.x - other.x, self.y - other.y)
}

///|
pub fn Vec2::to_angle(self : Vec2) -> Float {
  atan2(self.y, self.x)
}

///|
pub fn atan2(y : Float, x : Float) -> Float {
  Float::from_double(@coremath.atan2(y.to_double(), x.to_double()))
}

///|
pub fn cos(value : Float) -> Float {
  Float::from_double(@coremath.cos(value.to_double()))
}

///|
pub fn sin(value : Float) -> Float {
  Float::from_double(@coremath.sin(value.to_double()))
}

///|
pub fn sqrt(value : Float) -> Float {
  @coremath.powf(value, 0.5F)
}

///|
pub fn pow(base : Float, exponent : Float) -> Float {
  Float::from_double(@coremath.pow(base.to_double(), exponent.to_double()))
}

///|
pub fn pi_half() -> Float {
  Float::from_double(@coremath.PI / 2.0)
}

///|
/// Quaternion (x, y, z, w).
pub struct Quat {
  x : Float
  y : Float
  z : Float
  w : Float
}

///|
/// Construct a quaternion from raw components (x, y, z, w).
///
/// This is primarily for engine integrations (e.g. 3D physics) that need to
/// convert from external quaternion representations.
pub fn Quat::new(x : Float, y : Float, z : Float, w : Float) -> Quat {
  Quat::{ x, y, z, w }
}

///|
pub fn Quat::identity() -> Quat {
  Quat::{ x: 0.0F, y: 0.0F, z: 0.0F, w: 1.0F }
}

///|
/// Rotation around Z axis (radians).
pub fn Quat::from_rotation_z(angle : Float) -> Quat {
  let half = angle / 2.0F
  Quat::{ x: 0.0F, y: 0.0F, z: sin(half), w: cos(half) }
}

///|
pub fn Quat::from_rotation_x(angle : Float) -> Quat {
  let half = angle / 2.0F
  Quat::{ x: sin(half), y: 0.0F, z: 0.0F, w: cos(half) }
}

///|
pub fn Quat::from_rotation_y(angle : Float) -> Quat {
  let half = angle / 2.0F
  Quat::{ x: 0.0F, y: sin(half), z: 0.0F, w: cos(half) }
}

///|
pub fn Quat::from_axis_angle(axis : Vec3, angle : Float) -> Quat {
  let unit_axis = axis.normalize_or_zero()
  if unit_axis.length_squared() <= 1.0e-12F {
    return Quat::identity()
  }
  let half = angle / 2.0F
  let s = sin(half)
  Quat::{
    x: unit_axis.x * s,
    y: unit_axis.y * s,
    z: unit_axis.z * s,
    w: cos(half),
  }
}

///|
pub fn Quat::mul(self : Quat, other : Quat) -> Quat {
  // Hamilton product.
  let x = self.w * other.x +
    self.x * other.w +
    self.y * other.z -
    self.z * other.y
  let y = self.w * other.y -
    self.x * other.z +
    self.y * other.w +
    self.z * other.x
  let z = self.w * other.z +
    self.x * other.y -
    self.y * other.x +
    self.z * other.w
  let w = self.w * other.w -
    self.x * other.x -
    self.y * other.y -
    self.z * other.z
  Quat::{ x, y, z, w }
}

///|
/// Approximate yaw (rotation around Z) in radians.
pub fn Quat::to_rotation_z_angle(self : Quat) -> Float {
  // Tait-Bryan (Z-Y-X), yaw:
  // yaw = atan2(2*(w*z + x*y), 1 - 2*(y*y + z*z))
  let t0 = 2.0F * (self.w * self.z + self.x * self.y)
  let t1 = 1.0F - 2.0F * (self.y * self.y + self.z * self.z)
  atan2(t0, t1)
}

///|
pub fn Quat::normalize(self : Quat) -> Quat {
  let len_sq = self.x * self.x +
    self.y * self.y +
    self.z * self.z +
    self.w * self.w
  if len_sq <= 1.0e-12F {
    return Quat::identity()
  }
  let inv_len = 1.0F / sqrt(len_sq)
  Quat::{
    x: self.x * inv_len,
    y: self.y * inv_len,
    z: self.z * inv_len,
    w: self.w * inv_len,
  }
}

///|
fn quat_from_basis(x_axis : Vec3, y_axis : Vec3, z_axis : Vec3) -> Quat {
  let m00 = x_axis.x
  let m01 = y_axis.x
  let m02 = z_axis.x
  let m10 = x_axis.y
  let m11 = y_axis.y
  let m12 = z_axis.y
  let m20 = x_axis.z
  let m21 = y_axis.z
  let m22 = z_axis.z
  let trace = m00 + m11 + m22
  if trace > 0.0F {
    let s = sqrt(trace + 1.0F) * 2.0F
    return Quat::{
      x: (m21 - m12) / s,
      y: (m02 - m20) / s,
      z: (m10 - m01) / s,
      w: 0.25F * s,
    }.normalize()
  }
  if m00 > m11 && m00 > m22 {
    let s = sqrt(1.0F + m00 - m11 - m22) * 2.0F
    return Quat::{
      x: 0.25F * s,
      y: (m01 + m10) / s,
      z: (m02 + m20) / s,
      w: (m21 - m12) / s,
    }.normalize()
  }
  if m11 > m22 {
    let s = sqrt(1.0F + m11 - m00 - m22) * 2.0F
    return Quat::{
      x: (m01 + m10) / s,
      y: 0.25F * s,
      z: (m12 + m21) / s,
      w: (m02 - m20) / s,
    }.normalize()
  }
  let s = sqrt(1.0F + m22 - m00 - m11) * 2.0F
  Quat::{
    x: (m02 + m20) / s,
    y: (m12 + m21) / s,
    z: 0.25F * s,
    w: (m10 - m01) / s,
  }.normalize()
}

///|
// ECS component marker for codegen (`mgstudio gen`).
#ecs.component
pub struct Transform {
  translation : Vec3
  rotation : Quat
  scale : Vec3
}

///|
pub fn Transform::new(
  translation : Vec3,
  rotation : Quat,
  scale : Vec3,
) -> Transform {
  Transform::{ translation, rotation, scale }
}

///|
pub impl ToJson for Transform with to_json(self) {
  (
    self.translation.x,
    self.translation.y,
    self.translation.z,
    self.rotation.x,
    self.rotation.y,
    self.rotation.z,
    self.rotation.w,
    self.scale.x,
    self.scale.y,
    self.scale.z,
  ).to_json()
}

///|
pub impl @json.FromJson for Transform with from_json(json, path) {
  let (tx, ty, tz, rx, ry, rz, rw, sx, sy, sz) : (
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
  Transform::new(
    Vec3::new(tx, ty, tz),
    Quat::new(rx, ry, rz, rw),
    Vec3::new(sx, sy, sz),
  )
}

///|
pub fn Transform::identity() -> Transform {
  Transform::{
    translation: Vec3::zero(),
    rotation: Quat::identity(),
    scale: Vec3::splat(1.0F),
  }
}

///|
pub fn Transform::from_xyz(x : Float, y : Float, z : Float) -> Transform {
  Transform::new(Vec3::new(x, y, z), Quat::identity(), Vec3::splat(1.0F))
}

///|
pub fn Transform::from_xy(x : Float, y : Float) -> Transform {
  Transform::from_xyz(x, y, 0.0F)
}

///|
/// Convenience for 2D usage: translation.xy + rotation about Z + scale.xy.
pub fn Transform::from_xy_rotation_scale(
  translation : Vec2,
  rotation_z : Float,
  scale : Vec2,
  z? : Float = 0.0F,
) -> Transform {
  Transform::new(
    Vec3::new(translation.x, translation.y, z),
    Quat::from_rotation_z(rotation_z),
    Vec3::new(scale.x, scale.y, 1.0F),
  )
}

///|
pub fn Transform::rotation_z(self : Transform) -> Float {
  self.rotation.to_rotation_z_angle()
}

///|
pub fn Transform::with_translation(
  self : Transform,
  translation : Vec3,
) -> Transform {
  Transform::{ translation, rotation: self.rotation, scale: self.scale }
}

///|
pub fn Transform::with_rotation(self : Transform, rotation : Quat) -> Transform {
  Transform::{ translation: self.translation, rotation, scale: self.scale }
}

///|
pub fn Transform::with_scale(self : Transform, scale : Vec3) -> Transform {
  Transform::{ translation: self.translation, rotation: self.rotation, scale }
}

///|
pub fn Transform::looking_at(
  self : Transform,
  target : Vec3,
  up : Vec3,
) -> Transform {
  let forward = target.sub(self.translation).normalize_or_zero()
  if forward.length_squared() <= 1.0e-12F {
    return self
  }
  let up_hint = if up.length_squared() <= 1.0e-12F {
    Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    up.normalize_or_zero()
  }
  // Bevy follows a right-handed convention where local -Z points forward.
  let z_axis = forward.neg()
  let mut x_axis = up_hint.cross(z_axis).normalize_or_zero()
  if x_axis.length_squared() <= 1.0e-12F {
    x_axis = Vec3::new(1.0F, 0.0F, 0.0F).cross(z_axis).normalize_or_zero()
    if x_axis.length_squared() <= 1.0e-12F {
      x_axis = Vec3::new(0.0F, 0.0F, 1.0F).cross(z_axis).normalize_or_zero()
    }
  }
  let y_axis = z_axis.cross(x_axis).normalize_or_zero()
  let rotation = quat_from_basis(x_axis, y_axis, z_axis)
  Transform::{ translation: self.translation, rotation, scale: self.scale }
}
