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
fn ldtk_crop_value(
  value : Float,
  min_value : Float,
  max_value : Float,
) -> Float {
  if value < min_value {
    return min_value
  }
  if value > max_value {
    return max_value
  }
  value
}

///|
fn ldtk_crop_dimension(value : Float) -> Float {
  if value <= 0.0F {
    return 1.0F
  }
  value
}

///|
fn ldtk_spawn_background_image(
  world : @ecs.World,
  level : Level,
  background_image : @asset.Handle[@asset.Image],
  background_position : LevelBackgroundPosition,
  ldtk_entity : @core.Entity,
  layer_z : Float,
) -> Unit {
  let image_assets_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  guard (try! world.get_resource(image_assets_key)) is Some(image_assets) else {
    return
  }
  guard image_assets.get(background_image) is Some(image) else { return }

  if background_position.crop_rect.length() < 4 {
    return
  }
  let crop_x = ldtk_crop_value(
    background_position.crop_rect[0],
    0.0F,
    image.width.to_float(),
  )
  let crop_y = ldtk_crop_value(
    background_position.crop_rect[1],
    0.0F,
    image.height.to_float(),
  )
  let crop_w = ldtk_crop_dimension(
    ldtk_crop_value(
      background_position.crop_rect[2],
      0.0F,
      image.width.to_float() - crop_x,
    ),
  )
  let crop_h = ldtk_crop_dimension(
    ldtk_crop_value(
      background_position.crop_rect[3],
      0.0F,
      image.height.to_float() - crop_y,
    ),
  )

  let layout = @asset.TextureAtlasLayout::new_empty(
    @math.UVec2::new(image.width, image.height),
  )
  let atlas_index = layout.add_texture(
    @math.URect::new(
      @math.UVec2::new(crop_x.to_int(), crop_y.to_int()),
      @math.UVec2::new((crop_x + crop_w).to_int(), (crop_y + crop_h).to_int()),
    ),
  )
  let atlas_layout = @asset.asset_add_texture_atlas_layout(layout)
  let atlas = @asset.TextureAtlas::new(atlas_layout, atlas_index)
  let sprite = @sprite.Sprite::from_atlas_image(background_image, atlas)

  let scaled_w = crop_w * background_position.scale.x
  let scaled_h = crop_h * background_position.scale.y
  let top_left = ldtk_pixel_coords_to_translation(
    background_position.top_left_px,
    level.px_hei,
  )
  let center = @math.Vec2::new(
    top_left.x + scaled_w * 0.5F,
    top_left.y - scaled_h * 0.5F,
  )
  let transform = @transform.Transform::from_xyz(center.x, center.y, layer_z).with_scale(
    @math.Vec3::new(
      background_position.scale.x,
      background_position.scale.y,
      1.0F,
    ),
  )
  let entity = @sprite.SpriteBundle::new(sprite, transform).spawn(world)
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ldtk_entity),
  )
}

///|
fn ldtk_spawn_level_background(
  world : @ecs.World,
  level : Level,
  ldtk_entity : @core.Entity,
  layer_z : Float,
) -> Unit {
  let size = @math.Vec2::new(level.px_wid.to_float(), level.px_hei.to_float())
  let translation = @transform.Transform::from_xyz(
    level.px_wid.to_float() * 0.5F,
    level.px_hei.to_float() * 0.5F,
    layer_z,
  )
  let sprite = @sprite.Sprite::sized(size).with_color(level.bg_color)
  let background = @sprite.SpriteBundle::new(sprite, translation).spawn(world)
  try! world.set_by_key(
    background,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ldtk_entity),
  )
}

///|
fn ldtk_spawn_layer_entity(
  world : @ecs.World,
  layer_instance : LayerInstance,
  ldtk_entity : @core.Entity,
  layer_z : Float,
) -> @core.Entity {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(
      layer_instance.px_total_offset_x.to_float(),
      -layer_instance.px_total_offset_y.to_float(),
      layer_z,
    ),
  )
  try! world.set_by_key(
    entity,
    @visibility.ecs_key_visibility,
    @visibility.Visibility::Inherited,
  )
  try! world.set_by_key(
    entity,
    ecs_key_layer_metadata,
    LayerMetadata::from_layer_instance(layer_instance),
  )
  try! world.set_by_key(
    entity,
    @ecs.ecs_key_name,
    @ecs.Name::new(layer_instance.identifier),
  )
  try! world.set_by_key(
    entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(ldtk_entity),
  )
  entity
}

///|
fn ldtk_flip_x(flags : Int) -> Bool {
  (flags & 1) == 1
}

///|
fn ldtk_flip_y(flags : Int) -> Bool {
  (flags & 2) == 2
}

///|
fn ldtk_tile_sprite(
  tile : TileInstance,
  layer_instance : LayerInstance,
  tileset : @asset.Handle[@asset.Image]?,
) -> @sprite.Sprite {
  let tile_size = if layer_instance.grid_size <= 0 {
    1
  } else {
    layer_instance.grid_size
  }
  let base = match tileset {
    Some(handle) => @sprite.Sprite::from_image(handle)
    None =>
      @sprite.Sprite::sized(
        @math.Vec2::new(tile_size.to_float(), tile_size.to_float()),
      )
  }
  let rect = @math.Rect::new(
    @math.Vec2::new(tile.src.x.to_float(), tile.src.y.to_float()),
    @math.Vec2::new(
      tile.src.x.to_float() + tile_size.to_float(),
      tile.src.y.to_float() + tile_size.to_float(),
    ),
  )
  base
  .with_rect(Some(rect))
  .with_custom_size(
    Some(@math.Vec2::new(tile_size.to_float(), tile_size.to_float())),
  )
  .with_flip_x(ldtk_flip_x(tile.f))
  .with_flip_y(ldtk_flip_y(tile.f))
}

///|
fn ldtk_insert_tile_metadata(
  world : @ecs.World,
  tile_entity : @core.Entity,
  tile : TileInstance,
  tileset_definition : TilesetDefinition?,
) -> Unit {
  guard tileset_definition is Some(definition) else { return }
  if definition.custom_data_by_tile.get(tile.t) is Some(data) {
    try! world.set_by_key(
      tile_entity,
      ecs_key_tile_metadata,
      TileMetadata::new(data),
    )
  }
  if definition.enum_tags_by_tile.get(tile.t) is Some(tags) {
    try! world.set_by_key(
      tile_entity,
      ecs_key_tile_enum_tags,
      TileEnumTags::new(tags.tags, tags.source_enum_uid),
    )
  }
}

///|
fn ldtk_spawn_tile_entities(
  world : @ecs.World,
  layer_entity : @core.Entity,
  layer_instance : LayerInstance,
  tiles : Array[TileInstance],
  tileset : @asset.Handle[@asset.Image]?,
  tileset_definition : TilesetDefinition?,
  z_offset : Float,
) -> Unit {
  let safe_grid_size = if layer_instance.grid_size <= 0 {
    1
  } else {
    layer_instance.grid_size
  }
  for tile in tiles {
    if !tile_in_layer_bounds(tile, layer_instance) {
      continue
    }
    let grid_coords = tile_to_grid_coords(
      tile,
      layer_instance.c_hei,
      safe_grid_size,
    )
    let translation = grid_coords_to_translation_relative_to_tile_layer(
      grid_coords,
      @math.IVec2::new(safe_grid_size, safe_grid_size),
    )
    let sprite = ldtk_tile_sprite(tile, layer_instance, tileset)
    let tile_entity = @sprite.SpriteBundle::new(
      sprite,
      @transform.Transform::from_xyz(translation.x, translation.y, z_offset),
    ).spawn(world)
    try! world.set_by_key(tile_entity, ecs_key_grid_coords, grid_coords)
    try! world.set_by_key(
      tile_entity,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(layer_entity),
    )
    ldtk_insert_tile_metadata(world, tile_entity, tile, tileset_definition)
  }
}

///|
fn ldtk_int_grid_color(
  layer_definition_map : @hashmap.HashMap[Int, LayerDefinition],
  layer_instance : LayerInstance,
  value : Int,
) -> @sprite.Color {
  guard layer_definition_map.get(layer_instance.layer_def_uid)
    is Some(layer_definition) else {
    return @sprite.Color::white()
  }
  for definition in layer_definition.int_grid_values {
    if definition.value == value {
      return definition.color
    }
  }
  @sprite.Color::white()
}

///|
fn ldtk_spawn_int_grid_entities(
  world : @ecs.World,
  layer_entity : @core.Entity,
  layer_instance : LayerInstance,
  ldtk_settings : LdtkSettings,
  layer_definition_map : @hashmap.HashMap[Int, LayerDefinition],
  int_grid_image_handle : @asset.Handle[@asset.Image]?,
) -> Unit {
  let safe_grid_size = if layer_instance.grid_size <= 0 {
    1
  } else {
    layer_instance.grid_size
  }
  for index, value in layer_instance.int_grid_csv {
    if value == 0 {
      continue
    }
    guard int_grid_index_to_grid_coords(
        index,
        layer_instance.c_wid,
        layer_instance.c_hei,
      )
      is Some(grid_coords) else {
      continue
    }
    let translation = grid_coords_to_translation_relative_to_tile_layer(
      grid_coords,
      @math.IVec2::new(safe_grid_size, safe_grid_size),
    )
    let entity = world.spawn_empty()
    try! world.set_by_key(
      entity,
      @transform.ecs_key_transform,
      @transform.Transform::from_xyz(translation.x, translation.y, 0.0F),
    )
    try! world.set_by_key(entity, ecs_key_grid_coords, grid_coords)
    try! world.set_by_key(
      entity,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(layer_entity),
    )
    let int_grid_cell = IntGridCell::new(value)
    let dispatcher = ldtk_int_cell_dispatcher_for(
      world,
      layer_instance.identifier,
      value,
    )
    dispatcher(world, entity, int_grid_cell, layer_instance)
    match ldtk_settings.int_grid_rendering {
      IntGridRendering::Colorful => {
        let sprite = match int_grid_image_handle {
          Some(image_handle) =>
            @sprite.Sprite::from_image(image_handle)
            .with_custom_size(
              Some(
                @math.Vec2::new(
                  safe_grid_size.to_float(),
                  safe_grid_size.to_float(),
                ),
              ),
            )
            .with_color(
              ldtk_int_grid_color(layer_definition_map, layer_instance, value),
            )
          None =>
            @sprite.Sprite::sized(
              @math.Vec2::new(
                safe_grid_size.to_float(),
                safe_grid_size.to_float(),
              ),
            ).with_color(
              ldtk_int_grid_color(layer_definition_map, layer_instance, value),
            )
        }
        let sprite_entity = @sprite.SpriteBundle::new(
          sprite,
          @transform.Transform::identity(),
        ).spawn(world)
        try! world.set_by_key(
          sprite_entity,
          @hierarchy.ecs_key_parent,
          @hierarchy.Parent::new(entity),
        )
      }
      IntGridRendering::Invisible => ()
    }
  }
}

///|
fn ldtk_spawn_layer_entities(
  world : @ecs.World,
  level : Level,
  layer_entity : @core.Entity,
  layer_instance : LayerInstance,
  asset_server : @asset.AssetServer,
  tileset_map : @hashmap.HashMap[Int, @asset.Handle[@asset.Image]],
  entity_definition_map : @hashmap.HashMap[Int, EntityDefinition],
  tileset_definition_map : @hashmap.HashMap[Int, TilesetDefinition],
  _int_grid_image_handle : @asset.Handle[@asset.Image]?,
  ldtk_settings : LdtkSettings,
) -> Unit {
  for entity_instance in layer_instance.entity_instances {
    let entity = world.spawn_empty()
    try! world.set_by_key(
      entity,
      ecs_key_entity_iid,
      EntityIid::new(entity_instance.iid),
    )
    try! world.set_by_key(
      entity,
      @ecs.ecs_key_name,
      @ecs.Name::new(entity_instance.identifier),
    )
    try! world.set_by_key(
      entity,
      @transform.ecs_key_transform,
      calculate_transform_from_entity_instance_with_entity_definition_map(
        entity_instance,
        entity_definition_map,
        level.px_hei,
      ),
    )
    try! world.set_by_key(
      entity,
      @visibility.ecs_key_visibility,
      @visibility.Visibility::Inherited,
    )
    try! world.set_by_key(
      entity,
      @hierarchy.ecs_key_parent,
      @hierarchy.Parent::new(layer_entity),
    )
    let tileset = match entity_instance.tile {
      Some(tile) => tileset_map.get(tile.tileset_uid)
      None => None
    }
    let tileset_definition = match entity_instance.tile {
      Some(tile) => tileset_definition_map.get(tile.tileset_uid)
      None => None
    }
    let dispatcher = ldtk_entity_dispatcher_for(
      world,
      layer_instance.identifier,
      entity_instance.identifier,
    )
    dispatcher(
      world, entity, entity_instance, layer_instance, tileset, tileset_definition,
      asset_server,
    )
  }
  ldtk_settings |> ignore
}

///|
pub fn spawn_level(
  level : Level,
  background_image : @asset.Handle[@asset.Image]?,
  world : @ecs.World,
  asset_server : @asset.AssetServer,
  tileset_map : @hashmap.HashMap[Int, @asset.Handle[@asset.Image]],
  int_grid_image_handle : @asset.Handle[@asset.Image]?,
  ldtk_entity : @core.Entity,
  ldtk_settings : LdtkSettings,
  entity_definition_map : @hashmap.HashMap[Int, EntityDefinition],
  layer_definition_map : @hashmap.HashMap[Int, LayerDefinition],
  tileset_definition_map : @hashmap.HashMap[Int, TilesetDefinition],
) -> Unit {
  let mut layer_z : Float = 0.0F
  match ldtk_settings.level_background {
    LevelBackground::Rendered => {
      ldtk_spawn_level_background(world, level, ldtk_entity, layer_z)
      layer_z = layer_z + 1.0F
      match (background_image, level.bg_pos) {
        (Some(handle), Some(background_position)) => {
          ldtk_spawn_background_image(
            world, level, handle, background_position, ldtk_entity, layer_z,
          )
          layer_z = layer_z + 1.0F
        }
        _ => ()
      }
    }
    LevelBackground::Nonexistent => ()
  }
  guard level.layer_instances is Some(layer_instances) else { return }
  for reverse_index in 0..<layer_instances.length() {
    let layer_instance = layer_instances[layer_instances.length() -
      1 -
      reverse_index]
    if ldtk_settings.exclusions.layer_identifiers.contains(
        layer_instance.identifier,
      ) {
      continue
    }
    let layer_entity = ldtk_spawn_layer_entity(
      world, layer_instance, ldtk_entity, layer_z,
    )
    match layer_instance.layer_instance_type {
      Type::Entities =>
        ldtk_spawn_layer_entities(
          world, level, layer_entity, layer_instance, asset_server, tileset_map,
          entity_definition_map, tileset_definition_map, int_grid_image_handle, ldtk_settings,
        )
      Type::IntGrid =>
        ldtk_spawn_int_grid_entities(
          world, layer_entity, layer_instance, ldtk_settings, layer_definition_map,
          int_grid_image_handle,
        )
      Type::Tiles =>
        for
          sublayer_index, sublayer_tiles in layer_grid_tiles(
            layer_instance.grid_tiles,
          ) {
          ldtk_spawn_tile_entities(
            world,
            layer_entity,
            layer_instance,
            sublayer_tiles,
            match layer_instance.tileset_def_uid {
              Some(uid) => tileset_map.get(uid)
              None => None
            },
            match layer_instance.tileset_def_uid {
              Some(uid) => tileset_definition_map.get(uid)
              None => None
            },
            sublayer_index.to_float(),
          )
        }
      Type::AutoLayer =>
        for
          sublayer_index, sublayer_tiles in layer_grid_tiles(
            layer_instance.auto_layer_tiles,
          ) {
          ldtk_spawn_tile_entities(
            world,
            layer_entity,
            layer_instance,
            sublayer_tiles,
            match layer_instance.tileset_def_uid {
              Some(uid) => tileset_map.get(uid)
              None => None
            },
            match layer_instance.tileset_def_uid {
              Some(uid) => tileset_definition_map.get(uid)
              None => None
            },
            sublayer_index.to_float(),
          )
        }
    }
    layer_z = layer_z + 1.0F
  }
}
