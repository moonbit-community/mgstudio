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
/// Core render pipeline-facing API boundary.
/// Aggregates the stable ECS-facing surfaces split across `core_3d`,
/// `prepass`, and `deferred`.

///|
const CORE_PIPELINE_PLUGIN_NAME : String = "mgstudio.core_pipeline.CorePipelinePlugin"

///|
pub struct CorePipelinePlugin {}

///|
pub fn CorePipelinePlugin::default() -> CorePipelinePlugin {
  CorePipelinePlugin::{  }
}

///|
pub impl @app.PluginReplacement for CorePipelinePlugin with plugin_name(_self) {
  CORE_PIPELINE_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for CorePipelinePlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    core_pipeline_plugin_with(app, self)
  }
}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @core_3d {type Hdr}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @core_3d {type Msaa}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @deferred {type DeferredPrepass}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @prepass {type DepthPrepass}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @prepass {type MotionVectorPrepass}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @prepass {type NormalPrepass}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @fullscreen_vertex_shader {type FullscreenShader}

///|
// Bevy source: `bevy/crates/bevy_core_pipeline/src/lib.rs`.
pub using @skybox {type Skybox}

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @deferred.ecs_key_deferred_prepass

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @prepass.ecs_key_depth_prepass

///|
pub let ecs_key_hdr : @ecs.ComponentKey[Hdr] = @core_3d.ecs_key_hdr

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @prepass.ecs_key_motion_vector_prepass

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @core_3d.ecs_key_msaa

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @prepass.ecs_key_normal_prepass

///|
fn core_pipeline_configure_render_sub_app(
  sub_app : @app.SubApp[@ecs.World],
) -> @app.SubApp[@ecs.World] {
  let world = sub_app.world()
  if (try! world.get_resource(
      @fullscreen_vertex_shader.ecs_key_fullscreen_shader,
    ))
    is None {
    world.insert_resource(
      @fullscreen_vertex_shader.ecs_key_fullscreen_shader,
      FullscreenShader::default(),
    )
  }
  if (try! world.get_resource(ecs_key_camera_driver_state)) is None {
    world.insert_resource(
      ecs_key_camera_driver_state,
      CameraDriverState::default(),
    )
  }
  @render.configure_base_render_sets(sub_app).add_systems(
    @render.render_schedule_stage(),
    @app.system(camera_driver).in_set(@render.render_system_set_manage_views),
  )
}

///|
fn core_pipeline_install_render_graph_driver(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  if app.get_sub_app_mut(@app.RenderApp) is Some(render_sub_app_ref) {
    render_sub_app_ref.val = core_pipeline_configure_render_sub_app(
      render_sub_app_ref.val,
    )
  }
  app
}

///|
pub fn core_pipeline_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  core_pipeline_plugin_with(app, CorePipelinePlugin::default())
}

///|
pub fn core_pipeline_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : CorePipelinePlugin,
) -> @app.App[@ecs.World] {
  let app = app
    .add_plugin(@core_2d.core_2d_plugin)
    .add_plugin(@core_3d.core_3d_plugin)
    .add_plugin(@deferred.copy_deferred_lighting_id_plugin)
    .add_plugin(@blit.blit_plugin)
    .add_plugin(@tonemapping.tonemapping_plugin)
    .add_plugin(@upscaling.upscaling_plugin)
    .add_plugin(@oit.oit_plugin)
    .add_plugin(@mip_generation.mip_generation_plugin)
  core_pipeline_install_render_graph_driver(app)
}
