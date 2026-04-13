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

///|
test "diagnostic: max_history_length zero keeps only latest measurement" {
  let diagnostic = Diagnostic::new(DiagnosticPath::new("test")).with_max_history_length(
    0,
  )
  diagnostic.add_measurement(
    DiagnosticMeasurement::new(@core.Instant::from_secs_f32(1.0F), 10.0F),
    1,
  )
  diagnostic.add_measurement(
    DiagnosticMeasurement::new(@core.Instant::from_secs_f32(2.0F), 20.0F),
    2,
  )
  debug_inspect(diagnostic.history_len(), content="1")
  debug_inspect(diagnostic.value().unwrap(), content="20")
}

///|
test "diagnostic: same system sequence overwrites the latest measurement" {
  let diagnostic = Diagnostic::new(DiagnosticPath::new("test"))
  diagnostic.add_measurement(
    DiagnosticMeasurement::new(@core.Instant::from_secs_f32(1.0F), 10.0F),
    7,
  )
  diagnostic.add_measurement(
    DiagnosticMeasurement::new(@core.Instant::from_secs_f32(2.0F), 12.0F),
    7,
  )
  debug_inspect(diagnostic.history_len(), content="1")
  debug_inspect(diagnostic.value().unwrap(), content="12")
}

///|
test "diagnostic: duration tracks instant span" {
  let diagnostic = Diagnostic::new(DiagnosticPath::new("test"))
  diagnostic.add_measurement(
    DiagnosticMeasurement::new(@core.Instant::from_millis(250L), 1.0F),
    1,
  )
  diagnostic.add_measurement(
    DiagnosticMeasurement::new(@core.Instant::from_millis(750L), 2.0F),
    2,
  )
  debug_inspect(diagnostic.duration().unwrap().as_millis(), content="500")
}

///|
test "diagnostics store iter_mut exposes live diagnostic refs" {
  let store = DiagnosticsStore::default()
  let path = DiagnosticPath::new("test")
  store.add(Diagnostic::new(path))
  let diagnostics = store.iter_mut()
  debug_inspect(diagnostics.length(), content="1")
  diagnostics[0].val.set_enabled(false)
  debug_inspect(store.get(path).unwrap().is_enabled(), content="false")
}

///|
test "diagnostic: enable flag can be toggled through public API" {
  let diagnostic = Diagnostic::new(DiagnosticPath::new("test"))
  debug_inspect(diagnostic.is_enabled(), content="true")
  diagnostic.set_enabled(false)
  debug_inspect(diagnostic.is_enabled(), content="false")
}
