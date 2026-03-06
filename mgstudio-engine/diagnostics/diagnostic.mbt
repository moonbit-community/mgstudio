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
pub struct DiagnosticPath {
  path : String
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn DiagnosticPath::const_new(path : String) -> DiagnosticPath {
  DiagnosticPath::{ path, }
}

///|
pub fn DiagnosticPath::new(path : String) -> DiagnosticPath {
  if path == "" {
    abort("DiagnosticPath must not be empty")
  }
  if path.has_prefix("/") {
    abort("DiagnosticPath must not start with '/'")
  }
  if path.has_suffix("/") {
    abort("DiagnosticPath must not end with '/'")
  }
  if path.contains("//") {
    abort("DiagnosticPath must not contain empty components")
  }
  DiagnosticPath::{ path, }
}

///|
pub fn DiagnosticPath::from_components(
  components : Array[String],
) -> DiagnosticPath {
  DiagnosticPath::new(components.join("/"))
}

///|
pub fn DiagnosticPath::as_str(self : DiagnosticPath) -> String {
  self.path
}

///|
pub fn DiagnosticPath::components(self : DiagnosticPath) -> Array[String] {
  let components : Array[String] = []
  for component in self.path.split("/") {
    components.push(component.to_string())
  }
  components
}

///|
pub struct DiagnosticMeasurement {
  timestamp_seconds : Float
  value : Float
} derive(Eq, Show, ToJson, FromJson)

///|
pub fn DiagnosticMeasurement::new(
  timestamp_seconds : Float,
  value : Float,
) -> DiagnosticMeasurement {
  DiagnosticMeasurement::{ timestamp_seconds, value }
}

///|
pub struct Diagnostic {
  path : DiagnosticPath
  suffix : String
  history : Array[DiagnosticMeasurement]
  mut sum : Float
  mut ema : Float
  ema_smoothing_factor : Float
  max_history_length : Int
  is_enabled : Bool
  mut last_system_tick : Int?
} derive(Show)

///|
fn diagnostic_value_is_finite(value : Float) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn diagnostic_clamp01(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
}

///|
fn diagnostic_replace_latest_measurement(
  history : Array[DiagnosticMeasurement],
  measurement : DiagnosticMeasurement,
) -> DiagnosticMeasurement? {
  if history.length() == 0 {
    history.push(measurement)
    None
  } else {
    let last = history.length() - 1
    let previous = history[last]
    history[last] = measurement
    Some(previous)
  }
}

///|
pub fn Diagnostic::new(path : DiagnosticPath) -> Diagnostic {
  Diagnostic::{
    path,
    suffix: "",
    history: [],
    sum: 0.0F,
    ema: 0.0F,
    ema_smoothing_factor: 2.0F / 21.0F,
    max_history_length: DEFAULT_MAX_HISTORY_LENGTH,
    is_enabled: true,
    last_system_tick: None,
  }
}

///|
pub fn Diagnostic::with_max_history_length(
  self : Diagnostic,
  max_history_length : Int,
) -> Diagnostic {
  Diagnostic::{ ..self, max_history_length, }
}

///|
pub fn Diagnostic::with_suffix(
  self : Diagnostic,
  suffix : String,
) -> Diagnostic {
  Diagnostic::{ ..self, suffix, }
}

///|
pub fn Diagnostic::with_smoothing_factor(
  self : Diagnostic,
  smoothing_factor : Float,
) -> Diagnostic {
  Diagnostic::{ ..self, ema_smoothing_factor: smoothing_factor }
}

///|
pub fn Diagnostic::path(self : Diagnostic) -> DiagnosticPath {
  self.path
}

///|
pub fn Diagnostic::measurement(self : Diagnostic) -> DiagnosticMeasurement? {
  self.history.last()
}

///|
pub fn Diagnostic::value(self : Diagnostic) -> Float? {
  self.measurement().map(fn(measurement) { measurement.value })
}

///|
pub fn Diagnostic::average(self : Diagnostic) -> Float? {
  if self.history.length() == 0 {
    None
  } else {
    Some(self.sum / Float::from_int(self.history.length()))
  }
}

///|
pub fn Diagnostic::smoothed(self : Diagnostic) -> Float? {
  if self.history.length() == 0 {
    None
  } else {
    Some(self.ema)
  }
}

///|
pub fn Diagnostic::history_len(self : Diagnostic) -> Int {
  self.history.length()
}

///|
pub fn Diagnostic::duration(self : Diagnostic) -> Float? {
  if self.history.length() < 2 {
    return None
  }
  let newest = self.history[self.history.length() - 1]
  let oldest = self.history[0]
  Some(newest.timestamp_seconds - oldest.timestamp_seconds)
}

///|
pub fn Diagnostic::get_max_history_length(self : Diagnostic) -> Int {
  self.max_history_length
}

///|
pub fn Diagnostic::values(self : Diagnostic) -> Array[Float] {
  let values : Array[Float] = []
  for measurement in self.history {
    values.push(measurement.value)
  }
  values
}

///|
pub fn Diagnostic::measurements(
  self : Diagnostic,
) -> Array[DiagnosticMeasurement] {
  self.history.copy()
}

///|
pub fn Diagnostic::clear_history(self : Diagnostic) -> Unit {
  self.history.clear()
  self.sum = 0.0F
  self.ema = 0.0F
  self.last_system_tick = None
}

///|
pub fn Diagnostic::add_measurement(
  self : Diagnostic,
  measurement : DiagnosticMeasurement,
  system_tick : Int,
) -> Unit {
  let previous_latest = self.measurement()
  let had_previous = self.history.length() > 0
  let previous_measurement = if self.last_system_tick == Some(system_tick) {
    diagnostic_replace_latest_measurement(self.history, measurement)
  } else {
    self.history.push(measurement)
    None
  }

  let effective_previous = if previous_measurement is Some(previous) {
    Some(previous)
  } else {
    previous_latest
  }

  if measurement.value.is_nan() {
    ()
  } else if effective_previous is Some(previous) {
    let delta = measurement.timestamp_seconds - previous.timestamp_seconds
    let alpha = if self.ema_smoothing_factor <= 0.0F {
      1.0F
    } else {
      diagnostic_clamp01(delta / self.ema_smoothing_factor)
    }
    self.ema = self.ema + alpha * (measurement.value - self.ema)
  } else {
    self.ema = measurement.value
  }

  if self.max_history_length > 1 {
    if previous_measurement is Some(previous) {
      if diagnostic_value_is_finite(previous.value) {
        self.sum = self.sum - previous.value
      }
    }

    while self.history.length() > self.max_history_length {
      let removed = self.history[0]
      if diagnostic_value_is_finite(removed.value) {
        self.sum = self.sum - removed.value
      }
      let retained : Array[DiagnosticMeasurement] = []
      for i in 1..<self.history.length() {
        retained.push(self.history[i])
      }
      self.history.clear()
      for item in retained {
        self.history.push(item)
      }
    }

    if diagnostic_value_is_finite(measurement.value) {
      self.sum = self.sum + measurement.value
    }
  } else {
    self.history.clear()
    self.history.push(measurement)
    self.sum = if measurement.value.is_nan() { 0.0F } else { measurement.value }
  }

  if !had_previous && self.history.length() > 0 && measurement.value.is_nan() {
    self.sum = 0.0F
  }
  self.last_system_tick = Some(system_tick)
}

///|
pub struct DiagnosticsStore {
  diagnostics : @hashmap.HashMap[String, Ref[Diagnostic]]
}

///|
pub fn DiagnosticsStore::default() -> DiagnosticsStore {
  DiagnosticsStore::{ diagnostics: @hashmap.HashMap::new() }
}

///|
let diagnostics_store_resource : Ref[@core.Resource[DiagnosticsStore]] = Ref::new(
  @core.Resource::new(),
)

///|
pub impl @app.Resource for DiagnosticsStore with resource() {
  diagnostics_store_resource.val
}

///|
pub fn DiagnosticsStore::add(
  self : DiagnosticsStore,
  diagnostic : Diagnostic,
) -> Unit {
  self.diagnostics.set(diagnostic.path().as_str(), Ref::new(diagnostic))
}

///|
pub fn DiagnosticsStore::get(
  self : DiagnosticsStore,
  path : DiagnosticPath,
) -> Diagnostic? {
  self.diagnostics
  .get(path.as_str())
  .map(fn(diagnostic_ref) { diagnostic_ref.val })
}

///|
pub fn DiagnosticsStore::get_ref(
  self : DiagnosticsStore,
  path : DiagnosticPath,
) -> Ref[Diagnostic]? {
  self.diagnostics.get(path.as_str())
}

///|
pub fn DiagnosticsStore::get_measurement(
  self : DiagnosticsStore,
  path : DiagnosticPath,
) -> DiagnosticMeasurement? {
  match self.get_ref(path) {
    Some(diagnostic_ref) =>
      if diagnostic_ref.val.is_enabled {
        diagnostic_ref.val.measurement()
      } else {
        None
      }
    None => None
  }
}

///|
pub fn DiagnosticsStore::iter(self : DiagnosticsStore) -> Array[Diagnostic] {
  let diagnostics : Array[Diagnostic] = []
  for entry in self.diagnostics.iter() {
    let (_path, diagnostic_ref) = entry
    diagnostics.push(diagnostic_ref.val)
  }
  diagnostics
}

///|
pub fn DiagnosticsStore::iter_refs(
  self : DiagnosticsStore,
) -> Array[Ref[Diagnostic]] {
  let diagnostics : Array[Ref[Diagnostic]] = []
  for entry in self.diagnostics.iter() {
    let (_path, diagnostic_ref) = entry
    diagnostics.push(diagnostic_ref)
  }
  diagnostics
}

///|
pub struct Diagnostics {
  store_ref : Ref[DiagnosticsStore]
}

///|
pub impl @app.SystemParam for Diagnostics with get() {
  let tick = @app.current_system_ticks().this_run
  match DiagnosticsStore::resource().get_ref_mut(tick) {
    Some(store_ref) => Diagnostics::{ store_ref, }
    None => abort("Missing DiagnosticsStore resource")
  }
}

///|
pub fn Diagnostics::add_measurement(
  self : Diagnostics,
  path : DiagnosticPath,
  value : () -> Float,
) -> Unit {
  match self.store_ref.val.get_ref(path) {
    Some(diagnostic_ref) => {
      if !diagnostic_ref.val.is_enabled {
        return
      }
      let measurement = DiagnosticMeasurement::{
        timestamp_seconds: @time.host_time_now() / 1000.0F,
        value: value(),
      }
      diagnostic_ref.val.add_measurement(
        measurement,
        @app.current_system_ticks().this_run,
      )
    }
    None => ()
  }
}

///|
pub fn register_diagnostic(
  app : @app.App[@ecs.World],
  diagnostic : Diagnostic,
) -> @app.App[@ecs.World] {
  let tick = @app.current_system_ticks().this_run
  if !DiagnosticsStore::resource().is_present() {
    DiagnosticsStore::resource().insert(DiagnosticsStore::default(), tick)
  }
  match DiagnosticsStore::resource().get_ref_mut(tick) {
    Some(store_ref) => store_ref.val.add(diagnostic)
    None => abort("Failed to access DiagnosticsStore resource")
  }
  app
}
