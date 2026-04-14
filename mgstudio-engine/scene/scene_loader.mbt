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
// Bevy source: `bevy/crates/bevy_scene/src/scene_loader.rs`.

///|
fn scene_asset_ready(world : @ecs.World, handle : @asset.Handle[Scene]) -> Bool {
  let key : @ecs.ResourceKey[@asset.Assets[Scene]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) =>
      match assets.get(handle) {
        Some(scene) => scene.ready
        None => false
      }
    None => false
  }
}

///|
fn gltf_asset_ready(world : @ecs.World, handle : @asset.Handle[Gltf]) -> Bool {
  let key : @ecs.ResourceKey[@asset.Assets[Gltf]] = @asset.assets_resource_key()
  match (try! world.get_resource(key)) {
    Some(assets) =>
      match assets.get(handle) {
        Some(gltf) => {
          for scene_handle in gltf.scenes {
            if !scene_asset_ready(world, scene_handle) {
              return false
            }
          }
          true
        }
        None => false
      }
    None => false
  }
}

///|
fn scene_init_gltf_assets(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @asset.asset_register_ready_checker(scene_asset_ready)
  @asset.asset_register_ready_checker(gltf_asset_ready)
  @asset.init_asset_loader(
    @asset.init_asset(app, gltf_asset_default),
    @asset.AssetLoader::new(["gltf", "glb"], scene_load_gltf_root_asset),
  )
}

///|
fn scene_registry_from_world(world : @ecs.World) -> SceneAssetRegistryState? {
  let key : @ecs.ResourceKey[SceneAssetRegistryState] = SceneAssetRegistryState::resource()
  try! world.get_resource(key)
}

///|
fn scene_asset_base_path(asset_path : String) -> String {
  let (gltf_path, _label) = scene_split_gltf_asset_path(asset_path)
  @asset.asset_canonical_path(gltf_path)
}

///|
fn scene_reload_asset_path(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
  canonical_path : String,
) -> Unit {
  guard scene_registry_from_world(world) is Some(registry) else { return }

  let scenes_to_reload : Array[(@asset.Handle[Scene], String)] = []
  for entry in registry.scene_registry {
    if scene_asset_base_path(entry.0) == canonical_path {
      scenes_to_reload.push((entry.1, entry.0))
    }
  }

  let animations_to_reload : Array[
    (@asset.Handle[@animation.AnimationClip], String),
  ] = []
  for entry in registry.animation_registry {
    if scene_asset_base_path(entry.0) == canonical_path {
      animations_to_reload.push((entry.1, entry.0))
    }
  }

  let meshes_to_reload : Array[(@asset.Handle[@mesh.Mesh], String)] = []
  for entry in registry.mesh_registry {
    if scene_asset_base_path(entry.0) == canonical_path {
      meshes_to_reload.push((entry.1, entry.0))
    }
  }

  if scenes_to_reload.length() == 0 &&
    animations_to_reload.length() == 0 &&
    meshes_to_reload.length() == 0 {
    return
  }

  for entry in scenes_to_reload {
    scene_queue_gltf_request(world, asset_server, entry.0, entry.1)
  }
  for entry in animations_to_reload {
    scene_queue_gltf_animation_request(world, asset_server, entry.0, entry.1)
  }
  for entry in meshes_to_reload {
    scene_queue_gltf_mesh_request(world, asset_server, entry.0, entry.1)
  }
}
