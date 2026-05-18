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
const DEFERRED_PBR_LIGHTING_PLUGIN_NAME : String = "mgstudio.pbr.DeferredPbrLightingPlugin"

///|
pub const DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID : Int = 1

///|
pub const DEFERRED_PREPASS_EARLY_LABEL : String = @core_deferred.DEFERRED_PREPASS_EARLY_LABEL

///|
pub const DEFERRED_PREPASS_LATE_LABEL : String = @core_deferred.DEFERRED_PREPASS_LATE_LABEL

///|
pub type DeferredPlugin = @core_deferred.DeferredPlugin

///|
pub type DeferredPrepassNode = @core_deferred.DeferredPrepassNode

///|
pub type DeferredPrepassRunKind = @core_deferred.DeferredPrepassRunKind

///|
pub type DeferredPrepassViewState = @core_deferred.DeferredPrepassViewState

///|
pub type DeferredPrepassColorAttachmentPlan = @core_deferred.DeferredPrepassColorAttachmentPlan

///|
pub type DeferredPrepassRunPlan = @core_deferred.DeferredPrepassRunPlan

///|
pub struct DeferredPbrLightingState {
  enabled : Bool
}

///|
pub fn DeferredPbrLightingState::enabled() -> DeferredPbrLightingState {
  DeferredPbrLightingState::{ enabled: true }
}

///|
pub fn DeferredPbrLightingState::disabled() -> DeferredPbrLightingState {
  DeferredPbrLightingState::{ enabled: false }
}

///|
pub let ecs_key_deferred_pbr_lighting_state : @ecs.ResourceKey[
  DeferredPbrLightingState,
] = @ecs.register_resource(debug_name="mgstudio_pbr::DeferredPbrLightingState")

///|
pub struct DeferredPbrLightingPlugin {}

///|
pub fn DeferredPbrLightingPlugin::default() -> DeferredPbrLightingPlugin {
  DeferredPbrLightingPlugin::{  }
}

///|
pub impl @app.Plugin for DeferredPbrLightingPlugin with name(_self) {
  DEFERRED_PBR_LIGHTING_PLUGIN_NAME
}

///|
pub impl @app.Plugin for DeferredPbrLightingPlugin with build(_self, app) {
  register_embedded_wgsl_sources()
  deferred_pbr_lighting_plugin(app)
}

///|
pub struct PbrDeferredLightingDepthId {
  mut depth_id : Int
}

///|
pub let ecs_key_pbr_deferred_lighting_depth_id : @ecs.ComponentKey[
  PbrDeferredLightingDepthId,
] = @ecs.register_component(debug_name="mgstudio.pbr.deferred.depth_id")

///|
pub fn PbrDeferredLightingDepthId::default() -> PbrDeferredLightingDepthId {
  PbrDeferredLightingDepthId::{
    depth_id: DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID,
  }
}

///|
pub fn PbrDeferredLightingDepthId::new(
  value : Int,
) -> PbrDeferredLightingDepthId {
  PbrDeferredLightingDepthId::{
    depth_id: if value < 0 {
      0
    } else if value > 255 {
      255
    } else {
      value
    },
  }
}

///|
pub fn PbrDeferredLightingDepthId::set(
  self : PbrDeferredLightingDepthId,
  value : Int,
) -> Unit {
  self.depth_id = if value < 0 { 0 } else if value > 255 { 255 } else { value }
}

///|
pub fn PbrDeferredLightingDepthId::get(
  self : PbrDeferredLightingDepthId,
) -> Int {
  self.depth_id
}

///|
pub impl @ecs.Component for PbrDeferredLightingDepthId with component() {
  ecs_key_pbr_deferred_lighting_depth_id
}

///|
fn insert_deferred_lighting_pass_id_component(world : @ecs.World) -> Unit {
  let query : @ecs.Query[
    @ecs.Has[PbrDeferredLightingDepthId],
    @ecs.With[@core_pipeline.DeferredPrepass],
  ] = @ecs.query_filtered(
    world,
    @ecs.With::new(@core_pipeline.DeferredPrepass::component()),
  )
  let missing_depth_id_entities = []
  try! query.view(fn(entity, has_depth_id) {
    if !has_depth_id.present() {
      missing_depth_id_entities.push(entity)
    }
  })
  for entity in missing_depth_id_entities {
    try! world.set_by_key(
      entity,
      ecs_key_pbr_deferred_lighting_depth_id,
      PbrDeferredLightingDepthId::default(),
    )
  }
}

///|
pub fn deferred_pbr_lighting_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .insert_world_resource(
    ecs_key_deferred_pbr_lighting_state,
    DeferredPbrLightingState::enabled(),
  )
  .add_systems(
    @app.PostUpdate,
    @app.system(insert_deferred_lighting_pass_id_component),
  )
}

///|
pub fn deferred_pbr_lighting_enabled(world : @ecs.World) -> Bool {
  match (try! world.get_resource(ecs_key_deferred_pbr_lighting_state)) {
    Some(state) => state.enabled
    None => false
  }
}

///|
pub fn deferred_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @core_deferred.deferred_plugin(app)
}

///|
pub fn deferred_plugin_with(
  app : @app.App[@ecs.World],
  plugin : DeferredPlugin,
) -> @app.App[@ecs.World] {
  @core_deferred.deferred_plugin_with(app, plugin)
}

///|
pub fn deferred_prepass_has_any_phase(state : DeferredPrepassViewState) -> Bool {
  @core_deferred.deferred_prepass_has_any_phase(state)
}

///|
pub fn early_deferred_prepass_should_run(
  state : DeferredPrepassViewState,
) -> Bool {
  @core_deferred.early_deferred_prepass_should_run(state)
}

///|
pub fn late_deferred_prepass_should_run(
  state : DeferredPrepassViewState,
) -> Bool {
  @core_deferred.late_deferred_prepass_should_run(state)
}

///|
pub fn deferred_prepass_run_kind_label(kind : DeferredPrepassRunKind) -> String {
  @core_deferred.deferred_prepass_run_kind_label(kind)
}

///|
pub fn deferred_prepass_run_kind_is_late(kind : DeferredPrepassRunKind) -> Bool {
  @core_deferred.deferred_prepass_run_kind_is_late(kind)
}

///|
pub fn deferred_prepass_run_kind_should_run(
  kind : DeferredPrepassRunKind,
  state : DeferredPrepassViewState,
) -> Bool {
  @core_deferred.deferred_prepass_run_kind_should_run(kind, state)
}

///|
pub fn deferred_prepass_color_attachment_plan(
  kind : DeferredPrepassRunKind,
  state : DeferredPrepassViewState,
  webgl_manual_clear_supported? : Bool = false,
) -> DeferredPrepassColorAttachmentPlan {
  @core_deferred.deferred_prepass_color_attachment_plan(
    kind,
    state,
    webgl_manual_clear_supported~,
  )
}

///|
pub fn deferred_prepass_run_plan(
  kind : DeferredPrepassRunKind,
  state : DeferredPrepassViewState,
  webgl_manual_clear_supported? : Bool = false,
) -> DeferredPrepassRunPlan {
  @core_deferred.deferred_prepass_run_plan(
    kind,
    state,
    webgl_manual_clear_supported~,
  )
}
