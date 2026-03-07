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
//
// Adapted from Bevy's `bevy_diagnostic` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub struct FrameTimeDiagnosticsPlugin {
  max_history_length : Int
  smoothing_factor : Float
}

///|
pub fn FrameTimeDiagnosticsPlugin::new(
  max_history_length : Int,
) -> FrameTimeDiagnosticsPlugin {
  FrameTimeDiagnosticsPlugin::{
    max_history_length,
    smoothing_factor: 2.0F / (Float::from_int(max_history_length) + 1.0F),
  }
}

///|
pub fn FrameTimeDiagnosticsPlugin::default() -> FrameTimeDiagnosticsPlugin {
  FrameTimeDiagnosticsPlugin::new(DEFAULT_MAX_HISTORY_LENGTH)
}

///|
pub let frame_time_diagnostic_fps : DiagnosticPath = DiagnosticPath::const_new(
  "fps",
)

///|
pub let frame_time_diagnostic_frame_count : DiagnosticPath = DiagnosticPath::const_new(
  "frame_count",
)

///|
pub let frame_time_diagnostic_frame_time : DiagnosticPath = DiagnosticPath::const_new(
  "frame_time",
)

///|
pub fn frame_time_diagnostics_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  frame_time_diagnostics_plugin_with(app, FrameTimeDiagnosticsPlugin::default())
}

///|
pub fn frame_time_diagnostics_plugin_with(
  app : @app.App[@ecs.World],
  plugin : FrameTimeDiagnosticsPlugin,
) -> @app.App[@ecs.World] {
  register_diagnostic(
    register_diagnostic(
      register_diagnostic(
        app,
        Diagnostic::new(frame_time_diagnostic_frame_time)
        .with_suffix("ms")
        .with_max_history_length(plugin.max_history_length)
        .with_smoothing_factor(plugin.smoothing_factor),
      ),
      Diagnostic::new(frame_time_diagnostic_fps)
      .with_max_history_length(plugin.max_history_length)
      .with_smoothing_factor(plugin.smoothing_factor),
    ),
    Diagnostic::new(frame_time_diagnostic_frame_count)
    .with_smoothing_factor(0.0F)
    .with_max_history_length(0),
  ).add_system_param3(frame_time_diagnostic_system)
}

///|
fn frame_time_diagnostic_system(
  diagnostics : Diagnostics,
  time : @app.Res[@time.Time[Unit]],
  frame_count : @app.Res[FrameCount],
) -> Unit {
  diagnostics.add_measurement(frame_time_diagnostic_frame_count, fn() {
    Float::from_int(frame_count.get().value)
  })

  let delta_seconds = time.get().delta_seconds()
  if delta_seconds == 0.0F {
    return
  }

  diagnostics.add_measurement(frame_time_diagnostic_frame_time, fn() {
    delta_seconds * 1000.0F
  })
  diagnostics.add_measurement(frame_time_diagnostic_fps, fn() {
    1.0F / delta_seconds
  })
}
