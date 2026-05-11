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
  EcsPayload_examples_math_random_sampling_Mode(Mode)
  EcsPayload_examples_math_random_sampling_SampledShape(SampledShape)
  EcsPayload_examples_math_random_sampling_RandomSource(RandomSource)
  EcsPayload_examples_math_random_sampling_PointMesh(PointMesh)
  EcsPayload_examples_math_random_sampling_PointMaterial(PointMaterial)
  EcsPayload_examples_math_random_sampling_MousePressed(MousePressed)
  EcsPayload_examples_math_random_sampling_SamplePoint(SamplePoint)
}

///|
impl @ecs.EcsPayloadCodec for Mode with to_ecs_payload(self) {
  EcsPayload_examples_math_random_sampling_Mode(self)
}

///|
impl @ecs.EcsPayloadCodec for Mode with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_random_sampling_Mode(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SampledShape with to_ecs_payload(self) {
  EcsPayload_examples_math_random_sampling_SampledShape(self)
}

///|
impl @ecs.EcsPayloadCodec for SampledShape with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_random_sampling_SampledShape(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for RandomSource with to_ecs_payload(self) {
  EcsPayload_examples_math_random_sampling_RandomSource(self)
}

///|
impl @ecs.EcsPayloadCodec for RandomSource with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_random_sampling_RandomSource(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PointMesh with to_ecs_payload(self) {
  EcsPayload_examples_math_random_sampling_PointMesh(self)
}

///|
impl @ecs.EcsPayloadCodec for PointMesh with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_random_sampling_PointMesh(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PointMaterial with to_ecs_payload(self) {
  EcsPayload_examples_math_random_sampling_PointMaterial(self)
}

///|
impl @ecs.EcsPayloadCodec for PointMaterial with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_random_sampling_PointMaterial(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for MousePressed with to_ecs_payload(self) {
  EcsPayload_examples_math_random_sampling_MousePressed(self)
}

///|
impl @ecs.EcsPayloadCodec for MousePressed with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_random_sampling_MousePressed(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for SamplePoint with to_ecs_payload(self) {
  EcsPayload_examples_math_random_sampling_SamplePoint(self)
}

///|
impl @ecs.EcsPayloadCodec for SamplePoint with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_random_sampling_SamplePoint(value) => Some(value)
    _ => None
  }
}
