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
test "dev_tools frame_time_graph: uniform follows Bevy dt range" {
  let uniform = FrameTimeGraphConfigUniform::new(60.0F, 30.0F, true)
  debug_inspect(uniform.dt_min > 0.0F, content="true")
  debug_inspect(uniform.dt_max > uniform.dt_min, content="true")
  debug_inspect(uniform.dt_max_log2 > uniform.dt_min_log2, content="true")
  debug_inspect(uniform.proportional_width, content="1")
}

///|
test "dev_tools frame_time_graph: plugin does not install fps overlay" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@diagnostic.DiagnosticsPlugin::default())
    .add_plugins(@diagnostic.FrameTimeDiagnosticsPlugin::default())
    .add_plugins(FrameTimeGraphPlugin::default())
  debug_inspect(
    (app.world().get_resource(@dev_tools.FpsOverlayConfig::resource()) catch {
      _ => None
    })
    is Some(_),
    content="false",
  )
}

///|
test "panic dev_tools frame_time_graph: plugin requires frame time diagnostics" {
  ignore(frame_time_graph_plugin(@app.App::new(@ecs.World::new())))
}
