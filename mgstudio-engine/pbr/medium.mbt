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
// Bevy source: `bevy/crates/bevy_pbr/src/medium.rs`.

///|
const SCATTERING_MEDIUM_PLUGIN_NAME : String = "mgstudio.pbr.ScatteringMediumPlugin"

///|
pub type ScatteringMedium = @light.ScatteringMedium

///|
fn pbr_scattering_medium_sanitize_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn pbr_scattering_medium_sanitize_resolution(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
fn pbr_scattering_medium_clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
pub struct ScatteringMediumSampler {
  address_mode_u : @asset.ImageAddressMode
  address_mode_v : @asset.ImageAddressMode
  address_mode_w : @asset.ImageAddressMode
  mag_filter : @asset.ImageFilterMode
  min_filter : @asset.ImageFilterMode
  mipmap_filter : @asset.ImageFilterMode
}

///|
pub fn ScatteringMediumSampler::default() -> ScatteringMediumSampler {
  ScatteringMediumSampler::{
    address_mode_u: @asset.ImageAddressMode::ClampToEdge,
    address_mode_v: @asset.ImageAddressMode::ClampToEdge,
    address_mode_w: @asset.ImageAddressMode::ClampToEdge,
    mag_filter: @asset.ImageFilterMode::Linear,
    min_filter: @asset.ImageFilterMode::Linear,
    mipmap_filter: @asset.ImageFilterMode::Linear,
  }
}

///|
pub fn ScatteringMediumSampler::linear_clamp() -> ScatteringMediumSampler {
  ScatteringMediumSampler::default()
}

///|
pub fn ScatteringMediumSampler::with_address_mode(
  self : ScatteringMediumSampler,
  address_mode : @asset.ImageAddressMode,
) -> ScatteringMediumSampler {
  ScatteringMediumSampler::{
    ..self,
    address_mode_u: address_mode,
    address_mode_v: address_mode,
    address_mode_w: address_mode,
  }
}

///|
pub fn ScatteringMediumSampler::with_filter(
  self : ScatteringMediumSampler,
  filter : @asset.ImageFilterMode,
) -> ScatteringMediumSampler {
  ScatteringMediumSampler::{
    ..self,
    mag_filter: filter,
    min_filter: filter,
    mipmap_filter: filter,
  }
}

///|
pub fn ScatteringMediumSampler::is_linear_clamp(
  self : ScatteringMediumSampler,
) -> Bool {
  self.address_mode_u == @asset.ImageAddressMode::ClampToEdge &&
  self.address_mode_v == @asset.ImageAddressMode::ClampToEdge &&
  self.address_mode_w == @asset.ImageAddressMode::ClampToEdge &&
  self.mag_filter == @asset.ImageFilterMode::Linear &&
  self.min_filter == @asset.ImageFilterMode::Linear &&
  self.mipmap_filter == @asset.ImageFilterMode::Linear
}

///|
pub struct ScatteringMediumLutConfig {
  falloff_resolution : Int
  phase_resolution : Int
}

///|
pub fn ScatteringMediumLutConfig::default() -> ScatteringMediumLutConfig {
  ScatteringMediumLutConfig::{ falloff_resolution: 128, phase_resolution: 64 }
}

///|
pub fn ScatteringMediumLutConfig::with_falloff_resolution(
  self : ScatteringMediumLutConfig,
  falloff_resolution : Int,
) -> ScatteringMediumLutConfig {
  ScatteringMediumLutConfig::{
    ..self,
    falloff_resolution: pbr_scattering_medium_sanitize_resolution(
      falloff_resolution,
    ),
  }
}

///|
pub fn ScatteringMediumLutConfig::with_phase_resolution(
  self : ScatteringMediumLutConfig,
  phase_resolution : Int,
) -> ScatteringMediumLutConfig {
  ScatteringMediumLutConfig::{
    ..self,
    phase_resolution: pbr_scattering_medium_sanitize_resolution(
      phase_resolution,
    ),
  }
}

///|
pub struct ScatteringMediumRuntime {
  medium : ScatteringMedium
  density_multiplier : Float
  lut_config : ScatteringMediumLutConfig
}

///|
pub fn ScatteringMediumRuntime::default() -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::{
    medium: ScatteringMedium::default(),
    density_multiplier: 1.0F,
    lut_config: ScatteringMediumLutConfig::default(),
  }
}

///|
pub fn ScatteringMediumRuntime::earthlike() -> ScatteringMediumRuntime {
  let default_runtime = ScatteringMediumRuntime::default()
  ScatteringMediumRuntime::{
    medium: ScatteringMedium::earthlike(),
    density_multiplier: default_runtime.density_multiplier,
    lut_config: default_runtime.lut_config,
  }
}

///|
pub fn ScatteringMediumRuntime::from_medium(
  medium : ScatteringMedium,
) -> ScatteringMediumRuntime {
  let default_runtime = ScatteringMediumRuntime::default()
  ScatteringMediumRuntime::{
    medium,
    density_multiplier: default_runtime.density_multiplier,
    lut_config: default_runtime.lut_config,
  }
}

///|
pub fn ScatteringMediumRuntime::with_density_multiplier(
  self : ScatteringMediumRuntime,
  density_multiplier : Float,
) -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::{
    ..self,
    density_multiplier: pbr_scattering_medium_sanitize_non_negative(
      density_multiplier,
    ),
  }
}

///|
pub fn ScatteringMediumRuntime::with_lut_config(
  self : ScatteringMediumRuntime,
  lut_config : ScatteringMediumLutConfig,
) -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::{ ..self, lut_config, }
}

///|
fn pbr_scattering_medium_falloff_sample(
  falloff_index : Int,
  falloff_resolution : Int,
) -> Float {
  (Float::from_int(falloff_index) + 0.5F) / Float::from_int(falloff_resolution)
}

///|
fn pbr_scattering_medium_phase_sample(
  phase_index : Int,
  phase_resolution : Int,
) -> Float {
  (Float::from_int(phase_index) + 0.5F) / Float::from_int(phase_resolution)
}

///|
fn pbr_scattering_medium_phase_response(neg_l_dot_v : Float) -> Float {
  pbr_scattering_medium_clamp01((neg_l_dot_v + 1.0F) * 0.5F)
}

///|
fn pbr_scattering_medium_sample_density(
  runtime : ScatteringMediumRuntime,
  falloff : Float,
) -> Float {
  runtime.density_multiplier * pbr_scattering_medium_clamp01(falloff)
}

///|
pub fn pbr_scattering_medium_default_density_lut(
  runtime : ScatteringMediumRuntime,
) -> Array[@math.Vec4] {
  let falloff_resolution = pbr_scattering_medium_sanitize_resolution(
    runtime.lut_config.falloff_resolution,
  )
  let density : Array[@math.Vec4] = []
  for i in 0..<falloff_resolution {
    let falloff = pbr_scattering_medium_falloff_sample(i, falloff_resolution)
    let value = pbr_scattering_medium_sample_density(runtime, falloff)
    density.push(@math.Vec4::new(value, value, value, 1.0F))
  }
  for i in 0..<falloff_resolution {
    let falloff = pbr_scattering_medium_falloff_sample(i, falloff_resolution)
    let value = pbr_scattering_medium_sample_density(runtime, falloff)
    density.push(@math.Vec4::new(value, value, value, 1.0F))
  }
  density
}

///|
pub fn pbr_scattering_medium_default_scattering_lut(
  runtime : ScatteringMediumRuntime,
) -> Array[@math.Vec4] {
  let falloff_resolution = pbr_scattering_medium_sanitize_resolution(
    runtime.lut_config.falloff_resolution,
  )
  let phase_resolution = pbr_scattering_medium_sanitize_resolution(
    runtime.lut_config.phase_resolution,
  )
  let scattering : Array[@math.Vec4] = []
  for raw_i in 0..<(falloff_resolution * phase_resolution) {
    let i = raw_i % phase_resolution
    let j = raw_i / phase_resolution
    let falloff = pbr_scattering_medium_falloff_sample(i, falloff_resolution)
    let phase = pbr_scattering_medium_phase_sample(j, phase_resolution)
    let neg_l_dot_v = phase * 2.0F - 1.0F
    let value = pbr_scattering_medium_sample_density(runtime, falloff) *
      pbr_scattering_medium_phase_response(neg_l_dot_v)
    scattering.push(@math.Vec4::new(value, value, value, phase))
  }
  scattering
}

///|
pub struct GpuScatteringMedium {
  runtime : ScatteringMediumRuntime
  sampler : ScatteringMediumSampler
  density_lut : Array[@math.Vec4]
  scattering_lut : Array[@math.Vec4]
}

///|
pub fn GpuScatteringMedium::new(
  runtime : ScatteringMediumRuntime,
  sampler : ScatteringMediumSampler,
) -> GpuScatteringMedium {
  GpuScatteringMedium::{
    density_lut: pbr_scattering_medium_default_density_lut(runtime),
    scattering_lut: pbr_scattering_medium_default_scattering_lut(runtime),
    runtime,
    sampler,
  }
}

///|
pub fn GpuScatteringMedium::runtime(
  self : GpuScatteringMedium,
) -> ScatteringMediumRuntime {
  self.runtime
}

///|
pub fn GpuScatteringMedium::sampler(
  self : GpuScatteringMedium,
) -> ScatteringMediumSampler {
  self.sampler
}

///|
pub fn GpuScatteringMedium::density_lut_len(self : GpuScatteringMedium) -> Int {
  self.density_lut.length()
}

///|
pub fn GpuScatteringMedium::scattering_lut_len(
  self : GpuScatteringMedium,
) -> Int {
  self.scattering_lut.length()
}

///|
pub fn GpuScatteringMedium::density_lut(
  self : GpuScatteringMedium,
) -> Array[@math.Vec4] {
  self.density_lut
}

///|
pub fn GpuScatteringMedium::scattering_lut(
  self : GpuScatteringMedium,
) -> Array[@math.Vec4] {
  self.scattering_lut
}

///|
pub struct ScatteringMediumPlugin {
  enabled : Bool
  runtime_config : ScatteringMediumLutConfig
  sampler : ScatteringMediumSampler
}

///|
pub fn ScatteringMediumPlugin::default() -> ScatteringMediumPlugin {
  ScatteringMediumPlugin::{
    enabled: true,
    runtime_config: ScatteringMediumLutConfig::default(),
    sampler: ScatteringMediumSampler::default(),
  }
}

///|
pub fn ScatteringMediumPlugin::disabled() -> ScatteringMediumPlugin {
  ScatteringMediumPlugin::{
    ..ScatteringMediumPlugin::default(),
    enabled: false,
  }
}

///|
pub fn ScatteringMediumPlugin::with_lut_config(
  self : ScatteringMediumPlugin,
  runtime_config : ScatteringMediumLutConfig,
) -> ScatteringMediumPlugin {
  ScatteringMediumPlugin::{ ..self, runtime_config, }
}

///|
pub fn ScatteringMediumPlugin::with_sampler(
  self : ScatteringMediumPlugin,
  sampler : ScatteringMediumSampler,
) -> ScatteringMediumPlugin {
  ScatteringMediumPlugin::{ ..self, sampler, }
}

///|
pub struct ScatteringMediumPluginState {
  enabled : Bool
  runtime_config : ScatteringMediumLutConfig
  sampler : ScatteringMediumSampler
  default_gpu_medium : GpuScatteringMedium
}

///|
fn scattering_medium_plugin_state_debug_name() -> String {
  "mgstudio_pbr::ScatteringMediumPluginState"
}

///|
pub let ecs_key_scattering_medium_plugin_state : @ecs.ResourceKey[
  ScatteringMediumPluginState,
] = @ecs.register_resource(
  debug_name=scattering_medium_plugin_state_debug_name(),
)

///|
pub let ecs_key_scattering_medium_sampler : @ecs.ResourceKey[
  ScatteringMediumSampler,
] = @ecs.register_resource(debug_name="mgstudio_pbr::ScatteringMediumSampler")

///|
fn init_scattering_medium_resources(
  world : @ecs.World,
  plugin : ScatteringMediumPlugin,
) -> Unit {
  let sampler = plugin.sampler
  let runtime = ScatteringMediumRuntime::{
    ..ScatteringMediumRuntime::default(),
    lut_config: plugin.runtime_config,
  }
  let default_gpu_medium = GpuScatteringMedium::new(runtime, sampler)
  let plugin_state = ScatteringMediumPluginState::{
    enabled: plugin.enabled,
    runtime_config: plugin.runtime_config,
    sampler,
    default_gpu_medium,
  }
  world.insert_resource(ecs_key_scattering_medium_sampler, sampler)
  world.insert_resource(ecs_key_scattering_medium_plugin_state, plugin_state)
}

///|
pub fn scattering_medium_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  scattering_medium_plugin_with(app, ScatteringMediumPlugin::default())
}

///|
pub fn scattering_medium_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ScatteringMediumPlugin,
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_key_scattering_medium_plugin_state) {
    app
  } else {
    app.add_startup_system(fn(world : @ecs.World) {
      init_scattering_medium_resources(world, plugin)
    })
  }
}

///|
pub impl @app.Plugin for ScatteringMediumPlugin with name(_self) {
  SCATTERING_MEDIUM_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ScatteringMediumPlugin with build(self, app) {
  scattering_medium_plugin_with(app, self)
}

///|
pub fn pbr_scattering_medium_default() -> ScatteringMedium {
  ScatteringMedium::default()
}

///|
pub fn pbr_scattering_medium_earthlike() -> ScatteringMedium {
  ScatteringMedium::earthlike()
}

///|
pub fn pbr_scattering_medium_with_density_multiplier(
  medium : ScatteringMedium,
  density_multiplier : Float,
) -> ScatteringMedium {
  medium.with_density_multiplier(density_multiplier)
}

///|
pub fn pbr_scattering_medium_runtime_default() -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::default()
}

///|
pub fn pbr_scattering_medium_runtime_earthlike() -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::earthlike()
}

///|
pub fn pbr_scattering_medium_runtime_with_density_multiplier(
  runtime : ScatteringMediumRuntime,
  density_multiplier : Float,
) -> ScatteringMediumRuntime {
  runtime.with_density_multiplier(density_multiplier)
}

///|
pub fn pbr_scattering_medium_runtime_with_lut_config(
  runtime : ScatteringMediumRuntime,
  lut_config : ScatteringMediumLutConfig,
) -> ScatteringMediumRuntime {
  runtime.with_lut_config(lut_config)
}

///|
pub fn pbr_scattering_medium_lut_config_default() -> ScatteringMediumLutConfig {
  ScatteringMediumLutConfig::default()
}

///|
pub fn pbr_scattering_medium_sampler_default() -> ScatteringMediumSampler {
  ScatteringMediumSampler::default()
}

///|
pub fn pbr_scattering_medium_gpu_default() -> GpuScatteringMedium {
  GpuScatteringMedium::new(
    ScatteringMediumRuntime::default(),
    ScatteringMediumSampler::default(),
  )
}

///|
pub fn pbr_scattering_medium_gpu_from_runtime(
  runtime : ScatteringMediumRuntime,
) -> GpuScatteringMedium {
  GpuScatteringMedium::new(runtime, ScatteringMediumSampler::default())
}

///|
pub fn pbr_scattering_medium_gpu_with_sampler(
  runtime : ScatteringMediumRuntime,
  sampler : ScatteringMediumSampler,
) -> GpuScatteringMedium {
  GpuScatteringMedium::new(runtime, sampler)
}
