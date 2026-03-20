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
pub struct HalfSpace {
  normal_d : Vec4
} derive(Eq, ToJson, FromJson)

///|
fn half_space_normal3(normal_d : Vec4) -> Vec3 {
  Vec3::new(normal_d.x, normal_d.y, normal_d.z)
}

///|
fn half_space_normalize(normal_d : Vec4) -> Vec4 {
  let normal = half_space_normal3(normal_d)
  let length = normal.length()
  if length <= 1.0e-12F || length.is_nan() || length.is_inf() {
    normal_d
  } else {
    let inv_length = 1.0F / length
    Vec4::new(
      normal_d.x * inv_length,
      normal_d.y * inv_length,
      normal_d.z * inv_length,
      normal_d.w * inv_length,
    )
  }
}

///|
pub fn HalfSpace::new(normal_d : Vec4) -> HalfSpace {
  HalfSpace::{ normal_d: half_space_normalize(normal_d) }
}

///|
pub fn HalfSpace::normal(self : HalfSpace) -> Vec3 {
  half_space_normal3(self.normal_d)
}

///|
pub fn HalfSpace::d(self : HalfSpace) -> Float {
  self.normal_d.w
}

///|
pub fn HalfSpace::normal_d(self : HalfSpace) -> Vec4 {
  self.normal_d
}

///|
pub fn HalfSpace::intersection_point(
  a : HalfSpace,
  b : HalfSpace,
  c : HalfSpace,
) -> Vec3? {
  let an = a.normal()
  let bn = b.normal()
  let cn = c.normal()
  let x = Vec3::new(an.x, bn.x, cn.x)
  let y = Vec3::new(an.y, bn.y, cn.y)
  let z = Vec3::new(an.z, bn.z, cn.z)
  let d = Vec3::new(-a.d(), -b.d(), -c.d())
  let u = y.cross(z)
  let v = x.cross(d)
  let denom = x.dot(u)
  if half_space_normal3(a.normal_d).length() <= 1.0e-12F ||
    half_space_normal3(b.normal_d).length() <= 1.0e-12F ||
    half_space_normal3(c.normal_d).length() <= 1.0e-12F ||
    denom.is_nan() ||
    denom.is_inf() ||
    (if denom < 0.0F { -denom } else { denom }) <= 1.0e-12F {
    None
  } else {
    Some(Vec3::new(d.dot(u) / denom, z.dot(v) / denom, -y.dot(v) / denom))
  }
}
