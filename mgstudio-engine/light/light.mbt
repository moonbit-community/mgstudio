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
/// Light-facing API boundary aligned with Bevy's `bevy_light` crate.
/// Runtime implementation currently lives in `Milky2018/mgstudio/pbr`.

///|
pub type PointLight = @pbr.PointLight

///|
pub type PointLightTexture = @pbr.PointLightTexture

///|
pub type PointLightShadowMap = @pbr.PointLightShadowMap

///|
pub type SpotLight = @pbr.SpotLight

///|
pub type SpotLightTexture = @pbr.SpotLightTexture

///|
pub type DirectionalLight = @pbr.DirectionalLight

///|
pub type DirectionalLightTexture = @pbr.DirectionalLightTexture

///|
pub type DirectionalLightShadowMap = @pbr.DirectionalLightShadowMap

///|
pub type CascadeShadowConfig = @pbr.CascadeShadowConfig

///|
pub type CascadeShadowConfigBuilder = @pbr.CascadeShadowConfigBuilder

///|
pub type LightProbe = @pbr.LightProbe

///|
pub type IrradianceVolume = @pbr.IrradianceVolume

///|
pub type ParallaxCorrection = @pbr.ParallaxCorrection

///|
pub type EnvironmentMapLight = @pbr.EnvironmentMapLight

///|
pub type GeneratedEnvironmentMapLight = @pbr.GeneratedEnvironmentMapLight

///|
pub type AtmosphereEnvironmentMapLight = @pbr.AtmosphereEnvironmentMapLight

///|
pub type GlobalAmbientLight = @pbr.GlobalAmbientLight

///|
pub type Atmosphere = @pbr.Atmosphere

///|
pub type AtmosphereMode = @pbr.AtmosphereMode

///|
pub type AtmosphereSettings = @pbr.AtmosphereSettings

///|
pub type ScatteringMedium = @pbr.ScatteringMedium

///|
pub type VolumetricLight = @pbr.VolumetricLight

///|
pub type VolumetricFog = @pbr.VolumetricFog

///|
pub type FogVolume = @pbr.FogVolume

///|
pub type Skybox = @pbr.Skybox

///|
pub type ContactShadows = @pbr.ContactShadows

///|
pub type ShadowFilteringMethod = @pbr.ShadowFilteringMethod

///|
pub type NotShadowCaster = @pbr.NotShadowCaster

///|
pub type NotShadowReceiver = @pbr.NotShadowReceiver

///|
pub type TransmittedShadowReceiver = @pbr.TransmittedShadowReceiver

///|
pub let ecs_key_point_light : @ecs.ComponentKey[PointLight] = @pbr.ecs_key_point_light

///|
pub let ecs_key_point_light_texture : @ecs.ComponentKey[PointLightTexture] = @pbr.ecs_key_point_light_texture

///|
pub let ecs_key_spot_light : @ecs.ComponentKey[SpotLight] = @pbr.ecs_key_spot_light

///|
pub let ecs_key_spot_light_texture : @ecs.ComponentKey[SpotLightTexture] = @pbr.ecs_key_spot_light_texture

///|
pub let ecs_key_directional_light : @ecs.ComponentKey[DirectionalLight] = @pbr.ecs_key_directional_light

///|
pub let ecs_key_directional_light_texture : @ecs.ComponentKey[
  DirectionalLightTexture,
] = @pbr.ecs_key_directional_light_texture

///|
pub let ecs_key_light_probe : @ecs.ComponentKey[LightProbe] = @pbr.ecs_key_light_probe

///|
pub let ecs_key_irradiance_volume : @ecs.ComponentKey[IrradianceVolume] = @pbr.ecs_key_irradiance_volume

///|
pub let ecs_key_parallax_correction : @ecs.ComponentKey[ParallaxCorrection] = @pbr.ecs_key_parallax_correction

///|
pub let ecs_key_environment_map_light : @ecs.ComponentKey[EnvironmentMapLight] = @pbr.ecs_key_environment_map_light

///|
pub let ecs_key_generated_environment_map_light : @ecs.ComponentKey[
  GeneratedEnvironmentMapLight,
] = @pbr.ecs_key_generated_environment_map_light

///|
pub let ecs_key_skybox : @ecs.ComponentKey[Skybox] = @pbr.ecs_key_skybox

///|
pub let ecs_key_contact_shadows : @ecs.ComponentKey[ContactShadows] = @pbr.ecs_key_contact_shadows

///|
pub let ecs_key_shadow_filtering_method : @ecs.ComponentKey[
  ShadowFilteringMethod,
] = @pbr.ecs_key_shadow_filtering_method

///|
pub let ecs_key_not_shadow_caster : @ecs.ComponentKey[NotShadowCaster] = @pbr.ecs_key_not_shadow_caster

///|
pub let ecs_key_not_shadow_receiver : @ecs.ComponentKey[NotShadowReceiver] = @pbr.ecs_key_not_shadow_receiver

///|
pub let ecs_key_transmitted_shadow_receiver : @ecs.ComponentKey[
  TransmittedShadowReceiver,
] = @pbr.ecs_key_transmitted_shadow_receiver

///|
pub let ecs_key_global_ambient_light : @ecs.ResourceKey[GlobalAmbientLight] = @pbr.ecs_key_global_ambient_light

///|
pub let ecs_key_point_light_shadow_map : @ecs.ResourceKey[PointLightShadowMap] = @pbr.ecs_key_point_light_shadow_map

///|
pub let ecs_key_directional_light_shadow_map : @ecs.ResourceKey[
  DirectionalLightShadowMap,
] = @pbr.ecs_key_directional_light_shadow_map

///|
pub fn get_point_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[PointLight] {
  @pbr.get_point_light_store(world)
}

///|
pub fn get_point_light_texture_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[PointLightTexture] {
  @pbr.get_point_light_texture_store(world)
}

///|
pub fn get_spot_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SpotLight] {
  @pbr.get_spot_light_store(world)
}

///|
pub fn get_spot_light_texture_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[SpotLightTexture] {
  @pbr.get_spot_light_texture_store(world)
}

///|
pub fn get_directional_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[DirectionalLight] {
  @pbr.get_directional_light_store(world)
}

///|
pub fn get_directional_light_texture_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[DirectionalLightTexture] {
  @pbr.get_directional_light_texture_store(world)
}

///|
pub fn get_light_probe_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[LightProbe] {
  @pbr.get_light_probe_store(world)
}

///|
pub fn get_irradiance_volume_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[IrradianceVolume] {
  @pbr.get_irradiance_volume_store(world)
}

///|
pub fn get_parallax_correction_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ParallaxCorrection] {
  @pbr.get_parallax_correction_store(world)
}

///|
pub fn get_environment_map_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[EnvironmentMapLight] {
  @pbr.get_environment_map_light_store(world)
}

///|
pub fn get_generated_environment_map_light_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[GeneratedEnvironmentMapLight] {
  @pbr.get_generated_environment_map_light_store(world)
}

///|
pub fn get_skybox_store(world : @ecs.World) -> @ecs.ComponentAccess[Skybox] {
  @pbr.get_skybox_store(world)
}

///|
pub fn get_contact_shadows_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ContactShadows] {
  @pbr.get_contact_shadows_store(world)
}

///|
pub fn get_shadow_filtering_method_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ShadowFilteringMethod] {
  @pbr.get_shadow_filtering_method_store(world)
}

///|
pub fn get_not_shadow_caster_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[NotShadowCaster] {
  @pbr.get_not_shadow_caster_store(world)
}

///|
pub fn get_not_shadow_receiver_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[NotShadowReceiver] {
  @pbr.get_not_shadow_receiver_store(world)
}

///|
pub fn get_transmitted_shadow_receiver_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[TransmittedShadowReceiver] {
  @pbr.get_transmitted_shadow_receiver_store(world)
}

///|
pub fn get_global_ambient_light_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[GlobalAmbientLight] {
  @pbr.get_global_ambient_light_resource(world)
}

///|
pub fn get_point_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[PointLightShadowMap] {
  @pbr.get_point_light_shadow_map_resource(world)
}

///|
pub fn get_directional_light_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DirectionalLightShadowMap] {
  @pbr.get_directional_light_shadow_map_resource(world)
}
