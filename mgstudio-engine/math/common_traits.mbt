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
pub(open) trait StableInterpolate {
  fn stable_interpolate(Self, Self, Float) -> Self
}

///|
pub(open) trait VectorSpace {
  fn zero() -> Self
  fn add(self : Self, other : Self) -> Self
  fn sub(self : Self, other : Self) -> Self
  fn neg(self : Self) -> Self
  fn mul_scalar(self : Self, scalar : Float) -> Self
  fn div_scalar(self : Self, scalar : Float) -> Self
}

///|
pub fn[V : VectorSpace] vector_space_lerp(start : V, end_ : V, t : Float) -> V {
  start.mul_scalar(1.0F - t).add(end_.mul_scalar(t))
}

///|
pub(all) struct WithDerivative[T] {
  value : T
  derivative : T
}

///|
pub(all) struct WithTwoDerivatives[T] {
  value : T
  derivative : T
  second_derivative : T
}

///|
pub impl VectorSpace for Float with fn zero() {
  0.0F
}

///|
pub impl VectorSpace for Float with fn add(self, other) {
  self + other
}

///|
pub impl VectorSpace for Float with fn sub(self, other) {
  self - other
}

///|
pub impl VectorSpace for Float with fn neg(self) {
  -self
}

///|
pub impl VectorSpace for Float with fn mul_scalar(self, scalar) {
  self * scalar
}

///|
pub impl VectorSpace for Float with fn div_scalar(self, scalar) {
  self / scalar
}

///|
pub impl VectorSpace for Vec2 with fn zero() {
  Vec2::zero()
}

///|
pub impl VectorSpace for Vec2 with fn add(self, other) {
  self.add(other)
}

///|
pub impl VectorSpace for Vec2 with fn sub(self, other) {
  self.sub(other)
}

///|
pub impl VectorSpace for Vec2 with fn neg(self) {
  Vec2::new(-self.x, -self.y)
}

///|
pub impl VectorSpace for Vec2 with fn mul_scalar(self, scalar) {
  self.mul_scalar(scalar)
}

///|
pub impl VectorSpace for Vec2 with fn div_scalar(self, scalar) {
  self.mul_scalar(1.0F / scalar)
}

///|
pub impl VectorSpace for Vec3 with fn zero() {
  Vec3::zero()
}

///|
pub impl VectorSpace for Vec3 with fn add(self, other) {
  self.add(other)
}

///|
pub impl VectorSpace for Vec3 with fn sub(self, other) {
  self.sub(other)
}

///|
pub impl VectorSpace for Vec3 with fn neg(self) {
  self.neg()
}

///|
pub impl VectorSpace for Vec3 with fn mul_scalar(self, scalar) {
  self.mul_scalar(scalar)
}

///|
pub impl VectorSpace for Vec3 with fn div_scalar(self, scalar) {
  self.mul_scalar(1.0F / scalar)
}

///|
pub impl VectorSpace for Vec4 with fn zero() {
  Vec4::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
pub impl VectorSpace for Vec4 with fn add(self, other) {
  Vec4::new(
    self.x + other.x,
    self.y + other.y,
    self.z + other.z,
    self.w + other.w,
  )
}

///|
pub impl VectorSpace for Vec4 with fn sub(self, other) {
  Vec4::new(
    self.x - other.x,
    self.y - other.y,
    self.z - other.z,
    self.w - other.w,
  )
}

///|
pub impl VectorSpace for Vec4 with fn neg(self) {
  Vec4::new(-self.x, -self.y, -self.z, -self.w)
}

///|
pub impl VectorSpace for Vec4 with fn mul_scalar(self, scalar) {
  Vec4::new(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar)
}

///|
pub impl VectorSpace for Vec4 with fn div_scalar(self, scalar) {
  Vec4::new(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar)
}

///|
pub impl StableInterpolate for Float with fn stable_interpolate(self, other, t) {
  self + (other - self) * t
}

///|
pub impl StableInterpolate for Vec2 with fn stable_interpolate(self, other, t) {
  self.add(other.sub(self).mul_scalar(t))
}

///|
pub impl StableInterpolate for Vec3 with fn stable_interpolate(self, other, t) {
  self.add(other.sub(self).mul_scalar(t))
}

///|
pub impl StableInterpolate for Vec4 with fn stable_interpolate(self, other, t) {
  Vec4::new(
    self.x + (other.x - self.x) * t,
    self.y + (other.y - self.y) * t,
    self.z + (other.z - self.z) * t,
    self.w + (other.w - self.w) * t,
  )
}

///|
pub impl StableInterpolate for Quat with fn stable_interpolate(self, other, t) {
  self.lerp(other, t)
}
