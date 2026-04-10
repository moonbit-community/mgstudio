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
test "gltf: pbr material handler toggle can be switched at runtime" {
  let original = gltf_pbr_material_handler_enabled()
  gltf_set_pbr_material_handler_enabled(false)
  debug_inspect(gltf_pbr_material_handler_enabled(), content="false")
  gltf_set_pbr_material_handler_enabled(true)
  debug_inspect(gltf_pbr_material_handler_enabled(), content="true")
  gltf_set_pbr_material_handler_enabled(original)
}

///|
test "gltf: plugin surface can configure skinned mesh bounds policy" {
  let original = gltf_default_skinned_mesh_bounds_policy()
  gltf_set_default_skinned_mesh_bounds_policy(
    GltfSkinnedMeshBoundsPolicy::BindPose,
  )
  debug_inspect(
    gltf_default_skinned_mesh_bounds_policy() ==
    GltfSkinnedMeshBoundsPolicy::BindPose,
    content="true",
  )
  gltf_set_default_skinned_mesh_bounds_policy(
    GltfSkinnedMeshBoundsPolicy::NoFrustumCulling,
  )
  debug_inspect(
    gltf_default_skinned_mesh_bounds_policy() ==
    GltfSkinnedMeshBoundsPolicy::NoFrustumCulling,
    content="true",
  )
  gltf_set_default_skinned_mesh_bounds_policy(original)
}

///|
test "gltf: plugin surface can configure default coordinate conversion" {
  let original = gltf_default_convert_coordinates()
  gltf_set_default_convert_coordinates({
    rotate_scene_entity: true,
    rotate_meshes: false,
  })
  debug_inspect(
    gltf_default_convert_coordinates().rotate_scene_entity,
    content="true",
  )
  debug_inspect(
    gltf_default_convert_coordinates().rotate_meshes,
    content="false",
  )
  gltf_set_default_convert_coordinates(original)
}
