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
/// Bevy-light-aligned ownership boundary.
///
/// This package owns light-facing component/resource APIs and corresponding ECS
/// keys. `Milky2018/mgstudio/pbr` consumes these types/keys.

///|
fn light_sanitize_non_negative(value : Float) -> Float {
  if value < 0.0F {
    0.0F
  } else {
    value
  }
}

///|
fn light_clamp01(value : Float) -> Float {
  if value <= 0.0F {
    0.0F
  } else if value >= 1.0F {
    1.0F
  } else {
    value
  }
}

///|
/// Bevy-aligned marker component for directional volumetric lighting.
pub struct VolumetricLight {}

///|
pub fn VolumetricLight::default() -> VolumetricLight {
  VolumetricLight::{  }
}

///|
/// Bevy-aligned camera component that controls volumetric fog rendering.
pub struct VolumetricFog {
  ambient_color : @sprite.Color
  ambient_intensity : Float
  jitter : Float
  step_count : Int
} derive(ToJson, FromJson)

///|
pub fn VolumetricFog::default() -> VolumetricFog {
  VolumetricFog::{
    ambient_color: @sprite.Color::white(),
    ambient_intensity: 0.1F,
    jitter: 0.0F,
    step_count: 64,
  }
}

///|
pub fn VolumetricFog::with_ambient_color(
  self : VolumetricFog,
  ambient_color : @sprite.Color,
) -> VolumetricFog {
  VolumetricFog::{ ..self, ambient_color, }
}

///|
pub fn VolumetricFog::with_ambient_intensity(
  self : VolumetricFog,
  ambient_intensity : Float,
) -> VolumetricFog {
  VolumetricFog::{
    ..self,
    ambient_intensity: light_sanitize_non_negative(ambient_intensity),
  }
}

///|
pub fn VolumetricFog::with_jitter(
  self : VolumetricFog,
  jitter : Float,
) -> VolumetricFog {
  VolumetricFog::{ ..self, jitter: light_sanitize_non_negative(jitter) }
}

///|
pub fn VolumetricFog::with_step_count(
  self : VolumetricFog,
  step_count : Int,
) -> VolumetricFog {
  VolumetricFog::{
    ..self,
    step_count: if step_count <= 0 {
      1
    } else {
      step_count
    },
  }
}

///|
/// Bevy-aligned local fog volume component.
pub struct FogVolume {
  fog_color : @sprite.Color
  density_factor : Float
  density_texture : @asset.Handle[@asset.Image]?
  density_texture_offset : @math.Vec3
  absorption : Float
  scattering : Float
  scattering_asymmetry : Float
  light_tint : @sprite.Color
  light_intensity : Float
} derive(ToJson, FromJson)

///|
pub fn FogVolume::default() -> FogVolume {
  FogVolume::{
    fog_color: @sprite.Color::white(),
    density_factor: 0.1F,
    density_texture: None,
    density_texture_offset: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    absorption: 0.3F,
    scattering: 0.3F,
    scattering_asymmetry: 0.5F,
    light_tint: @sprite.Color::white(),
    light_intensity: 1.0F,
  }
}

///|
pub fn FogVolume::with_fog_color(
  self : FogVolume,
  fog_color : @sprite.Color,
) -> FogVolume {
  FogVolume::{ ..self, fog_color, }
}

///|
pub fn FogVolume::with_density_factor(
  self : FogVolume,
  density_factor : Float,
) -> FogVolume {
  FogVolume::{
    ..self,
    density_factor: light_sanitize_non_negative(density_factor),
  }
}

///|
pub fn FogVolume::with_density_texture(
  self : FogVolume,
  density_texture : @asset.Handle[@asset.Image]?,
) -> FogVolume {
  FogVolume::{ ..self, density_texture, }
}

///|
pub fn FogVolume::with_density_texture_offset(
  self : FogVolume,
  density_texture_offset : @math.Vec3,
) -> FogVolume {
  FogVolume::{ ..self, density_texture_offset, }
}

///|
pub fn FogVolume::with_absorption(
  self : FogVolume,
  absorption : Float,
) -> FogVolume {
  FogVolume::{ ..self, absorption: light_sanitize_non_negative(absorption) }
}

///|
pub fn FogVolume::with_scattering(
  self : FogVolume,
  scattering : Float,
) -> FogVolume {
  FogVolume::{ ..self, scattering: light_sanitize_non_negative(scattering) }
}

///|
pub fn FogVolume::with_scattering_asymmetry(
  self : FogVolume,
  scattering_asymmetry : Float,
) -> FogVolume {
  FogVolume::{
    ..self,
    scattering_asymmetry: light_clamp01((scattering_asymmetry + 1.0F) * 0.5F) *
    2.0F -
    1.0F,
  }
}

///|
pub fn FogVolume::with_light_tint(
  self : FogVolume,
  light_tint : @sprite.Color,
) -> FogVolume {
  FogVolume::{ ..self, light_tint, }
}

///|
pub fn FogVolume::with_light_intensity(
  self : FogVolume,
  light_intensity : Float,
) -> FogVolume {
  FogVolume::{
    ..self,
    light_intensity: light_sanitize_non_negative(light_intensity),
  }
}

///|
pub(all) enum AtmosphereMode {
  LookupTexture
  Raymarched
} derive(ToJson, FromJson)

///|
pub fn AtmosphereMode::default() -> AtmosphereMode {
  AtmosphereMode::LookupTexture
}

///|
/// Bevy-shaped atmosphere settings component.
pub struct AtmosphereSettings {
  scene_units_to_m : Float
  sky_max_samples : Int
  rendering_method : AtmosphereMode
} derive(ToJson, FromJson)

///|
pub fn AtmosphereSettings::default() -> AtmosphereSettings {
  AtmosphereSettings::{
    scene_units_to_m: 1.0F,
    sky_max_samples: 16,
    rendering_method: AtmosphereMode::LookupTexture,
  }
}

///|
pub fn AtmosphereSettings::with_scene_units_to_m(
  self : AtmosphereSettings,
  scene_units_to_m : Float,
) -> AtmosphereSettings {
  AtmosphereSettings::{
    ..self,
    scene_units_to_m: if scene_units_to_m <= 0.0F {
      0.0001F
    } else {
      scene_units_to_m
    },
  }
}

///|
pub fn AtmosphereSettings::with_sky_max_samples(
  self : AtmosphereSettings,
  sky_max_samples : Int,
) -> AtmosphereSettings {
  AtmosphereSettings::{
    ..self,
    sky_max_samples: if sky_max_samples <= 0 {
      1
    } else {
      sky_max_samples
    },
  }
}

///|
pub fn AtmosphereSettings::with_rendering_method(
  self : AtmosphereSettings,
  rendering_method : AtmosphereMode,
) -> AtmosphereSettings {
  AtmosphereSettings::{ ..self, rendering_method, }
}

///|
pub struct ScatteringMedium {
  density_multiplier : Float
} derive(ToJson, FromJson)

///|
pub fn ScatteringMedium::default() -> ScatteringMedium {
  ScatteringMedium::{ density_multiplier: 1.0F }
}

///|
pub fn ScatteringMedium::earthlike() -> ScatteringMedium {
  ScatteringMedium::default()
}

///|
pub fn ScatteringMedium::with_density_multiplier(
  self : ScatteringMedium,
  density_multiplier : Float,
) -> ScatteringMedium {
  self |> ignore
  ScatteringMedium::{
    density_multiplier: light_sanitize_non_negative(density_multiplier),
  }
}

///|
/// Bevy-shaped atmosphere component.
pub struct Atmosphere {
  bottom_radius : Float
  top_radius : Float
  ground_albedo : @math.Vec3
  medium : ScatteringMedium
} derive(ToJson, FromJson)

///|
pub fn Atmosphere::default() -> Atmosphere {
  Atmosphere::earthlike(ScatteringMedium::default())
}

///|
pub fn Atmosphere::earthlike(medium : ScatteringMedium) -> Atmosphere {
  Atmosphere::{
    bottom_radius: 6_360_000.0F,
    top_radius: 6_460_000.0F,
    ground_albedo: @math.Vec3::new(0.3F, 0.3F, 0.3F),
    medium,
  }
}

///|
pub fn Atmosphere::with_radii(
  self : Atmosphere,
  bottom_radius : Float,
  top_radius : Float,
) -> Atmosphere {
  let safe_bottom_radius = if bottom_radius <= 0.0F {
    0.0001F
  } else {
    bottom_radius
  }
  let safe_top_radius = if top_radius < safe_bottom_radius {
    safe_bottom_radius
  } else {
    top_radius
  }
  Atmosphere::{
    ..self,
    bottom_radius: safe_bottom_radius,
    top_radius: safe_top_radius,
  }
}

///|
pub fn Atmosphere::with_ground_albedo(
  self : Atmosphere,
  ground_albedo : @math.Vec3,
) -> Atmosphere {
  Atmosphere::{ ..self, ground_albedo, }
}

///|
pub fn Atmosphere::with_medium(
  self : Atmosphere,
  medium : ScatteringMedium,
) -> Atmosphere {
  Atmosphere::{ ..self, medium, }
}

///|
/// Lets atmosphere contribute environment-map lighting (camera/probe-level).
pub struct AtmosphereEnvironmentMapLight {
  intensity : Float
  affects_lightmapped_mesh_diffuse : Bool
  size : @math.UVec2
} derive(ToJson, FromJson)

///|
pub fn AtmosphereEnvironmentMapLight::default() -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::{
    intensity: 1.0F,
    affects_lightmapped_mesh_diffuse: true,
    size: @math.UVec2::new(512, 512),
  }
}

///|
pub fn AtmosphereEnvironmentMapLight::new(
  intensity : Float,
  affects_lightmapped_mesh_diffuse : Bool,
  size : @math.UVec2,
) -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::{
    intensity: light_sanitize_non_negative(intensity),
    affects_lightmapped_mesh_diffuse,
    size: if size.x <= 0 || size.y <= 0 {
      @math.UVec2::new(512, 512)
    } else {
      size
    },
  }
}

///|
pub fn AtmosphereEnvironmentMapLight::with_intensity(
  self : AtmosphereEnvironmentMapLight,
  intensity : Float,
) -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::{
    ..self,
    intensity: light_sanitize_non_negative(intensity),
  }
}

///|
pub fn AtmosphereEnvironmentMapLight::with_affects_lightmapped_mesh_diffuse(
  self : AtmosphereEnvironmentMapLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
pub fn AtmosphereEnvironmentMapLight::with_size(
  self : AtmosphereEnvironmentMapLight,
  size : @math.UVec2,
) -> AtmosphereEnvironmentMapLight {
  AtmosphereEnvironmentMapLight::{
    ..self,
    size: if size.x <= 0 || size.y <= 0 {
      @math.UVec2::new(512, 512)
    } else {
      size
    },
  }
}

///|
const POINT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS : Float = 0.08F

///|
const POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS : Float = 0.6F

///|
const POINT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z : Float = 0.1F

///|
const DIRECTIONAL_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS : Float = 0.02F

///|
const DIRECTIONAL_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS : Float = 1.8F

///|
const SPOT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS : Float = 0.02F

///|
const SPOT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS : Float = 1.8F

///|
const SPOT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z : Float = 0.1F

///|
pub struct PointLight {
  color : @sprite.Color
  intensity : Float
  range : Float
  radius : Float
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  soft_shadows_enabled : Bool
  affects_lightmapped_mesh_diffuse : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  shadow_map_near_z : Float
} derive(ToJson, FromJson)

///|
pub fn PointLight::default() -> PointLight {
  PointLight::{
    color: @sprite.Color::white(),
    intensity: 1_000_000.0F,
    range: 20.0F,
    radius: 0.0F,
    shadow_maps_enabled: false,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    affects_lightmapped_mesh_diffuse: true,
    shadow_depth_bias: POINT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: POINT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn PointLight::new(
  color : @sprite.Color,
  intensity : Float,
  range : Float,
  shadow_maps_enabled : Bool,
) -> PointLight {
  PointLight::{
    color,
    intensity,
    range,
    radius: 0.0F,
    shadow_maps_enabled,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    affects_lightmapped_mesh_diffuse: true,
    shadow_depth_bias: POINT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: POINT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: POINT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn PointLight::with_color(
  self : PointLight,
  color : @sprite.Color,
) -> PointLight {
  PointLight::{ ..self, color, }
}

///|
pub fn PointLight::with_range(self : PointLight, range : Float) -> PointLight {
  PointLight::{ ..self, range: light_sanitize_non_negative(range) }
}

///|
pub fn PointLight::with_intensity(
  self : PointLight,
  intensity : Float,
) -> PointLight {
  PointLight::{ ..self, intensity: light_sanitize_non_negative(intensity) }
}

///|
pub fn PointLight::with_radius(self : PointLight, radius : Float) -> PointLight {
  PointLight::{ ..self, radius: light_sanitize_non_negative(radius) }
}

///|
pub fn PointLight::with_contact_shadows_enabled(
  self : PointLight,
  contact_shadows_enabled : Bool,
) -> PointLight {
  PointLight::{ ..self, contact_shadows_enabled, }
}

///|
pub fn PointLight::with_soft_shadows_enabled(
  self : PointLight,
  soft_shadows_enabled : Bool,
) -> PointLight {
  PointLight::{ ..self, soft_shadows_enabled, }
}

///|
pub fn PointLight::with_shadow_maps_enabled(
  self : PointLight,
  shadow_maps_enabled : Bool,
) -> PointLight {
  PointLight::{ ..self, shadow_maps_enabled, }
}

///|
pub fn PointLight::with_affects_lightmapped_mesh_diffuse(
  self : PointLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> PointLight {
  PointLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
pub fn PointLight::with_shadow_depth_bias(
  self : PointLight,
  shadow_depth_bias : Float,
) -> PointLight {
  PointLight::{
    ..self,
    shadow_depth_bias: light_sanitize_non_negative(shadow_depth_bias),
  }
}

///|
pub fn PointLight::with_shadow_normal_bias(
  self : PointLight,
  shadow_normal_bias : Float,
) -> PointLight {
  PointLight::{
    ..self,
    shadow_normal_bias: light_sanitize_non_negative(shadow_normal_bias),
  }
}

///|
pub fn PointLight::with_shadow_map_near_z(
  self : PointLight,
  shadow_map_near_z : Float,
) -> PointLight {
  PointLight::{
    ..self,
    shadow_map_near_z: if shadow_map_near_z <= 0.0001F {
      0.0001F
    } else {
      shadow_map_near_z
    },
  }
}

///|
/// Point-light shadow map resource aligned with Bevy's `PointLightShadowMap`.
pub struct PointLightShadowMap {
  size : Int
} derive(ToJson, FromJson)

///|
pub fn PointLightShadowMap::default() -> PointLightShadowMap {
  PointLightShadowMap::{ size: 1024 }
}

///|
pub fn PointLightShadowMap::new(size : Int) -> PointLightShadowMap {
  PointLightShadowMap::{ size: if size <= 0 { 1 } else { size } }
}

///|
pub fn PointLightShadowMap::with_size(
  self : PointLightShadowMap,
  size : Int,
) -> PointLightShadowMap {
  self |> ignore
  PointLightShadowMap::new(size)
}

///|
fn directional_shadow_map_size_safe(size : Int) -> Int {
  let safe = if size <= 0 { 1 } else { size }
  let mut pow2 = 1
  while pow2 < safe {
    pow2 = pow2 * 2
  }
  pow2
}

///|
/// Directional/spot-light shadow map resource aligned with Bevy's
/// `DirectionalLightShadowMap`.
pub struct DirectionalLightShadowMap {
  size : Int
} derive(ToJson, FromJson)

///|
pub fn DirectionalLightShadowMap::default() -> DirectionalLightShadowMap {
  DirectionalLightShadowMap::{ size: 2048 }
}

///|
pub fn DirectionalLightShadowMap::new(size : Int) -> DirectionalLightShadowMap {
  DirectionalLightShadowMap::{ size: directional_shadow_map_size_safe(size) }
}

///|
pub fn DirectionalLightShadowMap::with_size(
  self : DirectionalLightShadowMap,
  size : Int,
) -> DirectionalLightShadowMap {
  self |> ignore
  DirectionalLightShadowMap::new(size)
}

///|
pub struct CascadeShadowConfig {
  bounds : Array[Float]
  overlap_proportion : Float
  minimum_distance : Float
} derive(ToJson, FromJson)

///|
pub struct CascadeShadowConfigBuilder {
  num_cascades : Int
  minimum_distance : Float
  maximum_distance : Float
  first_cascade_far_bound : Float
  overlap_proportion : Float
}

///|
fn cascade_shadow_config_safe_overlap(overlap : Float) -> Float {
  if overlap < 0.0F {
    0.0F
  } else if overlap >= 1.0F {
    0.9999F
  } else {
    overlap
  }
}

///|
fn cascade_shadow_config_calculate_bounds(
  num_cascades : Int,
  nearest_bound : Float,
  maximum_distance : Float,
) -> Array[Float] {
  if num_cascades <= 1 {
    return [maximum_distance]
  }
  let exponent = 1.0F / Float::from_double((num_cascades - 1).to_double())
  let base = @math.pow(maximum_distance / nearest_bound, exponent)
  let bounds : Array[Float] = []
  for i in 0..<num_cascades {
    bounds.push(
      nearest_bound * @math.pow(base, Float::from_double(i.to_double())),
    )
  }
  bounds
}

///|
pub fn CascadeShadowConfigBuilder::default() -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    num_cascades: 4,
    minimum_distance: 0.1F,
    maximum_distance: 150.0F,
    first_cascade_far_bound: 10.0F,
    overlap_proportion: 0.2F,
  }
}

///|
pub fn CascadeShadowConfigBuilder::new() -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::default()
}

///|
pub fn CascadeShadowConfigBuilder::with_num_cascades(
  self : CascadeShadowConfigBuilder,
  num_cascades : Int,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    num_cascades: if num_cascades <= 0 {
      1
    } else {
      num_cascades
    },
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_minimum_distance(
  self : CascadeShadowConfigBuilder,
  minimum_distance : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    minimum_distance: light_sanitize_non_negative(minimum_distance),
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_maximum_distance(
  self : CascadeShadowConfigBuilder,
  maximum_distance : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    maximum_distance: light_sanitize_non_negative(maximum_distance),
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_first_cascade_far_bound(
  self : CascadeShadowConfigBuilder,
  first_cascade_far_bound : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    first_cascade_far_bound: light_sanitize_non_negative(
      first_cascade_far_bound,
    ),
  }
}

///|
pub fn CascadeShadowConfigBuilder::with_overlap_proportion(
  self : CascadeShadowConfigBuilder,
  overlap_proportion : Float,
) -> CascadeShadowConfigBuilder {
  CascadeShadowConfigBuilder::{
    ..self,
    overlap_proportion: cascade_shadow_config_safe_overlap(overlap_proportion),
  }
}

///|
pub fn CascadeShadowConfigBuilder::build(
  self : CascadeShadowConfigBuilder,
) -> CascadeShadowConfig {
  let safe_num_cascades = if self.num_cascades <= 0 {
    1
  } else {
    self.num_cascades
  }
  let safe_minimum_distance = light_sanitize_non_negative(self.minimum_distance)
  let mut safe_maximum_distance = if self.maximum_distance <=
    safe_minimum_distance {
    safe_minimum_distance + 0.1F
  } else {
    self.maximum_distance
  }
  if safe_maximum_distance <= 0.0F {
    safe_maximum_distance = 0.1F
  }
  let mut safe_first_cascade_far_bound = if self.first_cascade_far_bound <=
    safe_minimum_distance {
    safe_minimum_distance + 0.1F
  } else {
    self.first_cascade_far_bound
  }
  if safe_num_cascades == 1 {
    safe_first_cascade_far_bound = safe_maximum_distance
  } else if safe_first_cascade_far_bound > safe_maximum_distance {
    safe_first_cascade_far_bound = safe_maximum_distance
  }

  CascadeShadowConfig::{
    bounds: cascade_shadow_config_calculate_bounds(
      safe_num_cascades, safe_first_cascade_far_bound, safe_maximum_distance,
    ),
    overlap_proportion: cascade_shadow_config_safe_overlap(
      self.overlap_proportion,
    ),
    minimum_distance: safe_minimum_distance,
  }
}

///|
pub fn CascadeShadowConfig::default() -> CascadeShadowConfig {
  CascadeShadowConfigBuilder::default().build()
}

///|
pub struct DirectionalLight {
  color : @sprite.Color
  illuminance : Float
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  affects_lightmapped_mesh_diffuse : Bool
  soft_shadow_size : Float?
  cascade_shadow_config : CascadeShadowConfig?
  shadow_depth_bias : Float
  shadow_normal_bias : Float
} derive(ToJson, FromJson)

///|
pub fn DirectionalLight::default() -> DirectionalLight {
  DirectionalLight::{
    color: @sprite.Color::white(),
    illuminance: 10000.0F,
    shadow_maps_enabled: false,
    contact_shadows_enabled: false,
    affects_lightmapped_mesh_diffuse: true,
    soft_shadow_size: None,
    cascade_shadow_config: None,
    shadow_depth_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
  }
}

///|
pub fn DirectionalLight::new(
  color : @sprite.Color,
  illuminance : Float,
  shadow_maps_enabled : Bool,
) -> DirectionalLight {
  DirectionalLight::{
    color,
    illuminance,
    shadow_maps_enabled,
    contact_shadows_enabled: false,
    affects_lightmapped_mesh_diffuse: true,
    soft_shadow_size: None,
    cascade_shadow_config: None,
    shadow_depth_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: DIRECTIONAL_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
  }
}

///|
pub fn DirectionalLight::with_illuminance(
  self : DirectionalLight,
  illuminance : Float,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    illuminance: light_sanitize_non_negative(illuminance),
  }
}

///|
pub fn DirectionalLight::with_contact_shadows_enabled(
  self : DirectionalLight,
  contact_shadows_enabled : Bool,
) -> DirectionalLight {
  DirectionalLight::{ ..self, contact_shadows_enabled, }
}

///|
pub fn DirectionalLight::with_shadow_maps_enabled(
  self : DirectionalLight,
  shadow_maps_enabled : Bool,
) -> DirectionalLight {
  DirectionalLight::{ ..self, shadow_maps_enabled, }
}

///|
pub fn DirectionalLight::with_affects_lightmapped_mesh_diffuse(
  self : DirectionalLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> DirectionalLight {
  DirectionalLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
pub fn DirectionalLight::with_soft_shadow_size(
  self : DirectionalLight,
  soft_shadow_size : Float?,
) -> DirectionalLight {
  let safe_soft_shadow_size = match soft_shadow_size {
    Some(value) => Some(light_sanitize_non_negative(value))
    None => None
  }
  DirectionalLight::{ ..self, soft_shadow_size: safe_soft_shadow_size }
}

///|
pub fn DirectionalLight::with_cascade_shadow_config(
  self : DirectionalLight,
  cascade_shadow_config : CascadeShadowConfig?,
) -> DirectionalLight {
  DirectionalLight::{ ..self, cascade_shadow_config, }
}

///|
pub fn DirectionalLight::with_cascade_shadow_config_builder(
  self : DirectionalLight,
  cascade_shadow_config_builder : CascadeShadowConfigBuilder,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    cascade_shadow_config: Some(cascade_shadow_config_builder.build()),
  }
}

///|
pub fn DirectionalLight::with_shadow_depth_bias(
  self : DirectionalLight,
  shadow_depth_bias : Float,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    shadow_depth_bias: light_sanitize_non_negative(shadow_depth_bias),
  }
}

///|
pub fn DirectionalLight::with_shadow_normal_bias(
  self : DirectionalLight,
  shadow_normal_bias : Float,
) -> DirectionalLight {
  DirectionalLight::{
    ..self,
    shadow_normal_bias: light_sanitize_non_negative(shadow_normal_bias),
  }
}

///|
pub struct SpotLight {
  color : @sprite.Color
  intensity : Float
  range : Float
  radius : Float
  inner_angle : Float
  outer_angle : Float
  shadow_maps_enabled : Bool
  contact_shadows_enabled : Bool
  soft_shadows_enabled : Bool
  affects_lightmapped_mesh_diffuse : Bool
  shadow_depth_bias : Float
  shadow_normal_bias : Float
  shadow_map_near_z : Float
} derive(ToJson, FromJson)

///|
pub fn SpotLight::default() -> SpotLight {
  SpotLight::{
    color: @sprite.Color::white(),
    intensity: 1_000_000.0F,
    range: 20.0F,
    radius: 0.0F,
    inner_angle: 0.6F,
    outer_angle: 0.8F,
    shadow_maps_enabled: false,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    affects_lightmapped_mesh_diffuse: true,
    shadow_depth_bias: SPOT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: SPOT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: SPOT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn SpotLight::new(
  color : @sprite.Color,
  intensity : Float,
  range : Float,
  inner_angle : Float,
  outer_angle : Float,
  shadow_maps_enabled : Bool,
) -> SpotLight {
  SpotLight::{
    color,
    intensity,
    range,
    radius: 0.0F,
    inner_angle,
    outer_angle,
    shadow_maps_enabled,
    contact_shadows_enabled: false,
    soft_shadows_enabled: false,
    affects_lightmapped_mesh_diffuse: true,
    shadow_depth_bias: SPOT_LIGHT_DEFAULT_SHADOW_DEPTH_BIAS,
    shadow_normal_bias: SPOT_LIGHT_DEFAULT_SHADOW_NORMAL_BIAS,
    shadow_map_near_z: SPOT_LIGHT_DEFAULT_SHADOW_MAP_NEAR_Z,
  }
}

///|
pub fn SpotLight::with_intensity(
  self : SpotLight,
  intensity : Float,
) -> SpotLight {
  SpotLight::{ ..self, intensity: light_sanitize_non_negative(intensity) }
}

///|
pub fn SpotLight::with_inner_angle(
  self : SpotLight,
  inner_angle : Float,
) -> SpotLight {
  let safe_inner_angle = if inner_angle < 0.0F {
    0.0F
  } else if inner_angle > self.outer_angle {
    self.outer_angle
  } else {
    inner_angle
  }
  SpotLight::{ ..self, inner_angle: safe_inner_angle }
}

///|
pub fn SpotLight::with_outer_angle(
  self : SpotLight,
  outer_angle : Float,
) -> SpotLight {
  let safe_outer_angle = if outer_angle <= 0.0001F {
    0.0001F
  } else {
    outer_angle
  }
  let safe_inner_angle = if self.inner_angle > safe_outer_angle {
    safe_outer_angle
  } else {
    self.inner_angle
  }
  SpotLight::{
    ..self,
    outer_angle: safe_outer_angle,
    inner_angle: safe_inner_angle,
  }
}

///|
pub fn SpotLight::with_radius(self : SpotLight, radius : Float) -> SpotLight {
  SpotLight::{ ..self, radius: light_sanitize_non_negative(radius) }
}

///|
pub fn SpotLight::with_contact_shadows_enabled(
  self : SpotLight,
  contact_shadows_enabled : Bool,
) -> SpotLight {
  SpotLight::{ ..self, contact_shadows_enabled, }
}

///|
pub fn SpotLight::with_shadow_maps_enabled(
  self : SpotLight,
  shadow_maps_enabled : Bool,
) -> SpotLight {
  SpotLight::{ ..self, shadow_maps_enabled, }
}

///|
pub fn SpotLight::with_soft_shadows_enabled(
  self : SpotLight,
  soft_shadows_enabled : Bool,
) -> SpotLight {
  SpotLight::{ ..self, soft_shadows_enabled, }
}

///|
pub fn SpotLight::with_affects_lightmapped_mesh_diffuse(
  self : SpotLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> SpotLight {
  SpotLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
pub fn SpotLight::with_shadow_depth_bias(
  self : SpotLight,
  shadow_depth_bias : Float,
) -> SpotLight {
  SpotLight::{
    ..self,
    shadow_depth_bias: light_sanitize_non_negative(shadow_depth_bias),
  }
}

///|
pub fn SpotLight::with_shadow_normal_bias(
  self : SpotLight,
  shadow_normal_bias : Float,
) -> SpotLight {
  SpotLight::{
    ..self,
    shadow_normal_bias: light_sanitize_non_negative(shadow_normal_bias),
  }
}

///|
pub fn SpotLight::with_shadow_map_near_z(
  self : SpotLight,
  shadow_map_near_z : Float,
) -> SpotLight {
  SpotLight::{
    ..self,
    shadow_map_near_z: if shadow_map_near_z <= 0.0001F {
      0.0001F
    } else {
      shadow_map_near_z
    },
  }
}

///|
pub(all) enum CubemapLayout3d {
  CrossVertical
  CrossHorizontal
  LineVertical
  LineHorizontal
  Equirectangular
  Faces
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn CubemapLayout3d::default() -> CubemapLayout3d {
  CubemapLayout3d::CrossVertical
}

///|
pub struct DirectionalLightTexture {
  image : @asset.Handle[@asset.Image]?
  tiled : Bool
} derive(ToJson, FromJson)

///|
pub fn DirectionalLightTexture::default() -> DirectionalLightTexture {
  DirectionalLightTexture::{ image: None, tiled: false }
}

///|
pub fn DirectionalLightTexture::new(
  image : @asset.Handle[@asset.Image]?,
  tiled : Bool,
) -> DirectionalLightTexture {
  DirectionalLightTexture::{ image, tiled }
}

///|
pub fn DirectionalLightTexture::with_image(
  self : DirectionalLightTexture,
  image : @asset.Handle[@asset.Image]?,
) -> DirectionalLightTexture {
  DirectionalLightTexture::{ ..self, image, }
}

///|
pub fn DirectionalLightTexture::with_tiled(
  self : DirectionalLightTexture,
  tiled : Bool,
) -> DirectionalLightTexture {
  DirectionalLightTexture::{ ..self, tiled, }
}

///|
pub struct SpotLightTexture {
  image : @asset.Handle[@asset.Image]?
} derive(ToJson, FromJson)

///|
pub fn SpotLightTexture::default() -> SpotLightTexture {
  SpotLightTexture::{ image: None }
}

///|
pub fn SpotLightTexture::new(
  image : @asset.Handle[@asset.Image]?,
) -> SpotLightTexture {
  SpotLightTexture::{ image, }
}

///|
pub fn SpotLightTexture::with_image(
  self : SpotLightTexture,
  image : @asset.Handle[@asset.Image]?,
) -> SpotLightTexture {
  self |> ignore
  SpotLightTexture::{ image, }
}

///|
pub struct PointLightTexture {
  image : @asset.Handle[@asset.Image]?
  cubemap_layout : CubemapLayout3d
} derive(ToJson, FromJson)

///|
pub fn PointLightTexture::default() -> PointLightTexture {
  PointLightTexture::{
    image: None,
    cubemap_layout: CubemapLayout3d::CrossVertical,
  }
}

///|
pub fn PointLightTexture::new(
  image : @asset.Handle[@asset.Image]?,
  cubemap_layout : CubemapLayout3d,
) -> PointLightTexture {
  PointLightTexture::{ image, cubemap_layout }
}

///|
pub fn PointLightTexture::with_image(
  self : PointLightTexture,
  image : @asset.Handle[@asset.Image]?,
) -> PointLightTexture {
  PointLightTexture::{ ..self, image, }
}

///|
pub fn PointLightTexture::with_cubemap_layout(
  self : PointLightTexture,
  cubemap_layout : CubemapLayout3d,
) -> PointLightTexture {
  PointLightTexture::{ ..self, cubemap_layout, }
}

///|
pub struct LightProbe {
  falloff : @math.Vec3
} derive(ToJson, FromJson)

///|
pub fn LightProbe::default() -> LightProbe {
  LightProbe::{ falloff: @math.Vec3::zero() }
}

///|
pub fn LightProbe::new() -> LightProbe {
  LightProbe::default()
}

///|
pub fn LightProbe::with_falloff(
  self : LightProbe,
  falloff : @math.Vec3,
) -> LightProbe {
  self |> ignore
  LightProbe::{ falloff, }
}

///|
pub struct EnvironmentMapLight {
  diffuse_map : @asset.Handle[@asset.Image]?
  specular_map : @asset.Handle[@asset.Image]?
  intensity : Float
  rotation : @math.Quat
  affects_lightmapped_mesh_diffuse : Bool
} derive(ToJson, FromJson)

///|
pub fn EnvironmentMapLight::default() -> EnvironmentMapLight {
  EnvironmentMapLight::{
    diffuse_map: None,
    specular_map: None,
    intensity: 0.0F,
    rotation: @math.Quat::identity(),
    affects_lightmapped_mesh_diffuse: true,
  }
}

///|
pub fn EnvironmentMapLight::new(
  diffuse_map : @asset.Handle[@asset.Image]?,
  specular_map : @asset.Handle[@asset.Image]?,
  intensity : Float,
) -> EnvironmentMapLight {
  EnvironmentMapLight::default()
  .with_diffuse_map(diffuse_map)
  .with_specular_map(specular_map)
  .with_intensity(intensity)
}

///|
pub fn EnvironmentMapLight::with_diffuse_map(
  self : EnvironmentMapLight,
  diffuse_map : @asset.Handle[@asset.Image]?,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, diffuse_map, }
}

///|
pub fn EnvironmentMapLight::with_specular_map(
  self : EnvironmentMapLight,
  specular_map : @asset.Handle[@asset.Image]?,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, specular_map, }
}

///|
pub fn EnvironmentMapLight::with_intensity(
  self : EnvironmentMapLight,
  intensity : Float,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{
    ..self,
    intensity: light_sanitize_non_negative(intensity),
  }
}

///|
pub fn EnvironmentMapLight::with_rotation(
  self : EnvironmentMapLight,
  rotation : @math.Quat,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, rotation, }
}

///|
pub fn EnvironmentMapLight::with_affects_lightmapped_mesh_diffuse(
  self : EnvironmentMapLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> EnvironmentMapLight {
  EnvironmentMapLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
pub struct GeneratedEnvironmentMapLight {
  environment_map : @asset.Handle[@asset.Image]?
  intensity : Float
  rotation : @math.Quat
  affects_lightmapped_mesh_diffuse : Bool
} derive(ToJson, FromJson)

///|
pub fn GeneratedEnvironmentMapLight::default() -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{
    environment_map: None,
    intensity: 0.0F,
    rotation: @math.Quat::identity(),
    affects_lightmapped_mesh_diffuse: true,
  }
}

///|
pub fn GeneratedEnvironmentMapLight::new(
  environment_map : @asset.Handle[@asset.Image]?,
  intensity : Float,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::default()
  .with_environment_map(environment_map)
  .with_intensity(intensity)
}

///|
pub fn GeneratedEnvironmentMapLight::with_environment_map(
  self : GeneratedEnvironmentMapLight,
  environment_map : @asset.Handle[@asset.Image]?,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{ ..self, environment_map, }
}

///|
pub fn GeneratedEnvironmentMapLight::with_intensity(
  self : GeneratedEnvironmentMapLight,
  intensity : Float,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{
    ..self,
    intensity: light_sanitize_non_negative(intensity),
  }
}

///|
pub fn GeneratedEnvironmentMapLight::with_rotation(
  self : GeneratedEnvironmentMapLight,
  rotation : @math.Quat,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{ ..self, rotation, }
}

///|
pub fn GeneratedEnvironmentMapLight::with_affects_lightmapped_mesh_diffuse(
  self : GeneratedEnvironmentMapLight,
  affects_lightmapped_mesh_diffuse : Bool,
) -> GeneratedEnvironmentMapLight {
  GeneratedEnvironmentMapLight::{ ..self, affects_lightmapped_mesh_diffuse, }
}

///|
pub(all) enum ParallaxCorrection {
  None
  Auto
  Custom(@math.Vec3)
} derive(ToJson, FromJson)

///|
pub fn ParallaxCorrection::default() -> ParallaxCorrection {
  ParallaxCorrection::Auto
}

///|
pub struct IrradianceVolume {
  voxels : @asset.Handle[@asset.Image]?
  intensity : Float
} derive(ToJson, FromJson)

///|
pub fn IrradianceVolume::default() -> IrradianceVolume {
  IrradianceVolume::{ voxels: None, intensity: 1.0F }
}

///|
pub fn IrradianceVolume::new(
  voxels : @asset.Handle[@asset.Image]?,
  intensity : Float,
) -> IrradianceVolume {
  IrradianceVolume::{
    voxels,
    intensity: light_sanitize_non_negative(intensity),
  }
}

///|
pub fn IrradianceVolume::with_voxels(
  self : IrradianceVolume,
  voxels : @asset.Handle[@asset.Image]?,
) -> IrradianceVolume {
  IrradianceVolume::{ ..self, voxels, }
}

///|
pub fn IrradianceVolume::with_intensity(
  self : IrradianceVolume,
  intensity : Float,
) -> IrradianceVolume {
  IrradianceVolume::new(self.voxels, intensity)
}

///|
pub struct GlobalAmbientLight {
  color : @sprite.Color
  brightness : Float
  affects_lightmapped_meshes : Bool
} derive(ToJson, FromJson)

///|
pub fn GlobalAmbientLight::default() -> GlobalAmbientLight {
  GlobalAmbientLight::{
    color: @sprite.Color::white(),
    brightness: 80.0F,
    affects_lightmapped_meshes: true,
  }
}

///|
pub fn GlobalAmbientLight::new(
  color : @sprite.Color,
  brightness : Float,
) -> GlobalAmbientLight {
  GlobalAmbientLight::{ color, brightness, affects_lightmapped_meshes: true }
}

///|
pub fn GlobalAmbientLight::with_affects_lightmapped_meshes(
  self : GlobalAmbientLight,
  affects_lightmapped_meshes : Bool,
) -> GlobalAmbientLight {
  GlobalAmbientLight::{ ..self, affects_lightmapped_meshes }
}

///|
pub let ecs_key_point_light : @ecs.ComponentKey[PointLight] = @ecs.register_component(
  debug_name="render3d.point_light",
)

///|
pub let ecs_key_point_light_texture : @ecs.ComponentKey[PointLightTexture] = @ecs.register_component(
  debug_name="render3d.point_light_texture",
)

///|
pub let ecs_key_spot_light : @ecs.ComponentKey[SpotLight] = @ecs.register_component(
  debug_name="render3d.spot_light",
)

///|
pub let ecs_key_spot_light_texture : @ecs.ComponentKey[SpotLightTexture] = @ecs.register_component(
  debug_name="render3d.spot_light_texture",
)

///|
pub let ecs_key_directional_light : @ecs.ComponentKey[DirectionalLight] = @ecs.register_component(
  debug_name="render3d.directional_light",
)

///|
pub let ecs_key_volumetric_light : @ecs.ComponentKey[VolumetricLight] = @ecs.register_component(
  debug_name="render3d.volumetric_light",
)

///|
pub let ecs_key_fog_volume : @ecs.ComponentKey[FogVolume] = @ecs.register_component(
  debug_name="render3d.fog_volume",
)

///|
pub let ecs_key_directional_light_texture : @ecs.ComponentKey[
  DirectionalLightTexture,
] = @ecs.register_component(debug_name="render3d.directional_light_texture")

///|
pub let ecs_key_light_probe : @ecs.ComponentKey[LightProbe] = @ecs.register_component(
  debug_name="render3d.light_probe",
)

///|
pub let ecs_key_irradiance_volume : @ecs.ComponentKey[IrradianceVolume] = @ecs.register_component(
  debug_name="render3d.irradiance_volume",
)

///|
pub let ecs_key_parallax_correction : @ecs.ComponentKey[ParallaxCorrection] = @ecs.register_component(
  debug_name="render3d.parallax_correction",
)

///|
pub let ecs_key_environment_map_light : @ecs.ComponentKey[EnvironmentMapLight] = @ecs.register_component(
  debug_name="render3d.environment_map_light",
)

///|
pub let ecs_key_generated_environment_map_light : @ecs.ComponentKey[
  GeneratedEnvironmentMapLight,
] = @ecs.register_component(
  debug_name="render3d.generated_environment_map_light",
)

///|
pub let ecs_key_atmosphere_environment_map_light : @ecs.ComponentKey[
  AtmosphereEnvironmentMapLight,
] = @ecs.register_component(
  debug_name="render3d.atmosphere_environment_map_light",
)

///|
pub impl @ecs.Component for PointLight with component() {
  ecs_key_point_light
}

///|
pub impl @ecs.Component for PointLightTexture with component() {
  ecs_key_point_light_texture
}

///|
pub impl @ecs.Component for SpotLight with component() {
  ecs_key_spot_light
}

///|
pub impl @ecs.Component for SpotLightTexture with component() {
  ecs_key_spot_light_texture
}

///|
pub impl @ecs.Component for DirectionalLight with component() {
  ecs_key_directional_light
}

///|
pub impl @ecs.Component for VolumetricLight with component() {
  ecs_key_volumetric_light
}

///|
pub impl @ecs.Component for FogVolume with component() {
  ecs_key_fog_volume
}

///|
pub impl @ecs.Component for DirectionalLightTexture with component() {
  ecs_key_directional_light_texture
}

///|
pub impl @ecs.Component for LightProbe with component() {
  ecs_key_light_probe
}

///|
pub impl @ecs.Component for IrradianceVolume with component() {
  ecs_key_irradiance_volume
}

///|
pub impl @ecs.Component for ParallaxCorrection with component() {
  ecs_key_parallax_correction
}

///|
pub impl @ecs.Component for EnvironmentMapLight with component() {
  ecs_key_environment_map_light
}

///|
pub impl @ecs.Component for GeneratedEnvironmentMapLight with component() {
  ecs_key_generated_environment_map_light
}

///|
pub impl @ecs.Component for AtmosphereEnvironmentMapLight with component() {
  ecs_key_atmosphere_environment_map_light
}

///|
pub let ecs_key_global_ambient_light : @ecs.ResourceKey[GlobalAmbientLight] = @ecs.register_resource(
  debug_name="render3d.global_ambient_light",
)

///|
pub let ecs_key_point_light_shadow_map : @ecs.ResourceKey[PointLightShadowMap] = @ecs.register_resource(
  debug_name="render3d.point_light_shadow_map",
)

///|
pub let ecs_key_directional_light_shadow_map : @ecs.ResourceKey[
  DirectionalLightShadowMap,
] = @ecs.register_resource(debug_name="render3d.directional_light_shadow_map")

///|
pub fn get_global_ambient_light_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[GlobalAmbientLight] {
  world.resource(ecs_key_global_ambient_light)
}

///|
pub fn get_point_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointLightShadowMap] {
  world.resource(ecs_key_point_light_shadow_map)
}

///|
pub fn get_directional_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DirectionalLightShadowMap] {
  world.resource(ecs_key_directional_light_shadow_map)
}
