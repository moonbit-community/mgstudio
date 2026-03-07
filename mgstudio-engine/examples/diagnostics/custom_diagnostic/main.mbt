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
/// Port of `bevy/examples/diagnostics/custom_diagnostic.rs`.

///|
let system_iteration_count : @diagnostics.DiagnosticPath = @diagnostics.DiagnosticPath::const_new(
  "system_iteration_count",
)

///|
fn main {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@mgstudio.default_plugins())
    .add_plugin(@diagnostics.log_diagnostics_plugin)
  @diagnostics.register_diagnostic(
    app,
    @diagnostics.Diagnostic::new(system_iteration_count).with_suffix(
      " iterations",
    ),
  )
  .add_systems(@app.Update, @app.system(@app.system_param(my_system)))
  .run()
}

///|
fn my_system(diagnostics : @diagnostics.Diagnostics) -> Unit {
  diagnostics.add_measurement(system_iteration_count, fn() { 10.0F })
}
