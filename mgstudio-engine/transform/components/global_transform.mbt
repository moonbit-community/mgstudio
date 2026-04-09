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
// Bevy source-shape anchor (`bevy_transform/src/components/global_transform.rs`).

///|
pub fn GlobalTransform::transform_point(
  self : GlobalTransform,
  point : @math.Vec3,
) -> @math.Vec3 {
  @math.Vec3::new(
    self.affine.a * point.x + self.affine.c * point.y + self.affine.tx,
    self.affine.b * point.x + self.affine.d * point.y + self.affine.ty,
    point.z + self.z,
  )
}

///|
pub fn GlobalTransform::inverse(self : GlobalTransform) -> GlobalTransform {
  let det = self.affine.a * self.affine.d - self.affine.b * self.affine.c
  if det <= 1.0e-12F && det >= -1.0e-12F {
    return GlobalTransform::identity()
  }
  let inv_det = 1.0F / det
  let a = self.affine.d * inv_det
  let b = -self.affine.b * inv_det
  let c = -self.affine.c * inv_det
  let d = self.affine.a * inv_det
  let tx = -(a * self.affine.tx + c * self.affine.ty)
  let ty = -(b * self.affine.tx + d * self.affine.ty)
  GlobalTransform::{ affine: Affine2::{ a, b, c, d, tx, ty }, z: -self.z }
}

///|
pub fn GlobalTransform::reparented_to(
  self : GlobalTransform,
  parent : GlobalTransform,
) -> GlobalTransform {
  parent.inverse().mul(self)
}

///|
pub fn GlobalTransform::compute_transform(self : GlobalTransform) -> Transform {
  self.to_transform_approx()
}
