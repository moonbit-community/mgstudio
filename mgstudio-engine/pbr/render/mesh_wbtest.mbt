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
test "pbr/render mesh: runtime state enables binding array material path" {
  let state = Render3dMeshRuntimeState::new()
  inspect(state.binding_arrays_are_usable, content="false")
  inspect(
    state.clustered_decals_are_usable,
    content=@render_gpu.host_gpu_mesh3d_binding_arrays_are_usable(
      required_storage_textures_per_shader_stage=0U,
    ).to_string(),
  )
}

///|
test "pbr/render mesh: pipeline capability changes reset specialized pipeline caches" {
  let state = Render3dMeshRuntimeState::new().with_pipeline_capabilities(
    false, false,
  )
  let unchanged = state.with_pipeline_capabilities(false, false)
  inspect(unchanged.binding_arrays_are_usable, content="false")
  inspect(unchanged.clustered_decals_are_usable, content="false")
  let changed = state.with_pipeline_capabilities(true, true)
  inspect(changed.binding_arrays_are_usable, content="true")
  inspect(changed.clustered_decals_are_usable, content="true")
  inspect(
    changed.specialized_material_pipelines.mesh_layout_cache_len(),
    content="0",
  )
  inspect(
    changed.specialized_prepass_material_pipelines.mesh_layout_cache_len(),
    content="0",
  )
}
