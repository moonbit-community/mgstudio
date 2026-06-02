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
// Bevy source: `bevy/crates/bevy_render/src/texture/gpu_image.rs` and
// `bevy/crates/bevy_render/src/render_asset.rs`.

///|
let gpu_image_render_asset_resource_keys : RenderAssetResourceKeys[
  @render_texture.GpuImage,
] = register_render_asset_resource_keys("mgstudio_render::GpuImage")

///|
pub impl RenderAssetResource for @render_texture.GpuImage with fn render_asset_resource_debug_name() {
  "mgstudio_render::GpuImage"
}

///|
pub impl RenderAssetResource for @render_texture.GpuImage with fn render_asset_resource_keys() {
  gpu_image_render_asset_resource_keys
}

///|
pub fn ensure_gpu_image_render_assets_resource(world : @ecs.World) -> Unit {
  let key : @ecs.ResourceKey[RenderAssets[@render_texture.GpuImage]] = RenderAssets::resource()
  if world.get_resource(key) is None {
    world.insert_resource(key, RenderAssets::new())
  }
}

///|
pub fn prepare_gpu_image_render_asset(
  world : @ecs.World,
  image_asset_id : @asset.AssetId[@asset.Image],
) -> Unit {
  ensure_gpu_image_render_assets_resource(world)
  guard @render_texture.GpuImage::from_texture_id(image_asset_id.index())
    is Some(gpu_image) else {
    return
  }
  let key : @ecs.ResourceKey[RenderAssets[@render_texture.GpuImage]] = RenderAssets::resource()
  ignore(
    world
    .resource(key)
    .update(fn(render_assets) {
      render_assets.insert(image_asset_id.index(), gpu_image)
      render_assets
    }),
  )
}
