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
  animations : Array[@asset.Handle[@animation.AnimationClip]]
  named_animations : Array[(String, @asset.Handle[@animation.AnimationClip])]
  source : String?
}

///|
pub fn Gltf::new(
  scenes : Array[@asset.Handle[Scene]],
  default_scene : @asset.Handle[Scene]?,
  animations? : Array[@asset.Handle[@animation.AnimationClip]] = [],
  named_animations? : Array[(String, @asset.Handle[@animation.AnimationClip])] = [],
  source? : String? = None,
) -> Gltf {
  Gltf::{ scenes, default_scene, animations, named_animations, source }
}

///|
fn gltf_asset_default() -> Gltf {
  Gltf::{
    scenes: [],
    default_scene: None,
    animations: [],
    named_animations: [],
    source: None,
  }
}

///|
fn scene_gltf_scene_asset_path(
  root_path : @asset.AssetPath,
  scene_index : Int,
) -> String {
  @asset.asset_format_path(
    root_path.with_label(Some("Scene\{scene_index.to_string()}")),
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
  let loader_settings = asset_server.gltf_loader_settings_for_asset_path(
    formatted_path,
  )
  let parsed = match gltf_parse_source(formatted_path, bytes) {
    Some(parsed) => parsed
    None => abort("Failed to parse glTF asset \{formatted_path}")
  }
  let (doc, _buffer_bytes) = parsed
  let scenes : Array[@asset.Handle[Scene]] = []
  let animations : Array[@asset.Handle[@animation.AnimationClip]] = []
  let named_animations : Array[
    (String, @asset.Handle[@animation.AnimationClip]),
  ] = []
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
  for animation_index, animation in doc.animations {
    let handle = scene_load_gltf_animation(
      asset_server,
      @asset.asset_format_path(
        root_path.with_label(Some("Animation\{animation_index.to_string()}")),
      ),
    )
    animations.push(handle)
    if animation.name != "" {
      named_animations.push((animation.name, handle))
    }
  }
  @gltf_loader_extensions.gltf_extension_notify_animations_collected(
    @asset.asset_format_path(root_path),
    animations,
    named_animations,
    gltf_collect_animation_root_indices(doc),
  )
  let source = if loader_settings.include_source {
    match gltf_parse_glb(bytes) {
      Some(parsed_glb) => Some(parsed_glb.0)
      None => Some(bytes_text(bytes))
    }
  } else {
    None
  }
  Gltf::new(scenes, default_scene, animations~, named_animations~, source~)
}
