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
const TIMELINE_TRACE_ENV_ENABLED : String = "MGSTUDIO_TIMELINE_TRACE"

///|
const TIMELINE_TRACE_ENV_OUTPUT : String = "MGSTUDIO_TIMELINE_TRACE_OUTPUT"

///|
const TIMELINE_TRACE_ENV_FLUSH_FRAMES : String = "MGSTUDIO_TIMELINE_TRACE_FLUSH_FRAMES"

///|
const TIMELINE_TRACE_ENV_CATEGORIES : String = "MGSTUDIO_TIMELINE_TRACE_CATEGORIES"

///|
const TIMELINE_TRACE_PLUGIN_NAME : String = "mgstudio.diagnostic.TimelineTracePlugin"

///|
const STRESS_DIAGNOSTICS_PLUGIN_NAME : String = "mgstudio.diagnostic.StressDiagnosticsPlugin"

///|
const STRESS_DIAGNOSTICS_ENV_GENERIC : String = "MGSTUDIO_STRESS_USE_GENERIC_DIAGNOSTICS"

///|
pub struct TimelineTraceConfig {
  enabled : Bool
  output_path : String
  flush_interval_frames : Int
  categories : Array[@app.TimelineTraceCategory]
}

///|
fn timeline_trace_default_categories() -> Array[@app.TimelineTraceCategory] {
  [
    @app.TimelineTraceCategory::ScheduleStage,
    @app.TimelineTraceCategory::System,
    @app.TimelineTraceCategory::RenderPass,
    @app.TimelineTraceCategory::RenderQueue,
  ]
}

///|
pub fn TimelineTraceConfig::default() -> TimelineTraceConfig {
  TimelineTraceConfig::{
    enabled: false,
    output_path: "/tmp/mgstudio_timeline_trace.json",
    flush_interval_frames: 60,
    categories: timeline_trace_default_categories(),
  }
}

///|
pub fn TimelineTraceConfig::with_enabled(
  self : TimelineTraceConfig,
  enabled : Bool,
) -> TimelineTraceConfig {
  TimelineTraceConfig::{ ..self, enabled, }
}

///|
pub fn TimelineTraceConfig::with_output_path(
  self : TimelineTraceConfig,
  output_path : String,
) -> TimelineTraceConfig {
  TimelineTraceConfig::{ ..self, output_path, }
}

///|
pub fn TimelineTraceConfig::with_flush_interval_frames(
  self : TimelineTraceConfig,
  flush_interval_frames : Int,
) -> TimelineTraceConfig {
  TimelineTraceConfig::{ ..self, flush_interval_frames, }
}

///|
pub fn TimelineTraceConfig::with_categories(
  self : TimelineTraceConfig,
  categories : Array[@app.TimelineTraceCategory],
) -> TimelineTraceConfig {
  TimelineTraceConfig::{ ..self, categories, }
}

///|
pub struct TimelineTracePlugin {
  config : TimelineTraceConfig
}

///|
pub fn TimelineTracePlugin::default() -> TimelineTracePlugin {
  TimelineTracePlugin::{ config: TimelineTraceConfig::default() }
}

///|
pub fn TimelineTracePlugin::with_config(
  config : TimelineTraceConfig,
) -> TimelineTracePlugin {
  TimelineTracePlugin::{ config, }
}

///|
pub impl @app.Plugin for TimelineTracePlugin with name(_self) {
  TIMELINE_TRACE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for TimelineTracePlugin with build(self, app) {
  timeline_trace_plugin_with(app, self)
}

///|
pub struct StressDiagnosticsPlugin {
  use_generic_stack : Bool?
  log_interval_seconds : Float
}

///|
pub fn StressDiagnosticsPlugin::default() -> StressDiagnosticsPlugin {
  StressDiagnosticsPlugin::{
    use_generic_stack: None,
    log_interval_seconds: 1.0F,
  }
}

///|
pub fn StressDiagnosticsPlugin::with_use_generic_stack(
  self : StressDiagnosticsPlugin,
  use_generic_stack : Bool,
) -> StressDiagnosticsPlugin {
  StressDiagnosticsPlugin::{
    ..self,
    use_generic_stack: Some(use_generic_stack),
  }
}

///|
pub fn StressDiagnosticsPlugin::with_log_interval_seconds(
  self : StressDiagnosticsPlugin,
  log_interval_seconds : Float,
) -> StressDiagnosticsPlugin {
  StressDiagnosticsPlugin::{ ..self, log_interval_seconds, }
}

///|
pub impl @app.Plugin for StressDiagnosticsPlugin with name(_self) {
  STRESS_DIAGNOSTICS_PLUGIN_NAME
}

///|
pub impl @app.Plugin for StressDiagnosticsPlugin with build(self, app) {
  stress_diagnostics_plugin_with(app, self)
}

///|
priv struct StressMetricsState {
  mut timer : @time.Timer
  mut frame_count : Int
  mut elapsed_seconds : Float
}

///|
fn stress_metrics_state_default(
  log_interval_seconds : Float,
) -> StressMetricsState {
  {
    timer: @time.Timer::from_seconds(log_interval_seconds, @time.Repeating),
    frame_count: 0,
    elapsed_seconds: 0.0F,
  }
}

///|
let stress_metrics_state_key : @ecs.ResourceKey[StressMetricsState] = @ecs.register_resource(
  debug_name="mgstudio_diagnostic::StressMetricsState",
)

///|
impl @app.Resource for StressMetricsState with resource() {
  stress_metrics_state_key
}

///|
fn stress_diagnostics_use_generic_stack() -> Bool {
  match @sys.get_env_var(STRESS_DIAGNOSTICS_ENV_GENERIC) {
    Some(raw) => {
      let token = raw.trim().to_string()
      token == "1" ||
      token == "true" ||
      token == "TRUE" ||
      token == "yes" ||
      token == "YES" ||
      token == "on" ||
      token == "ON"
    }
    None => false
  }
}

///|
fn stress_diagnostics_resolve_generic_stack(
  plugin : StressDiagnosticsPlugin,
) -> Bool {
  match plugin.use_generic_stack {
    Some(value) => value
    None => stress_diagnostics_use_generic_stack()
  }
}

///|
fn stress_metrics_system(
  state : @app.ResMut[StressMetricsState],
  time : @app.Res[@time.Time[@time.Real]],
) -> Unit {
  let state_value = state.peek()
  state.set_changed()
  let delta = time.get().delta()
  let delta_seconds = time.get().delta_seconds()
  if delta_seconds < 0.0F {
    return
  }
  state_value.frame_count = state_value.frame_count + 1
  state_value.elapsed_seconds = state_value.elapsed_seconds + delta_seconds
  state_value.timer = state_value.timer.tick(delta)
  if !state_value.timer.is_finished() || state_value.elapsed_seconds <= 0.0F {
    return
  }
  let frame_count = state_value.frame_count
  let fps = Float::from_int(frame_count) / state_value.elapsed_seconds
  let frame_time_ms = state_value.elapsed_seconds *
    1000.0F /
    Float::from_int(frame_count)
  @app.log_record(
    @app.Info,
    message="fps: \{fps.to_string()} (avg \{fps.to_string()})",
    target="mgstudio_diagnostic",
  )
  @app.log_record(
    @app.Info,
    message="frame_time: \{frame_time_ms.to_string()}ms (avg \{frame_time_ms.to_string()}ms)",
    target="mgstudio_diagnostic",
  )
  @app.log_record(
    @app.Info,
    message="frame_count: \{frame_count.to_string()}",
    target="mgstudio_diagnostic",
  )
}

///|
priv struct TimelineTraceState {
  config : TimelineTraceConfig
  events_json_lines : Array[String]
  mut frame_count_since_flush : Int
}

///|
let timeline_trace_state_resource_key : @ecs.ResourceKey[TimelineTraceState] = @ecs.register_resource(
  debug_name="mgstudio_diagnostic::TimelineTraceState",
)

///|
fn timeline_trace_env_enabled(default_value : Bool) -> Bool {
  match @sys.get_env_var(TIMELINE_TRACE_ENV_ENABLED) {
    Some(raw) => {
      let token = raw.trim().to_string()
      token == "1" ||
      token == "true" ||
      token == "TRUE" ||
      token == "yes" ||
      token == "YES" ||
      token == "on" ||
      token == "ON"
    }
    None => default_value
  }
}

///|
fn timeline_trace_env_string(default_value : String, key : String) -> String {
  match @sys.get_env_var(key) {
    Some(raw) => {
      let token = raw.trim().to_string()
      if token == "" {
        default_value
      } else {
        token
      }
    }
    None => default_value
  }
}

///|
fn timeline_trace_env_int(default_value : Int, key : String) -> Int {
  match @sys.get_env_var(key) {
    Some(raw) => {
      let token = raw.trim().to_string()
      if token == "" {
        default_value
      } else {
        @string.parse_int(token[:], base=10) catch {
          _ => default_value
        }
      }
    }
    None => default_value
  }
}

///|
fn timeline_trace_parse_category(token : String) -> @app.TimelineTraceCategory? {
  match token.trim().to_string() {
    "schedule_stage" | "ScheduleStage" | "stage" =>
      Some(@app.TimelineTraceCategory::ScheduleStage)
    "system" | "System" => Some(@app.TimelineTraceCategory::System)
    "render_pass" | "RenderPass" | "pass" =>
      Some(@app.TimelineTraceCategory::RenderPass)
    "render_queue" | "RenderQueue" | "queue" =>
      Some(@app.TimelineTraceCategory::RenderQueue)
    _ => None
  }
}

///|
fn timeline_trace_env_categories(
  default_value : Array[@app.TimelineTraceCategory],
) -> Array[@app.TimelineTraceCategory] {
  match @sys.get_env_var(TIMELINE_TRACE_ENV_CATEGORIES) {
    Some(raw) => {
      let categories : Array[@app.TimelineTraceCategory] = []
      for part in raw.split(",") {
        let token = part.trim().to_string()
        if token == "" {
          continue
        }
        if timeline_trace_parse_category(token) is Some(category) {
          categories.push(category)
        }
      }
      if categories.length() == 0 {
        default_value
      } else {
        categories
      }
    }
    None => default_value
  }
}

///|
fn timeline_trace_resolved_config(
  config : TimelineTraceConfig,
) -> TimelineTraceConfig {
  let enabled = timeline_trace_env_enabled(config.enabled)
  let output_path = timeline_trace_env_string(
    config.output_path,
    TIMELINE_TRACE_ENV_OUTPUT,
  )
  let flush_interval_frames = timeline_trace_env_int(
    config.flush_interval_frames,
    TIMELINE_TRACE_ENV_FLUSH_FRAMES,
  )
  let categories = timeline_trace_env_categories(config.categories)
  TimelineTraceConfig::{
    enabled,
    output_path,
    flush_interval_frames: if flush_interval_frames <= 0 {
      1
    } else {
      flush_interval_frames
    },
    categories,
  }
}

///|
fn timeline_trace_category_enabled(
  config : TimelineTraceConfig,
  category : @app.TimelineTraceCategory,
) -> Bool {
  for allowed in config.categories {
    if allowed == category {
      return true
    }
  }
  false
}

///|
fn timeline_trace_capture_span(span : @app.TimelineTraceSpan) -> Unit {
  @app.timeline_trace_push_pending_span(span)
}

///|
fn timeline_trace_json_escape(value : String) -> String {
  let chars : Array[Char] = []
  for ch in value {
    match ch {
      '\"' => {
        chars.push('\\')
        chars.push('\"')
      }
      '\\' => {
        chars.push('\\')
        chars.push('\\')
      }
      '\n' => {
        chars.push('\\')
        chars.push('n')
      }
      '\r' => {
        chars.push('\\')
        chars.push('r')
      }
      '\t' => {
        chars.push('\\')
        chars.push('t')
      }
      _ => chars.push(ch)
    }
  }
  String::from_array(chars)
}

///|
fn timeline_trace_event_json_line(
  category : @app.TimelineTraceCategory,
  name : String,
  ts_us : Int64,
  dur_us : Int64,
) -> String {
  let safe_ts = if ts_us >= 0L { ts_us } else { 0L }
  let safe_dur = if dur_us >= 0L { dur_us } else { 0L }
  let safe_name = timeline_trace_json_escape(name)
  let safe_category = timeline_trace_json_escape(
    @app.timeline_trace_category_label(category),
  )
  "{\"name\":\"\{safe_name}\",\"cat\":\"\{safe_category}\",\"ph\":\"X\",\"ts\":\{safe_ts.to_string()},\"dur\":\{safe_dur.to_string()},\"pid\":1,\"tid\":0}"
}

///|
fn timeline_trace_ensure_parent_dir(path : String) -> Unit {
  let path_value : @path.Path = path
  let parent = path_value.dirname().to_string()
  if parent == "" || parent == "." || parent == path {
    return
  }
  if @fs.path_exists(parent) {
    return
  }
  timeline_trace_ensure_parent_dir(parent)
  @fs.create_dir(parent) catch {
    _ => ()
  }
}

///|
fn timeline_trace_flush_to_disk(state : TimelineTraceState) -> Unit {
  timeline_trace_ensure_parent_dir(state.config.output_path)
  let mut output = "{\"traceEvents\":["
  for i in 0..<state.events_json_lines.length() {
    if i > 0 {
      output = "\{output},"
    }
    output = "\{output}\{state.events_json_lines[i]}"
  }
  output = "\{output}],\"displayTimeUnit\":\"ms\"}"
  @fs.write_string_to_file(state.config.output_path, output) catch {
    _ => ()
  }
}

///|
fn timeline_trace_append_pending_spans(state : TimelineTraceState) -> Unit {
  let pending = @app.timeline_trace_take_pending_spans()
  for span in pending {
    if !timeline_trace_category_enabled(state.config, span.category()) {
      continue
    }
    state.events_json_lines.push(
      timeline_trace_event_json_line(
        span.category(),
        span.name(),
        span.ts_us(),
        span.dur_us(),
      ),
    )
  }
}

///|
fn timeline_trace_flush_system(world : @ecs.World) -> Unit {
  guard (try! world.get_resource_ref_mut(timeline_trace_state_resource_key))
    is Some(state_ref) else {
    return
  }
  if !state_ref.val.config.enabled {
    return
  }
  timeline_trace_append_pending_spans(state_ref.val)
  state_ref.val.frame_count_since_flush = state_ref.val.frame_count_since_flush +
    1
  if state_ref.val.frame_count_since_flush >=
    state_ref.val.config.flush_interval_frames {
    timeline_trace_flush_to_disk(state_ref.val)
    state_ref.val.frame_count_since_flush = 0
  }
}

///|
let timeline_trace_plugin_marker_key : @ecs.ResourceKey[Bool] = @ecs.register_resource(
  debug_name="mgstudio_diagnostic::TimelineTracePluginMarker",
)

///|
pub fn timeline_trace_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  timeline_trace_plugin_with(app, TimelineTracePlugin::default())
}

///|
pub fn timeline_trace_plugin_with(
  app : @app.App[@ecs.World],
  plugin : TimelineTracePlugin,
) -> @app.App[@ecs.World] {
  let config = timeline_trace_resolved_config(plugin.config)
  if app.contains_resource(timeline_trace_plugin_marker_key) {
    return app
  }

  let mut app_ = app
    .insert_world_resource(timeline_trace_plugin_marker_key, true)
    .insert_world_resource(timeline_trace_state_resource_key, TimelineTraceState::{
      config,
      events_json_lines: [],
      frame_count_since_flush: 0,
    })

  @app.timeline_trace_clear_pending_spans()
  if config.enabled {
    @app.set_timeline_trace_span_sink(Some(timeline_trace_capture_span))
    app_ = app_.add_post_update_system(timeline_trace_flush_system)
  } else {
    @app.clear_timeline_trace_span_sink()
  }
  app_
}

///|
pub fn stress_diagnostics_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  stress_diagnostics_plugin_with(app, StressDiagnosticsPlugin::default())
}

///|
pub fn stress_diagnostics_has_lightweight_metrics(
  app : @app.App[@ecs.World],
) -> Bool {
  app.contains_resource(stress_metrics_state_key)
}

///|
pub fn stress_diagnostics_plugin_with(
  app : @app.App[@ecs.World],
  plugin : StressDiagnosticsPlugin,
) -> @app.App[@ecs.World] {
  if !stress_diagnostics_resolve_generic_stack(plugin) {
    let next = if app.contains_resource(stress_metrics_state_key) {
      app
    } else {
      app.insert_world_resource(
        stress_metrics_state_key,
        stress_metrics_state_default(plugin.log_interval_seconds),
      )
    }
    return next
      .add_systems(
        @app.PostUpdate,
        @app.system(@app.system_param2(stress_metrics_system)),
      )
      .add_plugins(TimelineTracePlugin::default())
  }
  let include_render_diagnostics = match
    @sys.get_env_var("MGSTUDIO_STRESS_INCLUDE_RENDER_DIAGNOSTICS") {
    Some(value) => value == "1" || value == "true" || value == "TRUE"
    None => false
  }
  let filtered_paths = [
    frame_time_diagnostic_fps, frame_time_diagnostic_frame_time, frame_time_diagnostic_frame_count,
  ]
  if include_render_diagnostics {
    filtered_paths.push(render_diagnostic_prepared_cameras_2d)
    filtered_paths.push(render_diagnostic_queued_draw_items_2d)
    filtered_paths.push(render_diagnostic_queue_cpu_ms_2d)
    filtered_paths.push(render_diagnostic_execute_cpu_ms_2d)
    filtered_paths.push(render_diagnostic_prepared_cameras_3d)
    filtered_paths.push(render_diagnostic_visible_meshes_3d)
    filtered_paths.push(render_diagnostic_queue_cpu_ms_3d)
    filtered_paths.push(render_diagnostic_execute_cpu_ms_3d)
    filtered_paths.push(render_diagnostic_pass_total_count)
    filtered_paths.push(render_diagnostic_pass_2d_count)
    filtered_paths.push(render_diagnostic_pass_3d_main_count)
    filtered_paths.push(render_diagnostic_pass_3d_motion_vector_count)
    filtered_paths.push(render_diagnostic_pass_3d_point_shadow_count)
    filtered_paths.push(render_diagnostic_pass_total_cpu_ms)
    filtered_paths.push(render_diagnostic_pass_2d_cpu_ms)
    filtered_paths.push(render_diagnostic_pass_3d_main_cpu_ms)
    filtered_paths.push(render_diagnostic_pass_3d_motion_vector_cpu_ms)
    filtered_paths.push(render_diagnostic_pass_3d_point_shadow_cpu_ms)
    filtered_paths.push(render_diagnostic_mesh2d_draw_calls)
    filtered_paths.push(render_diagnostic_mesh2d_executed_draw_calls)
    filtered_paths.push(render_diagnostic_mesh3d_draw_calls)
    filtered_paths.push(render_diagnostic_mesh3d_executed_draw_calls)
  }
  let log_plugin = LogDiagnosticsPlugin::{
    ..LogDiagnosticsPlugin::filtered(filtered_paths),
    wait_duration_seconds: plugin.log_interval_seconds,
  }
  let mut next = app
    .add_plugins(FrameTimeDiagnosticsPlugin::default())
    .add_plugins(log_plugin)
    .add_plugins(TimelineTracePlugin::default())
  if include_render_diagnostics {
    next = next.add_plugins(RenderDiagnosticsPlugin::default())
  }
  next
}
