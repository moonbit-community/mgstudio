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
// Mesh upload cache runtime ownership moved to `pbr/render/mesh.mbt`.

///|
pub fn render3d_upload_mesh_handle_cached(
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Int {
  @pbr_render.render3d_upload_mesh_handle_cached(phase_state_ref, mesh_handle)
}

///|
pub fn render3d_clear_mesh_upload_cache(
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
) -> Unit {
  phase_state_ref.val.mesh_upload_cache.clear()
}

///|
pub fn render3d_clear_mesh_upload_cache_for_world(world : @ecs.World) -> Unit {
  let phase_state_ref = @pbr_render.render3d_phase_state_ref_or_abort(world)
  render3d_clear_mesh_upload_cache(phase_state_ref)
}
