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
// Bevy source: `bevy/crates/bevy_light/src/ambient_light.rs`.

///|
pub type AmbientLightResource = GlobalAmbientLight

///|
pub let ecs_key_ambient_light_resource : @ecs.ResourceKey[AmbientLightResource] = ecs_key_global_ambient_light

///|
pub fn ambient_light_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[AmbientLightResource] {
  get_global_ambient_light_resource(world)
}
