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
// Bevy source: `bevy/crates/bevy_gizmos/src/arcs.rs`.

///|
pub fn[Config] gizmo_arc_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  arc_angle : Float,
  radius : Float,
  color : @sprite.Color,
) -> @sprite.Arc2dBuilder {
  gizmos.arc_2d(isometry, arc_angle, radius, color)
}

///|
pub fn[Config] gizmo_arc_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  angle : Float,
  radius : Float,
  color : @sprite.Color,
) -> Unit {
  gizmos.arc_3d(isometry, angle, radius, color)
}

///|
pub fn[Config] gizmo_short_arc_2d_between(
  gizmos : @sprite.Gizmos[Config],
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @sprite.Color,
) -> @sprite.Arc2dBuilder {
  gizmos.short_arc_2d_between(center, from, to, color)
}

///|
pub fn[Config] gizmo_long_arc_2d_between(
  gizmos : @sprite.Gizmos[Config],
  center : @math.Vec2,
  from : @math.Vec2,
  to : @math.Vec2,
  color : @sprite.Color,
) -> @sprite.Arc2dBuilder {
  gizmos.long_arc_2d_between(center, from, to, color)
}
