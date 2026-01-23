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
/// Geometric primitives (subset).
///
/// Ported from upstream `zeno/src/geometry.rs` (Apache-2.0 OR MIT).

///|
/// Two dimensional vector.
pub struct Vector {
  x : Double
  y : Double
}

///|
pub type Point = Vector

///|
pub fn Vector::new(x : Double, y : Double) -> Vector {
  Vector::{ x, y }
}

///|
pub fn Vector::zero() -> Vector {
  Vector::new(0.0, 0.0)
}

///|
pub fn Vector::x(self : Vector) -> Double {
  self.x
}

///|
pub fn Vector::y(self : Vector) -> Double {
  self.y
}

///|
pub fn Vector::length_squared(self : Vector) -> Double {
  self.x * self.x + self.y * self.y
}

///|
pub fn Vector::length(self : Vector) -> Double {
  (self.x * self.x + self.y * self.y).sqrt()
}

///|
pub fn Vector::distance_to(self : Vector, other : Vector) -> Double {
  (self - other).length()
}

///|
pub fn Vector::dot(self : Vector, other : Vector) -> Double {
  self.x * other.x + self.y * other.y
}

///|
pub fn Vector::cross(self : Vector, other : Vector) -> Double {
  self.x * other.y - self.y * other.x
}

///|
pub fn Vector::normalize(self : Vector) -> Vector {
  let length = self.length()
  if length == 0.0 {
    return Vector::zero()
  }
  let inv = 1.0 / length
  Vector::new(self.x * inv, self.y * inv)
}

///|
pub fn Vector::nearly_eq_by(
  self : Vector,
  other : Vector,
  epsilon : Double,
) -> Bool {
  (self.x - other.x).abs() < epsilon && (self.y - other.y).abs() < epsilon
}

///|
/// Equivalent to upstream `Vector::nearly_eq` (uses f32 epsilon).
pub fn Vector::nearly_eq(self : Vector, other : Vector) -> Bool {
  self.nearly_eq_by(other, 1.1920929e-7)
}

///|
pub fn Vector::scale(self : Vector, s : Double) -> Vector {
  Vector::new(self.x * s, self.y * s)
}

///|
pub fn Vector::div_scalar(self : Vector, s : Double) -> Vector {
  let inv = 1.0 / s
  Vector::new(self.x * inv, self.y * inv)
}

///|
pub fn Vector::floor(self : Vector) -> Vector {
  Vector::new(self.x.floor(), self.y.floor())
}

///|
pub fn Vector::ceil(self : Vector) -> Vector {
  Vector::new(self.x.ceil(), self.y.ceil())
}

///|
/// Upstream `geometry.rs::normal(start,end)`.
pub fn normal(start : Vector, end : Vector) -> Vector {
  Vector::new(end.y - start.y, -(end.x - start.x)).normalize()
}

///|
pub impl Sub for Vector with sub(self, rhs) {
  Vector::new(self.x() - rhs.x(), self.y() - rhs.y())
}

///|
pub impl Mul for Vector with mul(self, rhs) {
  Vector::new(self.x() * rhs.x(), self.y() * rhs.y())
}

///|
pub impl Div for Vector with div(self, rhs) {
  Vector::new(self.x() / rhs.x(), self.y() / rhs.y())
}

///|
pub impl Neg for Vector with neg(self) {
  Vector::new(-self.x(), -self.y())
}
