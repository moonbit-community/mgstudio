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
  .configure_set(stage, render_system_set_queue_meshes, after=[
    render_system_set_prepare_assets,
  ], before=[render_system_set_queue_sweep])
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
    render_system_set_render,
  ])
}
