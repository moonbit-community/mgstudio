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
  EcsPayload_gizmos_GizmoMeshConfig(GizmoMeshConfig)
  EcsPayload_gizmos_Gizmo(Gizmo)
  EcsPayload_gizmos_ShowSkinnedMeshBoundsGizmo(ShowSkinnedMeshBoundsGizmo)
  EcsPayload_gizmos_ShowAabbGizmo(ShowAabbGizmo)
  EcsPayload_gizmos_GizmoPluginMarker(GizmoPluginMarker)
  EcsPayload_gizmos_ShowFrustumGizmo(ShowFrustumGizmo)
  EcsPayload_gizmos_GizmoAsset(GizmoAsset)
}

///|
pub impl @ecs.EcsPayloadCodec for GizmoMeshConfig with to_ecs_payload(self) {
  EcsPayload_gizmos_GizmoMeshConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GizmoMeshConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gizmos_GizmoMeshConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Gizmo with to_ecs_payload(self) {
  EcsPayload_gizmos_Gizmo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Gizmo with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gizmos_Gizmo(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ShowSkinnedMeshBoundsGizmo with to_ecs_payload(
  self,
) {
  EcsPayload_gizmos_ShowSkinnedMeshBoundsGizmo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ShowSkinnedMeshBoundsGizmo with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_gizmos_ShowSkinnedMeshBoundsGizmo(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ShowAabbGizmo with to_ecs_payload(self) {
  EcsPayload_gizmos_ShowAabbGizmo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ShowAabbGizmo with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gizmos_ShowAabbGizmo(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for GizmoPluginMarker with to_ecs_payload(self) {
  EcsPayload_gizmos_GizmoPluginMarker(self)
}

///|
impl @ecs.EcsPayloadCodec for GizmoPluginMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gizmos_GizmoPluginMarker(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ShowFrustumGizmo with to_ecs_payload(self) {
  EcsPayload_gizmos_ShowFrustumGizmo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ShowFrustumGizmo with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_gizmos_ShowFrustumGizmo(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GizmoAsset with to_ecs_payload(self) {
  EcsPayload_gizmos_GizmoAsset(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GizmoAsset with from_ecs_payload(payload) {
  match payload {
    EcsPayload_gizmos_GizmoAsset(value) => Some(value)
    _ => None
  }
}
