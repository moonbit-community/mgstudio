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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/blit/mod.rs`.
// Blit plugin owner surface.

///|
const BLIT_PLUGIN_NAME : String = "mgstudio.core_pipeline.blit.BlitPlugin"

///|
pub const BLIT_PASS_LABEL : String = "blit"

///|
pub struct BlitPlugin {}

///|
pub fn BlitPlugin::default() -> BlitPlugin {
  BlitPlugin::{  }
}

///|
pub fn blit_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  blit_plugin_with(app, BlitPlugin::default())
}

///|
pub impl @app.Plugin for BlitPlugin with name(_self) {
  BLIT_PLUGIN_NAME
}

///|
pub impl @app.Plugin for BlitPlugin with build(self, app) {
  blit_plugin_with(app, self)
}

///|
pub fn blit_plugin_with(
  app : @app.App[@ecs.World],
  plugin : BlitPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { BlitPipeline::default() })
}

///|
pub fn blit_draw(scene_texture_id~ : Int) -> Unit {
  @render.host_gpu_draw_blit(scene_texture_id~)
}

///|
pub struct BlitPipeline {
  has_bind_group_layout : Bool
  has_sampler : Bool
  has_fullscreen_shader : Bool
  has_fragment_shader : Bool
}

///|
pub fn BlitPipeline::default() -> BlitPipeline {
  BlitPipeline::new()
}

///|
pub fn BlitPipeline::new(
  has_bind_group_layout? : Bool = false,
  has_sampler? : Bool = false,
  has_fullscreen_shader? : Bool = false,
  has_fragment_shader? : Bool = false,
) -> BlitPipeline {
  BlitPipeline::{
    has_bind_group_layout,
    has_sampler,
    has_fullscreen_shader,
    has_fragment_shader,
  }
}

///|
pub fn blit_pipeline_ready(pipeline : BlitPipeline) -> Bool {
  pipeline.has_bind_group_layout &&
  pipeline.has_sampler &&
  pipeline.has_fullscreen_shader &&
  pipeline.has_fragment_shader
}

///|
pub let ecs_key_blit_pipeline : @ecs.ResourceKey[BlitPipeline] = @ecs.register_resource(
  debug_name="core_pipeline.blit.pipeline",
)

///|
pub impl @app.Resource for BlitPipeline with resource() {
  ecs_key_blit_pipeline
}

///|
pub struct BlitPipelineKey {
  texture_format : String
  blend_state : String
  samples : Int
} derive(Eq, Debug)

///|
pub fn BlitPipelineKey::new(
  texture_format? : String = "bgra8unorm",
  blend_state? : String = "none",
  samples? : Int = 1,
) -> BlitPipelineKey {
  let samples = if samples <= 0 { 1 } else { samples }
  BlitPipelineKey::{ texture_format, blend_state, samples }
}

///|
pub struct BlitBindGroup {
  source_texture_view_id : Int
}

///|
pub fn BlitBindGroup::new(source_texture_view_id~ : Int) -> BlitBindGroup {
  BlitBindGroup::{ source_texture_view_id, }
}

///|
pub fn blit_bind_group_matches_source(
  bind_group : BlitBindGroup,
  source_texture_view_id~ : Int,
) -> Bool {
  bind_group.source_texture_view_id == source_texture_view_id
}
