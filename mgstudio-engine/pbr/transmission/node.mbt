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
// Bevy source: `bevy/crates/bevy_pbr/src/transmission/node.rs`.

///|
pub struct TransmittedShadowReceiver {} derive(ToJson, FromJson)

///|
pub fn TransmittedShadowReceiver::default() -> TransmittedShadowReceiver {
  TransmittedShadowReceiver::{  }
}

///|
pub let ecs_key_transmitted_shadow_receiver : @ecs.ComponentKey[
  TransmittedShadowReceiver,
] = @ecs.register_component(debug_name="render3d.transmitted_shadow_receiver")

///|
pub impl @ecs.Component for TransmittedShadowReceiver with component() {
  ecs_key_transmitted_shadow_receiver
}

///|
pub struct MainTransmissivePass3dConfig {
  enabled : Bool
  steps : Int
  should_copy_main_texture : Bool
}

///|
pub fn MainTransmissivePass3dConfig::default() -> MainTransmissivePass3dConfig {
  MainTransmissivePass3dConfig::{
    enabled: true,
    steps: 1,
    should_copy_main_texture: false,
  }
}

///|
pub fn MainTransmissivePass3dConfig::from_transmission(
  transmission : ScreenSpaceTransmission,
) -> MainTransmissivePass3dConfig {
  let safe_steps = if transmission.steps <= 0 { 1 } else { transmission.steps }
  MainTransmissivePass3dConfig::{
    enabled: true,
    steps: safe_steps,
    should_copy_main_texture: safe_steps > 1,
  }
}

///|
pub fn MainTransmissivePass3dConfig::with_enabled(
  self : MainTransmissivePass3dConfig,
  enabled : Bool,
) -> MainTransmissivePass3dConfig {
  MainTransmissivePass3dConfig::{ ..self, enabled, }
}

///|
pub fn MainTransmissivePass3dConfig::with_steps(
  self : MainTransmissivePass3dConfig,
  steps : Int,
) -> MainTransmissivePass3dConfig {
  let safe_steps = if steps <= 0 { 1 } else { steps }
  MainTransmissivePass3dConfig::{
    ..self,
    steps: safe_steps,
    should_copy_main_texture: safe_steps > 1,
  }
}

///|
pub fn main_transmissive_pass_3d_should_run(
  config : MainTransmissivePass3dConfig,
  items : Array[Transmissive3d],
) -> Bool {
  config.enabled && items.length() > 0
}

///|
pub fn main_transmissive_pass_3d_step_ranges(
  config : MainTransmissivePass3dConfig,
  items : Array[Transmissive3d],
) -> Array[(Int, Int)] {
  if !main_transmissive_pass_3d_should_run(config, items) {
    return []
  }
  transmissive3d_split_range(items.length(), config.steps)
}

///|
pub fn main_transmissive_pass_3d_should_copy_texture_per_step(
  config : MainTransmissivePass3dConfig,
) -> Bool {
  config.should_copy_main_texture
}

///|
pub fn main_transmissive_pass_3d_sorted_items(
  items : Array[Transmissive3d],
) -> Array[Transmissive3d] {
  transmissive3d_sort(items)
}
