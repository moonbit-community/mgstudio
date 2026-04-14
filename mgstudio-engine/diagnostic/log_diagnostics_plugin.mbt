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
const LOG_DIAGNOSTICS_PLUGIN_NAME : String = "mgstudio.diagnostic.LogDiagnosticsPlugin"

///|
pub struct LogDiagnosticsPlugin {
  debug : Bool
  wait_duration_seconds : Float
  filter : @hashmap.HashMap[String, Bool]?
}

///|
pub fn LogDiagnosticsPlugin::default() -> LogDiagnosticsPlugin {
  LogDiagnosticsPlugin::{
    debug: false,
    wait_duration_seconds: 1.0F,
    filter: None,
  }
}

///|
pub fn LogDiagnosticsPlugin::filtered(
  filter : Array[DiagnosticPath],
) -> LogDiagnosticsPlugin {
  let filter_map : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
  for path in filter {
    filter_map.set(path.as_str(), true)
  }
  LogDiagnosticsPlugin::{
    ..LogDiagnosticsPlugin::default(),
    filter: Some(filter_map),
  }
}

///|
pub impl @app.PluginReplacement for LogDiagnosticsPlugin with plugin_name(_self) {
  LOG_DIAGNOSTICS_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for LogDiagnosticsPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    log_diagnostics_plugin_with(app, self)
  }
}

///|
pub struct LogDiagnosticsState {
  mut timer : @time.Timer
  mut filter : @hashmap.HashMap[String, Bool]?
}

///|
pub fn LogDiagnosticsState::set_timer_duration(
  self : LogDiagnosticsState,
  duration_seconds : Float,
) -> Unit {
  self.timer = @time.Timer::from_seconds(duration_seconds, @time.Repeating)
}

///|
pub fn LogDiagnosticsState::add_filter(
  self : LogDiagnosticsState,
  diagnostic_path : DiagnosticPath,
) -> Bool {
  match self.filter {
    Some(filter) => {
      let exists = filter.contains(diagnostic_path.as_str())
      filter.set(diagnostic_path.as_str(), true)
      !exists
    }
    None => {
      let filter : @hashmap.HashMap[String, Bool] = @hashmap.HashMap::new()
      filter.set(diagnostic_path.as_str(), true)
      self.filter = Some(filter)
      true
    }
  }
}

///|
pub fn LogDiagnosticsState::extend_filter(
  self : LogDiagnosticsState,
  paths : Array[DiagnosticPath],
) -> Unit {
  for path in paths {
    self.add_filter(path) |> ignore
  }
}

///|
pub fn LogDiagnosticsState::remove_filter(
  self : LogDiagnosticsState,
  diagnostic_path : DiagnosticPath,
) -> Bool {
  match self.filter {
    Some(filter) => {
      let exists = filter.contains(diagnostic_path.as_str())
      filter.remove(diagnostic_path.as_str())
      exists
    }
    None => false
  }
}

///|
pub fn LogDiagnosticsState::clear_filter(self : LogDiagnosticsState) -> Unit {
  if self.filter is Some(filter) {
    filter.clear()
  }
}

///|
pub fn LogDiagnosticsState::enable_filtering(
  self : LogDiagnosticsState,
) -> Unit {
  self.filter = Some(@hashmap.HashMap::new())
}

///|
pub fn LogDiagnosticsState::disable_filtering(
  self : LogDiagnosticsState,
) -> Unit {
  self.filter = None
}

///|
pub fn LogDiagnosticsState::default() -> LogDiagnosticsState {
  LogDiagnosticsState::{
    timer: @time.Timer::from_seconds(1.0F, @time.Repeating),
    filter: None,
  }
}

///|
let log_diagnostics_state_resource_key : @ecs.ResourceKey[LogDiagnosticsState] = @ecs.register_resource(
  debug_name="mgstudio_diagnostic::LogDiagnosticsState",
)

///|
pub impl @app.Resource for LogDiagnosticsState with resource() {
  log_diagnostics_state_resource_key
}

///|
pub fn log_diagnostics_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  log_diagnostics_plugin_with(app, LogDiagnosticsPlugin::default())
}

///|
pub fn log_diagnostics_plugin_with(
  app : @app.App[@ecs.World],
  plugin : LogDiagnosticsPlugin,
) -> @app.App[@ecs.World] {
  let state = LogDiagnosticsState::{
    timer: @time.Timer::from_seconds(
      plugin.wait_duration_seconds,
      @time.Repeating,
    ),
    filter: plugin.filter,
  }
  if plugin.debug {
    app
    .insert_resource(state)
    .add_post_update_system_param3(log_diagnostics_debug_system)
  } else {
    app
    .insert_resource(state)
    .add_post_update_system_param3(log_diagnostics_system)
  }
}

///|
fn log_diagnostics_state_allows(
  state : LogDiagnosticsState,
  path : DiagnosticPath,
) -> Bool {
  match state.filter {
    Some(filter) => filter.contains(path.as_str())
    None => true
  }
}

///|
fn log_diagnostic_message(diagnostic : Diagnostic) -> String {
  match diagnostic.smoothed() {
    Some(value) =>
      if diagnostic.get_max_history_length() > 1 {
        match diagnostic.average() {
          Some(average) =>
            "\{diagnostic.path().as_str()}: \{value.to_string()}\{diagnostic.suffix} (avg \{average.to_string()}\{diagnostic.suffix})"
          None =>
            "\{diagnostic.path().as_str()}: \{value.to_string()}\{diagnostic.suffix}"
        }
      } else {
        "\{diagnostic.path().as_str()}: \{value.to_string()}\{diagnostic.suffix}"
      }
    None => ""
  }
}

///|
fn log_diagnostics_sorted(diagnostics : DiagnosticsStore) -> Array[Diagnostic] {
  let items = diagnostics.iter()
  items.sort_by(fn(left, right) {
    match left.path().as_str().compare(right.path().as_str()) {
      0 => 0
      n if n < 0 => -1
      _ => 1
    }
  })
  items
}

///|
fn log_diagnostics_system(
  state : @app.ResMut[LogDiagnosticsState],
  time : @app.Res[@time.Time[@time.Real]],
  diagnostics : @app.Res[DiagnosticsStore],
) -> Unit {
  let state_ref = state.get_ref()
  state_ref.val.timer = state_ref.val.timer.tick(time.get().delta())
  if !state_ref.val.timer.is_finished() {
    return
  }

  for diagnostic in log_diagnostics_sorted(diagnostics.get()) {
    if !diagnostic.is_enabled ||
      !log_diagnostics_state_allows(state_ref.val, diagnostic.path()) {
      continue
    }
    let message = log_diagnostic_message(diagnostic)
    if message != "" {
      @app.log_record(@app.Info, message~, target="mgstudio_diagnostic")
    }
  }
}

///|
fn log_diagnostics_debug_system(
  state : @app.ResMut[LogDiagnosticsState],
  time : @app.Res[@time.Time[@time.Real]],
  diagnostics : @app.Res[DiagnosticsStore],
) -> Unit {
  let state_ref = state.get_ref()
  state_ref.val.timer = state_ref.val.timer.tick(time.get().delta())
  if !state_ref.val.timer.is_finished() {
    return
  }

  for diagnostic in log_diagnostics_sorted(diagnostics.get()) {
    if !diagnostic.is_enabled ||
      !log_diagnostics_state_allows(state_ref.val, diagnostic.path()) {
      continue
    }
    @app.log_record(
      @app.Debug,
      message=to_repr(diagnostic).to_string(),
      target="mgstudio_diagnostic",
    )
  }
}
