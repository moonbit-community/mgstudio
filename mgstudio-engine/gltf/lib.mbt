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
pub type GltfLoaderRegistration = @gltf_loader.GltfLoaderRegistration

///|
pub type GltfLoaderSettings = @gltf_loader.GltfLoaderSettings

///|
pub type GltfAssetLabel = @gltf_loader.GltfAssetLabel

///|
pub type GltfSceneIndex = @gltf_loader.GltfSceneIndex

///|
pub type GltfNodeIndex = @gltf_loader.GltfNodeIndex

///|
pub type GltfMeshIndex = @gltf_loader.GltfMeshIndex

///|
pub type GltfPrimitiveIndex = @gltf_loader.GltfPrimitiveIndex

///|
pub type GltfMaterialName = @gltf_loader.GltfMaterialName

///|
pub type GltfSkinIndex = @gltf_loader.GltfSkinIndex

///|
pub type GltfExtras = @gltf_loader.GltfExtras

///|
pub type GltfSceneExtras = @gltf_loader.GltfSceneExtras

///|
pub type GltfMeshExtras = @gltf_loader.GltfMeshExtras

///|
pub type GltfMaterialExtras = @gltf_loader.GltfMaterialExtras

///|
pub type GltfCustomVertexAttribute = @gltf_loader.GltfCustomVertexAttribute

///|
pub type GltfConvertCoordinates = @gltf_loader.GltfConvertCoordinates

///|
pub type GltfSkinnedMeshBoundsPolicy = @gltf_loader.GltfSkinnedMeshBoundsPolicy

///|
pub type GltfPlugin = @gltf_loader.GltfPlugin

///|
pub fn gltf_plugin_with(
  app : @app.App[@ecs.World],
  plugin : GltfPlugin,
) -> @app.App[@ecs.World] {
  @gltf_loader.gltf_plugin_with(app, plugin)
}

///|
pub fn gltf_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @gltf_loader.gltf_plugin(app)
}
