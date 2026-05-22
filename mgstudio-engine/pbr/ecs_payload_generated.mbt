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
  EcsPayload_pbr_ViewContactShadowsUniformOffset(
    ViewContactShadowsUniformOffset
  )
  EcsPayload_pbr_ContactShadowsBuffer(ContactShadowsBuffer)
  EcsPayload_pbr_WireframeConfig(WireframeConfig)
  EcsPayload_pbr_MaterialsPluginState(MaterialsPluginState)
  EcsPayload_pbr_Skybox(Skybox)
  EcsPayload_pbr_Camera3d(Camera3d)
  EcsPayload_pbr_CameraDecalConfig3d(CameraDecalConfig3d)
  EcsPayload_pbr_CameraDeferredConfig3d(CameraDeferredConfig3d)
  EcsPayload_pbr_DistanceFog(DistanceFog)
  EcsPayload_pbr_AutoExposure(AutoExposure)
  EcsPayload_pbr_DepthOfField(DepthOfField)
  EcsPayload_pbr_Exposure(Exposure)
  EcsPayload_pbr_Wireframe(Wireframe)
  EcsPayload_pbr_FreeCamera(FreeCamera)
  EcsPayload_pbr_NoWireframe(NoWireframe)
  EcsPayload_pbr_ContactShadows(ContactShadows)
  EcsPayload_pbr_WireframeColor(WireframeColor)
  EcsPayload_pbr_FreeCameraState(FreeCameraState)
  EcsPayload_pbr_NotShadowCaster(NotShadowCaster)
  EcsPayload_pbr_OcclusionCulling(OcclusionCulling)
  EcsPayload_pbr_NoIndirectDrawing(NoIndirectDrawing)
  EcsPayload_pbr_NotShadowReceiver(NotShadowReceiver)
  EcsPayload_pbr_Projection(Projection)
  EcsPayload_pbr_ShadowFilteringMethod(ShadowFilteringMethod)
  EcsPayload_pbr_TransmittedShadowReceiver(TransmittedShadowReceiver)
  EcsPayload_pbr_OrderIndependentTransparencySettings(
    OrderIndependentTransparencySettings
  )
  EcsPayload_pbr_Render3dInternalAssetsState(Render3dInternalAssetsState)
  EcsPayload_pbr_PbrPluginRuntimeConfig(PbrPluginRuntimeConfig)
  EcsPayload_pbr_ScatteringMediumSampler(ScatteringMediumSampler)
  EcsPayload_pbr_ScatteringMediumPluginState(ScatteringMediumPluginState)
  EcsPayload_pbr_AutoExposureCompensationCurve(AutoExposureCompensationCurve)
  EcsPayload_pbr_MeshRenderPluginState(MeshRenderPluginState)
  EcsPayload_pbr_StandardMaterialPluginState(StandardMaterialPluginState)
  EcsPayload_pbr_RenderMaterialInstances(RenderMaterialInstances)
  EcsPayload_pbr_EntitySpecializationTicks(EntitySpecializationTicks)
  EcsPayload_pbr_SpecializedMaterialPipelineCache(
    SpecializedMaterialPipelineCache
  )
  EcsPayload_pbr_MaterialBindGroupAllocators(MaterialBindGroupAllocators)
}

///|
pub impl @ecs.EcsPayloadCodec for ViewContactShadowsUniformOffset with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_ViewContactShadowsUniformOffset(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ViewContactShadowsUniformOffset with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_ViewContactShadowsUniformOffset(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ContactShadowsBuffer with to_ecs_payload(self) {
  EcsPayload_pbr_ContactShadowsBuffer(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ContactShadowsBuffer with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_ContactShadowsBuffer(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WireframeConfig with to_ecs_payload(self) {
  EcsPayload_pbr_WireframeConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WireframeConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_WireframeConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MaterialsPluginState with to_ecs_payload(self) {
  EcsPayload_pbr_MaterialsPluginState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MaterialsPluginState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_MaterialsPluginState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Skybox with to_ecs_payload(self) {
  EcsPayload_pbr_Skybox(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Skybox with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_Skybox(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Camera3d with to_ecs_payload(self) {
  EcsPayload_pbr_Camera3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Camera3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_Camera3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CameraDecalConfig3d with to_ecs_payload(self) {
  EcsPayload_pbr_CameraDecalConfig3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CameraDecalConfig3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_CameraDecalConfig3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CameraDeferredConfig3d with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_CameraDeferredConfig3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CameraDeferredConfig3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_CameraDeferredConfig3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DistanceFog with to_ecs_payload(self) {
  EcsPayload_pbr_DistanceFog(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DistanceFog with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_DistanceFog(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AutoExposure with to_ecs_payload(self) {
  EcsPayload_pbr_AutoExposure(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AutoExposure with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_AutoExposure(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DepthOfField with to_ecs_payload(self) {
  EcsPayload_pbr_DepthOfField(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DepthOfField with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_DepthOfField(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Exposure with to_ecs_payload(self) {
  EcsPayload_pbr_Exposure(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Exposure with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_Exposure(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe with to_ecs_payload(self) {
  EcsPayload_pbr_Wireframe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_Wireframe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCamera with to_ecs_payload(self) {
  EcsPayload_pbr_FreeCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_FreeCamera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NoWireframe with to_ecs_payload(self) {
  EcsPayload_pbr_NoWireframe(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NoWireframe with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_NoWireframe(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ContactShadows with to_ecs_payload(self) {
  EcsPayload_pbr_ContactShadows(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ContactShadows with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_ContactShadows(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for WireframeColor with to_ecs_payload(self) {
  EcsPayload_pbr_WireframeColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for WireframeColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_WireframeColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCameraState with to_ecs_payload(self) {
  EcsPayload_pbr_FreeCameraState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCameraState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_FreeCameraState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NotShadowCaster with to_ecs_payload(self) {
  EcsPayload_pbr_NotShadowCaster(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NotShadowCaster with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_NotShadowCaster(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for OcclusionCulling with to_ecs_payload(self) {
  EcsPayload_pbr_OcclusionCulling(self)
}

///|
pub impl @ecs.EcsPayloadCodec for OcclusionCulling with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_OcclusionCulling(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NoIndirectDrawing with to_ecs_payload(self) {
  EcsPayload_pbr_NoIndirectDrawing(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NoIndirectDrawing with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_NoIndirectDrawing(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NotShadowReceiver with to_ecs_payload(self) {
  EcsPayload_pbr_NotShadowReceiver(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NotShadowReceiver with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_NotShadowReceiver(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Projection with to_ecs_payload(self) {
  EcsPayload_pbr_Projection(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Projection with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_Projection(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ShadowFilteringMethod with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_ShadowFilteringMethod(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ShadowFilteringMethod with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_ShadowFilteringMethod(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TransmittedShadowReceiver with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_TransmittedShadowReceiver(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TransmittedShadowReceiver with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_TransmittedShadowReceiver(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for OrderIndependentTransparencySettings with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_OrderIndependentTransparencySettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for OrderIndependentTransparencySettings with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_OrderIndependentTransparencySettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dInternalAssetsState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_Render3dInternalAssetsState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dInternalAssetsState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_Render3dInternalAssetsState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PbrPluginRuntimeConfig with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_PbrPluginRuntimeConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PbrPluginRuntimeConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_PbrPluginRuntimeConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScatteringMediumSampler with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_ScatteringMediumSampler(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScatteringMediumSampler with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_ScatteringMediumSampler(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScatteringMediumPluginState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_ScatteringMediumPluginState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScatteringMediumPluginState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_ScatteringMediumPluginState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for AutoExposureCompensationCurve with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_AutoExposureCompensationCurve(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AutoExposureCompensationCurve with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_AutoExposureCompensationCurve(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshRenderPluginState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_MeshRenderPluginState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshRenderPluginState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_MeshRenderPluginState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for StandardMaterialPluginState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_StandardMaterialPluginState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for StandardMaterialPluginState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_StandardMaterialPluginState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderMaterialInstances with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_RenderMaterialInstances(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderMaterialInstances with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_RenderMaterialInstances(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for EntitySpecializationTicks with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_EntitySpecializationTicks(self)
}

///|
pub impl @ecs.EcsPayloadCodec for EntitySpecializationTicks with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_EntitySpecializationTicks(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpecializedMaterialPipelineCache with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_SpecializedMaterialPipelineCache(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpecializedMaterialPipelineCache with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_SpecializedMaterialPipelineCache(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MaterialBindGroupAllocators with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_MaterialBindGroupAllocators(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MaterialBindGroupAllocators with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_MaterialBindGroupAllocators(value) => Some(value)
    _ => None
  }
}
