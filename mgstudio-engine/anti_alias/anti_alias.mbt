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
/// Anti-aliasing API boundary aligned with Bevy's `bevy_anti_alias` crate.
/// Runtime implementation currently lives in `Milky2018/mgstudio/pbr`.
/// Current surface maps to available MSAA/FXAA/TAA components.

///|
pub type Msaa = @pbr.Msaa

///|
pub type Fxaa = @pbr.Fxaa

///|
pub type FxaaSensitivity = @pbr.FxaaSensitivity

///|
pub type TemporalAntiAliasing = @pbr.TemporalAntiAliasing

///|
pub type TemporalJitter = @pbr.TemporalJitter

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @pbr.ecs_key_msaa

///|
pub let ecs_key_fxaa : @ecs.ComponentKey[Fxaa] = @pbr.ecs_key_fxaa

///|
pub let ecs_key_temporal_anti_aliasing : @ecs.ComponentKey[TemporalAntiAliasing] = @pbr.ecs_key_temporal_anti_aliasing

///|
pub let ecs_key_temporal_jitter : @ecs.ComponentKey[TemporalJitter] = @pbr.ecs_key_temporal_jitter

///|
pub fn get_msaa_store(world : @ecs.World) -> @ecs.ComponentAccess[Msaa] {
  @pbr.get_msaa_store(world)
}

///|
pub fn get_fxaa_store(world : @ecs.World) -> @ecs.ComponentAccess[Fxaa] {
  @pbr.get_fxaa_store(world)
}

///|
pub fn get_temporal_anti_aliasing_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[TemporalAntiAliasing] {
  @pbr.get_temporal_anti_aliasing_store(world)
}

///|
pub fn get_temporal_jitter_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[TemporalJitter] {
  @pbr.get_temporal_jitter_store(world)
}
