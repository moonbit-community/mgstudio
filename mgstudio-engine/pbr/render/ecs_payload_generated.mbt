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
  EcsPayload_pbr_render_PerspectiveProjection3d(PerspectiveProjection3d)
  EcsPayload_pbr_render_OrthographicProjection3d(OrthographicProjection3d)
  EcsPayload_pbr_render_SubCameraView3d(SubCameraView3d)
  EcsPayload_pbr_render_Render3dGpuPreprocessState(Render3dGpuPreprocessState)
  EcsPayload_pbr_render_Render3dDiagnosticsState(Render3dDiagnosticsState)
  EcsPayload_pbr_render_ViewFogUniformOffset(ViewFogUniformOffset)
  EcsPayload_pbr_render_FogMeta(FogMeta)
  EcsPayload_pbr_render_Render3dWorldTransformCache(Render3dWorldTransformCache)
  EcsPayload_pbr_render_MorphIndices(MorphIndices)
  EcsPayload_pbr_render_MorphUniforms(MorphUniforms)
  EcsPayload_pbr_render_Render3dMeshRuntimeState(Render3dMeshRuntimeState)
  EcsPayload_pbr_render_SkinUniforms(SkinUniforms)
  EcsPayload_pbr_render_ProjectionRuntime3d(ProjectionRuntime3d)
  EcsPayload_pbr_render_Frustum(Frustum)
}

///|
pub impl @ecs.EcsPayloadCodec for PerspectiveProjection3d with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_render_PerspectiveProjection3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PerspectiveProjection3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_PerspectiveProjection3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for OrthographicProjection3d with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_render_OrthographicProjection3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for OrthographicProjection3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_OrthographicProjection3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SubCameraView3d with to_ecs_payload(self) {
  EcsPayload_pbr_render_SubCameraView3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SubCameraView3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_render_SubCameraView3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dGpuPreprocessState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_render_Render3dGpuPreprocessState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dGpuPreprocessState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_Render3dGpuPreprocessState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dDiagnosticsState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_render_Render3dDiagnosticsState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dDiagnosticsState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_Render3dDiagnosticsState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ViewFogUniformOffset with to_ecs_payload(self) {
  EcsPayload_pbr_render_ViewFogUniformOffset(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ViewFogUniformOffset with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_ViewFogUniformOffset(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FogMeta with to_ecs_payload(self) {
  EcsPayload_pbr_render_FogMeta(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FogMeta with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_render_FogMeta(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dWorldTransformCache with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_render_Render3dWorldTransformCache(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dWorldTransformCache with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_Render3dWorldTransformCache(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MorphIndices with to_ecs_payload(self) {
  EcsPayload_pbr_render_MorphIndices(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MorphIndices with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_render_MorphIndices(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MorphUniforms with to_ecs_payload(self) {
  EcsPayload_pbr_render_MorphUniforms(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MorphUniforms with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_render_MorphUniforms(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dMeshRuntimeState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_render_Render3dMeshRuntimeState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Render3dMeshRuntimeState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_Render3dMeshRuntimeState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SkinUniforms with to_ecs_payload(self) {
  EcsPayload_pbr_render_SkinUniforms(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SkinUniforms with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_render_SkinUniforms(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ProjectionRuntime3d with to_ecs_payload(self) {
  EcsPayload_pbr_render_ProjectionRuntime3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ProjectionRuntime3d with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_render_ProjectionRuntime3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Frustum with to_ecs_payload(self) {
  EcsPayload_pbr_render_Frustum(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Frustum with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_render_Frustum(value) => Some(value)
    _ => None
  }
}
