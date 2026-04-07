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

///|
priv struct RenderTimelineActivePass {
  name : String
  ts_us : Int64
}

///|
let render_timeline_active_pass_ref : Ref[RenderTimelineActivePass?] = Ref::new(
  None,
)

///|
fn render_timeline_end_active_pass() -> Unit {
  if render_timeline_active_pass_ref.val is Some(active_pass) {
    @app.timeline_trace_end_span(
      @app.TimelineTraceCategory::RenderPass,
      active_pass.name,
      active_pass.ts_us,
    )
  }
  render_timeline_active_pass_ref.val = None
}

///|
fn render_timeline_begin_pass(name : String) -> Unit {
  render_timeline_end_active_pass()
  let ts_us = @app.timeline_trace_begin_span(
    @app.TimelineTraceCategory::RenderPass,
    name,
  )
  if ts_us >= 0L {
    render_timeline_active_pass_ref.val = Some(RenderTimelineActivePass::{
      name,
      ts_us,
    })
  }
}
