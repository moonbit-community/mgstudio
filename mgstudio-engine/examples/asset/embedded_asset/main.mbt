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
const EMBEDDED_CRATE_NAME : String = "embedded_asset"

///|
struct EmbeddedAssetPlugin {}

///|
#warnings("-unnecessary_annotation")
fn EmbeddedAssetPlugin::EmbeddedAssetPlugin() -> EmbeddedAssetPlugin {
  EmbeddedAssetPlugin::{  }
}

///|
impl @app.Plugin for EmbeddedAssetPlugin with fn name(_self) {
  "examples.asset.embedded_asset.EmbeddedAssetPlugin"
}

///|
impl @app.Plugin for EmbeddedAssetPlugin with fn build(_self, app) {
  @asset.embedded_asset(
    app,
    @asset.AssetPath::from_path(
      "\{EMBEDDED_CRATE_NAME}/files/bevy_pixel_light.png",
    ).with_source(@asset.AssetSourceId::from("embedded")),
    "examples/asset/files/bevy_pixel_light.png",
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))

  let asset_path = @asset.AssetPath::from_path(
    "\{EMBEDDED_CRATE_NAME}/files/bevy_pixel_light.png",
  ).with_source(@asset.AssetSourceId::from("embedded"))
  if asset_path !=
    @asset.asset_parse_path(
      "embedded://embedded_asset/files/bevy_pixel_light.png",
    ) {
    abort("embedded asset path formatting drifted from Bevy-style embedded URL")
  }

  ignore(
    commands.spawn_component(
      @sprite.Sprite::from_image(asset_server.get().load(asset_path)),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_plugins(EmbeddedAssetPlugin::EmbeddedAssetPlugin())
  .add_systems_param2(Startup, setup)
  .run()
}
