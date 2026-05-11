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
  EcsPayload_examples_camera_first_person_view_model_Player(Player)
  EcsPayload_examples_camera_first_person_view_model_CameraSensitivity(
    CameraSensitivity
  )
  EcsPayload_examples_camera_first_person_view_model_WorldModelCamera(
    WorldModelCamera
  )
}

///|
impl @ecs.EcsPayloadCodec for Player with to_ecs_payload(self) {
  EcsPayload_examples_camera_first_person_view_model_Player(self)
}

///|
impl @ecs.EcsPayloadCodec for Player with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_camera_first_person_view_model_Player(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CameraSensitivity with to_ecs_payload(self) {
  EcsPayload_examples_camera_first_person_view_model_CameraSensitivity(self)
}

///|
impl @ecs.EcsPayloadCodec for CameraSensitivity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_camera_first_person_view_model_CameraSensitivity(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for WorldModelCamera with to_ecs_payload(self) {
  EcsPayload_examples_camera_first_person_view_model_WorldModelCamera(self)
}

///|
impl @ecs.EcsPayloadCodec for WorldModelCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_camera_first_person_view_model_WorldModelCamera(value) =>
      Some(value)
    _ => None
  }
}
