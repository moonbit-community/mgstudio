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
// Bevy source: `bevy/crates/bevy_light/src/probe.rs`.

///|
pub type LightProbeComponent = LightProbe

///|
pub type EnvironmentMapLightComponent = EnvironmentMapLight

///|
pub type GeneratedEnvironmentMapLightComponent = GeneratedEnvironmentMapLight

///|
pub type IrradianceVolumeComponent = IrradianceVolume

///|
pub type ParallaxCorrectionComponent = ParallaxCorrection

///|
pub type SkyboxComponent = Skybox

///|
pub let ecs_key_light_probe_component : @ecs.ComponentKey[LightProbeComponent] = ecs_key_light_probe

///|
pub let ecs_key_environment_map_light_component : @ecs.ComponentKey[
  EnvironmentMapLightComponent,
] = ecs_key_environment_map_light

///|
pub let ecs_key_generated_environment_map_light_component : @ecs.ComponentKey[
  GeneratedEnvironmentMapLightComponent,
] = ecs_key_generated_environment_map_light

///|
pub let ecs_key_irradiance_volume_component : @ecs.ComponentKey[
  IrradianceVolumeComponent,
] = ecs_key_irradiance_volume

///|
pub let ecs_key_parallax_correction_component : @ecs.ComponentKey[
  ParallaxCorrectionComponent,
] = ecs_key_parallax_correction

///|
pub let ecs_key_skybox_component : @ecs.ComponentKey[SkyboxComponent] = ecs_key_skybox

///|
/// Camera skybox settings aligned with Bevy's `bevy_light::Skybox`.
pub struct Skybox {
  image : @asset.Handle[@asset.Image]?
  brightness : Float
  rotation : @math.Quat
} derive(ToJson, FromJson)

///|
pub fn Skybox::Skybox() -> Skybox {
  Skybox::{ image: None, brightness: 0.0F, rotation: @math.Quat::identity() }
}

///|
pub fn Skybox::new(
  image : @asset.Handle[@asset.Image],
  brightness : Float,
) -> Skybox {
  Skybox::{
    ..Skybox(),
    image: Some(image),
    brightness: light_sanitize_non_negative(brightness),
  }
}

///|
pub fn Skybox::with_image(
  self : Skybox,
  image : @asset.Handle[@asset.Image]?,
) -> Skybox {
  Skybox::{ ..self, image, }
}

///|
pub fn Skybox::with_brightness(self : Skybox, brightness : Float) -> Skybox {
  Skybox::{ ..self, brightness: light_sanitize_non_negative(brightness) }
}

///|
pub fn Skybox::with_rotation(self : Skybox, rotation : @math.Quat) -> Skybox {
  Skybox::{ ..self, rotation, }
}

///|
pub let ecs_key_skybox : @ecs.ComponentKey[Skybox] = @ecs.register_component(
  debug_name="mgstudio_light::Skybox",
)

///|
pub impl @ecs.Component for Skybox with fn component() {
  ecs_key_skybox
}

///|
// Bevy source: `bevy/crates/bevy_light/src/probe.rs::automatically_add_parallax_correction_components`.
pub fn automatically_add_parallax_correction_components(
  commands : @app.Commands,
  reflection_probe_query : @ecs.Query[
    @core.Entity,
    (
      @ecs.With[EnvironmentMapLight],
      @ecs.With[LightProbe],
      @ecs.Without[ParallaxCorrection],
    ),
  ],
) -> Unit {
  try! reflection_probe_query.view(fn(_query_entity, entity) {
    commands.entity(entity).insert_component(ParallaxCorrection::default())
  })
}
