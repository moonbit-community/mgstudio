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
  EcsPayload_examples_animation_animated_mesh_events_AnimationSetup(
    AnimationSetup
  )
  EcsPayload_examples_animation_animated_mesh_events_ParticleAssets(
    ParticleAssets
  )
  EcsPayload_examples_animation_animated_mesh_events_Particle(Particle)
  EcsPayload_examples_animation_animated_mesh_events_StepEvent(StepEvent)
}

///|
impl @ecs.EcsPayloadCodec for AnimationSetup with to_ecs_payload(self) {
  EcsPayload_examples_animation_animated_mesh_events_AnimationSetup(self)
}

///|
impl @ecs.EcsPayloadCodec for AnimationSetup with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animated_mesh_events_AnimationSetup(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for ParticleAssets with to_ecs_payload(self) {
  EcsPayload_examples_animation_animated_mesh_events_ParticleAssets(self)
}

///|
impl @ecs.EcsPayloadCodec for ParticleAssets with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animated_mesh_events_ParticleAssets(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for Particle with to_ecs_payload(self) {
  EcsPayload_examples_animation_animated_mesh_events_Particle(self)
}

///|
impl @ecs.EcsPayloadCodec for Particle with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animated_mesh_events_Particle(value) =>
      Some(value)
    _ => None
  }
}

///|
impl @ecs.EcsPayloadCodec for StepEvent with to_ecs_payload(self) {
  EcsPayload_examples_animation_animated_mesh_events_StepEvent(self)
}

///|
impl @ecs.EcsPayloadCodec for StepEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_examples_animation_animated_mesh_events_StepEvent(value) =>
      Some(value)
    _ => None
  }
}
