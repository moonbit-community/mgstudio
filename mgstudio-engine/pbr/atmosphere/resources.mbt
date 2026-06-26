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
// Bevy source: `bevy/crates/bevy_pbr/src/atmosphere/resources.rs`.

///|
pub type AtmosphereMode = @light.AtmosphereMode

///|
pub type AtmosphereSettings = @light.AtmosphereSettings

///|
pub struct GpuAtmosphereSettings {
  transmittance_lut_size : @math.UVec2
  multiscattering_lut_size : @math.UVec2
  sky_view_lut_size : @math.UVec2
  aerial_view_lut_size : (@math.UVec2, Int)
  transmittance_lut_samples : Int
  multiscattering_lut_dirs : Int
  multiscattering_lut_samples : Int
  sky_view_lut_samples : Int
  aerial_view_lut_samples : Int
  aerial_view_lut_max_distance : Float
  sky_max_samples : Int
  rendering_method : AtmosphereMode
}

///|
pub struct GpuAtmosphere {
  ground_albedo : @math.Vec3
  inner_radius : Float
  outer_radius : Float
  world_to_atmosphere : @math.Affine3
}

///|
pub fn GpuAtmosphere::GpuAtmosphere() -> GpuAtmosphere {
  GpuAtmosphere::{
    ground_albedo: @math.Vec3::zero(),
    inner_radius: 0.0F,
    outer_radius: 0.0F,
    world_to_atmosphere: @math.Affine3::identity(),
  }
}

///|
pub fn pbr_gpu_atmosphere(
  atmosphere : Atmosphere,
  world_to_atmosphere : @math.Affine3,
) -> GpuAtmosphere {
  GpuAtmosphere::{
    ground_albedo: atmosphere.ground_albedo,
    inner_radius: atmosphere.inner_radius,
    outer_radius: atmosphere.outer_radius,
    world_to_atmosphere,
  }
}

///|
pub fn GpuAtmosphereSettings::GpuAtmosphereSettings() -> GpuAtmosphereSettings {
  GpuAtmosphereSettings::{
    transmittance_lut_size: @math.UVec2::new(256, 128),
    multiscattering_lut_size: @math.UVec2::new(32, 32),
    sky_view_lut_size: @math.UVec2::new(400, 200),
    aerial_view_lut_size: (@math.UVec2::new(32, 32), 32),
    transmittance_lut_samples: 40,
    multiscattering_lut_dirs: 64,
    multiscattering_lut_samples: 20,
    sky_view_lut_samples: 16,
    aerial_view_lut_samples: 10,
    aerial_view_lut_max_distance: 32_000.0F,
    sky_max_samples: 16,
    rendering_method: AtmosphereMode::LookupTexture,
  }
}

///|
pub(all) enum AtmosphereTextureDimension {
  D2
  D3
} derive(Eq, Debug)

///|
pub(all) enum AtmosphereTextureFormat {
  Rgba16Float
} derive(Eq, Debug)

///|
pub struct AtmosphereTextureDescriptor {
  width : Int
  height : Int
  depth_or_array_layers : Int
  dimension : AtmosphereTextureDimension
  format : AtmosphereTextureFormat
  storage_binding : Bool
  texture_binding : Bool
}

///|
pub fn AtmosphereTextureDescriptor::new(
  width : Int,
  height : Int,
  depth_or_array_layers : Int,
  dimension : AtmosphereTextureDimension,
) -> AtmosphereTextureDescriptor {
  AtmosphereTextureDescriptor::{
    width: if width <= 0 {
      1
    } else {
      width
    },
    height: if height <= 0 {
      1
    } else {
      height
    },
    depth_or_array_layers: if depth_or_array_layers <= 0 {
      1
    } else {
      depth_or_array_layers
    },
    dimension,
    format: AtmosphereTextureFormat::Rgba16Float,
    storage_binding: true,
    texture_binding: true,
  }
}

///|
pub struct AtmosphereTextures {
  transmittance_lut : AtmosphereTextureDescriptor
  multiscattering_lut : AtmosphereTextureDescriptor
  sky_view_lut : AtmosphereTextureDescriptor
  aerial_view_lut : AtmosphereTextureDescriptor
}

///|
pub fn AtmosphereTextures::from_settings(
  settings : GpuAtmosphereSettings,
) -> AtmosphereTextures {
  AtmosphereTextures::{
    transmittance_lut: AtmosphereTextureDescriptor::new(
      settings.transmittance_lut_size.x,
      settings.transmittance_lut_size.y,
      1,
      AtmosphereTextureDimension::D2,
    ),
    multiscattering_lut: AtmosphereTextureDescriptor::new(
      settings.multiscattering_lut_size.x,
      settings.multiscattering_lut_size.y,
      1,
      AtmosphereTextureDimension::D2,
    ),
    sky_view_lut: AtmosphereTextureDescriptor::new(
      settings.sky_view_lut_size.x,
      settings.sky_view_lut_size.y,
      1,
      AtmosphereTextureDimension::D2,
    ),
    aerial_view_lut: AtmosphereTextureDescriptor::new(
      settings.aerial_view_lut_size.0.x,
      settings.aerial_view_lut_size.0.y,
      settings.aerial_view_lut_size.1,
      AtmosphereTextureDimension::D3,
    ),
  }
}

///|
pub struct AtmosphereSampler {
  filtering : Bool
}

///|
pub fn AtmosphereSampler::AtmosphereSampler() -> AtmosphereSampler {
  AtmosphereSampler::{ filtering: true }
}

///|
pub struct AtmosphereBindGroupLayouts {
  transmittance_lut : Bool
  multiscattering_lut : Bool
  sky_view_lut : Bool
  aerial_view_lut : Bool
}

///|
pub fn AtmosphereBindGroupLayouts::AtmosphereBindGroupLayouts() -> AtmosphereBindGroupLayouts {
  AtmosphereBindGroupLayouts::{
    transmittance_lut: true,
    multiscattering_lut: true,
    sky_view_lut: true,
    aerial_view_lut: true,
  }
}

///|
pub struct RenderSkyBindGroupLayouts {
  render_sky : Bool
}

///|
pub fn RenderSkyBindGroupLayouts::RenderSkyBindGroupLayouts() -> RenderSkyBindGroupLayouts {
  RenderSkyBindGroupLayouts::{ render_sky: true }
}

///|
pub struct AtmosphereLutPipelines {
  transmittance_lut : Bool
  multiscattering_lut : Bool
  sky_view_lut : Bool
  aerial_view_lut : Bool
}

///|
pub fn AtmosphereLutPipelines::AtmosphereLutPipelines() -> AtmosphereLutPipelines {
  AtmosphereLutPipelines::{
    transmittance_lut: true,
    multiscattering_lut: true,
    sky_view_lut: true,
    aerial_view_lut: true,
  }
}

///|
pub struct AtmosphereTransform {
  world_from_atmosphere : @math.Affine3
  atmosphere_from_world : @math.Affine3
}

///|
pub fn AtmosphereTransform::identity() -> AtmosphereTransform {
  AtmosphereTransform::{
    world_from_atmosphere: @math.Affine3::identity(),
    atmosphere_from_world: @math.Affine3::identity(),
  }
}

///|
pub struct AtmosphereTransforms {
  uniforms : Array[AtmosphereTransform]
}

///|
pub fn AtmosphereTransforms::AtmosphereTransforms() -> AtmosphereTransforms {
  AtmosphereTransforms::{ uniforms: [] }
}

///|
pub struct AtmosphereBindGroups {
  transmittance_lut : Bool
  multiscattering_lut : Bool
  sky_view_lut : Bool
  aerial_view_lut : Bool
  render_sky : Bool
}

///|
pub fn AtmosphereBindGroups::AtmosphereBindGroups() -> AtmosphereBindGroups {
  AtmosphereBindGroups::{
    transmittance_lut: true,
    multiscattering_lut: true,
    sky_view_lut: true,
    aerial_view_lut: true,
    render_sky: true,
  }
}

///|
pub struct AtmosphereBuffer {
  value : GpuAtmosphere
}

///|
pub fn AtmosphereBuffer::AtmosphereBuffer() -> AtmosphereBuffer {
  AtmosphereBuffer::{ value: GpuAtmosphere::GpuAtmosphere() }
}

///|
pub fn pbr_gpu_atmosphere_settings(
  settings : AtmosphereSettings,
) -> GpuAtmosphereSettings {
  GpuAtmosphereSettings::{
    transmittance_lut_size: settings.transmittance_lut_size,
    multiscattering_lut_size: settings.multiscattering_lut_size,
    sky_view_lut_size: settings.sky_view_lut_size,
    aerial_view_lut_size: settings.aerial_view_lut_size,
    transmittance_lut_samples: settings.transmittance_lut_samples,
    multiscattering_lut_dirs: settings.multiscattering_lut_dirs,
    multiscattering_lut_samples: settings.multiscattering_lut_samples,
    sky_view_lut_samples: settings.sky_view_lut_samples,
    aerial_view_lut_samples: settings.aerial_view_lut_samples,
    aerial_view_lut_max_distance: settings.aerial_view_lut_max_distance,
    sky_max_samples: settings.sky_max_samples,
    rendering_method: settings.rendering_method,
  }
}

///|
pub fn pbr_atmosphere_settings_default() -> AtmosphereSettings {
  AtmosphereSettings()
}

///|
pub fn pbr_atmosphere_settings_with_sky_max_samples(
  settings : AtmosphereSettings,
  sky_max_samples : Int,
) -> AtmosphereSettings {
  settings.with_sky_max_samples(sky_max_samples)
}

///|
pub fn pbr_atmosphere_settings_with_rendering_method(
  settings : AtmosphereSettings,
  rendering_method : AtmosphereMode,
) -> AtmosphereSettings {
  settings.with_rendering_method(rendering_method)
}
