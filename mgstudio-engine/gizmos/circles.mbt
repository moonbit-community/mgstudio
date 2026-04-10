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
// Bevy source: `bevy/crates/bevy_gizmos/src/circles.rs`.
// Bridge aliases for circle/arc primitive inputs.

///|
pub type GizmoCircle = @math.Circle

///|
pub type GizmoArc2d = @math.Arc2d

///|
pub const GIZMO_CIRCLES_MODULE_TAG : String = "bevy_gizmos::circles"

///|
pub fn gizmo_circle_identity(circle : GizmoCircle) -> GizmoCircle {
  circle
}

///|
pub fn gizmo_arc2d_identity(arc : GizmoArc2d) -> GizmoArc2d {
  arc
}
