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
  diagnostic.add_measurement(DiagnosticMeasurement::new(1.0F, 10.0F), 1)
  diagnostic.add_measurement(DiagnosticMeasurement::new(2.0F, 20.0F), 2)
  inspect(diagnostic.history_len(), content="1")
  inspect(diagnostic.value().unwrap(), content="20")
}

///|
test "diagnostic: same system tick overwrites the latest measurement" {
  let diagnostic = Diagnostic::new(DiagnosticPath::new("test"))
  diagnostic.add_measurement(DiagnosticMeasurement::new(1.0F, 10.0F), 7)
  diagnostic.add_measurement(DiagnosticMeasurement::new(2.0F, 12.0F), 7)
  inspect(diagnostic.history_len(), content="1")
  inspect(diagnostic.value().unwrap(), content="12")
}
