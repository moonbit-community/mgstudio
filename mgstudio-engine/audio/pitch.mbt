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
pub struct Pitch {
  frequency : Float
  duration_seconds : Float
} derive(ToJson, FromJson)

///|
pub fn Pitch::new(frequency : Float, duration_seconds : Float) -> Pitch {
  Pitch::{ frequency, duration_seconds }
}

///|
pub struct PitchAssets {
  assets : @asset.Assets[Pitch]
}

///|
pub fn PitchAssets::new() -> PitchAssets {
  PitchAssets::{ assets: @asset.Assets::new() }
}

///|
pub fn PitchAssets::add(
  self : PitchAssets,
  pitch : Pitch,
) -> @asset.Handle[Pitch] {
  self.assets.add(pitch)
}

///|
pub fn PitchAssets::get(
  self : PitchAssets,
  handle : @asset.Handle[Pitch],
) -> Pitch? {
  self.assets.get(handle)
}

///|
pub fn PitchAssets::set(
  self : PitchAssets,
  handle : @asset.Handle[Pitch],
  pitch : Pitch,
) -> Bool {
  self.assets.set(handle, pitch)
}

///|
let pitch_assets_resource_key : @ecs.ResourceKey[PitchAssets] = @ecs.register_resource(
  debug_name="bevy_audio::PitchAssets",
)

///|
pub impl @app.Resource for PitchAssets with resource() {
  pitch_assets_resource_key
}

///|
pub fn pitch_add(pitch : Pitch) -> @asset.Handle[Pitch] {
  let tick = @app.current_system_ticks().this_run
  let assets_ref = audio_resource_ensure_ref_mut(
    PitchAssets::resource(),
    fn() { PitchAssets::new() },
    tick,
  )
  assets_ref.val.add(pitch)
}

///|
pub fn pitch_get(handle : @asset.Handle[Pitch]) -> Pitch? {
  match audio_resource_get(PitchAssets::resource()) {
    Some(assets) => assets.get(handle)
    None => None
  }
}

///|
pub fn pitch_set(handle : @asset.Handle[Pitch], pitch : Pitch) -> Bool {
  let tick = @app.current_system_ticks().this_run
  guard audio_resource_ref_mut(PitchAssets::resource(), tick)
    is Some(assets_ref) else {
    return false
  }
  assets_ref.val.set(handle, pitch)
}
