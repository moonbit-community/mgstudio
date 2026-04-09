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
pub using @root_gltf {type GltfAssetLabel}

///|
pub using @root_gltf {type GltfCustomVertexAttribute}

///|
pub using @root_gltf {type GltfExtensionHandler}

///|
pub using @root_gltf {type GltfExtensionHandlers}

///|
pub using @root_gltf {type GltfLoaderRegistration}

///|
pub using @root_gltf {type GltfLoaderSettings}

///|
pub using @root_gltf {type GltfExtras}

///|
pub using @root_gltf {type GltfMaterialExtras}

///|
pub using @root_gltf {type GltfMaterialName}

///|
pub using @root_gltf {type GltfMeshExtras}

///|
pub using @root_gltf {type GltfMeshIndex}

///|
pub using @root_gltf {type GltfNodeIndex}

///|
pub using @root_gltf {type GltfPrimitiveIndex}

///|
pub using @root_gltf {type GltfSceneExtras}

///|
pub using @root_gltf {type GltfSceneIndex}

///|
pub using @root_gltf {type GltfSkinIndex}

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
  @root_gltf.gltf_pbr_material_handler_enabled()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @root_gltf.gltf_plugin(app)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_register_extension_handler(handler : GltfExtensionHandler) -> Unit {
  @root_gltf.gltf_register_extension_handler(handler)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_resolve_custom_vertex_attribute_name(name : String) -> String? {
  @root_gltf.gltf_resolve_custom_vertex_attribute_name(name)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_set_pbr_material_handler_enabled(enabled : Bool) -> Unit {
  @root_gltf.gltf_set_pbr_material_handler_enabled(enabled)
}
