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
fn render3d_extract_skin_bindings(
  source_world : @ecs.World,
  phase_state_ref : Ref[Render3dPhaseState],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  @pbr_render.render3d_extract_skin_bindings(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
}

///|
fn render3d_prepare_skin_bindings_upload(
  source_world : @ecs.World,
  phase_state_ref : Ref[Render3dPhaseState],
  world_transform_cache_ref : Ref[Render3dWorldTransformCache],
) -> Unit {
  @pbr_render.render3d_prepare_skin_bindings_upload(
    source_world, phase_state_ref, world_transform_cache_ref,
  )
}

///|
fn render3d_prepared_skin_binding_keys(
  phase_state_ref : Ref[Render3dPhaseState],
  entity : @core.Entity,
) -> (Int, Int) {
  @pbr_render.render3d_prepared_skin_binding_keys(phase_state_ref, entity)
}
