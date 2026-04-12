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
pub fn scene_loader_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  scene_plugin(app)
}
