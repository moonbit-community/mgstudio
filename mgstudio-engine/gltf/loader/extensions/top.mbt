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
// Bevy source: `bevy/crates/bevy_gltf/src/loader/extensions/mod.rs`.
// Bridge surface to the root `gltf` package implementation.
pub using @root_gltf {type GltfExtensionHandler}

///|
pub using @root_gltf {type GltfExtensionHandlers}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_clear_extension_handlers() -> Unit {
  @root_gltf.gltf_clear_extension_handlers()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_extension_handlers() -> GltfExtensionHandlers {
  @root_gltf.gltf_extension_handlers()
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_register_extension_handler(handler : GltfExtensionHandler) -> Unit {
  @root_gltf.gltf_register_extension_handler(handler)
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_extension_notify_animations_collected(
  source : String,
  animations : Array[@asset.Handle[@animation.AnimationClip]],
  named_animations : Array[(String, @asset.Handle[@animation.AnimationClip])],
  animation_roots : Array[Int],
) -> Unit {
  @root_gltf.gltf_extension_notify_animations_collected(
    source, animations, named_animations, animation_roots,
  )
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_extension_notify_mesh_spawned(
  source : String,
  mesh_index : Int,
  primitive_index : Int,
  entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  @root_gltf.gltf_extension_notify_mesh_spawned(
    source, mesh_index, primitive_index, entity, world,
  )
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_extension_notify_node_spawned(
  source : String,
  node_index : Int,
  entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  @root_gltf.gltf_extension_notify_node_spawned(
    source, node_index, entity, world,
  )
}

///|
// Bridge surface to the root `gltf` package implementation.
pub fn gltf_extension_notify_scene_completed(
  source : String,
  scene_index : Int,
  entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  @root_gltf.gltf_extension_notify_scene_completed(
    source, scene_index, entity, world,
  )
}
