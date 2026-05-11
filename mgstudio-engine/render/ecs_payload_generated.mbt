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
  EcsPayload_render_CurrentView(CurrentView)
  EcsPayload_render_RenderAppChannels(RenderAppChannels)
  EcsPayload_render_SortedCameras(SortedCameras)
  EcsPayload_render_RenderPluginMarker(RenderPluginMarker)
  EcsPayload_render_RenderMainWorld(RenderMainWorld)
  EcsPayload_render_SyncToRenderWorld(SyncToRenderWorld)
  EcsPayload_render_RenderEntity(RenderEntity)
  EcsPayload_render_MainEntity(MainEntity)
  EcsPayload_render_TemporaryRenderEntity(TemporaryRenderEntity)
  EcsPayload_render_PendingSyncEntity(PendingSyncEntity)
  EcsPayload_render_RenderState(RenderState)
  EcsPayload_render_RenderAssets(RenderAssetsPayload)
  EcsPayload_render_PrepareNextFrameAssets(PrepareNextFrameAssetsPayload)
  EcsPayload_render_ErasedRenderAssets(ErasedRenderAssetsPayload)
  EcsPayload_render_ErasedPrepareNextFrameAssets(
    ErasedPrepareNextFrameAssetsPayload
  )
  EcsPayload_render_GpuComponentArrayBufferState(
    GpuComponentArrayBufferStatePayload
  )
}

///|
pub impl @ecs.EcsPayloadCodec for CurrentView with to_ecs_payload(self) {
  EcsPayload_render_CurrentView(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CurrentView with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_CurrentView(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAppChannels with to_ecs_payload(self) {
  EcsPayload_render_RenderAppChannels(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderAppChannels with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_RenderAppChannels(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SortedCameras with to_ecs_payload(self) {
  EcsPayload_render_SortedCameras(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SortedCameras with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_SortedCameras(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for RenderPluginMarker with to_ecs_payload(self) {
  EcsPayload_render_RenderPluginMarker(self)
}

///|
impl @ecs.EcsPayloadCodec for RenderPluginMarker with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_RenderPluginMarker(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for RenderMainWorld with to_ecs_payload(self) {
  EcsPayload_render_RenderMainWorld(self)
}

///|
impl @ecs.EcsPayloadCodec for RenderMainWorld with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_RenderMainWorld(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SyncToRenderWorld with to_ecs_payload(self) {
  EcsPayload_render_SyncToRenderWorld(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SyncToRenderWorld with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_SyncToRenderWorld(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderEntity with to_ecs_payload(self) {
  EcsPayload_render_RenderEntity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderEntity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_RenderEntity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for MainEntity with to_ecs_payload(self) {
  EcsPayload_render_MainEntity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for MainEntity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_MainEntity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TemporaryRenderEntity with to_ecs_payload(
  self,
) {
  EcsPayload_render_TemporaryRenderEntity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TemporaryRenderEntity with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_TemporaryRenderEntity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PendingSyncEntity with to_ecs_payload(self) {
  EcsPayload_render_PendingSyncEntity(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PendingSyncEntity with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_PendingSyncEntity(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderState with to_ecs_payload(self) {
  EcsPayload_render_RenderState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_RenderState(value) => Some(value)
    _ => None
  }
}

///|
pub(all) struct RenderAssetsPayload {
  items : Array[(Int, @ecs.EcsPayload)]
}

///|
pub(all) struct PrepareNextFrameAssetsPayload {
  values : Array[(Int, @ecs.EcsPayload)]
}

///|
pub(all) struct ErasedRenderAssetsPayload {
  items : Array[(UntypedRenderAssetId, @ecs.EcsPayload)]
}

///|
pub(all) struct ErasedPrepareNextFrameAssetsPayload {
  values : Array[(UntypedRenderAssetId, @ecs.EcsPayload)]
}

///|
pub(all) struct GpuComponentArrayBufferStatePayload {
  buffer : @ecs.EcsPayload
  indices : Map[UInt64, UInt]
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for RenderAssets[A] with to_ecs_payload(
  self,
) {
  let items : Array[(Int, @ecs.EcsPayload)] = []
  for entry in self.to_array() {
    items.push((entry.0, A::to_ecs_payload(entry.1.val)))
  }
  EcsPayload_render_RenderAssets(RenderAssetsPayload::{ items, })
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for RenderAssets[A] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_render_RenderAssets(value) => {
      let assets : RenderAssets[A] = RenderAssets::new()
      for entry in value.items {
        match A::from_ecs_payload(entry.1) {
          Some(item) => assets.insert(entry.0, item)
          None => return None
        }
      }
      Some(assets)
    }
    _ => None
  }
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for PrepareNextFrameAssets[
  A,
] with to_ecs_payload(self) {
  let values : Array[(Int, @ecs.EcsPayload)] = []
  for entry in self.values {
    values.push((entry.0, A::to_ecs_payload(entry.1)))
  }
  EcsPayload_render_PrepareNextFrameAssets(PrepareNextFrameAssetsPayload::{
    values,
  })
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for PrepareNextFrameAssets[
  A,
] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_PrepareNextFrameAssets(value) => {
      let assets : PrepareNextFrameAssets[A] = PrepareNextFrameAssets::new()
      for entry in value.values {
        match A::from_ecs_payload(entry.1) {
          Some(item) => assets.push(entry.0, item)
          None => return None
        }
      }
      Some(assets)
    }
    _ => None
  }
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for ErasedRenderAssets[
  A,
] with to_ecs_payload(self) {
  let items : Array[(UntypedRenderAssetId, @ecs.EcsPayload)] = []
  for entry in self.to_array() {
    items.push((entry.0, A::to_ecs_payload(entry.1.val)))
  }
  EcsPayload_render_ErasedRenderAssets(ErasedRenderAssetsPayload::{ items, })
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for ErasedRenderAssets[
  A,
] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_ErasedRenderAssets(value) => {
      let assets : ErasedRenderAssets[A] = ErasedRenderAssets::new()
      for entry in value.items {
        match A::from_ecs_payload(entry.1) {
          Some(item) => assets.insert(entry.0, item)
          None => return None
        }
      }
      Some(assets)
    }
    _ => None
  }
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for ErasedPrepareNextFrameAssets[
  A,
] with to_ecs_payload(self) {
  let values : Array[(UntypedRenderAssetId, @ecs.EcsPayload)] = []
  for entry in self.values {
    values.push((entry.0, A::to_ecs_payload(entry.1)))
  }
  EcsPayload_render_ErasedPrepareNextFrameAssets(ErasedPrepareNextFrameAssetsPayload::{
    values,
  })
}

///|
pub impl[A : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for ErasedPrepareNextFrameAssets[
  A,
] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_ErasedPrepareNextFrameAssets(value) => {
      let assets : ErasedPrepareNextFrameAssets[A] = ErasedPrepareNextFrameAssets::new()
      for entry in value.values {
        match A::from_ecs_payload(entry.1) {
          Some(item) => assets.push(entry.0, item)
          None => return None
        }
      }
      Some(assets)
    }
    _ => None
  }
}

///|
pub impl[C : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for GpuComponentArrayBufferState[
  C,
] with to_ecs_payload(self) {
  EcsPayload_render_GpuComponentArrayBufferState(GpuComponentArrayBufferStatePayload::{
    buffer: @render_resource.GpuArrayBuffer::to_ecs_payload(self.buffer),
    indices: self.indices,
  })
}

///|
pub impl[C : @ecs.EcsPayloadCodec] @ecs.EcsPayloadCodec for GpuComponentArrayBufferState[
  C,
] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_render_GpuComponentArrayBufferState(value) =>
      match @render_resource.GpuArrayBuffer::from_ecs_payload(value.buffer) {
        Some(buffer) =>
          Some(GpuComponentArrayBufferState::{ buffer, indices: value.indices })
        None => None
      }
    _ => None
  }
}
