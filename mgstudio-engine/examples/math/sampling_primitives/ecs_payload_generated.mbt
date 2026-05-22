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
  EcsPayload_examples_math_sampling_primitives_SamplePoint(SamplePoint)
  EcsPayload_examples_math_sampling_primitives_SpawningPoint(SpawningPoint)
  EcsPayload_examples_math_sampling_primitives_DespawningPoint(DespawningPoint)
  EcsPayload_examples_math_sampling_primitives_FireflyLights(FireflyLights)
  EcsPayload_examples_math_sampling_primitives_CameraRig(CameraRig)
}

///|
impl @ecs.EcsPayloadCodec for SamplePoint with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_SamplePoint(self)
}

///|
impl @ecs.EcsPayloadCodec for SamplePoint with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_SamplePoint(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SpawningPoint with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_SpawningPoint(self)
}

///|
impl @ecs.EcsPayloadCodec for SpawningPoint with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_SpawningPoint(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DespawningPoint with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_DespawningPoint(self)
}

///|
impl @ecs.EcsPayloadCodec for DespawningPoint with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_DespawningPoint(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for FireflyLights with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_FireflyLights(self)
}

///|
impl @ecs.EcsPayloadCodec for FireflyLights with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_FireflyLights(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CameraRig with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_CameraRig(self)
}

///|
impl @ecs.EcsPayloadCodec for CameraRig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_CameraRig(value) => Some(value)
    _ => None
  }
}
