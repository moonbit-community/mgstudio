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
  EcsPayload_asset_AssetServer(AssetServer)
  EcsPayload_asset_UntypedAssetLoadFailedEvent(UntypedAssetLoadFailedEvent)
  EcsPayload_asset_Handle(HandlePayload)
  EcsPayload_asset_AssetEvent(AssetEventPayload)
  EcsPayload_asset_Assets(AssetsPayload)
  EcsPayload_asset_AssetLoadFailedEvent(AssetLoadFailedEventPayload)
  EcsPayload_asset_Blob(Blob)
  EcsPayload_asset_Font(Font)
  EcsPayload_asset_LoadedFolder(LoadedFolder)
  EcsPayload_asset_TextureAtlasLayout(TextureAtlasLayout)
  EcsPayload_asset_AssetIoRuntimeState(AssetIoRuntimeState)
  EcsPayload_asset_AssetLoaderRegistryState(AssetLoaderRegistryState)
  EcsPayload_asset_TypedAssetLoaderRegistryState(TypedAssetLoaderRegistryState)
  EcsPayload_asset_AssetSourceBuilderRegistryState(
    AssetSourceBuilderRegistryState
  )
  EcsPayload_asset_AssetProcessorRegistryState(AssetProcessorRegistryState)
}

///|
pub impl @ecs.EcsPayloadCodec for AssetServer with to_ecs_payload(self) {
  EcsPayload_asset_AssetServer(self)
}

///|
pub impl @ecs.EcsPayloadCodec for AssetServer with from_ecs_payload(payload) {
  match payload {
    EcsPayload_asset_AssetServer(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for UntypedAssetLoadFailedEvent with to_ecs_payload(
  self,
) {
  EcsPayload_asset_UntypedAssetLoadFailedEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for UntypedAssetLoadFailedEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_UntypedAssetLoadFailedEvent(value) => Some(value)
    _ => None
  }
}

///|
pub(all) struct HandlePayload {
  id : Int
}

///|
pub(all) struct AssetEventPayload {
  tag : Int
  id : Int
}

///|
pub(all) struct AssetsPayload {
  items : Array[@ecs.EcsPayload?]
  alive : Int
  events : Array[AssetEventPayload]
  dirty : Array[Int]
}

///|
pub(all) struct AssetLoadFailedEventPayload {
  id : Int
  path : AssetPath
  error : String
}

///|
pub impl[T] @ecs.EcsPayloadCodec for Handle[T] with to_ecs_payload(self) {
  EcsPayload_asset_Handle(HandlePayload::{ id: self.id })
}

///|
pub impl[T] @ecs.EcsPayloadCodec for Handle[T] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_asset_Handle(value) => Some(Handle::new(value.id))
    _ => None
  }
}

///|
fn[T] asset_event_to_payload(event : AssetEvent[T]) -> AssetEventPayload {
  match event {
    Added(handle) => AssetEventPayload::{ tag: 0, id: handle.id() }
    Modified(handle) => AssetEventPayload::{ tag: 1, id: handle.id() }
    Removed(handle) => AssetEventPayload::{ tag: 2, id: handle.id() }
    Unused(handle) => AssetEventPayload::{ tag: 3, id: handle.id() }
    LoadedWithDependencies(handle) =>
      AssetEventPayload::{ tag: 4, id: handle.id() }
  }
}

///|
fn[T] asset_event_from_payload(payload : AssetEventPayload) -> AssetEvent[T]? {
  let handle : Handle[T] = Handle::new(payload.id)
  match payload.tag {
    0 => Some(AssetEvent::Added(handle))
    1 => Some(AssetEvent::Modified(handle))
    2 => Some(AssetEvent::Removed(handle))
    3 => Some(AssetEvent::Unused(handle))
    4 => Some(AssetEvent::LoadedWithDependencies(handle))
    _ => None
  }
}

///|
pub impl[T] @ecs.EcsPayloadCodec for AssetEvent[T] with to_ecs_payload(self) {
  EcsPayload_asset_AssetEvent(asset_event_to_payload(self))
}

///|
pub impl[T] @ecs.EcsPayloadCodec for AssetEvent[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_AssetEvent(value) => asset_event_from_payload(value)
    _ => None
  }
}

///|
pub impl[T] @ecs.EcsPayloadCodec for Assets[T] with to_ecs_payload(self) {
  EcsPayload_asset_Assets(AssetsPayload::{
    items: self.items,
    alive: self.alive,
    events: self.events,
    dirty: self.dirty,
  })
}

///|
pub impl[T] @ecs.EcsPayloadCodec for Assets[T] with from_ecs_payload(payload) {
  match payload {
    EcsPayload_asset_Assets(value) =>
      Some(Assets::{
        items: value.items,
        alive: value.alive,
        events: value.events,
        dirty: value.dirty,
        marker: None,
      })
    _ => None
  }
}

///|
pub impl[T] @ecs.EcsPayloadCodec for AssetLoadFailedEvent[T] with to_ecs_payload(
  self,
) {
  EcsPayload_asset_AssetLoadFailedEvent(AssetLoadFailedEventPayload::{
    id: self.id.index(),
    path: self.path,
    error: self.error,
  })
}

///|
pub impl[T] @ecs.EcsPayloadCodec for AssetLoadFailedEvent[T] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_AssetLoadFailedEvent(value) =>
      Some(AssetLoadFailedEvent::{
        id: AssetId::new(value.id),
        path: value.path,
        error: value.error,
      })
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Blob with to_ecs_payload(self) {
  EcsPayload_asset_Blob(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Blob with from_ecs_payload(payload) {
  match payload {
    EcsPayload_asset_Blob(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Font with to_ecs_payload(self) {
  EcsPayload_asset_Font(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Font with from_ecs_payload(payload) {
  match payload {
    EcsPayload_asset_Font(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LoadedFolder with to_ecs_payload(self) {
  EcsPayload_asset_LoadedFolder(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LoadedFolder with from_ecs_payload(payload) {
  match payload {
    EcsPayload_asset_LoadedFolder(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TextureAtlasLayout with to_ecs_payload(self) {
  EcsPayload_asset_TextureAtlasLayout(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TextureAtlasLayout with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_TextureAtlasLayout(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AssetIoRuntimeState with to_ecs_payload(self) {
  EcsPayload_asset_AssetIoRuntimeState(self)
}

///|
impl @ecs.EcsPayloadCodec for AssetIoRuntimeState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_asset_AssetIoRuntimeState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AssetLoaderRegistryState with to_ecs_payload(self) {
  EcsPayload_asset_AssetLoaderRegistryState(self)
}

///|
impl @ecs.EcsPayloadCodec for AssetLoaderRegistryState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_AssetLoaderRegistryState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TypedAssetLoaderRegistryState with to_ecs_payload(
  self,
) {
  EcsPayload_asset_TypedAssetLoaderRegistryState(self)
}

///|
impl @ecs.EcsPayloadCodec for TypedAssetLoaderRegistryState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_TypedAssetLoaderRegistryState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AssetSourceBuilderRegistryState with to_ecs_payload(
  self,
) {
  EcsPayload_asset_AssetSourceBuilderRegistryState(self)
}

///|
impl @ecs.EcsPayloadCodec for AssetSourceBuilderRegistryState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_AssetSourceBuilderRegistryState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for AssetProcessorRegistryState with to_ecs_payload(
  self,
) {
  EcsPayload_asset_AssetProcessorRegistryState(self)
}

///|
impl @ecs.EcsPayloadCodec for AssetProcessorRegistryState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_asset_AssetProcessorRegistryState(value) => Some(value)
    _ => None
  }
}
