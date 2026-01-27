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
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(sprite_sheet_setup)
  .run()
}

///|
fn sprite_sheet_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let texture = asset_server.load("branding/bevy_bird_dark.png")
  let layout = @asset.TextureAtlasLayout::from_grid(
    @math.UVec2::new(128, 128),
    2,
    2,
  )
  let layout_handle = @asset.asset_add_texture_atlas_layout(layout)
  let tick = @core.ChangeTickWorld::read_change_tick(world)
  let atlas_store = @asset.Has_TextureAtlas::get_texture_atlas_store(world)
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
      let entity = @render2d.SpriteBundle::new(sprite, transform, texture).spawn(
        world,
      )
      atlas_store.insert(
        entity,
        @asset.TextureAtlas::new(layout_handle, idx),
        tick,
      )
      idx = idx + 1
    }
  }
  let camera = @render2d.Camera2d::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore
}
