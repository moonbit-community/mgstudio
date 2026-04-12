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
// Bevy source: `bevy/crates/bevy_gltf/src/lib.rs`.
pub type GltfLoaderRegistration = () -> Unit

///|
pub type GltfLoaderSettings = @asset.ImageLoaderSettings

///|
pub type GltfAssetLabel = @gltf_gltf_ext.GltfAssetLabel

///|
pub type GltfSceneIndex = @gltf_gltf_ext.GltfSceneIndex

///|
pub type GltfNodeIndex = @gltf_gltf_ext.GltfNodeIndex

///|
pub type GltfMeshIndex = @gltf_gltf_ext.GltfMeshIndex

///|
pub type GltfPrimitiveIndex = @gltf_gltf_ext.GltfPrimitiveIndex

///|
pub type GltfMaterialName = @gltf_gltf_ext.GltfMaterialName

///|
pub type GltfSkinIndex = @gltf_gltf_ext.GltfSkinIndex

///|
pub type GltfExtras = @gltf_gltf_ext.GltfExtras

///|
pub type GltfSceneExtras = @gltf_gltf_ext.GltfSceneExtras

///|
pub type GltfMeshExtras = @gltf_gltf_ext.GltfMeshExtras

///|
pub type GltfMaterialExtras = @gltf_gltf_ext.GltfMaterialExtras

///|
pub(all) enum GltfSkinnedMeshBoundsPolicy {
  BindPose
  Dynamic
  NoFrustumCulling
} derive(Eq)

///|
pub fn GltfSkinnedMeshBoundsPolicy::default() -> GltfSkinnedMeshBoundsPolicy {
  Dynamic
}

///|
pub struct GltfPlugin {
  pbr_material_handler_enabled : Bool
  convert_coordinates : GltfConvertCoordinates
  custom_vertex_attributes : Array[GltfCustomVertexAttribute]
  extension_handlers : Array[GltfExtensionHandler]
  skinned_mesh_bounds_policy : GltfSkinnedMeshBoundsPolicy
}

///|
pub fn GltfPlugin::default() -> GltfPlugin {
  {
    pbr_material_handler_enabled: true,
    convert_coordinates: GltfConvertCoordinates::default(),
    custom_vertex_attributes: [],
    extension_handlers: [],
    skinned_mesh_bounds_policy: GltfSkinnedMeshBoundsPolicy::default(),
  }
}

///|
pub fn GltfPlugin::with_pbr_material_handler_enabled(
  self : GltfPlugin,
  enabled : Bool,
) -> GltfPlugin {
  { ..self, pbr_material_handler_enabled: enabled }
}

///|
pub fn GltfPlugin::add_custom_vertex_attribute(
  self : GltfPlugin,
  gltf_name : String,
  mapped_name : String,
) -> GltfPlugin {
  {
    ..self,
    custom_vertex_attributes: [
      ..self.custom_vertex_attributes,
      GltfCustomVertexAttribute::new(gltf_name, mapped_name),
    ],
  }
}

///|
pub fn GltfPlugin::with_convert_coordinates(
  self : GltfPlugin,
  convert_coordinates : GltfConvertCoordinates,
) -> GltfPlugin {
  { ..self, convert_coordinates, }
}

///|
pub fn GltfPlugin::add_extension_handler(
  self : GltfPlugin,
  handler : GltfExtensionHandler,
) -> GltfPlugin {
  { ..self, extension_handlers: [..self.extension_handlers, handler] }
}

///|
pub fn GltfPlugin::with_skinned_mesh_bounds_policy(
  self : GltfPlugin,
  policy : GltfSkinnedMeshBoundsPolicy,
) -> GltfPlugin {
  { ..self, skinned_mesh_bounds_policy: policy }
}

///|
pub fn gltf_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GltfPlugin,
) -> @app.App[@ecs.World] {
  gltf_set_pbr_material_handler_enabled(plugin.pbr_material_handler_enabled)
  gltf_set_default_convert_coordinates(plugin.convert_coordinates)
  gltf_set_default_skinned_mesh_bounds_policy(plugin.skinned_mesh_bounds_policy)
  gltf_clear_custom_vertex_attributes()
  for custom_attribute in plugin.custom_vertex_attributes {
    gltf_add_custom_vertex_attribute(
      custom_attribute.gltf_name(),
      custom_attribute.mapped_name(),
    )
  }
  gltf_clear_extension_handlers()
  for handler in plugin.extension_handlers {
    gltf_register_extension_handler(handler)
  }
  gltf_register_asset_loaders_once()
  app
}

///|
pub fn gltf_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  gltf_plugin_with(app, GltfPlugin::default())
}
