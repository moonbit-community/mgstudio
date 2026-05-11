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
  EcsPayload_render_resource_PipelineCache(PipelineCache)
  EcsPayload_render_resource_GpuArrayBuffer(GpuArrayBufferPayload)
  EcsPayload_render_resource_StorageBuffer(StorageBufferPayload)
}

///|
pub(all) struct GpuArrayBufferPayload {
  values : Array[@ecs.EcsPayload]
  buffer_id : BufferId
}

///|
pub(all) struct StorageBufferPayload {
  values : Array[@ecs.EcsPayload]
  buffer_id : BufferId
  label : String?
}

///|
pub impl @ecs.EcsPayloadCodec for PipelineCache with to_ecs_payload(self) {
  EcsPayload_render_resource_PipelineCache(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PipelineCache with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_resource_PipelineCache(value) => Some(value)
    _ => None
  }
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for GpuArrayBuffer[T] with to_ecs_payload(
  self,
) {
  let values : Array[@ecs.EcsPayload] = []
  for value in self.values {
    values.push(T::to_ecs_payload(value))
  }
  EcsPayload_render_resource_GpuArrayBuffer(GpuArrayBufferPayload::{
    values,
    buffer_id: self.buffer_id,
  })
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for GpuArrayBuffer[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_resource_GpuArrayBuffer(value) => {
      let buffer : GpuArrayBuffer[T] = GpuArrayBuffer::{
        values: [],
        buffer_id: value.buffer_id,
      }
      for item_payload in value.values {
        match T::from_ecs_payload(item_payload) {
          Some(item) => buffer.values.push(item)
          None => return None
        }
      }
      Some(buffer)
    }
    _ => None
  }
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for StorageBuffer[T] with to_ecs_payload(
  self,
) {
  let values : Array[@ecs.EcsPayload] = []
  for value in self.data.values() {
    values.push(T::to_ecs_payload(value))
  }
  EcsPayload_render_resource_StorageBuffer(StorageBufferPayload::{
    values,
    buffer_id: self.data.buffer_id(),
    label: self.label,
  })
}

///|
pub impl[T : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for StorageBuffer[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_resource_StorageBuffer(value) => {
      let data : BufferVec[T] = BufferVec::with_buffer_id(value.buffer_id)
      for item_payload in value.values {
        match T::from_ecs_payload(item_payload) {
          Some(item) => data.push(item)
          None => return None
        }
      }
      Some(StorageBuffer::{ data, label: value.label })
    }
    _ => None
  }
}
