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
// Bevy source: `bevy/crates/bevy_asset/src/direct_access_ext.rs`.
pub fn[T] asset_world_add(world : @ecs.World, asset : T) -> Handle[T] {
  match (try! world.get_resource_mut(assets_resource_key())) {
    Some(assets) => assets.modify(fn(value) { value.add(asset) })
    None =>
      abort(
        "Assets resource is missing; initialize the asset store before inserting through direct asset access",
      )
  }
}

///|
pub fn[T, P : IntoAssetPath] asset_world_load(
  world : @ecs.World,
  path : P,
) -> Handle[T] {
  asset_with_world(world, fn() { asset_server_or_abort().load(path) })
}

///|
pub fn[T, P : IntoAssetPath] asset_world_load_with_settings(
  world : @ecs.World,
  path : P,
  configure : (ImageLoaderSettings) -> Unit,
) -> Handle[T] {
  asset_with_world(world, fn() {
    asset_server_or_abort().load_with_settings(path, configure)
  })
}
