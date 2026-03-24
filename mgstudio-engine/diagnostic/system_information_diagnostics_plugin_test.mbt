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
fn system_information_diagnostic_registered(
  app : @app.App[@ecs.World],
  path : DiagnosticPath,
) -> Bool {
  let store = try! app
    .world()
    .get_resource(DiagnosticsStore::resource())
    .unwrap()
  store.get(path) is Some(_)
}

///|
test "diagnostics: diagnostics plugin initializes system info resource" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([diagnostics_plugin])
  inspect(
    app.world().get_resource(SystemInfo::resource()) is Some(_),
    content="true",
  )
}

///|
test "diagnostics: system information plugin registers diagnostic paths" {
  let app = @app.App::new(@ecs.World::new()).add_plugins([
    diagnostics_plugin, system_information_diagnostics_plugin,
  ])

  inspect(
    system_information_diagnostic_registered(
      app, system_information_diagnostic_system_cpu_usage,
    ),
    content="true",
  )
  inspect(
    system_information_diagnostic_registered(
      app, system_information_diagnostic_system_mem_usage,
    ),
    content="true",
  )
  inspect(
    system_information_diagnostic_registered(
      app, system_information_diagnostic_process_cpu_usage,
    ),
    content="true",
  )
  inspect(
    system_information_diagnostic_registered(
      app, system_information_diagnostic_process_mem_usage,
    ),
    content="true",
  )
}
