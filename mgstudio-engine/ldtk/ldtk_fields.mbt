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
pub suberror LdtkFieldsError {
  FieldNotFound(String)
  WrongFieldType(String)
  UnexpectedNull(String)
}

///|
pub(open) trait LdtkFields {
  field_instances(Self) -> Array[LdtkFieldInstance]
}

///|
pub impl LdtkFields for EntityInstance with field_instances(value) {
  value.field_instances
}

///|
pub impl LdtkFields for Level with field_instances(value) {
  value.field_instances
}

///|
pub impl LdtkFields for LoadedLevel with field_instances(value) {
  value.level.field_instances
}

///|
fn ldtk_wrong_field_type(identifier : String) -> LdtkFieldsError {
  WrongFieldType(identifier)
}

///|
fn[T] ldtk_unwrap_non_null(
  value : T?,
  identifier : String,
) -> T raise LdtkFieldsError {
  match value {
    Some(parsed) => parsed
    None => raise UnexpectedNull(identifier)
  }
}

///|
fn[T] ldtk_fields_all_some(
  values : Array[T?],
  identifier : String,
) -> Array[T] raise LdtkFieldsError {
  let out : Array[T] = []
  for value in values {
    match value {
      Some(item) => out.push(item)
      None => raise UnexpectedNull(identifier)
    }
  }
  out
}

///|
pub fn[A : LdtkFields] ldtk_get_field_instance(
  value : A,
  identifier : String,
) -> LdtkFieldInstance raise LdtkFieldsError {
  for field in value.field_instances() {
    if field.identifier == identifier {
      return field
    }
  }
  raise FieldNotFound(identifier)
}

///|
pub fn[A : LdtkFields] ldtk_get_field(
  value : A,
  identifier : String,
) -> FieldValue raise LdtkFieldsError {
  ldtk_get_field_instance(value, identifier).value
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_int_field(
  value : A,
  identifier : String,
) -> Int? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Int(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_int_field(
  value : A,
  identifier : String,
) -> Int raise LdtkFieldsError {
  ldtk_unwrap_non_null(ldtk_get_maybe_int_field(value, identifier), identifier)
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_float_field(
  value : A,
  identifier : String,
) -> Float? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Float(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_float_field(
  value : A,
  identifier : String,
) -> Float raise LdtkFieldsError {
  ldtk_unwrap_non_null(
    ldtk_get_maybe_float_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_bool_field(
  value : A,
  identifier : String,
) -> Bool raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Bool(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_string_field(
  value : A,
  identifier : String,
) -> String? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    String(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_string_field(
  value : A,
  identifier : String,
) -> String raise LdtkFieldsError {
  ldtk_unwrap_non_null(
    ldtk_get_maybe_string_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_color_field(
  value : A,
  identifier : String,
) -> @sprite.Color raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Color(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_file_path_field(
  value : A,
  identifier : String,
) -> String? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    FilePath(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_file_path_field(
  value : A,
  identifier : String,
) -> String raise LdtkFieldsError {
  ldtk_unwrap_non_null(
    ldtk_get_maybe_file_path_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_enum_field(
  value : A,
  identifier : String,
) -> String? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Enum(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_enum_field(
  value : A,
  identifier : String,
) -> String raise LdtkFieldsError {
  ldtk_unwrap_non_null(ldtk_get_maybe_enum_field(value, identifier), identifier)
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_tile_field(
  value : A,
  identifier : String,
) -> TilesetRectangle? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Tile(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_tile_field(
  value : A,
  identifier : String,
) -> TilesetRectangle raise LdtkFieldsError {
  ldtk_unwrap_non_null(ldtk_get_maybe_tile_field(value, identifier), identifier)
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_entity_ref_field(
  value : A,
  identifier : String,
) -> ReferenceToAnEntityInstance? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    EntityRef(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_entity_ref_field(
  value : A,
  identifier : String,
) -> ReferenceToAnEntityInstance raise LdtkFieldsError {
  ldtk_unwrap_non_null(
    ldtk_get_maybe_entity_ref_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_point_field(
  value : A,
  identifier : String,
) -> @math.IVec2? raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Point(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_point_field(
  value : A,
  identifier : String,
) -> @math.IVec2 raise LdtkFieldsError {
  ldtk_unwrap_non_null(
    ldtk_get_maybe_point_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_ints_field(
  value : A,
  identifier : String,
) -> Array[Int?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Ints(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_ints_field(
  value : A,
  identifier : String,
) -> Array[Int] raise LdtkFieldsError {
  ldtk_fields_all_some(ldtk_get_maybe_ints_field(value, identifier), identifier)
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_floats_field(
  value : A,
  identifier : String,
) -> Array[Float?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Floats(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_floats_field(
  value : A,
  identifier : String,
) -> Array[Float] raise LdtkFieldsError {
  ldtk_fields_all_some(
    ldtk_get_maybe_floats_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_bools_field(
  value : A,
  identifier : String,
) -> Array[Bool] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Bools(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_strings_field(
  value : A,
  identifier : String,
) -> Array[String?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Strings(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_strings_field(
  value : A,
  identifier : String,
) -> Array[String] raise LdtkFieldsError {
  ldtk_fields_all_some(
    ldtk_get_maybe_strings_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_colors_field(
  value : A,
  identifier : String,
) -> Array[@sprite.Color] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Colors(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_file_paths_field(
  value : A,
  identifier : String,
) -> Array[String?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    FilePaths(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_file_paths_field(
  value : A,
  identifier : String,
) -> Array[String] raise LdtkFieldsError {
  ldtk_fields_all_some(
    ldtk_get_maybe_file_paths_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_enums_field(
  value : A,
  identifier : String,
) -> Array[String?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Enums(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_enums_field(
  value : A,
  identifier : String,
) -> Array[String] raise LdtkFieldsError {
  ldtk_fields_all_some(
    ldtk_get_maybe_enums_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_tiles_field(
  value : A,
  identifier : String,
) -> Array[TilesetRectangle?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Tiles(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_tiles_field(
  value : A,
  identifier : String,
) -> Array[TilesetRectangle] raise LdtkFieldsError {
  ldtk_fields_all_some(
    ldtk_get_maybe_tiles_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_entity_refs_field(
  value : A,
  identifier : String,
) -> Array[ReferenceToAnEntityInstance?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    EntityRefs(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_entity_refs_field(
  value : A,
  identifier : String,
) -> Array[ReferenceToAnEntityInstance] raise LdtkFieldsError {
  ldtk_fields_all_some(
    ldtk_get_maybe_entity_refs_field(value, identifier),
    identifier,
  )
}

///|
pub fn[A : LdtkFields] ldtk_get_maybe_points_field(
  value : A,
  identifier : String,
) -> Array[@math.IVec2?] raise LdtkFieldsError {
  match ldtk_get_field(value, identifier) {
    Points(parsed) => parsed
    _ => raise ldtk_wrong_field_type(identifier)
  }
}

///|
pub fn[A : LdtkFields] ldtk_iter_points_field(
  value : A,
  identifier : String,
) -> Array[@math.IVec2] raise LdtkFieldsError {
  ldtk_fields_all_some(
    ldtk_get_maybe_points_field(value, identifier),
    identifier,
  )
}
