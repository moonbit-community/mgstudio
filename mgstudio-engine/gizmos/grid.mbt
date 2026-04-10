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
// Bridge alias for 2D grid builder surface.

///|
pub type GizmoGrid2dBuilder = @sprite.Grid2dBuilder

///|
pub const GIZMO_GRID_MODULE_TAG : String = "bevy_gizmos::grid"

///|
pub fn gizmo_grid_builder_identity(
  builder : GizmoGrid2dBuilder,
) -> GizmoGrid2dBuilder {
  builder
}
