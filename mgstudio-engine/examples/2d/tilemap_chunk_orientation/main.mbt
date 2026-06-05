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
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::set(@asset.AssetPlugin::nearest()))
  .insert_resource(
    @camera_clear_color.ClearColor::new(@sprite.Color::srgb(0.5F, 0.5F, 0.9F)),
  )
  .add_systems(@app.Startup, @app.system_config_param2(setup))
  .run()
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let chunk_size = @math.UVec2::splat(8)
  let tile_display_size = @math.UVec2::splat(64)
  let orientations : Array[@sprite_tilemap_chunk.TileOrientation] = [
    @sprite_tilemap_chunk.TileOrientation::Default,
    @sprite_tilemap_chunk.TileOrientation::Rotate90,
    @sprite_tilemap_chunk.TileOrientation::Rotate180,
    @sprite_tilemap_chunk.TileOrientation::Rotate270,
    @sprite_tilemap_chunk.TileOrientation::MirrorH,
    @sprite_tilemap_chunk.TileOrientation::MirrorHRotate90,
    @sprite_tilemap_chunk.TileOrientation::MirrorHRotate180,
    @sprite_tilemap_chunk.TileOrientation::MirrorHRotate270,
  ]
  let colors : Array[@sprite.Color] = [
    @sprite.Color::white(),
    @sprite.Color::new(1.0F, 0.0F, 0.0F, 1.0F),
    @sprite.Color::new(0.0F, 1.0F, 0.0F, 1.0F),
    @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    @sprite.Color::new(1.0F, 0.0F, 0.0F, 0.25F),
    @sprite.Color::new(0.0F, 1.0F, 0.0F, 0.25F),
    @sprite.Color::new(0.0F, 0.0F, 1.0F, 0.25F),
    @sprite.Color::new(1.0F, 1.0F, 1.0F, 0.5F),
  ]
  let tile_data : Array[@sprite_tilemap_chunk.TileData?] = []
  for i in 0..<(chunk_size.x * chunk_size.y) {
    let row = i / 8
    let col = i % 8
    tile_data.push(
      Some(
        @sprite_tilemap_chunk.TileData::new(
          row % 2,
          color=colors[row],
          visible=row != 7,
          orientation=orientations[col],
        ),
      ),
    )
  }
  let tileset = asset_server
    .get()
    .load_with_settings("textures/arrow.png", fn(settings) {
      settings.array_layout = Some(@asset.ImageArrayLayout::RowCount(2))
    })
  ignore(
    commands.spawn(
      (
        @sprite_tilemap_chunk.TilemapChunk::new(
          chunk_size,
          tile_display_size,
          tileset,
          alpha_mode=@sprite_render.AlphaMode2d::Blend,
        ),
        @sprite_tilemap_chunk.TilemapChunkTileData::new(tile_data),
      ),
    ),
  )
  ignore(commands.spawn_component(@camera_components2d.Camera2d::Camera2d()))
}
