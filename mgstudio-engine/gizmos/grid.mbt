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
// Bevy source: `bevy/crates/bevy_gizmos/src/grid.rs`.

///|
pub fn[Config] gizmo_grid_2d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @sprite.Isometry2d,
  cell_count : @math.IVec2,
  spacing : @math.Vec2,
  color : @sprite.Color,
) -> @sprite.Grid2dBuilder {
  gizmos.grid_2d(isometry, cell_count, spacing, color)
}

///|
pub fn[Config] gizmo_grid_3d(
  gizmos : @sprite.Gizmos[Config],
  isometry : @math.Isometry3d,
  cell_count : @math.IVec2,
  spacing : @math.Vec2,
  color : @sprite.Color,
) -> Unit {
  gizmos.grid_3d(isometry, cell_count, spacing, color)
}
