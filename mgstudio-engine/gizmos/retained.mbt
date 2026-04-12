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
// Bevy source: `bevy/crates/bevy_gizmos/src/retained.rs`.

///|
pub struct GizmoAssetHandle {
  id : Int
} derive(Eq, Debug)

///|
pub fn GizmoAssetHandle::new(id~ : Int) -> GizmoAssetHandle {
  GizmoAssetHandle::{ id, }
}

///|
pub struct RetainedGizmo {
  handle : GizmoAssetHandle
  line_config : GizmoLineConfig
  depth_bias : Float
}

///|
pub fn RetainedGizmo::default() -> RetainedGizmo {
  RetainedGizmo::{
    handle: GizmoAssetHandle::new(id=0),
    line_config: GizmoLineConfig::default(),
    depth_bias: 0.0F,
  }
}
