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
// Bevy source: `bevy/crates/bevy_material/src/opaque.rs`.

///|
pub type MaterialDefaultOpaqueMethod = DefaultOpaqueRendererMethod

///|
pub let ecs_key_material_default_opaque_method : @ecs.ResourceKey[
  MaterialDefaultOpaqueMethod,
] = ecs_key_default_opaque_renderer_method

///|
pub fn material_default_opaque_method_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[MaterialDefaultOpaqueMethod] {
  get_default_opaque_renderer_method_resource(world)
}
