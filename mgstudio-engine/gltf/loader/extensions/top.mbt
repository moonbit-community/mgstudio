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
let gltf_extension_handlers_registry_bootstrap : Array[GltfExtensionHandler] = []

///|
let gltf_pbr_material_handler_enabled_bootstrap_ref : Ref[Bool] = Ref::new(true)

///|
pub struct GltfExtensionRuntimeState {
  handlers : Array[GltfExtensionHandler]
  mut pbr_material_handler_enabled : Bool
}

///|
fn GltfExtensionRuntimeState::from_bootstrap() -> GltfExtensionRuntimeState {
  let handlers : Array[GltfExtensionHandler] = []
  for handler in gltf_extension_handlers_registry_bootstrap {
    handlers.push(handler)
  }
  GltfExtensionRuntimeState::{
    handlers,
    pbr_material_handler_enabled: gltf_pbr_material_handler_enabled_bootstrap_ref.val,
  }
}

///|
pub let ecs_key_gltf_extension_runtime_state : @ecs.ResourceKey[
  GltfExtensionRuntimeState,
] = @ecs.register_resource(debug_name="gltf.loader.extensions.runtime_state")

///|
pub impl @app.Resource for GltfExtensionRuntimeState with resource() {
  ecs_key_gltf_extension_runtime_state
}

///|
pub fn gltf_extension_runtime_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  if app.contains_resource(ecs_key_gltf_extension_runtime_state) {
    app
  } else {
    app.insert_world_resource(
      ecs_key_gltf_extension_runtime_state,
      GltfExtensionRuntimeState::from_bootstrap(),
    )
  }
}

///|
fn gltf_extension_runtime_state_ref_if_present() -> Ref[
  GltfExtensionRuntimeState,
]? {
  guard @app.current_world() is Some(world) else { return None }
  try world.get_resource_ref_mut(ecs_key_gltf_extension_runtime_state) catch {
    _ => None
  } noraise {
    value => value
  }
}

///|
fn gltf_extension_runtime_handlers() -> Array[GltfExtensionHandler] {
  if gltf_extension_runtime_state_ref_if_present() is Some(state_ref) {
    return state_ref.val.handlers
  }
  gltf_extension_handlers_registry_bootstrap
}

///|
pub fn gltf_register_extension_handler(handler : GltfExtensionHandler) -> Unit {
  gltf_extension_handlers_registry_bootstrap.push(handler)
  if gltf_extension_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.handlers.push(handler)
  }
}

///|
pub fn gltf_extension_handlers() -> GltfExtensionHandlers {
  GltfExtensionHandlers::new(gltf_extension_runtime_handlers())
}

///|
pub fn gltf_clear_extension_handlers() -> Unit {
  gltf_extension_handlers_registry_bootstrap.clear()
  if gltf_extension_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.handlers.clear()
  }
}

///|
pub fn gltf_extension_notify_animations_collected(
  asset_path : String,
  animations : Array[@asset.Handle[@animation.AnimationClip]],
  named_animations : Array[(String, @asset.Handle[@animation.AnimationClip])],
  animation_roots : Array[Int],
) -> Unit {
  for handler in gltf_extension_runtime_handlers() {
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
  for handler in gltf_extension_runtime_handlers() {
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
  for handler in gltf_extension_runtime_handlers() {
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
  for handler in gltf_extension_runtime_handlers() {
    if handler.on_scene_completed is Some(callback) {
      callback(asset_path, scene_index, root_entity, world)
    }
  }
}

///|
pub fn gltf_set_pbr_material_handler_enabled(enabled : Bool) -> Unit {
  gltf_pbr_material_handler_enabled_bootstrap_ref.val = enabled
  if gltf_extension_runtime_state_ref_if_present() is Some(state_ref) {
    state_ref.val.pbr_material_handler_enabled = enabled
  }
}

///|
pub fn gltf_pbr_material_handler_enabled() -> Bool {
  if gltf_extension_runtime_state_ref_if_present() is Some(state_ref) {
    return state_ref.val.pbr_material_handler_enabled
  }
  gltf_pbr_material_handler_enabled_bootstrap_ref.val
}
