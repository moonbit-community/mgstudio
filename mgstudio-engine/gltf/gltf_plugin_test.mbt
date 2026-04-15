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

///|
test "gltf: plugin surface can configure default image sampler" {
  let original = gltf_default_image_sampler()
  let nearest_clamp = @image.ImageSamplerDescriptor::nearest()
  nearest_clamp.set_address_mode(@image.ImageAddressMode::ClampToEdge) |> ignore
  gltf_set_default_image_sampler(nearest_clamp)
  let configured = gltf_default_image_sampler()
  debug_inspect(
    configured.min_filter == @image.ImageFilterMode::Nearest,
    content="true",
  )
  debug_inspect(
    configured.address_mode_u == @image.ImageAddressMode::ClampToEdge,
    content="true",
  )
  gltf_set_default_image_sampler(original)
}

///|
test "gltf: loader registration runs in finish lifecycle and only once" {
  let registration_count = Ref::new(0)
  @gltf_loader.gltf_install_loader_registration(fn() {
    registration_count.val = registration_count.val + 1
  })

  let mut app = @app.App::new(@ecs.World::new()).add_plugins(
    GltfPlugin::default(),
  )
  debug_inspect(registration_count.val, content="0")

  app = app.run_once()
  debug_inspect(registration_count.val, content="1")

  app = app.run_once()
  debug_inspect(registration_count.val, content="1")
}
