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
pub fn gltf_set_pbr_material_handler_enabled(enabled : Bool) -> Unit {
  @gltf_loader.gltf_set_pbr_material_handler_enabled(enabled)
}

///|
pub fn gltf_pbr_material_handler_enabled() -> Bool {
  @gltf_loader.gltf_pbr_material_handler_enabled()
}

///|
pub fn gltf_set_default_image_sampler(
  sampler : @image.ImageSamplerDescriptor,
) -> Unit {
  @gltf_loader.gltf_set_default_image_sampler(sampler)
}

///|
pub fn gltf_default_image_sampler() -> @image.ImageSamplerDescriptor {
  @gltf_loader.gltf_default_image_sampler()
}

///|
pub fn gltf_set_default_convert_coordinates(
  convert_coordinates : GltfConvertCoordinates,
) -> Unit {
  @gltf_loader.gltf_set_default_convert_coordinates(convert_coordinates)
}

///|
pub fn gltf_default_convert_coordinates() -> GltfConvertCoordinates {
  @gltf_loader.gltf_default_convert_coordinates()
}

///|
pub fn gltf_set_default_skinned_mesh_bounds_policy(
  policy : GltfSkinnedMeshBoundsPolicy,
) -> Unit {
  @gltf_loader.gltf_set_default_skinned_mesh_bounds_policy(policy)
}

///|
pub fn gltf_default_skinned_mesh_bounds_policy() -> GltfSkinnedMeshBoundsPolicy {
  @gltf_loader.gltf_default_skinned_mesh_bounds_policy()
}

///|
pub fn gltf_install_loader_registration(
  register : GltfLoaderRegistration,
) -> Unit {
  @gltf_loader.gltf_install_loader_registration(register)
}
