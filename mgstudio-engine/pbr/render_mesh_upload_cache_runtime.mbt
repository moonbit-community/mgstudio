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
fn render3d_upload_mesh_handle_cached(
  phase_state_ref : Ref[@pbr_render.Render3dPhaseState],
  mesh_handle : @asset.Handle[@mesh.Mesh],
) -> Int {
  let mesh_handle_id = mesh_handle.id()
  if mesh_handle_id < 0 {
    return -1
  }
  match phase_state_ref.val.mesh_upload_cache.get(mesh_handle_id) {
    Some(mesh_id) =>
      if mesh_id > 0 {
        mesh_id
      } else {
        let uploaded_mesh_id = @sprite_render.render2d_upload_mesh_handle(
          mesh_handle,
        )
        phase_state_ref.val.mesh_upload_cache.set(
          mesh_handle_id, uploaded_mesh_id,
        )
        uploaded_mesh_id
      }
    None => {
      let uploaded_mesh_id = @sprite_render.render2d_upload_mesh_handle(
        mesh_handle,
      )
      phase_state_ref.val.mesh_upload_cache.set(
        mesh_handle_id, uploaded_mesh_id,
      )
      uploaded_mesh_id
    }
  }
}
