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
extenum @ecs.EcsPayload += {
  EcsPayload_light_ShowLightGizmo(ShowLightGizmo)
  EcsPayload_light_PointLight(PointLight)
  EcsPayload_light_PointLightTexture(PointLightTexture)
  EcsPayload_light_SpotLight(SpotLight)
  EcsPayload_light_SpotLightTexture(SpotLightTexture)
  EcsPayload_light_DirectionalLight(DirectionalLight)
  EcsPayload_light_RectLight(RectLight)
  EcsPayload_light_SunDisk(SunDisk)
  EcsPayload_light_VolumetricLight(VolumetricLight)
  EcsPayload_light_VolumetricFog(VolumetricFog)
  EcsPayload_light_Atmosphere(Atmosphere)
  EcsPayload_light_AtmosphereSettings(AtmosphereSettings)
  EcsPayload_light_FogVolume(FogVolume)
  EcsPayload_light_ScatteringMedium(ScatteringMedium)
  EcsPayload_light_DirectionalLightTexture(DirectionalLightTexture)
  EcsPayload_light_LightProbe(LightProbe)
  EcsPayload_light_IrradianceVolume(IrradianceVolume)
  EcsPayload_light_ClusteredDecal(ClusteredDecal)
  EcsPayload_light_ParallaxCorrection(ParallaxCorrection)
  EcsPayload_light_EnvironmentMapLight(EnvironmentMapLight)
  EcsPayload_light_GeneratedEnvironmentMapLight(GeneratedEnvironmentMapLight)
  EcsPayload_light_AtmosphereEnvironmentMapLight(AtmosphereEnvironmentMapLight)
  EcsPayload_light_GlobalAmbientLight(GlobalAmbientLight)
  EcsPayload_light_PointLightShadowMap(PointLightShadowMap)
  EcsPayload_light_DirectionalLightShadowMap(DirectionalLightShadowMap)
}

///|
pub impl @ecs.EcsPayloadCodec for ShowLightGizmo with to_ecs_payload(self) {
  EcsPayload_light_ShowLightGizmo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ShowLightGizmo with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_ShowLightGizmo(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointLight with to_ecs_payload(self) {
  EcsPayload_light_PointLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointLight with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_PointLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointLightTexture with to_ecs_payload(self) {
  EcsPayload_light_PointLightTexture(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointLightTexture with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_PointLightTexture(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpotLight with to_ecs_payload(self) {
  EcsPayload_light_SpotLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpotLight with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_SpotLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpotLightTexture with to_ecs_payload(self) {
  EcsPayload_light_SpotLightTexture(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpotLightTexture with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_SpotLightTexture(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalLight with to_ecs_payload(self) {
  EcsPayload_light_DirectionalLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalLight with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_DirectionalLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RectLight with to_ecs_payload(self) {
  EcsPayload_light_RectLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RectLight with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_RectLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SunDisk with to_ecs_payload(self) {
  EcsPayload_light_SunDisk(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SunDisk with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_SunDisk(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for VolumetricLight with to_ecs_payload(self) {
  EcsPayload_light_VolumetricLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for VolumetricLight with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_VolumetricLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for VolumetricFog with to_ecs_payload(self) {
  EcsPayload_light_VolumetricFog(self)
}

///|
pub impl @ecs.EcsPayloadCodec for VolumetricFog with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_VolumetricFog(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Atmosphere with to_ecs_payload(self) {
  EcsPayload_light_Atmosphere(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Atmosphere with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_Atmosphere(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AtmosphereSettings with to_ecs_payload(self) {
  EcsPayload_light_AtmosphereSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AtmosphereSettings with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_AtmosphereSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FogVolume with to_ecs_payload(self) {
  EcsPayload_light_FogVolume(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FogVolume with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_FogVolume(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScatteringMedium with to_ecs_payload(self) {
  EcsPayload_light_ScatteringMedium(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScatteringMedium with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_ScatteringMedium(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalLightTexture with to_ecs_payload(
  self,
) {
  EcsPayload_light_DirectionalLightTexture(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalLightTexture with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_DirectionalLightTexture(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LightProbe with to_ecs_payload(self) {
  EcsPayload_light_LightProbe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LightProbe with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_LightProbe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for IrradianceVolume with to_ecs_payload(self) {
  EcsPayload_light_IrradianceVolume(self)
}

///|
pub impl @ecs.EcsPayloadCodec for IrradianceVolume with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_IrradianceVolume(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ClusteredDecal with to_ecs_payload(self) {
  EcsPayload_light_ClusteredDecal(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ClusteredDecal with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_ClusteredDecal(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ParallaxCorrection with to_ecs_payload(self) {
  EcsPayload_light_ParallaxCorrection(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ParallaxCorrection with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_ParallaxCorrection(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for EnvironmentMapLight with to_ecs_payload(self) {
  EcsPayload_light_EnvironmentMapLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for EnvironmentMapLight with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_EnvironmentMapLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GeneratedEnvironmentMapLight with to_ecs_payload(
  self,
) {
  EcsPayload_light_GeneratedEnvironmentMapLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GeneratedEnvironmentMapLight with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_GeneratedEnvironmentMapLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AtmosphereEnvironmentMapLight with to_ecs_payload(
  self,
) {
  EcsPayload_light_AtmosphereEnvironmentMapLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AtmosphereEnvironmentMapLight with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_AtmosphereEnvironmentMapLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalAmbientLight with to_ecs_payload(self) {
  EcsPayload_light_GlobalAmbientLight(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalAmbientLight with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_GlobalAmbientLight(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PointLightShadowMap with to_ecs_payload(self) {
  EcsPayload_light_PointLightShadowMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PointLightShadowMap with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_PointLightShadowMap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalLightShadowMap with to_ecs_payload(
  self,
) {
  EcsPayload_light_DirectionalLightShadowMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DirectionalLightShadowMap with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_DirectionalLightShadowMap(value) => Some(value)
    _ => None
  }
}
