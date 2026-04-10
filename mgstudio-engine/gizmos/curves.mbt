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
// Bridge aliases for curve gizmo inputs.

///|
pub type GizmoCubicCurve2d = @math.CubicCurve[@math.Vec2]

///|
pub type GizmoCubicCurve3d = @math.CubicCurve[@math.Vec3]

///|
///|
pub fn gizmo_curve2d_identity(curve : GizmoCubicCurve2d) -> GizmoCubicCurve2d {
  curve
}

///|
pub fn gizmo_curve3d_identity(curve : GizmoCubicCurve3d) -> GizmoCubicCurve3d {
  curve
}
