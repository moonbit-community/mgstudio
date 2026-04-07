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
pub(all) enum LevelSelection {
  Identifier(String)
  Indices(LevelIndices)
  Iid(LevelIid)
  Uid(Int)
}

///|
pub fn LevelSelection::default() -> LevelSelection {
  LevelSelection::index(0)
}

///|
pub fn LevelSelection::iid(iid : String) -> LevelSelection {
  Iid(LevelIid::new(iid))
}

///|
pub fn LevelSelection::index(level_index : Int) -> LevelSelection {
  Indices(LevelIndices::in_root(level_index))
}

///|
pub fn LevelSelection::indices(
  world_index : Int,
  level_index : Int,
) -> LevelSelection {
  Indices(LevelIndices::in_world(world_index, level_index))
}

///|
pub fn LevelSelection::is_match(
  self : LevelSelection,
  indices : LevelIndices,
  level : Level,
) -> Bool {
  match self {
    Identifier(identifier) => identifier == level.identifier
    Indices(selected_indices) =>
      selected_indices.world == indices.world &&
      selected_indices.level == indices.level
    Iid(level_iid) => level_iid.get() == level.iid
    Uid(uid) => uid == level.uid
  }
}

///|
pub(all) enum LevelEvent {
  SpawnTriggered(LevelIid)
  Spawned(LevelIid)
  Transformed(LevelIid)
  Despawned(LevelIid)
}

///|
let ldtk_level_selection_key : @ecs.ResourceKey[LevelSelection] = @ecs.register_resource(
  debug_name="bevy_ecs_ldtk.LevelSelection",
)

///|
let ldtk_settings_key : @ecs.ResourceKey[LdtkSettings] = @ecs.register_resource(
  debug_name="bevy_ecs_ldtk.LdtkSettings",
)

///|
let ldtk_runtime_state_key : @ecs.ResourceKey[LdtkRuntimeState] = @ecs.register_resource(
  debug_name="bevy_ecs_ldtk.LdtkRuntimeState",
)

///|
let ldtk_spawned_level_iids_key : @ecs.ResourceKey[LdtkSpawnedLevelIids] = @ecs.register_resource(
  debug_name="bevy_ecs_ldtk.LdtkSpawnedLevelIids",
)

///|
pub let ldtk_level_event_key : @ecs.MessageKey[LevelEvent] = @ecs.register_message(
  debug_name="bevy_ecs_ldtk.LevelEvent",
)

///|
pub impl @app.Resource for LevelSelection with resource() {
  ldtk_level_selection_key
}

///|
pub impl @app.Resource for LdtkSettings with resource() {
  ldtk_settings_key
}

///|
pub impl @app.Resource for LdtkRuntimeState with resource() {
  ldtk_runtime_state_key
}

///|
pub impl @app.Resource for LdtkSpawnedLevelIids with resource() {
  ldtk_spawned_level_iids_key
}

///|
pub impl @ecs.Message for LevelEvent with message() {
  ldtk_level_event_key
}

///|
pub(all) enum SetClearColor {
  No
  FromLevelBackground
  FromEditorBackground
}

///|
pub fn SetClearColor::default() -> SetClearColor {
  SetClearColor::No
}

///|
pub(all) enum LevelSpawnBehavior {
  UseZeroTranslation
  UseWorldTranslation(Bool)
}

///|
pub fn LevelSpawnBehavior::default() -> LevelSpawnBehavior {
  LevelSpawnBehavior::UseZeroTranslation
}

///|
pub(all) enum IntGridRendering {
  Colorful
  Invisible
}

///|
pub fn IntGridRendering::default() -> IntGridRendering {
  IntGridRendering::Colorful
}

///|
pub(all) enum LevelBackground {
  Rendered
  Nonexistent
}

///|
pub fn LevelBackground::default() -> LevelBackground {
  LevelBackground::Rendered
}

///|
pub struct SpawnExclusions {
  layer_identifiers : Array[String]
}

///|
pub fn SpawnExclusions::default() -> SpawnExclusions {
  SpawnExclusions::{ layer_identifiers: [] }
}

///|
pub struct LdtkSettings {
  level_spawn_behavior : LevelSpawnBehavior
  set_clear_color : SetClearColor
  int_grid_rendering : IntGridRendering
  level_background : LevelBackground
  exclusions : SpawnExclusions
}

///|
pub fn LdtkSettings::default() -> LdtkSettings {
  LdtkSettings::{
    level_spawn_behavior: LevelSpawnBehavior::default(),
    set_clear_color: SetClearColor::default(),
    int_grid_rendering: IntGridRendering::default(),
    level_background: LevelBackground::default(),
    exclusions: SpawnExclusions::default(),
  }
}

///|
pub struct LdtkRuntimeState {
  spawned_levels_by_world : @hashmap.HashMap[
    String,
    @hashmap.HashMap[String, @core.Entity],
  ]
}

///|
pub fn LdtkRuntimeState::default() -> LdtkRuntimeState {
  LdtkRuntimeState::{ spawned_levels_by_world: @hashmap.HashMap::new() }
}

///|
pub struct LdtkSpawnedLevelIids {
  iids : Array[LevelIid]
}

///|
pub fn LdtkSpawnedLevelIids::default() -> LdtkSpawnedLevelIids {
  LdtkSpawnedLevelIids::{ iids: [] }
}

///|
pub fn LdtkSpawnedLevelIids::iids(
  self : LdtkSpawnedLevelIids,
) -> Array[LevelIid] {
  self.iids
}

///|
fn ldtk_entity_key(entity : @core.Entity) -> String {
  "\{entity.id.to_string()}:\{entity.generation.to_string()}"
}

///|
pub fn LdtkRuntimeState::world_spawned_levels(
  self : LdtkRuntimeState,
  world_entity : @core.Entity,
) -> @hashmap.HashMap[String, @core.Entity] {
  self.spawned_levels_by_world.get_or_init(ldtk_entity_key(world_entity), fn() {
    @hashmap.HashMap::new()
  })
}

///|
pub fn LdtkRuntimeState::remove_world(
  self : LdtkRuntimeState,
  world_entity : @core.Entity,
) -> Unit {
  self.spawned_levels_by_world.remove(ldtk_entity_key(world_entity))
}

///|
pub fn ldtk_send_level_event(world : @ecs.World, event : LevelEvent) -> Unit {
  ignore(world.send_message(ldtk_level_event_key, event))
}
