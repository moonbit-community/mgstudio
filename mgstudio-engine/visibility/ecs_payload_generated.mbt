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
  EcsPayload_visibility_Visibility(Visibility)
  EcsPayload_visibility_InheritedVisibility(InheritedVisibility)
  EcsPayload_visibility_ViewVisibility(ViewVisibility)
  EcsPayload_visibility_NoFrustumCulling(NoFrustumCulling)
  EcsPayload_visibility_NoAutoAabb(NoAutoAabb)
  EcsPayload_visibility_NoCpuCulling(NoCpuCulling)
  EcsPayload_visibility_VisibilityRange(VisibilityRange)
}

///|
pub impl @ecs.EcsPayloadCodec for Visibility with to_ecs_payload(self) {
  EcsPayload_visibility_Visibility(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Visibility with from_ecs_payload(payload) {
  match payload {
    EcsPayload_visibility_Visibility(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for InheritedVisibility with to_ecs_payload(self) {
  EcsPayload_visibility_InheritedVisibility(self)
}

///|
pub impl @ecs.EcsPayloadCodec for InheritedVisibility with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_visibility_InheritedVisibility(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ViewVisibility with to_ecs_payload(self) {
  EcsPayload_visibility_ViewVisibility(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ViewVisibility with from_ecs_payload(payload) {
  match payload {
    EcsPayload_visibility_ViewVisibility(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NoFrustumCulling with to_ecs_payload(self) {
  EcsPayload_visibility_NoFrustumCulling(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NoFrustumCulling with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_visibility_NoFrustumCulling(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NoAutoAabb with to_ecs_payload(self) {
  EcsPayload_visibility_NoAutoAabb(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NoAutoAabb with from_ecs_payload(payload) {
  match payload {
    EcsPayload_visibility_NoAutoAabb(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NoCpuCulling with to_ecs_payload(self) {
  EcsPayload_visibility_NoCpuCulling(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NoCpuCulling with from_ecs_payload(payload) {
  match payload {
    EcsPayload_visibility_NoCpuCulling(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for VisibilityRange with to_ecs_payload(self) {
  EcsPayload_visibility_VisibilityRange(self)
}

///|
pub impl @ecs.EcsPayloadCodec for VisibilityRange with from_ecs_payload(payload) {
  match payload {
    EcsPayload_visibility_VisibilityRange(value) => Some(value)
    _ => None
  }
}
