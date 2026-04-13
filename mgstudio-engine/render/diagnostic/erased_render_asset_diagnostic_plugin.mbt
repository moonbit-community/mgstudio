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
// Bevy source: `bevy/crates/bevy_render/src/diagnostic/erased_render_asset_diagnostic_plugin.rs`.

///|
pub struct ErasedRenderAssetDiagnosticPlugin {
  suffix : String
}

///|
pub fn ErasedRenderAssetDiagnosticPlugin::default() -> ErasedRenderAssetDiagnosticPlugin {
  ErasedRenderAssetDiagnosticPlugin::{ suffix: " assets" }
}

///|
pub fn ErasedRenderAssetDiagnosticPlugin::new(
  suffix : String,
) -> ErasedRenderAssetDiagnosticPlugin {
  ErasedRenderAssetDiagnosticPlugin::{ suffix, }
}

///|
pub struct ErasedRenderAssetDiagnosticState {
  suffix : String
  mut snapshot : @renderer.RenderDiagnosticsSnapshot
  mut sample_count : Int
  mut last_sample_us : Float
}

///|
fn erased_render_asset_diagnostic_state_debug_name() -> String {
  "mgstudio.render.diagnostic.ErasedRenderAssetDiagnosticState"
}

///|
let erased_render_asset_diagnostic_state_key : @ecs.ResourceKey[
  ErasedRenderAssetDiagnosticState,
] = @ecs.register_resource(
  debug_name=erased_render_asset_diagnostic_state_debug_name(),
)

///|
pub impl @app.Resource for ErasedRenderAssetDiagnosticState with resource() {
  erased_render_asset_diagnostic_state_key
}

///|
pub fn ErasedRenderAssetDiagnosticState::new(
  suffix : String,
) -> ErasedRenderAssetDiagnosticState {
  ErasedRenderAssetDiagnosticState::{
    suffix,
    snapshot: @renderer.RenderDiagnosticsSnapshot::default(),
    sample_count: 0,
    last_sample_us: 0.0F,
  }
}

///|
fn erased_render_asset_diagnostic_sample_system(world : @ecs.World) -> Unit {
  match
    (try
      world.get_resource_ref_mut(erased_render_asset_diagnostic_state_key)
    catch {
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
pub fn erased_render_asset_diagnostic_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  erased_render_asset_diagnostic_plugin_with(
    app,
    ErasedRenderAssetDiagnosticPlugin::default(),
  )
}

///|
pub fn erased_render_asset_diagnostic_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ErasedRenderAssetDiagnosticPlugin,
) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(erased_render_asset_diagnostic_state_key) {
    next = next.insert_world_resource(
      erased_render_asset_diagnostic_state_key,
      ErasedRenderAssetDiagnosticState::new(plugin.suffix),
    )
  }
  next.add_post_update_system(erased_render_asset_diagnostic_sample_system)
}
