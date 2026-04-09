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
// Bevy source: `bevy/crates/bevy_post_process/src/effect_stack/vignette.rs`.
// Host-side uniform packing for the stable root `Vignette` runtime.

///|
pub struct VignetteUniform {
  intensity : Float
  radius : Float
  smoothness : Float
  roundness : Float
  center : @math.Vec2
  edge_compensation : Float
  color : @color.Color
} derive(ToJson, FromJson)

///|
pub fn VignetteUniform::from_settings(settings : Vignette) -> VignetteUniform {
  VignetteUniform::{
    intensity: settings.intensity,
    radius: settings.radius,
    smoothness: settings.smoothness,
    roundness: settings.roundness,
    center: settings.center,
    edge_compensation: settings.edge_compensation,
    color: settings.color,
  }
}

///|
pub fn vignette_screen_centered(settings : Vignette) -> Bool {
  (settings.center.x - 0.5F).abs() <= 0.000001F &&
  (settings.center.y - 0.5F).abs() <= 0.000001F
}
