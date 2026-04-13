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
test "app: timeline trace captures schedule stage and system spans" {
  let spans : Ref[Array[TimelineTraceSpan]] = Ref::new([])
  set_timeline_trace_span_sink(Some(fn(span) { spans.val.push(span) }))

  let mut app = App::new(@ecs.World::new())
  app = app.add_system_config(
    system(fn(_world : @ecs.World) { ignore(()) }).named("timeline_test_system"),
  )
  app = app.update()

  clear_timeline_trace_span_sink()

  let mut has_stage = false
  let mut has_system = false
  let mut all_non_negative = true
  for span in spans.val {
    if span.category() == TimelineTraceCategory::ScheduleStage {
      has_stage = true
    }
    if span.category() == TimelineTraceCategory::System &&
      span.name() == "timeline_test_system" {
      has_system = true
    }
    if span.ts_us() < 0L || span.dur_us() < 0L {
      all_non_negative = false
    }
  }
  debug_inspect(has_stage, content="true")
  debug_inspect(has_system, content="true")
  debug_inspect(all_non_negative, content="true")
}

///|
test "app: timeline trace disabled path stays no-op" {
  clear_timeline_trace_span_sink()
  debug_inspect(timeline_trace_enabled(), content="false")

  let begin_ts = timeline_trace_begin_span(
    TimelineTraceCategory::System,
    "disabled",
  )
  timeline_trace_end_span(TimelineTraceCategory::System, "disabled", begin_ts)

  debug_inspect(begin_ts, content="-1")
}
