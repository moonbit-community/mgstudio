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
// Bevy source: `bevy/crates/bevy_gizmos/src/skinned_mesh_bounds.rs`.

///|
pub struct SkinnedMeshBoundsGizmoPlugin {}

///|
pub fn SkinnedMeshBoundsGizmoPlugin::default() -> SkinnedMeshBoundsGizmoPlugin {
  SkinnedMeshBoundsGizmoPlugin::{  }
}

///|
pub struct SkinnedMeshBoundsGizmoConfigGroup {
  draw_all : Bool
  default_color : @sprite.Color
}

///|
pub fn SkinnedMeshBoundsGizmoConfigGroup::default() -> SkinnedMeshBoundsGizmoConfigGroup {
  SkinnedMeshBoundsGizmoConfigGroup::{
    draw_all: false,
    default_color: @sprite.Color::white(),
  }
}

///|
pub struct ShowSkinnedMeshBoundsGizmo {
  color : @sprite.Color?
}

///|
pub fn ShowSkinnedMeshBoundsGizmo::default() -> ShowSkinnedMeshBoundsGizmo {
  ShowSkinnedMeshBoundsGizmo::{ color: None }
}
