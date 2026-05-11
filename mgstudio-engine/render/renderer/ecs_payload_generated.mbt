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
  EcsPayload_renderer_RenderDevice(RenderDevice)
  EcsPayload_renderer_RenderQueue(RenderQueue)
  EcsPayload_renderer_RenderAdapter(RenderAdapter)
  EcsPayload_renderer_RenderInstance(RenderInstance)
  EcsPayload_renderer_RenderAdapterInfo(RenderAdapterInfo)
  EcsPayload_renderer_PendingCommandBuffers(PendingCommandBuffers)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderDevice with to_ecs_payload(self) {
  EcsPayload_renderer_RenderDevice(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderDevice with from_ecs_payload(payload) {
  match payload {
    EcsPayload_renderer_RenderDevice(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderQueue with to_ecs_payload(self) {
  EcsPayload_renderer_RenderQueue(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderQueue with from_ecs_payload(payload) {
  match payload {
    EcsPayload_renderer_RenderQueue(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAdapter with to_ecs_payload(self) {
  EcsPayload_renderer_RenderAdapter(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAdapter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_renderer_RenderAdapter(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderInstance with to_ecs_payload(self) {
  EcsPayload_renderer_RenderInstance(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderInstance with from_ecs_payload(payload) {
  match payload {
    EcsPayload_renderer_RenderInstance(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAdapterInfo with to_ecs_payload(self) {
  EcsPayload_renderer_RenderAdapterInfo(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAdapterInfo with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_renderer_RenderAdapterInfo(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PendingCommandBuffers with to_ecs_payload(
  self,
) {
  EcsPayload_renderer_PendingCommandBuffers(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PendingCommandBuffers with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_renderer_PendingCommandBuffers(value) => Some(value)
    _ => None
  }
}
