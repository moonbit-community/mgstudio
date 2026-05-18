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
pub const DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID : Int = @pbr_deferred.DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID

///|
pub const DEFERRED_LIGHTING_PASS_LABEL : String = @pbr_deferred.DEFERRED_LIGHTING_PASS_LABEL

///|
pub const DEFERRED_LIGHTING_PIPELINE_LABEL : String = @pbr_deferred.DEFERRED_LIGHTING_PIPELINE_LABEL

///|
pub const DEFERRED_LIGHTING_LAYOUT_LABEL : String = @pbr_deferred.DEFERRED_LIGHTING_LAYOUT_LABEL

///|
pub const DEFERRED_LIGHTING_LAYOUT_GROUP_2_LABEL : String = @pbr_deferred.DEFERRED_LIGHTING_LAYOUT_GROUP_2_LABEL

///|
pub const DEFERRED_LIGHTING_SHADER_PATH : String = @pbr_deferred.DEFERRED_LIGHTING_SHADER_PATH

///|
pub type DeferredPbrLightingState = @pbr_deferred.DeferredPbrLightingState

///|
pub let ecs_key_deferred_pbr_lighting_state : @ecs.ResourceKey[
  DeferredPbrLightingState,
] = @pbr_deferred.ecs_key_deferred_pbr_lighting_state

///|
pub type DeferredPbrLightingPlugin = @pbr_deferred.DeferredPbrLightingPlugin

///|
pub type DeferredLightingPipeline = @pbr_deferred.DeferredLightingPipeline

///|
pub type DeferredLightingViewState = @pbr_deferred.DeferredLightingViewState

///|
pub type DeferredLightingPreparePlan = @pbr_deferred.DeferredLightingPreparePlan

///|
pub type DeferredLightingPipelineDescriptorPlan = @pbr_deferred.DeferredLightingPipelineDescriptorPlan

///|
pub type DeferredLightingPassPlan = @pbr_deferred.DeferredLightingPassPlan

///|
pub type DeferredLightingShadowFilteringMethod = @pbr_deferred.DeferredLightingShadowFilteringMethod

///|
pub type SkipDeferredLighting = @pbr_deferred.SkipDeferredLighting

///|
pub type PbrDeferredLightingDepthId = @pbr_deferred.PbrDeferredLightingDepthId

///|
pub let ecs_key_deferred_lighting_pipeline : @ecs.ComponentKey[
  DeferredLightingPipeline,
] = @pbr_deferred.ecs_key_deferred_lighting_pipeline

///|
pub let ecs_key_skip_deferred_lighting : @ecs.ComponentKey[SkipDeferredLighting] = @pbr_deferred.ecs_key_skip_deferred_lighting

///|
pub let ecs_key_pbr_deferred_lighting_depth_id : @ecs.ComponentKey[
  PbrDeferredLightingDepthId,
] = @pbr_deferred.ecs_key_pbr_deferred_lighting_depth_id

///|
pub fn deferred_pbr_lighting_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @pbr_deferred.deferred_pbr_lighting_plugin(app)
}

///|
pub fn deferred_pbr_lighting_enabled(world : @ecs.World) -> Bool {
  @pbr_deferred.deferred_pbr_lighting_enabled(world)
}

///|
pub fn deferred_lighting_shader_defs(
  state : DeferredLightingViewState,
) -> Array[String] {
  @pbr_deferred.deferred_lighting_shader_defs(state)
}

///|
pub fn deferred_lighting_color_target_format(
  state : DeferredLightingViewState,
) -> String {
  @pbr_deferred.deferred_lighting_color_target_format(state)
}

///|
pub fn deferred_lighting_prepare_plan(
  state : DeferredLightingViewState,
) -> DeferredLightingPreparePlan {
  @pbr_deferred.deferred_lighting_prepare_plan(state)
}

///|
pub fn deferred_lighting_pipeline_descriptor_plan(
  state : DeferredLightingViewState,
) -> DeferredLightingPipelineDescriptorPlan {
  @pbr_deferred.deferred_lighting_pipeline_descriptor_plan(state)
}

///|
pub fn deferred_lighting_pass_plan(
  has_pipeline? : Bool = false,
  has_depth_id_binding? : Bool = false,
  has_mesh_view_bind_group? : Bool = false,
  has_view_target? : Bool = false,
  has_deferred_lighting_id_depth_texture? : Bool = false,
) -> DeferredLightingPassPlan {
  @pbr_deferred.deferred_lighting_pass_plan(
    has_pipeline~,
    has_depth_id_binding~,
    has_mesh_view_bind_group~,
    has_view_target~,
    has_deferred_lighting_id_depth_texture~,
  )
}
