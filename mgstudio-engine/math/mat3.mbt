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
pub struct Mat3 {
  x_axis : Vec3
  y_axis : Vec3
  z_axis : Vec3
}

///|
pub fn Mat3::identity() -> Mat3 {
  Mat3::{
    x_axis: Vec3::new(1.0F, 0.0F, 0.0F),
    y_axis: Vec3::new(0.0F, 1.0F, 0.0F),
    z_axis: Vec3::new(0.0F, 0.0F, 1.0F),
  }
}

///|
pub fn Mat3::from_cols(x_axis : Vec3, y_axis : Vec3, z_axis : Vec3) -> Mat3 {
  Mat3::{ x_axis, y_axis, z_axis }
}

///|
pub fn Mat3::transpose(self : Mat3) -> Mat3 {
  Mat3::from_cols(
    Vec3::new(self.x_axis.x, self.y_axis.x, self.z_axis.x),
    Vec3::new(self.x_axis.y, self.y_axis.y, self.z_axis.y),
    Vec3::new(self.x_axis.z, self.y_axis.z, self.z_axis.z),
  )
}

///|
pub fn Mat3::mul(self : Mat3, other : Mat3) -> Mat3 {
  Mat3::from_cols(
    self.mul_vec3(other.x_axis),
    self.mul_vec3(other.y_axis),
    self.mul_vec3(other.z_axis),
  )
}

///|
pub fn Mat3::mul_scalar(self : Mat3, scalar : Float) -> Mat3 {
  Mat3::from_cols(
    self.x_axis.mul_scalar(scalar),
    self.y_axis.mul_scalar(scalar),
    self.z_axis.mul_scalar(scalar),
  )
}

///|
pub fn Mat3::mul_vec3(self : Mat3, value : Vec3) -> Vec3 {
  Vec3::new(
    self.x_axis.x * value.x + self.y_axis.x * value.y + self.z_axis.x * value.z,
    self.x_axis.y * value.x + self.y_axis.y * value.y + self.z_axis.y * value.z,
    self.x_axis.z * value.x + self.y_axis.z * value.y + self.z_axis.z * value.z,
  )
}

///|
pub fn Mat3::determinant(self : Mat3) -> Float {
  self.x_axis.dot(self.y_axis.cross(self.z_axis))
}

///|
pub fn Mat3::inverse(self : Mat3) -> Mat3? {
  let cofactor_x = self.y_axis.cross(self.z_axis)
  let cofactor_y = self.z_axis.cross(self.x_axis)
  let cofactor_z = self.x_axis.cross(self.y_axis)
  let det = self.x_axis.dot(cofactor_x)
  if det <= 1.0e-12F && det >= -1.0e-12F {
    return None
  }
  Some(
    Mat3::from_cols(cofactor_x, cofactor_y, cofactor_z)
    .transpose()
    .mul_scalar(1.0F / det),
  )
}
