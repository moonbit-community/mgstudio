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
  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("bevy_pixel_dark.png"),
        ).with_custom_size(Some(@math.Vec2::new(160.0F, 120.0F))),
        @transform.Transform::from_xyz(-100.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server.get().load("bevy_pixel_dark_with_meta.png"),
        ).with_custom_size(Some(@math.Vec2::new(160.0F, 120.0F))),
        @transform.Transform::from_xyz(100.0F, 0.0F, 0.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @sprite.Sprite::from_image(
          asset_server
          .get()
          .load_with_settings("bevy_pixel_dark_with_settings.png", fn(
            settings,
          ) {
            settings.sampler = @asset.ImageSampler::nearest()
          }),
        ).with_custom_size(Some(@math.Vec2::new(160.0F, 120.0F))),
        @transform.Transform::from_xyz(0.0F, 150.0F, 0.0F),
      ),
    ),
  )

  ignore(commands.spawn_component(@sprite.Camera2d::default()))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(
      @asset.AssetPlugin::default().with_file_path("examples/asset/files"),
    ),
  )
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
