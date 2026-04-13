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
// Bevy source: `bevy/crates/bevy_light/src/directional_light.rs`.

///|
pub type DirectionalLightComponent = DirectionalLight

///|
pub type DirectionalLightTextureComponent = DirectionalLightTexture

///|
pub type SunDiskComponent = SunDisk

///|
pub let ecs_key_directional_light_component : @ecs.ComponentKey[
  DirectionalLightComponent,
] = ecs_key_directional_light

///|
pub let ecs_key_directional_light_texture_component : @ecs.ComponentKey[
  DirectionalLightTextureComponent,
] = ecs_key_directional_light_texture

///|
pub let ecs_key_sun_disk_component : @ecs.ComponentKey[SunDiskComponent] = ecs_key_sun_disk

///|
fn directional_light_is_power_of_two(value : Int) -> Bool {
  if value <= 0 {
    return false
  }
  let mut current = 1
  while current < value {
    current = current * 2
  }
  current == value
}

///|
fn directional_light_next_power_of_two(value : Int) -> Int {
  if value <= 1 {
    return 1
  }
  let mut current = 1
  while current < value {
    current = current * 2
  }
  current
}

///|
pub fn directional_light_validated_shadow_map_size(size : Int) -> Int {
  if directional_light_is_power_of_two(size) {
    size
  } else {
    directional_light_next_power_of_two(size)
  }
}

///|
pub fn validate_directional_light_shadow_map_size(
  world : @ecs.World,
) -> Unit {
  match (try! world.get_resource(ecs_key_directional_light_shadow_map)) {
    Some(resource) =>
      if !directional_light_is_power_of_two(resource.size) {
        let corrected = DirectionalLightShadowMap::{
          size: directional_light_validated_shadow_map_size(resource.size),
        }
        world.insert_resource(ecs_key_directional_light_shadow_map, corrected)
      }
    None => ()
  }
}
