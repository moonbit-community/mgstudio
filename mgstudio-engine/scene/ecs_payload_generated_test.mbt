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
  EcsPayload_scene_SceneFilterTestComponent(SceneFilterTestComponent)
  EcsPayload_scene_SceneFilterTestResource(SceneFilterTestResource)
}

///|
pub impl @ecs.EcsPayloadCodec for SceneFilterTestComponent with to_ecs_payload(
  self,
) {
  EcsPayload_scene_SceneFilterTestComponent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SceneFilterTestComponent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_scene_SceneFilterTestComponent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SceneFilterTestResource with to_ecs_payload(
  self,
) {
  EcsPayload_scene_SceneFilterTestResource(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SceneFilterTestResource with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_scene_SceneFilterTestResource(value) => Some(value)
    _ => None
  }
}
