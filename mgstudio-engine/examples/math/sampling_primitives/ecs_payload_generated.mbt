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
  EcsPayload_examples_math_sampling_primitives_SamplingMode(SamplingMode)
  EcsPayload_examples_math_sampling_primitives_SpawningMode(SpawningMode)
  EcsPayload_examples_math_sampling_primitives_SpawnQueue(SpawnQueue)
  EcsPayload_examples_math_sampling_primitives_PointCounter(PointCounter)
  EcsPayload_examples_math_sampling_primitives_RandomSource(RandomSource)
  EcsPayload_examples_math_sampling_primitives_SampledShapes(SampledShapes)
  EcsPayload_examples_math_sampling_primitives_PointMesh(PointMesh)
  EcsPayload_examples_math_sampling_primitives_PointMaterial(PointMaterial)
  EcsPayload_examples_math_sampling_primitives_MousePressed(MousePressed)
  EcsPayload_examples_math_sampling_primitives_InstructionText(InstructionText)
  EcsPayload_examples_math_sampling_primitives_SamplePoint(SamplePoint)
  EcsPayload_examples_math_sampling_primitives_SpawningPoint(SpawningPoint)
  EcsPayload_examples_math_sampling_primitives_DespawningPoint(DespawningPoint)
  EcsPayload_examples_math_sampling_primitives_FireflyLights(FireflyLights)
  EcsPayload_examples_math_sampling_primitives_CameraRig(CameraRig)
}

///|
impl @ecs.EcsPayloadCodec for SamplingMode with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_SamplingMode(self)
}

///|
impl @ecs.EcsPayloadCodec for SamplingMode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_SamplingMode(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SpawningMode with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_SpawningMode(self)
}

///|
impl @ecs.EcsPayloadCodec for SpawningMode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_SpawningMode(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SpawnQueue with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_SpawnQueue(self)
}

///|
impl @ecs.EcsPayloadCodec for SpawnQueue with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_SpawnQueue(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PointCounter with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_PointCounter(self)
}

///|
impl @ecs.EcsPayloadCodec for PointCounter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_PointCounter(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for RandomSource with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_RandomSource(self)
}

///|
impl @ecs.EcsPayloadCodec for RandomSource with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_RandomSource(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SampledShapes with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_SampledShapes(self)
}

///|
impl @ecs.EcsPayloadCodec for SampledShapes with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_SampledShapes(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PointMesh with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_PointMesh(self)
}

///|
impl @ecs.EcsPayloadCodec for PointMesh with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_PointMesh(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PointMaterial with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_PointMaterial(self)
}

///|
impl @ecs.EcsPayloadCodec for PointMaterial with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_PointMaterial(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MousePressed with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_MousePressed(self)
}

///|
impl @ecs.EcsPayloadCodec for MousePressed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_MousePressed(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for InstructionText with to_ecs_payload(self) {
  EcsPayload_examples_math_sampling_primitives_InstructionText(self)
}

///|
impl @ecs.EcsPayloadCodec for InstructionText with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_sampling_primitives_InstructionText(value) =>
      Some(value)
    _ => None
  }
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
