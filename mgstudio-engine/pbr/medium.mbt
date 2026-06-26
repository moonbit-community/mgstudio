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
fn pbr_scattering_medium_sanitize_resolution(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
fn pbr_scattering_medium_signum(value : Float) -> Float {
  if value < 0.0F {
    -1.0F
  } else if value > 0.0F {
    1.0F
  } else {
    0.0F
  }
}

///|
fn pbr_scattering_medium_vec3_mul(
  lhs : @math.Vec3,
  rhs : @math.Vec3,
) -> @math.Vec3 {
  @math.Vec3::new(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z)
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
pub fn ScatteringMediumSampler::ScatteringMediumSampler() -> ScatteringMediumSampler {
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
  ScatteringMediumSampler::ScatteringMediumSampler()
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
pub struct ScatteringMediumRuntime {
  medium : ScatteringMedium
}

///|
pub fn ScatteringMediumRuntime::ScatteringMediumRuntime() -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::{ medium: ScatteringMedium() }
}

///|
pub fn ScatteringMediumRuntime::earth() -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::{ medium: ScatteringMedium::earth(256, 256) }
}

///|
pub fn ScatteringMediumRuntime::from_medium(
  medium : ScatteringMedium,
) -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::{ medium, }
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
pub fn pbr_scattering_medium_default_density_lut(
  runtime : ScatteringMediumRuntime,
) -> Array[@math.Vec4] {
  let falloff_resolution = pbr_scattering_medium_sanitize_resolution(
    runtime.medium.falloff_resolution,
  )
  let density : Array[@math.Vec4] = []
  for i in 0..<falloff_resolution {
    let falloff = pbr_scattering_medium_falloff_sample(i, falloff_resolution)
    let mut absorption = @math.Vec3::zero()
    for term in runtime.medium.terms {
      absorption = absorption.add(
        term.absorption.mul_scalar(term.falloff.sample(falloff)),
      )
    }
    density.push(
      @math.Vec4::new(absorption.x, absorption.y, absorption.z, 0.0F),
    )
  }
  for i in 0..<falloff_resolution {
    let falloff = pbr_scattering_medium_falloff_sample(i, falloff_resolution)
    let mut scattering = @math.Vec3::zero()
    for term in runtime.medium.terms {
      scattering = scattering.add(
        term.scattering.mul_scalar(term.falloff.sample(falloff)),
      )
    }
    density.push(
      @math.Vec4::new(scattering.x, scattering.y, scattering.z, 0.0F),
    )
  }
  density
}

///|
pub fn pbr_scattering_medium_default_scattering_lut(
  runtime : ScatteringMediumRuntime,
) -> Array[@math.Vec4] {
  let falloff_resolution = pbr_scattering_medium_sanitize_resolution(
    runtime.medium.falloff_resolution,
  )
  let phase_resolution = pbr_scattering_medium_sanitize_resolution(
    runtime.medium.phase_resolution,
  )
  let scattering : Array[@math.Vec4] = []
  let phase_mapping_n = 0.5F
  let inv_n = 1.0F / phase_mapping_n
  for raw_i in 0..<(falloff_resolution * phase_resolution) {
    let i = raw_i % phase_resolution
    let j = raw_i / phase_resolution
    let falloff = pbr_scattering_medium_falloff_sample(i, falloff_resolution)
    let phase = pbr_scattering_medium_phase_sample(j, phase_resolution)
    let s = 2.0F * phase - 1.0F
    let neg_l_dot_v = pbr_scattering_medium_signum(s) *
      (1.0F - @math.pow(1.0F - @math.abs(s), inv_n))
    let mut value = @math.Vec3::zero()
    for term in runtime.medium.terms {
      let f = term.falloff.sample(falloff)
      match term.phase.sample(neg_l_dot_v) {
        Some(phase_value) =>
          value = value.add(
            pbr_scattering_medium_vec3_mul(term.scattering, phase_value).mul_scalar(
              f,
            ),
          )
        None => ()
      }
    }
    scattering.push(@math.Vec4::new(value.x, value.y, value.z, 0.0F))
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
fn pbr_scattering_medium_u32le_pack(words : Array[UInt]) -> Bytes {
  Bytes::makei(words.length() * 4, i => {
    let word = words[i / 4]
    let shift = i % 4 * 8
    ((word >> shift) & 0xFFU).reinterpret_as_int().to_byte()
  })
}

///|
fn pbr_scattering_medium_vec4_rgba32f_bytes(
  values : Array[@math.Vec4],
) -> Bytes {
  let words : Array[UInt] = []
  for value in values {
    words.push(value.x.reinterpret_as_uint())
    words.push(value.y.reinterpret_as_uint())
    words.push(value.z.reinterpret_as_uint())
    words.push(value.w.reinterpret_as_uint())
  }
  pbr_scattering_medium_u32le_pack(words)
}

///|
pub fn GpuScatteringMedium::density_lut_width(
  self : GpuScatteringMedium,
) -> Int {
  pbr_scattering_medium_sanitize_resolution(
    self.runtime.medium.falloff_resolution,
  )
}

///|
pub fn GpuScatteringMedium::density_lut_height(
  _self : GpuScatteringMedium,
) -> Int {
  2
}

///|
pub fn GpuScatteringMedium::scattering_lut_width(
  self : GpuScatteringMedium,
) -> Int {
  pbr_scattering_medium_sanitize_resolution(
    self.runtime.medium.falloff_resolution,
  )
}

///|
pub fn GpuScatteringMedium::scattering_lut_height(
  self : GpuScatteringMedium,
) -> Int {
  pbr_scattering_medium_sanitize_resolution(
    self.runtime.medium.phase_resolution,
  )
}

///|
pub fn GpuScatteringMedium::density_lut_rgba32f_bytes(
  self : GpuScatteringMedium,
) -> Bytes {
  pbr_scattering_medium_vec4_rgba32f_bytes(self.density_lut)
}

///|
pub fn GpuScatteringMedium::scattering_lut_rgba32f_bytes(
  self : GpuScatteringMedium,
) -> Bytes {
  pbr_scattering_medium_vec4_rgba32f_bytes(self.scattering_lut)
}

///|
pub struct ScatteringMediumPlugin {
  enabled : Bool
  sampler : ScatteringMediumSampler
}

///|
pub fn ScatteringMediumPlugin::ScatteringMediumPlugin() -> ScatteringMediumPlugin {
  ScatteringMediumPlugin::{
    enabled: true,
    sampler: ScatteringMediumSampler::ScatteringMediumSampler(),
  }
}

///|
pub fn ScatteringMediumPlugin::disabled() -> ScatteringMediumPlugin {
  ScatteringMediumPlugin::{ ..ScatteringMediumPlugin(), enabled: false }
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
  let runtime = ScatteringMediumRuntime::ScatteringMediumRuntime()
  let default_gpu_medium = GpuScatteringMedium::new(runtime, sampler)
  let plugin_state = ScatteringMediumPluginState::{
    enabled: plugin.enabled,
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
  scattering_medium_plugin_with(
    app,
    ScatteringMediumPlugin::ScatteringMediumPlugin(),
  )
}

///|
pub fn scattering_medium_plugin_with(
  app : @app.App[@ecs.World],
  plugin : ScatteringMediumPlugin,
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_key_scattering_medium_plugin_state) {
    app
  } else {
    init_scattering_medium_resources(app.world(), plugin)
    app
  }
}

///|
pub impl @app.Plugin for ScatteringMediumPlugin with fn name(_self) {
  SCATTERING_MEDIUM_PLUGIN_NAME
}

///|
pub impl @app.Plugin for ScatteringMediumPlugin with fn build(self, app) {
  scattering_medium_plugin_with(app, self)
}

///|
pub fn pbr_scattering_medium_default() -> ScatteringMedium {
  ScatteringMedium()
}

///|
pub fn pbr_scattering_medium_earth() -> ScatteringMedium {
  ScatteringMedium::earth(256, 256)
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
  ScatteringMediumRuntime::ScatteringMediumRuntime()
}

///|
pub fn pbr_scattering_medium_runtime_earth() -> ScatteringMediumRuntime {
  ScatteringMediumRuntime::earth()
}

///|
pub fn pbr_scattering_medium_sampler_default() -> ScatteringMediumSampler {
  ScatteringMediumSampler::ScatteringMediumSampler()
}

///|
pub fn pbr_scattering_medium_gpu_default() -> GpuScatteringMedium {
  GpuScatteringMedium::new(
    ScatteringMediumRuntime::ScatteringMediumRuntime(),
    ScatteringMediumSampler::ScatteringMediumSampler(),
  )
}

///|
pub fn pbr_scattering_medium_gpu_from_runtime(
  runtime : ScatteringMediumRuntime,
) -> GpuScatteringMedium {
  GpuScatteringMedium::new(
    runtime,
    ScatteringMediumSampler::ScatteringMediumSampler(),
  )
}

///|
pub fn pbr_scattering_medium_gpu_with_sampler(
  runtime : ScatteringMediumRuntime,
  sampler : ScatteringMediumSampler,
) -> GpuScatteringMedium {
  GpuScatteringMedium::new(runtime, sampler)
}
