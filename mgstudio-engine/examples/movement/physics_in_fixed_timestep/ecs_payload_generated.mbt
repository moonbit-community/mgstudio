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
  EcsPayload_examples_movement_physics_in_fixed_timestep_AccumulatedInput(
    AccumulatedInput
  )
  EcsPayload_examples_movement_physics_in_fixed_timestep_Velocity(Velocity)
  EcsPayload_examples_movement_physics_in_fixed_timestep_PhysicalTranslation(
    PhysicalTranslation
  )
  EcsPayload_examples_movement_physics_in_fixed_timestep_PreviousPhysicalTranslation(
    PreviousPhysicalTranslation
  )
  EcsPayload_examples_movement_physics_in_fixed_timestep_CameraSensitivity(
    CameraSensitivity
  )
}

///|
impl @ecs.EcsPayloadCodec for AccumulatedInput with to_ecs_payload(self) {
  EcsPayload_examples_movement_physics_in_fixed_timestep_AccumulatedInput(self)
}

///|
impl @ecs.EcsPayloadCodec for AccumulatedInput with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_physics_in_fixed_timestep_AccumulatedInput(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Velocity with to_ecs_payload(self) {
  EcsPayload_examples_movement_physics_in_fixed_timestep_Velocity(self)
}

///|
impl @ecs.EcsPayloadCodec for Velocity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_physics_in_fixed_timestep_Velocity(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PhysicalTranslation with to_ecs_payload(self) {
  EcsPayload_examples_movement_physics_in_fixed_timestep_PhysicalTranslation(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for PhysicalTranslation with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_physics_in_fixed_timestep_PhysicalTranslation(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for PreviousPhysicalTranslation with to_ecs_payload(
  self,
) {
  EcsPayload_examples_movement_physics_in_fixed_timestep_PreviousPhysicalTranslation(
    self,
  )
}

///|
impl @ecs.EcsPayloadCodec for PreviousPhysicalTranslation with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_examples_movement_physics_in_fixed_timestep_PreviousPhysicalTranslation(
      value
    ) => Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for CameraSensitivity with to_ecs_payload(self) {
  EcsPayload_examples_movement_physics_in_fixed_timestep_CameraSensitivity(self)
}

///|
impl @ecs.EcsPayloadCodec for CameraSensitivity with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_movement_physics_in_fixed_timestep_CameraSensitivity(
      value
    ) => Some(value)
    _ => None
  }
}
