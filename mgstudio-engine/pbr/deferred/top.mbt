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
pub const DEFERRED_LIGHTING_PASS_LABEL : String = "deferred_lighting"

///|
pub const DEFERRED_LIGHTING_PIPELINE_LABEL : String = "deferred_lighting_pipeline"

///|
pub const DEFERRED_LIGHTING_LAYOUT_LABEL : String = "deferred_lighting_layout"

///|
pub const DEFERRED_LIGHTING_LAYOUT_GROUP_2_LABEL : String = "deferred_lighting_layout_group_2"

///|
pub const DEFERRED_LIGHTING_SHADER_PATH : String = "pbr/deferred/deferred_lighting.wgsl"

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
pub type Tonemapping = @post_process.Tonemapping

///|
pub type DebandDither = @post_process.DebandDither

///|
pub(all) enum DeferredLightingShadowFilteringMethod {
  Hardware2x2
  Gaussian
  Temporal
} derive(Eq, Debug)

///|
pub fn DeferredLightingShadowFilteringMethod::default() -> DeferredLightingShadowFilteringMethod {
  DeferredLightingShadowFilteringMethod::Gaussian
}

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
pub struct DeferredLightingPipeline {
  pipeline_id : Int
} derive(ToJson, FromJson)

///|
pub fn DeferredLightingPipeline::new(
  pipeline_id~ : Int,
) -> DeferredLightingPipeline {
  DeferredLightingPipeline::{ pipeline_id, }
}

///|
pub fn DeferredLightingPipeline::pipeline_id(
  self : DeferredLightingPipeline,
) -> Int {
  self.pipeline_id
}

///|
pub struct SkipDeferredLighting {} derive(Default, Eq, Debug, ToJson, FromJson)

///|
pub struct DeferredLightingViewState {
  hdr : Bool
  invert_culling : Bool
  tonemapping : Tonemapping?
  deband_dither : DebandDither?
  shadow_filter_method : DeferredLightingShadowFilteringMethod?
  screen_space_ambient_occlusion : Bool
  screen_space_reflections : Bool
  distance_fog : Bool
  normal_prepass : Bool
  depth_prepass : Bool
  motion_vector_prepass : Bool
  deferred_prepass : Bool
  environment_map : Bool
  irradiance_volume : Bool
  skip_deferred_lighting : Bool
  atmosphere : Bool
  binding_arrays_are_usable : Bool
}

///|
pub fn DeferredLightingViewState::new(
  hdr? : Bool = false,
  invert_culling? : Bool = false,
  tonemapping? : Tonemapping? = None,
  deband_dither? : DebandDither? = None,
  shadow_filter_method? : DeferredLightingShadowFilteringMethod? = None,
  screen_space_ambient_occlusion? : Bool = false,
  screen_space_reflections? : Bool = false,
  distance_fog? : Bool = false,
  normal_prepass? : Bool = false,
  depth_prepass? : Bool = false,
  motion_vector_prepass? : Bool = false,
  deferred_prepass? : Bool = false,
  environment_map? : Bool = false,
  irradiance_volume? : Bool = false,
  skip_deferred_lighting? : Bool = false,
  atmosphere? : Bool = false,
  binding_arrays_are_usable? : Bool = false,
) -> DeferredLightingViewState {
  DeferredLightingViewState::{
    hdr,
    invert_culling,
    tonemapping,
    deband_dither,
    shadow_filter_method,
    screen_space_ambient_occlusion,
    screen_space_reflections,
    distance_fog,
    normal_prepass,
    depth_prepass,
    motion_vector_prepass,
    deferred_prepass,
    environment_map,
    irradiance_volume,
    skip_deferred_lighting,
    atmosphere,
    binding_arrays_are_usable,
  }
}

///|
pub struct DeferredLightingPreparePlan {
  should_prepare : Bool
  remove_existing_pipeline : Bool
  shader_defs : Array[String]
  color_target_format : String
}

///|
pub struct DeferredLightingPipelineDescriptorPlan {
  label : String
  layout_count : Int
  main_view_layout : Bool
  binding_array_layout : Bool
  depth_id_layout : Bool
  vertex_shader_path : String
  fragment_shader_path : String
  shader_defs : Array[String]
  color_target_count : Int
  color_target_format : String
  color_write_mask_all : Bool
  depth_format : String
  depth_write_enabled : Bool
  depth_compare : String
  stencil_ignored : Bool
}

///|
pub struct DeferredLightingPassPlan {
  label : String
  should_run : Bool
  color_attachment_count : Int
  depth_format : String
  depth_load : String
  depth_store : String
  bind_group_count : Int
  dynamic_offset_count : Int
  bind_group_2_label : String
  draw_vertex_start : Int
  draw_vertex_end : Int
  draw_instance_start : Int
  draw_instance_end : Int
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
pub let ecs_key_deferred_lighting_pipeline : @ecs.ComponentKey[
  DeferredLightingPipeline,
] = @ecs.register_component(debug_name="mgstudio.pbr.deferred.pipeline")

///|
pub let ecs_key_skip_deferred_lighting : @ecs.ComponentKey[SkipDeferredLighting] = @ecs.register_component(
  debug_name="mgstudio.pbr.deferred.skip_lighting",
)

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
pub impl @ecs.Component for DeferredLightingPipeline with component() {
  ecs_key_deferred_lighting_pipeline
}

///|
pub impl @ecs.Component for SkipDeferredLighting with component() {
  ecs_key_skip_deferred_lighting
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
fn deferred_lighting_tonemapping_shader_def(
  tonemapping : Tonemapping,
) -> String {
  match tonemapping {
    Tonemapping::None => "TONEMAP_METHOD_NONE"
    Tonemapping::Reinhard => "TONEMAP_METHOD_REINHARD"
    Tonemapping::ReinhardLuminance => "TONEMAP_METHOD_REINHARD_LUMINANCE"
    Tonemapping::AcesFitted => "TONEMAP_METHOD_ACES_FITTED"
    Tonemapping::AgX => "TONEMAP_METHOD_AGX"
    Tonemapping::SomewhatBoringDisplayTransform =>
      "TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM"
    Tonemapping::TonyMcMapface => "TONEMAP_METHOD_TONY_MC_MAPFACE"
    Tonemapping::BlenderFilmic => "TONEMAP_METHOD_BLENDER_FILMIC"
  }
}

///|
fn deferred_lighting_shadow_filter_shader_def(
  filtering : DeferredLightingShadowFilteringMethod,
) -> String {
  match filtering {
    Hardware2x2 => "SHADOW_FILTER_METHOD_HARDWARE_2X2"
    Gaussian => "SHADOW_FILTER_METHOD_GAUSSIAN"
    Temporal => "SHADOW_FILTER_METHOD_TEMPORAL"
  }
}

///|
pub fn deferred_lighting_shader_defs(
  state : DeferredLightingViewState,
) -> Array[String] {
  let shader_defs : Array[String] = []
  shader_defs.push("DEFERRED_LIGHTING_PIPELINE")
  match state.tonemapping {
    Some(tonemapping) =>
      if !state.hdr {
        shader_defs.push("TONEMAP_IN_SHADER")
        shader_defs.push(deferred_lighting_tonemapping_shader_def(tonemapping))
        match state.deband_dither {
          Some(DebandDither::Enabled) => shader_defs.push("DEBAND_DITHER")
          Some(DebandDither::Disabled) | None => ()
        }
      }
    None => ()
  }
  if state.screen_space_ambient_occlusion {
    shader_defs.push("SCREEN_SPACE_AMBIENT_OCCLUSION")
  }
  if state.environment_map {
    shader_defs.push("ENVIRONMENT_MAP")
  }
  if state.irradiance_volume {
    shader_defs.push("IRRADIANCE_VOLUME")
  }
  if state.normal_prepass {
    shader_defs.push("NORMAL_PREPASS")
  }
  if state.depth_prepass {
    shader_defs.push("DEPTH_PREPASS")
  }
  if state.motion_vector_prepass {
    shader_defs.push("MOTION_VECTOR_PREPASS")
  }
  if state.screen_space_reflections {
    shader_defs.push("SCREEN_SPACE_REFLECTIONS")
  }
  if state.distance_fog {
    shader_defs.push("DISTANCE_FOG")
  }
  if state.atmosphere {
    shader_defs.push("ATMOSPHERE")
  }
  shader_defs.push("DEFERRED_PREPASS")
  let shadow_filter = match state.shadow_filter_method {
    Some(filtering) => filtering
    None => DeferredLightingShadowFilteringMethod::default()
  }
  shader_defs.push(deferred_lighting_shadow_filter_shader_def(shadow_filter))
  if state.binding_arrays_are_usable {
    shader_defs.push("MULTIPLE_LIGHT_PROBES_IN_ARRAY")
    shader_defs.push("MULTIPLE_LIGHTMAPS_IN_ARRAY")
  }
  shader_defs
}

///|
pub fn deferred_lighting_color_target_format(
  state : DeferredLightingViewState,
) -> String {
  if state.hdr {
    "ViewTarget::TEXTURE_FORMAT_HDR"
  } else {
    "TextureFormat::bevy_default"
  }
}

///|
pub fn deferred_lighting_prepare_plan(
  state : DeferredLightingViewState,
) -> DeferredLightingPreparePlan {
  let should_prepare = state.deferred_prepass && !state.skip_deferred_lighting
  DeferredLightingPreparePlan::{
    should_prepare,
    remove_existing_pipeline: !should_prepare,
    shader_defs: if should_prepare {
      deferred_lighting_shader_defs(state)
    } else {
      []
    },
    color_target_format: deferred_lighting_color_target_format(state),
  }
}

///|
pub fn deferred_lighting_pipeline_descriptor_plan(
  state : DeferredLightingViewState,
) -> DeferredLightingPipelineDescriptorPlan {
  DeferredLightingPipelineDescriptorPlan::{
    label: DEFERRED_LIGHTING_PIPELINE_LABEL,
    layout_count: 3,
    main_view_layout: true,
    binding_array_layout: true,
    depth_id_layout: true,
    vertex_shader_path: DEFERRED_LIGHTING_SHADER_PATH,
    fragment_shader_path: DEFERRED_LIGHTING_SHADER_PATH,
    shader_defs: deferred_lighting_shader_defs(state),
    color_target_count: 1,
    color_target_format: deferred_lighting_color_target_format(state),
    color_write_mask_all: true,
    depth_format: @core_deferred.DEFERRED_LIGHTING_PASS_ID_DEPTH_FORMAT,
    depth_write_enabled: false,
    depth_compare: "Equal",
    stencil_ignored: true,
  }
}

///|
pub fn deferred_lighting_pass_plan(
  has_pipeline? : Bool = false,
  has_depth_id_binding? : Bool = false,
  has_mesh_view_bind_group? : Bool = false,
  has_view_target? : Bool = false,
  has_deferred_lighting_id_depth_texture? : Bool = false,
) -> DeferredLightingPassPlan {
  let should_run = has_pipeline &&
    has_depth_id_binding &&
    has_mesh_view_bind_group &&
    has_view_target &&
    has_deferred_lighting_id_depth_texture
  DeferredLightingPassPlan::{
    label: DEFERRED_LIGHTING_PASS_LABEL,
    should_run,
    color_attachment_count: if should_run {
      1
    } else {
      0
    },
    depth_format: @core_deferred.DEFERRED_LIGHTING_PASS_ID_DEPTH_FORMAT,
    depth_load: "Load",
    depth_store: "Discard",
    bind_group_count: if should_run {
      3
    } else {
      0
    },
    dynamic_offset_count: if should_run {
      7
    } else {
      0
    },
    bind_group_2_label: DEFERRED_LIGHTING_LAYOUT_GROUP_2_LABEL,
    draw_vertex_start: 0,
    draw_vertex_end: 3,
    draw_instance_start: 0,
    draw_instance_end: 1,
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
