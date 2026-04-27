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
pub fn pitch_add(world : @ecs.World, pitch : Pitch) -> @asset.Handle[Pitch] {
  let key : @ecs.ResourceKey[@asset.Assets[Pitch]] = @asset.assets_resource_key()
  guard audio_resource_mut(world, key) is Some(assets) else {
    abort(
      "Assets<Pitch> resource is missing; add AudioPlugin before using pitch audio",
    )
  }
  assets.modify(fn(value) { value.add(pitch) })
}

///|
pub fn pitch_get(world : @ecs.World, handle : @asset.Handle[Pitch]) -> Pitch? {
  let key : @ecs.ResourceKey[@asset.Assets[Pitch]] = @asset.assets_resource_key()
  match audio_resource_get(world, key) {
    Some(assets) => assets.get(handle)
    None => None
  }
}

///|
pub fn pitch_set(
  world : @ecs.World,
  handle : @asset.Handle[Pitch],
  pitch : Pitch,
) -> Bool {
  let key : @ecs.ResourceKey[@asset.Assets[Pitch]] = @asset.assets_resource_key()
  guard audio_resource_mut(world, key) is Some(assets) else { return false }
  assets.modify(fn(value) { value.set(handle, pitch) })
}
