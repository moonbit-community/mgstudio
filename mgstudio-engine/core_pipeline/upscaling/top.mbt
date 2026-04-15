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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/upscaling/mod.rs`.
// Upscaling plugin owner surface.

///|
const UPSCALING_PLUGIN_NAME : String = "mgstudio.core_pipeline.upscaling.UpscalingPlugin"

///|
pub struct UpscalingPlugin {}

///|
pub fn UpscalingPlugin::default() -> UpscalingPlugin {
  UpscalingPlugin::{  }
}

///|
pub fn upscaling_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  upscaling_plugin_with(app, UpscalingPlugin::default())
}

///|
pub impl @app.Plugin for UpscalingPlugin with name(_self) {
  UPSCALING_PLUGIN_NAME
}

///|
pub impl @app.Plugin for UpscalingPlugin with build(self, app) {
  upscaling_plugin_with(app, self)
}

///|
pub fn upscaling_plugin_with(
  app : @app.App[@ecs.World],
  plugin : UpscalingPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { ViewUpscalingPipeline::default() })
}

///|
pub struct ViewUpscalingPipeline {
  pipeline_id : Int
}

///|
pub fn ViewUpscalingPipeline::default() -> ViewUpscalingPipeline {
  ViewUpscalingPipeline::{ pipeline_id: -1 }
}

///|
pub fn ViewUpscalingPipeline::new(pipeline_id~ : Int) -> ViewUpscalingPipeline {
  ViewUpscalingPipeline::{ pipeline_id, }
}

///|
pub let ecs_key_view_upscaling_pipeline : @ecs.ResourceKey[
  ViewUpscalingPipeline,
] = @ecs.register_resource(debug_name="core_pipeline.upscaling.view_pipeline")

///|
pub impl @app.Resource for ViewUpscalingPipeline with resource() {
  ecs_key_view_upscaling_pipeline
}

///|
pub struct UpscalingPrepareViewState {
  out_texture_id : Int
  camera_output_mode_skip : Bool
  output_texture_seen_before : Bool
  camera_has_explicit_output_blend_state : Bool
}

///|
pub fn UpscalingPrepareViewState::new(
  out_texture_id~ : Int,
  camera_output_mode_skip? : Bool = false,
  output_texture_seen_before? : Bool = false,
  camera_has_explicit_output_blend_state? : Bool = false,
) -> UpscalingPrepareViewState {
  UpscalingPrepareViewState::{
    out_texture_id,
    camera_output_mode_skip,
    output_texture_seen_before,
    camera_has_explicit_output_blend_state,
  }
}

///|
pub fn upscaling_should_prepare_view_pipeline(
  state : UpscalingPrepareViewState,
) -> Bool {
  !state.camera_output_mode_skip
}

///|
pub fn upscaling_should_force_alpha_blending(
  state : UpscalingPrepareViewState,
) -> Bool {
  state.output_texture_seen_before &&
  !state.camera_has_explicit_output_blend_state
}
