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
pub fn int_grid_index_to_grid_coords(
  index : Int,
  layer_width_in_tiles : Int,
  layer_height_in_tiles : Int,
) -> GridCoords? {
  if layer_width_in_tiles <= 0 || layer_height_in_tiles <= 0 || index < 0 {
    return None
  }
  let tile_x = index % layer_width_in_tiles
  let inverted_y = (index - tile_x) / layer_width_in_tiles
  if inverted_y < 0 || inverted_y >= layer_height_in_tiles {
    return None
  }
  Some(
    ldtk_grid_coords_to_grid_coords(
      @math.IVec2::new(tile_x, inverted_y),
      layer_height_in_tiles,
    ),
  )
}

///|
pub fn create_entity_definition_map(
  entity_definitions : Array[EntityDefinition],
) -> @hashmap.HashMap[Int, EntityDefinition] {
  let map : @hashmap.HashMap[Int, EntityDefinition] = @hashmap.HashMap([])
  for definition in entity_definitions {
    map.set(definition.uid, definition)
  }
  map
}

///|
pub fn create_layer_definition_map(
  layer_definitions : Array[LayerDefinition],
) -> @hashmap.HashMap[Int, LayerDefinition] {
  let map : @hashmap.HashMap[Int, LayerDefinition] = @hashmap.HashMap([])
  for definition in layer_definitions {
    map.set(definition.uid, definition)
  }
  map
}

///|
fn ldtk_coord_conversion(coords : @math.IVec2, height : Int) -> @math.IVec2 {
  @math.IVec2::new(coords.x, height - coords.y)
}

///|
fn ldtk_coord_conversion_origin_adjusted(
  coords : @math.IVec2,
  height : Int,
) -> @math.IVec2 {
  @math.IVec2::new(coords.x, height - coords.y - 1)
}

///|
pub fn ldtk_pixel_coords_to_translation(
  ldtk_coords : @math.IVec2,
  ldtk_pixel_height : Int,
) -> @math.Vec2 {
  let converted = ldtk_coord_conversion(ldtk_coords, ldtk_pixel_height)
  @math.Vec2::new(Float::from_int(converted.x), Float::from_int(converted.y))
}

///|
pub fn translation_to_ldtk_pixel_coords(
  translation : @math.Vec2,
  ldtk_pixel_height : Int,
) -> @math.IVec2 {
  ldtk_coord_conversion(
    @math.IVec2::new(translation.x.to_int(), translation.y.to_int()),
    ldtk_pixel_height,
  )
}

///|
pub fn ldtk_grid_coords_to_grid_coords(
  ldtk_coords : @math.IVec2,
  ldtk_grid_height : Int,
) -> GridCoords {
  let converted = ldtk_coord_conversion_origin_adjusted(
    ldtk_coords, ldtk_grid_height,
  )
  GridCoords::new(converted.x, converted.y)
}

///|
pub fn grid_coords_to_ldtk_grid_coords(
  grid_coords : GridCoords,
  ldtk_grid_height : Int,
) -> @math.IVec2 {
  ldtk_coord_conversion_origin_adjusted(
    @math.IVec2::new(grid_coords.x, grid_coords.y),
    ldtk_grid_height,
  )
}

///|
pub fn translation_to_grid_coords(
  translation : @math.Vec2,
  grid_size : @math.IVec2,
) -> GridCoords {
  let width = if grid_size.x <= 0 { 1 } else { grid_size.x }
  let height = if grid_size.y <= 0 { 1 } else { grid_size.y }
  GridCoords::new(
    (translation.x / Float::from_int(width)).to_int(),
    (translation.y / Float::from_int(height)).to_int(),
  )
}

///|
pub fn grid_coords_to_translation_relative_to_tile_layer(
  grid_coords : GridCoords,
  tile_size : @math.IVec2,
) -> @math.Vec2 {
  @math.Vec2::new(
    Float::from_int(grid_coords.x * tile_size.x),
    Float::from_int(grid_coords.y * tile_size.y),
  )
}

///|
pub fn grid_coords_to_translation(
  grid_coords : GridCoords,
  tile_size : @math.IVec2,
) -> @math.Vec2 {
  let relative = grid_coords_to_translation_relative_to_tile_layer(
    grid_coords, tile_size,
  )
  @math.Vec2::new(
    relative.x + Float::from_int(tile_size.x) / 2.0F,
    relative.y + Float::from_int(tile_size.y) / 2.0F,
  )
}

///|
pub fn ldtk_pixel_coords_to_grid_coords(
  ldtk_coords : @math.IVec2,
  ldtk_grid_height : Int,
  grid_size : @math.IVec2,
) -> GridCoords {
  let safe_x = if grid_size.x <= 0 { 1 } else { grid_size.x }
  let safe_y = if grid_size.y <= 0 { 1 } else { grid_size.y }
  ldtk_grid_coords_to_grid_coords(
    @math.IVec2::new(ldtk_coords.x / safe_x, ldtk_coords.y / safe_y),
    ldtk_grid_height,
  )
}

///|
pub fn ldtk_grid_coords_to_translation_relative_to_tile_layer(
  ldtk_coords : @math.IVec2,
  ldtk_grid_height : Int,
  grid_size : @math.IVec2,
) -> @math.Vec2 {
  let px = @math.IVec2::new(
    ldtk_coords.x * grid_size.x,
    ldtk_coords.y * grid_size.y,
  )
  let converted = ldtk_pixel_coords_to_translation(
    px,
    ldtk_grid_height * grid_size.y,
  )
  @math.Vec2::new(converted.x, converted.y - Float::from_int(grid_size.y))
}

///|
pub fn ldtk_grid_coords_to_translation(
  ldtk_coords : @math.IVec2,
  ldtk_grid_height : Int,
  grid_size : @math.IVec2,
) -> @math.Vec2 {
  let relative = ldtk_grid_coords_to_translation_relative_to_tile_layer(
    ldtk_coords, ldtk_grid_height, grid_size,
  )
  @math.Vec2::new(
    relative.x + Float::from_int(grid_size.x) / 2.0F,
    relative.y + Float::from_int(grid_size.y) / 2.0F,
  )
}

///|
pub fn ldtk_pixel_coords_to_translation_pivoted(
  ldtk_coords : @math.IVec2,
  ldtk_pixel_height : Int,
  entity_size : @math.IVec2,
  pivot : @math.Vec2,
) -> @math.Vec2 {
  let pivot_point = ldtk_pixel_coords_to_translation(
    ldtk_coords, ldtk_pixel_height,
  )
  let adjusted_pivot = @math.Vec2::new(0.5F - pivot.x, pivot.y - 0.5F)
  let offset = @math.Vec2::new(
    Float::from_int(entity_size.x) * adjusted_pivot.x,
    Float::from_int(entity_size.y) * adjusted_pivot.y,
  )
  @math.Vec2::new(pivot_point.x + offset.x, pivot_point.y + offset.y)
}

///|
pub fn calculate_transform_from_entity_instance(
  entity_instance : EntityInstance,
  level_height : Int,
) -> @transform.Transform {
  calculate_transform_from_entity_instance_with_entity_definition_map(
    entity_instance,
    @hashmap.HashMap([]),
    level_height,
  )
}

///|
pub fn calculate_transform_from_entity_instance_with_entity_definition_map(
  entity_instance : EntityInstance,
  entity_definition_map : @hashmap.HashMap[Int, EntityDefinition],
  level_height : Int,
) -> @transform.Transform {
  let definition_size = match
    entity_definition_map.get(entity_instance.def_uid) {
    Some(definition) =>
      match definition.tile_rect {
        Some(tile_rect) =>
          @math.IVec2::new(
            if tile_rect.w <= 0 {
              1
            } else {
              tile_rect.w
            },
            if tile_rect.h <= 0 {
              1
            } else {
              tile_rect.h
            },
          )
        None =>
          @math.IVec2::new(
            if definition.width <= 0 {
              1
            } else {
              definition.width
            },
            if definition.height <= 0 {
              1
            } else {
              definition.height
            },
          )
      }
    None =>
      @math.IVec2::new(
        if entity_instance.width <= 0 {
          1
        } else {
          entity_instance.width
        },
        if entity_instance.height <= 0 {
          1
        } else {
          entity_instance.height
        },
      )
  }
  let safe_width = if entity_instance.width <= 0 {
    1
  } else {
    entity_instance.width
  }
  let safe_height = if entity_instance.height <= 0 {
    1
  } else {
    entity_instance.height
  }
  let translation = ldtk_pixel_coords_to_translation_pivoted(
    entity_instance.px,
    level_height,
    @math.IVec2::new(safe_width, safe_height),
    entity_instance.pivot,
  )
  let scale = @math.Vec3::new(
    Float::from_int(safe_width) / Float::from_int(definition_size.x),
    Float::from_int(safe_height) / Float::from_int(definition_size.y),
    1.0F,
  )
  @transform.Transform::from_xyz(translation.x, translation.y, 0.0F).with_scale(
    scale,
  )
}

///|
pub fn tile_to_grid_coords(
  tile_instance : TileInstance,
  layer_height_in_tiles : Int,
  layer_grid_size : Int,
) -> GridCoords {
  let safe_grid_size = if layer_grid_size <= 0 { 1 } else { layer_grid_size }
  ldtk_pixel_coords_to_grid_coords(
    tile_instance.px,
    layer_height_in_tiles,
    @math.IVec2::new(safe_grid_size, safe_grid_size),
  )
}
