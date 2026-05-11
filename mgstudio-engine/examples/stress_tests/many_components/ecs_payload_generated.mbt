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
  EcsPayload_examples_stress_tests_many_components_CompA(CompA)
  EcsPayload_examples_stress_tests_many_components_CompB(CompB)
  EcsPayload_examples_stress_tests_many_components_CompC(CompC)
  EcsPayload_examples_stress_tests_many_components_CompD(CompD)
  EcsPayload_examples_stress_tests_many_components_CompE(CompE)
  EcsPayload_examples_stress_tests_many_components_CompF(CompF)
}

///|
impl @ecs.EcsPayloadCodec for CompA with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_many_components_CompA(self)
}

///|
impl @ecs.EcsPayloadCodec for CompA with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_many_components_CompA(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CompB with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_many_components_CompB(self)
}

///|
impl @ecs.EcsPayloadCodec for CompB with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_many_components_CompB(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CompC with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_many_components_CompC(self)
}

///|
impl @ecs.EcsPayloadCodec for CompC with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_many_components_CompC(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CompD with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_many_components_CompD(self)
}

///|
impl @ecs.EcsPayloadCodec for CompD with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_many_components_CompD(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CompE with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_many_components_CompE(self)
}

///|
impl @ecs.EcsPayloadCodec for CompE with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_many_components_CompE(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CompF with to_ecs_payload(self) {
  EcsPayload_examples_stress_tests_many_components_CompF(self)
}

///|
impl @ecs.EcsPayloadCodec for CompF with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_stress_tests_many_components_CompF(value) => Some(value)
    _ => None
  }
}
