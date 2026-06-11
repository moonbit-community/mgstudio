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
// Bevy source: `bevy/crates/bevy_sprite_render/src/tilemap_chunk/tilemap_chunk_material.rs`.

///|
const MESH2D_SHADER_PATH : String = "sprite_render/mesh2d/mesh2d.wgsl"

///|
const TILEMAP_CHUNK_MATERIAL_SHADER_PATH : String = "sprite_render/tilemap_chunk/tilemap_chunk_material.wgsl"

///|
fn register_tilemap_chunk_material_wgsl_source() -> Unit {
  @shader_source.load_embedded_shader_source(
    TILEMAP_CHUNK_MATERIAL_SHADER_PATH,
    tilemap_chunk_material_wgsl_source,
  )
}

///|
pub struct TilemapChunkMaterial {
  alpha_mode : @mesh2d_material.AlphaMode2d
  tileset : @asset.Handle[@asset.Image]
  tile_data : @asset.Handle[@asset.Image]
}

///|
pub fn TilemapChunkMaterial::new(
  tileset : @asset.Handle[@asset.Image],
  tile_data : @asset.Handle[@asset.Image],
  alpha_mode : @mesh2d_material.AlphaMode2d,
) -> TilemapChunkMaterial {
  TilemapChunkMaterial::{ alpha_mode, tileset, tile_data }
}

///|
pub fn TilemapChunkMaterial::TilemapChunkMaterial() -> TilemapChunkMaterial {
  TilemapChunkMaterial::new(
    @asset.Handle::new(0),
    @asset.Handle::new(0),
    @mesh2d_material.AlphaMode2d::Blend,
  )
}

///|
pub impl @asset.Asset for TilemapChunkMaterial with fn asset_debug_name() {
  "mgstudio_sprite_render::TilemapChunkMaterial"
}

///|
pub impl @asset.Asset for TilemapChunkMaterial with fn asset_as_image(_self) {
  None
}

///|
let tilemap_chunk_material_asset_resource_keys : @asset.AssetResourceKeys[
  TilemapChunkMaterial,
] = @asset.register_asset_resource_keys(
  TilemapChunkMaterial::asset_debug_name(),
)

///|
pub impl @asset.Asset for TilemapChunkMaterial with fn asset_resource_keys() {
  tilemap_chunk_material_asset_resource_keys
}

///|
fn tilemap_chunk_material_bind_group(
  tileset : @asset.Handle[@asset.Image],
  tile_data : @asset.Handle[@asset.Image],
) -> @mesh2d_material.Material2dBindGroup {
  @mesh2d_material.Material2dBindGroup::new([
    @mesh2d_material.Material2dBinding::texture_with_layout(
      0,
      Some(tileset),
      @mesh2d_material.Material2dTextureSampleType::Float,
      @mesh2d_material.Material2dTextureViewDimension::D2Array,
    ),
    @mesh2d_material.Material2dBinding::sampler(1, Some(tileset)),
    @mesh2d_material.Material2dBinding::texture_with_layout(
      2,
      Some(tile_data),
      @mesh2d_material.Material2dTextureSampleType::UInt,
      @mesh2d_material.Material2dTextureViewDimension::D2,
    ),
  ])
}

///|
pub impl @mesh2d_material.Material2d for TilemapChunkMaterial with fn alpha_mode(
  self,
) {
  self.alpha_mode
}

///|
pub impl @mesh2d_material.Material2d for TilemapChunkMaterial with fn material2d_debug_name() {
  "mgstudio_sprite_render::TilemapChunkMaterial"
}

///|
let tilemap_chunk_material_material2d_keys : @mesh2d_material.Material2dKeys[
  TilemapChunkMaterial,
] = @mesh2d_material.register_material2d_keys(
  TilemapChunkMaterial::material2d_debug_name(),
)

///|
pub impl @mesh2d_material.Material2d for TilemapChunkMaterial with fn material2d_keys() {
  tilemap_chunk_material_material2d_keys
}

///|
pub impl @mesh2d_material.Material2d for TilemapChunkMaterial with fn bind_group(
  self,
) {
  tilemap_chunk_material_bind_group(self.tileset, self.tile_data)
}

///|
pub impl @mesh2d_material.Material2d for TilemapChunkMaterial with fn specialize(
  descriptor,
  layout,
  key,
) {
  layout |> ignore
  key |> ignore
  descriptor
}

///|
pub struct TilemapChunkMaterialPlugin {}

///|
pub fn TilemapChunkMaterialPlugin::TilemapChunkMaterialPlugin() -> TilemapChunkMaterialPlugin {
  TilemapChunkMaterialPlugin::{  }
}

///|
pub impl @app.Plugin for TilemapChunkMaterialPlugin with fn name(_self) {
  "mgstudio.sprite_render.TilemapChunkMaterialPlugin"
}

///|
pub impl @app.Plugin for TilemapChunkMaterialPlugin with fn build(_self, app) {
  register_tilemap_chunk_material_wgsl_source()
  let plugin : @mesh2d_material.Material2dPlugin[TilemapChunkMaterial] = @mesh2d_material.Material2dPlugin::Material2dPlugin()
    .with_asset_init(fn() { TilemapChunkMaterial::TilemapChunkMaterial() })
    .with_vertex_shader(MESH2D_SHADER_PATH)
    .with_fragment_shader(TILEMAP_CHUNK_MATERIAL_SHADER_PATH)
  app.add_plugins(plugin)
}

///|
pub(all) struct PackedTileData {
  tileset_index : Int
  color : @color.Color
  flags : Int
}

///|
pub fn PackedTileData::empty() -> PackedTileData {
  PackedTileData::{
    tileset_index: 0xFFFF,
    color: @color.Color::srgba(0.0F, 0.0F, 0.0F, 0.0F),
    flags: 0,
  }
}

///|
pub fn PackedTileData::from_tile_data(tile : TileData) -> PackedTileData {
  PackedTileData::{
    tileset_index: tile.tileset_index,
    color: tile.color,
    flags: (if tile.visible { 1 } else { 0 }) | (tile.orientation.to_int() << 1),
  }
}

///|
pub fn PackedTileData::from_optional(
  maybe_tile_data : TileData?,
) -> PackedTileData {
  match maybe_tile_data {
    Some(tile) => PackedTileData::from_tile_data(tile)
    None => PackedTileData::empty()
  }
}

///|
fn tilemap_chunk_color_u8(value : Float) -> Int {
  let clamped = if value < 0.0F {
    0.0F
  } else if value > 1.0F {
    1.0F
  } else {
    value
  }
  (clamped * 255.0F + 0.5F).to_int()
}

///|
fn tilemap_chunk_u16_bytes(value : Int) -> (Byte, Byte) {
  let clamped = if value < 0 {
    0U
  } else if value > 0xFFFF {
    0xFFFFU
  } else {
    value.reinterpret_as_uint()
  }
  (
    (clamped & 0xFFU).reinterpret_as_int().to_byte(),
    ((clamped >> 8) & 0xFFU).reinterpret_as_int().to_byte(),
  )
}

///|
fn PackedTileData::write_bytes(
  self : PackedTileData,
  out : Array[Byte],
) -> Unit {
  let (index_lo, index_hi) = tilemap_chunk_u16_bytes(self.tileset_index)
  let (r, g, b, a) = self.color.to_srgba_tuple()
  let (flags_lo, flags_hi) = tilemap_chunk_u16_bytes(self.flags)
  out.push(index_lo)
  out.push(index_hi)
  out.push(tilemap_chunk_color_u8(r).to_byte())
  out.push(tilemap_chunk_color_u8(g).to_byte())
  out.push(tilemap_chunk_color_u8(b).to_byte())
  out.push(tilemap_chunk_color_u8(a).to_byte())
  out.push(flags_lo)
  out.push(flags_hi)
}

///|
fn packed_tile_data_bytes(data : Array[PackedTileData]) -> Bytes {
  let out : Array[Byte] = []
  for tile in data {
    tile.write_bytes(out)
  }
  Bytes::from_array(out)
}

///|
pub fn make_chunk_tile_data_image(
  size : @math.UVec2,
  data : Array[PackedTileData],
) -> @asset.Image? {
  let expected_len = size.x * size.y
  if expected_len <= 0 || data.length() != expected_len {
    return None
  }
  Some(
    @asset.Image::new(size.x, size.y, packed_tile_data_bytes(data))
    .with_format(@asset.TextureFormat::Rgba16Uint)
    .with_sampler(@asset.ImageSampler::nearest()),
  )
}

///|
pub fn tilemap_chunk_tile_data_image(
  chunk : TilemapChunk,
  tile_data : TilemapChunkTileData,
) -> @asset.Image? {
  let expected_len = chunk.tile_capacity()
  if expected_len <= 0 || tile_data.tile_data.length() != expected_len {
    return None
  }
  let packed : Array[PackedTileData] = []
  for maybe_tile in tile_data.tile_data {
    packed.push(PackedTileData::from_optional(maybe_tile))
  }
  make_chunk_tile_data_image(chunk.chunk_size, packed)
}

///|
test "tilemap chunk material makes nearest Rgba16Uint tile data image" {
  let tile = TileData::new(
    7,
    color=@color.Color::srgba(0.25F, 0.5F, 0.75F, 1.0F),
    visible=true,
    orientation=TileOrientation::Rotate90,
  )
  let image = make_chunk_tile_data_image(@math.UVec2::new(2, 1), [
    PackedTileData::from_tile_data(tile),
    PackedTileData::empty(),
  ]).unwrap()
  let ok = image.width == 2 &&
    image.height == 1 &&
    image.format == @asset.TextureFormat::Rgba16Uint &&
    image.sampler is @asset.ImageSampler::Descriptor(_) &&
    image.pixels.length() == 16 &&
    image.pixels[0].to_int() == 7 &&
    image.pixels[1].to_int() == 0 &&
    image.pixels[2].to_int() == 64 &&
    image.pixels[3].to_int() == 128 &&
    image.pixels[4].to_int() == 191 &&
    image.pixels[5].to_int() == 255 &&
    image.pixels[6].to_int() == 7 &&
    image.pixels[7].to_int() == 0 &&
    image.pixels[8].to_int() == 255 &&
    image.pixels[9].to_int() == 255
  debug_inspect(ok, content="true")
}
