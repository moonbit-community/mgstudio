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
pub struct Affine3 {
  matrix3 : Mat3
  translation : Vec3
}

///|
pub fn Affine3::identity() -> Affine3 {
  Affine3::{ matrix3: Mat3::identity(), translation: Vec3::zero() }
}

///|
pub fn Affine3::from_mat3_translation(
  matrix3 : Mat3,
  translation : Vec3,
) -> Affine3 {
  Affine3::{ matrix3, translation }
}

///|
fn affine3_quat_from_basis(x_axis : Vec3, y_axis : Vec3, z_axis : Vec3) -> Quat {
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
pub fn Affine3::from_translation(translation : Vec3) -> Affine3 {
  Affine3::{ matrix3: Mat3::identity(), translation }
}

///|
pub fn Affine3::from_scale_rotation_translation(
  scale : Vec3,
  rotation : Quat,
  translation : Vec3,
) -> Affine3 {
  let x2 = rotation.x + rotation.x
  let y2 = rotation.y + rotation.y
  let z2 = rotation.z + rotation.z
  let xx = rotation.x * x2
  let xy = rotation.x * y2
  let xz = rotation.x * z2
  let yy = rotation.y * y2
  let yz = rotation.y * z2
  let zz = rotation.z * z2
  let wx = rotation.w * x2
  let wy = rotation.w * y2
  let wz = rotation.w * z2
  let m00 = (1.0F - (yy + zz)) * scale.x
  let m01 = (xy + wz) * scale.x
  let m02 = (xz - wy) * scale.x
  let m10 = (xy - wz) * scale.y
  let m11 = (1.0F - (xx + zz)) * scale.y
  let m12 = (yz + wx) * scale.y
  let m20 = (xz + wy) * scale.z
  let m21 = (yz - wx) * scale.z
  let m22 = (1.0F - (xx + yy)) * scale.z
  Affine3::{
    matrix3: Mat3::from_cols(
      Vec3::new(m00, m01, m02),
      Vec3::new(m10, m11, m12),
      Vec3::new(m20, m21, m22),
    ),
    translation,
  }
}

///|
pub fn Affine3::mul_transform(
  self : Affine3,
  scale : Vec3,
  rotation : Quat,
  translation : Vec3,
) -> Affine3 {
  let x2 = rotation.x + rotation.x
  let y2 = rotation.y + rotation.y
  let z2 = rotation.z + rotation.z
  let xx = rotation.x * x2
  let xy = rotation.x * y2
  let xz = rotation.x * z2
  let yy = rotation.y * y2
  let yz = rotation.y * z2
  let zz = rotation.z * z2
  let wx = rotation.w * x2
  let wy = rotation.w * y2
  let wz = rotation.w * z2
  let m00 = (1.0F - (yy + zz)) * scale.x
  let m01 = (xy + wz) * scale.x
  let m02 = (xz - wy) * scale.x
  let m10 = (xy - wz) * scale.y
  let m11 = (1.0F - (xx + zz)) * scale.y
  let m12 = (yz + wx) * scale.y
  let m20 = (xz + wy) * scale.z
  let m21 = (yz - wx) * scale.z
  let m22 = (1.0F - (xx + yy)) * scale.z

  let sx = self.matrix3.x_axis
  let sy = self.matrix3.y_axis
  let sz = self.matrix3.z_axis
  let result_x_axis = Vec3::new(
    sx.x * m00 + sy.x * m01 + sz.x * m02,
    sx.y * m00 + sy.y * m01 + sz.y * m02,
    sx.z * m00 + sy.z * m01 + sz.z * m02,
  )
  let result_y_axis = Vec3::new(
    sx.x * m10 + sy.x * m11 + sz.x * m12,
    sx.y * m10 + sy.y * m11 + sz.y * m12,
    sx.z * m10 + sy.z * m11 + sz.z * m12,
  )
  let result_z_axis = Vec3::new(
    sx.x * m20 + sy.x * m21 + sz.x * m22,
    sx.y * m20 + sy.y * m21 + sz.y * m22,
    sx.z * m20 + sy.z * m21 + sz.z * m22,
  )
  let result_translation = Vec3::new(
    sx.x * translation.x + sy.x * translation.y + sz.x * translation.z +
    self.translation.x,
    sx.y * translation.x + sy.y * translation.y + sz.y * translation.z +
    self.translation.y,
    sx.z * translation.x + sy.z * translation.y + sz.z * translation.z +
    self.translation.z,
  )
  Affine3::{
    matrix3: Mat3::from_cols(result_x_axis, result_y_axis, result_z_axis),
    translation: result_translation,
  }
}

///|
pub fn Affine3::mul(self : Affine3, other : Affine3) -> Affine3 {
  let translated = other.translation
  let tx = self.matrix3.x_axis.x * translated.x +
    self.matrix3.y_axis.x * translated.y +
    self.matrix3.z_axis.x * translated.z +
    self.translation.x
  let ty = self.matrix3.x_axis.y * translated.x +
    self.matrix3.y_axis.y * translated.y +
    self.matrix3.z_axis.y * translated.z +
    self.translation.y
  let tz = self.matrix3.x_axis.z * translated.x +
    self.matrix3.y_axis.z * translated.y +
    self.matrix3.z_axis.z * translated.z +
    self.translation.z
  Affine3::{
    matrix3: self.matrix3.mul(other.matrix3),
    translation: Vec3::new(tx, ty, tz),
  }
}

///|
pub fn Affine3::inverse(self : Affine3) -> Affine3 {
  match self.matrix3.inverse() {
    Some(inverse_matrix3) =>
      Affine3::{
        matrix3: inverse_matrix3,
        translation: inverse_matrix3.mul_vec3(self.translation).neg(),
      }
    None => Affine3::identity()
  }
}

///|
pub fn Affine3::to_scale_rotation_translation(
  self : Affine3,
) -> (Vec3, Quat, Vec3) {
  let scale = Vec3::new(
    self.matrix3.x_axis.length(),
    self.matrix3.y_axis.length(),
    self.matrix3.z_axis.length(),
  )
  let inv_scale_x = if scale.x <= 1.0e-12F { 0.0F } else { 1.0F / scale.x }
  let inv_scale_y = if scale.y <= 1.0e-12F { 0.0F } else { 1.0F / scale.y }
  let inv_scale_z = if scale.z <= 1.0e-12F { 0.0F } else { 1.0F / scale.z }
  let rotation = affine3_quat_from_basis(
    self.matrix3.x_axis.mul_scalar(inv_scale_x),
    self.matrix3.y_axis.mul_scalar(inv_scale_y),
    self.matrix3.z_axis.mul_scalar(inv_scale_z),
  )
  (scale, rotation, self.translation)
}

///|
pub fn Affine3::transform_point3(self : Affine3, point : Vec3) -> Vec3 {
  self.matrix3.mul_vec3(point).add(self.translation)
}
