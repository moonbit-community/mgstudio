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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/mod.rs`.
// Bridge surface to the root `gltf` package implementation.
pub using @gltf_gltf_ext {type GltfAssetLabel}

///|
pub using @root_gltf {type GltfCustomVertexAttribute}

///|
pub using @gltf_loader_extensions {type GltfExtensionHandler}

///|
pub using @gltf_loader_extensions {type GltfExtensionHandlers}

///|
pub using @root_gltf {type GltfLoaderRegistration}

///|
pub using @root_gltf {type GltfLoaderSettings}

///|
pub using @root_gltf {type GltfPlugin}

///|
pub using @root_gltf {type GltfSkinnedMeshBoundsPolicy}

///|
pub using @gltf_gltf_ext {type GltfExtras}

///|
pub using @gltf_gltf_ext {type GltfMaterialExtras}

///|
pub using @gltf_gltf_ext {type GltfMaterialName}

///|
pub using @gltf_gltf_ext {type GltfMeshExtras}

///|
pub using @gltf_gltf_ext {type GltfMeshIndex}

///|
pub using @gltf_gltf_ext {type GltfNodeIndex}

///|
pub using @gltf_gltf_ext {type GltfPrimitiveIndex}

///|
pub using @gltf_gltf_ext {type GltfSceneExtras}

///|
pub using @gltf_gltf_ext {type GltfSceneIndex}

///|
pub using @gltf_gltf_ext {type GltfSkinIndex}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_add_custom_vertex_attribute(
  name : String,
  mapped_name : String,
) -> Unit {
  @root_gltf.gltf_add_custom_vertex_attribute(name, mapped_name)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_clear_custom_vertex_attributes() -> Unit {
  @root_gltf.gltf_clear_custom_vertex_attributes()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_custom_vertex_attributes() -> Array[GltfCustomVertexAttribute] {
  @root_gltf.gltf_custom_vertex_attributes()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_install_loader_registration(
  registration : GltfLoaderRegistration,
) -> Unit {
  @root_gltf.gltf_install_loader_registration(registration)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_pbr_material_handler_enabled() -> Bool {
  @gltf_loader_extensions.gltf_pbr_material_handler_enabled()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GltfPlugin,
) -> @app.App[@ecs.World] {
  @root_gltf.gltf_plugin_with(app, plugin)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @root_gltf.gltf_plugin(app)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_register_extension_handler(handler : GltfExtensionHandler) -> Unit {
  @gltf_loader_extensions.gltf_register_extension_handler(handler)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_resolve_custom_vertex_attribute_name(name : String) -> String? {
  @root_gltf.gltf_resolve_custom_vertex_attribute_name(name)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_set_pbr_material_handler_enabled(enabled : Bool) -> Unit {
  @gltf_loader_extensions.gltf_set_pbr_material_handler_enabled(enabled)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_default_skinned_mesh_bounds_policy() -> GltfSkinnedMeshBoundsPolicy {
  @root_gltf.gltf_default_skinned_mesh_bounds_policy()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_set_default_skinned_mesh_bounds_policy(
  policy : GltfSkinnedMeshBoundsPolicy,
) -> Unit {
  @root_gltf.gltf_set_default_skinned_mesh_bounds_policy(policy)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_default_convert_coordinates() -> @root_gltf.GltfConvertCoordinates {
  @root_gltf.gltf_default_convert_coordinates()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_set_default_convert_coordinates(
  convert_coordinates : @root_gltf.GltfConvertCoordinates,
) -> Unit {
  @root_gltf.gltf_set_default_convert_coordinates(convert_coordinates)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_extras(value : String) -> GltfExtras {
  @gltf_gltf_ext.gltf_extras(value)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_material_name(name : String) -> GltfMaterialName {
  @gltf_gltf_ext.gltf_material_name(name)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_material_extras(value : String) -> GltfMaterialExtras {
  @gltf_gltf_ext.gltf_material_extras(value)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_mesh_extras(value : String) -> GltfMeshExtras {
  @gltf_gltf_ext.gltf_mesh_extras(value)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_scene_extras(value : String) -> GltfSceneExtras {
  @gltf_gltf_ext.gltf_scene_extras(value)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_mesh_index(mesh_index : Int) -> GltfMeshIndex {
  @gltf_gltf_ext.gltf_mesh_index(mesh_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_primitive_index(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfPrimitiveIndex {
  @gltf_gltf_ext.gltf_primitive_index(mesh_index, primitive_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_skin_index(skin_index : Int) -> GltfSkinIndex {
  @gltf_gltf_ext.gltf_skin_index(skin_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_scene_index(scene_index : Int) -> GltfSceneIndex {
  @gltf_gltf_ext.gltf_scene_index(scene_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_node_index(node_index : Int) -> GltfNodeIndex {
  @gltf_gltf_ext.gltf_node_index(node_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_scene_asset_label(scene_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_scene_asset_label(scene_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_node_asset_label(node_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_node_asset_label(node_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_mesh_asset_label(mesh_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_mesh_asset_label(mesh_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_primitive_asset_label(
  mesh_index : Int,
  primitive_index : Int,
) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_primitive_asset_label(mesh_index, primitive_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_skin_asset_label(skin_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_skin_asset_label(skin_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_material_asset_label(
  material_index : Int,
  is_scale_inverted : Bool,
) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_material_asset_label(material_index, is_scale_inverted)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_default_material_asset_label() -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_default_material_asset_label()
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_animation_asset_label(animation_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_animation_asset_label(animation_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_inverse_bind_matrices_asset_label(
  skin_index : Int,
) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_inverse_bind_matrices_asset_label(skin_index)
}

///|
// Bridge surface to the `gltf/loader/gltf_ext` package implementation.
pub fn gltf_texture_asset_label(texture_index : Int) -> GltfAssetLabel {
  @gltf_gltf_ext.gltf_texture_asset_label(texture_index)
}
