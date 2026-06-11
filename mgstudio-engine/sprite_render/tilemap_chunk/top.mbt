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

///|
pub struct TilemapChunkPlugin {}

///|
pub fn TilemapChunkPlugin::TilemapChunkPlugin() -> TilemapChunkPlugin {
  TilemapChunkPlugin::{  }
}

///|
pub impl @app.Plugin for TilemapChunkPlugin with fn name(_self) {
  "mgstudio.sprite_render.TilemapChunkPlugin"
}

///|
pub impl @app.Plugin for TilemapChunkPlugin with fn build(_self, app) {
  app
  .init_resource(fn() { TilemapChunkMeshCache::TilemapChunkMeshCache() })
  .add_systems(@app.Update, @app.system(update_tilemap_chunk_indices))
}

///|
pub struct TilemapChunkMeshCache {
  handles : @hashmap.HashMap[String, @asset.Handle[@mesh.Mesh]]
}

///|
pub fn TilemapChunkMeshCache::TilemapChunkMeshCache() -> TilemapChunkMeshCache {
  TilemapChunkMeshCache::{ handles: @hashmap.HashMap([]) }
}

///|
pub impl @app.Resource for TilemapChunkMeshCache with fn resource() {
  tilemap_chunk_mesh_cache_key
}

///|
let tilemap_chunk_mesh_cache_key : @ecs.ResourceKey[TilemapChunkMeshCache] = @ecs.register_resource(
  debug_name="mgstudio_sprite_render::TilemapChunkMeshCache",
)

///|
fn tilemap_chunk_mesh_size(chunk : TilemapChunk) -> @math.UVec2 {
  let safe_chunk_size = tilemap_chunk_safe_uvec2(
    chunk.chunk_size,
    @math.UVec2::new(1, 1),
  )
  let safe_tile_size = tilemap_chunk_safe_uvec2(
    chunk.tile_display_size,
    @math.UVec2::new(1, 1),
  )
  @math.UVec2::new(
    safe_chunk_size.x * safe_tile_size.x,
    safe_chunk_size.y * safe_tile_size.y,
  )
}

///|
fn tilemap_chunk_mesh_cache_string(size : @math.UVec2) -> String {
  "\{size.x.to_string()}x\{size.y.to_string()}"
}

///|
fn tilemap_chunk_entity_key(entity : @core.Entity) -> UInt64 {
  let hi = entity.id.reinterpret_as_uint().to_uint64()
  let lo = entity.generation.reinterpret_as_uint().to_uint64() & 0xFFFF_FFFFUL
  (hi << 32) | lo
}

///|
fn tilemap_chunk_insert_entity_key(
  set : @hashset.HashSet[UInt64],
  entity : @core.Entity,
) -> Unit {
  set.add(tilemap_chunk_entity_key(entity))
}

///|
fn tilemap_chunk_mesh_handle(
  world : @ecs.World,
  chunk : TilemapChunk,
) -> @asset.Handle[@mesh.Mesh] {
  let size = tilemap_chunk_mesh_size(chunk)
  let key = tilemap_chunk_mesh_cache_string(size)
  let cache_ref = world
    .get_resource_mut(TilemapChunkMeshCache::resource())
    .unwrap()
  if cache_ref.peek().handles.get(key) is Some(handle) {
    return handle
  }
  let mesh_assets_key : @ecs.ResourceKey[@asset.Assets[@mesh.Mesh]] = @asset.assets_resource_key()
  let mesh_assets_ref = world.get_resource_mut(mesh_assets_key).unwrap()
  let handle = mesh_assets_ref.modify(fn(meshes) {
    @mesh_primitives.add_mesh(
      meshes,
      @math.Rectangle::from_size(
        @math.Vec2::new(
          Float::from_double(size.x.to_double()),
          Float::from_double(size.y.to_double()),
        ),
      ),
    )
  })
  cache_ref.modify(fn(cache) { cache.handles.set(key, handle) })
  handle
}

///|
fn tilemap_chunk_update_tile_data_image(
  world : @ecs.World,
  handle : @asset.Handle[@asset.Image],
  chunk : TilemapChunk,
  tile_data : TilemapChunkTileData,
) -> Bool {
  guard tilemap_chunk_tile_data_image(chunk, tile_data) is Some(image) else {
    return false
  }
  let images_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  guard world.get_resource_mut(images_key) is Some(images_ref) else {
    return false
  }
  images_ref.modify(fn(images) { images.set(handle, image) })
}

///|
fn tilemap_chunk_create_material(
  world : @ecs.World,
  chunk : TilemapChunk,
  tile_data : TilemapChunkTileData,
) -> @asset.Handle[TilemapChunkMaterial]? {
  guard tilemap_chunk_tile_data_image(chunk, tile_data) is Some(image) else {
    return None
  }
  let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  let material_assets_key : @ecs.ResourceKey[
    @asset.Assets[TilemapChunkMaterial],
  ] = @asset.assets_resource_key()
  guard world.get_resource_mut(image_assets_key) is Some(images_ref) else {
    return None
  }
  let tile_data_handle = images_ref.modify(fn(images) { images.add(image) })
  guard world.get_resource_mut(material_assets_key) is Some(materials_ref) else {
    return None
  }
  Some(
    materials_ref.modify(fn(materials) {
      materials.add(
        TilemapChunkMaterial::new(
          chunk.tileset,
          tile_data_handle,
          chunk.alpha_mode,
        ),
      )
    }),
  )
}

///|
fn tilemap_chunk_sync_existing_material(
  world : @ecs.World,
  handle : @asset.Handle[TilemapChunkMaterial],
  chunk : TilemapChunk,
  tile_data : TilemapChunkTileData,
) -> Bool {
  let material_assets_key : @ecs.ResourceKey[
    @asset.Assets[TilemapChunkMaterial],
  ] = @asset.assets_resource_key()
  guard world.get_resource_mut(material_assets_key) is Some(materials_ref) else {
    return false
  }
  guard materials_ref.peek().get(handle) is Some(material) else { return false }
  if !tilemap_chunk_update_tile_data_image(
      world,
      material.tile_data,
      chunk,
      tile_data,
    ) {
    return false
  }
  materials_ref.modify(fn(materials) {
    materials.set(
      handle,
      TilemapChunkMaterial::new(
        chunk.tileset,
        material.tile_data,
        chunk.alpha_mode,
      ),
    )
  })
}

///|
pub fn update_tilemap_chunk_indices(world : @ecs.World) -> Unit {
  if world.component_count(ecs_key_tilemap_chunk) == 0 {
    return
  }
  let tick = world.get_tick_context().ticks()
  let changed : @hashset.HashSet[UInt64] = @hashset.HashSet([])
  for entity in world.added_components(ecs_key_tilemap_chunk, tick).read() {
    tilemap_chunk_insert_entity_key(changed, entity)
  }
  for entity in world.changed_components(ecs_key_tilemap_chunk, tick).read() {
    tilemap_chunk_insert_entity_key(changed, entity)
  }
  for
    entity in world
    .added_components(ecs_key_tilemap_chunk_tile_data, tick)
    .read() {
    tilemap_chunk_insert_entity_key(changed, entity)
  }
  for
    entity in world
    .changed_components(ecs_key_tilemap_chunk_tile_data, tick)
    .read() {
    tilemap_chunk_insert_entity_key(changed, entity)
  }
  let material_key : @ecs.ComponentKey[
    @mesh2d_material.MeshMaterial2d[TilemapChunkMaterial],
  ] = @mesh2d_material.MeshMaterial2d::component()
  let query : @ecs.Query[
    (@ecs.Read[TilemapChunk], @ecs.Read[TilemapChunkTileData]),
    @ecs.All,
  ] = @ecs.query(world)
  let updates : Array[
    (@core.Entity, TilemapChunk, TilemapChunkTileData, Bool, Bool),
  ] = []
  try! query.view(fn(entity, data) {
    let missing_mesh = (try! world.get_by_key(entity, @mesh.ecs_key_mesh2d))
      is None
    let missing_material = (try! world.get_by_key(entity, material_key)) is None
    if !missing_mesh &&
      !missing_material &&
      !changed.contains(tilemap_chunk_entity_key(entity)) {
      return
    }
    let (chunk, tile_data) = data
    updates.push(
      (entity, chunk.value(), tile_data.value(), missing_mesh, missing_material),
    )
  })
  for update in updates {
    let (entity, chunk, tile_data, missing_mesh, missing_material) = update
    if missing_mesh || changed.contains(tilemap_chunk_entity_key(entity)) {
      let mesh = tilemap_chunk_mesh_handle(world, chunk)
      try! world.set_by_key(
        entity,
        @mesh.ecs_key_mesh2d,
        @mesh.Mesh2d::new(mesh),
      )
    }
    if missing_material {
      guard tilemap_chunk_create_material(world, chunk, tile_data)
        is Some(material) else {
        continue
      }
      try! world.set_by_key(
        entity,
        material_key,
        @mesh2d_material.MeshMaterial2d::new(material),
      )
    } else if changed.contains(tilemap_chunk_entity_key(entity)) {
      guard (try! world.get_by_key(entity, material_key)) is Some(material) else {
        continue
      }
      if !tilemap_chunk_sync_existing_material(
          world,
          material.handle,
          chunk,
          tile_data,
        ) {
        guard tilemap_chunk_create_material(world, chunk, tile_data)
          is Some(next_material) else {
          continue
        }
        try! world.set_by_key(
          entity,
          material_key,
          @mesh2d_material.MeshMaterial2d::new(next_material),
        )
      }
    }
  }
}
