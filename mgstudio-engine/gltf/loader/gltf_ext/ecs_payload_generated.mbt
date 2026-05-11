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
  EcsPayload_gltf_loader_gltf_ext_GltfExtras(GltfExtras)
  EcsPayload_gltf_loader_gltf_ext_GltfSceneExtras(GltfSceneExtras)
  EcsPayload_gltf_loader_gltf_ext_GltfMeshExtras(GltfMeshExtras)
  EcsPayload_gltf_loader_gltf_ext_GltfMaterialExtras(GltfMaterialExtras)
  EcsPayload_gltf_loader_gltf_ext_GltfMaterialName(GltfMaterialName)
  EcsPayload_gltf_loader_gltf_ext_GltfSceneIndex(GltfSceneIndex)
  EcsPayload_gltf_loader_gltf_ext_GltfNodeIndex(GltfNodeIndex)
  EcsPayload_gltf_loader_gltf_ext_GltfMeshIndex(GltfMeshIndex)
  EcsPayload_gltf_loader_gltf_ext_GltfPrimitiveIndex(GltfPrimitiveIndex)
  EcsPayload_gltf_loader_gltf_ext_GltfSkinIndex(GltfSkinIndex)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfExtras with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfExtras(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfExtras with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfExtras(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfSceneExtras with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfSceneExtras(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfSceneExtras with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfSceneExtras(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMeshExtras with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfMeshExtras(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMeshExtras with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfMeshExtras(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMaterialExtras with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfMaterialExtras(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMaterialExtras with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfMaterialExtras(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMaterialName with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfMaterialName(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMaterialName with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfMaterialName(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfSceneIndex with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfSceneIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfSceneIndex with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfSceneIndex(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfNodeIndex with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfNodeIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfNodeIndex with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfNodeIndex(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMeshIndex with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfMeshIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfMeshIndex with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfMeshIndex(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfPrimitiveIndex with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfPrimitiveIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfPrimitiveIndex with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfPrimitiveIndex(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GltfSkinIndex with to_ecs_payload(self) {
  EcsPayload_gltf_loader_gltf_ext_GltfSkinIndex(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GltfSkinIndex with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gltf_loader_gltf_ext_GltfSkinIndex(value) => Some(value)
    _ => None
  }
}
