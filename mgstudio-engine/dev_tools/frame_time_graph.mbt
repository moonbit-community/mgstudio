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
// Bevy source: `bevy/crates/bevy_dev_tools/src/frame_time_graph/mod.rs`.

///|
pub struct FrameTimeGraphPlugin {}

///|
pub fn FrameTimeGraphPlugin::default() -> FrameTimeGraphPlugin {
  FrameTimeGraphPlugin::{  }
}

///|
pub impl @app.Plugin for FrameTimeGraphPlugin with name(_self) {
  "mgstudio.dev_tools.FrameTimeGraphPlugin"
}

///|
pub impl @app.Plugin for FrameTimeGraphPlugin with build(self, app) {
  frame_time_graph_plugin_with(app, self)
}

///|
priv struct FrameTimeGraphValues {
  values : Array[Float]
}

///|
fn FrameTimeGraphValues::default() -> FrameTimeGraphValues {
  FrameTimeGraphValues::{ values: [] }
}

///|
let frame_time_graph_values_resource_key : @ecs.ResourceKey[
  FrameTimeGraphValues,
] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::frame_time_graph::FrameTimeGraphValues",
)

///|
pub(all) struct FrameTimeGraphConfigUniform {
  dt_min : Float
  dt_max : Float
  dt_min_log2 : Float
  dt_max_log2 : Float
  proportional_width : UInt
}

///|
pub(all) struct FrametimeGraphMaterial {
  values : @asset.Handle[@render_resource.StorageBuffer[Float]]
  config : FrameTimeGraphConfigUniform
}

///|
pub fn FrametimeGraphMaterial::new(
  values : @asset.Handle[@render_resource.StorageBuffer[Float]],
  config : FrameTimeGraphConfigUniform,
) -> FrametimeGraphMaterial {
  FrametimeGraphMaterial::{ values, config }
}

///|
fn FrametimeGraphMaterial::asset_init_probe() -> FrametimeGraphMaterial {
  FrametimeGraphMaterial::{
    values: @asset.Handle::new(-1),
    config: FrameTimeGraphConfigUniform::new(60.0F, 30.0F, true),
  }
}

///|
fn frame_time_graph_material_assets_key() -> @ecs.ResourceKey[
  @asset.Assets[FrametimeGraphMaterial],
] {
  @asset.assets_resource_key()
}

///|
fn frame_time_graph_buffer_assets_key() -> @ecs.ResourceKey[
  @asset.Assets[@render_resource.StorageBuffer[Float]],
] {
  @asset.assets_resource_key()
}

///|
fn frame_time_graph_log2(value : Float) -> Float {
  if value <= 0.0F {
    return 0.0F
  }
  let mut normalized = value
  let mut exponent = 0.0F
  while normalized < 1.0F {
    normalized = normalized * 2.0F
    exponent = exponent - 1.0F
  }
  while normalized >= 2.0F {
    normalized = normalized / 2.0F
    exponent = exponent + 1.0F
  }
  let mut fraction = 0.0F
  let mut factor = 0.5F
  let mut current = normalized
  for _ in 0..<16 {
    current = current * current
    if current >= 2.0F {
      current = current / 2.0F
      fraction = fraction + factor
    }
    factor = factor / 2.0F
  }
  exponent + fraction
}

///|
pub fn FrameTimeGraphConfigUniform::new(
  target_fps : Float,
  min_fps : Float,
  proportional_width : Bool,
) -> FrameTimeGraphConfigUniform {
  let dt_min = 1.0F / (target_fps * 1.2F)
  let dt_max = 1.0F / min_fps
  FrameTimeGraphConfigUniform::{
    dt_min,
    dt_max,
    dt_min_log2: frame_time_graph_log2(dt_min),
    dt_max_log2: frame_time_graph_log2(dt_max),
    proportional_width: if proportional_width {
      1U
    } else {
      0U
    },
  }
}

///|
fn frame_time_graph_has_frame_time_diagnostics(
  app : @app.App[@ecs.World],
) -> Bool {
  match
    (try! app.world().get_resource(@diagnostic.DiagnosticsStore::resource())) {
    Some(store) =>
      store.get(@diagnostic.frame_time_diagnostic_frame_time) is Some(_)
    None => false
  }
}

///|
pub fn frame_time_graph_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  frame_time_graph_plugin_with(app, FrameTimeGraphPlugin::default())
}

///|
pub fn frame_time_graph_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : FrameTimeGraphPlugin,
) -> @app.App[@ecs.World] {
  register_embedded_wgsl_sources()
  if !frame_time_graph_has_frame_time_diagnostics(app) {
    abort("FrameTimeGraphPlugin requires FrameTimeDiagnosticsPlugin")
  }
  @asset.init_asset(
    @asset.init_asset(
      app.insert_world_resource(
        frame_time_graph_values_resource_key,
        FrameTimeGraphValues::default(),
      ),
      fn() -> @render_resource.StorageBuffer[Float] {
        @render_resource.StorageBuffer::new()
      },
    ),
    FrametimeGraphMaterial::asset_init_probe,
  ).add_systems(
    @app.Update,
    @app.system(update_frame_time_values).in_set(fps_overlay_set_update_text),
  )
}

///|
fn frame_time_graph_config_enabled(world : @ecs.World) -> Bool {
  match (try! world.get_resource(FpsOverlayConfig::resource())) {
    Some(config) => config.frame_time_graph_config.enabled
    None => true
  }
}

///|
fn update_frame_time_values(world : @ecs.World) -> Unit {
  if !frame_time_graph_config_enabled(world) {
    return
  }
  guard (try! world.get_resource(@diagnostic.DiagnosticsStore::resource()))
    is Some(store) else {
    return
  }
  guard store.get(@diagnostic.frame_time_diagnostic_frame_time)
    is Some(frame_time) else {
    return
  }
  guard (try! world.get_resource_ref_mut(frame_time_graph_values_resource_key))
    is Some(values_ref) else {
    return
  }
  values_ref.val.values.clear()
  for value in frame_time.values() {
    values_ref.val.values.push(value / 1000.0F)
  }
  frame_time_graph_update_material_buffers(world, values_ref.val.values)
}

///|
fn frame_time_graph_update_material_buffers(
  world : @ecs.World,
  frame_times : Array[Float],
) -> Unit {
  guard (try! world.get_resource_ref_mut(frame_time_graph_material_assets_key()))
    is Some(materials_ref) else {
    return
  }
  guard (try! world.get_resource_ref_mut(frame_time_graph_buffer_assets_key()))
    is Some(buffers_ref) else {
    return
  }
  for entry in materials_ref.val.iter_mut() {
    let material = entry.1
    match buffers_ref.val.get_mut(material.values) {
      Some(buffer) => {
        buffer.clear()
        for value in frame_times {
          buffer.push(value)
        }
      }
      None => ()
    }
  }
}
