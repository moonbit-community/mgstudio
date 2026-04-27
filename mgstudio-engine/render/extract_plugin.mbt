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
  match (try! world.get_resource(ecs_key_render_main_world)) {
    Some(value) => value.world
    None => world
  }
}

///|
pub fn render_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  app.add_plugins(RenderPlugin::default())
}

///|
fn render_plugin_install(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let mut next = app.add_plugins(SyncWorldPlugin::default())
  if next.get_sub_app(@app.RenderApp) is None {
    let render_sub_app = @app.SubApp::new(@ecs.World::new()).set_update_schedule(
      Some(render_schedule_stage()),
    )
    let render_sub_app = configure_base_render_sets(render_sub_app)
    next = next.insert_sub_app(@app.RenderApp, render_sub_app)
  }
  next = next.set_sub_app_extract(@app.RenderApp, render_sub_app_extract)
  if next.get_sub_app_mut(@app.RenderApp) is Some(render_sub_app_ref) {
    render_sub_app_ref.val = render_sub_app_ref.val.add_systems(
      render_schedule_stage(),
      @app.system(despawn_temporary_render_entities).in_set(
        render_system_set_cleanup,
      ),
    )
  }
  if !next.contains_resource(ecs_key_render_plugin_marker) {
    register_embedded_wgsl_sources()
    @renderer.register_embedded_wgsl_sources()
    @render_view_window.register_embedded_wgsl_sources()
    @post_process_bloom.register_embedded_wgsl_sources()
    @post_process_effect_stack.register_embedded_wgsl_sources()
    @post_process_motion_blur.register_embedded_wgsl_sources()
    next = next.add_plugins(@batching.GpuPreprocessingPlugin::default())
    next = next.add_plugins(
      @occlusion_culling.OcclusionCullingPlugin::default(),
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
  if next.get_sub_app_mut(@app.RenderApp) is Some(sub_app_ref) {
    sub_app_ref.val = update(sub_app_ref.val)
  }
  next
}

///|
pub fn with_render_app(
  app : @app.App[@ecs.World],
  update : (@app.SubApp[@ecs.World]) -> @app.SubApp[@ecs.World],
) -> @app.App[@ecs.World] {
  let next = app
  match next.get_sub_app_mut(@app.RenderApp) {
    Some(sub_app_ref) => {
      sub_app_ref.val = update(sub_app_ref.val)
      next
    }
    None =>
      abort(
        "RenderApp is missing; add RenderPlugin before configuring render systems",
      )
  }
}
