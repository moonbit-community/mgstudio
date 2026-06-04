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
test "render settings: default render creation is automatic" {
  match RenderCreation::default() {
    Automatic(settings) => {
      debug_inspect(
        settings.priority == WgpuSettingsPriority::default(),
        content="true",
      )
      debug_inspect(settings.force_fallback_adapter, content="false")
    }
    Manual(_) => abort("default render creation should be automatic")
  }
}

///|
test "render settings: bevy renderer resources use distinct world keys" {
  let device_key = render_device_resource_key
  let queue_key = render_queue_resource_key
  let adapter_key = render_adapter_resource_key
  let adapter_info_key = render_adapter_info_resource_key
  let instance_key = render_instance_resource_key
  let pipeline_cache_key = pipeline_cache_resource_key
  debug_inspect(device_key.id() != queue_key.id(), content="true")
  debug_inspect(device_key.id() != adapter_key.id(), content="true")
  debug_inspect(adapter_key.id() != adapter_info_key.id(), content="true")
  debug_inspect(instance_key.id() != pipeline_cache_key.id(), content="true")
}

///|
test "render schedule: render graph is a distinct root graph schedule" {
  let graph = RenderGraph::RenderGraph()
  ignore(graph)
  debug_inspect(
    RenderGraph::schedule() != render_schedule_stage(),
    content="true",
  )
  debug_inspect(
    RenderGraph::base_schedule().label() == RenderGraph::schedule(),
    content="true",
  )
}

///|
test "render schedule: recovery drives render and render graph phases once" {
  let log : Array[String] = []
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(render_recovery_schedule_stage()))
    .add_schedule(@app.Schedule::new(render_schedule_stage()))
    .add_schedule(RenderGraph::base_schedule())
  render_sub_app
  .world()
  .insert_resource(
    render_schedule_order_resource_key,
    RenderScheduleOrder::RenderScheduleOrder(),
  )
  let render_sub_app = configure_base_render_sets(
    configure_base_render_graph_sets(render_sub_app),
  )
  let render_sub_app = render_sub_app
    .add_systems(
      render_recovery_schedule_stage(),
      @app.system(run_render_schedule),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("prepare") }).in_set(
        render_system_set_prepare_bind_groups,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(render_graph_driver_system).in_set(render_system_set_render),
    )
    .add_systems(
      RenderGraph::schedule(),
      @app.system(fn(_world : @ecs.World) { log.push("begin") }).in_set(
        render_graph_system_set_begin,
      ),
    )
    .add_systems(
      RenderGraph::schedule(),
      @app.system(fn(_world : @ecs.World) { log.push("render") }).in_set(
        render_graph_system_set_render,
      ),
    )
    .add_systems(
      RenderGraph::schedule(),
      @app.system(fn(_world : @ecs.World) { log.push("submit") }).in_set(
        render_graph_system_set_submit,
      ),
    )
    .add_systems(
      RenderGraph::schedule(),
      @app.system(fn(_world : @ecs.World) { log.push("finish") }).in_set(
        render_graph_system_set_finish,
      ),
    )
  ignore(render_sub_app.update())
  debug_inspect(log.join(","), content="\"prepare,begin,render,submit,finish\"")
}

///|
test "render schedule: order inserts stages around render" {
  let before = @app.schedule_label("mgstudio.render.test.before")
  let after = @app.schedule_label("mgstudio.render.test.after")
  let order = RenderScheduleOrder::RenderScheduleOrder()
  order.insert_before(render_schedule_stage(), before)
  order.insert_after(render_schedule_stage(), after)
  let labels = order.labels()
  debug_inspect(labels.length(), content="3")
  debug_inspect(labels[0] == before, content="true")
  debug_inspect(labels[1] == render_schedule_stage(), content="true")
  debug_inspect(labels[2] == after, content="true")
}

///|
test "render schedule: startup and recovery labels are distinct" {
  debug_inspect(
    render_startup_schedule_stage() != render_schedule_stage(),
    content="true",
  )
  debug_inspect(
    render_recovery_schedule_stage() != render_schedule_stage(),
    content="true",
  )
  debug_inspect(
    render_startup_schedule_stage() != render_recovery_schedule_stage(),
    content="true",
  )
}

///|
test "render settings: current view stores the render entity" {
  let entity = @core.Entity::new(42, 7)
  let current = CurrentView::new(entity)
  debug_inspect(current.entity() == entity, content="true")
  debug_inspect(
    current_view_resource_key.id() != render_device_resource_key.id(),
    content="true",
  )
}

///|
test "render plugin: initializes pending command buffers in render app" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  let render_sub_app = app.get_sub_app(@app.RenderApp).unwrap()
  let render_world = render_sub_app.world()
  let pending = render_world
    .get_resource(pending_command_buffers_resource_key)
    .unwrap()
  debug_inspect(pending.is_empty(), content="true")
}

///|
test "render plugin: installs render asset byte budget resources" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  let main_budget = app
    .world()
    .get_resource(render_asset_bytes_per_frame_resource_key)
    .unwrap()
  debug_inspect(main_budget.max_bytes() is None, content="true")
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let limiter = render_world
    .get_resource(render_asset_bytes_per_frame_limiter_resource_key)
    .unwrap()
  debug_inspect(limiter.max_bytes() is None, content="true")
  debug_inspect(limiter.bytes_written(), content="0")
}

///|
test "render asset byte budget: extract updates limiter and cleanup resets writes" {
  let main_world = @ecs.World::new()
  main_world.insert_resource(
    render_asset_bytes_per_frame_resource_key,
    RenderAssetBytesPerFrame::new(64),
  )
  let render_world = @ecs.World::new()
  render_world.insert_resource(
    render_asset_bytes_per_frame_limiter_resource_key,
    RenderAssetBytesPerFrameLimiter::RenderAssetBytesPerFrameLimiter(),
  )
  let synced = render_sub_app_extract(main_world, render_world)
  let render_world = synced.1
  extract_render_asset_bytes_per_frame(render_world)
  let limiter = render_world
    .get_resource(render_asset_bytes_per_frame_limiter_resource_key)
    .unwrap()
  debug_inspect(limiter.max_bytes().unwrap(), content="64")
  limiter.write_bytes(16)
  debug_inspect(limiter.bytes_written(), content="16")
  reset_render_asset_bytes_per_frame(render_world)
  debug_inspect(limiter.bytes_written(), content="0")
}

///|
test "render plugin: initializes render state as not ready" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let state = render_world.get_resource(render_state_resource_key).unwrap()
  debug_inspect(state.is_ready(), content="false")
  debug_inspect(renderer_is_ready(render_world), content="false")
  mark_renderer_ready(render_world)
  debug_inspect(renderer_is_ready(render_world), content="true")
}
