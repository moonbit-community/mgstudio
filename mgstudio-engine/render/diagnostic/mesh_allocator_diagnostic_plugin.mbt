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
// Bevy source: `bevy/crates/bevy_render/src/diagnostic/mesh_allocator_diagnostic_plugin.rs`.

///|
const MESH_ALLOCATOR_DIAGNOSTIC_PLUGIN_NAME : String = "mgstudio.render.diagnostic.MeshAllocatorDiagnosticPlugin"

///|
pub struct MeshAllocatorDiagnosticPlugin {
  suffix : String
}

///|
pub fn MeshAllocatorDiagnosticPlugin::default() -> MeshAllocatorDiagnosticPlugin {
  MeshAllocatorDiagnosticPlugin::{ suffix: " meshes" }
}

///|
pub fn MeshAllocatorDiagnosticPlugin::new(
  suffix : String,
) -> MeshAllocatorDiagnosticPlugin {
  MeshAllocatorDiagnosticPlugin::{ suffix, }
}

///|
pub impl @app.Plugin for MeshAllocatorDiagnosticPlugin with name(_self) {
  MESH_ALLOCATOR_DIAGNOSTIC_PLUGIN_NAME
}

///|
pub impl @app.Plugin for MeshAllocatorDiagnosticPlugin with build(self, app) {
  mesh_allocator_diagnostic_plugin_with(app, self)
}

///|
pub struct MeshAllocatorDiagnosticState {
  suffix : String
  mut snapshot : @renderer.RenderDiagnosticsSnapshot
  mut sample_count : Int
  mut last_sample_us : Float
}

///|
fn mesh_allocator_diagnostic_state_debug_name() -> String {
  "mgstudio.render.diagnostic.MeshAllocatorDiagnosticState"
}

///|
let mesh_allocator_diagnostic_state_key : @ecs.ResourceKey[
  MeshAllocatorDiagnosticState,
] = @ecs.register_resource(
  debug_name=mesh_allocator_diagnostic_state_debug_name(),
)

///|
pub impl @app.Resource for MeshAllocatorDiagnosticState with resource() {
  mesh_allocator_diagnostic_state_key
}

///|
pub fn MeshAllocatorDiagnosticState::new(
  suffix : String,
) -> MeshAllocatorDiagnosticState {
  MeshAllocatorDiagnosticState::{
    suffix,
    snapshot: @renderer.RenderDiagnosticsSnapshot::default(),
    sample_count: 0,
    last_sample_us: 0.0F,
  }
}

///|
fn mesh_allocator_diagnostic_sample_system(world : @ecs.World) -> Unit {
  match
    (try world.get_resource_ref_mut(mesh_allocator_diagnostic_state_key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(state_ref) => {
      state_ref.val.sample_count = state_ref.val.sample_count + 1
      state_ref.val.snapshot = @renderer.render_diagnostics_snapshot()
      state_ref.val.last_sample_us = @time.host_time_now()
    }
    None => ()
  }
}

///|
pub fn mesh_allocator_diagnostic_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  mesh_allocator_diagnostic_plugin_with(
    app,
    MeshAllocatorDiagnosticPlugin::default(),
  )
}

///|
pub fn mesh_allocator_diagnostic_plugin_with(
  app : @app.App[@ecs.World],
  plugin : MeshAllocatorDiagnosticPlugin,
) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(mesh_allocator_diagnostic_state_key) {
    next = next.insert_world_resource(
      mesh_allocator_diagnostic_state_key,
      MeshAllocatorDiagnosticState::new(plugin.suffix),
    )
  }
  next.add_post_update_system(mesh_allocator_diagnostic_sample_system)
}
