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
// Bevy source: `bevy/crates/bevy_anti_alias/src/smaa/mod.rs`.

///|
pub const SMAA_RUNTIME_SUPPORTED : Bool = false

///|
const SMAA_PLUGIN_NAME : String = "mgstudio.anti_alias.smaa.SmaaPlugin"

///|
pub struct SmaaPlugin {}

///|
pub fn SmaaPlugin::default() -> SmaaPlugin {
  SmaaPlugin::{  }
}

///|
pub(all) enum SmaaPreset {
  Low
  Medium
  High
  Ultra
} derive(Eq, Debug)

///|
pub fn SmaaPreset::default() -> SmaaPreset {
  High
}

///|
pub fn SmaaPreset::shader_def(self : SmaaPreset) -> String {
  match self {
    Low => "SMAA_PRESET_LOW"
    Medium => "SMAA_PRESET_MEDIUM"
    High => "SMAA_PRESET_HIGH"
    Ultra => "SMAA_PRESET_ULTRA"
  }
}

///|
pub struct Smaa {
  preset : SmaaPreset
} derive(Eq, Debug)

///|
pub fn Smaa::default() -> Smaa {
  Smaa::{ preset: SmaaPreset::default() }
}

///|
const SMAA_AREA_LUT_PATH : String = "anti_alias/smaa/SMAAAreaLUT.ktx2"

///|
const SMAA_SEARCH_LUT_PATH : String = "anti_alias/smaa/SMAASearchLUT.ktx2"

///|
pub struct SmaaLuts {
  area_lut : @asset.Handle[@asset.Image]
  search_lut : @asset.Handle[@asset.Image]
}

///|
pub fn SmaaLuts::from_asset_server(
  asset_server : @asset.AssetServer,
) -> SmaaLuts {
  SmaaLuts::{
    area_lut: asset_server.load_with_settings(SMAA_AREA_LUT_PATH, fn(settings) {
      settings.is_srgb = false
      settings.asset_usage = @asset.RenderAssetUsages::render_world()
    }),
    search_lut: asset_server.load_with_settings(SMAA_SEARCH_LUT_PATH, fn(
      settings,
    ) {
      settings.is_srgb = false
      settings.asset_usage = @asset.RenderAssetUsages::render_world()
    }),
  }
}

///|
pub let ecs_key_smaa_luts : @ecs.ResourceKey[SmaaLuts] = @ecs.register_resource(
  debug_name="mgstudio_anti_alias::SmaaLuts",
)

///|
pub fn smaa_embedded_lut_registered(path : String) -> Bool {
  @embedded_asset.embedded_asset_virtual_bytes(path) is Some(_)
}

///|
pub impl @app.Resource for SmaaLuts with resource() {
  ecs_key_smaa_luts
}

///|
pub struct SmaaInfoUniform {
  rt_metrics : @math.Vec4
} derive(ToJson)

///|
pub fn SmaaInfoUniform::from_viewport_size(
  width : Float,
  height : Float,
) -> SmaaInfoUniform {
  SmaaInfoUniform::{
    rt_metrics: @math.Vec4::new(1.0F / width, 1.0F / height, width, height),
  }
}

///|
pub struct SmaaInfoUniformOffset {
  offset : UInt
} derive(Eq, Debug)

///|
pub fn SmaaInfoUniformOffset::new(offset : UInt) -> SmaaInfoUniformOffset {
  SmaaInfoUniformOffset::{ offset, }
}

///|
pub struct SmaaRuntimeState {
  enabled_camera_count : Int
  runtime_supported : Bool
} derive(Eq, Debug)

///|
pub struct SmaaEdgeDetectionPipeline {
  postprocess_bind_group_layout : @material.BindGroupLayoutDescriptor
  edge_detection_bind_group_layout : @material.BindGroupLayoutDescriptor
  shader : String
}

///|
pub struct SmaaBlendingWeightCalculationPipeline {
  postprocess_bind_group_layout : @material.BindGroupLayoutDescriptor
  blending_weight_calculation_bind_group_layout : @material.BindGroupLayoutDescriptor
  shader : String
}

///|
pub struct SmaaNeighborhoodBlendingPipeline {
  postprocess_bind_group_layout : @material.BindGroupLayoutDescriptor
  neighborhood_blending_bind_group_layout : @material.BindGroupLayoutDescriptor
  shader : String
}

///|
pub struct SmaaPipelines {
  edge_detection : SmaaEdgeDetectionPipeline
  blending_weight_calculation : SmaaBlendingWeightCalculationPipeline
  neighborhood_blending : SmaaNeighborhoodBlendingPipeline
}

///|
pub struct SmaaNeighborhoodBlendingPipelineKey {
  texture_format : UInt
  preset : SmaaPreset
} derive(Eq, Debug)

///|
pub fn SmaaNeighborhoodBlendingPipelineKey::new(
  texture_format : UInt,
  preset : SmaaPreset,
) -> SmaaNeighborhoodBlendingPipelineKey {
  SmaaNeighborhoodBlendingPipelineKey::{ texture_format, preset }
}

///|
pub struct ViewSmaaPipelines {
  edge_detection_pipeline_id : @material.CachedRenderPipelineId
  blending_weight_calculation_pipeline_id : @material.CachedRenderPipelineId
  neighborhood_blending_pipeline_id : @material.CachedRenderPipelineId
}

///|
pub fn ViewSmaaPipelines::new(
  edge_detection_pipeline_id : @material.CachedRenderPipelineId,
  blending_weight_calculation_pipeline_id : @material.CachedRenderPipelineId,
  neighborhood_blending_pipeline_id : @material.CachedRenderPipelineId,
) -> ViewSmaaPipelines {
  ViewSmaaPipelines::{
    edge_detection_pipeline_id,
    blending_weight_calculation_pipeline_id,
    neighborhood_blending_pipeline_id,
  }
}

///|
pub fn SmaaRuntimeState::default() -> SmaaRuntimeState {
  SmaaRuntimeState::{
    enabled_camera_count: 0,
    runtime_supported: SMAA_RUNTIME_SUPPORTED,
  }
}

///|
let ecs_key_smaa : @ecs.ComponentKey[Smaa] = @ecs.register_component(
  debug_name="mgstudio_anti_alias::Smaa",
)

///|
let ecs_key_smaa_runtime_state : @ecs.ResourceKey[SmaaRuntimeState] = @ecs.register_resource(
  debug_name="anti_alias.smaa.runtime_state",
)

///|
pub impl @ecs.Component for Smaa with component() {
  ecs_key_smaa
}

///|
pub impl @app.Resource for SmaaRuntimeState with resource() {
  ecs_key_smaa_runtime_state
}

///|
fn smaa_texture_entry() -> @material.BindGroupLayoutEntryBuilder {
  @material.bind_group_layout_entry_builder(
    @render_resource.BindingType::Texture,
  )
}

///|
fn smaa_sampler_entry() -> @material.BindGroupLayoutEntryBuilder {
  @material.bind_group_layout_entry_builder(
    @render_resource.BindingType::Sampler,
  )
}

///|
fn smaa_uniform_entry() -> @material.BindGroupLayoutEntryBuilder {
  @material.bind_group_layout_entry_builder(
    @render_resource.BindingType::Buffer,
  ).visibility(
    (@wgpu.SHADER_STAGE_VERTEX | @wgpu.SHADER_STAGE_FRAGMENT).to_uint(),
  )
}

///|
fn smaa_layout(
  label : String,
  entries : Array[@material.BindGroupLayoutEntryBuilder],
) -> @material.BindGroupLayoutDescriptor {
  @material.BindGroupLayoutDescriptor::new(
    label,
    @material.bind_group_layout_entries_sequential(
      @wgpu.SHADER_STAGE_FRAGMENT.to_uint(),
      entries,
    ).entries(),
  )
}

///|
pub fn init_smaa_pipelines(
  shader? : String = "anti_alias/smaa/smaa.wgsl",
) -> SmaaPipelines {
  let postprocess_bind_group_layout = smaa_layout(
    "SMAA postprocess bind group layout",
    [smaa_texture_entry(), smaa_uniform_entry()],
  )
  let edge_detection_bind_group_layout = smaa_layout(
    "SMAA edge detection bind group layout",
    [smaa_sampler_entry()],
  )
  let blending_weight_calculation_bind_group_layout = smaa_layout(
    "SMAA blending weight calculation bind group layout",
    [
      smaa_texture_entry(),
      smaa_sampler_entry(),
      smaa_texture_entry(),
      smaa_texture_entry(),
    ],
  )
  let neighborhood_blending_bind_group_layout = smaa_layout(
    "SMAA neighborhood blending bind group layout",
    [smaa_texture_entry(), smaa_sampler_entry()],
  )
  SmaaPipelines::{
    edge_detection: SmaaEdgeDetectionPipeline::{
      postprocess_bind_group_layout,
      edge_detection_bind_group_layout,
      shader,
    },
    blending_weight_calculation: SmaaBlendingWeightCalculationPipeline::{
      postprocess_bind_group_layout,
      blending_weight_calculation_bind_group_layout,
      shader,
    },
    neighborhood_blending: SmaaNeighborhoodBlendingPipeline::{
      postprocess_bind_group_layout,
      neighborhood_blending_bind_group_layout,
      shader,
    },
  }
}

///|
fn smaa_vertex_state(
  shader : String,
  shader_defs : Array[@material.ShaderDefVal],
  entry_point : String,
) -> @material.VertexState {
  @material.VertexState::new(Some(shader), shader_defs, Some(entry_point), [])
}

///|
fn smaa_fragment_state(
  shader : String,
  shader_defs : Array[@material.ShaderDefVal],
  entry_point : String,
  format : UInt,
) -> @material.FragmentState {
  @material.FragmentState::new(Some(shader), shader_defs, Some(entry_point), [
    Some(@material.ColorTargetState::new(format, @wgpu.COLOR_WRITE_MASK_ALL)),
  ])
}

///|
fn smaa_depth_stencil_state() -> @material.DepthStencilState {
  @material.DepthStencilState::new(
    @wgpu.TEXTURE_FORMAT_STENCIL8,
    false,
    @wgpu.COMPARE_FUNCTION_ALWAYS,
  )
}

///|
pub fn SmaaEdgeDetectionPipeline::specialize(
  self : SmaaEdgeDetectionPipeline,
  preset : SmaaPreset,
) -> @material.RenderPipelineDescriptor {
  let shader_defs = [
    @material.ShaderDefVal::Flag("SMAA_EDGE_DETECTION"),
    @material.ShaderDefVal::Flag(preset.shader_def()),
  ]
  @material.RenderPipelineDescriptor::default()
  .with_label(Some("SMAA edge detection"))
  .with_layout([
    self.postprocess_bind_group_layout,
    self.edge_detection_bind_group_layout,
  ])
  .with_vertex(
    smaa_vertex_state(self.shader, shader_defs, "edge_detection_vertex_main"),
  )
  .with_fragment(
    Some(
      smaa_fragment_state(
        self.shader,
        shader_defs,
        "luma_edge_detection_fragment_main",
        @wgpu.TEXTURE_FORMAT_RG8_UNORM,
      ),
    ),
  )
  .with_depth_stencil(Some(smaa_depth_stencil_state()))
}

///|
pub fn SmaaBlendingWeightCalculationPipeline::specialize(
  self : SmaaBlendingWeightCalculationPipeline,
  preset : SmaaPreset,
) -> @material.RenderPipelineDescriptor {
  let shader_defs = [
    @material.ShaderDefVal::Flag("SMAA_BLENDING_WEIGHT_CALCULATION"),
    @material.ShaderDefVal::Flag(preset.shader_def()),
  ]
  @material.RenderPipelineDescriptor::default()
  .with_label(Some("SMAA blending weight calculation"))
  .with_layout([
    self.postprocess_bind_group_layout,
    self.blending_weight_calculation_bind_group_layout,
  ])
  .with_vertex(
    smaa_vertex_state(
      self.shader,
      shader_defs,
      "blending_weight_calculation_vertex_main",
    ),
  )
  .with_fragment(
    Some(
      smaa_fragment_state(
        self.shader,
        shader_defs,
        "blending_weight_calculation_fragment_main",
        @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
      ),
    ),
  )
  .with_depth_stencil(Some(smaa_depth_stencil_state()))
}

///|
pub fn SmaaNeighborhoodBlendingPipeline::specialize(
  self : SmaaNeighborhoodBlendingPipeline,
  key : SmaaNeighborhoodBlendingPipelineKey,
) -> @material.RenderPipelineDescriptor {
  let shader_defs = [
    @material.ShaderDefVal::Flag("SMAA_NEIGHBORHOOD_BLENDING"),
    @material.ShaderDefVal::Flag(key.preset.shader_def()),
  ]
  @material.RenderPipelineDescriptor::default()
  .with_label(Some("SMAA neighborhood blending"))
  .with_layout([
    self.postprocess_bind_group_layout,
    self.neighborhood_blending_bind_group_layout,
  ])
  .with_vertex(
    smaa_vertex_state(
      self.shader,
      shader_defs,
      "neighborhood_blending_vertex_main",
    ),
  )
  .with_fragment(
    Some(
      smaa_fragment_state(
        self.shader,
        shader_defs,
        "neighborhood_blending_fragment_main",
        key.texture_format,
      ),
    ),
  )
}

///|
pub impl @app.Plugin for SmaaPlugin with name(_self) {
  SMAA_PLUGIN_NAME
}

///|
pub impl @app.Plugin for SmaaPlugin with build(self, app) {
  register_embedded_wgsl_sources()
  ignore(@asset.embedded_asset(app, SMAA_AREA_LUT_PATH, SMAA_AREA_LUT_PATH))
  ignore(@asset.embedded_asset(app, SMAA_SEARCH_LUT_PATH, SMAA_SEARCH_LUT_PATH))
  smaa_plugin_with(app, self)
}

///|
pub fn smaa_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  smaa_plugin_with(app, SmaaPlugin::default())
}

///|
pub fn smaa_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : SmaaPlugin,
) -> @app.App[@ecs.World] {
  let world = app.world()
  if (try! world.get_resource(ecs_key_smaa_luts)) is None {
    world.insert_resource(
      ecs_key_smaa_luts,
      SmaaLuts::from_asset_server(@asset.AssetServer::new()),
    )
  }
  app
  .init_resource(fn() { SmaaRuntimeState::default() })
  .add_system(smaa_update_runtime_state)
}

///|
fn smaa_camera_component_present(
  world : @ecs.World,
  entity : @core.Entity,
) -> Bool {
  try! world.contains_by_key(entity, @sprite.ecs_key_camera)
}

///|
pub fn smaa_update_runtime_state(world : @ecs.World) -> Unit {
  let mut enabled_camera_count = 0
  world.for_each_component(ecs_key_smaa, fn(entity, _smaa : Smaa) {
    if smaa_camera_component_present(world, entity) {
      enabled_camera_count = enabled_camera_count + 1
    }
  })
  let next = SmaaRuntimeState::{
    enabled_camera_count,
    runtime_supported: SMAA_RUNTIME_SUPPORTED,
  }
  let current : SmaaRuntimeState? = try! world.get_resource(
    ecs_key_smaa_runtime_state,
  )
  match current {
    Some(state) =>
      if state != next {
        world.insert_resource(ecs_key_smaa_runtime_state, next)
      }
    None => world.insert_resource(ecs_key_smaa_runtime_state, next)
  }
}
