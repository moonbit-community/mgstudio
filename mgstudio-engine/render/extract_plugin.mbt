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
priv struct RenderPluginMarker {}

///|
let ecs_key_render_plugin_marker : @ecs.ResourceKey[RenderPluginMarker] = @ecs.register_resource(
  debug_name="mgstudio_render::RenderPluginMarker",
)

///|
priv struct RenderMainWorld {
  world : @ecs.World
}

///|
let ecs_key_render_main_world : @ecs.ResourceKey[RenderMainWorld] = @ecs.register_resource(
  debug_name="mgstudio_render::MainWorld",
)

///|
fn render_sub_app_extract(
  main_world : @ecs.World,
  render_world : @ecs.World,
) -> (@ecs.World, @ecs.World) {
  ensure_primary_render_resources(main_world, render_world)
  update_render_state(main_world, render_world)
  let synced = sync_world(main_world, render_world)
  let main_world = synced.0
  let render_world = synced.1
  render_world.insert_resource(ecs_key_render_main_world, RenderMainWorld::{
    world: main_world,
  })
  (main_world, render_world)
}

///|
pub fn render_source_world(world : @ecs.World) -> @ecs.World {
  match world.get_resource(ecs_key_render_main_world) {
    Some(value) => value.world
    None => world
  }
}

///|
pub fn render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(RenderPlugin::RenderPlugin())
}

///|
fn render_plugin_install(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let mut next = app.add_plugins(SyncWorldPlugin::SyncWorldPlugin())
  if !next.contains_resource(render_asset_bytes_per_frame_resource_key) {
    next = next.insert_world_resource(
      render_asset_bytes_per_frame_resource_key,
      RenderAssetBytesPerFrame::RenderAssetBytesPerFrame(),
    )
  }
  if next.get_sub_app(@app.RenderApp) is None {
    let render_sub_app = @app.SubApp::new(@ecs.World::new()).set_update_schedule(
      Some(render_recovery_schedule_stage()),
    )
    let render_sub_app = configure_base_render_sets(
      configure_base_render_graph_sets(
        render_sub_app.add_schedule(RenderGraph::base_schedule()),
      ),
    )
    let render_sub_app = render_sub_app.add_schedule(
      @app.Schedule::new(render_startup_schedule_stage()),
    )
    let render_sub_app = render_sub_app.add_schedule(
      @app.Schedule::new(render_recovery_schedule_stage()),
    )
    next = next.insert_sub_app(@app.RenderApp, render_sub_app)
  }
  next = next.set_sub_app_extract(@app.RenderApp, render_sub_app_extract)
  @render_texture.register_asset_texture_backend()
  ignore(
    next.modify_sub_app(@app.RenderApp, fn(render_sub_app) {
      init_renderer_context_resources(render_sub_app.world())
      init_render_state(render_sub_app.world())
      if !render_sub_app
        .world()
        .resource(render_schedule_order_resource_key)
        .is_present() {
        render_sub_app
        .world()
        .insert_resource(
          render_schedule_order_resource_key,
          RenderScheduleOrder::RenderScheduleOrder(),
        )
      }
      render_sub_app
      .world()
      .insert_resource(
        render_asset_bytes_per_frame_limiter_resource_key,
        RenderAssetBytesPerFrameLimiter::RenderAssetBytesPerFrameLimiter(),
      )
      render_sub_app
      .add_systems(
        render_recovery_schedule_stage(),
        @app.system(run_render_schedule)
        .named("mgstudio_render::run_render_schedule")
        .run_if(renderer_is_ready),
      )
      .add_systems(
        render_schedule_stage(),
        @app.system(extract_render_asset_bytes_per_frame).in_set(
          render_system_set_extract_commands,
        ),
      )
      .add_systems(
        render_schedule_stage(),
        @app.system(despawn_temporary_render_entities).in_set(
          render_system_set_cleanup,
        ),
      )
      .add_systems(
        render_schedule_stage(),
        @app.system(reset_render_asset_bytes_per_frame).in_set(
          render_system_set_cleanup,
        ),
      )
      .add_systems(
        render_schedule_stage(),
        @app.system(render_graph_driver_system).in_set(render_system_set_render),
      )
      .add_systems(
        RenderGraph::schedule(),
        @app.system(prepare_active_frame_submissions)
        .named("mgstudio_render::prepare_active_frame_submissions")
        .in_set(render_graph_system_set_prepare_frame_submissions),
      )
      .add_systems(
        RenderGraph::schedule(),
        @app.system(flush_pending_command_buffers)
        .named("mgstudio_render::flush_pending_command_buffers")
        .in_set(render_graph_system_set_flush_command_buffers),
      )
      .add_systems(
        RenderGraph::schedule(),
        @app.system(present_active_frames)
        .named("mgstudio_render::present_active_frames")
        .in_set(render_graph_system_set_present_frames),
      )
    }),
  )
  if !next.contains_resource(ecs_key_render_plugin_marker) {
    register_embedded_wgsl_sources()
    @renderer.register_embedded_wgsl_sources()
    @render_view_window.register_embedded_wgsl_sources()
    @post_process.register_embedded_wgsl_sources()
    @post_process_bloom.register_embedded_wgsl_sources()
    @post_process_effect_stack.register_embedded_wgsl_sources()
    @post_process_motion_blur.register_embedded_wgsl_sources()
    next = next.add_plugins(
      @batching.GpuPreprocessingPlugin::GpuPreprocessingPlugin(),
    )
    next = next.add_plugins(
      @occlusion_culling.OcclusionCullingPlugin::OcclusionCullingPlugin(),
    )
    next = next.insert_world_resource(ecs_key_render_plugin_marker, RenderPluginMarker::{

    })
  }
  next
}

///|
pub fn try_with_render_app(
  app : @app.App[@ecs.World],
  update : (@app.SubApp[@ecs.World]) -> @app.SubApp[@ecs.World],
) -> @app.App[@ecs.World] {
  let next = app
  ignore(next.modify_sub_app(@app.RenderApp, update))
  next
}

///|
pub fn with_render_app(
  app : @app.App[@ecs.World],
  update : (@app.SubApp[@ecs.World]) -> @app.SubApp[@ecs.World],
) -> @app.App[@ecs.World] {
  let next = app
  if next.modify_sub_app(@app.RenderApp, update) {
    next
  } else {
    abort(
      "RenderApp is missing; add RenderPlugin before configuring render systems",
    )
  }
}
