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
pub struct AudioSource {
  bytes : Bytes
} derive(ToJson, FromJson)

///|
pub fn AudioSource::new(bytes : Bytes) -> AudioSource {
  AudioSource::{ bytes, }
}

///|
pub fn AudioSource::bytes(self : AudioSource) -> Bytes {
  self.bytes
}

///|
priv struct AudioSourceAssetPaths {
  paths : Array[(String, @asset.Handle[AudioSource])]
}

///|
fn AudioSourceAssetPaths::new() -> AudioSourceAssetPaths {
  AudioSourceAssetPaths::{ paths: [] }
}

///|
fn AudioSourceAssetPaths::find_path_handle(
  self : AudioSourceAssetPaths,
  canonical_path : String,
) -> @asset.Handle[AudioSource]? {
  for i in 0..<self.paths.length() {
    let entry = self.paths[i]
    if entry.0 == canonical_path {
      return Some(entry.1)
    }
  }
  None
}

///|
fn AudioSourceAssetPaths::register_path(
  self : AudioSourceAssetPaths,
  canonical_path : String,
  handle : @asset.Handle[AudioSource],
) -> Unit {
  for i in 0..<self.paths.length() {
    if self.paths[i].0 == canonical_path {
      self.paths[i] = (canonical_path, handle)
      return
    }
  }
  self.paths.push((canonical_path, handle))
}

///|
let audio_source_asset_paths_resource_key : @ecs.ResourceKey[
  AudioSourceAssetPaths,
] = @ecs.register_resource(
  debug_name="mgstudio_audio::AudioSourceAssetPaths",
)

///|
impl @app.Resource for AudioSourceAssetPaths with resource() {
  audio_source_asset_paths_resource_key
}

///|
fn audio_source_assets_mut_or_abort(
  world : @ecs.World,
) -> @ecs.ResourceMut[@asset.Assets[AudioSource]] {
  let key : @ecs.ResourceKey[
    @asset.Assets[AudioSource],
  ] = @asset.assets_resource_key()
  match audio_resource_mut(world, key) {
    Some(assets) => assets
    None =>
      abort(
        "Assets<AudioSource> resource is missing; add AudioPlugin before using audio sources",
      )
  }
}

///|
fn audio_source_assets_or_none(world : @ecs.World) -> @asset.Assets[AudioSource]? {
  let key : @ecs.ResourceKey[
    @asset.Assets[AudioSource],
  ] = @asset.assets_resource_key()
  audio_resource_get(world, key)
}

///|
pub fn audio_source_add(
  world : @ecs.World,
  source : AudioSource,
) -> @asset.Handle[AudioSource] {
  audio_source_assets_mut_or_abort(world).modify(fn(value) {
    value.add(source)
  })
}

///|
pub fn audio_source_get(
  world : @ecs.World,
  handle : @asset.Handle[AudioSource],
) -> AudioSource? {
  match audio_source_assets_or_none(world) {
    Some(assets) => assets.get(handle)
    None => None
  }
}

///|
pub fn audio_source_set(
  world : @ecs.World,
  handle : @asset.Handle[AudioSource],
  source : AudioSource,
) -> Bool {
  audio_source_assets_mut_or_abort(world).modify(fn(value) {
    value.set(handle, source)
  })
}

///|
pub fn audio_source_from_blob(
  blob : @asset.Handle[@asset.Blob],
) -> AudioSource? {
  match @asset.asset_blob_read_bytes(blob) {
    Some(bytes) => Some(AudioSource::new(bytes))
    None => None
  }
}

///|
pub fn audio_source_load(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
  path : String,
) -> @asset.Handle[AudioSource]? {
  let canonical_path = @asset.asset_canonical_path(path)
  let paths = audio_resource_ensure_mut(world, AudioSourceAssetPaths::resource(), fn() {
    AudioSourceAssetPaths::new()
  })
  match paths.peek().find_path_handle(canonical_path) {
    Some(handle) => Some(handle)
    None => {
      let blob = asset_server.load_bytes(canonical_path)
      match audio_source_from_blob(blob) {
        Some(source) => {
          let handle = audio_source_assets_mut_or_abort(world).modify(fn(value) {
            value.add(source)
          })
          ignore(paths.modify(fn(value) {
            value.register_path(canonical_path, handle)
          }))
          Some(handle)
        }
        None => None
      }
    }
  }
}

///|
fn audio_source_load_registered(
  asset_server : @asset.AssetServer,
  path : String,
) -> @asset.Handle[AudioSource] {
  let world = match @app.current_world() {
    Some(world) => world
    None =>
      abort(
        "AssetServer::load[AudioSource] requires an active app world; load the audio plugin and call it from a scheduled system",
      )
  }
  match audio_source_load(world, asset_server, path) {
    Some(handle) => handle
    None => abort("Failed to decode AudioSource bytes for asset path \{path}")
  }
}
