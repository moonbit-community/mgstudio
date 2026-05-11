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
  EcsPayload_examples_stress_tests_bevymark_Bird(Bird)
  EcsPayload_examples_stress_tests_bevymark_BirdCounter(BirdCounter)
  EcsPayload_examples_stress_tests_bevymark_BirdAssets(BirdAssets)
}

///|
impl @ecs.EcsPayloadCodec for Bird with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_bevymark_Bird(self)
}

///|
impl @ecs.EcsPayloadCodec for Bird with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_bevymark_Bird(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for BirdCounter with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_bevymark_BirdCounter(self)
}

///|
impl @ecs.EcsPayloadCodec for BirdCounter with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_bevymark_BirdCounter(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for BirdAssets with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_bevymark_BirdAssets(self)
}

///|
impl @ecs.EcsPayloadCodec for BirdAssets with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_bevymark_BirdAssets(value) => Some(value)
    _ => None
  }
}
