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
pub struct EntityIid {
  iid : String
}

///|
pub fn EntityIid::new(iid : String) -> EntityIid {
  EntityIid::{ iid, }
}

///|
pub fn EntityIid::as_str(self : EntityIid) -> String {
  self.iid
}

///|
pub struct LevelIid {
  iid : String
}

///|
pub fn LevelIid::new(iid : String) -> LevelIid {
  LevelIid::{ iid, }
}

///|
pub fn LevelIid::get(self : LevelIid) -> String {
  self.iid
}

///|
pub fn LevelIid::as_str(self : LevelIid) -> String {
  self.iid
}

///|
pub struct LevelSet {
  iids : Array[LevelIid]
}

///|
pub fn LevelSet::new(iids : Array[LevelIid]) -> LevelSet {
  let seen : @hashmap.HashMap[String, Bool] = @hashmap.HashMap([])
  let deduped : Array[LevelIid] = []
  for iid in iids {
    if !seen.contains(iid.get()) {
      seen.set(iid.get(), true)
      deduped.push(iid)
    }
  }
  LevelSet::{ iids: deduped }
}

///|
pub fn LevelSet::default() -> LevelSet {
  LevelSet::{ iids: [] }
}

///|
pub fn LevelSet::from_iids(iids : Array[String]) -> LevelSet {
  let values : Array[LevelIid] = []
  for iid in iids {
    values.push(LevelIid::new(iid))
  }
  LevelSet::new(values)
}

///|
pub fn LevelSet::contains(self : LevelSet, iid : LevelIid) -> Bool {
  for value in self.iids {
    if value.get() == iid.get() {
      return true
    }
  }
  false
}

///|
pub fn LevelSet::iids(self : LevelSet) -> Array[LevelIid] {
  self.iids
}

///|
pub struct IntGridCell {
  value : Int
}

///|
pub fn IntGridCell::new(value : Int) -> IntGridCell {
  IntGridCell::{ value, }
}

///|
pub struct Worldly {
  entity_iid : String
}

///|
pub fn Worldly::new(entity_iid : String) -> Worldly {
  Worldly::{ entity_iid, }
}

///|
pub fn Worldly::from_entity_info(entity_instance : EntityInstance) -> Worldly {
  Worldly::{ entity_iid: entity_instance.iid }
}

///|
pub struct GridCoords {
  x : Int
  y : Int
}

///|
pub fn GridCoords::new(x : Int, y : Int) -> GridCoords {
  GridCoords::{ x, y }
}

///|
pub fn GridCoords::from_entity_info(
  entity_instance : EntityInstance,
  layer_instance : LayerInstance,
) -> GridCoords {
  let converted = ldtk_grid_coords_to_grid_coords(
    entity_instance.grid,
    layer_instance.c_hei,
  )
  GridCoords::new(converted.x, converted.y)
}

///|
pub fn GridCoords::add(self : GridCoords, rhs : GridCoords) -> GridCoords {
  GridCoords::{ x: self.x + rhs.x, y: self.y + rhs.y }
}

///|
pub fn GridCoords::sub(self : GridCoords, rhs : GridCoords) -> GridCoords {
  GridCoords::{ x: self.x - rhs.x, y: self.y - rhs.y }
}

///|
pub fn GridCoords::mul(self : GridCoords, rhs : GridCoords) -> GridCoords {
  GridCoords::{ x: self.x * rhs.x, y: self.y * rhs.y }
}

///|
pub struct TileMetadata {
  data : String
}

///|
pub fn TileMetadata::new(data : String) -> TileMetadata {
  TileMetadata::{ data, }
}

///|
pub struct TileEnumTags {
  tags : Array[String]
  source_enum_uid : Int?
}

///|
pub fn TileEnumTags::new(
  tags : Array[String],
  source_enum_uid : Int?,
) -> TileEnumTags {
  TileEnumTags::{ tags, source_enum_uid }
}

///|
pub struct LayerMetadata {
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
}

///|
pub fn LayerMetadata::from_layer_instance(
  layer_instance : LayerInstance,
) -> LayerMetadata {
  LayerMetadata::{
    c_hei: layer_instance.c_hei,
    c_wid: layer_instance.c_wid,
    grid_size: layer_instance.grid_size,
    identifier: layer_instance.identifier,
    opacity: layer_instance.opacity,
    px_total_offset_x: layer_instance.px_total_offset_x,
    px_total_offset_y: layer_instance.px_total_offset_y,
    tileset_def_uid: layer_instance.tileset_def_uid,
    tileset_rel_path: layer_instance.tileset_rel_path,
    layer_instance_type: layer_instance.layer_instance_type,
    iid: layer_instance.iid,
    layer_def_uid: layer_instance.layer_def_uid,
    level_id: layer_instance.level_id,
    optional_rules: layer_instance.optional_rules,
    override_tileset_uid: layer_instance.override_tileset_uid,
    px_offset_x: layer_instance.px_offset_x,
    px_offset_y: layer_instance.px_offset_y,
    seed: layer_instance.seed,
    visible: layer_instance.visible,
  }
}

///|
pub struct Respawn {}

///|
pub struct LdtkProjectHandle {
  handle : @asset.Handle[LdtkProject]
}

///|
pub fn LdtkProjectHandle::new(
  handle : @asset.Handle[LdtkProject],
) -> LdtkProjectHandle {
  LdtkProjectHandle::{ handle, }
}

///|
pub fn LdtkProjectHandle::id(self : LdtkProjectHandle) -> Int {
  self.handle.id()
}

///|
pub fn LdtkProjectHandle::handle(
  self : LdtkProjectHandle,
) -> @asset.Handle[LdtkProject] {
  self.handle
}

///|
pub struct LdtkWorldBundle {
  ldtk_handle : LdtkProjectHandle
  level_set : LevelSet
  transform : @transform.Transform
  global_transform : @transform.GlobalTransform
  visibility : @visibility.Visibility
  inherited_visibility : @visibility.InheritedVisibility
  view_visibility : @visibility.ViewVisibility
}

///|
pub fn LdtkWorldBundle::new(
  handle : @asset.Handle[LdtkProject],
) -> LdtkWorldBundle {
  let transform = @transform.Transform::identity()
  LdtkWorldBundle::{
    ldtk_handle: LdtkProjectHandle::new(handle),
    level_set: LevelSet::default(),
    transform,
    global_transform: @transform.GlobalTransform::from_transform(transform),
    visibility: @visibility.Visibility::Inherited,
    inherited_visibility: @visibility.InheritedVisibility::new(true),
    view_visibility: @visibility.ViewVisibility::new(true),
  }
}

///|
fn ldtk_world_bundle_insert(
  bundle : LdtkWorldBundle,
  world : @ecs.World,
  entity : @core.Entity,
  loc~ : SourceLoc,
) -> Unit raise @ecs.EcsError {
  world.set_by_key(
    entity,
    ecs_key_ldtk_project_handle,
    bundle.ldtk_handle,
    loc~,
  )
  world.set_by_key(entity, ecs_key_level_set, bundle.level_set, loc~)
  world.set_by_key(entity, @transform.ecs_key_transform, bundle.transform, loc~)
  world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    bundle.global_transform,
    loc~,
  )
  world.set_by_key(
    entity,
    @visibility.ecs_key_visibility,
    bundle.visibility,
    loc~,
  )
  world.set_by_key(
    entity,
    @visibility.ecs_key_inherited_visibility,
    bundle.inherited_visibility,
    loc~,
  )
  world.set_by_key(
    entity,
    @visibility.ecs_key_view_visibility,
    bundle.view_visibility,
    loc~,
  )
}

///|
#callsite(autofill(loc))
pub fn LdtkWorldBundle::spawn(
  self : LdtkWorldBundle,
  world : @ecs.World,
  loc~ : SourceLoc,
) -> @core.Entity {
  try! world.spawn_bundle(self, loc~)
}

///|
pub impl @app.CommandSpawnComponents for LdtkWorldBundle with spawn_components(
  self,
  world,
  entity,
  _sequence,
  loc~,
) {
  ldtk_world_bundle_insert(self, world, entity, loc~)
}

///|
pub impl @ecs.Bundle for LdtkWorldBundle with insert_into(
  self,
  world,
  entity,
  loc~,
) {
  ldtk_world_bundle_insert(self, world, entity, loc~)
}
