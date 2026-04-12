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
// Bevy source: `bevy/crates/bevy_gizmos/src/curves.rs`.

///|
pub fn[Config] gizmo_curve_2d(
  gizmos : @sprite.Gizmos[Config],
  points : Array[@math.Vec2],
  color : @sprite.Color,
) -> Unit {
  gizmos.curve_2d(points, color)
}

///|
pub fn[Config] gizmo_curve_3d(
  gizmos : @sprite.Gizmos[Config],
  points : Array[@math.Vec3],
  color : @sprite.Color,
) -> Unit {
  gizmos.curve_3d(points, color)
}

///|
pub fn[Config] gizmo_curve_gradient_2d(
  gizmos : @sprite.Gizmos[Config],
  points : Array[(@math.Vec2, @sprite.Color)],
) -> Unit {
  gizmos.curve_gradient_2d(points)
}

///|
pub fn[Config] gizmo_curve_gradient_3d(
  gizmos : @sprite.Gizmos[Config],
  points : Array[(@math.Vec3, @sprite.Color)],
) -> Unit {
  gizmos.curve_gradient_3d(points)
}
