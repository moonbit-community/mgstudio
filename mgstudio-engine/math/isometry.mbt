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
pub struct Isometry2d {
  translation : Vec2
  rotation : Rot2
}

///|
pub struct Isometry3d {
  translation : Vec3
  rotation : Quat
}

///|
pub fn Isometry2d::new(translation : Vec2, rotation : Rot2) -> Isometry2d {
  Isometry2d::{ translation, rotation }
}

///|
pub fn Isometry2d::identity() -> Isometry2d {
  Isometry2d::{ translation: Vec2::zero(), rotation: Rot2::identity() }
}

///|
pub fn Isometry2d::inverse(self : Isometry2d) -> Isometry2d {
  let rotation = self.rotation.inverse()
  let translation = rotation.mul_vec2(self.translation.mul_scalar(-1.0F))
  Isometry2d::{ translation, rotation }
}

///|
pub fn Isometry2d::transform_point2(self : Isometry2d, point : Vec2) -> Vec2 {
  self.rotation.mul_vec2(point).add(self.translation)
}

///|
pub fn Isometry3d::new(translation : Vec3, rotation : Quat) -> Isometry3d {
  Isometry3d::{ translation, rotation }
}

///|
pub fn Isometry3d::identity() -> Isometry3d {
  Isometry3d::{ translation: Vec3::zero(), rotation: Quat::identity() }
}

///|
pub fn Isometry3d::inverse(self : Isometry3d) -> Isometry3d {
  let rotation = Quat::{
    x: -self.rotation.x,
    y: -self.rotation.y,
    z: -self.rotation.z,
    w: self.rotation.w,
  }.normalize()
  let translation = quat_rotate_vec3(rotation, self.translation.neg())
  Isometry3d::{ translation, rotation }
}

///|
pub fn Isometry3d::transform_point3(self : Isometry3d, point : Vec3) -> Vec3 {
  quat_rotate_vec3(self.rotation, point).add(self.translation)
}

///|
fn quat_rotate_vec3(rotation : Quat, value : Vec3) -> Vec3 {
  let qv = Vec3::new(rotation.x, rotation.y, rotation.z)
  let t = qv.cross(value).mul_scalar(2.0F)
  value.add(t.mul_scalar(rotation.w)).add(qv.cross(t))
}
