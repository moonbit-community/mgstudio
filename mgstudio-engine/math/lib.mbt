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
pub(all) struct Vec2 {
  mut x : Float
  mut y : Float
}

///|
pub fn Vec2::new(x : Float, y : Float) -> Vec2 {
  Vec2::{ x, y }
}

///|
pub fn Vec2::zero() -> Vec2 {
  Vec2::new(0.0F, 0.0F)
}

///|
pub fn Vec2::add(self : Vec2, other : Vec2) -> Vec2 {
  Vec2::new(self.x + other.x, self.y + other.y)
}

///|
pub fn Vec2::mul_scalar(self : Vec2, scalar : Float) -> Vec2 {
  Vec2::new(self.x * scalar, self.y * scalar)
}

///|
pub fn Vec2::dot(self : Vec2, other : Vec2) -> Float {
  self.x * other.x + self.y * other.y
}

///|
pub fn Vec2::length_squared(self : Vec2) -> Float {
  self.dot(self)
}

///|
pub fn Vec2::length(self : Vec2) -> Float {
  sqrt(self.length_squared())
}

///|
pub fn Vec2::distance(self : Vec2, other : Vec2) -> Float {
  self.sub(other).length()
}

///|
pub fn Vec2::normalize_or_zero(self : Vec2) -> Vec2 {
  let len_sq = self.length_squared()
  if len_sq <= 1.0e-12F {
    return Vec2::zero()
  }
  let inv_len = 1.0F / sqrt(len_sq)
  self.mul_scalar(inv_len)
}

///|
pub fn Vec2::perp_dot(self : Vec2, other : Vec2) -> Float {
  self.x * other.y - self.y * other.x
}

///|
/// Returns the signed angle in radians for the minimal rotation from `self` to
/// `rhs`, matching glam/Bevy `Vec2::angle_to`.
pub fn Vec2::angle_to(self : Vec2, rhs : Vec2) -> Float {
  let denom = sqrt(self.length_squared() * rhs.length_squared())
  let cos_angle = if denom <= 0.0F { 0.0F } else { self.dot(rhs) / denom }
  math_acos_approx(cos_angle) * math_signum(self.perp_dot(rhs))
}

///|
pub(all) struct Vec3 {
  mut x : Float
  mut y : Float
  mut z : Float
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
pub fn Vec3::distance(self : Vec3, other : Vec3) -> Float {
  self.sub(other).length()
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
pub fn Vec3::normalize(self : Vec3) -> Vec3 {
  self.mul_scalar(1.0F / self.length())
}

///|
/// Returns any vector orthonormal to this unit vector, following glam's
/// Pixar orthonormal-basis implementation used by Bevy.
pub fn Vec3::any_orthonormal_vector(self : Vec3) -> Vec3 {
  let sign = math_signum(self.z)
  let a = -1.0F / (sign + self.z)
  let b = self.x * self.y * a
  Vec3::new(b, sign + self.y * self.y * a, -self.y)
}

///|
pub fn Vec3::max_element(self : Vec3) -> Float {
  let max_xy = if self.x > self.y { self.x } else { self.y }
  if max_xy > self.z {
    max_xy
  } else {
    self.z
  }
}

///|
pub fn Vec3::min_element(self : Vec3) -> Float {
  let min_xy = if self.x < self.y { self.x } else { self.y }
  if min_xy < self.z {
    min_xy
  } else {
    self.z
  }
}

///|
pub fn Vec3::floor(self : Vec3) -> Vec3 {
  Vec3::new(self.x.floor(), self.y.floor(), self.z.floor())
}

///|
pub fn Vec3::ceil(self : Vec3) -> Vec3 {
  Vec3::new(self.x.ceil(), self.y.ceil(), self.z.ceil())
}

///|
pub fn Vec3::zxy(self : Vec3) -> Vec3 {
  Vec3::new(self.z, self.x, self.y)
}

///|
/// Smoothly nudge this vector towards `target` at a frame-rate independent decay rate.
pub fn Vec3::smooth_nudge(
  self : Vec3,
  target : Vec3,
  decay_rate : Float,
  delta : Float,
) -> Unit {
  if decay_rate <= 0.0F || delta <= 0.0F {
    return
  }
  let factor = 1.0F - pow(2.718281828459045F, -decay_rate * delta)
  if factor <= 0.0F {
    return
  }
  let current = Vec3::new(self.x, self.y, self.z)
  let next = current.add(target.sub(current).mul_scalar(factor))
  self.x = next.x
  self.y = next.y
  self.z = next.z
}

///|
pub(all) struct Vec4 {
  mut x : Float
  mut y : Float
  mut z : Float
  mut w : Float
} derive(Eq)

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
fn math_signum(value : Float) -> Float {
  if value != value {
    value
  } else if value < 0.0F {
    -1.0F
  } else {
    1.0F
  }
}

///|
fn math_acos_approx(value : Float) -> Float {
  let nonnegative = value >= 0.0F
  let x = abs(value)
  let omx = if 1.0F - x < 0.0F { 0.0F } else { 1.0F - x }
  let root = sqrt(omx)
  let mut result = (
      (
        (
          (
            ((-0.0012624911F * x + 0.00667009F) * x - 0.017088126F) * x +
            0.03089188F
          ) *
          x -
          0.050174303F
        ) *
        x +
        0.08897899F
      ) *
      x -
      0.2145988F
    ) *
    x +
    1.5707963F
  result = result * root
  if nonnegative {
    result
  } else {
    pi() - result
  }
}

///|
pub(all) enum EulerRot {
  ZYX
  ZXY
  YXZ
  YZX
  XYZ
  XZY
  ZYXEx
  ZXYEx
  YXZEx
  YZXEx
  XYZEx
  XZYEx
} derive(Eq, Debug, ToJson, FromJson)

///|
/// Quaternion (x, y, z, w).
pub(all) struct Quat {
  mut x : Float
  mut y : Float
  mut z : Float
  mut w : Float
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
pub impl ToJson for Vec2 with to_json(self) {
  (self.x, self.y).to_json()
}

///|
pub impl @json.FromJson for Vec2 with from_json(json, path) {
  let (x, y) : (Float, Float) = @json.from_json(json, path~)
  Vec2::new(x, y)
}

///|
pub impl ToJson for Vec3 with to_json(self) {
  (self.x, self.y, self.z).to_json()
}

///|
pub impl @json.FromJson for Vec3 with from_json(json, path) {
  let (x, y, z) : (Float, Float, Float) = @json.from_json(json, path~)
  Vec3::new(x, y, z)
}

///|
pub impl ToJson for Vec4 with to_json(self) {
  (self.x, self.y, self.z, self.w).to_json()
}

///|
pub impl @json.FromJson for Vec4 with from_json(json, path) {
  let (x, y, z, w) : (Float, Float, Float, Float) = @json.from_json(json, path~)
  Vec4::new(x, y, z, w)
}

///|
pub impl ToJson for IVec2 with to_json(self) {
  (self.x, self.y).to_json()
}

///|
pub impl @json.FromJson for IVec2 with from_json(json, path) {
  let (x, y) : (Int, Int) = @json.from_json(json, path~)
  IVec2::new(x, y)
}

///|
pub impl ToJson for UVec2 with to_json(self) {
  (self.x, self.y).to_json()
}

///|
pub impl @json.FromJson for UVec2 with from_json(json, path) {
  let (x, y) : (Int, Int) = @json.from_json(json, path~)
  UVec2::new(x, y)
}

///|
pub impl ToJson for Quat with to_json(self) {
  (self.x, self.y, self.z, self.w).to_json()
}

///|
pub impl @json.FromJson for Quat with from_json(json, path) {
  let (x, y, z, w) : (Float, Float, Float, Float) = @json.from_json(json, path~)
  Quat::new(x, y, z, w)
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
pub fn Quat::from_euler(
  order : EulerRot,
  first : Float,
  second : Float,
  third : Float,
) -> Quat {
  match order {
    EulerRot::XYZ =>
      Quat::from_rotation_x(first)
      .mul(Quat::from_rotation_y(second))
      .mul(Quat::from_rotation_z(third))
      .normalize()
    EulerRot::XZY =>
      Quat::from_rotation_x(first)
      .mul(Quat::from_rotation_z(second))
      .mul(Quat::from_rotation_y(third))
      .normalize()
    EulerRot::YXZ =>
      Quat::from_rotation_y(first)
      .mul(Quat::from_rotation_x(second))
      .mul(Quat::from_rotation_z(third))
      .normalize()
    EulerRot::YZX =>
      Quat::from_rotation_y(first)
      .mul(Quat::from_rotation_z(second))
      .mul(Quat::from_rotation_x(third))
      .normalize()
    EulerRot::ZXY =>
      Quat::from_rotation_z(first)
      .mul(Quat::from_rotation_x(second))
      .mul(Quat::from_rotation_y(third))
      .normalize()
    EulerRot::ZYX =>
      Quat::from_rotation_z(first)
      .mul(Quat::from_rotation_y(second))
      .mul(Quat::from_rotation_x(third))
      .normalize()
    EulerRot::XYZEx => Quat::from_euler(EulerRot::ZYX, third, second, first)
    EulerRot::XZYEx => Quat::from_euler(EulerRot::YZX, third, second, first)
    EulerRot::YXZEx => Quat::from_euler(EulerRot::ZXY, third, second, first)
    EulerRot::YZXEx => Quat::from_euler(EulerRot::XZY, third, second, first)
    EulerRot::ZXYEx => Quat::from_euler(EulerRot::YXZ, third, second, first)
    EulerRot::ZYXEx => Quat::from_euler(EulerRot::XYZ, third, second, first)
  }
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
/// Gets the minimal rotation for transforming normalized vector `from` to
/// normalized vector `to`, matching glam/Bevy `Quat::from_rotation_arc`.
pub fn Quat::from_rotation_arc(from : Vec3, to : Vec3) -> Quat {
  let one_minus_eps = 1.0F - 2.0F * 1.1920929e-7F
  let dot = from.dot(to)
  if dot > one_minus_eps {
    Quat::identity()
  } else if dot < -one_minus_eps {
    Quat::from_axis_angle(from.any_orthonormal_vector(), pi())
  } else {
    let c = from.cross(to)
    Quat::new(c.x, c.y, c.z, 1.0F + dot).normalize()
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
pub fn Quat::inverse(self : Quat) -> Quat {
  Quat::{ x: -self.x, y: -self.y, z: -self.z, w: self.w }
}

///|
pub fn Quat::mul_vec3(self : Quat, value : Vec3) -> Vec3 {
  let qv = Vec3::new(self.x, self.y, self.z)
  let t = qv.cross(value).mul_scalar(2.0F)
  value.add(t.mul_scalar(self.w)).add(qv.cross(t))
}

///|
pub fn Quat::to_axis_angle(self : Quat) -> (Vec3, Float) {
  let v = Vec3::new(self.x, self.y, self.z)
  let length = v.length()
  if length >= 1.0e-8F {
    (v.div_scalar(length), 2.0F * atan2(length, self.w))
  } else {
    (Vec3::new(1.0F, 0.0F, 0.0F), 0.0F)
  }
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
pub fn Quat::lerp(self : Quat, other : Quat, s : Float) -> Quat {
  let factor = if s < 0.0F { 0.0F } else if s > 1.0F { 1.0F } else { s }
  let dot = self.x * other.x +
    self.y * other.y +
    self.z * other.z +
    self.w * other.w
  let other_adjusted = if dot < 0.0F {
    Quat::{ x: -other.x, y: -other.y, z: -other.z, w: -other.w }
  } else {
    other
  }
  Quat::{
    x: self.x + (other_adjusted.x - self.x) * factor,
    y: self.y + (other_adjusted.y - self.y) * factor,
    z: self.z + (other_adjusted.z - self.z) * factor,
    w: self.w + (other_adjusted.w - self.w) * factor,
  }.normalize()
}

///|
pub fn Quat::to_euler(self : Quat, order : EulerRot) -> (Float, Float, Float) {
  match order {
    EulerRot::XYZ
    | EulerRot::XZY
    | EulerRot::YXZ
    | EulerRot::YZX
    | EulerRot::ZXY
    | EulerRot::ZYX => quat_to_euler_intrinsic(self.normalize(), order)
    EulerRot::XYZEx => {
      let (third, second, first) = quat_to_euler_intrinsic(
        self.normalize(),
        EulerRot::ZYX,
      )
      (first, second, third)
    }
    EulerRot::XZYEx => {
      let (third, second, first) = quat_to_euler_intrinsic(
        self.normalize(),
        EulerRot::YZX,
      )
      (first, second, third)
    }
    EulerRot::YXZEx => {
      let (third, second, first) = quat_to_euler_intrinsic(
        self.normalize(),
        EulerRot::ZXY,
      )
      (first, second, third)
    }
    EulerRot::YZXEx => {
      let (third, second, first) = quat_to_euler_intrinsic(
        self.normalize(),
        EulerRot::XZY,
      )
      (first, second, third)
    }
    EulerRot::ZXYEx => {
      let (third, second, first) = quat_to_euler_intrinsic(
        self.normalize(),
        EulerRot::YXZ,
      )
      (first, second, third)
    }
    EulerRot::ZYXEx => {
      let (third, second, first) = quat_to_euler_intrinsic(
        self.normalize(),
        EulerRot::XYZ,
      )
      (first, second, third)
    }
  }
}

///|
fn quat_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn quat_clamp(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn quat_rotation_matrix(
  rotation : Quat,
) -> (Float, Float, Float, Float, Float, Float, Float, Float, Float) {
  let x = rotation.x
  let y = rotation.y
  let z = rotation.z
  let w = rotation.w
  let xx = x * x
  let yy = y * y
  let zz = z * z
  let xy = x * y
  let xz = x * z
  let yz = y * z
  let wx = w * x
  let wy = w * y
  let wz = w * z
  (
    1.0F - 2.0F * (yy + zz),
    2.0F * (xy - wz),
    2.0F * (xz + wy),
    2.0F * (xy + wz),
    1.0F - 2.0F * (xx + zz),
    2.0F * (yz - wx),
    2.0F * (xz - wy),
    2.0F * (yz + wx),
    1.0F - 2.0F * (xx + yy),
  )
}

///|
fn quat_to_euler_intrinsic(
  rotation : Quat,
  order : EulerRot,
) -> (Float, Float, Float) {
  let (m00, m01, m02, m10, m11, m12, m20, m21, m22) = quat_rotation_matrix(
    rotation,
  )
  let epsilon = 0.9999999F
  match order {
    EulerRot::XYZ => {
      let second = Float::from_double(
        @coremath.asin(quat_clamp(m02, -1.0F, 1.0F).to_double()),
      )
      if quat_abs(m02) < epsilon {
        (atan2(-m12, m22), second, atan2(-m01, m00))
      } else {
        (atan2(m21, m11), second, 0.0F)
      }
    }
    EulerRot::XZY => {
      let second = Float::from_double(
        @coremath.asin(quat_clamp(-m01, -1.0F, 1.0F).to_double()),
      )
      if quat_abs(m01) < epsilon {
        (atan2(m21, m11), second, atan2(m02, m00))
      } else {
        (atan2(-m12, m22), second, 0.0F)
      }
    }
    EulerRot::YXZ => {
      let second = Float::from_double(
        @coremath.asin(quat_clamp(-m12, -1.0F, 1.0F).to_double()),
      )
      if quat_abs(m12) < epsilon {
        (atan2(m02, m22), second, atan2(m10, m11))
      } else {
        (atan2(-m20, m00), second, 0.0F)
      }
    }
    EulerRot::YZX => {
      let second = Float::from_double(
        @coremath.asin(quat_clamp(m10, -1.0F, 1.0F).to_double()),
      )
      if quat_abs(m10) < epsilon {
        (atan2(-m20, m00), second, atan2(-m12, m11))
      } else {
        (atan2(m02, m22), second, 0.0F)
      }
    }
    EulerRot::ZXY => {
      let second = Float::from_double(
        @coremath.asin(quat_clamp(m21, -1.0F, 1.0F).to_double()),
      )
      if quat_abs(m21) < epsilon {
        (atan2(-m01, m11), second, atan2(-m20, m22))
      } else {
        (atan2(m10, m00), second, 0.0F)
      }
    }
    EulerRot::ZYX => {
      let second = Float::from_double(
        @coremath.asin(quat_clamp(-m20, -1.0F, 1.0F).to_double()),
      )
      if quat_abs(m20) < epsilon {
        (atan2(m10, m00), second, atan2(m21, m22))
      } else {
        (atan2(-m01, m11), second, 0.0F)
      }
    }
    _ => (0.0F, 0.0F, 0.0F)
  }
}

///|
