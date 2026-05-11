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
  EcsPayload_camera_controller_FreeCamera(FreeCamera)
  EcsPayload_camera_controller_FreeCameraState(FreeCameraState)
  EcsPayload_camera_controller_PanCamera(PanCamera)
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCamera with to_ecs_payload(self) {
  EcsPayload_camera_controller_FreeCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_camera_controller_FreeCamera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCameraState with to_ecs_payload(self) {
  EcsPayload_camera_controller_FreeCameraState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for FreeCameraState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_camera_controller_FreeCameraState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PanCamera with to_ecs_payload(self) {
  EcsPayload_camera_controller_PanCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PanCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_camera_controller_PanCamera(value) => Some(value)
    _ => None
  }
}
