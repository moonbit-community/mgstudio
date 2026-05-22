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
// Bevy source:
// `bevy/crates/bevy_core_pipeline/src/prepass/background_motion_vectors.rs`.

///|
pub struct NoBackgroundMotionVectors {} derive(Eq, Debug)

///|
pub fn NoBackgroundMotionVectors::NoBackgroundMotionVectors() -> NoBackgroundMotionVectors {
  NoBackgroundMotionVectors::{  }
}

///|
pub struct BackgroundMotionVectorsPipelineKey {
  samples : Int
  normal_prepass : Bool
} derive(Eq, Debug)

///|
pub fn BackgroundMotionVectorsPipelineKey::new(
  samples~ : Int,
  normal_prepass~ : Bool,
) -> BackgroundMotionVectorsPipelineKey {
  BackgroundMotionVectorsPipelineKey::{ samples, normal_prepass }
}

///|
pub fn BackgroundMotionVectorsPipelineKey::samples(
  self : BackgroundMotionVectorsPipelineKey,
) -> Int {
  self.samples
}

///|
pub fn BackgroundMotionVectorsPipelineKey::normal_prepass(
  self : BackgroundMotionVectorsPipelineKey,
) -> Bool {
  self.normal_prepass
}

///|
pub struct BackgroundMotionVectorsPluginState {
  required_independent_blend : Bool
  enabled : Bool
} derive(Eq, Debug)

///|
pub fn BackgroundMotionVectorsPluginState::new(
  gpu_has_independent_blend : Bool,
) -> BackgroundMotionVectorsPluginState {
  BackgroundMotionVectorsPluginState::{
    required_independent_blend: true,
    enabled: gpu_has_independent_blend,
  }
}

///|
pub fn BackgroundMotionVectorsPluginState::enabled(
  self : BackgroundMotionVectorsPluginState,
) -> Bool {
  self.enabled
}

///|
pub fn background_motion_vectors_should_prepare(
  has_motion_vector_prepass : Bool,
  has_no_background_motion_vectors : Bool,
  gpu_has_independent_blend : Bool,
) -> Bool {
  has_motion_vector_prepass &&
  !has_no_background_motion_vectors &&
  gpu_has_independent_blend
}

///|
pub let ecs_key_no_background_motion_vectors : @ecs.ComponentKey[
  NoBackgroundMotionVectors,
] = @ecs.register_component(
  debug_name="mgstudio.core_pipeline.prepass.NoBackgroundMotionVectors",
)

///|
pub impl @ecs.EcsPayloadCodec for NoBackgroundMotionVectors with to_ecs_payload(
  self,
) {
  EcsPayload_core_pipeline_prepass_NoBackgroundMotionVectors(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NoBackgroundMotionVectors with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_core_pipeline_prepass_NoBackgroundMotionVectors(value) =>
      Some(value)
    _ => None
  }
}

///|
pub impl @ecs.Component for NoBackgroundMotionVectors with component() {
  ecs_key_no_background_motion_vectors
}
