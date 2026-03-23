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
const TILESET_RANDOM_RANGE : Int = 5

///|
struct UpdateTimer {
  mut timer : @time.Timer
}

///|
let update_timer_key : @ecs.ComponentKey[UpdateTimer] = @ecs.register_component(
  debug_name="examples.2d.tilemap_chunk.UpdateTimer",
)

///|
pub impl @ecs.Component for UpdateTimer with component() {
  update_timer_key
}

///|
struct MovePlayer {}

///|
let move_player_key : @ecs.ComponentKey[MovePlayer] = @ecs.register_component(
  debug_name="examples.2d.tilemap_chunk.MovePlayer",
)

///|
pub impl @ecs.Component for MovePlayer with component() {
  move_player_key
}

///|
struct SeededRng {
  rng : @random.Rand
}

///|
let seeded_rng_key : @ecs.ResourceKey[SeededRng] = @ecs.register_resource(
  debug_name="examples.2d.tilemap_chunk.SeededRng",
)

///|
pub impl @app.Resource for SeededRng with resource() {
  seeded_rng_key
}

///|
fn main {
  let setup_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param2(setup),
  )
  let spawn_fake_player_system : @app.SystemConfig[@ecs.World] = @app.system(
    @app.system_param4(spawn_fake_player),
  )

  @app.App::new(@ecs.World::new())
  .add_plugin_group(fn() {
    @mgstudio.DefaultPlugins::set(@asset.AssetPlugin::default_nearest())
  })
  .add_systems(
    @app.Startup,
    (setup_system, spawn_fake_player_system) |> @app.chain(),
  )
  .add_systems(@app.Update, @app.system(@app.system_param4(update_tilemap)))
  .add_systems(@app.Update, @app.system(@app.system_param3(move_player)))
  .add_systems(@app.Update, @app.system(@app.system_param2(log_tile)))
  .run()
}

///|
fn build_initial_tile_data(
  rng : @random.Rand,
  tile_count : Int,
) -> Array[@sprite.TileData?] {
  let tile_data : Array[@sprite.TileData?] = []
  for _ in 0..<tile_count {
    let value = rng.int(limit=TILESET_RANDOM_RANGE)
    tile_data.push(
      if value == 0 {
        None
      } else {
        Some(@sprite.TileData::from_tileset_index(value - 1))
      },
    )
  }
  tile_data
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let rng = @random.Rand::chacha8(seed=b"bevy-tilemap-chunk-seed-00000042")
  let chunk = @sprite.TilemapChunk::new(
    @math.UVec2::splat(CHUNK_SIDE),
    @math.UVec2::splat(TILE_SIZE),
    asset_server
    .get()
    .load_with_settings("textures/array_texture.png", fn(settings) {
      settings.array_layout = Some(@asset.ImageArrayLayout::RowCount(4))
    }),
    @math.UVec2::new(1, 1),
  )
  let tile_data = build_initial_tile_data(rng, chunk.tile_capacity())

  ignore(
    commands.spawn(
      (
        chunk,
        @sprite.TilemapChunkTileData::new(tile_data),
        UpdateTimer::{
          timer: @time.Timer::from_seconds(
            UPDATE_INTERVAL_SECONDS,
            @time.TimerMode::Repeating,
          ),
        },
      ),
    ),
  )
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  commands.insert_resource(SeededRng::{ rng, })
}

///|
fn spawn_player(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@sprite.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  chunk : @sprite.TilemapChunk,
  tile_pos : @math.UVec2,
  moving? : Bool = false,
) -> Unit {
  let base_transform = chunk.calculate_tile_transform(tile_pos)
  let transform = base_transform.with_translation(
    @math.Vec3::new(
      base_transform.translation.x,
      base_transform.translation.y,
      1.0F,
    ),
  )
  let player_mesh = @sprite.Mesh2d::new(
    meshes.get_ref().val.add(
      @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::new(8.0F, 8.0F)).to_mesh(),
    ),
  )
  let player_material = @sprite.MeshMaterial2d::new(
    materials.get_ref().val.add(
      @sprite.ColorMaterialAsset::from_color(
        @sprite.Color::new(0.956F, 0.271F, 0.271F, 1.0F),
      ),
    ),
  )

  if moving {
    ignore(
      commands.spawn(
        (player_mesh, player_material, transform, MovePlayer::{  }),
      ),
    )
  } else {
    ignore(commands.spawn((player_mesh, player_material, transform)))
  }
}

///|
fn spawn_fake_player(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@sprite.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  chunks : @ecs.Query1[@sprite.TilemapChunk],
) -> Unit {
  guard (try! chunks.single()) is Some(chunk) else { return }
  spawn_player(
    commands,
    meshes,
    materials,
    chunk,
    @math.UVec2::new(0, 0),
    moving=true,
  )
  spawn_player(commands, meshes, materials, chunk, @math.UVec2::new(5, 6))
}

///|
fn move_player(
  players : @ecs.Query1Filtered[@transform.Transform, @ecs.With[MovePlayer]],
  time : @app.Res[@time.Time[Unit]],
  chunks : @ecs.Query1[@sprite.TilemapChunk],
) -> Unit {
  guard (try! chunks.single()) is Some(chunk) else { return }

  let t = (@math.sin(time.get().elapsed_secs()) + 1.0F) / 2.0F
  let origin = chunk.calculate_tile_transform(@math.UVec2::new(0, 0)).translation.x
  let destination = chunk.calculate_tile_transform(
      @math.UVec2::new(CHUNK_SIDE - 1, 0),
    ).translation.x

  try! players.view_mut(fn(_entity, player) {
    let player_ref = player.get_ref()
    player_ref.val.translation.x = origin + (destination - origin) * t
  })
}

///|
fn update_tilemap(
  timers : @ecs.Query1[UpdateTimer],
  tile_data_query : @ecs.Query1[@sprite.TilemapChunkTileData],
  time : @app.Res[@time.Time[Unit]],
  rng : @app.ResMut[SeededRng],
) -> Unit {
  let rng_ref = rng.get_ref()
  try! timers.view_mut(fn(entity, timer) {
    let timer_ref = timer.get_ref()
    timer_ref.val.timer = timer_ref.val.timer.tick(time.get().delta())

    if !timer_ref.val.timer.just_finished() {
      return
    }

    ignore(
      try! tile_data_query.with_mut(entity, fn(tile_data) {
        let tile_data_ref = tile_data.get_ref()
        let tile_count = tile_data_ref.val.tile_data.length()
        if tile_count == 0 {
          return
        }
        for _ in 0..<UPDATE_BATCH_COUNT {
          let index = rng_ref.val.rng.int(limit=tile_count)
          tile_data_ref.val.tile_data[index] = Some(
            @sprite.TileData::from_tileset_index(
              rng_ref.val.rng.int(limit=TILESET_RANDOM_RANGE),
            ),
          )
        }
      }),
    )
  })
}

///|
fn first_tilemap(
  tilemaps : @ecs.Query2[@sprite.TilemapChunk, @sprite.TilemapChunkTileData],
) -> (@sprite.TilemapChunk, @sprite.TilemapChunkTileData)? {
  let result : Ref[(@sprite.TilemapChunk, @sprite.TilemapChunkTileData)?] = Ref::new(
    None,
  )
  try! tilemaps.view(fn(_entity, chunk, tile_data) {
    if result.val is None {
      result.val = Some((chunk, tile_data))
    }
  })
  result.val
}

///|
fn log_tile(
  tilemaps : @ecs.Query2[@sprite.TilemapChunk, @sprite.TilemapChunkTileData],
  last_tileset_index : @app.Local[Int],
) -> Unit {
  guard first_tilemap(tilemaps) is Some((chunk, tile_data)) else { return }
  guard tile_data.tile_data_from_tile_pos(
      chunk.chunk_size,
      @math.UVec2::new(3, 4),
    )
    is Some(tile) else {
    return
  }

  if tile.tileset_index != last_tileset_index.get() {
    @app.log_info(
      "tile_data changed: tileset_index=" + tile.tileset_index.to_string(),
    )
    last_tileset_index.set(tile.tileset_index)
  }
}
