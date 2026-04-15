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
fn color_for_support(supported : Bool) -> @sprite.Color {
  if supported {
    @sprite.Color::srgb(0.2F, 0.85F, 0.35F)
  } else {
    @sprite.Color::srgb(0.88F, 0.25F, 0.28F)
  }
}

///|
fn setup(commands : @app.Commands) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let formats = @asset.asset_supported_compressed_image_formats()
  let astc = @asset.asset_compressed_image_formats_contains(
    formats,
    @asset.COMPRESSED_IMAGE_FORMAT_ASTC_LDR,
  )
  let bc = @asset.asset_compressed_image_formats_contains(
    formats,
    @asset.COMPRESSED_IMAGE_FORMAT_BC,
  )
  let etc2 = @asset.asset_compressed_image_formats_contains(
    formats,
    @asset.COMPRESSED_IMAGE_FORMAT_ETC2,
  )

  let entries = [
    (-240.0F, color_for_support(astc)),
    (0.0F, color_for_support(bc)),
    (240.0F, color_for_support(etc2)),
  ]
  for i in 0..<entries.length() {
    ignore(
      commands.spawn(
        (
          @sprite.Sprite::sized(@math.Vec2::new(180.0F, 260.0F)).with_color(
            entries[i].1,
          ),
          @transform.Transform::from_xyz(entries[i].0, 0.0F, 0.0F),
        ),
      ),
    )
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param(setup)))
  .run()
}
