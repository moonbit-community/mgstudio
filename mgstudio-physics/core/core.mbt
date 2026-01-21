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
pub type Real = Float

///|
const EPSILON : Real = 1.0e-6F

///|
fn sin(value : Real) -> Real {
  Float::from_double(@math.sin(value.to_double()))
}

///|
fn cos(value : Real) -> Real {
  Float::from_double(@math.cos(value.to_double()))
}

///|
fn atan2(y : Real, x : Real) -> Real {
  Float::from_double(@math.atan2(y.to_double(), x.to_double()))
}

///|
fn sqrt(value : Real) -> Real {
  if value <= 0.0F {
    0.0F
  } else {
    let mut x = value
    for _ in 0..<8 {
      x = 0.5F * (x + value / x)
    }
    x
  }
}

///|
fn pi_value() -> Real {
  Float::from_double(@math.PI)
}

///|
fn min(a : Real, b : Real) -> Real {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max(a : Real, b : Real) -> Real {
  if a > b {
    a
  } else {
    b
  }
}

///|
pub struct Vec2 {
  x : Real
  y : Real
}

///|
pub fn Vec2::new(x : Real, y : Real) -> Vec2 {
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
pub fn Vec2::sub(self : Vec2, other : Vec2) -> Vec2 {
  Vec2::new(self.x - other.x, self.y - other.y)
}

///|
pub fn Vec2::dot(self : Vec2, other : Vec2) -> Real {
  self.x * other.x + self.y * other.y
}

///|
pub fn Vec2::cross(self : Vec2, other : Vec2) -> Real {
  self.x * other.y - self.y * other.x
}

///|
pub fn Vec2::length_squared(self : Vec2) -> Real {
  self.dot(self)
}

///|
pub fn Vec2::length(self : Vec2) -> Real {
  sqrt(self.length_squared())
}

///|
pub fn Vec2::normalize(self : Vec2) -> Vec2 {
  let len = self.length()
  if len <= EPSILON {
    Vec2::zero()
  } else {
    Vec2::new(self.x / len, self.y / len)
  }
}

///|
pub fn pi() -> Real {
  pi_value()
}

///|
pub fn two_pi() -> Real {
  pi_value() * 2.0F
}

///|
pub fn abs(value : Real) -> Real {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
pub struct Rot2 {
  sin : Real
  cos : Real
}

///|
pub fn Rot2::identity() -> Rot2 {
  Rot2::{ sin: 0.0F, cos: 1.0F }
}

///|
pub fn Rot2::from_angle(angle : Real) -> Rot2 {
  Rot2::{ sin: sin(angle), cos: cos(angle) }
}

///|
pub fn Rot2::angle(self : Rot2) -> Real {
  atan2(self.sin, self.cos)
}

///|
pub fn Rot2::rotate_vec2(self : Rot2, v : Vec2) -> Vec2 {
  Vec2::new(self.cos * v.x - self.sin * v.y, self.sin * v.x + self.cos * v.y)
}

///|
pub fn Rot2::mul(self : Rot2, other : Rot2) -> Rot2 {
  Rot2::{
    sin: self.sin * other.cos + self.cos * other.sin,
    cos: self.cos * other.cos - self.sin * other.sin,
  }
}

///|
pub fn Rot2::inverse(self : Rot2) -> Rot2 {
  Rot2::{ sin: -self.sin, cos: self.cos }
}

///|
pub fn rotation_from_angle(angle : Real) -> Rot2 {
  Rot2::from_angle(angle)
}

///|
pub struct Isometry2 {
  translation : Vec2
  rotation : Rot2
}

///|
pub fn Isometry2::identity() -> Isometry2 {
  Isometry2::{ translation: Vec2::zero(), rotation: Rot2::identity() }
}

///|
pub fn Isometry2::new(translation : Vec2, rotation : Rot2) -> Isometry2 {
  Isometry2::{ translation, rotation }
}

///|
pub fn Isometry2::from_translation(translation : Vec2) -> Isometry2 {
  Isometry2::new(translation, Rot2::identity())
}

///|
pub fn Isometry2::mul(self : Isometry2, other : Isometry2) -> Isometry2 {
  let rotated = self.rotation.rotate_vec2(other.translation)
  Isometry2::new(
    self.translation.add(rotated),
    self.rotation.mul(other.rotation),
  )
}

///|
pub fn Isometry2::inverse(self : Isometry2) -> Isometry2 {
  let inv_rot = self.rotation.inverse()
  let neg_translation = Vec2::new(-self.translation.x, -self.translation.y)
  let inv_translation = inv_rot.rotate_vec2(neg_translation)
  Isometry2::new(inv_translation, inv_rot)
}

///|
pub fn Isometry2::transform_point(self : Isometry2, point : Vec2) -> Vec2 {
  self.rotation.rotate_vec2(point).add(self.translation)
}

///|
pub struct Aabb {
  mins : Vec2
  maxs : Vec2
}

///|
pub fn Aabb::new(mins : Vec2, maxs : Vec2) -> Aabb {
  Aabb::{ mins, maxs }
}

///|
pub fn Aabb::from_points(a : Vec2, b : Vec2) -> Aabb {
  Aabb::new(
    Vec2::new(min(a.x, b.x), min(a.y, b.y)),
    Vec2::new(max(a.x, b.x), max(a.y, b.y)),
  )
}

///|
pub fn Aabb::combine(self : Aabb, other : Aabb) -> Aabb {
  Aabb::new(
    Vec2::new(min(self.mins.x, other.mins.x), min(self.mins.y, other.mins.y)),
    Vec2::new(max(self.maxs.x, other.maxs.x), max(self.maxs.y, other.maxs.y)),
  )
}

///|
pub fn Aabb::contains_point(self : Aabb, point : Vec2) -> Bool {
  point.x >= self.mins.x &&
  point.x <= self.maxs.x &&
  point.y >= self.mins.y &&
  point.y <= self.maxs.y
}

///|
pub struct MassProperties {
  mass : Real
  inv_mass : Real
  inertia : Real
  inv_inertia : Real
  center_of_mass : Vec2
}

///|
pub fn MassProperties::new(
  mass : Real,
  inertia : Real,
  center_of_mass : Vec2,
) -> MassProperties {
  let inv_mass = if mass <= EPSILON { 0.0F } else { 1.0F / mass }
  let inv_inertia = if inertia <= EPSILON { 0.0F } else { 1.0F / inertia }
  MassProperties::{ mass, inv_mass, inertia, inv_inertia, center_of_mass }
}
