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
pub let ecs_key_entity_iid : @ecs.ComponentKey[EntityIid] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.entity_iid",
)

///|
pub let ecs_key_level_iid : @ecs.ComponentKey[LevelIid] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.level_iid",
)

///|
pub let ecs_key_level_set : @ecs.ComponentKey[LevelSet] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.level_set",
)

///|
pub let ecs_key_int_grid_cell : @ecs.ComponentKey[IntGridCell] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.int_grid_cell",
)

///|
pub let ecs_key_worldly : @ecs.ComponentKey[Worldly] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.worldly",
)

///|
pub let ecs_key_grid_coords : @ecs.ComponentKey[GridCoords] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.grid_coords",
)

///|
pub let ecs_key_tile_metadata : @ecs.ComponentKey[TileMetadata] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.tile_metadata",
)

///|
pub let ecs_key_tile_enum_tags : @ecs.ComponentKey[TileEnumTags] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.tile_enum_tags",
)

///|
pub let ecs_key_layer_metadata : @ecs.ComponentKey[LayerMetadata] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.layer_metadata",
)

///|
pub let ecs_key_respawn : @ecs.ComponentKey[Respawn] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.respawn",
)

///|
pub let ecs_key_ldtk_project_handle : @ecs.ComponentKey[LdtkProjectHandle] = @ecs.register_component(
  debug_name="mgstudio_ecs_ldtk.ldtk_project_handle",
)

///|
pub impl @ecs.Component for EntityIid with component() {
  ecs_key_entity_iid
}

///|
pub impl @ecs.Component for LevelIid with component() {
  ecs_key_level_iid
}

///|
pub impl @ecs.Component for LevelSet with component() {
  ecs_key_level_set
}

///|
pub impl @ecs.Component for IntGridCell with component() {
  ecs_key_int_grid_cell
}

///|
pub impl @ecs.Component for Worldly with component() {
  ecs_key_worldly
}

///|
pub impl @ecs.Component for GridCoords with component() {
  ecs_key_grid_coords
}

///|
pub impl @ecs.Component for TileMetadata with component() {
  ecs_key_tile_metadata
}

///|
pub impl @ecs.Component for TileEnumTags with component() {
  ecs_key_tile_enum_tags
}

///|
pub impl @ecs.Component for LayerMetadata with component() {
  ecs_key_layer_metadata
}

///|
pub impl @ecs.Component for Respawn with component() {
  ecs_key_respawn
}

///|
pub impl @ecs.Component for LdtkProjectHandle with component() {
  ecs_key_ldtk_project_handle
}
