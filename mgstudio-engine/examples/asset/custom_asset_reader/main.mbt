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
let read_paths : Array[String] = []

///|
let printed_paths : Array[String] = []

///|
fn custom_asset_reader(base_reader : @asset.AssetReader) -> @asset.AssetReader {
  @asset.AssetReader::new(
    fn(path) {
      read_paths.push(path)
      base_reader.read(path)
    },
    fn(path) { base_reader.read_meta(path) },
    fn(path) { base_reader.read_directory(path) },
    fn(path) { base_reader.is_directory(path) },
  )
}

///|
fn print_reads(_world : @ecs.World) -> Unit {
  for path in read_paths {
    if !printed_paths.contains(path) {
      println("Reading \{path}")
      printed_paths.push(path)
    }
  }
}

///|
fn custom_asset_reader_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  @asset.register_asset_source(
    app,
    @asset.AssetSourceId::Default,
    @asset.AssetSourceBuilder::platform_default("", None).with_reader(
      custom_asset_reader,
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  ignore(
    commands.spawn_component(
      @sprite.Sprite::from_image(asset_server.get().load("branding/icon.png")),
    ),
  )
}

///|
fn main {
  custom_asset_reader_plugin(@app.App::new(@ecs.World::new()))
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .add_systems(@app.Update, @app.system(print_reads))
  .run()
}
