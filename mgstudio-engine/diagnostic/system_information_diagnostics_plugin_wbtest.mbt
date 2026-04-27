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
test "diagnostics: collected system info contains host metadata" {
  let info = collect_system_info()
  debug_inspect(info.os != "", content="true")
  debug_inspect(info.kernel != "", content="true")
  debug_inspect(info.cpu != "", content="true")
  debug_inspect(info.core_count != "", content="true")
  debug_inspect(info.memory.has_suffix("GiB"), content="true")
}

///|
test "diagnostics: sysinfo refresh data populates diagnostics store" {
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    DiagnosticsPlugin::default(),
  )
  let pid = match @sysinfo.get_current_pid() {
    Ok(value) => value
    Err(message) => abort(message)
  }
  let system = @sysinfo.System::new_with_specifics(
    @sysinfo.RefreshKind::nothing()
    .with_cpu(@sysinfo.CpuRefreshKind::nothing().with_cpu_usage())
    .with_memory(@sysinfo.MemoryRefreshKind::everything()),
  )
  let data = collect_sysinfo_refresh_data(system, pid)
  app = register_diagnostic(
    register_diagnostic(
      register_diagnostic(
        register_diagnostic(
          app,
          Diagnostic::new(system_information_diagnostic_system_cpu_usage),
        ),
        Diagnostic::new(system_information_diagnostic_system_mem_usage),
      ),
      Diagnostic::new(system_information_diagnostic_process_cpu_usage),
    ),
    Diagnostic::new(system_information_diagnostic_process_mem_usage),
  )
  app = app
    .add_system_param(fn(diagnostics : Diagnostics) {
      apply_sysinfo_refresh_data(diagnostics, data)
    })
    .run_once()
  let store_ref = try! app
    .world()
    .get_resource_ref_mut(DiagnosticsStore::resource())
    .unwrap()

  debug_inspect(
    store_ref.val
    .get(system_information_diagnostic_system_cpu_usage)
    .unwrap()
    .value()
    is Some(_),
    content="true",
  )
  debug_inspect(
    store_ref.val
    .get(system_information_diagnostic_system_mem_usage)
    .unwrap()
    .value()
    is Some(_),
    content="true",
  )
  debug_inspect(
    store_ref.val
    .get(system_information_diagnostic_process_cpu_usage)
    .unwrap()
    .value()
    is Some(_),
    content="true",
  )
  debug_inspect(
    store_ref.val
    .get(system_information_diagnostic_process_mem_usage)
    .unwrap()
    .value()
    is Some(_),
    content="true",
  )
}
