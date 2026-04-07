// Copyright 2025 International Digital Economy Academy
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

/// Render pass trace helpers for the outer frame timeline.

///|
priv struct RenderPassTraceActiveSpan {
  name : String
  ts_us : Int64
}

///|
let render_pass_trace_active_span_ref : Ref[RenderPassTraceActiveSpan?] = Ref::new(
  None,
)

///|
fn render_pass_trace_end_active_span() -> Unit {
  if render_pass_trace_active_span_ref.val is Some(active_pass) {
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderPass,
      active_pass.name,
      active_pass.ts_us,
    )
  }
  render_pass_trace_active_span_ref.val = None
}

///|
fn render_pass_trace_begin_span(name : String) -> Unit {
  render_pass_trace_end_active_span()
  let ts_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderPass,
    name,
  )
  if ts_us >= 0L {
    render_pass_trace_active_span_ref.val = Some(RenderPassTraceActiveSpan::{
      name,
      ts_us,
    })
  }
}
