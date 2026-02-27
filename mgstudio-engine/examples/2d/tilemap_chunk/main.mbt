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
const CHUNK_SIDE : Int = 64

///|
const TILE_SIZE : Int = 8

///|
const UPDATE_INTERVAL_SECONDS : Float = 0.1F

///|
const UPDATE_BATCH_COUNT : Int = 50

///|
const LCG_MOD : Int = 2147483647

///|
const TILESET_RANDOM_RANGE : Int = 5

///|
priv struct TilemapChunkState {
  mut chunk : @render2d.TilemapChunk?
  mut tiles : Array[@render2d.TileData?]
  mut update_accumulator : Float
  mut seed : Int
  mut player : @core.Entity
  mut last_logged_tile_value : Int
}

///|
let tilemap_chunk_state : Ref[TilemapChunkState] = Ref::new(TilemapChunkState::{
  chunk: None,
  tiles: [],
  update_accumulator: 0.0F,
  seed: 42,
  player: @core.Entity::placeholder(),
  last_logged_tile_value: -1,
})

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(tilemap_chunk_setup)
  .add_system(tilemap_chunk_update)
  .run()
}

///|
fn tilemap_chunk_setup(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let tileset_texture = asset_server.load_with_settings(
    "textures/array_texture.png",
    @asset.ImageLoaderSettings::default()
    .with_sampler(@asset.ImageSampler::Nearest)
    .with_array_layout(Some(@asset.ImageArrayLayout::RowCount(4))),
  )
  let chunk = @render2d.TilemapChunk::new(
    @math.UVec2::splat(CHUNK_SIDE),
    @math.UVec2::splat(TILE_SIZE),
    tileset_texture,
    @math.UVec2::new(1, 1),
  )
  tilemap_chunk_state.val.seed = 42
  let tiles = build_initial_tile_data(chunk.tile_capacity())
  let player = spawn_fake_player(world, chunk, @math.UVec2::new(0, 0))
  spawn_fake_player(world, chunk, @math.UVec2::new(5, 6)) |> ignore

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

  tilemap_chunk_state.val.chunk = Some(chunk)
  tilemap_chunk_state.val.tiles = tiles
  tilemap_chunk_state.val.update_accumulator = 0.0F
  tilemap_chunk_state.val.player = player
  tilemap_chunk_state.val.last_logged_tile_value = -1
}

///|
fn tilemap_chunk_update(world : @ecs_world.World) -> Unit {
  guard tilemap_chunk_state.val.chunk is Some(chunk) else { return }

  @render2d.render2d_draw_tilemap_chunk(
    world,
    chunk,
    @render2d.TilemapChunkTileData::new(tilemap_chunk_state.val.tiles),
    @math.Transform::identity(),
    @render2d.RenderLayers::default(),
  )

  update_fake_player(world, chunk)
  update_tilemap_data(chunk)
  log_probe_tile(chunk)
}

///|
fn update_fake_player(
  world : @ecs_world.World,
  chunk : @render2d.TilemapChunk,
) -> Unit {
  if tilemap_chunk_state.val.player.is_placeholder() {
    return
  }
  let start = chunk.calculate_tile_transform(@math.UVec2::new(0, 0)).translation.x
  let end = chunk.calculate_tile_transform(@math.UVec2::new(CHUNK_SIDE - 1, 0)).translation.x
  let t = (1.0F + @math.sin(@time.time_elapsed_seconds())) * 0.5F
  let next_x = start + (end - start) * t

  let transform_store = world.get_transform_store()
  guard transform_store.get(tilemap_chunk_state.val.player) is Some(transform) else {
    return
  }
  let next_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(next_x, transform.translation.y),
    transform.rotation_z(),
    @math.Vec2::new(transform.scale.x, transform.scale.y),
    z=transform.translation.z,
  )
  let tick = world.read_change_tick()
  transform_store.set(tilemap_chunk_state.val.player, next_transform, tick)
  |> ignore
}

///|
fn update_tilemap_data(chunk : @render2d.TilemapChunk) -> Unit {
  tilemap_chunk_state.val.update_accumulator = tilemap_chunk_state.val.update_accumulator +
    @time.time_delta_seconds()
  if tilemap_chunk_state.val.update_accumulator < UPDATE_INTERVAL_SECONDS {
    return
  }
  tilemap_chunk_state.val.update_accumulator = 0.0F
  let tile_count = tilemap_chunk_state.val.tiles.length()
  if tile_count == 0 {
    return
  }
  for _ in 0..<UPDATE_BATCH_COUNT {
    let index = seeded_random_range(tile_count)
    let value = seeded_random_range(TILESET_RANDOM_RANGE)
    tilemap_chunk_state.val.tiles[index] = Some(
      @render2d.TileData::from_tileset_index(value),
    )
  }
  if chunk.tile_capacity() != tile_count {
    @window.host_debug_string(
      value="tilemap_chunk: tile_data length mismatch, expected=" +
        chunk.tile_capacity().to_string() +
        ", actual=" +
        tile_count.to_string(),
    )
  }
}

///|
fn log_probe_tile(chunk : @render2d.TilemapChunk) -> Unit {
  let data = @render2d.TilemapChunkTileData::new(tilemap_chunk_state.val.tiles)
  let tile = data.tile_data_from_tile_pos(
    chunk.chunk_size,
    @math.UVec2::new(3, 4),
  )
  let current = match tile {
    Some(v) => v.tileset_index
    None => -1
  }
  if current == tilemap_chunk_state.val.last_logged_tile_value {
    return
  }
  tilemap_chunk_state.val.last_logged_tile_value = current
  let text = if current < 0 { "none" } else { current.to_string() }
  @window.host_debug_string(value="tilemap_chunk tile(3,4)=" + text)
}

///|
fn build_initial_tile_data(tile_count : Int) -> Array[@render2d.TileData?] {
  let tiles : Array[@render2d.TileData?] = []
  for _ in 0..<tile_count {
    let value = seeded_random_range(TILESET_RANDOM_RANGE)
    tiles.push(
      if value == 0 {
        None
      } else {
        Some(@render2d.TileData::from_tileset_index(value - 1))
      },
    )
  }
  tiles
}

///|
fn spawn_fake_player(
  world : @ecs_world.World,
  chunk : @render2d.TilemapChunk,
  tile_pos : @math.UVec2,
) -> @core.Entity {
  let tile_transform = chunk.calculate_tile_transform(tile_pos)
  let player_transform = @math.Transform::from_xy_rotation_scale(
    @math.Vec2::new(tile_transform.translation.x, tile_transform.translation.y),
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
    z=1.0F,
  )
  @render2d.Mesh2dBundle::new(
    @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::new(8.0F, 8.0F)),
    @render2d.ColorMaterial::new(
      @render2d.Color::new(0.956F, 0.271F, 0.271F, 1.0F),
    ),
    player_transform,
  ).spawn(world)
}

///|
fn seeded_random_range(max_exclusive : Int) -> Int {
  if max_exclusive <= 0 {
    return 0
  }
  tilemap_chunk_state.val.seed = lcg_next(tilemap_chunk_state.val.seed)
  tilemap_chunk_state.val.seed % max_exclusive
}

///|
fn lcg_next(seed : Int) -> Int {
  let mut next = (seed * 1103515245 + 12345) % LCG_MOD
  if next < 0 {
    next = next + LCG_MOD
  }
  next
}
