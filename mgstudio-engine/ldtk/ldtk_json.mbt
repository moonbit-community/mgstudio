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
pub struct LdtkFieldInstance {
  identifier : String
  tile : TilesetRectangle?
  field_instance_type : String
  value : FieldValue
  def_uid : Int
  real_editor_values : Array[Json?]
}

///|
pub struct ReferenceToAnEntityInstance {
  entity_iid : String
  layer_iid : String
  level_iid : String
  world_iid : String
}

///|
pub(all) enum FieldValue {
  Int(Int?)
  Float(Float?)
  Bool(Bool)
  String(String?)
  Color(@sprite.Color)
  FilePath(String?)
  Enum(String?)
  Tile(TilesetRectangle?)
  EntityRef(ReferenceToAnEntityInstance?)
  Point(@math.IVec2?)
  Ints(Array[Int?])
  Floats(Array[Float?])
  Bools(Array[Bool])
  Strings(Array[String?])
  Colors(Array[@sprite.Color])
  FilePaths(Array[String?])
  Enums(Array[String?])
  Tiles(Array[TilesetRectangle?])
  EntityRefs(Array[ReferenceToAnEntityInstance?])
  Points(Array[@math.IVec2?])
}

///|
pub struct EntityInstance {
  iid : String
  identifier : String
  def_uid : Int
  width : Int
  height : Int
  tags : Array[String]
  grid : @math.IVec2
  px : @math.IVec2
  pivot : @math.Vec2
  tile : TilesetRectangle?
  world_x : Int?
  world_y : Int?
  field_instances : Array[LdtkFieldInstance]
}

///|
pub struct TilesetRectangle {
  h : Int
  tileset_uid : Int
  w : Int
  x : Int
  y : Int
}

///|
pub struct IntGridValueDefinition {
  value : Int
  color : @sprite.Color
}

///|
pub(all) enum Type {
  AutoLayer
  Entities
  IntGrid
  Tiles
}

///|
pub fn Type::default() -> Type {
  Type::Tiles
}

///|
pub struct TileInstance {
  px : @math.IVec2
  src : @math.IVec2
  f : Int
  t : Int
  d : Array[Int]
}

///|
pub struct LayerInstance {
  c_hei : Int
  c_wid : Int
  grid_size : Int
  identifier : String
  opacity : Float
  px_total_offset_x : Int
  px_total_offset_y : Int
  tileset_def_uid : Int?
  tileset_rel_path : String?
  layer_instance_type : Type
  iid : String
  layer_def_uid : Int
  level_id : Int
  optional_rules : Array[Int]
  override_tileset_uid : Int?
  px_offset_x : Int
  px_offset_y : Int
  seed : Int
  visible : Bool
  int_grid_csv : Array[Int]
  grid_tiles : Array[TileInstance]
  auto_layer_tiles : Array[TileInstance]
  entity_instances : Array[EntityInstance]
}

///|
pub struct NeighbourLevel {
  dir : String
  level_iid : String
}

///|
pub struct LevelBackgroundPosition {
  crop_rect : Array[Float]
  scale : @math.Vec2
  top_left_px : @math.IVec2
}

///|
pub(all) enum BgPos {
  Contain
  Cover
  CoverDirty
  Repeat
  Unscaled
}

///|
pub fn BgPos::default() -> BgPos {
  BgPos::Contain
}

///|
pub struct Level {
  iid : String
  identifier : String
  uid : Int
  world_x : Int
  world_y : Int
  px_wid : Int
  px_hei : Int
  bg_color : @sprite.Color
  bg_pos : LevelBackgroundPosition?
  neighbours : Array[NeighbourLevel]
  smart_color : @sprite.Color
  level_bg_color : @sprite.Color?
  bg_pivot_x : Float
  bg_pivot_y : Float
  level_bg_pos : BgPos?
  bg_rel_path : String?
  external_rel_path : String?
  field_instances : Array[LdtkFieldInstance]
  layer_instances : Array[LayerInstance]?
  use_auto_identifier : Bool
  world_depth : Int
}

///|
pub struct World {
  iid : String
  identifier : String
  world_grid_width : Int?
  world_grid_height : Int?
  world_layout : String?
  levels : Array[Level]
}

///|
pub struct EntityDefinition {
  uid : Int
  identifier : String
  width : Int
  height : Int
  tile_rect : EntityTileRect?
}

///|
pub struct EntityTileRect {
  w : Int
  h : Int
}

///|
pub struct LayerDefinition {
  uid : Int
  identifier : String
  layer_definition_type : Type
  grid_size : Int
  tileset_def_uid : Int?
  tile_pivot_x : Float
  tile_pivot_y : Float
  int_grid_values : Array[IntGridValueDefinition]
}

///|
pub struct LdtkTileEnumTags {
  tags : Array[String]
  source_enum_uid : Int?
}

///|
pub fn LdtkTileEnumTags::new(
  tags : Array[String],
  source_enum_uid : Int?,
) -> LdtkTileEnumTags {
  LdtkTileEnumTags::{ tags, source_enum_uid }
}

///|
pub struct TilesetDefinition {
  uid : Int
  identifier : String
  rel_path : String?
  tile_grid_size : Int
  px_wid : Int
  px_hei : Int
  c_wid : Int
  c_hei : Int
  spacing : Int
  padding : Int
  custom_data_by_tile : @hashmap.HashMap[Int, String]
  enum_tags_by_tile : @hashmap.HashMap[Int, LdtkTileEnumTags]
}

///|
pub struct Definitions {
  entities : Array[EntityDefinition]
  layers : Array[LayerDefinition]
  tilesets : Array[TilesetDefinition]
}

///|
fn ldtk_create_int_grid_image_size(definitions : Definitions) -> Int {
  let mut max_grid_size = 0
  for layer in definitions.layers {
    match layer.layer_definition_type {
      Type::IntGrid =>
        if layer.tileset_def_uid is None && layer.grid_size > max_grid_size {
          max_grid_size = layer.grid_size
        }
      _ => ()
    }
  }
  max_grid_size
}

///|
pub fn Definitions::create_int_grid_image(self : Definitions) -> @asset.Image? {
  let grid_size = ldtk_create_int_grid_image_size(self)
  if grid_size <= 0 {
    return None
  }
  let pixels : Array[Byte] = []
  for _ in 0..<(grid_size * grid_size) {
    pixels.push(255)
    pixels.push(255)
    pixels.push(255)
    pixels.push(255)
  }
  Some(@asset.Image::new(grid_size, grid_size, Bytes::from_array(pixels)))
}

///|
pub struct LdtkJson {
  iid : String
  bg_color : @sprite.Color
  default_level_bg_color : @sprite.Color
  external_levels : Bool
  world_layout : String?
  world_grid_width : Int?
  world_grid_height : Int?
  levels : Array[Level]
  worlds : Array[World]
  defs : Definitions
}

///|
fn ldtk_parse_hex_nibble(value : Int) -> Int {
  if value >= 48 && value <= 57 {
    return value - 48
  }
  if value >= 65 && value <= 70 {
    return value - 65 + 10
  }
  if value >= 97 && value <= 102 {
    return value - 97 + 10
  }
  abort("Invalid hex digit in LDtk color")
}

///|
fn ldtk_parse_hex_pair(source : String, start : Int) -> Int {
  guard start >= 0 && start + 1 < source.length() else {
    abort("Invalid hex color pair bounds")
  }
  let hi = ldtk_parse_hex_nibble(source.code_unit_at(start).to_int())
  let lo = ldtk_parse_hex_nibble(source.code_unit_at(start + 1).to_int())
  hi * 16 + lo
}

///|
fn ldtk_parse_color_hex(value : String) -> @sprite.Color {
  if value.length() == 7 && value.code_unit_at(0).to_int() == 35 {
    let r = Float::from_int(ldtk_parse_hex_pair(value, 1)) / 255.0F
    let g = Float::from_int(ldtk_parse_hex_pair(value, 3)) / 255.0F
    let b = Float::from_int(ldtk_parse_hex_pair(value, 5)) / 255.0F
    return @sprite.Color::srgb(r, g, b)
  }
  if value.length() == 9 && value.code_unit_at(0).to_int() == 35 {
    let r = Float::from_int(ldtk_parse_hex_pair(value, 1)) / 255.0F
    let g = Float::from_int(ldtk_parse_hex_pair(value, 3)) / 255.0F
    let b = Float::from_int(ldtk_parse_hex_pair(value, 5)) / 255.0F
    let a = Float::from_int(ldtk_parse_hex_pair(value, 7)) / 255.0F
    return @sprite.Color::srgba(r, g, b, a)
  }
  abort("Invalid LDtk color format: \{value}")
}

///|
fn ldtk_empty_json_array() -> Json {
  ([] : Array[Json]).to_json()
}

///|
fn[T : @json.FromJson] ldtk_try_from_json(json : Json) -> T? {
  Some(@json.from_json(json)) catch {
    _ => None
  }
}

///|
fn ldtk_json_object(json : Json) -> Map[String, Json] {
  match json {
    Object(obj) => obj
    _ => abort("Expected LDtk JSON object")
  }
}

///|
fn ldtk_json_array(json : Json) -> Array[Json] {
  match json {
    Array(values) => values
    _ => abort("Expected LDtk JSON array")
  }
}

///|
fn ldtk_optional_json(object : Map[String, Json], key : String) -> Json? {
  match object.get(key) {
    Some(Null) => None
    Some(value) => Some(value)
    None => None
  }
}

///|
fn ldtk_object_get_or(
  object : Map[String, Json],
  key : String,
  default : Json,
) -> Json {
  match object.get(key) {
    Some(value) => value
    None => default
  }
}

///|
fn ldtk_optional_int(object : Map[String, Json], key : String) -> Int? {
  match ldtk_optional_json(object, key) {
    Some(value) => Some(try! @json.from_json(value))
    None => None
  }
}

///|
fn ldtk_optional_string(object : Map[String, Json], key : String) -> String? {
  match ldtk_optional_json(object, key) {
    Some(value) => Some(try! @json.from_json(value))
    None => None
  }
}

///|
fn ldtk_int_or_default(
  object : Map[String, Json],
  key : String,
  default : Int,
) -> Int {
  match ldtk_optional_json(object, key) {
    Some(value) => try! @json.from_json(value)
    None => default
  }
}

///|
fn ldtk_float_or_default(
  object : Map[String, Json],
  key : String,
  default : Float,
) -> Float {
  match ldtk_optional_json(object, key) {
    Some(value) => try! @json.from_json(value)
    None => default
  }
}

///|
fn ldtk_bool_or_default(
  object : Map[String, Json],
  key : String,
  default : Bool,
) -> Bool {
  match ldtk_optional_json(object, key) {
    Some(value) => try! @json.from_json(value)
    None => default
  }
}

///|
fn ldtk_string_or_default(
  object : Map[String, Json],
  key : String,
  default : String,
) -> String {
  match ldtk_optional_json(object, key) {
    Some(value) => try! @json.from_json(value)
    None => default
  }
}

///|
fn ldtk_decode_ivec2(json : Json) -> @math.IVec2 {
  let values : Array[Int] = try! @json.from_json(json)
  if values.length() < 2 {
    return @math.IVec2::new(0, 0)
  }
  @math.IVec2::new(values[0], values[1])
}

///|
fn ldtk_decode_vec2(json : Json) -> @math.Vec2 {
  let values : Array[Float] = try! @json.from_json(json)
  if values.length() < 2 {
    return @math.Vec2::new(0.0F, 0.0F)
  }
  @math.Vec2::new(values[0], values[1])
}

///|
fn ldtk_decode_type(value : String) -> Type {
  match value {
    "AutoLayer" => Type::AutoLayer
    "Entities" => Type::Entities
    "IntGrid" => Type::IntGrid
    "Tiles" => Type::Tiles
    _ => Type::default()
  }
}

///|
fn ldtk_decode_bg_pos(value : String) -> BgPos {
  match value {
    "Contain" => BgPos::Contain
    "Cover" => BgPos::Cover
    "CoverDirty" => BgPos::CoverDirty
    "Repeat" => BgPos::Repeat
    "Unscaled" => BgPos::Unscaled
    _ => BgPos::default()
  }
}

///|
fn ldtk_decode_tileset_rectangle(json : Json) -> TilesetRectangle {
  let object = ldtk_json_object(json)
  TilesetRectangle::{
    h: ldtk_int_or_default(object, "h", 0),
    tileset_uid: ldtk_int_or_default(object, "tilesetUid", -1),
    w: ldtk_int_or_default(object, "w", 0),
    x: ldtk_int_or_default(object, "x", 0),
    y: ldtk_int_or_default(object, "y", 0),
  }
}

///|
fn ldtk_decode_reference_to_entity_instance(
  json : Json,
) -> ReferenceToAnEntityInstance {
  let object = ldtk_json_object(json)
  ReferenceToAnEntityInstance::{
    entity_iid: ldtk_string_or_default(object, "entityIid", ""),
    layer_iid: ldtk_string_or_default(object, "layerIid", ""),
    level_iid: ldtk_string_or_default(object, "levelIid", ""),
    world_iid: ldtk_string_or_default(object, "worldIid", ""),
  }
}

///|
fn ldtk_decode_grid_point(json : Json) -> @math.IVec2 {
  let object = ldtk_json_object(json)
  @math.IVec2::new(
    ldtk_int_or_default(object, "cx", 0),
    ldtk_int_or_default(object, "cy", 0),
  )
}

///|
fn ldtk_field_type_is_enum(field_instance_type : String) -> Bool {
  field_instance_type.has_prefix("LocalEnum.") ||
  field_instance_type.has_prefix("ExternEnum.")
}

///|
fn ldtk_field_type_is_enum_array(field_instance_type : String) -> Bool {
  field_instance_type.has_prefix("Array<LocalEnum.") ||
  field_instance_type.has_prefix("Array<ExternEnum.")
}

///|
fn ldtk_decode_field_colors(value : Json) -> Array[@sprite.Color] {
  let out : Array[@sprite.Color] = []
  for color_json in ldtk_json_array(value) {
    match color_json {
      String(color_hex) => out.push(ldtk_parse_color_hex(color_hex))
      _ => abort("Invalid LDtk color array payload")
    }
  }
  out
}

///|
fn ldtk_decode_field_points(value : Json) -> Array[@math.IVec2?] {
  let out : Array[@math.IVec2?] = []
  for point_json in ldtk_json_array(value) {
    match point_json {
      Null => out.push(None)
      _ => out.push(Some(ldtk_decode_grid_point(point_json)))
    }
  }
  out
}

///|
fn ldtk_decode_field_entity_refs(
  value : Json,
) -> Array[ReferenceToAnEntityInstance?] {
  let out : Array[ReferenceToAnEntityInstance?] = []
  for ref_json in ldtk_json_array(value) {
    match ref_json {
      Null => out.push(None)
      _ => out.push(Some(ldtk_decode_reference_to_entity_instance(ref_json)))
    }
  }
  out
}

///|
fn ldtk_decode_field_tiles(value : Json) -> Array[TilesetRectangle?] {
  let out : Array[TilesetRectangle?] = []
  for tile_json in ldtk_json_array(value) {
    match tile_json {
      Null => out.push(None)
      _ => out.push(Some(ldtk_decode_tileset_rectangle(tile_json)))
    }
  }
  out
}

///|
fn ldtk_decode_field_value(
  field_instance_type : String,
  value : Json,
) -> FieldValue {
  match field_instance_type {
    "Int" => Int(ldtk_try_from_json(value))
    "Float" => Float(ldtk_try_from_json(value))
    "Bool" => Bool(try! @json.from_json(value))
    "String" => String(ldtk_try_from_json(value))
    "Color" =>
      match value {
        String(color_hex) => Color(ldtk_parse_color_hex(color_hex))
        _ => abort("Invalid LDtk Color field payload")
      }
    "FilePath" => FilePath(ldtk_try_from_json(value))
    "Tile" =>
      match value {
        Null => Tile(None)
        _ => Tile(Some(ldtk_decode_tileset_rectangle(value)))
      }
    "EntityRef" =>
      match value {
        Null => EntityRef(None)
        _ => EntityRef(Some(ldtk_decode_reference_to_entity_instance(value)))
      }
    "Point" =>
      match value {
        Null => Point(None)
        _ => Point(Some(ldtk_decode_grid_point(value)))
      }
    "Multilines" => String(ldtk_try_from_json(value))
    "Array<Multilines>" => Strings(try! @json.from_json(value))
    "Array<Int>" => Ints(try! @json.from_json(value))
    "Array<Float>" => Floats(try! @json.from_json(value))
    "Array<Bool>" => Bools(try! @json.from_json(value))
    "Array<String>" => Strings(try! @json.from_json(value))
    "Array<Color>" => Colors(ldtk_decode_field_colors(value))
    "Array<FilePath>" => FilePaths(try! @json.from_json(value))
    "Array<Tile>" => Tiles(ldtk_decode_field_tiles(value))
    "Array<EntityRef>" => EntityRefs(ldtk_decode_field_entity_refs(value))
    "Array<Point>" => Points(ldtk_decode_field_points(value))
    _ =>
      if ldtk_field_type_is_enum(field_instance_type) {
        Enum(ldtk_try_from_json(value))
      } else if ldtk_field_type_is_enum_array(field_instance_type) {
        Enums(try! @json.from_json(value))
      } else {
        abort("Encountered unknown LDtk field type: \{field_instance_type}")
      }
  }
}

///|
fn ldtk_decode_level_background_position(
  json : Json,
) -> LevelBackgroundPosition {
  let object = ldtk_json_object(json)
  let crop_rect : Array[Float] = match ldtk_optional_json(object, "cropRect") {
    Some(value) => try! @json.from_json(value)
    None => []
  }
  LevelBackgroundPosition::{
    crop_rect,
    scale: ldtk_decode_vec2(
      ldtk_object_get_or(object, "scale", [1.0, 1.0].to_json()),
    ),
    top_left_px: ldtk_decode_ivec2(
      ldtk_object_get_or(object, "topLeftPx", [0, 0].to_json()),
    ),
  }
}

///|
fn ldtk_decode_tile_instance(json : Json) -> TileInstance {
  let object = ldtk_json_object(json)
  TileInstance::{
    px: ldtk_decode_ivec2(ldtk_object_get_or(object, "__px", [0, 0].to_json())),
    src: ldtk_decode_ivec2(ldtk_object_get_or(object, "src", [0, 0].to_json())),
    f: ldtk_int_or_default(object, "f", 0),
    t: ldtk_int_or_default(object, "t", -1),
    d: match ldtk_optional_json(object, "d") {
      Some(value) => try! @json.from_json(value)
      None => []
    },
  }
}

///|
fn ldtk_decode_field_instance(json : Json) -> LdtkFieldInstance {
  let object = ldtk_json_object(json)
  let field_instance_type = ldtk_string_or_default(object, "__type", "")
  let field_value_json = ldtk_object_get_or(object, "__value", Json::null())
  let real_editor_values : Array[Json?] = match
    ldtk_optional_json(object, "realEditorValues") {
    Some(value) => try! @json.from_json(value)
    None => []
  }
  LdtkFieldInstance::{
    identifier: ldtk_string_or_default(object, "__identifier", ""),
    tile: match ldtk_optional_json(object, "__tile") {
      Some(value) => Some(ldtk_decode_tileset_rectangle(value))
      None => None
    },
    field_instance_type,
    value: ldtk_decode_field_value(field_instance_type, field_value_json),
    def_uid: ldtk_int_or_default(object, "defUid", -1),
    real_editor_values,
  }
}

///|
fn ldtk_decode_entity_instance(json : Json) -> EntityInstance {
  let object = ldtk_json_object(json)
  let field_instances : Array[LdtkFieldInstance] = []
  for
    field_json in ldtk_json_array(
      ldtk_object_get_or(object, "fieldInstances", ldtk_empty_json_array()),
    ) {
    field_instances.push(ldtk_decode_field_instance(field_json))
  }
  EntityInstance::{
    iid: ldtk_string_or_default(object, "iid", ""),
    identifier: ldtk_string_or_default(object, "__identifier", ""),
    def_uid: ldtk_int_or_default(object, "defUid", -1),
    width: ldtk_int_or_default(object, "width", 0),
    height: ldtk_int_or_default(object, "height", 0),
    tags: match ldtk_optional_json(object, "__tags") {
      Some(value) => try! @json.from_json(value)
      None => []
    },
    grid: ldtk_decode_ivec2(
      ldtk_object_get_or(object, "__grid", [0, 0].to_json()),
    ),
    px: ldtk_decode_ivec2(ldtk_object_get_or(object, "px", [0, 0].to_json())),
    pivot: ldtk_decode_vec2(
      ldtk_object_get_or(object, "__pivot", [0.0, 0.0].to_json()),
    ),
    tile: match ldtk_optional_json(object, "__tile") {
      Some(value) => Some(ldtk_decode_tileset_rectangle(value))
      None => None
    },
    world_x: ldtk_optional_int(object, "__worldX"),
    world_y: ldtk_optional_int(object, "__worldY"),
    field_instances,
  }
}

///|
fn ldtk_decode_layer_instance(json : Json) -> LayerInstance {
  let object = ldtk_json_object(json)
  let int_grid_csv : Array[Int] = match
    ldtk_optional_json(object, "intGridCsv") {
    Some(value) => try! @json.from_json(value)
    None => []
  }
  let grid_tiles : Array[TileInstance] = []
  for
    tile_json in ldtk_json_array(
      ldtk_object_get_or(object, "gridTiles", ldtk_empty_json_array()),
    ) {
    grid_tiles.push(ldtk_decode_tile_instance(tile_json))
  }
  let auto_layer_tiles : Array[TileInstance] = []
  for
    tile_json in ldtk_json_array(
      ldtk_object_get_or(object, "autoLayerTiles", ldtk_empty_json_array()),
    ) {
    auto_layer_tiles.push(ldtk_decode_tile_instance(tile_json))
  }
  let entity_instances : Array[EntityInstance] = []
  for
    entity_json in ldtk_json_array(
      ldtk_object_get_or(object, "entityInstances", ldtk_empty_json_array()),
    ) {
    entity_instances.push(ldtk_decode_entity_instance(entity_json))
  }
  LayerInstance::{
    c_hei: ldtk_int_or_default(object, "__cHei", 0),
    c_wid: ldtk_int_or_default(object, "__cWid", 0),
    grid_size: ldtk_int_or_default(object, "__gridSize", 0),
    identifier: ldtk_string_or_default(object, "__identifier", ""),
    opacity: ldtk_float_or_default(object, "__opacity", 1.0F),
    px_total_offset_x: ldtk_int_or_default(object, "__pxTotalOffsetX", 0),
    px_total_offset_y: ldtk_int_or_default(object, "__pxTotalOffsetY", 0),
    tileset_def_uid: ldtk_optional_int(object, "__tilesetDefUid"),
    tileset_rel_path: ldtk_optional_string(object, "__tilesetRelPath"),
    layer_instance_type: ldtk_decode_type(
      ldtk_string_or_default(object, "__type", "Tiles"),
    ),
    iid: ldtk_string_or_default(object, "iid", ""),
    layer_def_uid: ldtk_int_or_default(object, "layerDefUid", -1),
    level_id: ldtk_int_or_default(object, "levelId", -1),
    optional_rules: match ldtk_optional_json(object, "optionalRules") {
      Some(value) => try! @json.from_json(value)
      None => []
    },
    override_tileset_uid: ldtk_optional_int(object, "overrideTilesetUid"),
    px_offset_x: ldtk_int_or_default(object, "pxOffsetX", 0),
    px_offset_y: ldtk_int_or_default(object, "pxOffsetY", 0),
    seed: ldtk_int_or_default(object, "seed", 0),
    visible: ldtk_bool_or_default(object, "visible", true),
    int_grid_csv,
    grid_tiles,
    auto_layer_tiles,
    entity_instances,
  }
}

///|
fn ldtk_decode_level_neighbours(json : Json) -> Array[NeighbourLevel] {
  let out : Array[NeighbourLevel] = []
  for value in ldtk_json_array(json) {
    let object = ldtk_json_object(value)
    let level_iid = ldtk_string_or_default(object, "levelIid", "")
    if level_iid != "" {
      out.push(NeighbourLevel::{
        dir: ldtk_string_or_default(object, "dir", ""),
        level_iid,
      })
    }
  }
  out
}

///|
fn ldtk_decode_level(json : Json) -> Level {
  let object = ldtk_json_object(json)
  let field_instances : Array[LdtkFieldInstance] = []
  for
    field_json in ldtk_json_array(
      ldtk_object_get_or(object, "fieldInstances", ldtk_empty_json_array()),
    ) {
    field_instances.push(ldtk_decode_field_instance(field_json))
  }
  let layer_instances = match ldtk_optional_json(object, "layerInstances") {
    Some(value) => {
      let parsed : Array[LayerInstance] = []
      for layer_json in ldtk_json_array(value) {
        parsed.push(ldtk_decode_layer_instance(layer_json))
      }
      Some(parsed)
    }
    None => None
  }
  Level::{
    iid: ldtk_string_or_default(object, "iid", ""),
    identifier: ldtk_string_or_default(object, "identifier", ""),
    uid: ldtk_int_or_default(object, "uid", -1),
    world_x: ldtk_int_or_default(object, "worldX", 0),
    world_y: ldtk_int_or_default(object, "worldY", 0),
    px_wid: ldtk_int_or_default(object, "pxWid", 0),
    px_hei: ldtk_int_or_default(object, "pxHei", 0),
    bg_color: ldtk_parse_color_hex(
      ldtk_string_or_default(object, "__bgColor", "#000000"),
    ),
    bg_pos: match ldtk_optional_json(object, "__bgPos") {
      Some(value) => Some(ldtk_decode_level_background_position(value))
      None => None
    },
    neighbours: ldtk_decode_level_neighbours(
      ldtk_object_get_or(object, "__neighbours", ldtk_empty_json_array()),
    ),
    smart_color: ldtk_parse_color_hex(
      ldtk_string_or_default(
        object,
        "__smartColor",
        ldtk_string_or_default(object, "__bgColor", "#000000"),
      ),
    ),
    level_bg_color: match ldtk_optional_string(object, "bgColor") {
      Some(value) => Some(ldtk_parse_color_hex(value))
      None => None
    },
    bg_pivot_x: ldtk_float_or_default(object, "bgPivotX", 0.0F),
    bg_pivot_y: ldtk_float_or_default(object, "bgPivotY", 0.0F),
    level_bg_pos: match ldtk_optional_string(object, "bgPos") {
      Some(value) => Some(ldtk_decode_bg_pos(value))
      None => None
    },
    bg_rel_path: ldtk_optional_string(object, "bgRelPath"),
    external_rel_path: ldtk_optional_string(object, "externalRelPath"),
    field_instances,
    layer_instances,
    use_auto_identifier: ldtk_bool_or_default(
      object, "useAutoIdentifier", false,
    ),
    world_depth: ldtk_int_or_default(object, "worldDepth", 0),
  }
}

///|
fn ldtk_decode_world(json : Json) -> World {
  let object = ldtk_json_object(json)
  let levels : Array[Level] = []
  for
    level_json in ldtk_json_array(
      ldtk_object_get_or(object, "levels", ldtk_empty_json_array()),
    ) {
    levels.push(ldtk_decode_level(level_json))
  }
  World::{
    iid: ldtk_string_or_default(object, "iid", ""),
    identifier: ldtk_string_or_default(object, "identifier", ""),
    world_grid_width: ldtk_optional_int(object, "worldGridWidth"),
    world_grid_height: ldtk_optional_int(object, "worldGridHeight"),
    world_layout: ldtk_optional_string(object, "worldLayout"),
    levels,
  }
}

///|
fn ldtk_decode_tileset_definition(json : Json) -> TilesetDefinition {
  let object = ldtk_json_object(json)
  let custom_data_by_tile : @hashmap.HashMap[Int, String] = @hashmap.HashMap::new()
  for
    custom_json in ldtk_json_array(
      ldtk_object_get_or(object, "customData", ldtk_empty_json_array()),
    ) {
    let custom_object = ldtk_json_object(custom_json)
    let tile_id = ldtk_int_or_default(custom_object, "tileId", -1)
    let data = ldtk_string_or_default(custom_object, "data", "")
    if tile_id >= 0 {
      custom_data_by_tile.set(tile_id, data)
    }
  }

  let enum_tags_by_tile : @hashmap.HashMap[Int, LdtkTileEnumTags] = @hashmap.HashMap::new()
  for
    tag_json in ldtk_json_array(
      ldtk_object_get_or(object, "enumTags", ldtk_empty_json_array()),
    ) {
    let tag_object = ldtk_json_object(tag_json)
    let tag_name = ldtk_string_or_default(tag_object, "enumValueId", "")
    let source_enum_uid = ldtk_optional_int(tag_object, "sourceEnumUid")
    let tile_ids : Array[Int] = match
      ldtk_optional_json(tag_object, "tileIds") {
      Some(value) => try! @json.from_json(value)
      None => []
    }
    for tile_id in tile_ids {
      if enum_tags_by_tile.get(tile_id) is Some(previous) {
        let merged_tags = previous.tags.copy()
        if tag_name != "" {
          merged_tags.push(tag_name)
        }
        enum_tags_by_tile.set(
          tile_id,
          LdtkTileEnumTags::new(merged_tags, previous.source_enum_uid),
        )
      } else {
        let tags : Array[String] = []
        if tag_name != "" {
          tags.push(tag_name)
        }
        enum_tags_by_tile.set(
          tile_id,
          LdtkTileEnumTags::new(tags, source_enum_uid),
        )
      }
    }
  }

  TilesetDefinition::{
    uid: ldtk_int_or_default(object, "uid", -1),
    identifier: ldtk_string_or_default(object, "identifier", ""),
    rel_path: ldtk_optional_string(object, "relPath"),
    tile_grid_size: ldtk_int_or_default(object, "tileGridSize", 0),
    px_wid: ldtk_int_or_default(object, "pxWid", 0),
    px_hei: ldtk_int_or_default(object, "pxHei", 0),
    c_wid: ldtk_int_or_default(object, "__cWid", 0),
    c_hei: ldtk_int_or_default(object, "__cHei", 0),
    spacing: ldtk_int_or_default(object, "spacing", 0),
    padding: ldtk_int_or_default(object, "padding", 0),
    custom_data_by_tile,
    enum_tags_by_tile,
  }
}

///|
fn ldtk_decode_entity_definition(json : Json) -> EntityDefinition {
  let object = ldtk_json_object(json)
  let tile_rect = match ldtk_optional_json(object, "tileRect") {
    Some(tile_rect_json) => {
      let tile_rect_object = ldtk_json_object(tile_rect_json)
      Some(EntityTileRect::{
        w: ldtk_int_or_default(tile_rect_object, "w", 0),
        h: ldtk_int_or_default(tile_rect_object, "h", 0),
      })
    }
    None => None
  }
  EntityDefinition::{
    uid: ldtk_int_or_default(object, "uid", -1),
    identifier: ldtk_string_or_default(object, "identifier", ""),
    width: ldtk_int_or_default(object, "width", 0),
    height: ldtk_int_or_default(object, "height", 0),
    tile_rect,
  }
}

///|
fn ldtk_decode_layer_definition(json : Json) -> LayerDefinition {
  let object = ldtk_json_object(json)
  let int_grid_values : Array[IntGridValueDefinition] = []
  for
    value_json in ldtk_json_array(
      ldtk_object_get_or(object, "intGridValues", ldtk_empty_json_array()),
    ) {
    let value_object = ldtk_json_object(value_json)
    int_grid_values.push(IntGridValueDefinition::{
      value: ldtk_int_or_default(value_object, "value", 0),
      color: ldtk_parse_color_hex(
        ldtk_string_or_default(value_object, "color", "#000000"),
      ),
    })
  }
  LayerDefinition::{
    uid: ldtk_int_or_default(object, "uid", -1),
    identifier: ldtk_string_or_default(object, "identifier", ""),
    layer_definition_type: ldtk_decode_type(
      match ldtk_optional_string(object, "__type") {
        Some(value) => value
        None => ldtk_string_or_default(object, "type", "Tiles")
      },
    ),
    grid_size: ldtk_int_or_default(object, "gridSize", 0),
    tileset_def_uid: ldtk_optional_int(object, "tilesetDefUid"),
    tile_pivot_x: ldtk_float_or_default(object, "tilePivotX", 0.0F),
    tile_pivot_y: ldtk_float_or_default(object, "tilePivotY", 0.0F),
    int_grid_values,
  }
}

///|
fn ldtk_decode_definitions(json : Json) -> Definitions {
  let object = ldtk_json_object(json)
  let entities : Array[EntityDefinition] = []
  for
    entity_json in ldtk_json_array(
      ldtk_object_get_or(object, "entities", ldtk_empty_json_array()),
    ) {
    entities.push(ldtk_decode_entity_definition(entity_json))
  }
  let layers : Array[LayerDefinition] = []
  for
    layer_json in ldtk_json_array(
      ldtk_object_get_or(object, "layers", ldtk_empty_json_array()),
    ) {
    layers.push(ldtk_decode_layer_definition(layer_json))
  }
  let tilesets : Array[TilesetDefinition] = []
  for
    tileset_json in ldtk_json_array(
      ldtk_object_get_or(object, "tilesets", ldtk_empty_json_array()),
    ) {
    tilesets.push(ldtk_decode_tileset_definition(tileset_json))
  }
  Definitions::{ entities, layers, tilesets }
}

///|
pub fn ldtk_parse_json_from_text(text : String) -> LdtkJson {
  let parsed = try! @json.parse(text[:])
  let object = ldtk_json_object(parsed)
  let levels : Array[Level] = []
  for
    level_json in ldtk_json_array(
      ldtk_object_get_or(object, "levels", ldtk_empty_json_array()),
    ) {
    levels.push(ldtk_decode_level(level_json))
  }
  let worlds : Array[World] = []
  for
    world_json in ldtk_json_array(
      ldtk_object_get_or(object, "worlds", ldtk_empty_json_array()),
    ) {
    worlds.push(ldtk_decode_world(world_json))
  }
  LdtkJson::{
    iid: ldtk_string_or_default(object, "iid", ""),
    bg_color: ldtk_parse_color_hex(
      ldtk_string_or_default(object, "bgColor", "#000000"),
    ),
    default_level_bg_color: ldtk_parse_color_hex(
      ldtk_string_or_default(object, "defaultLevelBgColor", "#000000"),
    ),
    external_levels: ldtk_bool_or_default(object, "externalLevels", false),
    world_layout: ldtk_optional_string(object, "worldLayout"),
    world_grid_width: ldtk_optional_int(object, "worldGridWidth"),
    world_grid_height: ldtk_optional_int(object, "worldGridHeight"),
    levels,
    worlds,
    defs: ldtk_decode_definitions(
      ldtk_object_get_or(
        object,
        "defs",
        {
          "entities": ldtk_empty_json_array(),
          "layers": ldtk_empty_json_array(),
          "tilesets": ldtk_empty_json_array(),
        }.to_json(),
      ),
    ),
  }
}

///|
pub fn ldtk_parse_json(bytes : Bytes) -> LdtkJson {
  let text = @utf8.decode_lossy(bytes[:], ignore_bom=true)
  ldtk_parse_json_from_text(text)
}
