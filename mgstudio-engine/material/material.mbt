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
/// Material-facing API boundary aligned with Bevy's `bevy_material` crate.
/// Runtime implementation currently lives in `Milky2018/mgstudio/pbr`.

///|
pub type AlphaMode = @pbr.AlphaMode3d

///|
pub type AlphaMode3d = @pbr.AlphaMode3d

///|
pub type Face3d = @pbr.Face3d

///|
pub type OpaqueRendererMethod = @pbr.OpaqueRendererMethod

///|
pub type DefaultOpaqueRendererMethod = @pbr.DefaultOpaqueRendererMethod

///|
pub type ParallaxMappingMethod = @pbr.ParallaxMappingMethod

///|
pub type StandardMaterial = @pbr.StandardMaterial

///|
pub type MeshMaterial3d = @pbr.MeshMaterial3d

///|
pub type MeshMaterial3dBundle = @pbr.MeshMaterial3dBundle

///|
pub type ExtendedMaterialMetadata3d = @pbr.ExtendedMaterialMetadata3d

///|
pub type ForwardDecalMaterialExt = @pbr.ForwardDecalMaterialExt

///|
pub let ecs_key_mesh_material3d : @ecs.ComponentKey[MeshMaterial3d] = @pbr.ecs_key_mesh_material3d

///|
pub let ecs_key_forward_decal_material_ext : @ecs.ComponentKey[
  ForwardDecalMaterialExt,
] = @pbr.ecs_key_forward_decal_material_ext

///|
pub let ecs_key_default_opaque_renderer_method : @ecs.ResourceKey[
  DefaultOpaqueRendererMethod,
] = @pbr.ecs_key_default_opaque_renderer_method

///|
pub fn standard_material_add(
  material : StandardMaterial,
) -> @asset.Handle[StandardMaterial] {
  @pbr.standard_material_add(material)
}

///|
pub fn standard_material_get(
  handle : @asset.Handle[StandardMaterial],
) -> StandardMaterial? {
  @pbr.standard_material_get(handle)
}

///|
pub fn standard_material_set(
  handle : @asset.Handle[StandardMaterial],
  material : StandardMaterial,
) -> Bool {
  @pbr.standard_material_set(handle, material)
}

///|
pub fn get_mesh_material3d_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[MeshMaterial3d] {
  @pbr.get_mesh_material3d_store(world)
}

///|
pub fn get_forward_decal_material_ext_store(
  world : @ecs.World,
) -> @ecs.ComponentAccess[ForwardDecalMaterialExt] {
  @pbr.get_forward_decal_material_ext_store(world)
}

///|
pub fn get_default_opaque_renderer_method_resource(
  world : @ecs.World,
) -> @ecs.ResourceAccess[DefaultOpaqueRendererMethod] {
  @pbr.get_default_opaque_renderer_method_resource(world)
}
