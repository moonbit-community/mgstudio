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
//
// Adapted from Bevy's `bevy_diagnostic` crate.
// Copyright (c) Bevy Contributors.
// Licensed under Apache-2.0 or MIT.

///|
pub struct SystemInformationDiagnosticsPlugin {}

///|
pub fn SystemInformationDiagnosticsPlugin::default() -> SystemInformationDiagnosticsPlugin {
  SystemInformationDiagnosticsPlugin::{  }
}

///|
pub let system_information_diagnostic_system_cpu_usage : DiagnosticPath = DiagnosticPath::const_new(
  "system/cpu_usage",
)

///|
pub let system_information_diagnostic_system_mem_usage : DiagnosticPath = DiagnosticPath::const_new(
  "system/mem_usage",
)

///|
pub let system_information_diagnostic_process_cpu_usage : DiagnosticPath = DiagnosticPath::const_new(
  "process/cpu_usage",
)

///|
pub let system_information_diagnostic_process_mem_usage : DiagnosticPath = DiagnosticPath::const_new(
  "process/mem_usage",
)

///|
pub struct SystemInfo {
  os : String
  kernel : String
  cpu : String
  core_count : String
  memory : String
} derive(Debug)

///|
let system_info_resource_key : @ecs.ResourceKey[SystemInfo] = @ecs.register_resource(
  debug_name="mgstudio_diagnostic::SystemInfo",
)

///|
pub impl @app.Resource for SystemInfo with resource() {
  system_info_resource_key
}

///|
priv struct SystemInformationDiagnosticsPluginMarker {}

///|
let system_information_diagnostics_plugin_marker_key : @ecs.ResourceKey[
  SystemInformationDiagnosticsPluginMarker,
] = @ecs.register_resource(
  debug_name="mgstudio_diagnostic::SystemInformationDiagnosticsPluginMarker",
)

///|
priv struct SysinfoRefreshData {
  system_cpu_usage : Float
  system_mem_usage : Float
  process_cpu_usage : Float
  process_mem_usage : Float
}

///|
priv struct SysinfoRefreshState {
  mut elapsed_ms : Int64
}

///|
let sysinfo_refresh_state_resource_key : @ecs.ResourceKey[SysinfoRefreshState] = @ecs.register_resource(
  debug_name="mgstudio_diagnostic::SysinfoRefreshState",
)

///|
impl @app.Resource for SysinfoRefreshState with resource() {
  sysinfo_refresh_state_resource_key
}

///|
const BYTES_TO_GIB : Double = 1.0 / 1024.0 / 1024.0 / 1024.0

///|
const PROCESS_USAGE_SUFFIX : String = "%"

///|
fn minimum_refresh_interval_ms() -> Int64 {
  @sysinfo.MINIMUM_CPU_UPDATE_INTERVAL.to_int64()
}

///|
fn system_info_not_available() -> String {
  "not available"
}

///|
fn format_one_decimal(value : Double) -> String {
  let scaled = (value * 10.0).round().to_int()
  let magnitude = if scaled < 0 { -scaled } else { scaled }
  let whole = magnitude / 10
  let fractional = magnitude % 10
  let sign = if scaled < 0 { "-" } else { "" }
  "\{sign}\{whole.to_string()}.\{fractional.to_string()}"
}

///|
fn format_gib_string(bytes : UInt64) -> String {
  "\{format_one_decimal(bytes.to_double() * BYTES_TO_GIB)} GiB"
}

///|
fn sysinfo_cpu_name(system : @sysinfo.System) -> String {
  let cpus = system.cpus()
  if cpus.length() == 0 {
    system_info_not_available()
  } else {
    let brand = cpus[0].brand().trim().to_string()
    if brand == "" {
      system_info_not_available()
    } else {
      brand
    }
  }
}

///|
fn collect_system_info() -> SystemInfo {
  let system = @sysinfo.System::new_with_specifics(
    @sysinfo.RefreshKind::nothing()
    .with_cpu(@sysinfo.CpuRefreshKind::nothing())
    .with_memory(@sysinfo.MemoryRefreshKind::nothing().with_ram()),
  )
  SystemInfo::{
    os: match @sysinfo.System::long_os_version() {
      Some(value) => value
      None => system_info_not_available()
    },
    kernel: match @sysinfo.System::kernel_version() {
      Some(value) => value
      None => system_info_not_available()
    },
    cpu: sysinfo_cpu_name(system),
    core_count: match @sysinfo.System::physical_core_count() {
      Some(value) => value.to_string()
      None => system_info_not_available()
    },
    memory: format_gib_string(system.total_memory()),
  }
}

///|
pub fn SystemInfo::default() -> SystemInfo {
  collect_system_info()
}

///|
fn sysinfo_cpu_count(system : @sysinfo.System) -> Double {
  let cpu_count = system.cpus().length()
  if cpu_count <= 0 {
    1.0
  } else {
    cpu_count.to_double()
  }
}

///|
fn collect_sysinfo_refresh_data(
  system : @sysinfo.System,
  pid : @sysinfo.Pid,
) -> SysinfoRefreshData {
  ignore(
    system.refresh_processes(@sysinfo.ProcessesToUpdate::Selected([pid]), true),
  )
  system.refresh_cpu_specifics(
    @sysinfo.CpuRefreshKind::nothing().with_cpu_usage(),
  )
  system.refresh_memory()

  let total_memory = system.total_memory()
  let used_memory = system.used_memory()
  let system_mem_usage = if total_memory == 0 {
    0.0
  } else {
    used_memory.to_double() / total_memory.to_double() * 100.0
  }

  let process = system.process(pid)
  let process_mem_usage = match process {
    Some(value) => value.memory().to_double() * BYTES_TO_GIB
    None => 0.0
  }
  let process_cpu_usage = match process {
    Some(value) => value.cpu_usage() / sysinfo_cpu_count(system)
    None => 0.0
  }

  SysinfoRefreshData::{
    system_cpu_usage: Float::from_double(system.global_cpu_usage()),
    system_mem_usage: Float::from_double(system_mem_usage),
    process_cpu_usage: Float::from_double(process_cpu_usage),
    process_mem_usage: Float::from_double(process_mem_usage),
  }
}

///|
fn collect_sysinfo_refresh_data_once() -> SysinfoRefreshData {
  let pid = match @sysinfo.get_current_pid() {
    Ok(pid) => pid
    Err(message) =>
      abort("Failed to get current process id for diagnostics: \{message}")
  }
  let system = @sysinfo.System::new_with_specifics(
    @sysinfo.RefreshKind::nothing()
    .with_cpu(@sysinfo.CpuRefreshKind::nothing().with_cpu_usage())
    .with_memory(@sysinfo.MemoryRefreshKind::everything()),
  )
  collect_sysinfo_refresh_data(system, pid)
}

///|
fn setup_system(commands : @app.Commands) -> Unit {
  commands.insert_resource(SysinfoRefreshState::{
    elapsed_ms: minimum_refresh_interval_ms(),
  })
}

///|
fn refresh_system_information_diagnostics(
  diagnostics : Diagnostics,
  state : @app.ResMut[SysinfoRefreshState],
  time : @app.Res[@time.Time[@time.Real]],
) -> Unit {
  let state_ref = state.get_ref()
  state_ref.val.elapsed_ms = state_ref.val.elapsed_ms +
    time.get().delta().as_millis()
  if state_ref.val.elapsed_ms < minimum_refresh_interval_ms() {
    return
  }

  state_ref.val.elapsed_ms = 0
  apply_sysinfo_refresh_data(diagnostics, collect_sysinfo_refresh_data_once())
}

///|
fn apply_sysinfo_refresh_data(
  diagnostics : Diagnostics,
  data : SysinfoRefreshData,
) -> Unit {
  diagnostics.add_measurement(system_information_diagnostic_system_cpu_usage, fn() {
    data.system_cpu_usage
  })
  diagnostics.add_measurement(system_information_diagnostic_system_mem_usage, fn() {
    data.system_mem_usage
  })
  diagnostics.add_measurement(system_information_diagnostic_process_cpu_usage, fn() {
    data.process_cpu_usage
  })
  diagnostics.add_measurement(system_information_diagnostic_process_mem_usage, fn() {
    data.process_mem_usage
  })
}

///|
pub fn system_information_diagnostics_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  system_information_diagnostics_plugin_with(
    app,
    SystemInformationDiagnosticsPlugin::default(),
  )
}

///|
pub fn system_information_diagnostics_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : SystemInformationDiagnosticsPlugin,
) -> @app.App[@ecs.World] {
  let mut app_ = app
  if app_.contains_resource(system_information_diagnostics_plugin_marker_key) {
    return app_
  }

  app_ = register_diagnostic(
    register_diagnostic(
      register_diagnostic(
        register_diagnostic(
          app_
          .insert_world_resource(
            system_information_diagnostics_plugin_marker_key,
            SystemInformationDiagnosticsPluginMarker::{  },
          )
          .init_resource(fn() { SystemInfo::default() }),
          Diagnostic::new(system_information_diagnostic_system_cpu_usage).with_suffix(
            PROCESS_USAGE_SUFFIX,
          ),
        ),
        Diagnostic::new(system_information_diagnostic_system_mem_usage).with_suffix(
          PROCESS_USAGE_SUFFIX,
        ),
      ),
      Diagnostic::new(system_information_diagnostic_process_cpu_usage).with_suffix(
        PROCESS_USAGE_SUFFIX,
      ),
    ),
    Diagnostic::new(system_information_diagnostic_process_mem_usage).with_suffix(
      "GiB",
    ),
  )

  app_
  .add_startup_system_param(setup_system)
  .add_first_system_param3(refresh_system_information_diagnostics)
}
