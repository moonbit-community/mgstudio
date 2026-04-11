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
/// Anti-aliasing API boundary aligned with Bevy's `bevy_anti_alias` crate.
/// Surface re-exports are sourced from `core_pipeline` and `post_process`.
/// Current surface maps to available MSAA/FXAA/TAA components.

///|
pub struct AntiAliasPlugin {}

///|
pub fn AntiAliasPlugin::default() -> AntiAliasPlugin {
  AntiAliasPlugin::{  }
}

///|
pub const ANTI_ALIAS_PLUGIN_ID : String = "bevy_anti_alias::AntiAliasPlugin"

///|
pub impl @app.PluginReplacement for AntiAliasPlugin with replacement_id(_self) {
  ANTI_ALIAS_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for AntiAliasPlugin with world_plugin(self) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    anti_alias_plugin_with(app, self)
  }
}

///|
pub fn anti_alias_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  anti_alias_plugin_with(app, AntiAliasPlugin::default())
}

///|
pub fn anti_alias_plugin_with(
  app : @app.App[@ecs.World],
  _plugin : AntiAliasPlugin,
) -> @app.App[@ecs.World] {
  app
  .add_plugin(@fxaa.fxaa_plugin)
  .add_plugin(@smaa.smaa_plugin)
  .add_plugin(@taa.temporal_anti_alias_plugin)
  .add_plugin(@cas.cas_plugin)
  .add_plugin(@dlss.dlss_plugin)
}

///|
pub type Msaa = @core_pipeline.Msaa

///|
pub type Fxaa = @post_process.Fxaa

///|
pub type FxaaSensitivity = @post_process.FxaaSensitivity

///|
pub type TemporalAntiAliasing = @post_process.TemporalAntiAliasing

///|
pub type TemporalJitter = @post_process.TemporalJitter

///|
pub type Smaa = @smaa.Smaa

///|
pub type SmaaPreset = @smaa.SmaaPreset

///|
pub type ContrastAdaptiveSharpening = @cas.ContrastAdaptiveSharpening

///|
pub type DenoiseCas = @cas.DenoiseCas

///|
pub type CasUniform = @cas.CasUniform

///|
pub type DlssPerfQualityMode = @dlss.DlssPerfQualityMode

///|
pub type DlssProjectId = @dlss.DlssProjectId

///|
pub type Dlss = @dlss.Dlss

///|
pub const SMAA_RUNTIME_SUPPORTED : Bool = @smaa.SMAA_RUNTIME_SUPPORTED

///|
pub const CAS_RUNTIME_SUPPORTED : Bool = @cas.CAS_RUNTIME_SUPPORTED

///|
pub const DLSS_RUNTIME_SUPPORTED : Bool = @dlss.DLSS_RUNTIME_SUPPORTED

///|
pub type FxaaPlugin = @fxaa.FxaaPlugin

///|
pub type SmaaPlugin = @smaa.SmaaPlugin

///|
pub type TemporalAntiAliasPlugin = @taa.TemporalAntiAliasPlugin

///|
pub type CasPlugin = @cas.CasPlugin

///|
pub type DlssPlugin = @dlss.DlssPlugin

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @core_pipeline.ecs_key_msaa

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @post_process.ecs_key_fxaa

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @post_process.ecs_key_temporal_anti_aliasing

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @post_process.ecs_key_temporal_jitter

///|
pub let ecs_key_smaa : @ecs.ComponentKey[Smaa] = @smaa.Smaa::component()

///|
pub let ecs_key_contrast_adaptive_sharpening : @ecs.ComponentKey[
  ContrastAdaptiveSharpening,
] = @cas.ContrastAdaptiveSharpening::component()

///|
pub let ecs_key_denoise_cas : @ecs.ComponentKey[DenoiseCas] = @cas.DenoiseCas::component()

///|
pub let ecs_key_cas_uniform : @ecs.ComponentKey[CasUniform] = @cas.CasUniform::component()
