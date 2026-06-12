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
  let handle : @asset.Handle[@asset.Image] = @asset.asset_with_world(
    @ecs.World::new(),
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
