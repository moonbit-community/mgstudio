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
// Bevy source: `bevy/examples/window/custom_cursor_image.rs`.

///|
fn setup_cursor_icon(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  texture_atlas_layouts : @app.ResMut[@asset.Assets[@asset.TextureAtlasLayout]],
  window_entity : @app.Single[@core.Entity, @ecs.With[@window.Window]],
) -> Unit {
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::splat(64),
    20,
    10,
    padding=@math.UVec2::splat(5),
  )
  let texture_atlas_layout = texture_atlas_layouts.get_ref().val.add(layout)
  let atlas = @asset.TextureAtlas::new(texture_atlas_layout, 0)
  let custom_cursor_image = @window.CustomCursorImage::new(
    asset_server
    .get()
    .load_image(
      "cursors/kenney_crosshairPack/Tilesheet/crosshairs_tilesheet_white.png",
    ),
    (0, 0),
    texture_atlas=Some(atlas),
  )
  commands
  .entity(window_entity.get())
  .insert_component(
    @window.CursorIcon::from_custom(
      @window.CustomCursor::Image(custom_cursor_image),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup_cursor_icon)))
  .run()
}
