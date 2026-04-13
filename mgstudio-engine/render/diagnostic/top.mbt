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
// Bevy source: `bevy/crates/bevy_render/src/diagnostic/mod.rs`.

///|
pub struct RenderDiagnosticsModuleState {
  mut last_snapshot : @renderer.RenderDiagnosticsSnapshot
  mut last_sample_us : Float
  mut sample_count : Int
}

///|
fn render_diagnostics_module_state_debug_name() -> String {
  "mgstudio.render.diagnostic.RenderDiagnosticsModuleState"
}

///|
let render_diagnostics_module_state_key : @ecs.ResourceKey[
  RenderDiagnosticsModuleState,
] = @ecs.register_resource(
  debug_name=render_diagnostics_module_state_debug_name(),
)

///|
pub impl @app.Resource for RenderDiagnosticsModuleState with resource() {
  render_diagnostics_module_state_key
}

///|
pub fn RenderDiagnosticsModuleState::default() -> RenderDiagnosticsModuleState {
  RenderDiagnosticsModuleState::{
    last_snapshot: @renderer.RenderDiagnosticsSnapshot::default(),
    last_sample_us: 0.0F,
    sample_count: 0,
  }
}

///|
pub fn render_diagnostics_module_snapshot() -> @renderer.RenderDiagnosticsSnapshot {
  @renderer.render_diagnostics_snapshot()
}

///|
fn render_diagnostics_module_refresh_system(world : @ecs.World) -> Unit {
  match
    (try world.get_resource_ref_mut(render_diagnostics_module_state_key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(state_ref) => {
      state_ref.val.sample_count = state_ref.val.sample_count + 1
      state_ref.val.last_snapshot = @renderer.render_diagnostics_snapshot()
      state_ref.val.last_sample_us = @time.host_time_now()
    }
    None => ()
  }
}

///|
pub fn render_diagnostics_module_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(render_diagnostics_module_state_key) {
    next = next.insert_world_resource(
      render_diagnostics_module_state_key,
      RenderDiagnosticsModuleState::default(),
    )
  }
  next.add_post_update_system(render_diagnostics_module_refresh_system)
}
