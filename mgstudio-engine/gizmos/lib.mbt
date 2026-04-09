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
// Bevy source: `bevy/crates/bevy_gizmos/src/lib.rs`.
// Bridge surface for the package root lives here; runtime implementation
// remains delegated to `sprite`.

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
pub type DefaultGizmoConfigGroup = @sprite.DefaultGizmoConfigGroup

///|
pub type GizmoConfigStore = @sprite.GizmoConfigStore

///|
pub fn[G : Default + @sprite.GizmoConfigGroup] init_gizmo_group(
  app : @app.App[@ecs.World],
  group : G,
) -> @app.App[@ecs.World] {
  @sprite.init_gizmo_group(app, group)
}

///|
pub type Gizmos[G] = @sprite.Gizmos[G]

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
  @sprite.init_gizmo_group(
    @sprite_render.sprite_render_plugin(app),
    DefaultGizmoConfigGroup::default(),
  )
}
