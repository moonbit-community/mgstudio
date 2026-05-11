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
  EcsPayload_examples_math_bounding_2d_Test(Test)
  EcsPayload_examples_math_bounding_2d_Spin(Spin)
  EcsPayload_examples_math_bounding_2d_Shape(Shape)
  EcsPayload_examples_math_bounding_2d_DesiredVolume(DesiredVolume)
  EcsPayload_examples_math_bounding_2d_CurrentVolume(CurrentVolume)
}

///|
impl @ecs.EcsPayloadCodec for Test with to_ecs_payload(self) {
  EcsPayload_examples_math_bounding_2d_Test(self)
}

///|
impl @ecs.EcsPayloadCodec for Test with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_bounding_2d_Test(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Spin with to_ecs_payload(self) {
  EcsPayload_examples_math_bounding_2d_Spin(self)
}

///|
impl @ecs.EcsPayloadCodec for Spin with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_bounding_2d_Spin(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Shape with to_ecs_payload(self) {
  EcsPayload_examples_math_bounding_2d_Shape(self)
}

///|
impl @ecs.EcsPayloadCodec for Shape with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_bounding_2d_Shape(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for DesiredVolume with to_ecs_payload(self) {
  EcsPayload_examples_math_bounding_2d_DesiredVolume(self)
}

///|
impl @ecs.EcsPayloadCodec for DesiredVolume with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_bounding_2d_DesiredVolume(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CurrentVolume with to_ecs_payload(self) {
  EcsPayload_examples_math_bounding_2d_CurrentVolume(self)
}

///|
impl @ecs.EcsPayloadCodec for CurrentVolume with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_math_bounding_2d_CurrentVolume(value) => Some(value)
    _ => None
  }
}
