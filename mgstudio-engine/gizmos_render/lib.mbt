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
// Bevy source: `bevy/crates/bevy_gizmos_render/src/lib.rs`.
// Bridge surface for the package root lives here; runtime implementation
// remains delegated to `sprite_render` and `pbr`.

///|
pub(all) enum GizmoRenderSystems {
  QueueLineGizmos2d
  QueueLineGizmos3d
} derive(Eq, Debug)

///|
pub fn gizmo_render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @sprite_render.sprite_render_plugin(app)
}

///|
pub fn gizmo_render_system_set(system : GizmoRenderSystems) -> @app.SystemSet {
  match system {
    QueueLineGizmos2d => @sprite_render.render2d_set_queue
    QueueLineGizmos3d => @pbr.render3d_set_queue
  }
}
