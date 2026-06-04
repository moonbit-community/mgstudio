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
// Bevy source: `bevy/crates/bevy_render/src/lib.rs` (`RenderSystems`).

///|
// Bevy source: `bevy/crates/bevy_render/src/renderer/mod.rs` (`RenderGraph`).
pub struct RenderGraph {}

///|
pub fn RenderGraph::RenderGraph() -> RenderGraph {
  RenderGraph::{  }
}

///|
pub fn RenderGraph::schedule() -> @app.ScheduleStage {
  render_graph_schedule_stage()
}

///|
pub fn RenderGraph::base_schedule() -> @app.Schedule {
  @app.Schedule::new(RenderGraph::schedule())
}

///|
// Bevy source: `bevy/crates/bevy_render/src/renderer/mod.rs` (`RenderGraphSystems`).
pub let render_graph_system_set_begin : @app.SystemSet = @app.system_set(
  "mgstudio.render.graph.begin",
)

///|
pub let render_graph_system_set_render : @app.SystemSet = @app.system_set(
  "mgstudio.render.graph.render",
)

///|
pub let render_graph_system_set_submit : @app.SystemSet = @app.system_set(
  "mgstudio.render.graph.submit",
)

///|
pub let render_graph_system_set_finish : @app.SystemSet = @app.system_set(
  "mgstudio.render.graph.finish",
)

///|
pub let render_graph_system_set_prepare_frame_submissions : @app.SystemSet = @app.system_set(
  "mgstudio.render.graph.prepare_frame_submissions",
)

///|
pub let render_graph_system_set_flush_command_buffers : @app.SystemSet = @app.system_set(
  "mgstudio.render.graph.flush_command_buffers",
)

///|
pub let render_graph_system_set_present_frames : @app.SystemSet = @app.system_set(
  "mgstudio.render.graph.present_frames",
)

///|
// Bevy source: `bevy/crates/bevy_render/src/lib.rs` (`RenderStartup`).
pub fn render_startup_schedule_stage() -> @app.ScheduleStage {
  @app.schedule_label("mgstudio.render.startup")
}

///|
// Bevy source: `bevy/crates/bevy_render/src/lib.rs` (`RenderRecovery`).
pub fn render_recovery_schedule_stage() -> @app.ScheduleStage {
  @app.schedule_label("mgstudio.render.recovery")
}

///|
// Bevy source: `bevy/crates/bevy_render/src/lib.rs` (`RenderScheduleOrder`).
pub struct RenderScheduleOrder {
  labels : Array[@app.ScheduleStage]
}

///|
pub fn RenderScheduleOrder::RenderScheduleOrder() -> RenderScheduleOrder {
  RenderScheduleOrder::{ labels: [render_schedule_stage()] }
}

///|
pub fn RenderScheduleOrder::labels(
  self : RenderScheduleOrder,
) -> Array[@app.ScheduleStage] {
  self.labels.copy()
}

///|
pub fn RenderScheduleOrder::insert_after(
  self : RenderScheduleOrder,
  after : @app.ScheduleStage,
  schedule : @app.ScheduleStage,
) -> Unit {
  for i, current in self.labels {
    if current == after {
      self.labels.insert(i + 1, schedule)
      return
    }
  }
  abort("Expected render schedule stage to exist")
}

///|
pub fn RenderScheduleOrder::insert_before(
  self : RenderScheduleOrder,
  before : @app.ScheduleStage,
  schedule : @app.ScheduleStage,
) -> Unit {
  for i, current in self.labels {
    if current == before {
      self.labels.insert(i, schedule)
      return
    }
  }
  abort("Expected render schedule stage to exist")
}

///|
pub let render_schedule_order_resource_key : @ecs.ResourceKey[
  RenderScheduleOrder,
] = @ecs.register_resource(debug_name="mgstudio_render::RenderScheduleOrder")

///|
pub let render_system_set_extract_commands : @app.SystemSet = @app.system_set(
  "mgstudio.render.extract_commands",
)

///|
pub let render_system_set_prepare_assets : @app.SystemSet = @app.system_set(
  "mgstudio.render.prepare_assets",
)

///|
pub let render_system_set_prepare_meshes : @app.SystemSet = @app.system_set(
  "mgstudio.render.prepare_meshes",
)

///|
pub let render_system_set_manage_views : @app.SystemSet = @app.system_set(
  "mgstudio.render.manage_views",
)

///|
pub let render_system_set_queue : @app.SystemSet = @app.system_set(
  "mgstudio.render.queue",
)

///|
pub let render_system_set_queue_meshes : @app.SystemSet = @app.system_set(
  "mgstudio.render.queue_meshes",
)

///|
pub let render_system_set_queue_sweep : @app.SystemSet = @app.system_set(
  "mgstudio.render.queue_sweep",
)

///|
pub let render_system_set_phase_sort : @app.SystemSet = @app.system_set(
  "mgstudio.render.phase_sort",
)

///|
pub let render_system_set_prepare : @app.SystemSet = @app.system_set(
  "mgstudio.render.prepare",
)

///|
pub let render_system_set_prepare_resources : @app.SystemSet = @app.system_set(
  "mgstudio.render.prepare_resources",
)

///|
pub let render_system_set_prepare_resources_collect_phase_buffers : @app.SystemSet = @app.system_set(
  "mgstudio.render.prepare_resources_collect_phase_buffers",
)

///|
pub let render_system_set_prepare_resources_flush : @app.SystemSet = @app.system_set(
  "mgstudio.render.prepare_resources_flush",
)

///|
pub let render_system_set_prepare_bind_groups : @app.SystemSet = @app.system_set(
  "mgstudio.render.prepare_bind_groups",
)

///|
pub let render_system_set_process_pipeline_queue : @app.SystemSet = @app.system_set(
  "mgstudio.render.process_pipeline_queue",
)

///|
pub let render_system_set_register_pipeline_descriptors : @app.SystemSet = @app.system_set(
  "mgstudio.render.register_pipeline_descriptors",
)

///|
pub let render_system_set_render : @app.SystemSet = @app.system_set(
  "mgstudio.render.render",
)

///|
pub let render_system_set_cleanup : @app.SystemSet = @app.system_set(
  "mgstudio.render.cleanup",
)

///|
pub let render_system_set_post_cleanup : @app.SystemSet = @app.system_set(
  "mgstudio.render.post_cleanup",
)

///|
pub fn render_schedule_stage() -> @app.ScheduleStage {
  @app.schedule_label("mgstudio.render")
  // Keep one canonical render-subapp schedule label so all render packages
  // target the same stage instead of relying on main-world stage names.
}

///|
pub fn render_graph_schedule_stage() -> @app.ScheduleStage {
  @app.schedule_label("mgstudio.render.graph")
}

///|
fn render_graph_driver_system(world : @ecs.World) -> Unit {
  @app.run_current_schedule_stage(world, RenderGraph::schedule())
}

///|
fn run_render_schedule(world : @ecs.World) -> Unit {
  let order = match world.get_resource(render_schedule_order_resource_key) {
    Some(value) => value
    None => RenderScheduleOrder::RenderScheduleOrder()
  }
  for stage in order.labels() {
    @app.run_current_schedule_stage(world, stage)
  }
}

///|
fn send_time(world : @ecs.World) -> Unit {
  guard world.get_resource(@time.time_sender_resource_key) is Some(sender) else {
    return
  }
  sender.try_send(@core.Instant::now()) catch {
    @time.TimeSendError::Full =>
      abort(
        "The TimeSender channel should always be empty during render. You might need to add the mgstudio::core::time_system to your app.",
      )
  }
}

///|
fn run_render_recovery_schedule(world : @ecs.World) -> Unit {
  if renderer_is_ready(world) {
    run_render_schedule(world)
  }
  send_time(world)
}

///|
pub fn configure_base_render_graph_sets(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let stage = RenderGraph::schedule()
  sub_app
  .configure_set(stage, render_graph_system_set_begin, before=[
    render_graph_system_set_render,
  ])
  .configure_set(stage, render_graph_system_set_render, before=[
    render_graph_system_set_submit,
  ])
  .configure_set(stage, render_graph_system_set_submit, before=[
    render_graph_system_set_finish,
  ])
  .configure_set(
    stage,
    render_graph_system_set_prepare_frame_submissions,
    before=[render_graph_system_set_flush_command_buffers],
    in_sets=[render_graph_system_set_submit],
  )
  .configure_set(
    stage,
    render_graph_system_set_flush_command_buffers,
    before=[render_graph_system_set_finish],
    in_sets=[render_graph_system_set_submit],
  )
  .configure_set(stage, render_graph_system_set_present_frames, in_sets=[
    render_graph_system_set_finish,
  ])
}

///|
pub fn configure_base_render_sets(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let stage = render_schedule_stage()
  sub_app
  .configure_set(stage, render_system_set_extract_commands, before=[
    render_system_set_prepare_meshes,
  ])
  .configure_set(stage, render_system_set_prepare_meshes, before=[
    render_system_set_manage_views,
  ])
  .configure_set(stage, render_system_set_manage_views, before=[
    render_system_set_queue,
  ])
  .configure_set(stage, render_system_set_queue, before=[
    render_system_set_queue_meshes,
  ])
  .configure_set(
    stage,
    render_system_set_queue_meshes,
    after=[render_system_set_prepare_assets],
    before=[render_system_set_queue_sweep],
  )
  .configure_set(stage, render_system_set_queue_sweep, before=[
    render_system_set_phase_sort,
  ])
  .configure_set(stage, render_system_set_phase_sort, before=[
    render_system_set_prepare,
  ])
  .configure_set(stage, render_system_set_prepare, before=[
    render_system_set_render,
  ])
  .configure_set(stage, render_system_set_render, before=[
    render_system_set_cleanup,
  ])
  .configure_set(stage, render_system_set_cleanup, before=[
    render_system_set_post_cleanup,
  ])
  .configure_set(stage, render_system_set_extract_commands, before=[
    render_system_set_prepare_assets, render_system_set_prepare,
  ])
  .configure_set(stage, render_system_set_prepare_assets, before=[
    render_system_set_prepare_meshes, render_system_set_prepare,
  ])
  .configure_set(stage, render_system_set_prepare_resources, before=[
    render_system_set_prepare_resources_collect_phase_buffers,
  ])
  .configure_set(stage, render_system_set_prepare, before=[
    render_system_set_prepare_resources,
  ])
  .configure_set(
    stage,
    render_system_set_prepare_resources_collect_phase_buffers,
    before=[render_system_set_prepare_resources_flush],
  )
  .configure_set(stage, render_system_set_prepare_resources_flush, before=[
    render_system_set_prepare_bind_groups,
  ])
  .configure_set(stage, render_system_set_prepare_bind_groups, before=[
    render_system_set_process_pipeline_queue,
  ])
  .configure_set(stage, render_system_set_process_pipeline_queue, before=[
    render_system_set_register_pipeline_descriptors,
  ])
  .configure_set(stage, render_system_set_register_pipeline_descriptors, before=[
    render_system_set_render,
  ])
}
