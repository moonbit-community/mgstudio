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
pub fn sprite_sheet_run() -> Unit {
  let plugins : Array[@app.Plugin] = [
    @window.window_plugin, @time.time_plugin, @asset.asset_plugin, @render2d.render2d_plugin,
    @input.input_plugin,
  ]
  @app.App::new()
  .add_plugins(plugins)
  .add_startup_system(sprite_sheet_setup)
  .run()
}

///|
fn sprite_sheet_setup() -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(128, 128),
    2,
    2,
  )
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)
  let sprite = @render2d.Sprite::new(@render2d.Color::white())
  let mut idx = 0
  for y in 0..<2 {
    for x in 0..<2 {
      let translation = @math.Vec2::new(
        Float::from_double((x * 160 - 80).to_double()),
        Float::from_double((80 - y * 160).to_double()),
      )
      let transform = @math.Transform::new(
        translation,
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
      )
      let handle = @render2d.SpriteBundle::new(sprite, transform, texture).spawn()
      @render2d.render2d_set_sprite_atlas_handle(handle, layout_handle, idx)
      |> ignore
      idx = idx + 1
    }
  }
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn()
  |> ignore
}
