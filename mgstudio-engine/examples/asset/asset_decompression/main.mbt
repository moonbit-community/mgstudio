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
struct GzAsset {
  uncompressed_bytes : Bytes
  uncompressed_path : @asset.AssetPath
}

///|
struct CompressedImage {
  compressed : @asset.Handle[GzAsset]
}

///|
let compressed_image_key : @ecs.ComponentKey[CompressedImage] = @ecs.register_component(
  debug_name="examples.asset.asset_decompression.CompressedImage",
)

///|
pub impl @ecs.Component for CompressedImage with component() {
  compressed_image_key
}

///|
fn path_without_gzip_suffix(path : String) -> String {
  guard path.length() > 3 else {
    abort("Compressed asset path is missing the .gz suffix")
  }
  let suffix = path[path.length() - 3:path.length()].to_string()
  if suffix != ".gz" {
    abort("Compressed asset path is missing the .gz suffix")
  }
  path[0:path.length() - 3].to_string()
}

///|
fn load_gzip_asset(
  _asset_server : @asset.AssetServer,
  path : @asset.AssetPath,
  bytes : Bytes,
) -> GzAsset {
  guard @asset.gzip_decompress(bytes) is Some(uncompressed_bytes) else {
    abort("Failed to decompress gzip asset bytes")
  }
  GzAsset::{
    uncompressed_bytes,
    uncompressed_path: @asset.AssetPath::from_path(
      path_without_gzip_suffix(path.path),
    ).with_source(path.source),
  }
}

///|
fn gzip_asset_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @asset.init_asset_loader(
    app,
    @asset.AssetLoader::new(["gz"], load_gzip_asset),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn_component(CompressedImage::{
      compressed: asset_server.get().load("data/compressed_image.png.gz"),
    }),
  )
}

///|
fn decompress(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  compressed_assets : @app.ResMut[@asset.Assets[GzAsset]],
  query : @ecs.Query[@ecs.Comp[CompressedImage], @ecs.All],
) -> Unit {
  let asset_store = compressed_assets.get_ref().val
  try! query.view(fn(entity, compressed_image) {
    let compressed_image = compressed_image.value()
    guard asset_store.remove(compressed_image.compressed) is Some(compressed) else {
      return
    }
    let image : @asset.Image = asset_server
      .get()
      .load_image_direct(
        compressed.uncompressed_path,
        compressed.uncompressed_bytes,
      )
    let image_handle = asset_server.get().add(image)
    commands.entity(entity).remove(compressed_image_key)
    commands
    .entity(entity)
    .insert_component(@sprite.Sprite::from_image(image_handle))
  })
}

///|
fn main {
  gzip_asset_plugin(
    @app.App::new(@ecs.World::new()).add_plugins(@mgstudio.default_plugins()),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param4(decompress)))
  .run()
}
