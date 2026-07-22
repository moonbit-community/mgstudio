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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/deferred/copy_lighting_id.rs`.
// Deferred lighting-id copy node/plugin surface.

///|
const COPY_DEFERRED_LIGHTING_ID_PLUGIN_NAME : String = "mgstudio.core_pipeline.deferred.copy_lighting_id.CopyDeferredLightingIdPlugin"

///|
pub const COPY_DEFERRED_LIGHTING_ID_PASS_LABEL : String = "copy_deferred_lighting_id"

///|
pub const COPY_DEFERRED_LIGHTING_ID_BIND_GROUP_LAYOUT_LABEL : String = "copy_deferred_lighting_id_bind_group_layout"

///|
pub const COPY_DEFERRED_LIGHTING_ID_BIND_GROUP_LABEL : String = "copy_deferred_lighting_id_bind_group"

///|
pub const COPY_DEFERRED_LIGHTING_ID_PIPELINE_LABEL : String = "copy_deferred_lighting_id_pipeline"

///|
pub const COPY_DEFERRED_LIGHTING_ID_SHADER_PATH : String = "core_pipeline/deferred/copy_deferred_lighting_id.wgsl"

///|
pub const DEFERRED_LIGHTING_ID_DEPTH_TEXTURE_LABEL : String = "deferred_lighting_id_depth_texture_a"

///|
pub struct CopyDeferredLightingIdPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn CopyDeferredLightingIdPlugin::CopyDeferredLightingIdPlugin() -> CopyDeferredLightingIdPlugin {
  CopyDeferredLightingIdPlugin::{  }
}

///|
pub struct CopyDeferredLightingIdPipelinePlan {
  bind_group_layout_label : String
  bind_group_layout_count : Int
  texture_sample_type_uint : Bool
  uses_fullscreen_vertex_shader : Bool
  fragment_shader_path : String
  render_pipeline_label : String
  depth_format : String
  depth_write_enabled : Bool
  depth_compare_always : Bool
}

///|
pub struct CopyDeferredLightingIdPassPlan {
  label : String
  should_run : Bool
  bind_group_label : String
  color_attachment_count : Int
  has_depth_stencil_attachment : Bool
  depth_format : String
  depth_load_clear_value : Int
  depth_store : Bool
  draw_vertex_start : Int
  draw_vertex_end : Int
  draw_instance_start : Int
  draw_instance_end : Int
}

///|
pub struct DeferredLightingIdDepthTextureDescriptorPlan {
  label : String
  should_prepare : Bool
  width : Int
  height : Int
  mip_level_count : Int
  sample_count : Int
  dimension : String
  format : String
  usage_render_attachment : Bool
  usage_copy_src : Bool
  view_format_count : Int
}

///|
pub struct DeferredLightingIdDepthTexture {
  texture_id : Int
}

///|
pub fn DeferredLightingIdDepthTexture::new(
  texture_id~ : Int,
) -> DeferredLightingIdDepthTexture {
  { texture_id, }
}

///|
pub fn copy_deferred_lighting_id_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  copy_deferred_lighting_id_plugin_with(app, CopyDeferredLightingIdPlugin())
}

///|
pub impl @app.Plugin for CopyDeferredLightingIdPlugin with fn name(_self) {
  COPY_DEFERRED_LIGHTING_ID_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CopyDeferredLightingIdPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  copy_deferred_lighting_id_plugin_with(app, self)
}

///|
pub fn copy_deferred_lighting_id_plugin_with(
  app : @app.App[@ecs.World],
  plugin : CopyDeferredLightingIdPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() {
    CopyDeferredLightingIdState::CopyDeferredLightingIdState()
  })
}

///|
pub fn deferred_lighting_id_depth_texture_id(
  texture : DeferredLightingIdDepthTexture,
) -> Int {
  texture.texture_id
}

///|
pub struct CopyDeferredLightingIdState {
  has_copy_pipeline : Bool
  has_deferred_lighting_pass_id_texture : Bool
  has_deferred_lighting_id_depth_texture : Bool
}

///|
pub fn CopyDeferredLightingIdState::CopyDeferredLightingIdState() -> CopyDeferredLightingIdState {
  CopyDeferredLightingIdState::new()
}

///|
pub fn CopyDeferredLightingIdState::new(
  has_copy_pipeline? : Bool = false,
  has_deferred_lighting_pass_id_texture? : Bool = false,
  has_deferred_lighting_id_depth_texture? : Bool = false,
) -> CopyDeferredLightingIdState {
  {
    has_copy_pipeline,
    has_deferred_lighting_pass_id_texture,
    has_deferred_lighting_id_depth_texture,
  }
}

///|
pub fn copy_deferred_lighting_id_should_run(
  state : CopyDeferredLightingIdState,
) -> Bool {
  state.has_copy_pipeline &&
  state.has_deferred_lighting_pass_id_texture &&
  state.has_deferred_lighting_id_depth_texture
}

///|
pub fn copy_deferred_lighting_id_pipeline_plan() -> CopyDeferredLightingIdPipelinePlan {
  {
    bind_group_layout_label: COPY_DEFERRED_LIGHTING_ID_BIND_GROUP_LAYOUT_LABEL,
    bind_group_layout_count: 1,
    texture_sample_type_uint: true,
    uses_fullscreen_vertex_shader: true,
    fragment_shader_path: COPY_DEFERRED_LIGHTING_ID_SHADER_PATH,
    render_pipeline_label: COPY_DEFERRED_LIGHTING_ID_PIPELINE_LABEL,
    depth_format: DEFERRED_LIGHTING_PASS_ID_DEPTH_FORMAT,
    depth_write_enabled: true,
    depth_compare_always: true,
  }
}

///|
pub fn copy_deferred_lighting_id_pass_plan(
  state : CopyDeferredLightingIdState,
) -> CopyDeferredLightingIdPassPlan {
  let should_run = copy_deferred_lighting_id_should_run(state)
  {
    label: COPY_DEFERRED_LIGHTING_ID_PASS_LABEL,
    should_run,
    bind_group_label: COPY_DEFERRED_LIGHTING_ID_BIND_GROUP_LABEL,
    color_attachment_count: 0,
    has_depth_stencil_attachment: should_run,
    depth_format: DEFERRED_LIGHTING_PASS_ID_DEPTH_FORMAT,
    depth_load_clear_value: 0,
    depth_store: should_run,
    draw_vertex_start: 0,
    draw_vertex_end: 3,
    draw_instance_start: 0,
    draw_instance_end: 1,
  }
}

///|
pub fn deferred_lighting_id_depth_texture_should_prepare(
  physical_target_width : Int,
  physical_target_height : Int,
) -> Bool {
  physical_target_width > 0 && physical_target_height > 0
}

///|
pub fn deferred_lighting_id_depth_texture_descriptor_plan(
  physical_target_width : Int,
  physical_target_height : Int,
) -> DeferredLightingIdDepthTextureDescriptorPlan {
  {
    label: DEFERRED_LIGHTING_ID_DEPTH_TEXTURE_LABEL,
    should_prepare: deferred_lighting_id_depth_texture_should_prepare(
      physical_target_width, physical_target_height,
    ),
    width: physical_target_width,
    height: physical_target_height,
    mip_level_count: 1,
    sample_count: 1,
    dimension: "D2",
    format: DEFERRED_LIGHTING_PASS_ID_DEPTH_FORMAT,
    usage_render_attachment: true,
    usage_copy_src: true,
    view_format_count: 0,
  }
}

///|
pub let ecs_key_copy_deferred_lighting_id_state : @ecs.ResourceKey[
  CopyDeferredLightingIdState,
] = @ecs.register_resource(
  debug_name="core_pipeline.deferred.copy_lighting_id.state",
)

///|
pub impl @app.Resource for CopyDeferredLightingIdState with fn resource() {
  ecs_key_copy_deferred_lighting_id_state
}
