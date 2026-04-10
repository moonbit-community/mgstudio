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
// Bevy source: `bevy/crates/bevy_gizmos/src/primitives/dim2.rs`.

///|
pub type GizmoPrimitiveCircle2d = @math.Circle

///|
pub type GizmoPrimitiveRect2d = @math.Rectangle

///|
pub type GizmoPrimitiveCapsule2d = @math.Capsule2d

///|
pub fn gizmo_primitive_circle2d_identity(
  shape : GizmoPrimitiveCircle2d,
) -> GizmoPrimitiveCircle2d {
  shape
}

///|
pub fn gizmo_primitive_rect2d_identity(
  shape : GizmoPrimitiveRect2d,
) -> GizmoPrimitiveRect2d {
  shape
}

///|
pub fn gizmo_primitive_capsule2d_identity(
  shape : GizmoPrimitiveCapsule2d,
) -> GizmoPrimitiveCapsule2d {
  shape
}
