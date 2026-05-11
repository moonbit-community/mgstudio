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
  EcsPayload_examples_3d_tonemapping_CameraTransform(CameraTransform)
  EcsPayload_examples_3d_tonemapping_CurrentScene(CurrentScene)
  EcsPayload_examples_3d_tonemapping_SelectedParameter(SelectedParameter)
  EcsPayload_examples_3d_tonemapping_PerMethodSettings(PerMethodSettings)
  EcsPayload_examples_3d_tonemapping_SceneNumber(SceneNumber)
  EcsPayload_examples_3d_tonemapping_HDRViewer(HDRViewer)
  EcsPayload_examples_3d_tonemapping_TonemappingUiRoot(TonemappingUiRoot)
  EcsPayload_examples_3d_tonemapping_TonemappingUiText(TonemappingUiText)
}

///|
impl @ecs.EcsPayloadCodec for CameraTransform with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_CameraTransform(self)
}

///|
impl @ecs.EcsPayloadCodec for CameraTransform with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_CameraTransform(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CurrentScene with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_CurrentScene(self)
}

///|
impl @ecs.EcsPayloadCodec for CurrentScene with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_CurrentScene(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SelectedParameter with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_SelectedParameter(self)
}

///|
impl @ecs.EcsPayloadCodec for SelectedParameter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_SelectedParameter(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PerMethodSettings with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_PerMethodSettings(self)
}

///|
impl @ecs.EcsPayloadCodec for PerMethodSettings with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_PerMethodSettings(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SceneNumber with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_SceneNumber(self)
}

///|
impl @ecs.EcsPayloadCodec for SceneNumber with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_SceneNumber(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for HDRViewer with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_HDRViewer(self)
}

///|
impl @ecs.EcsPayloadCodec for HDRViewer with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_HDRViewer(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TonemappingUiRoot with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_TonemappingUiRoot(self)
}

///|
impl @ecs.EcsPayloadCodec for TonemappingUiRoot with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_TonemappingUiRoot(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for TonemappingUiText with to_ecs_payload(self) {
  EcsPayload_examples_3d_tonemapping_TonemappingUiText(self)
}

///|
impl @ecs.EcsPayloadCodec for TonemappingUiText with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_3d_tonemapping_TonemappingUiText(value) => Some(value)
    _ => None
  }
}
