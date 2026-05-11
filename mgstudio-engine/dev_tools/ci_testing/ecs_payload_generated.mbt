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
  EcsPayload_dev_tools_ci_testing_CiTestingConfig(CiTestingConfig)
  EcsPayload_dev_tools_ci_testing_CiTestingCustomEvent(CiTestingCustomEvent)
  EcsPayload_dev_tools_ci_testing_CiTestingRuntimeState(CiTestingRuntimeState)
  EcsPayload_dev_tools_ci_testing_CiTestingPluginMarker(CiTestingPluginMarker)
}

///|
pub impl @ecs.EcsPayloadCodec for CiTestingConfig with to_ecs_payload(self) {
  EcsPayload_dev_tools_ci_testing_CiTestingConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CiTestingConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_dev_tools_ci_testing_CiTestingConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CiTestingCustomEvent with to_ecs_payload(self) {
  EcsPayload_dev_tools_ci_testing_CiTestingCustomEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CiTestingCustomEvent with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_ci_testing_CiTestingCustomEvent(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for CiTestingRuntimeState with to_ecs_payload(
  self,
) {
  EcsPayload_dev_tools_ci_testing_CiTestingRuntimeState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for CiTestingRuntimeState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_ci_testing_CiTestingRuntimeState(value) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CiTestingPluginMarker with to_ecs_payload(self) {
  EcsPayload_dev_tools_ci_testing_CiTestingPluginMarker(self)
}

///|
impl @ecs.EcsPayloadCodec for CiTestingPluginMarker with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_dev_tools_ci_testing_CiTestingPluginMarker(value) => Some(value)
    _ => None
  }
}
