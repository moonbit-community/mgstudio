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
// Bevy source: `bevy/crates/bevy_core_pipeline/src/tonemapping/mod.rs`.
// Tonemapping plugin owner surface.

///|
const TONEMAPPING_PLUGIN_NAME : String = "mgstudio.core_pipeline.tonemapping.TonemappingPlugin"

///|
pub struct TonemappingPlugin {}

///|
pub fn TonemappingPlugin::default() -> TonemappingPlugin {
  TonemappingPlugin::{  }
}

///|
pub type Tonemapping = @post_process.Tonemapping

///|
pub type DebandDither = @post_process.DebandDither

///|
pub let ecs_key_tonemapping : @ecs.ComponentKey[Tonemapping] = @post_process.ecs_key_tonemapping

///|
pub let ecs_key_deband_dither : @ecs.ComponentKey[DebandDither] = @post_process.ecs_key_deband_dither

///|
const TONEMAPPING_LUT_BLENDER_FILMIC_PATH : String = "textures/tonemapping/Blender_-11_12.ktx2"

///|
const TONEMAPPING_LUT_AGX_PATH : String = "textures/tonemapping/AgX-default_contrast.ktx2"

///|
const TONEMAPPING_LUT_TONY_MC_MAPFACE_PATH : String = "textures/tonemapping/tony_mc_mapface.ktx2"

///|
pub struct TonemappingLuts {
  blender_filmic : @asset.Handle[@asset.Image]
  agx : @asset.Handle[@asset.Image]
  tony_mc_mapface : @asset.Handle[@asset.Image]
}

///|
pub fn TonemappingLuts::from_asset_server(
  asset_server : @asset.AssetServer,
) -> TonemappingLuts {
  TonemappingLuts::{
    blender_filmic: asset_server.load(TONEMAPPING_LUT_BLENDER_FILMIC_PATH),
    agx: asset_server.load(TONEMAPPING_LUT_AGX_PATH),
    tony_mc_mapface: asset_server.load(TONEMAPPING_LUT_TONY_MC_MAPFACE_PATH),
  }
}

///|
pub let ecs_key_tonemapping_luts : @ecs.ResourceKey[TonemappingLuts] = @ecs.register_resource(
  debug_name="mgstudio_core_pipeline::TonemappingLuts",
)

///|
pub impl @app.Resource for TonemappingLuts with resource() {
  ecs_key_tonemapping_luts
}

///|
pub fn tonemapping_luts_from_world_or_init(
  world : @ecs.World,
) -> TonemappingLuts {
  match (try! world.get_resource(ecs_key_tonemapping_luts)) {
    Some(luts) => luts
    None => {
      let luts = TonemappingLuts::from_asset_server(@asset.AssetServer::new())
      world.insert_resource(ecs_key_tonemapping_luts, luts)
      luts
    }
  }
}

///|
fn tonemapping_ensure_luts_startup(world : @ecs.World) -> Unit {
  tonemapping_luts_from_world_or_init(world) |> ignore
}

///|
pub fn tonemapping_is_enabled(tonemapping : Tonemapping) -> Bool {
  tonemapping != Tonemapping::None
}

///|
pub struct TonemappingPipelineKeyFlags {
  hue_rotate : Bool
  white_balance : Bool
  sectional_color_grading : Bool
} derive(Eq, Debug)

///|
pub fn TonemappingPipelineKeyFlags::default() -> TonemappingPipelineKeyFlags {
  TonemappingPipelineKeyFlags::{
    hue_rotate: false,
    white_balance: false,
    sectional_color_grading: false,
  }
}

///|
pub fn TonemappingPipelineKeyFlags::new(
  hue_rotate? : Bool = false,
  white_balance? : Bool = false,
  sectional_color_grading? : Bool = false,
) -> TonemappingPipelineKeyFlags {
  TonemappingPipelineKeyFlags::{
    hue_rotate,
    white_balance,
    sectional_color_grading,
  }
}

///|
pub struct TonemappingPipelineKey {
  deband_dither : DebandDither
  tonemapping : Tonemapping
  flags : TonemappingPipelineKeyFlags
} derive(Eq, Debug)

///|
pub fn TonemappingPipelineKey::new(
  deband_dither? : DebandDither = DebandDither::default(),
  tonemapping? : Tonemapping = Tonemapping::default(),
  flags? : TonemappingPipelineKeyFlags = TonemappingPipelineKeyFlags::default(),
) -> TonemappingPipelineKey {
  TonemappingPipelineKey::{ deband_dither, tonemapping, flags }
}

///|
pub fn TonemappingPipelineKey::default() -> TonemappingPipelineKey {
  TonemappingPipelineKey::new()
}

///|
pub fn tonemapping_pipeline_key_shader_defs(
  key : TonemappingPipelineKey,
) -> Array[String] {
  let shader_defs : Array[String] = []
  shader_defs.push("TONEMAPPING_LUT_TEXTURE_BINDING_INDEX=3")
  shader_defs.push("TONEMAPPING_LUT_SAMPLER_BINDING_INDEX=4")

  if key.deband_dither == DebandDither::Enabled {
    shader_defs.push("DEBAND_DITHER")
  }
  if key.flags.hue_rotate {
    shader_defs.push("HUE_ROTATE")
  }
  if key.flags.white_balance {
    shader_defs.push("WHITE_BALANCE")
  }
  if key.flags.sectional_color_grading {
    shader_defs.push("SECTIONAL_COLOR_GRADING")
  }

  match key.tonemapping {
    None => shader_defs.push("TONEMAP_METHOD_NONE")
    Reinhard => shader_defs.push("TONEMAP_METHOD_REINHARD")
    ReinhardLuminance => shader_defs.push("TONEMAP_METHOD_REINHARD_LUMINANCE")
    AcesFitted => shader_defs.push("TONEMAP_METHOD_ACES_FITTED")
    AgX => shader_defs.push("TONEMAP_METHOD_AGX")
    SomewhatBoringDisplayTransform =>
      shader_defs.push("TONEMAP_METHOD_SOMEWHAT_BORING_DISPLAY_TRANSFORM")
    TonyMcMapface => shader_defs.push("TONEMAP_METHOD_TONY_MC_MAPFACE")
    BlenderFilmic => shader_defs.push("TONEMAP_METHOD_BLENDER_FILMIC")
  }
  shader_defs
}

///|
pub fn tonemapping_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  tonemapping_plugin_with(app, TonemappingPlugin::default())
}

///|
pub impl @app.PluginReplacement for TonemappingPlugin with plugin_name(_self) {
  TONEMAPPING_PLUGIN_NAME
}

///|
pub impl @app.PluginReplacement for TonemappingPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    tonemapping_plugin_with(app, self)
  }
}

///|
pub fn tonemapping_plugin_with(
  app : @app.App[@ecs.World],
  plugin : TonemappingPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app
  .init_resource(fn() { TonemappingPipelineKey::default() })
  .add_systems(@app.Startup, @app.system(tonemapping_ensure_luts_startup))
}

///|
pub let ecs_key_tonemapping_pipeline_key : @ecs.ResourceKey[
  TonemappingPipelineKey,
] = @ecs.register_resource(debug_name="core_pipeline.tonemapping.pipeline_key")

///|
pub impl @app.Resource for TonemappingPipelineKey with resource() {
  ecs_key_tonemapping_pipeline_key
}
