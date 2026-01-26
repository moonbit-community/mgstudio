// Copyright 2025 International Digital Economy Academy
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
pub fn texture_atlas_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(texture_atlas_setup)
  .run()
}

///|
fn texture_atlas_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let layout = @asset.TextureAtlasLayout::new_empty(@math.UVec2::new(256, 256))
  layout.add_texture(
    @math.URect::new(@math.UVec2::new(0, 0), @math.UVec2::new(128, 128)),
  )
  |> ignore
  layout.add_texture(
    @math.URect::new(@math.UVec2::new(128, 0), @math.UVec2::new(256, 128)),
  )
  |> ignore
  layout.add_texture(
    @math.URect::new(@math.UVec2::new(0, 128), @math.UVec2::new(128, 256)),
  )
  |> ignore
  layout.add_texture(
    @math.URect::new(@math.UVec2::new(128, 128), @math.UVec2::new(256, 256)),
  )
  |> ignore
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  for i in 0..<4 {
    let x = i % 2 * 160 - 80
    let y = 80 - i / 2 * 160
    let translation = @math.Vec2::new(
      Float::from_double(x.to_double()),
      Float::from_double(y.to_double()),
    )
    let transform = @math.Transform::new(
      translation,
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
    )
    let handle = @render2d.SpriteBundle::new(sprite, transform, texture).spawn()
    @render2d.render2d_set_sprite_atlas_handle(handle, layout_handle, i)
    |> ignore
  }
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
}
