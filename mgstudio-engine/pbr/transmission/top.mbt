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
// Bevy source: `bevy/crates/bevy_pbr/src/transmission/mod.rs`.

///|
pub(all) enum ScreenSpaceTransmissionQuality {
  Low
  Medium
  High
  Ultra
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn ScreenSpaceTransmissionQuality::default() -> ScreenSpaceTransmissionQuality {
  ScreenSpaceTransmissionQuality::High
}

///|
pub struct ScreenSpaceTransmission {
  quality : ScreenSpaceTransmissionQuality
  steps : Int
} derive(ToJson, FromJson)

///|
pub fn ScreenSpaceTransmission::default() -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::{
    quality: ScreenSpaceTransmissionQuality::default(),
    steps: 2,
  }
}

///|
pub fn ScreenSpaceTransmission::new(
  quality : ScreenSpaceTransmissionQuality,
  steps : Int,
) -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::{
    quality,
    steps: if steps < 0 {
      0
    } else if steps > 4 {
      4
    } else {
      steps
    },
  }
}

///|
pub fn ScreenSpaceTransmission::with_quality(
  self : ScreenSpaceTransmission,
  quality : ScreenSpaceTransmissionQuality,
) -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::{ ..self, quality, }
}

///|
pub fn ScreenSpaceTransmission::with_steps(
  self : ScreenSpaceTransmission,
  steps : Int,
) -> ScreenSpaceTransmission {
  ScreenSpaceTransmission::new(self.quality, steps)
}

///|
pub fn screen_space_transmission_blur_taps(
  quality : ScreenSpaceTransmissionQuality,
) -> Int {
  match quality {
    Low => 4
    Medium => 8
    High => 16
    Ultra => 32
  }
}

///|
pub let ecs_key_screen_space_transmission : @ecs.ComponentKey[
  ScreenSpaceTransmission,
] = @ecs.register_component(debug_name="render3d.screen_space_transmission")

///|
pub impl @ecs.Component for ScreenSpaceTransmission with component() {
  ecs_key_screen_space_transmission
}
