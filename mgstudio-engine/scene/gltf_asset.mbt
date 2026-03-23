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
pub struct Gltf {
  scenes : Array[@asset.Handle[Scene]]
  default_scene : @asset.Handle[Scene]?
}

///|
pub fn Gltf::new(
  scenes : Array[@asset.Handle[Scene]],
  default_scene : @asset.Handle[Scene]?,
) -> Gltf {
  Gltf::{ scenes, default_scene }
}

///|
fn gltf_asset_default() -> Gltf {
  Gltf::{ scenes: [], default_scene: None }
}

///|
fn scene_gltf_scene_asset_path(
  root_path : @asset.AssetPath,
  scene_index : Int,
) -> String {
  @asset.asset_format_path(
    root_path.with_label(Some("Scene" + scene_index.to_string())),
  )
}

///|
fn scene_load_gltf_root_asset(
  asset_server : @asset.AssetServer,
  path : @asset.AssetPath,
  bytes : Bytes,
) -> Gltf {
  let root_path = path.with_label(None)
  let formatted_path = @asset.asset_format_path(root_path)
  let parsed = match gltf_parse_source(formatted_path, bytes) {
    Some(parsed) => parsed
    None => abort("Failed to parse glTF asset " + formatted_path)
  }
  let (doc, _buffer_bytes) = parsed
  let scenes : Array[@asset.Handle[Scene]] = []
  for scene_index in 0..<doc.scenes.length() {
    scenes.push(
      scene_load_gltf_scene(
        asset_server,
        scene_gltf_scene_asset_path(root_path, scene_index),
      ),
    )
  }
  let default_scene = if scenes.length() == 0 {
    None
  } else {
    let scene_index = gltf_select_scene_index(doc, doc.default_scene)
    Some(scenes[scene_index])
  }
  Gltf::new(scenes, default_scene)
}

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
