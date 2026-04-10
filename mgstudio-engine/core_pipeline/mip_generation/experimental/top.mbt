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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/mip_generation/experimental/mod.rs`.
// Experimental mip-generation module surface.

///|
pub const EXPERIMENTAL_MIP_GENERATION_MODULE_ID : String = "bevy_core_pipeline::mip_generation::experimental"

///|
pub struct ExperimentalMipGeneration {}

///|
pub fn ExperimentalMipGeneration::default() -> ExperimentalMipGeneration {
  ExperimentalMipGeneration::{  }
}

///|
pub fn experimental_mip_generation_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  experimental_mip_generation_plugin_with(
    app,
    ExperimentalMipGeneration::default(),
  )
}

///|
pub fn experimental_mip_generation_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ExperimentalMipGeneration,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { DownsampleDepthPipelinePairState::default() })
}

///|
pub impl @app.PluginReplacement for ExperimentalMipGeneration with replacement_id(
  _self,
) {
  EXPERIMENTAL_MIP_GENERATION_MODULE_ID
}

///|
pub impl @app.PluginReplacement for ExperimentalMipGeneration with world_plugin(
  self,
) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    experimental_mip_generation_plugin_with(app, self)
  }
}

///|
pub fn experimental_mip_generation_has_depth_support() -> Bool {
  DEPTH_PYRAMID_MIP_COUNT > 0
}

///|
pub fn experimental_mip_generation_depth_pass_labels() -> Array[String] {
  [
    downsample_depth_pass_label(DownsampleDepthPassKind::Early),
    downsample_depth_pass_label(DownsampleDepthPassKind::Late),
  ]
}
