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
// Bevy source: `bevy/crates/bevy_light/src/cascade.rs`.
// Bridge aliases for cascade shadow configuration.

///|
pub type CascadeConfig = CascadeShadowConfig

///|
pub type CascadeConfigBuilder = CascadeShadowConfigBuilder

///|
pub type DirectionalShadowMapResource = DirectionalLightShadowMap

///|
pub let ecs_key_directional_shadow_map_resource : @ecs.ResourceKey[
  DirectionalShadowMapResource,
] = ecs_key_directional_light_shadow_map

///|
pub fn directional_shadow_map_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DirectionalShadowMapResource] {
  get_directional_light_shadow_map_resource(world)
}
