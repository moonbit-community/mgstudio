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
pub const DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID : Int = @pbr_deferred.DEFAULT_PBR_DEFERRED_LIGHTING_PASS_ID

///|
pub type DeferredPbrLightingState = @pbr_deferred.DeferredPbrLightingState

///|
pub let ecs_key_deferred_pbr_lighting_state : @ecs.ResourceKey[
  DeferredPbrLightingState,
] = @pbr_deferred.ecs_key_deferred_pbr_lighting_state

///|
pub type DeferredPbrLightingPlugin = @pbr_deferred.DeferredPbrLightingPlugin

///|
pub type PbrDeferredLightingDepthId = @pbr_deferred.PbrDeferredLightingDepthId

///|
pub let ecs_key_pbr_deferred_lighting_depth_id : @ecs.ComponentKey[
  PbrDeferredLightingDepthId,
] = @pbr_deferred.ecs_key_pbr_deferred_lighting_depth_id

///|
pub fn deferred_pbr_lighting_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @pbr_deferred.deferred_pbr_lighting_plugin(app)
}

///|
pub fn deferred_pbr_lighting_enabled(world : @ecs.World) -> Bool {
  @pbr_deferred.deferred_pbr_lighting_enabled(world)
}
