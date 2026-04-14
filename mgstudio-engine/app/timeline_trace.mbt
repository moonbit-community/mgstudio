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
pub(all) enum TimelineTraceCategory {
  ScheduleStage
  System
  RenderPass
  RenderQueue
} derive(Eq, Debug)

///|
pub struct TimelineTraceSpan {
  category : TimelineTraceCategory
  name : String
  ts_us : Int64
  dur_us : Int64
}

///|
pub fn TimelineTraceSpan::category(
  self : TimelineTraceSpan,
) -> TimelineTraceCategory {
  self.category
}

///|
pub fn TimelineTraceSpan::name(self : TimelineTraceSpan) -> String {
  self.name
}

///|
pub fn TimelineTraceSpan::ts_us(self : TimelineTraceSpan) -> Int64 {
  self.ts_us
}

///|
pub fn TimelineTraceSpan::dur_us(self : TimelineTraceSpan) -> Int64 {
  self.dur_us
}

///|
pub fn timeline_trace_category_label(
  category : TimelineTraceCategory,
) -> String {
  match category {
    ScheduleStage => "schedule_stage"
    System => "system"
    RenderPass => "render_pass"
    RenderQueue => "render_queue"
  }
}

///|
pub type TimelineTraceSpanSink = (TimelineTraceSpan) -> Unit

///|
let timeline_trace_span_sink_ref : Ref[TimelineTraceSpanSink?] = Ref::new(None)

///|
let timeline_trace_pending_spans_ref : Ref[Array[TimelineTraceSpan]] = Ref::new([],
)

///|
pub fn set_timeline_trace_span_sink(sink : TimelineTraceSpanSink?) -> Unit {
  timeline_trace_span_sink_ref.val = sink
}

///|
pub fn clear_timeline_trace_span_sink() -> Unit {
  timeline_trace_span_sink_ref.val = None
}

///|
pub fn timeline_trace_push_pending_span(span : TimelineTraceSpan) -> Unit {
  timeline_trace_pending_spans_ref.val.push(span)
}

///|
pub fn timeline_trace_take_pending_spans() -> Array[TimelineTraceSpan] {
  let pending = timeline_trace_pending_spans_ref.val
  timeline_trace_pending_spans_ref.val = []
  pending
}

///|
pub fn timeline_trace_clear_pending_spans() -> Unit {
  timeline_trace_pending_spans_ref.val = []
}

///|
pub fn timeline_trace_enabled() -> Bool {
  timeline_trace_span_sink_ref.val is Some(_)
}

///|
pub fn timeline_trace_now_us() -> Int64 {
  @core.Instant::now().as_duration_since_start().as_micros()
}

///|
pub fn timeline_trace_begin_span(
  _category : TimelineTraceCategory,
  _name : String,
) -> Int64 {
  if timeline_trace_enabled() {
    timeline_trace_now_us()
  } else {
    -1L
  }
}

///|
pub fn timeline_trace_end_span(
  category : TimelineTraceCategory,
  name : String,
  ts_us : Int64,
) -> Unit {
  if ts_us < 0L {
    return
  }
  let end_ts_us = timeline_trace_now_us()
  let dur_us = if end_ts_us >= ts_us { end_ts_us - ts_us } else { 0L }
  timeline_trace_emit_complete_span(category, name, ts_us, dur_us)
}

///|
pub fn timeline_trace_emit_complete_span(
  category : TimelineTraceCategory,
  name : String,
  ts_us : Int64,
  dur_us : Int64,
) -> Unit {
  guard timeline_trace_span_sink_ref.val is Some(sink) else { return }
  let span = TimelineTraceSpan::{
    category,
    name,
    ts_us,
    dur_us: if dur_us >= 0L {
      dur_us
    } else {
      0L
    },
  }
  sink(span)
}
