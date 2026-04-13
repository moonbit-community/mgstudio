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
pub struct StressDiagnosticsPlugin {}

///|
pub fn StressDiagnosticsPlugin::default() -> StressDiagnosticsPlugin {
  StressDiagnosticsPlugin::{  }
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
let timeline_trace_pending_spans_ref : Ref[Array[@app.TimelineTraceSpan]] = Ref::new([],
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
  timeline_trace_pending_spans_ref.val.push(span)
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
  let pending = timeline_trace_pending_spans_ref.val
  timeline_trace_pending_spans_ref.val = []
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

  timeline_trace_pending_spans_ref.val = []
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
  let log_plugin = LogDiagnosticsPlugin::{
    ..LogDiagnosticsPlugin::filtered([
      frame_time_diagnostic_fps, frame_time_diagnostic_frame_time, frame_time_diagnostic_frame_count,
      render_diagnostic_prepared_cameras_2d, render_diagnostic_queued_draw_items_2d,
      render_diagnostic_queue_cpu_ms_2d, render_diagnostic_execute_cpu_ms_2d, render_diagnostic_prepared_cameras_3d,
      render_diagnostic_visible_meshes_3d, render_diagnostic_queue_cpu_ms_3d, render_diagnostic_execute_cpu_ms_3d,
      render_diagnostic_pass_total_count, render_diagnostic_pass_2d_count, render_diagnostic_pass_3d_main_count,
      render_diagnostic_pass_3d_motion_vector_count, render_diagnostic_pass_3d_point_shadow_count,
      render_diagnostic_pass_total_cpu_ms, render_diagnostic_pass_2d_cpu_ms, render_diagnostic_pass_3d_main_cpu_ms,
      render_diagnostic_pass_3d_motion_vector_cpu_ms, render_diagnostic_pass_3d_point_shadow_cpu_ms,
      render_diagnostic_mesh2d_draw_calls, render_diagnostic_mesh2d_executed_draw_calls,
      render_diagnostic_mesh3d_draw_calls, render_diagnostic_mesh3d_executed_draw_calls,
    ]),
    wait_duration_seconds: 1.0F,
  }
  app.add_plugins([
    frame_time_diagnostics_plugin,
    render_diagnostics_plugin,
    fn(app) { log_diagnostics_plugin_with(app, log_plugin) },
    timeline_trace_plugin,
  ])
}
