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
  EcsPayload_pbr_transmission_ScreenSpaceTransmission(ScreenSpaceTransmission)
  EcsPayload_pbr_transmission_TransmittedShadowReceiver(
    TransmittedShadowReceiver
  )
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenSpaceTransmission with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_transmission_ScreenSpaceTransmission(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScreenSpaceTransmission with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_transmission_ScreenSpaceTransmission(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TransmittedShadowReceiver with to_ecs_payload(
  self,
) {
  EcsPayload_pbr_transmission_TransmittedShadowReceiver(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TransmittedShadowReceiver with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_pbr_transmission_TransmittedShadowReceiver(value) => Some(value)
    _ => None
  }
}
