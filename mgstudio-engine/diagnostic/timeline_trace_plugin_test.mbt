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
fn timeline_trace_test_output_path() -> String {
  "/tmp/mgstudio_timeline_trace_test_\{@core.Instant::now().as_duration_since_start().as_nanos().to_string()}.json"
}

///|
test "diagnostics: timeline trace plugin writes filtered chrome trace json" {
  let output_path = timeline_trace_test_output_path()
  let config = TimelineTraceConfig::default()
    .with_enabled(true)
    .with_output_path(output_path)
    .with_flush_interval_frames(1)
    .with_categories([@app.TimelineTraceCategory::System])
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    TimelineTracePlugin::with_config(config),
  )
  app = app.add_system_config(
    @app.system(fn(_world : @ecs.World) { ignore(()) }).named(
      "timeline_trace_test_system",
    ),
  )
  app = app.update()

  let json_text = @fs.read_file_to_string(output_path) catch { _ => "" }
  debug_inspect(json_text.contains("\"traceEvents\""), content="true")
  debug_inspect(json_text.contains("\"cat\":\"system\""), content="true")
  debug_inspect(
    json_text.contains("\"name\":\"timeline_trace_test_system\""),
    content="true",
  )
  debug_inspect(
    !json_text.contains("\"cat\":\"schedule_stage\""),
    content="true",
  )
}

///|
test "diagnostics: timeline trace plugin captures direct render queue spans" {
  let output_path = timeline_trace_test_output_path()
  let config = TimelineTraceConfig::default()
    .with_enabled(true)
    .with_output_path(output_path)
    .with_flush_interval_frames(1)
    .with_categories([@app.TimelineTraceCategory::RenderQueue])
  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    TimelineTracePlugin::with_config(config),
  )
  app = app.add_system_config(
    @app.system(fn(_world : @ecs.World) {
      let trace_start_us = @app.timeline_trace_begin_span(
        @app.TimelineTraceCategory::RenderQueue,
        "queue_2d",
      )
      @app.timeline_trace_end_span(
        @app.TimelineTraceCategory::RenderQueue,
        "queue_2d",
        trace_start_us,
      )
    }),
  )
  app = app.update()

  let json_text = @fs.read_file_to_string(output_path) catch { _ => "" }
  debug_inspect(json_text.contains("\"cat\":\"render_queue\""), content="true")
  debug_inspect(json_text.contains("\"name\":\"queue_2d\""), content="true")
}

///|
test "diagnostics: stress diagnostics plugin installs lightweight metrics by default" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@time.TimePlugin::default())
    .add_plugins(StressDiagnosticsPlugin::default())
    .update()
  debug_inspect(
    stress_diagnostics_has_lightweight_metrics(app),
    content="true",
  )
}
