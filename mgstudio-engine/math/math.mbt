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
pub fn Vec3::mul(self : Vec3, other : Vec3) -> Vec3 {
  Vec3::new(self.x * other.x, self.y * other.y, self.z * other.z)
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
