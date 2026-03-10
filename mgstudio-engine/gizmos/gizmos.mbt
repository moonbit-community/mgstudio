// Copyright 2026 International Digital Economy Academy
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
/// Gizmo API boundary aligned with Bevy's `bevy_gizmos` crate.
/// Runtime implementation currently lives in `Milky2018/mgstudio/sprite`.

///|
pub type Isometry2d = @sprite.Isometry2d

///|
pub type GizmoLineJoint = @sprite.GizmoLineJoint

///|
pub type GizmoLineStyle = @sprite.GizmoLineStyle

///|
pub type GizmoLineConfig = @sprite.GizmoLineConfig

///|
pub type GizmoConfig = @sprite.GizmoConfig

///|
pub type Gizmos = @sprite.Gizmos

///|
pub type RoundedRectBuilder = @sprite.RoundedRectBuilder

///|
pub type Ellipse2dBuilder = @sprite.Ellipse2dBuilder

///|
pub type Arc2dBuilder = @sprite.Arc2dBuilder

///|
pub type ArrowBuilder = @sprite.ArrowBuilder

///|
pub type Grid2dBuilder = @sprite.Grid2dBuilder

///|
pub fn gizmo_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite.render2d_plugin(app)
}

///|
pub fn gizmo_config() -> GizmoConfig {
  @sprite.gizmo_config()
}

///|
pub fn insert_gizmo_config(config : GizmoConfig) -> Unit {
  @sprite.gizmo_set_config(config)
}
