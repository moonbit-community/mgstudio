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
/// 2D affine transform.
///
/// Ported from upstream `zeno/src/geometry.rs` (Apache-2.0 OR MIT).
pub struct Transform {
  xx : Double
  xy : Double
  yx : Double
  yy : Double
  x : Double
  y : Double
}

///|
pub fn Transform::identity() -> Transform {
  Transform::{ xx: 1.0, xy: 0.0, yx: 0.0, yy: 1.0, x: 0.0, y: 0.0 }
}

///|
pub fn Transform::translate(x : Double, y : Double) -> Transform {
  Transform::{ xx: 1.0, xy: 0.0, yx: 0.0, yy: 1.0, x, y }
}

///|
pub fn Transform::scale(x : Double, y : Double) -> Transform {
  Transform::{ xx: x, xy: 0.0, yx: 0.0, yy: y, x: 0.0, y: 0.0 }
}

///|
pub fn Transform::transform_point(self : Transform, point : Point) -> Point {
  Vector::new(
    point.x() * self.xx + point.y() * self.yx + self.x,
    point.x() * self.xy + point.y() * self.yy + self.y,
  )
}

///|
pub fn Transform::transform_vector(self : Transform, vector : Vector) -> Vector {
  Vector::new(
    vector.x() * self.xx + vector.y() * self.yx,
    vector.x() * self.xy + vector.y() * self.yy,
  )
}
