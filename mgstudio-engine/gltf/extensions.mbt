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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/extensions/mod.rs`.
// Root bridge to `gltf/loader/extensions`.
pub using @gltf_loader_extensions {type GltfExtensionHandler}

///|
pub using @gltf_loader_extensions {type GltfExtensionHandlers}

///|
pub fn gltf_register_extension_handler(handler : GltfExtensionHandler) -> Unit {
  @gltf_loader_extensions.gltf_register_extension_handler(handler)
}

///|
pub fn gltf_extension_handlers() -> GltfExtensionHandlers {
  @gltf_loader_extensions.gltf_extension_handlers()
}

///|
pub fn gltf_clear_extension_handlers() -> Unit {
  @gltf_loader_extensions.gltf_clear_extension_handlers()
}

///|
pub fn gltf_extension_notify_animations_collected(
  asset_path : String,
  animations : Array[@asset.Handle[@animation.AnimationClip]],
  named_animations : Array[(String, @asset.Handle[@animation.AnimationClip])],
  animation_roots : Array[Int],
) -> Unit {
  @gltf_loader_extensions.gltf_extension_notify_animations_collected(
    asset_path, animations, named_animations, animation_roots,
  )
}

///|
pub fn gltf_extension_notify_node_spawned(
  asset_path : String,
  node_index : Int,
  entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  @gltf_loader_extensions.gltf_extension_notify_node_spawned(
    asset_path, node_index, entity, world,
  )
}

///|
pub fn gltf_extension_notify_mesh_spawned(
  asset_path : String,
  mesh_index : Int,
  primitive_index : Int,
  entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  @gltf_loader_extensions.gltf_extension_notify_mesh_spawned(
    asset_path, mesh_index, primitive_index, entity, world,
  )
}

///|
pub fn gltf_extension_notify_scene_completed(
  asset_path : String,
  scene_index : Int,
  root_entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  @gltf_loader_extensions.gltf_extension_notify_scene_completed(
    asset_path, scene_index, root_entity, world,
  )
}
