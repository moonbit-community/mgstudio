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
pub type LdtkEntityDispatcher = (
  @ecs.World,
  @core.Entity,
  EntityInstance,
  LayerInstance,
  @asset.Handle[@asset.Image]?,
  TilesetDefinition?,
  @asset.AssetServer,
) -> Unit

///|
pub type LdtkIntCellDispatcher = (
  @ecs.World,
  @core.Entity,
  IntGridCell,
  LayerInstance,
) -> Unit

///|
pub struct LdtkEntityMap {
  entries : @hashmap.HashMap[(String?, String?), LdtkEntityDispatcher]
}

///|
pub fn LdtkEntityMap::default() -> LdtkEntityMap {
  LdtkEntityMap::{ entries: @hashmap.HashMap::new() }
}

///|
pub struct LdtkIntCellMap {
  entries : @hashmap.HashMap[(String?, Int?), LdtkIntCellDispatcher]
}

///|
pub fn LdtkIntCellMap::default() -> LdtkIntCellMap {
  LdtkIntCellMap::{ entries: @hashmap.HashMap::new() }
}

///|
let ldtk_entity_map_key : @ecs.ResourceKey[LdtkEntityMap] = @ecs.register_resource(
  debug_name="bevy_ecs_ldtk.LdtkEntityMap",
)

///|
let ldtk_int_cell_map_key : @ecs.ResourceKey[LdtkIntCellMap] = @ecs.register_resource(
  debug_name="bevy_ecs_ldtk.LdtkIntCellMap",
)

///|
pub impl @app.Resource for LdtkEntityMap with resource() {
  ldtk_entity_map_key
}

///|
pub impl @app.Resource for LdtkIntCellMap with resource() {
  ldtk_int_cell_map_key
}

///|
fn ldtk_ensure_entity_map(world : @ecs.World) -> Ref[LdtkEntityMap] {
  if (try! world.get_resource(ldtk_entity_map_key)) is None {
    world.insert_resource(ldtk_entity_map_key, LdtkEntityMap::default())
  }
  match (try! world.get_resource_ref_mut(ldtk_entity_map_key)) {
    Some(value) => value
    None => abort("Failed to access LdtkEntityMap resource")
  }
}

///|
fn ldtk_ensure_int_cell_map(world : @ecs.World) -> Ref[LdtkIntCellMap] {
  if (try! world.get_resource(ldtk_int_cell_map_key)) is None {
    world.insert_resource(ldtk_int_cell_map_key, LdtkIntCellMap::default())
  }
  match (try! world.get_resource_ref_mut(ldtk_int_cell_map_key)) {
    Some(value) => value
    None => abort("Failed to access LdtkIntCellMap resource")
  }
}

///|
pub fn register_ldtk_entity_for_layer_optional(
  app : @app.App[@ecs.World],
  layer_identifier : String?,
  entity_identifier : String?,
  dispatcher : LdtkEntityDispatcher,
) -> @app.App[@ecs.World] {
  let world = app.world()
  ldtk_ensure_entity_map(world).val.entries.set(
    (layer_identifier, entity_identifier),
    dispatcher,
  )
  app
}

///|
pub fn register_ldtk_entity_for_layer(
  app : @app.App[@ecs.World],
  layer_identifier : String,
  entity_identifier : String,
  dispatcher : LdtkEntityDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_entity_for_layer_optional(
    app,
    Some(layer_identifier),
    Some(entity_identifier),
    dispatcher,
  )
}

///|
pub fn register_ldtk_entity(
  app : @app.App[@ecs.World],
  entity_identifier : String,
  dispatcher : LdtkEntityDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_entity_for_layer_optional(
    app,
    None,
    Some(entity_identifier),
    dispatcher,
  )
}

///|
pub fn register_default_ldtk_entity_for_layer(
  app : @app.App[@ecs.World],
  layer_identifier : String,
  dispatcher : LdtkEntityDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_entity_for_layer_optional(
    app,
    Some(layer_identifier),
    None,
    dispatcher,
  )
}

///|
pub fn register_default_ldtk_entity(
  app : @app.App[@ecs.World],
  dispatcher : LdtkEntityDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_entity_for_layer_optional(app, None, None, dispatcher)
}

///|
pub fn register_ldtk_int_cell_for_layer_optional(
  app : @app.App[@ecs.World],
  layer_identifier : String?,
  value : Int?,
  dispatcher : LdtkIntCellDispatcher,
) -> @app.App[@ecs.World] {
  let world = app.world()
  ldtk_ensure_int_cell_map(world).val.entries.set(
    (layer_identifier, value),
    dispatcher,
  )
  app
}

///|
pub fn register_ldtk_int_cell_for_layer(
  app : @app.App[@ecs.World],
  layer_identifier : String,
  value : Int,
  dispatcher : LdtkIntCellDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_int_cell_for_layer_optional(
    app,
    Some(layer_identifier),
    Some(value),
    dispatcher,
  )
}

///|
pub fn register_ldtk_int_cell(
  app : @app.App[@ecs.World],
  value : Int,
  dispatcher : LdtkIntCellDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_int_cell_for_layer_optional(app, None, Some(value), dispatcher)
}

///|
pub fn register_default_ldtk_int_cell_for_layer(
  app : @app.App[@ecs.World],
  layer_identifier : String,
  dispatcher : LdtkIntCellDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_int_cell_for_layer_optional(
    app,
    Some(layer_identifier),
    None,
    dispatcher,
  )
}

///|
pub fn register_default_ldtk_int_cell(
  app : @app.App[@ecs.World],
  dispatcher : LdtkIntCellDispatcher,
) -> @app.App[@ecs.World] {
  register_ldtk_int_cell_for_layer_optional(app, None, None, dispatcher)
}

///|
pub fn ldtk_entity_map_default_dispatch(
  world : @ecs.World,
  entity : @core.Entity,
  entity_instance : EntityInstance,
  _layer_instance : LayerInstance,
  _tileset : @asset.Handle[@asset.Image]?,
  _tileset_definition : TilesetDefinition?,
  _asset_server : @asset.AssetServer,
) -> Unit {
  try! world.set_by_key(
    entity,
    ecs_key_entity_iid,
    EntityIid::new(entity_instance.iid),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::identity(),
  )
}

///|
pub fn ldtk_int_cell_map_default_dispatch(
  world : @ecs.World,
  entity : @core.Entity,
  cell : IntGridCell,
  _layer_instance : LayerInstance,
) -> Unit {
  try! world.set_by_key(entity, ecs_key_int_grid_cell, cell)
}

///|
fn[A : Hash + Eq, B : Hash + Eq] ldtk_try_each_optional_permutation(
  a : A,
  b : B,
  map : @hashmap.HashMap[(A?, B?), LdtkEntityDispatcher],
) -> LdtkEntityDispatcher? {
  match map.get((Some(a), Some(b))) {
    Some(value) => Some(value)
    None =>
      match map.get((None, Some(b))) {
        Some(value) => Some(value)
        None =>
          match map.get((Some(a), None)) {
            Some(value) => Some(value)
            None => map.get((None, None))
          }
      }
  }
}

///|
fn ldtk_try_each_optional_permutation_int(
  layer_identifier : String,
  value : Int,
  map : @hashmap.HashMap[(String?, Int?), LdtkIntCellDispatcher],
) -> LdtkIntCellDispatcher? {
  match map.get((Some(layer_identifier), Some(value))) {
    Some(dispatcher) => Some(dispatcher)
    None =>
      match map.get((None, Some(value))) {
        Some(dispatcher) => Some(dispatcher)
        None =>
          match map.get((Some(layer_identifier), None)) {
            Some(dispatcher) => Some(dispatcher)
            None => map.get((None, None))
          }
      }
  }
}

///|
pub fn ldtk_entity_dispatcher_for(
  world : @ecs.World,
  layer_identifier : String,
  entity_identifier : String,
) -> LdtkEntityDispatcher {
  guard (try! world.get_resource(ldtk_entity_map_key)) is Some(map) else {
    return ldtk_entity_map_default_dispatch
  }
  match
    ldtk_try_each_optional_permutation(
      layer_identifier,
      entity_identifier,
      map.entries,
    ) {
    Some(dispatcher) => dispatcher
    None => ldtk_entity_map_default_dispatch
  }
}

///|
pub fn ldtk_int_cell_dispatcher_for(
  world : @ecs.World,
  layer_identifier : String,
  value : Int,
) -> LdtkIntCellDispatcher {
  guard (try! world.get_resource(ldtk_int_cell_map_key)) is Some(map) else {
    return ldtk_int_cell_map_default_dispatch
  }
  match
    ldtk_try_each_optional_permutation_int(layer_identifier, value, map.entries) {
    Some(dispatcher) => dispatcher
    None => ldtk_int_cell_map_default_dispatch
  }
}
