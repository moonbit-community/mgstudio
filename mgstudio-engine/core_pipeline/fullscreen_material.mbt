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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/fullscreen_material.rs`.
// Fullscreen material plugin owner surface.

///|
const FULLSCREEN_MATERIAL_PLUGIN_NAME : String = "mgstudio.core_pipeline.fullscreen_material.FullscreenMaterialPlugin"

///|
pub struct FullscreenMaterialPlugin {}

///|
pub fn FullscreenMaterialPlugin::default() -> FullscreenMaterialPlugin {
  FullscreenMaterialPlugin::{  }
}

///|
pub fn fullscreen_material_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  fullscreen_material_plugin_with(app, FullscreenMaterialPlugin::default())
}

///|
pub impl @app.Plugin for FullscreenMaterialPlugin with name(_self) {
  FULLSCREEN_MATERIAL_PLUGIN_NAME
}

///|
pub impl @app.Plugin for FullscreenMaterialPlugin with build(self, app) {
  fullscreen_material_plugin_with(app, self)
}

///|
pub fn fullscreen_material_plugin_with(
  app : @app.App[@ecs.World],
  plugin : FullscreenMaterialPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { FullscreenMaterialPipelineState::default() })
}

///|
pub fn fullscreen_material_shader() -> @fullscreen_vertex_shader.FullscreenShader {
  @fullscreen_vertex_shader.FullscreenShader::default()
}

///|
pub const FULLSCREEN_MATERIAL_PASS_LABEL : String = "fullscreen_material_pass"

///|
pub struct FullscreenMaterialPipelineState {
  has_bind_group_layout : Bool
  has_sampler : Bool
  ldr_pipeline_id : Int
  hdr_pipeline_id : Int
}

///|
pub fn FullscreenMaterialPipelineState::default() -> FullscreenMaterialPipelineState {
  FullscreenMaterialPipelineState::new()
}

///|
pub fn FullscreenMaterialPipelineState::new(
  has_bind_group_layout? : Bool = false,
  has_sampler? : Bool = false,
  ldr_pipeline_id? : Int = -1,
  hdr_pipeline_id? : Int = -1,
) -> FullscreenMaterialPipelineState {
  FullscreenMaterialPipelineState::{
    has_bind_group_layout,
    has_sampler,
    ldr_pipeline_id,
    hdr_pipeline_id,
  }
}

///|
pub fn fullscreen_material_pipeline_ready(
  pipeline : FullscreenMaterialPipelineState,
) -> Bool {
  pipeline.has_bind_group_layout &&
  pipeline.has_sampler &&
  pipeline.ldr_pipeline_id >= 0 &&
  pipeline.hdr_pipeline_id >= 0
}

///|
pub fn fullscreen_material_pipeline_id(
  pipeline : FullscreenMaterialPipelineState,
  view_target_is_hdr~ : Bool,
) -> Int {
  if view_target_is_hdr {
    pipeline.hdr_pipeline_id
  } else {
    pipeline.ldr_pipeline_id
  }
}

///|
pub let ecs_key_fullscreen_material_pipeline : @ecs.ResourceKey[
  FullscreenMaterialPipelineState,
] = @ecs.register_resource(
  debug_name="core_pipeline.fullscreen_material.pipeline_state",
)

///|
pub impl @app.Resource for FullscreenMaterialPipelineState with resource() {
  ecs_key_fullscreen_material_pipeline
}

///|
pub struct FullscreenMaterialBindGroupState {
  source_a_texture_view_id : Int
  source_b_texture_view_id : Int
}

///|
pub fn FullscreenMaterialBindGroupState::new(
  source_a_texture_view_id~ : Int,
  source_b_texture_view_id~ : Int,
) -> FullscreenMaterialBindGroupState {
  FullscreenMaterialBindGroupState::{
    source_a_texture_view_id,
    source_b_texture_view_id,
  }
}

///|
pub fn fullscreen_material_bind_group_for_source_a(
  bind_groups : FullscreenMaterialBindGroupState,
  source_texture_view_id~ : Int,
) -> Bool {
  bind_groups.source_a_texture_view_id == source_texture_view_id
}

///|
pub fn fullscreen_material_bind_group_for_source_b(
  bind_groups : FullscreenMaterialBindGroupState,
  source_texture_view_id~ : Int,
) -> Bool {
  bind_groups.source_b_texture_view_id == source_texture_view_id
}

///|
pub fn fullscreen_material_bind_group_matches_source(
  bind_groups : FullscreenMaterialBindGroupState,
  source_texture_view_id~ : Int,
) -> Bool {
  fullscreen_material_bind_group_for_source_a(
    bind_groups,
    source_texture_view_id~,
  ) ||
  fullscreen_material_bind_group_for_source_b(
    bind_groups,
    source_texture_view_id~,
  )
}

///|
pub struct FullscreenMaterialPrepareViewState {
  main_texture_view_id : Int
  main_texture_other_view_id : Int
  has_existing_bind_groups : Bool
}

///|
pub fn FullscreenMaterialPrepareViewState::new(
  main_texture_view_id~ : Int,
  main_texture_other_view_id~ : Int,
  has_existing_bind_groups? : Bool = false,
) -> FullscreenMaterialPrepareViewState {
  FullscreenMaterialPrepareViewState::{
    main_texture_view_id,
    main_texture_other_view_id,
    has_existing_bind_groups,
  }
}

///|
pub fn fullscreen_material_requires_bind_group_build(
  state : FullscreenMaterialPrepareViewState,
) -> Bool {
  !state.has_existing_bind_groups
}

///|
pub fn fullscreen_material_requires_bind_group_update(
  state : FullscreenMaterialPrepareViewState,
  bind_groups : FullscreenMaterialBindGroupState,
) -> Bool {
  state.main_texture_view_id != bind_groups.source_a_texture_view_id ||
  state.main_texture_other_view_id != bind_groups.source_b_texture_view_id
}
