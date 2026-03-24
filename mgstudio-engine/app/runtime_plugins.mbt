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
} derive(Eq, Show)

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
  @ecs.register_message(debug_name="bevy_app::AppExit")
}

///|
pub(all) enum RenderRuntimeError {
  OutOfMemory
  Validation
  DeviceLost
  Loop
  Unknown(String)
} derive(Eq, Show)

///|
pub(all) enum RenderErrorPolicy {
  Ignore
  Panic
  ExitApp
  StopRendering
  Recover
} derive(Eq, Show)

///|
pub type RenderErrorHandler = (RenderRuntimeError) -> RenderErrorPolicy

///|
fn default_render_error_handler(
  _error : RenderRuntimeError,
) -> RenderErrorPolicy {
  RenderErrorPolicy::Recover
}

///|
let render_error_handler_ref : Ref[RenderErrorHandler] = Ref::new(
  default_render_error_handler,
)

///|
let render_runtime_error_ref : Ref[RenderRuntimeError?] = Ref::new(None)

///|
let render_runtime_stopped_ref : Ref[Bool] = Ref::new(false)

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
      abort("render runtime error: " + error.to_string())
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
  let reader = self.world().message_reader(key, Ref::new(0))
  let exits_result : Result[Array[AppExit], @ecs.EcsError] = try? reader.read()
  match exits_result {
    Ok(exits) =>
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
    Err(_) => None
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
let schedule_runner_state_ref : Ref[ScheduleRunnerState] = Ref::new(ScheduleRunnerState::{
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
    let app_ref : Ref[App[@ecs.World]] = Ref::new(app.run_startup())
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
pub fn schedule_runner_plugin(
  plugin : ScheduleRunnerPlugin,
) -> Plugin[@ecs.World] {
  fn(app : App[@ecs.World]) -> App[@ecs.World] {
    let mode = plugin.mode
    app.set_runner(fn(app_with_runner : App[@ecs.World]) {
      schedule_runner_build(app_with_runner, mode)
    })
  }
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
pub(all) struct TaskPoolThreadAssignmentPolicy {
  min_threads : Int
  max_threads : Int
  percent : Float
  on_thread_spawn : (() -> Unit)?
  on_thread_destroy : (() -> Unit)?
}

///|
fn task_pool_assignment_policy(
  min_threads : Int,
  max_threads : Int,
  percent : Float,
) -> TaskPoolThreadAssignmentPolicy {
  TaskPoolThreadAssignmentPolicy::{
    min_threads: if min_threads <= 0 {
      1
    } else {
      min_threads
    },
    max_threads: if max_threads <= 0 {
      1
    } else {
      max_threads
    },
    percent,
    on_thread_spawn: None,
    on_thread_destroy: None,
  }
}

///|
pub fn task_pool_assignment_thread_count(
  policy : TaskPoolThreadAssignmentPolicy,
  remaining_threads : Int,
  total_threads : Int,
) -> Int {
  guard policy.percent >= 0.0F else {
    abort("TaskPoolThreadAssignmentPolicy.percent must be non-negative")
  }

  let proportion = total_threads.to_double() * policy.percent.to_double()
  let mut desired = proportion.to_int()
  if proportion - desired.to_double() >= 0.5 {
    desired = desired + 1
  }
  desired = desired.min(remaining_threads)

  let lower = if policy.min_threads <= 0 { 1 } else { policy.min_threads }
  let upper = if policy.max_threads <= 0 { 1 } else { policy.max_threads }
  desired.max(lower).min(upper)
}

///|
pub struct TaskPoolOptions {
  min_total_threads : Int
  max_total_threads : Int
  io : TaskPoolThreadAssignmentPolicy
  async_compute : TaskPoolThreadAssignmentPolicy
  compute : TaskPoolThreadAssignmentPolicy
}

///|
pub fn TaskPoolOptions::default() -> TaskPoolOptions {
  TaskPoolOptions::{
    min_total_threads: 1,
    max_total_threads: 2_147_483_647,
    io: task_pool_assignment_policy(1, 4, 0.25F),
    async_compute: task_pool_assignment_policy(1, 4, 0.25F),
    compute: task_pool_assignment_policy(1, 2_147_483_647, 1.0F),
  }
}

///|
pub fn TaskPoolOptions::with_num_threads(thread_count : Int) -> TaskPoolOptions {
  let clamped = if thread_count <= 0 { 1 } else { thread_count }
  {
    ..TaskPoolOptions::default(),
    min_total_threads: clamped,
    max_total_threads: clamped,
  }
}

///|
fn task_pool_builder_from_policy(
  thread_count : Int,
  thread_name : String,
  policy : TaskPoolThreadAssignmentPolicy,
) -> @tasks.TaskPool {
  let mut builder = @tasks.TaskPoolBuilder::new()
    .num_threads(thread_count)
    .thread_name(thread_name)
  if policy.on_thread_spawn is Some(callback) {
    builder = builder.on_thread_spawn(callback)
  }
  if policy.on_thread_destroy is Some(callback) {
    builder = builder.on_thread_destroy(callback)
  }
  builder.build()
}

///|
pub fn TaskPoolOptions::create_default_pools(self : TaskPoolOptions) -> Unit {
  let min_total = if self.min_total_threads <= 0 {
    1
  } else {
    self.min_total_threads
  }
  let max_total = if self.max_total_threads <= 0 {
    1
  } else {
    self.max_total_threads
  }
  let total_threads = @tasks.available_parallelism()
    .max(min_total)
    .min(max_total)
  let mut remaining_threads = total_threads

  let io_threads = task_pool_assignment_thread_count(
    self.io,
    remaining_threads,
    total_threads,
  )
  remaining_threads = (remaining_threads - io_threads).max(0)
  ignore(
    @tasks.IoTaskPool::get_or_init(fn() {
      task_pool_builder_from_policy(io_threads, "IO Task Pool", self.io)
    }),
  )

  let async_compute_threads = task_pool_assignment_thread_count(
    self.async_compute,
    remaining_threads,
    total_threads,
  )
  remaining_threads = (remaining_threads - async_compute_threads).max(0)
  ignore(
    @tasks.AsyncComputeTaskPool::get_or_init(fn() {
      task_pool_builder_from_policy(
        async_compute_threads,
        "Async Compute Task Pool",
        self.async_compute,
      )
    }),
  )

  let compute_threads = task_pool_assignment_thread_count(
    self.compute,
    remaining_threads,
    total_threads,
  )
  ignore(
    @tasks.ComputeTaskPool::get_or_init(fn() {
      task_pool_builder_from_policy(
        compute_threads,
        "Compute Task Pool",
        self.compute,
      )
    }),
  )
}

///|
pub struct TaskPoolPlugin {
  task_pool_options : TaskPoolOptions
}

///|
pub fn TaskPoolPlugin::default() -> TaskPoolPlugin {
  TaskPoolPlugin::{ task_pool_options: TaskPoolOptions::default() }
}

///|
pub fn TaskPoolPlugin::new(
  task_pool_options : TaskPoolOptions,
) -> TaskPoolPlugin {
  TaskPoolPlugin::{ task_pool_options, }
}

///|
pub fn[W] task_pool_plugin(plugin : TaskPoolPlugin) -> Plugin[W] {
  fn(app : App[W]) -> App[W] {
    plugin.task_pool_options.create_default_pools()
    app
  }
}

///|
pub(all) enum LogLevel {
  Error
  Warn
  Info
  Debug
  Trace
} derive(Eq, Show)

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
    filter: "",
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
let log_state_ref : Ref[LogState] = Ref::new(LogState::{
  config: LogPlugin::default(),
  once_keys: @hashmap.HashMap::new(),
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
fn log_target_allowed(config : LogPlugin, target : String) -> Bool {
  if config.filter == "" {
    true
  } else if target == "" {
    true
  } else {
    target.contains(config.filter)
  }
}

///|
fn log_emit_default_fmt(record : LogRecord) -> Unit {
  let prefix = if record.target == "" { "" } else { "[" + record.target + "] " }
  println("[" + log_level_label(record.level) + "] " + prefix + record.message)
}

///|
pub fn log_record(
  level : LogLevel,
  message~ : String,
  target? : String = "",
  name? : String = "",
) -> Unit {
  let config = log_state_ref.val.config
  if log_level_rank(level) > log_level_rank(config.level) {
    return
  }
  if !log_target_allowed(config, target) {
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
pub fn[W] log_plugin(plugin : LogPlugin) -> Plugin[W] {
  fn(app : App[W]) -> App[W] {
    log_state_ref.val.config = plugin
    log_state_ref.val.once_keys = @hashmap.HashMap::new()
    app
  }
}

///|
pub fn[W] log_plugin_default(app : App[W]) -> App[W] {
  let plugin : Plugin[W] = log_plugin(LogPlugin::default())
  plugin(app)
}
