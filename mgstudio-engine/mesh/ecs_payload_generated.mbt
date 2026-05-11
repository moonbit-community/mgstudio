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
  EcsPayload_mesh_Mesh(Mesh)
  EcsPayload_mesh_Mesh2d(Mesh2d)
  EcsPayload_mesh_Mesh3d(Mesh3d)
  EcsPayload_mesh_MeshTag(MeshTag)
  EcsPayload_mesh_SkinnedMeshInverseBindposes(SkinnedMeshInverseBindposes)
  EcsPayload_mesh_SkinnedMesh(SkinnedMesh)
  EcsPayload_mesh_MorphTargetMesh(MorphTargetMesh)
  EcsPayload_mesh_MorphWeights(MorphWeights)
  EcsPayload_mesh_DynamicSkinnedMeshBounds(DynamicSkinnedMeshBounds)
}

///|
pub impl @ecs.EcsPayloadCodec for Mesh with to_ecs_payload(self) {
  EcsPayload_mesh_Mesh(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Mesh with from_ecs_payload(payload) {
  match payload {
    EcsPayload_mesh_Mesh(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Mesh2d with to_ecs_payload(self) {
  EcsPayload_mesh_Mesh2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Mesh2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_mesh_Mesh2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Mesh3d with to_ecs_payload(self) {
  EcsPayload_mesh_Mesh3d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Mesh3d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_mesh_Mesh3d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MeshTag with to_ecs_payload(self) {
  EcsPayload_mesh_MeshTag(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MeshTag with from_ecs_payload(payload) {
  match payload {
    EcsPayload_mesh_MeshTag(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SkinnedMeshInverseBindposes with to_ecs_payload(
  self,
) {
  EcsPayload_mesh_SkinnedMeshInverseBindposes(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SkinnedMeshInverseBindposes with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_mesh_SkinnedMeshInverseBindposes(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SkinnedMesh with to_ecs_payload(self) {
  EcsPayload_mesh_SkinnedMesh(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SkinnedMesh with from_ecs_payload(payload) {
  match payload {
    EcsPayload_mesh_SkinnedMesh(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MorphTargetMesh with to_ecs_payload(self) {
  EcsPayload_mesh_MorphTargetMesh(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MorphTargetMesh with from_ecs_payload(payload) {
  match payload {
    EcsPayload_mesh_MorphTargetMesh(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MorphWeights with to_ecs_payload(self) {
  EcsPayload_mesh_MorphWeights(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MorphWeights with from_ecs_payload(payload) {
  match payload {
    EcsPayload_mesh_MorphWeights(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for DynamicSkinnedMeshBounds with to_ecs_payload(
  self,
) {
  EcsPayload_mesh_DynamicSkinnedMeshBounds(self)
}

///|
pub impl @ecs.EcsPayloadCodec for DynamicSkinnedMeshBounds with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_mesh_DynamicSkinnedMeshBounds(value) => Some(value)
    _ => None
  }
}
