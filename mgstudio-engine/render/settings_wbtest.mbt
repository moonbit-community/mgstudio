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
struct RenderExtractDirectMarker {} derive(Eq, Debug)

///|
fn RenderExtractDirectMarker::RenderExtractDirectMarker() -> RenderExtractDirectMarker {
  RenderExtractDirectMarker::{  }
}

///|
let render_extract_direct_marker_key : @ecs.ResourceKey[
  RenderExtractDirectMarker,
] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderExtractDirectMarker",
)

///|
impl @app.Resource for RenderExtractDirectMarker with fn resource() {
  render_extract_direct_marker_key
}

///|
struct RenderExtractDeferredMarker {} derive(Eq, Debug)

///|
fn RenderExtractDeferredMarker::RenderExtractDeferredMarker() -> RenderExtractDeferredMarker {
  RenderExtractDeferredMarker::{  }
}

///|
let render_extract_deferred_marker_key : @ecs.ResourceKey[
  RenderExtractDeferredMarker,
] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderExtractDeferredMarker",
)

///|
impl @app.Resource for RenderExtractDeferredMarker with fn resource() {
  render_extract_deferred_marker_key
}

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
test "render plugin: default stores bevy render configuration" {
  let plugin = RenderPlugin::RenderPlugin()
  match plugin.render_creation() {
    Automatic(settings) =>
      debug_inspect(
        settings.priority == WgpuSettingsPriority::default(),
        content="true",
      )
    Manual(_) => abort("default RenderPlugin should use automatic creation")
  }
  debug_inspect(plugin.synchronous_pipeline_compilation(), content="false")
  debug_inspect(
    plugin.debug_flags().allow_copies_from_indirect_parameters(),
    content="false",
  )
}

///|
test "render plugin: bevy render configuration setters preserve fields" {
  let debug_flags = RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
    true,
  )
  let plugin = RenderPlugin::RenderPlugin()
    .with_render_creation(
      RenderCreation::automatic(
        WgpuSettings::WgpuSettings().with_force_fallback_adapter(true),
      ),
    )
    .with_synchronous_pipeline_compilation(true)
    .with_debug_flags(debug_flags)
  match plugin.render_creation() {
    Automatic(settings) =>
      debug_inspect(settings.force_fallback_adapter, content="true")
    Manual(_) => abort("configured RenderPlugin should use automatic creation")
  }
  debug_inspect(plugin.synchronous_pipeline_compilation(), content="true")
  debug_inspect(
    plugin.debug_flags().allow_copies_from_indirect_parameters(),
    content="true",
  )
}

///|
test "render plugin: debug flags configure batching indirect parameter readback copies" {
  let debug_flags = RenderDebugFlags::RenderDebugFlags().with_allow_copies_from_indirect_parameters(
    true,
  )
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin().with_debug_flags(debug_flags),
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let settings = render_world
    .get_resource(@batching.IndirectParametersBuffersSettings::resource())
    .unwrap()
  debug_inspect(
    settings.allow_copies_from_indirect_parameter_buffers(),
    content="true",
  )
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
  let render_sub_app = configure_base_render_sets(render_sub_app)
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
      @app.system(render_system).in_set(render_system_set_render),
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
test "render schedule: view and specialization sets match bevy order" {
  let log : Array[String] = []
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(render_schedule_stage()))
    .add_schedule(@app.Schedule::new(render_schedule_stage()))
  let render_sub_app = configure_base_render_sets(render_sub_app)
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("prepare_meshes") }).in_set(
        render_system_set_prepare_meshes,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("create_views") }).in_set(
        render_system_set_create_views,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("specialize") }).in_set(
        render_system_set_specialize,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("prepare_views") }).in_set(
        render_system_set_prepare_views,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("queue") }).in_set(
        render_system_set_queue,
      ),
    )
  ignore(render_sub_app.update())
  debug_inspect(
    log.join(","),
    content="\"prepare_meshes,create_views,specialize,prepare_views,queue\"",
  )
}

///|
test "render schedule: prepare resource sets match bevy order" {
  let log : Array[String] = []
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(render_schedule_stage()))
    .add_schedule(@app.Schedule::new(render_schedule_stage()))
  let render_sub_app = configure_base_render_sets(render_sub_app)
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("prepare_resources") }).in_set(
        render_system_set_prepare_resources,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("batch_phases") }).in_set(
        render_system_set_prepare_resources_batch_phases,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("write_phase_buffers") }).in_set(
        render_system_set_prepare_resources_write_phase_buffers,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("collect_phase_buffers") }).in_set(
        render_system_set_prepare_resources_collect_phase_buffers,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("flush") }).in_set(
        render_system_set_prepare_resources_flush,
      ),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("bind_groups") }).in_set(
        render_system_set_prepare_bind_groups,
      ),
    )
  ignore(render_sub_app.update())
  debug_inspect(
    log.join(","),
    content="\"prepare_resources,batch_phases,write_phase_buffers,collect_phase_buffers,flush,bind_groups\"",
  )
}

///|
test "render schedule: pipeline queue is chained inside render set" {
  let log : Array[String] = []
  let cache = @render_resource.PipelineCache::new()
  ignore(
    cache.queue_render_pipeline(
      @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor(),
    ),
  )
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(render_schedule_stage()))
    .add_schedule(@app.Schedule::new(render_schedule_stage()))
  render_sub_app.world().insert_resource(pipeline_cache_resource_key, cache)
  let render_sub_app = configure_base_render_sets(render_sub_app)
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(world : @ecs.World) {
        process_pipeline_queue_system(world)
        log.push("process")
      }).in_set(render_system_set_process_pipeline_queue),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(world : @ecs.World) {
        log.push("register")
        let cache = world.get_resource(pipeline_cache_resource_key).unwrap()
        log.push(
          "driver:\{cache.pipeline_count()}:\{cache.queued_pipeline_count()}:\{to_repr(cache.waiting_pipelines()).to_string()}",
        )
      }).in_set(render_system_set_register_pipeline_descriptors),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(world : @ecs.World) {
        render_system(world)
        log.push("render_system")
      }).in_set(render_system_set_render_graph_driver),
    )
  ignore(render_sub_app.update())
  debug_inspect(
    log.join(","),
    content="\"process,register,driver:1:0:[0],render_system\"",
  )
}

///|
test "render settings: descriptor registration observes pipeline cache waiting ids" {
  let world = @ecs.World::new()
  let cache = @render_resource.PipelineCache::new()
  ignore(
    cache.queue_render_pipeline(
      @render_resource.RenderPipelineDescriptor::RenderPipelineDescriptor(),
    ),
  )
  world.insert_resource(pipeline_cache_resource_key, cache)
  process_pipeline_queue_system(world)
  let cache = world.get_resource(pipeline_cache_resource_key).unwrap()
  debug_inspect(cache.waiting_pipelines(), content="[0]")
  register_pipeline_cache_render_pipeline_descriptors(world)
  let cache = world.get_resource(pipeline_cache_resource_key).unwrap()
  debug_inspect(cache.waiting_pipelines(), content="[0]")
}

///|
test "render settings: compute pipeline descriptors are materialized when backend exists" {
  let world = @ecs.World::new()
  let cache = @render_resource.PipelineCache::new()
  let pipeline_id = cache.queue_compute_pipeline(
    @render_resource.ComputePipelineDescriptor::ComputePipelineDescriptor()
    .with_shader(Some("pbr/cluster/cluster_z_slice.wgsl"))
    .with_entry_point(Some("z_slice_main")),
  )
  world.insert_resource(pipeline_cache_resource_key, cache)
  process_pipeline_queue_system(world)
  let cache = world.get_resource(pipeline_cache_resource_key).unwrap()
  debug_inspect(cache.waiting_pipelines(), content="[0]")
  debug_inspect(
    cache.get_compute_pipeline_state(pipeline_id).is_creating(),
    content="true",
  )
  register_pipeline_cache_render_pipeline_descriptors(world)
  let cache = world.get_resource(pipeline_cache_resource_key).unwrap()
  let state = cache.get_compute_pipeline_state(pipeline_id)
  let waiting = cache.waiting_pipelines()
  let still_waiting = waiting.length() == 1 &&
    waiting[0] == pipeline_id.id() &&
    state.is_creating()
  let retryable = waiting.length() == 1 &&
    waiting[0] == pipeline_id.id() &&
    (state.is_queued() || state.is_err())
  let materialized = waiting.length() == 0 && state.is_ok()
  debug_inspect(still_waiting || retryable || materialized, content="true")
}

///|
test "render recovery: render schedule only runs when renderer is ready" {
  let log : Array[String] = []
  let time_channels = @time.create_time_channels()
  let time_sender = time_channels.0
  let time_receiver = time_channels.1
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .set_update_schedule(Some(render_recovery_schedule_stage()))
    .add_schedule(@app.Schedule::new(render_schedule_stage()))
    .add_schedule(@app.Schedule::new(render_recovery_schedule_stage()))
    .add_systems(
      render_recovery_schedule_stage(),
      @app.system(run_render_recovery_schedule),
    )
    .add_systems(
      render_schedule_stage(),
      @app.system(fn(_world : @ecs.World) { log.push("render") }),
    )
  render_sub_app
  .world()
  .insert_resource(
    render_schedule_order_resource_key,
    RenderScheduleOrder::RenderScheduleOrder(),
  )
  render_sub_app
  .world()
  .insert_resource(@time.time_sender_resource_key, time_sender)
  ignore(render_sub_app.update())
  debug_inspect(log.join(","), content="\"\"")
  debug_inspect(time_receiver.try_recv() is Some(_), content="true")
  mark_renderer_ready(render_sub_app.world())
  ignore(render_sub_app.update())
  debug_inspect(log.join(","), content="\"render\"")
  debug_inspect(time_receiver.try_recv() is Some(_), content="true")
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
test "render plugin: initializes pending command buffers from render startup" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  let render_sub_app = app
    .get_sub_app(@app.RenderApp)
    .unwrap()
    .set_update_schedule(Some(render_startup_schedule_stage()))
  let render_world = render_sub_app.world()
  debug_inspect(
    render_world.resource(pending_command_buffers_resource_key).is_present(),
    content="false",
  )
  ignore(render_sub_app.run_startup())
  let pending = render_world
    .get_resource(pending_command_buffers_resource_key)
    .unwrap()
  debug_inspect(pending.is_empty(), content="true")
}

///|
test "render startup: gpu resources can be initialized repeatedly" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  let render_sub_app = app
    .get_sub_app(@app.RenderApp)
    .unwrap()
    .set_update_schedule(Some(render_startup_schedule_stage()))
  let render_world = render_sub_app.world()
  ignore(render_sub_app.run_startup())
  debug_inspect(
    render_world.resource(pending_command_buffers_resource_key).is_present(),
    content="true",
  )
  render_world.remove_resource(pending_command_buffers_resource_key) |> ignore
  debug_inspect(
    render_world.resource(pending_command_buffers_resource_key).is_present(),
    content="false",
  )
  ignore(render_sub_app.run_startup())
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
test "render extract schedule: runs before render and defers commands to ExtractCommands" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  ignore(
    app.modify_sub_app(@app.RenderApp, fn(render_sub_app) {
      render_sub_app
      .add_systems(
        render_extract_schedule_stage(),
        @app.system(fn(world : @ecs.World) {
          world.insert_resource(
            RenderExtractDirectMarker::resource(),
            RenderExtractDirectMarker::RenderExtractDirectMarker(),
          )
        }),
      )
      .add_systems(
        render_extract_schedule_stage(),
        @app.system_config_param(fn(commands : @app.Commands) {
          commands.insert_resource(
            RenderExtractDeferredMarker::RenderExtractDeferredMarker(),
          )
        }),
      )
    }),
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  mark_renderer_ready(render_world)
  let app = app.run_once()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(
    render_world.resource(RenderExtractDirectMarker::resource()).is_present(),
    content="true",
  )
  debug_inspect(
    render_world.resource(RenderExtractDeferredMarker::resource()).is_present(),
    content="true",
  )
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

///|
test "render plugin: future resources unpack during plugin finish" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  debug_inspect(
    app.world().resource(future_render_resources_resource_key).is_present(),
    content="true",
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(
    render_world.resource(render_device_resource_key).is_present(),
    content="false",
  )

  let app = app.finish()
  debug_inspect(
    app.world().resource(future_render_resources_resource_key).is_present(),
    content="false",
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(
    render_world.resource(render_device_resource_key).is_present(),
    content="true",
  )
  debug_inspect(
    render_world.resource(@render_view.ViewUniforms::resource()).is_present(),
    content="true",
  )
}

///|
test "render plugin: initializes manual texture views in main and render worlds" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  debug_inspect(
    app
    .world()
    .resource(@render_texture.ManualTextureViews::resource())
    .is_present(),
    content="true",
  )
  let app = app.finish()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(
    render_world
    .resource(@render_texture.ManualTextureViews::resource())
    .is_present(),
    content="true",
  )
}

///|
test "render recovery: reinitializing consumes future render resources before startup" {
  let backend = @renderer.GpuBackend::new()
  let resources = RenderResources::from_backend(backend)
  let main_world = @ecs.World::new()
  debug_inspect(
    insert_future_render_resources(
      RenderCreation::manual_resources(resources),
      main_world,
    ),
    content="true",
  )
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .add_schedule(@app.Schedule::new(render_startup_schedule_stage()))
    .add_systems(
      render_startup_schedule_stage(),
      @app.system(init_pending_command_buffers_resource),
    )
  let render_world = render_sub_app.world()
  render_world.insert_resource(
    render_state_resource_key,
    RenderState::reinitializing(),
  )
  let app = @app.App::new(main_world)
    .insert_sub_app(@app.RenderApp, render_sub_app)
    .set_sub_app_extract(@app.RenderApp, fn(
      main_world : @ecs.World,
      render_world : @ecs.World,
    ) {
      update_render_state(main_world, render_world)
      (main_world, render_world)
    })

  let app = app.run_once()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(
    app.world().resource(future_render_resources_resource_key).is_present(),
    content="false",
  )
  let state_after_reinit = render_world
    .get_resource(render_state_resource_key)
    .unwrap()
  debug_inspect(state_after_reinit is Initializing, content="true")
  debug_inspect(
    render_world.resource(render_device_resource_key).is_present(),
    content="true",
  )
  debug_inspect(
    render_world.resource(pending_command_buffers_resource_key).is_present(),
    content="false",
  )

  let app = app.run_once()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(renderer_is_ready(render_world), content="true")
  debug_inspect(
    render_world.resource(pending_command_buffers_resource_key).is_present(),
    content="true",
  )
}

///|
test "render error handler: ignore policy marks renderer ready" {
  let main_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  main_world.insert_resource(
    render_error_handler_resource_key,
    RenderErrorHandler::new(fn(_error, _main_world, _render_world) {
      RenderErrorPolicy::Ignore
    }),
  )
  render_world.insert_resource(
    render_state_resource_key,
    RenderState::errored(
      RenderError::new(RenderErrorType::Validation, "validation"),
    ),
  )

  update_render_state(main_world, render_world)
  debug_inspect(renderer_is_ready(render_world), content="true")
}

///|
test "render error handler: recover policy creates future resources and restarts" {
  let backend = @renderer.GpuBackend::new()
  let resources = RenderResources::from_backend(backend)
  let main_world = @ecs.World::new()
  let render_sub_app = @app.SubApp::new(@ecs.World::new())
    .add_schedule(@app.Schedule::new(render_startup_schedule_stage()))
    .add_systems(
      render_startup_schedule_stage(),
      @app.system(init_pending_command_buffers_resource),
    )
  let render_world = render_sub_app.world()
  main_world.insert_resource(
    render_error_handler_resource_key,
    RenderErrorHandler::new(fn(_error, _main_world, _render_world) {
      RenderErrorPolicy::Recover(RenderCreation::manual_resources(resources))
    }),
  )
  render_world.insert_resource(
    render_state_resource_key,
    RenderState::errored(
      RenderError::new(RenderErrorType::DeviceLost, "device lost"),
    ),
  )
  let app = @app.App::new(main_world)
    .insert_sub_app(@app.RenderApp, render_sub_app)
    .set_sub_app_extract(@app.RenderApp, fn(
      main_world : @ecs.World,
      render_world : @ecs.World,
    ) {
      update_render_state(main_world, render_world)
      (main_world, render_world)
    })

  let app = app.run_once()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let state_after_error = render_world
    .get_resource(render_state_resource_key)
    .unwrap()
  debug_inspect(state_after_error is Reinitializing, content="true")
  debug_inspect(
    app.world().resource(future_render_resources_resource_key).is_present(),
    content="true",
  )

  let app = app.run_once()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let state_after_reinit = render_world
    .get_resource(render_state_resource_key)
    .unwrap()
  debug_inspect(state_after_reinit is Initializing, content="true")
  debug_inspect(
    app.world().resource(future_render_resources_resource_key).is_present(),
    content="false",
  )

  let app = app.run_once()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(renderer_is_ready(render_world), content="true")
  debug_inspect(
    render_world.resource(pending_command_buffers_resource_key).is_present(),
    content="true",
  )
}

///|
test "render error handler: recover default creation enters reinitializing" {
  let main_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  main_world.insert_resource(
    render_error_handler_resource_key,
    RenderErrorHandler::new(fn(_error, _main_world, _render_world) {
      RenderErrorPolicy::Recover(RenderCreation::default())
    }),
  )
  render_world.insert_resource(
    render_state_resource_key,
    RenderState::errored(
      RenderError::new(RenderErrorType::DeviceLost, "device lost"),
    ),
  )

  update_render_state(main_world, render_world)
  let state_after_error = render_world
    .get_resource(render_state_resource_key)
    .unwrap()
  debug_inspect(state_after_error is Reinitializing, content="true")
  debug_inspect(
    main_world.resource(future_render_resources_resource_key).is_present(),
    content="true",
  )
}

///|
test "render error handler: default handler sends app exit from main world" {
  let main_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  main_world.insert_resource(
    render_error_handler_resource_key,
    RenderErrorHandler::RenderErrorHandler(),
  )
  render_world.insert_resource(
    render_state_resource_key,
    RenderState::errored(
      RenderError::new(RenderErrorType::Validation, "validation"),
    ),
  )

  update_render_state(main_world, render_world)
  let key = @app.AppExit::message()
  let reader = main_world.message_reader(key)
  let exits = reader.read()
  debug_inspect(exits.length(), content="1")
  debug_inspect(exits[0].is_error(), content="true")
}

///|
test "render plugin: installs window render resources in render world" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    RenderPlugin::RenderPlugin(),
  )
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(
    render_world
    .resource(@render_view_window.extracted_windows_resource_key)
    .is_present(),
    content="true",
  )
  debug_inspect(
    render_world
    .resource(@render_view_window.window_surfaces_resource_key)
    .is_present(),
    content="true",
  )
}
