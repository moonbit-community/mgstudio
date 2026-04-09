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
