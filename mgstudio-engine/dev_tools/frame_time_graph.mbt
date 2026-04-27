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
pub(all) struct FrameTimeGraphConfigUniform {
  dt_min : Float
  dt_max : Float
  dt_min_log2 : Float
  dt_max_log2 : Float
  proportional_width : UInt
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
  if !frame_time_graph_has_frame_time_diagnostics(app) {
    abort("FrameTimeGraphPlugin requires FrameTimeDiagnosticsPlugin")
  }
  app
}
