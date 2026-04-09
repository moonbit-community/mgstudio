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
// Bevy source: `bevy/crates/bevy_post_process/src/motion_blur/pipeline.rs`.
// Host-side sample generation over the stable root `MotionBlur` runtime.

///|
pub struct MotionBlurSample {
  offset : Float
  weight : Float
} derive(ToJson, FromJson)

///|
pub fn motion_blur_samples(settings : MotionBlur) -> Array[MotionBlurSample] {
  if settings.samples <= 0 || settings.shutter_angle <= 0.0F {
    return []
  }
  if settings.samples == 1 {
    return [MotionBlurSample::{ offset: 0.0F, weight: 1.0F }]
  }
  let samples : Array[MotionBlurSample] = []
  let half_angle = settings.shutter_angle * 0.5F
  let last_index = settings.samples - 1
  let last_index_float = Float::from_double(last_index.to_double())
  for index in 0..<settings.samples {
    let normalized = Float::from_double(index.to_double()) / last_index_float
    let offset = (normalized - 0.5F) * settings.shutter_angle
    let normalized_distance = if half_angle <= 0.0F {
      0.0F
    } else {
      offset.abs() / half_angle
    }
    samples.push(MotionBlurSample::{
      offset,
      weight: 1.0F - normalized_distance * 0.5F,
    })
  }
  samples
}
