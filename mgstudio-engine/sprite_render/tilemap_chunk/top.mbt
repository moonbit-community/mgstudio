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
// Bevy source: `bevy/crates/bevy_sprite_render/src/tilemap_chunk/mod.rs`.

///|
pub struct TileData {
  tileset_index : Int
  color : @color.Color
  visible : Bool
  orientation : TileOrientation
}

///|
pub fn TileData::TileData() -> TileData {
  TileData::{
    tileset_index: 0,
    color: @color.Color::white(),
    visible: true,
    orientation: TileOrientation::Default,
  }
}

///|
pub fn TileData::from_tileset_index(tileset_index : Int) -> TileData {
  let value = if tileset_index < 0 { 0 } else { tileset_index }
  TileData::{ ..TileData::TileData(), tileset_index: value }
}

///|
pub fn TileData::new(
  tileset_index : Int,
  color? : @color.Color = @color.Color::white(),
  visible? : Bool = true,
  orientation? : TileOrientation = TileOrientation::Default,
) -> TileData {
  let value = if tileset_index < 0 { 0 } else { tileset_index }
  TileData::{ tileset_index: value, color, visible, orientation }
}

///|
pub struct TilemapChunk {
  chunk_size : @math.UVec2
  tile_display_size : @math.UVec2
  tileset : @asset.Handle[@asset.Image]
  alpha_mode : @mesh2d_material.AlphaMode2d
}

///|
pub fn TilemapChunk::new(
  chunk_size : @math.UVec2,
  tile_display_size : @math.UVec2,
  tileset : @asset.Handle[@asset.Image],
  alpha_mode? : @mesh2d_material.AlphaMode2d = @mesh2d_material.AlphaMode2d::Blend,
) -> TilemapChunk {
  TilemapChunk::{ chunk_size, tile_display_size, tileset, alpha_mode }
}

///|
pub fn TilemapChunk::tile_capacity(self : TilemapChunk) -> Int {
  self.chunk_size.x * self.chunk_size.y
}

///|
fn tilemap_chunk_safe_uvec2(
  value : @math.UVec2,
  fallback : @math.UVec2,
) -> @math.UVec2 {
  let x = if value.x <= 0 { fallback.x } else { value.x }
  let y = if value.y <= 0 { fallback.y } else { value.y }
  @math.UVec2::new(x, y)
}

///|
fn tilemap_chunk_local_center(
  chunk : TilemapChunk,
  tile_pos : @math.UVec2,
) -> @math.Vec2 {
  let safe_chunk_size = tilemap_chunk_safe_uvec2(
    chunk.chunk_size,
    @math.UVec2::new(1, 1),
  )
  let safe_tile_size = tilemap_chunk_safe_uvec2(
    chunk.tile_display_size,
    @math.UVec2::new(1, 1),
  )
  let tile_w = Float::from_double(safe_tile_size.x.to_double())
  let tile_h = Float::from_double(safe_tile_size.y.to_double())
  let chunk_w = Float::from_double(safe_chunk_size.x.to_double()) * tile_w
  let chunk_h = Float::from_double(safe_chunk_size.y.to_double()) * tile_h
  let origin_x = -chunk_w / 2.0F + tile_w / 2.0F
  let origin_y = -chunk_h / 2.0F + tile_h / 2.0F
  let x = origin_x + Float::from_double(tile_pos.x.to_double()) * tile_w
  let y = origin_y + Float::from_double(tile_pos.y.to_double()) * tile_h
  @math.Vec2::new(x, y)
}

///|
pub fn TilemapChunk::calculate_tile_transform(
  self : TilemapChunk,
  tile_pos : @math.UVec2,
) -> @transform.Transform {
  let local_center = tilemap_chunk_local_center(self, tile_pos)
  let safe_tile_size = tilemap_chunk_safe_uvec2(
    self.tile_display_size,
    @math.UVec2::new(1, 1),
  )
  @transform.Transform::from_xy_rotation_scale(
    local_center,
    0.0F,
    @math.Vec2::new(
      Float::from_double(safe_tile_size.x.to_double()),
      Float::from_double(safe_tile_size.y.to_double()),
    ),
  )
}

///|
pub struct TilemapChunkTileData {
  tile_data : Array[TileData?]
}

///|
pub fn TilemapChunkTileData::new(
  tile_data : Array[TileData?],
) -> TilemapChunkTileData {
  TilemapChunkTileData::{ tile_data, }
}

///|
pub fn TilemapChunkTileData::tile_data_from_tile_pos(
  self : TilemapChunkTileData,
  chunk_size : @math.UVec2,
  tile_pos : @math.UVec2,
) -> TileData? {
  if tile_pos.x < 0 || tile_pos.y < 0 {
    return None
  }
  if tile_pos.x >= chunk_size.x || tile_pos.y >= chunk_size.y {
    return None
  }
  let index = tile_pos.y * chunk_size.x + tile_pos.x
  if index < 0 || index >= self.tile_data.length() {
    return None
  }
  self.tile_data[index]
}

///|
pub fn TilemapChunkTileData::set_tile_data_from_tile_pos(
  self : TilemapChunkTileData,
  chunk_size : @math.UVec2,
  tile_pos : @math.UVec2,
  value : TileData?,
) -> TilemapChunkTileData {
  if tile_pos.x < 0 || tile_pos.y < 0 {
    return self
  }
  if tile_pos.x >= chunk_size.x || tile_pos.y >= chunk_size.y {
    return self
  }
  let index = tile_pos.y * chunk_size.x + tile_pos.x
  if index < 0 || index >= self.tile_data.length() {
    return self
  }
  let next : Array[TileData?] = []
  for i in 0..<self.tile_data.length() {
    if i == index {
      next.push(value)
    } else {
      next.push(self.tile_data[i])
    }
  }
  TilemapChunkTileData::{ tile_data: next }
}

///|
pub let ecs_key_tilemap_chunk : @ecs.ComponentKey[TilemapChunk] = @ecs.register_component(
  debug_name="mgstudio_sprite_render.tilemap_chunk",
)

///|
pub let ecs_key_tilemap_chunk_tile_data : @ecs.ComponentKey[
  TilemapChunkTileData,
] = @ecs.register_component(
  debug_name="mgstudio_sprite_render.tilemap_chunk_tile_data",
)

///|
pub impl @ecs.Component for TilemapChunk with fn component() {
  ecs_key_tilemap_chunk
}

///|
pub impl @ecs.Component for TilemapChunkTileData with fn component() {
  ecs_key_tilemap_chunk_tile_data
}

///|
fn encode_tile_orientation(orientation : TileOrientation) -> Json {
  orientation.to_int().to_json()
}

///|
fn encode_tile_data(tile_data : TileData) -> Json {
  (
    tile_data.tileset_index,
    tile_data.color,
    tile_data.visible,
    encode_tile_orientation(tile_data.orientation),
  ).to_json()
}

///|
fn encode_tilemap_chunk(tilemap_chunk : TilemapChunk) -> Json {
  (
    tilemap_chunk.chunk_size,
    tilemap_chunk.tile_display_size,
    tilemap_chunk.tileset.id(),
    tilemap_chunk.alpha_mode,
  ).to_json()
}

///|
fn encode_tilemap_chunk_tile_data(tile_data : TilemapChunkTileData) -> Json {
  tile_data.tile_data.to_json()
}

///|
fn decode_image_handle(json : Json) -> @asset.Handle[@asset.Image] {
  let id : Int = try! @json.from_json(json)
  @asset.Handle::new(id)
}

///|
fn decode_tile_orientation(json : Json) -> TileOrientation {
  let raw : Int = try! @json.from_json(json)
  TileOrientation::from_bools(
    (raw & 0b100) != 0,
    (raw & 0b010) != 0,
    (raw & 0b001) != 0,
  )
}

///|
fn decode_tile_data(json : Json) -> TileData {
  let (tileset_index, color, visible, orientation_json) : (
    Int,
    @color.Color,
    Bool,
    Json,
  ) = try! @json.from_json(json)
  TileData::new(
    tileset_index,
    color~,
    visible~,
    orientation=decode_tile_orientation(orientation_json),
  )
}

///|
fn decode_tilemap_chunk(json : Json) -> TilemapChunk {
  let (chunk_size, tile_display_size, tileset_json, alpha_mode) : (
    @math.UVec2,
    @math.UVec2,
    Json,
    @mesh2d_material.AlphaMode2d,
  ) = try! @json.from_json(json)
  TilemapChunk::new(
    chunk_size,
    tile_display_size,
    decode_image_handle(tileset_json),
    alpha_mode~,
  )
}

///|
fn decode_tilemap_chunk_tile_data(json : Json) -> TilemapChunkTileData {
  let tile_data_json : Array[Json] = try! @json.from_json(json)
  let tile_data : Array[TileData?] = []
  for entry in tile_data_json {
    tile_data.push(
      match entry {
        Null => None
        _ => Some(decode_tile_data(entry))
      },
    )
  }
  TilemapChunkTileData::new(tile_data)
}

///|
pub impl ToJson for TileData with fn to_json(self) {
  encode_tile_data(self)
}

///|
pub impl @json.FromJson for TileData with fn from_json(json, _path) {
  decode_tile_data(json)
}

///|
pub impl ToJson for TilemapChunk with fn to_json(self) {
  encode_tilemap_chunk(self)
}

///|
pub impl @json.FromJson for TilemapChunk with fn from_json(json, _path) {
  decode_tilemap_chunk(json)
}

///|
pub impl ToJson for TilemapChunkTileData with fn to_json(self) {
  encode_tilemap_chunk_tile_data(self)
}

///|
pub impl @json.FromJson for TilemapChunkTileData with fn from_json(json, _path) {
  decode_tilemap_chunk_tile_data(json)
}
