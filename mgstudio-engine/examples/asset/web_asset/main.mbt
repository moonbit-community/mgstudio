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
  let url = "https://raw.githubusercontent.com/bevyengine/bevy/refs/heads/main/assets/branding/bevy_bird_dark.png"
  ignore(
    commands.spawn_component(
      @sprite.Sprite::from_image(asset_server.get().load(url)),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@asset.WebAssetPlugin::{
      silence_startup_warning: true,
    })
  })
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
