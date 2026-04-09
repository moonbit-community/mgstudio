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
// Bevy source-shape anchor (`bevy_transform/src/traits.rs`).

///|
pub(open) trait TransformPoint {
  transform_point(self : Self, point : @math.Vec3) -> @math.Vec3
}

///|
pub impl TransformPoint for Transform with transform_point(self, point) {
  let scaled = @math.Vec3::new(
    point.x * self.scale.x,
    point.y * self.scale.y,
    point.z * self.scale.z,
  )
  transform_rotate_vec3(self.rotation, scaled).add(self.translation)
}

///|
pub impl TransformPoint for GlobalTransform with transform_point(self, point) {
  @math.Vec3::new(
    self.affine.a * point.x + self.affine.c * point.y + self.affine.tx,
    self.affine.b * point.x + self.affine.d * point.y + self.affine.ty,
    point.z + self.z,
  )
}

///|
pub impl TransformPoint for @math.Isometry3d with transform_point(self, point) {
  self.transform_point3(point)
}
