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
let pitch_assets_resource : Ref[@core.Resource[PitchAssets]] = Ref::new(
  @core.Resource::new(),
)

///|
pub impl @app.Resource for PitchAssets with resource() {
  pitch_assets_resource.val
}

///|
pub fn pitch_add(pitch : Pitch) -> @asset.Handle[Pitch] {
  let tick = @app.current_system_ticks().this_run
  if !pitch_assets_resource.val.is_present() {
    pitch_assets_resource.val.insert(PitchAssets::new(), tick)
  }
  let assets_ref = pitch_assets_resource.val.get_ref_mut(tick).unwrap()
  assets_ref.val.add(pitch)
}

///|
pub fn pitch_get(handle : @asset.Handle[Pitch]) -> Pitch? {
  match pitch_assets_resource.val.get() {
    Some(assets) => assets.get(handle)
    None => None
  }
}

///|
pub fn pitch_set(handle : @asset.Handle[Pitch], pitch : Pitch) -> Bool {
  let tick = @app.current_system_ticks().this_run
  guard pitch_assets_resource.val.get_ref_mut(tick) is Some(assets_ref) else {
    return false
  }
  assets_ref.val.set(handle, pitch)
}
