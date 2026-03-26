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
pub struct GltfCustomVertexAttribute {
  gltf_name : String
  mapped_name : String
}

///|
pub fn GltfCustomVertexAttribute::new(
  gltf_name : String,
  mapped_name : String,
) -> GltfCustomVertexAttribute {
  { gltf_name, mapped_name }
}

///|
pub fn GltfCustomVertexAttribute::gltf_name(
  self : GltfCustomVertexAttribute,
) -> String {
  self.gltf_name
}

///|
pub fn GltfCustomVertexAttribute::mapped_name(
  self : GltfCustomVertexAttribute,
) -> String {
  self.mapped_name
}

///|
pub struct GltfExtensionHandler {
  on_animations_collected : ((
    String,
    Array[@asset.Handle[@animation.AnimationClip]],
    Array[(String, @asset.Handle[@animation.AnimationClip])],
    Array[Int],
  ) -> Unit)?
  on_node_spawned : ((String, Int, @core.Entity, @ecs.World) -> Unit)?
  on_mesh_spawned : ((String, Int, Int, @core.Entity, @ecs.World) -> Unit)?
  on_scene_completed : ((String, Int, @core.Entity, @ecs.World) -> Unit)?
}

///|
pub fn GltfExtensionHandler::new(
  on_animations_collected? : ((
    String,
    Array[@asset.Handle[@animation.AnimationClip]],
    Array[(String, @asset.Handle[@animation.AnimationClip])],
    Array[Int],
  ) -> Unit)? = None,
  on_node_spawned? : ((String, Int, @core.Entity, @ecs.World) -> Unit)? = None,
  on_mesh_spawned? : ((String, Int, Int, @core.Entity, @ecs.World) -> Unit)? = None,
  on_scene_completed? : ((String, Int, @core.Entity, @ecs.World) -> Unit)? = None,
) -> GltfExtensionHandler {
  {
    on_animations_collected,
    on_node_spawned,
    on_mesh_spawned,
    on_scene_completed,
  }
}

///|
pub struct GltfExtensionHandlers {
  handlers : Array[GltfExtensionHandler]
}

///|
pub fn GltfExtensionHandlers::new(
  handlers : Array[GltfExtensionHandler],
) -> GltfExtensionHandlers {
  { handlers, }
}

///|
pub fn GltfExtensionHandlers::handlers(
  self : GltfExtensionHandlers,
) -> Array[GltfExtensionHandler] {
  self.handlers
}

///|
let gltf_custom_vertex_attributes_registry : Array[GltfCustomVertexAttribute] = []

///|
let gltf_extension_handlers_registry : Array[GltfExtensionHandler] = []

///|
fn gltf_attribute_name_matches(
  registered_name : String,
  attribute_name : String,
) -> Bool {
  if registered_name == attribute_name {
    return true
  }
  if attribute_name.length() > 0 && attribute_name.code_unit_at(0) == 95 {
    return registered_name ==
      attribute_name[1:attribute_name.length()].to_string()
  }
  false
}

///|
pub fn gltf_add_custom_vertex_attribute(
  gltf_name : String,
  mapped_name : String,
) -> Unit {
  for i in 0..<gltf_custom_vertex_attributes_registry.length() {
    if gltf_custom_vertex_attributes_registry[i].gltf_name() == gltf_name {
      gltf_custom_vertex_attributes_registry[i] = GltfCustomVertexAttribute::new(
        gltf_name, mapped_name,
      )
      return
    }
  }
  gltf_custom_vertex_attributes_registry.push(
    GltfCustomVertexAttribute::new(gltf_name, mapped_name),
  )
}

///|
pub fn gltf_custom_vertex_attributes() -> Array[GltfCustomVertexAttribute] {
  gltf_custom_vertex_attributes_registry
}

///|
pub fn gltf_clear_custom_vertex_attributes() -> Unit {
  gltf_custom_vertex_attributes_registry.clear()
}

///|
pub fn gltf_register_extension_handler(handler : GltfExtensionHandler) -> Unit {
  gltf_extension_handlers_registry.push(handler)
}

///|
pub fn gltf_extension_handlers() -> GltfExtensionHandlers {
  GltfExtensionHandlers::new(gltf_extension_handlers_registry)
}

///|
pub fn gltf_clear_extension_handlers() -> Unit {
  gltf_extension_handlers_registry.clear()
}

///|
pub fn gltf_resolve_custom_vertex_attribute_name(
  attribute_name : String,
) -> String? {
  for attribute in gltf_custom_vertex_attributes_registry {
    if gltf_attribute_name_matches(attribute.gltf_name(), attribute_name) {
      return Some(attribute.mapped_name())
    }
  }
  None
}

///|
pub fn gltf_extension_notify_animations_collected(
  asset_path : String,
  animations : Array[@asset.Handle[@animation.AnimationClip]],
  named_animations : Array[(String, @asset.Handle[@animation.AnimationClip])],
  animation_roots : Array[Int],
) -> Unit {
  for handler in gltf_extension_handlers_registry {
    if handler.on_animations_collected is Some(callback) {
      callback(asset_path, animations, named_animations, animation_roots)
    }
  }
}

///|
pub fn gltf_extension_notify_node_spawned(
  asset_path : String,
  node_index : Int,
  entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  for handler in gltf_extension_handlers_registry {
    if handler.on_node_spawned is Some(callback) {
      callback(asset_path, node_index, entity, world)
    }
  }
}

///|
pub fn gltf_extension_notify_mesh_spawned(
  asset_path : String,
  mesh_index : Int,
  primitive_index : Int,
  entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  for handler in gltf_extension_handlers_registry {
    if handler.on_mesh_spawned is Some(callback) {
      callback(asset_path, mesh_index, primitive_index, entity, world)
    }
  }
}

///|
pub fn gltf_extension_notify_scene_completed(
  asset_path : String,
  scene_index : Int,
  root_entity : @core.Entity,
  world : @ecs.World,
) -> Unit {
  for handler in gltf_extension_handlers_registry {
    if handler.on_scene_completed is Some(callback) {
      callback(asset_path, scene_index, root_entity, world)
    }
  }
}
