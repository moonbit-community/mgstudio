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
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let source = @asset.AssetSourceId::from("example_files")
  let asset_path = @asset.AssetPath::from_path("bevy_pixel_light.png").with_source(
    source,
  )
  if asset_path !=
    @asset.asset_parse_path("example_files://bevy_pixel_light.png") {
    abort(
      "extra asset source path formatting drifted from Bevy-style source URL",
    )
  }

  ignore(
    commands.spawn_component(
      @sprite.Sprite::from_image(asset_server.get().load(asset_path)),
    ),
  )
}

///|
fn main {
  @asset.register_asset_source(
    @app.App::new(@ecs.World::new()),
    "example_files",
    @asset.AssetSourceBuilder::platform_default("examples/asset/files", None),
  )
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
