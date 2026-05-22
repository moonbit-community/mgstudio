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
  EcsPayload_scene_Scene(Scene)
  EcsPayload_scene_Gltf(Gltf)
  EcsPayload_scene_SceneRoot(SceneRoot)
  EcsPayload_scene_SceneInstance(SceneInstance)
  EcsPayload_scene_SceneInstanceReady(SceneInstanceReady)
  EcsPayload_scene_SceneRootRespawnRequested(SceneRootRespawnRequested)
}

///|
pub impl @ecs.EcsPayloadCodec for Scene with to_ecs_payload(self) {
  EcsPayload_scene_Scene(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Scene with from_ecs_payload(payload) {
  match payload {
    EcsPayload_scene_Scene(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Gltf with to_ecs_payload(self) {
  EcsPayload_scene_Gltf(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Gltf with from_ecs_payload(payload) {
  match payload {
    EcsPayload_scene_Gltf(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SceneRoot with to_ecs_payload(self) {
  EcsPayload_scene_SceneRoot(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SceneRoot with from_ecs_payload(payload) {
  match payload {
    EcsPayload_scene_SceneRoot(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SceneInstance with to_ecs_payload(self) {
  EcsPayload_scene_SceneInstance(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SceneInstance with from_ecs_payload(payload) {
  match payload {
    EcsPayload_scene_SceneInstance(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SceneInstanceReady with to_ecs_payload(self) {
  EcsPayload_scene_SceneInstanceReady(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SceneInstanceReady with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_scene_SceneInstanceReady(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SceneRootRespawnRequested with to_ecs_payload(
  self,
) {
  EcsPayload_scene_SceneRootRespawnRequested(self)
}

///|
impl @ecs.EcsPayloadCodec for SceneRootRespawnRequested with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_scene_SceneRootRespawnRequested(value) => Some(value)
    _ => None
  }
}
