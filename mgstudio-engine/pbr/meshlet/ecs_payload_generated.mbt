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
  EcsPayload_pbr_meshlet_MeshletViewMaterialsMainOpaquePass(
    MeshletViewMaterialsMainOpaquePass
  )
  EcsPayload_pbr_meshlet_MeshletViewMaterialsPrepass(
    MeshletViewMaterialsPrepass
  )
  EcsPayload_pbr_meshlet_MeshletViewMaterialsDeferredGBufferPrepass(
    MeshletViewMaterialsDeferredGBufferPrepass
  )
  EcsPayload_pbr_meshlet_MeshletMesh3d(MeshletMesh3d)
  EcsPayload_pbr_meshlet_MeshletPluginMarker(MeshletPluginMarker)
  EcsPayload_pbr_meshlet_MeshletPluginState(MeshletPluginState)
  EcsPayload_pbr_meshlet_InstanceManager(InstanceManager)
  EcsPayload_pbr_meshlet_ResourceManager(ResourceManager)
  EcsPayload_pbr_meshlet_MeshletPipelines(MeshletPipelines)
  EcsPayload_pbr_meshlet_MeshletMeshManager(MeshletMeshManager)
  EcsPayload_pbr_meshlet_MeshletVisibilityBufferRasterState(
    MeshletVisibilityBufferRasterState
  )
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletViewMaterialsMainOpaquePass with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_meshlet_MeshletViewMaterialsMainOpaquePass(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletViewMaterialsMainOpaquePass with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletViewMaterialsMainOpaquePass(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletViewMaterialsPrepass with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_meshlet_MeshletViewMaterialsPrepass(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletViewMaterialsPrepass with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletViewMaterialsPrepass(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletViewMaterialsDeferredGBufferPrepass with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_meshlet_MeshletViewMaterialsDeferredGBufferPrepass(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletViewMaterialsDeferredGBufferPrepass with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletViewMaterialsDeferredGBufferPrepass(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletMesh3d with to_ecs_payload(self) {
  EcsPayload_pbr_meshlet_MeshletMesh3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletMesh3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletMesh3d(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MeshletPluginMarker with to_ecs_payload(self) {
  EcsPayload_pbr_meshlet_MeshletPluginMarker(self)
}

///|
impl @ecs.EcsPayloadCodec for MeshletPluginMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletPluginMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletPluginState with to_ecs_payload(self) {
  EcsPayload_pbr_meshlet_MeshletPluginState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletPluginState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletPluginState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for InstanceManager with to_ecs_payload(self) {
  EcsPayload_pbr_meshlet_InstanceManager(self)
}

///|
pub impl @ecs.EcsPayloadCodec for InstanceManager with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_meshlet_InstanceManager(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ResourceManager with to_ecs_payload(self) {
  EcsPayload_pbr_meshlet_ResourceManager(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ResourceManager with from_ecs_payload(payload) {
  match payload {
    EcsPayload_pbr_meshlet_ResourceManager(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletPipelines with to_ecs_payload(self) {
  EcsPayload_pbr_meshlet_MeshletPipelines(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletPipelines with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletPipelines(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletMeshManager with to_ecs_payload(self) {
  EcsPayload_pbr_meshlet_MeshletMeshManager(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletMeshManager with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletMeshManager(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletVisibilityBufferRasterState with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_meshlet_MeshletVisibilityBufferRasterState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshletVisibilityBufferRasterState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_meshlet_MeshletVisibilityBufferRasterState(value) =>
      Some(value)
    _ => None
  }
}

///|
