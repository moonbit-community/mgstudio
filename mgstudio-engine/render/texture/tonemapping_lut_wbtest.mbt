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
test "render/texture: bevy tonemapping ktx2 assets upload as 3d textures" {
  register_asset_texture_backend()
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let handle : @asset.Handle[@asset.Image] = @asset.asset_with_world(
    lifecycle_world_15_0,
    fn() {
      @asset.AssetServer::new().load(
        "textures/tonemapping/AgX-default_contrast.ktx2",
      )
    },
  )
  let is_3d = match GpuImage::from_texture_id(handle.id()) {
    Some(image) =>
      match image.texture() {
        Some(texture) =>
          texture.dimension_u32().raw == @wgpu.TEXTURE_DIMENSION_3D
        None => false
      }
    None => false
  }
  debug_inspect(is_3d, content="true")
}

///|
test "render/texture: bevy fog volume density asset reaches volumetric fog textured branch" {
  let backend = @renderer.GpuBackend::new(assets_base="assets")
  @renderer.render_context_set_backend_for_test(Some(backend))
  register_asset_texture_backend()
  let lifecycle_world_38_0 = @ecs.World::new()
  defer lifecycle_world_38_0.close()
  let handle : @asset.Handle[@asset.Image] = @asset.asset_with_world(
    lifecycle_world_38_0,
    fn() { @asset.AssetServer::new().load("volumes/bunny.ktx2") },
  )
  let texture_id = handle.id()
  debug_inspect(texture_id > 0, content="true")
  let image = GpuImage::from_texture_id(texture_id).unwrap()
  debug_inspect(image.width(), content="64")
  debug_inspect(image.height(), content="64")
  debug_inspect(
    image
    .format()
    .map(fn(format) { format.to_u32() == @wgpu.TEXTURE_FORMAT_R32_FLOAT }),
    content="Some(true)",
  )
  debug_inspect(
    image
    .texture()
    .map(fn(texture) {
      texture.dimension_u32().raw == @wgpu.TEXTURE_DIMENSION_3D
    }),
    content="Some(true)",
  )
  debug_inspect(image.view() is Some(_), content="true")
  debug_inspect(
    GpuImage::from_texture_id(texture_id) is Some(_),
    content="true",
  )
  @renderer.render_context_set_backend_for_test(None)
}
