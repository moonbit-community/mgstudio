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
pub struct AudioSourceAssets {
  assets : @asset.Assets[AudioSource]
}

///|
pub fn AudioSourceAssets::new() -> AudioSourceAssets {
  AudioSourceAssets::{ assets: @asset.Assets::new() }
}

///|
pub fn AudioSourceAssets::add(
  self : AudioSourceAssets,
  source : AudioSource,
) -> @asset.Handle[AudioSource] {
  self.assets.add(source)
}

///|
pub fn AudioSourceAssets::get(
  self : AudioSourceAssets,
  handle : @asset.Handle[AudioSource],
) -> AudioSource? {
  self.assets.get(handle)
}

///|
pub fn AudioSourceAssets::set(
  self : AudioSourceAssets,
  handle : @asset.Handle[AudioSource],
  source : AudioSource,
) -> Bool {
  self.assets.set(handle, source)
}

///|
let audio_source_assets_resource_key : @ecs.ResourceKey[AudioSourceAssets] = @ecs.register_resource(
  debug_name="bevy_audio::AudioSourceAssets",
)

///|
pub impl @app.Resource for AudioSourceAssets with resource() {
  audio_source_assets_resource_key
}

///|
pub fn audio_source_add(source : AudioSource) -> @asset.Handle[AudioSource] {
  let tick = @app.current_system_ticks().this_run
  let assets_ref = audio_resource_ensure_ref_mut(
    AudioSourceAssets::resource(),
    fn() { AudioSourceAssets::new() },
    tick,
  )
  assets_ref.val.add(source)
}

///|
pub fn audio_source_get(handle : @asset.Handle[AudioSource]) -> AudioSource? {
  match audio_resource_get(AudioSourceAssets::resource()) {
    Some(assets) => assets.get(handle)
    None => None
  }
}

///|
pub fn audio_source_set(
  handle : @asset.Handle[AudioSource],
  source : AudioSource,
) -> Bool {
  let tick = @app.current_system_ticks().this_run
  guard audio_resource_ref_mut(AudioSourceAssets::resource(), tick)
    is Some(assets_ref) else {
    return false
  }
  assets_ref.val.set(handle, source)
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
  asset_server : @asset.AssetServer,
  path : String,
) -> @asset.Handle[AudioSource]? {
  let blob = asset_server.load_bytes(path)
  match audio_source_from_blob(blob) {
    Some(source) => Some(audio_source_add(source))
    None => None
  }
}
