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
// Bevy source: `bevy/crates/bevy_render/src/diagnostic/render_asset_diagnostic_plugin.rs`.

///|
const RENDER_ASSET_DIAGNOSTIC_PLUGIN_NAME : String = "mgstudio.render.diagnostic.RenderAssetDiagnosticPlugin"

///|
pub struct RenderAssetDiagnosticPlugin {
  suffix : String
}

///|
pub fn RenderAssetDiagnosticPlugin::new(
  suffix : String,
) -> RenderAssetDiagnosticPlugin {
  RenderAssetDiagnosticPlugin::{ suffix, }
}

///|
pub fn RenderAssetDiagnosticPlugin::default() -> RenderAssetDiagnosticPlugin {
  RenderAssetDiagnosticPlugin::new(" assets")
}

///|
pub impl @app.Plugin for RenderAssetDiagnosticPlugin with name(_self) {
  RENDER_ASSET_DIAGNOSTIC_PLUGIN_NAME
}

///|
pub impl @app.Plugin for RenderAssetDiagnosticPlugin with build(self, app) {
  render_asset_diagnostic_plugin_with(app, self)
}

///|
pub struct RenderAssetDiagnosticState {
  suffix : String
  mut snapshot : @renderer.RenderDiagnosticsSnapshot
  mut sample_count : Int
  mut last_sample_us : Float
}

///|
fn render_asset_diagnostic_state_debug_name() -> String {
  "mgstudio.render.diagnostic.RenderAssetDiagnosticState"
}

///|
let render_asset_diagnostic_state_key : @ecs.ResourceKey[
  RenderAssetDiagnosticState,
] = @ecs.register_resource(
  debug_name=render_asset_diagnostic_state_debug_name(),
)

///|
pub impl @app.Resource for RenderAssetDiagnosticState with resource() {
  render_asset_diagnostic_state_key
}

///|
pub fn RenderAssetDiagnosticState::new(
  suffix : String,
) -> RenderAssetDiagnosticState {
  RenderAssetDiagnosticState::{
    suffix,
    snapshot: @renderer.RenderDiagnosticsSnapshot::default(),
    sample_count: 0,
    last_sample_us: 0.0F,
  }
}

///|
fn render_asset_diagnostic_sample_system(world : @ecs.World) -> Unit {
  match
    (try world.get_resource_mut(render_asset_diagnostic_state_key) catch {
      _ => None
    } noraise {
      value => value
    }) {
    Some(state_ref) =>
      ignore(
        state_ref.modify(fn(value) {
          value.sample_count = value.sample_count + 1
          value.snapshot = @renderer.render_diagnostics_snapshot()
          value.last_sample_us = @time.host_time_now()
        }),
      )
    None => ()
  }
}

///|
pub fn render_asset_diagnostic_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_asset_diagnostic_plugin_with(
    app,
    RenderAssetDiagnosticPlugin::default(),
  )
}

///|
pub fn render_asset_diagnostic_plugin_with(
  app : @app.App[@ecs.World],
  plugin : RenderAssetDiagnosticPlugin,
) -> @app.App[@ecs.World] {
  let mut next = app
  if !next.contains_resource(render_asset_diagnostic_state_key) {
    next = next.insert_world_resource(
      render_asset_diagnostic_state_key,
      RenderAssetDiagnosticState::new(plugin.suffix),
    )
  }
  next.add_post_update_system(render_asset_diagnostic_sample_system)
}
