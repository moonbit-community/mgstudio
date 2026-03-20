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
pub fn Mat3::mul_vec3(self : Mat3, value : Vec3) -> Vec3 {
  self.x_axis
  .mul_scalar(value.x)
  .add(self.y_axis.mul_scalar(value.y))
  .add(self.z_axis.mul_scalar(value.z))
}
