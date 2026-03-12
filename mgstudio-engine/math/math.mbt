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
pub fn Vec2::normalize_or_zero(self : Vec2) -> Vec2 {
  let len_sq = self.length_squared()
  if len_sq <= 1.0e-12F {
    return Vec2::zero()
  }
  let inv_len = 1.0F / sqrt(len_sq)
  self.mul_scalar(inv_len)
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
pub fn Vec3::normalize_or_zero(self : Vec3) -> Vec3 {
  let len_sq = self.length_squared()
  if len_sq <= 1.0e-12F {
    return Vec3::zero()
  }
  let inv_len = 1.0F / sqrt(len_sq)
  self.mul_scalar(inv_len)
}

///|
pub(all) enum CompassOctant {
  North
  NorthEast
  East
  SouthEast
  South
  SouthWest
  West
  NorthWest
} derive(Eq, Show)

///|
pub(all) struct Cuboid {
  half_size : Vec3
}

///|
pub impl Default for Cuboid with default() {
  Cuboid::{ half_size: Vec3::splat(0.5F) }
}

///|
pub fn Cuboid::new(
  x_length : Float,
  y_length : Float,
  z_length : Float,
) -> Cuboid {
  Cuboid::from_size(Vec3::new(x_length, y_length, z_length))
}

///|
pub fn Cuboid::from_size(size : Vec3) -> Cuboid {
  Cuboid::{ half_size: size.mul_scalar(0.5F) }
}

///|
pub fn Cuboid::from_corners(point1 : Vec3, point2 : Vec3) -> Cuboid {
  Cuboid::from_size(
    Vec3::new(
      cuboid_abs_float(point2.x - point1.x),
      cuboid_abs_float(point2.y - point1.y),
      cuboid_abs_float(point2.z - point1.z),
    ),
  )
}

///|
pub fn Cuboid::from_length(length : Float) -> Cuboid {
  Cuboid::{ half_size: Vec3::splat(length * 0.5F) }
}

///|
pub fn Cuboid::size(self : Cuboid) -> Vec3 {
  self.half_size.mul_scalar(2.0F)
}

///|
pub fn Cuboid::sample_interior(self : Cuboid, rng : @random.Rand) -> Vec3 {
  Vec3::new(
    cuboid_sample_axis(rng, self.half_size.x),
    cuboid_sample_axis(rng, self.half_size.y),
    cuboid_sample_axis(rng, self.half_size.z),
  )
}

///|
fn cuboid_abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn cuboid_sample_axis(rng : @random.Rand, half_extent : Float) -> Float {
  (rng.float() * 2.0F - 1.0F) * half_extent
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
pub fn pi() -> Float {
  Float::from_double(@coremath.PI)
}

///|
pub fn pi_half() -> Float {
  Float::from_double(@coremath.PI / 2.0)
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
} derive(Eq, Show, ToJson, FromJson)

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
pub impl ToJson for Cuboid with to_json(self) {
  self.half_size.to_json()
}

///|
pub impl @json.FromJson for Cuboid with from_json(json, path) {
  Cuboid::{ half_size: @json.from_json(json, path~) }
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
pub impl ToJson for URect with to_json(self) {
  (self.min, self.max).to_json()
}

///|
pub impl @json.FromJson for URect with from_json(json, path) {
  let (min, max) : (UVec2, UVec2) = @json.from_json(json, path~)
  URect::new(min, max)
}

///|
pub impl ToJson for Rect with to_json(self) {
  (self.min, self.max).to_json()
}

///|
pub impl @json.FromJson for Rect with from_json(json, path) {
  let (min, max) : (Vec2, Vec2) = @json.from_json(json, path~)
  Rect::new(min, max)
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
fn quat_rotate_vec3(rotation : Quat, value : Vec3) -> Vec3 {
  let qv = Vec3::new(rotation.x, rotation.y, rotation.z)
  let t = qv.cross(value).mul_scalar(2.0F)
  value.add(t.mul_scalar(rotation.w)).add(qv.cross(t))
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
fn vec3_try_normalize(value : Vec3) -> Vec3? {
  let len_sq = value.length_squared()
  if len_sq <= 1.0e-12F {
    None
  } else {
    Some(value.mul_scalar(1.0F / sqrt(len_sq)))
  }
}

///|
fn vec3_reject_from_normalized(value : Vec3, normal : Vec3) -> Vec3 {
  value.sub(normal.mul_scalar(value.dot(normal)))
}

///|
fn vec3_any_orthonormal_vector(normal : Vec3) -> Vec3 {
  let axis = if quat_abs(normal.x) > quat_abs(normal.z) {
    Vec3::new(-normal.y, normal.x, 0.0F)
  } else {
    Vec3::new(0.0F, -normal.z, normal.y)
  }
  match vec3_try_normalize(axis) {
    Some(value) => value
    None => Vec3::new(1.0F, 0.0F, 0.0F)
  }
}

///|
fn quat_from_rotation_arc(from : Vec3, to : Vec3) -> Quat {
  let from = match vec3_try_normalize(from) {
    Some(value) => value
    None => Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let to = match vec3_try_normalize(to) {
    Some(value) => value
    None => Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let dot = from.dot(to)
  if dot >= 1.0F - 1.0e-6F {
    return Quat::identity()
  }
  if dot <= -1.0F + 1.0e-6F {
    return Quat::from_axis_angle(vec3_any_orthonormal_vector(from), pi())
  }
  Quat::{
    x: from.y * to.z - from.z * to.y,
    y: from.z * to.x - from.x * to.z,
    z: from.x * to.y - from.y * to.x,
    w: 1.0F + dot,
  }.normalize()
}

///|
pub(all) struct Transform {
  mut translation : Vec3
  mut rotation : Quat
  mut scale : Vec3
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
pub fn Transform::from_translation(translation : Vec3) -> Transform {
  Transform::new(translation, Quat::identity(), Vec3::splat(1.0F))
}

///|
pub fn Transform::from_rotation(rotation : Quat) -> Transform {
  Transform::new(Vec3::zero(), rotation, Vec3::splat(1.0F))
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
pub fn Transform::local_x(self : Transform) -> Vec3 {
  quat_rotate_vec3(self.rotation, Vec3::new(1.0F, 0.0F, 0.0F)).normalize_or_zero()
}

///|
pub fn Transform::left(self : Transform) -> Vec3 {
  self.local_x().neg()
}

///|
pub fn Transform::right(self : Transform) -> Vec3 {
  self.local_x()
}

///|
pub fn Transform::local_y(self : Transform) -> Vec3 {
  quat_rotate_vec3(self.rotation, Vec3::new(0.0F, 1.0F, 0.0F)).normalize_or_zero()
}

///|
pub fn Transform::up(self : Transform) -> Vec3 {
  self.local_y()
}

///|
pub fn Transform::down(self : Transform) -> Vec3 {
  self.local_y().neg()
}

///|
pub fn Transform::local_z(self : Transform) -> Vec3 {
  quat_rotate_vec3(self.rotation, Vec3::new(0.0F, 0.0F, 1.0F)).normalize_or_zero()
}

///|
pub fn Transform::forward(self : Transform) -> Vec3 {
  self.local_z().neg()
}

///|
pub fn Transform::back(self : Transform) -> Vec3 {
  self.local_z()
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

///|
pub fn Transform::looking_to(
  self : Transform,
  direction : Vec3,
  up : Vec3,
) -> Transform {
  let forward = direction.normalize_or_zero()
  if forward.length_squared() <= 1.0e-12F {
    return self.looking_at(
      self.translation.add(Vec3::new(0.0F, 0.0F, -1.0F)),
      Vec3::new(0.0F, 1.0F, 0.0F),
    )
  }
  let up_hint = if up.length_squared() <= 1.0e-12F {
    Vec3::new(0.0F, 1.0F, 0.0F)
  } else {
    up
  }
  self.looking_at(self.translation.add(forward), up_hint)
}

///|
pub fn Transform::rotate(self : Transform, rotation : Quat) -> Unit {
  self.rotation = rotation.mul(self.rotation).normalize()
}

///|
pub fn Transform::translate_around(
  self : Transform,
  point : Vec3,
  rotation : Quat,
) -> Unit {
  self.translation = point.add(
    quat_rotate_vec3(rotation.normalize(), self.translation.sub(point)),
  )
}

///|
pub fn Transform::rotate_around(
  self : Transform,
  point : Vec3,
  rotation : Quat,
) -> Unit {
  self.translate_around(point, rotation)
  self.rotate(rotation)
}

///|
pub fn Transform::aligned_by(
  self : Transform,
  main_axis : Vec3,
  main_direction : Vec3,
  secondary_axis : Vec3,
  secondary_direction : Vec3,
) -> Transform {
  let aligned = Transform::{
    translation: self.translation,
    rotation: self.rotation,
    scale: self.scale,
  }
  aligned.align(main_axis, main_direction, secondary_axis, secondary_direction)
  aligned
}

///|
/// Based on Bevy's `Transform::align` algorithm in `bevy_transform`.
pub fn Transform::align(
  self : Transform,
  main_axis : Vec3,
  main_direction : Vec3,
  secondary_axis : Vec3,
  secondary_direction : Vec3,
) -> Unit {
  let main_axis = match vec3_try_normalize(main_axis) {
    Some(value) => value
    None => Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let main_direction = match vec3_try_normalize(main_direction) {
    Some(value) => value
    None => Vec3::new(1.0F, 0.0F, 0.0F)
  }
  let secondary_axis = match vec3_try_normalize(secondary_axis) {
    Some(value) => value
    None => Vec3::new(0.0F, 1.0F, 0.0F)
  }
  let secondary_direction = match vec3_try_normalize(secondary_direction) {
    Some(value) => value
    None => Vec3::new(0.0F, 1.0F, 0.0F)
  }

  let first_rotation = quat_from_rotation_arc(main_axis, main_direction)
  let secondary_image = quat_rotate_vec3(first_rotation, secondary_axis)
  let secondary_image_ortho = vec3_try_normalize(
    vec3_reject_from_normalized(secondary_image, main_direction),
  )
  let secondary_direction_ortho = vec3_try_normalize(
    vec3_reject_from_normalized(secondary_direction, main_direction),
  )

  self.rotation = match (secondary_image_ortho, secondary_direction_ortho) {
    (Some(secondary_image_ortho), Some(secondary_direction_ortho)) =>
      quat_from_rotation_arc(secondary_image_ortho, secondary_direction_ortho)
      .mul(first_rotation)
      .normalize()
    _ => first_rotation
  }
}

///|
pub fn Transform::rotate_y(self : Transform, angle : Float) -> Unit {
  self.rotate(Quat::from_rotation_y(angle))
}

///|
pub fn Transform::rotate_z(self : Transform, angle : Float) -> Unit {
  self.rotate(Quat::from_rotation_z(angle))
}
