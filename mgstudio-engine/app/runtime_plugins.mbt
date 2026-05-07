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
/// App exit signal, aligned with Bevy's `AppExit`.
pub(all) enum AppExit {
  Success
  Error(Int)
} derive(Eq, Debug)

///|
pub fn AppExit::error() -> AppExit {
  Error(1)
}

///|
pub fn AppExit::is_success(self : AppExit) -> Bool {
  match self {
    Success => true
    Error(_) => false
  }
}

///|
pub fn AppExit::is_error(self : AppExit) -> Bool {
  !self.is_success()
}

///|
pub fn AppExit::from_code(code : Int) -> AppExit {
  if code <= 0 {
    Success
  } else {
    Error(code)
  }
}

///|
fn app_exit_message_key() -> @ecs.MessageKey[AppExit] {
  @ecs.Message::message()
}

///|
pub impl @ecs.Message for AppExit with message() {
  @ecs.register_message(debug_name="mgstudio_app::AppExit")
}

///|
pub(all) enum RenderRuntimeError {
  OutOfMemory
  Validation
  DeviceLost
  Loop
  Unknown(String)
} derive(Eq, Debug)

///|
pub(all) enum RenderErrorPolicy {
  Ignore
  Panic
  ExitApp
  StopRendering
  Recover
} derive(Eq, Debug)

///|
pub type RenderErrorHandler = (RenderRuntimeError) -> RenderErrorPolicy

///|
fn default_render_error_handler(
  _error : RenderRuntimeError,
) -> RenderErrorPolicy {
  RenderErrorPolicy::Recover
}

///|
let render_error_handler_ref : Ref[RenderErrorHandler] = Ref(
  default_render_error_handler,
)

///|
let render_runtime_error_ref : Ref[RenderRuntimeError?] = Ref(None)

///|
let render_runtime_stopped_ref : Ref[Bool] = Ref(false)

///|
pub fn render_runtime_error() -> RenderRuntimeError? {
  render_runtime_error_ref.val
}

///|
pub fn app_rendering_enabled() -> Bool {
  !render_runtime_stopped_ref.val
}

///|
pub fn app_rendering_stop() -> Unit {
  render_runtime_stopped_ref.val = true
}

///|
pub fn app_rendering_resume() -> Unit {
  render_runtime_stopped_ref.val = false
}

///|
pub fn set_render_error_handler(handler : RenderErrorHandler) -> Unit {
  render_error_handler_ref.val = handler
}

///|
pub fn reset_render_error_handler() -> Unit {
  render_error_handler_ref.val = default_render_error_handler
}

///|
pub fn report_render_runtime_error(error : RenderRuntimeError) -> Unit {
  render_runtime_error_ref.val = Some(error)
  match (render_error_handler_ref.val)(error) {
    RenderErrorPolicy::Ignore => ()
    RenderErrorPolicy::Panic =>
      abort("render runtime error: \{to_repr(error).to_string()}")
    RenderErrorPolicy::ExitApp => {
      if current_world() is Some(world) {
        let key = app_exit_message_key()
        if !world.contains_message(key) {
          world.init_message(key)
        }
        ignore(world.send_message(key, AppExit::error()))
      }
      render_runtime_stopped_ref.val = true
    }
    RenderErrorPolicy::StopRendering => render_runtime_stopped_ref.val = true
    RenderErrorPolicy::Recover => render_runtime_stopped_ref.val = false
  }
}

///|
pub fn app_runtime_reset() -> Unit {
  render_runtime_error_ref.val = None
  render_runtime_stopped_ref.val = false
  render_error_handler_ref.val = default_render_error_handler
  host_app_reset_close()
}

///|
pub fn App::should_exit(self : App[@ecs.World]) -> AppExit? {
  let key = app_exit_message_key()
  if !self.world().contains_message(key) {
    return None
  }
  let reader = self.world().message_reader(key, Ref(0))
  let exits = reader.read() catch { _ => return None }
  if exits.length() == 0 {
    None
  } else {
    for exit in exits {
      if exit.is_error() {
        return Some(exit)
      }
    }
    Some(AppExit::Success)
  }
}

///|
pub(all) enum ScheduleRunnerMode {
  RunOnce
  RunLoop(Float)
}

///|
pub struct ScheduleRunnerPlugin {
  mode : ScheduleRunnerMode
}

///|
pub fn ScheduleRunnerPlugin::run_once() -> ScheduleRunnerPlugin {
  ScheduleRunnerPlugin::{ mode: RunOnce }
}

///|
pub fn ScheduleRunnerPlugin::run_loop(
  interval_seconds : Float,
) -> ScheduleRunnerPlugin {
  let clamped = if interval_seconds < 0.0F { 0.0F } else { interval_seconds }
  ScheduleRunnerPlugin::{ mode: RunLoop(clamped) }
}

///|
priv struct ScheduleRunnerState {
  mut tick : RunnerFn?
}

///|
let schedule_runner_state_ref : Ref[ScheduleRunnerState] = Ref(ScheduleRunnerState::{
  tick: None,
})

///|
fn schedule_runner_tick() -> Unit {
  if schedule_runner_state_ref.val.tick is Some(tick) {
    tick()
  }
}

///|
fn schedule_runner_build(
  app : App[@ecs.World],
  mode : ScheduleRunnerMode,
) -> RunnerFn {
  fn() {
    let app_ref : Ref[App[@ecs.World]] = Ref(app.run_startup())
    match mode {
      RunOnce => app_ref.val = app_ref.val.run_once()
      RunLoop(interval_seconds) => {
        host_app_reset_close()
        schedule_runner_state_ref.val.tick = Some(fn() {
          app_ref.val = app_ref.val.run_once()
          if app_ref.val.should_exit() is Some(_) {
            host_app_request_close()
            schedule_runner_state_ref.val.tick = None
          }
        })
        let step : FuncRef[() -> Unit] = fn() { schedule_runner_tick() }
        let interval_ms = if interval_seconds <= 0.0F {
          0
        } else {
          (interval_seconds * 1000.0F).to_int()
        }
        host_app_run_loop(step, interval_ms~)
        schedule_runner_state_ref.val.tick = None
      }
    }
  }
}

///|
pub impl Plugin for ScheduleRunnerPlugin with name(_self) {
  "mgstudio.app.ScheduleRunnerPlugin"
}

///|
pub impl Plugin for ScheduleRunnerPlugin with build(self, app) {
  let mode = self.mode
  app.set_runner(fn(app_with_runner : App[@ecs.World]) {
    schedule_runner_build(app_with_runner, mode)
  })
}

///|
pub fn app_stdin_read_line() -> String? {
  let len = host_app_stdin_read_line_len()
  if len < 0 {
    return None
  }
  let chars : Array[Char] = []
  for i in 0..<len {
    let code_unit = host_app_stdin_read_line_code_unit(offset=i)
    if code_unit.to_char() is Some(ch) {
      chars.push(ch)
    } else {
      chars.push(Int::unsafe_to_char(0xFFFD))
    }
  }
  Some(String::from_array(chars))
}

///|
pub(all) enum LogLevel {
  Error
  Warn
  Info
  Debug
  Trace
} derive(Eq, Debug)

///|
pub struct LogRecord {
  level : LogLevel
  target : String
  name : String
  message : String
}

///|
pub fn LogRecord::level(self : LogRecord) -> LogLevel {
  self.level
}

///|
pub fn LogRecord::target(self : LogRecord) -> String {
  self.target
}

///|
pub fn LogRecord::name(self : LogRecord) -> String {
  self.name
}

///|
pub fn LogRecord::message(self : LogRecord) -> String {
  self.message
}

///|
pub type LogLayer = (LogRecord) -> Unit

///|
pub const DEFAULT_LOG_FILTER : String = "wgpu=error,naga=warn,moon_wgsl=warn,calloop::loop_logic=error,"

///|
pub struct LogPlugin {
  level : LogLevel
  filter : String
  custom_layer : LogLayer?
  fmt_layer : LogLayer?
}

///|
pub fn LogPlugin::default() -> LogPlugin {
  LogPlugin::{
    level: LogLevel::Info,
    filter: DEFAULT_LOG_FILTER,
    custom_layer: None,
    fmt_layer: None,
  }
}

///|
pub fn LogPlugin::with_level(self : LogPlugin, level : LogLevel) -> LogPlugin {
  LogPlugin::{ ..self, level, }
}

///|
pub fn LogPlugin::with_filter(self : LogPlugin, filter : String) -> LogPlugin {
  LogPlugin::{ ..self, filter, }
}

///|
pub fn LogPlugin::with_custom_layer(
  self : LogPlugin,
  custom_layer : LogLayer,
) -> LogPlugin {
  LogPlugin::{ ..self, custom_layer: Some(custom_layer) }
}

///|
pub fn LogPlugin::with_fmt_layer(
  self : LogPlugin,
  fmt_layer : LogLayer,
) -> LogPlugin {
  LogPlugin::{ ..self, fmt_layer: Some(fmt_layer) }
}

///|
priv struct LogState {
  mut config : LogPlugin
  mut once_keys : @hashmap.HashMap[String, Bool]
}

///|
let log_state_ref : Ref[LogState] = Ref(LogState::{
  config: LogPlugin::default(),
  once_keys: @hashmap.HashMap([]),
})

///|
fn log_level_rank(level : LogLevel) -> Int {
  match level {
    Error => 1
    Warn => 2
    Info => 3
    Debug => 4
    Trace => 5
  }
}

///|
fn log_level_label(level : LogLevel) -> String {
  match level {
    Error => "ERROR"
    Warn => "WARN"
    Info => "INFO"
    Debug => "DEBUG"
    Trace => "TRACE"
  }
}

///|
fn log_level_from_filter_value(value : String) -> LogLevel? {
  match value.trim().to_owned().to_lower() {
    "error" => Some(LogLevel::Error)
    "warn" => Some(LogLevel::Warn)
    "warning" => Some(LogLevel::Warn)
    "info" => Some(LogLevel::Info)
    "debug" => Some(LogLevel::Debug)
    "trace" => Some(LogLevel::Trace)
    _ => None
  }
}

///|
fn log_filter_target_matches(target : String, filter_target : String) -> Bool {
  if filter_target == "" {
    false
  } else {
    target == filter_target || target.has_prefix("\{filter_target}::")
  }
}

///|
fn log_effective_level(config : LogPlugin, target : String) -> LogLevel {
  let mut effective = config.level
  let mut best_target_len = -1
  for raw_directive in config.filter.split(",") {
    let directive = raw_directive.trim().to_owned()
    if directive == "" {
      continue
    }
    let parts : Array[String] = []
    for part in directive.split("=") {
      parts.push(part.to_owned())
    }
    if parts.length() == 1 {
      if log_level_from_filter_value(parts[0].to_string()) is Some(level) {
        effective = level
      }
    } else {
      let filter_target = parts[0].trim().to_owned()
      let level_value = parts[1].trim().to_owned()
      if log_filter_target_matches(target, filter_target) &&
        filter_target.length() > best_target_len &&
        log_level_from_filter_value(level_value) is Some(level) {
        effective = level
        best_target_len = filter_target.length()
      }
    }
  }
  effective
}

///|
fn log_emit_default_fmt(record : LogRecord) -> Unit {
  let prefix = if record.target == "" { "" } else { "[\{record.target}] " }
  println("[\{log_level_label(record.level)}] \{prefix}\{record.message}")
}

///|
pub fn log_record(
  level : LogLevel,
  message~ : String,
  target? : String = "",
  name? : String = "",
) -> Unit {
  let config = log_state_ref.val.config
  if log_level_rank(level) > log_level_rank(log_effective_level(config, target)) {
    return
  }

  let record = LogRecord::{ level, target, name, message }

  if config.fmt_layer is Some(fmt_layer) {
    fmt_layer(record)
  } else {
    log_emit_default_fmt(record)
  }
  if config.custom_layer is Some(custom_layer) {
    custom_layer(record)
  }
}

///|
pub fn log_once(
  level : LogLevel,
  callsite~ : String,
  message~ : String,
  target? : String = "",
  name? : String = "",
) -> Unit {
  if log_state_ref.val.once_keys.contains(callsite) {
    return
  }
  log_state_ref.val.once_keys.set(callsite, true)
  log_record(level, message~, target~, name~)
}

///|
pub fn log_once_with(
  level : LogLevel,
  callsite~ : String,
  producer : () -> String,
  target? : String = "",
  name? : String = "",
) -> Unit {
  if log_state_ref.val.once_keys.contains(callsite) {
    return
  }
  log_state_ref.val.once_keys.set(callsite, true)
  let message = producer()
  log_record(level, message~, target~, name~)
}

///|
pub fn log_error(message : String) -> Unit {
  log_record(LogLevel::Error, message~)
}

///|
pub fn log_warn(message : String) -> Unit {
  log_record(LogLevel::Warn, message~)
}

///|
pub fn log_info(message : String) -> Unit {
  log_record(LogLevel::Info, message~)
}

///|
pub fn log_debug(message : String) -> Unit {
  log_record(LogLevel::Debug, message~)
}

///|
pub fn log_trace(message : String) -> Unit {
  log_record(LogLevel::Trace, message~)
}

///|
pub fn log_error_once(callsite : String, message : String) -> Unit {
  log_once(LogLevel::Error, callsite~, message~)
}

///|
pub fn log_warn_once(callsite : String, message : String) -> Unit {
  log_once(LogLevel::Warn, callsite~, message~)
}

///|
pub fn log_info_once(callsite : String, message : String) -> Unit {
  log_once(LogLevel::Info, callsite~, message~)
}

///|
pub fn log_debug_once(callsite : String, message : String) -> Unit {
  log_once(LogLevel::Debug, callsite~, message~)
}

///|
pub fn log_trace_once(callsite : String, message : String) -> Unit {
  log_once(LogLevel::Trace, callsite~, message~)
}

///|
pub impl Plugin for LogPlugin with name(_self) {
  "mgstudio.log.LogPlugin"
}

///|
pub impl Plugin for LogPlugin with build(self, app) {
  log_state_ref.val.config = self
  log_state_ref.val.once_keys = @hashmap.HashMap([])
  app
}
