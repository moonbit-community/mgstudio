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
// Bevy source: `bevy/crates/bevy_pbr/src/prepass/mod.rs`.

///|
pub const PREPASS_PLUGIN_ID : String = @core_prepass.PREPASS_PLUGIN_ID

///|
pub const EARLY_PREPASS_LABEL : String = @core_prepass.EARLY_PREPASS_LABEL

///|
pub const LATE_PREPASS_LABEL : String = @core_prepass.LATE_PREPASS_LABEL

///|
pub type PrepassPlugin = @core_prepass.PrepassPlugin

///|
pub type PrepassNode = @core_prepass.PrepassNode

///|
pub type PrepassViewState = @core_prepass.PrepassViewState

///|
pub type DepthPrepass = @core_pipeline.DepthPrepass

///|
pub type NormalPrepass = @core_pipeline.NormalPrepass

///|
pub type MotionVectorPrepass = @core_pipeline.MotionVectorPrepass

///|
pub type DeferredPrepass = @core_pipeline.DeferredPrepass

///|
pub let ecs_key_depth_prepass : @ecs.ComponentKey[DepthPrepass] = @core_pipeline.ecs_key_depth_prepass

///|
pub let ecs_key_normal_prepass : @ecs.ComponentKey[NormalPrepass] = @core_pipeline.ecs_key_normal_prepass

///|
pub let ecs_key_motion_vector_prepass : @ecs.ComponentKey[MotionVectorPrepass] = @core_pipeline.ecs_key_motion_vector_prepass

///|
pub let ecs_key_deferred_prepass : @ecs.ComponentKey[DeferredPrepass] = @core_pipeline.ecs_key_deferred_prepass

///|
pub let ecs_key_prepass_view_state : @ecs.ResourceKey[PrepassViewState] = @core_prepass.ecs_key_prepass_view_state

///|
pub fn prepass_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @core_prepass.prepass_plugin(app)
}

///|
pub fn prepass_plugin_with(
  app : @app.App[@ecs.World],
  plugin : PrepassPlugin,
) -> @app.App[@ecs.World] {
  @core_prepass.prepass_plugin_with(app, plugin)
}

///|
pub fn prepass_any_color_attachment_enabled(
  has_normal~ : Bool,
  has_motion_vectors~ : Bool,
  has_deferred~ : Bool,
  has_deferred_lighting_pass_id~ : Bool,
) -> Bool {
  @core_prepass.prepass_any_color_attachment_enabled(
    has_normal~, has_motion_vectors~, has_deferred~, has_deferred_lighting_pass_id~,
  )
}

///|
pub fn prepass_has_any_phase(state : PrepassViewState) -> Bool {
  @core_prepass.prepass_has_any_phase(state)
}

///|
pub fn prepass_should_skip_due_to_deferred(state : PrepassViewState) -> Bool {
  @core_prepass.prepass_should_skip_due_to_deferred(state)
}

///|
pub fn early_prepass_should_run(state : PrepassViewState) -> Bool {
  @core_prepass.early_prepass_should_run(state)
}

///|
pub fn late_prepass_should_run(state : PrepassViewState) -> Bool {
  @core_prepass.late_prepass_should_run(state)
}

///|
pub fn prepass_should_copy_depth_to_prepass_depth(
  state : PrepassViewState,
) -> Bool {
  @core_prepass.prepass_should_copy_depth_to_prepass_depth(state)
}

///|
pub fn prepass_has_any_color_attachment(state : PrepassViewState) -> Bool {
  @core_prepass.prepass_has_any_color_attachment(state)
}
