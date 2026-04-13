// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_post_process/src/effect_stack/chromatic_aberration.rs`.
// Host-side helpers derived from the stable root `ChromaticAberration` runtime.

///|
pub struct ChromaticAberration {
  intensity : Float
  max_samples : Int
} derive(ToJson, FromJson)

///|
pub fn ChromaticAberration::default() -> ChromaticAberration {
  ChromaticAberration::{ intensity: 0.02F, max_samples: 8 }
}

///|
pub fn ChromaticAberration::new(
  intensity : Float,
  max_samples : Int,
) -> ChromaticAberration {
  let safe_intensity = if intensity < 0.0F { 0.0F } else { intensity }
  let safe_max_samples = if max_samples <= 0 { 1 } else { max_samples }
  ChromaticAberration::{
    intensity: safe_intensity,
    max_samples: safe_max_samples,
  }
}

///|
pub fn ChromaticAberration::with_intensity(
  self : ChromaticAberration,
  intensity : Float,
) -> ChromaticAberration {
  ChromaticAberration::new(intensity, self.max_samples)
}

///|
pub fn ChromaticAberration::with_max_samples(
  self : ChromaticAberration,
  max_samples : Int,
) -> ChromaticAberration {
  ChromaticAberration::new(self.intensity, max_samples)
}

///|
pub let ecs_key_chromatic_aberration : @ecs.ComponentKey[ChromaticAberration] = @ecs.register_component(
  debug_name="render3d.chromatic_aberration",
)

///|
pub impl @ecs.Component for ChromaticAberration with component() {
  ecs_key_chromatic_aberration
}

///|
pub struct ChromaticAberrationUniform {
  intensity : Float
  inverse_max_samples : Float
} derive(ToJson, FromJson)

///|
pub fn ChromaticAberrationUniform::from_settings(
  settings : ChromaticAberration,
) -> ChromaticAberrationUniform {
  ChromaticAberrationUniform::{
    intensity: settings.intensity,
    inverse_max_samples: 1.0F /
    Float::from_double(settings.max_samples.to_double()),
  }
}

///|
pub fn chromatic_aberration_sample_offsets(
  settings : ChromaticAberration,
) -> Array[Float] {
  let sample_count = if settings.max_samples <= 0 {
    1
  } else {
    settings.max_samples
  }
  if sample_count == 1 {
    return [0.0F]
  }
  let offsets : Array[Float] = []
  let sample_count_float = Float::from_double((sample_count - 1).to_double())
  for index in 0..<sample_count {
    let centered = Float::from_double(index.to_double()) / sample_count_float -
      0.5F
    offsets.push(centered * 2.0F * settings.intensity)
  }
  offsets
}
