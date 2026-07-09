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
  medium : ScatteringMedium,
) -> Array[@math.Vec4] {
  let falloff_resolution = pbr_scattering_medium_sanitize_resolution(
    medium.falloff_resolution,
  )
  let density : Array[@math.Vec4] = []
  for i in 0..<falloff_resolution {
    let falloff = pbr_scattering_medium_falloff_sample(i, falloff_resolution)
    let mut absorption = @math.Vec3::zero()
    for term in medium.terms {
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
    for term in medium.terms {
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
  medium : ScatteringMedium,
) -> Array[@math.Vec4] {
  let falloff_resolution = pbr_scattering_medium_sanitize_resolution(
    medium.falloff_resolution,
  )
  let phase_resolution = pbr_scattering_medium_sanitize_resolution(
    medium.phase_resolution,
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
    for term in medium.terms {
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
  terms : Array[@light.ScatteringTerm]
  falloff_resolution : Int
  phase_resolution : Int
  sampler : ScatteringMediumSampler
  density_lut : Array[@math.Vec4]
  scattering_lut : Array[@math.Vec4]
}

///|
pub fn GpuScatteringMedium::new(
  medium : ScatteringMedium,
  sampler : ScatteringMediumSampler,
) -> GpuScatteringMedium {
  GpuScatteringMedium::{
    terms: medium.terms,
    falloff_resolution: medium.falloff_resolution,
    phase_resolution: medium.phase_resolution,
    density_lut: pbr_scattering_medium_default_density_lut(medium),
    scattering_lut: pbr_scattering_medium_default_scattering_lut(medium),
    sampler,
  }
}

///|
pub fn GpuScatteringMedium::terms(
  self : GpuScatteringMedium,
) -> Array[@light.ScatteringTerm] {
  self.terms
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
fn pbr_scattering_medium_hash_u64(hash : UInt64, value : UInt64) -> UInt64 {
  let mut next = hash
  next = (next ^ (value & 0xFFUL)) * 1099511628211UL
  next = (next ^ ((value >> 8) & 0xFFUL)) * 1099511628211UL
  next = (next ^ ((value >> 16) & 0xFFUL)) * 1099511628211UL
  next = (next ^ ((value >> 24) & 0xFFUL)) * 1099511628211UL
  next = (next ^ ((value >> 32) & 0xFFUL)) * 1099511628211UL
  next = (next ^ ((value >> 40) & 0xFFUL)) * 1099511628211UL
  next = (next ^ ((value >> 48) & 0xFFUL)) * 1099511628211UL
  (next ^ ((value >> 56) & 0xFFUL)) * 1099511628211UL
}

///|
fn pbr_scattering_medium_hash_int(hash : UInt64, value : Int) -> UInt64 {
  pbr_scattering_medium_hash_u64(hash, value.reinterpret_as_uint().to_uint64())
}

///|
fn pbr_scattering_medium_hash_float(hash : UInt64, value : Float) -> UInt64 {
  pbr_scattering_medium_hash_u64(hash, value.reinterpret_as_uint().to_uint64())
}

///|
fn pbr_scattering_medium_hash_vec3(hash : UInt64, value : @math.Vec3) -> UInt64 {
  let next = pbr_scattering_medium_hash_float(hash, value.x)
  let next = pbr_scattering_medium_hash_float(next, value.y)
  pbr_scattering_medium_hash_float(next, value.z)
}

///|
fn pbr_scattering_medium_hash_falloff(
  hash : UInt64,
  falloff : @light.Falloff,
) -> UInt64 {
  match falloff {
    @light.Falloff::Linear => pbr_scattering_medium_hash_u64(hash, 1UL)
    @light.Falloff::Exponential(scale) =>
      pbr_scattering_medium_hash_float(
        pbr_scattering_medium_hash_u64(hash, 2UL),
        scale,
      )
    @light.Falloff::Tent(center, width) => {
      let next = pbr_scattering_medium_hash_float(
        pbr_scattering_medium_hash_u64(hash, 3UL),
        center,
      )
      pbr_scattering_medium_hash_float(next, width)
    }
  }
}

///|
fn pbr_scattering_medium_hash_phase(
  hash : UInt64,
  phase : @light.PhaseFunction,
) -> UInt64 {
  match phase {
    @light.PhaseFunction::Isotropic => pbr_scattering_medium_hash_u64(hash, 1UL)
    @light.PhaseFunction::Rayleigh => pbr_scattering_medium_hash_u64(hash, 2UL)
    @light.PhaseFunction::Mie(asymmetry) =>
      pbr_scattering_medium_hash_float(
        pbr_scattering_medium_hash_u64(hash, 3UL),
        asymmetry,
      )
  }
}

///|
fn pbr_scattering_medium_signature(medium : ScatteringMedium) -> UInt64 {
  let mut hash = 14695981039346656037UL
  hash = pbr_scattering_medium_hash_int(hash, medium.falloff_resolution)
  hash = pbr_scattering_medium_hash_int(hash, medium.phase_resolution)
  hash = pbr_scattering_medium_hash_int(hash, medium.terms.length())
  for term in medium.terms {
    hash = pbr_scattering_medium_hash_vec3(hash, term.absorption)
    hash = pbr_scattering_medium_hash_vec3(hash, term.scattering)
    hash = pbr_scattering_medium_hash_falloff(hash, term.falloff)
    hash = pbr_scattering_medium_hash_phase(hash, term.phase)
  }
  hash
}

///|
priv struct PreparedGpuScatteringMedium {
  signature : UInt64
  density_width : Int
  density_height : Int
  density_bytes : Bytes
  scattering_width : Int
  scattering_height : Int
  scattering_bytes : Bytes
}

///|
let prepared_gpu_scattering_medium_render_asset_keys : @render.RenderAssetResourceKeys[
  PreparedGpuScatteringMedium,
] = @render.register_render_asset_resource_keys(
  "mgstudio_pbr::GpuScatteringMedium",
)

///|
impl @render.RenderAssetResource for PreparedGpuScatteringMedium with fn render_asset_resource_debug_name() {
  "mgstudio_pbr::GpuScatteringMedium"
}

///|
impl @render.RenderAssetResource for PreparedGpuScatteringMedium with fn render_asset_resource_keys() {
  prepared_gpu_scattering_medium_render_asset_keys
}

///|
fn PreparedGpuScatteringMedium::from_medium(
  medium : ScatteringMedium,
  sampler : ScatteringMediumSampler,
) -> PreparedGpuScatteringMedium {
  let gpu_medium = GpuScatteringMedium::new(medium, sampler)
  PreparedGpuScatteringMedium::{
    signature: pbr_scattering_medium_signature(medium),
    density_width: gpu_medium.density_lut_width(),
    density_height: gpu_medium.density_lut_height(),
    density_bytes: gpu_medium.density_lut_rgba32f_bytes(),
    scattering_width: gpu_medium.scattering_lut_width(),
    scattering_height: gpu_medium.scattering_lut_height(),
    scattering_bytes: gpu_medium.scattering_lut_rgba32f_bytes(),
  }
}

///|
fn PreparedGpuScatteringMedium::signature(
  self : PreparedGpuScatteringMedium,
) -> UInt64 {
  self.signature
}

///|
fn PreparedGpuScatteringMedium::density_width(
  self : PreparedGpuScatteringMedium,
) -> Int {
  self.density_width
}

///|
fn PreparedGpuScatteringMedium::density_height(
  self : PreparedGpuScatteringMedium,
) -> Int {
  self.density_height
}

///|
fn PreparedGpuScatteringMedium::density_bytes(
  self : PreparedGpuScatteringMedium,
) -> Bytes {
  self.density_bytes
}

///|
fn PreparedGpuScatteringMedium::scattering_width(
  self : PreparedGpuScatteringMedium,
) -> Int {
  self.scattering_width
}

///|
fn PreparedGpuScatteringMedium::scattering_height(
  self : PreparedGpuScatteringMedium,
) -> Int {
  self.scattering_height
}

///|
fn PreparedGpuScatteringMedium::scattering_bytes(
  self : PreparedGpuScatteringMedium,
) -> Bytes {
  self.scattering_bytes
}

///|
pub fn GpuScatteringMedium::density_lut_width(
  self : GpuScatteringMedium,
) -> Int {
  pbr_scattering_medium_sanitize_resolution(self.falloff_resolution)
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
  pbr_scattering_medium_sanitize_resolution(self.falloff_resolution)
}

///|
pub fn GpuScatteringMedium::scattering_lut_height(
  self : GpuScatteringMedium,
) -> Int {
  pbr_scattering_medium_sanitize_resolution(self.phase_resolution)
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
  let default_gpu_medium = GpuScatteringMedium::new(ScatteringMedium(), sampler)
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
  let next = if app.contains_resource(ecs_key_scattering_medium_plugin_state) {
    app
  } else {
    init_scattering_medium_resources(app.world(), plugin)
    app
  }
  @asset.init_asset(next, fn() { ScatteringMedium::ScatteringMedium() })
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
pub fn pbr_scattering_medium_sampler_default() -> ScatteringMediumSampler {
  ScatteringMediumSampler::ScatteringMediumSampler()
}

///|
pub fn pbr_scattering_medium_gpu_default() -> GpuScatteringMedium {
  GpuScatteringMedium::new(
    ScatteringMedium(),
    ScatteringMediumSampler::ScatteringMediumSampler(),
  )
}

///|
pub fn pbr_scattering_medium_gpu_from_medium(
  medium : ScatteringMedium,
) -> GpuScatteringMedium {
  GpuScatteringMedium::new(
    medium,
    ScatteringMediumSampler::ScatteringMediumSampler(),
  )
}

///|
pub fn pbr_scattering_medium_gpu_with_sampler(
  medium : ScatteringMedium,
  sampler : ScatteringMediumSampler,
) -> GpuScatteringMedium {
  GpuScatteringMedium::new(medium, sampler)
}
