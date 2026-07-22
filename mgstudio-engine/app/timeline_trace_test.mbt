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
  let spans : Ref[Array[TimelineTraceSpan]] = Ref([])
  set_timeline_trace_span_sink(Some(fn(span) { spans.val.push(span) }))

  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let mut app = App::new(lifecycle_world_15_0)
  app = app.add_system_config(
    system(fn(_world : @ecs.World) { ignore(()) }).named("timeline_test_system"),
  )
  app = app.update()

  clear_timeline_trace_span_sink()

  let mut has_stage = false
  let mut has_system = false
  let mut all_non_negative = true
  for span in spans.val {
    if span.category() == ScheduleStage {
      has_stage = true
    }
    if span.category() == System && span.name() == "timeline_test_system" {
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
  clear_timeline_trace_counter_sink()
  debug_inspect(timeline_trace_enabled(), content="false")

  let begin_ts = timeline_trace_begin_span(System, "disabled")
  timeline_trace_end_span(System, "disabled", begin_ts)

  debug_inspect(begin_ts, content="-1")
}

///|
test "app: timeline trace pending queue stores and drains spans" {
  clear_timeline_trace_span_sink()
  clear_timeline_trace_counter_sink()
  timeline_trace_clear_pending_spans()
  timeline_trace_clear_pending_counters()

  set_timeline_trace_span_sink(
    Some(fn(span) { timeline_trace_push_pending_span(span) }),
  )
  timeline_trace_emit_complete_span(RenderQueue, "queue_test", 10L, 20L)
  clear_timeline_trace_span_sink()

  let first_batch = timeline_trace_take_pending_spans()
  let second_batch = timeline_trace_take_pending_spans()

  debug_inspect(first_batch.length(), content="1")
  debug_inspect(first_batch[0].name() == "queue_test", content="true")
  debug_inspect(first_batch[0].category() == RenderQueue, content="true")
  debug_inspect(second_batch.length(), content="0")
}

///|
test "app: timeline trace pending queue stores and drains counters" {
  clear_timeline_trace_span_sink()
  clear_timeline_trace_counter_sink()
  timeline_trace_clear_pending_counters()

  set_timeline_trace_counter_sink(
    Some(fn(counter) { timeline_trace_push_pending_counter(counter) }),
  )
  timeline_trace_emit_counter_int("counter_test", 42)
  clear_timeline_trace_counter_sink()

  let first_batch = timeline_trace_take_pending_counters()
  let second_batch = timeline_trace_take_pending_counters()

  debug_inspect(first_batch.length(), content="1")
  debug_inspect(first_batch[0].name() == "counter_test", content="true")
  debug_inspect(first_batch[0].value(), content="42")
  debug_inspect(second_batch.length(), content="0")
}
