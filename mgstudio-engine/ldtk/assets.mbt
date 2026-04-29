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
pub struct LevelIndices {
  world : Int?
  level : Int
}

///|
pub fn LevelIndices::in_world(
  world_index : Int,
  level_index : Int,
) -> LevelIndices {
  LevelIndices::{ world: Some(world_index), level: level_index }
}

///|
pub fn LevelIndices::in_root(index : Int) -> LevelIndices {
  LevelIndices::{ world: None, level: index }
}

///|
pub struct LevelMetadata {
  bg_image : @asset.Handle[@asset.Image]?
  indices : LevelIndices
}

///|
pub fn LevelMetadata::new(
  bg_image : @asset.Handle[@asset.Image]?,
  indices : LevelIndices,
) -> LevelMetadata {
  LevelMetadata::{ bg_image, indices }
}

///|
pub struct ExternalLevelMetadata {
  metadata : LevelMetadata
  external_handle : @asset.Handle[@asset.Blob]
}

///|
pub fn ExternalLevelMetadata::new(
  metadata : LevelMetadata,
  external_handle : @asset.Handle[@asset.Blob],
) -> ExternalLevelMetadata {
  ExternalLevelMetadata::{ metadata, external_handle }
}

///|
pub struct LdtkProject {
  data : LdtkJson
  level_map : @hashmap.HashMap[String, LevelMetadata]
  tileset_map : @hashmap.HashMap[Int, @asset.Handle[@asset.Image]]
  int_grid_image_handle : @asset.Handle[@asset.Image]?
  external_level_blob_handles : @hashmap.HashMap[
    String,
    @asset.Handle[@asset.Blob],
  ]
}

///|
pub fn LdtkProject::new(
  data : LdtkJson,
  level_map : @hashmap.HashMap[String, LevelMetadata],
  tileset_map : @hashmap.HashMap[Int, @asset.Handle[@asset.Image]],
  int_grid_image_handle : @asset.Handle[@asset.Image]?,
  external_level_blob_handles : @hashmap.HashMap[
    String,
    @asset.Handle[@asset.Blob],
  ],
) -> LdtkProject {
  LdtkProject::{
    data,
    level_map,
    tileset_map,
    int_grid_image_handle,
    external_level_blob_handles,
  }
}

///|
pub fn LdtkProject::json_data(self : LdtkProject) -> LdtkJson {
  self.data
}

///|
pub fn LdtkProject::project_data(self : LdtkProject) -> LdtkProjectData {
  LdtkProjectData::from_project(self)
}

///|
pub fn LdtkProject::as_standalone(self : LdtkProject) -> LdtkJsonWithMetadata {
  self.project_data().as_standalone()
}

///|
pub fn LdtkProject::as_parent(self : LdtkProject) -> LdtkJsonWithMetadata {
  self.project_data().as_parent()
}

///|
pub fn LdtkProject::tileset_map(
  self : LdtkProject,
) -> @hashmap.HashMap[Int, @asset.Handle[@asset.Image]] {
  self.tileset_map
}

///|
pub fn LdtkProject::int_grid_image_handle(
  self : LdtkProject,
) -> @asset.Handle[@asset.Image]? {
  self.int_grid_image_handle
}

///|
pub fn LdtkProject::get_level_metadata_by_iid(
  self : LdtkProject,
  iid : String,
) -> LevelMetadata? {
  self.level_map.get(iid)
}

///|
pub fn LdtkProject::root_levels(self : LdtkProject) -> Array[Level] {
  self.data.levels
}

///|
pub fn LdtkProject::worlds(self : LdtkProject) -> Array[World] {
  self.data.worlds
}

///|
pub fn LdtkProject::get_raw_level_at_indices(
  self : LdtkProject,
  indices : LevelIndices,
) -> Level? {
  match indices.world {
    Some(world_index) =>
      if world_index >= 0 &&
        world_index < self.data.worlds.length() &&
        indices.level >= 0 &&
        indices.level < self.data.worlds[world_index].levels.length() {
        Some(self.data.worlds[world_index].levels[indices.level])
      } else {
        None
      }
    None =>
      if indices.level >= 0 && indices.level < self.data.levels.length() {
        Some(self.data.levels[indices.level])
      } else {
        None
      }
  }
}

///|
pub fn LdtkProject::get_raw_level_by_iid(
  self : LdtkProject,
  iid : String,
) -> Level? {
  match self.level_map.get(iid) {
    Some(metadata) => self.get_raw_level_at_indices(metadata.indices)
    None => None
  }
}

///|
fn ldtk_level_loaded(level : Level) -> Bool {
  level.layer_instances is Some(_)
}

///|
fn ldtk_level_from_blob(blob : @asset.Handle[@asset.Blob]) -> Level {
  match @asset.asset_blob_read_text(blob) {
    Some(text) => ldtk_decode_level(try! @json.parse(text[:]))
    None => abort("LDtk external level blob has no readable text payload")
  }
}

///|
pub fn LdtkProject::get_loaded_level_by_iid(
  self : LdtkProject,
  blob_assets : @asset.Assets[@asset.Blob],
  iid : String,
) -> Level? {
  guard self.get_raw_level_by_iid(iid) is Some(level) else { return None }
  if ldtk_level_loaded(level) {
    return Some(level)
  }
  guard self.external_level_blob_handles.get(level.iid) is Some(blob_handle) else {
    return None
  }
  if blob_assets.contains(blob_handle) {
    Some(ldtk_level_from_blob(blob_handle))
  } else {
    None
  }
}

///|
pub fn LdtkProject::find_raw_level_by_level_selection(
  self : LdtkProject,
  selection : LevelSelection,
) -> Level? {
  match selection {
    Identifier(identifier) => {
      for level in self.data.levels {
        if level.identifier == identifier {
          return Some(level)
        }
      }
      for world in self.data.worlds {
        for level in world.levels {
          if level.identifier == identifier {
            return Some(level)
          }
        }
      }
      None
    }
    Indices(indices) => self.get_raw_level_at_indices(indices)
    Iid(level_iid) => self.get_raw_level_by_iid(level_iid.get())
    Uid(uid) => {
      for level in self.data.levels {
        if level.uid == uid {
          return Some(level)
        }
      }
      for world in self.data.worlds {
        for level in world.levels {
          if level.uid == uid {
            return Some(level)
          }
        }
      }
      None
    }
  }
}

///|
fn ldtk_string_last_index_of_char(input : String, code_unit : Int) -> Int {
  let mut out = -1
  for i in 0..<input.length() {
    if input.code_unit_at(i).to_int() == code_unit {
      out = i
    }
  }
  out
}

///|
fn ldtk_resolve_relative_asset_path(
  ldtk_path : @asset.AssetPath,
  rel_path : String,
) -> @asset.AssetPath {
  if rel_path.length() == 0 {
    return ldtk_path.with_label(None)
  }
  if ldtk_string_last_index_of_char(rel_path, 58) >= 0 {
    return @asset.asset_parse_path(rel_path).with_label(None)
  }

  let base_path = ldtk_path.path
  let slash_index = ldtk_string_last_index_of_char(base_path, 47)
  let base_dir = if slash_index >= 0 {
    base_path[0:slash_index + 1].to_owned()
  } else {
    ""
  }
  let rel_without_prefix = if rel_path.length() > 0 &&
    rel_path.code_unit_at(0).to_int() == 47 {
    rel_path[1:rel_path.length()].to_owned()
  } else {
    rel_path
  }
  @asset.asset_parse_path(base_dir + rel_without_prefix)
  .with_source(ldtk_path.source)
  .with_label(None)
}

///|
fn ldtk_level_map_insert(
  level_map : @hashmap.HashMap[String, LevelMetadata],
  level : Level,
  indices : LevelIndices,
  ldtk_root_path : @asset.AssetPath,
  asset_server : @asset.AssetServer,
) -> Unit {
  let bg_image = match level.bg_rel_path {
    Some(rel_path) =>
      Some(
        asset_server.load(
          ldtk_resolve_relative_asset_path(ldtk_root_path, rel_path),
        ),
      )
    None => None
  }
  level_map.set(level.iid, LevelMetadata::new(bg_image, indices))
}

///|
fn ldtk_load_project_asset(
  context : @asset.LoadContext,
  bytes : Bytes,
) -> LdtkProject {
  let data = ldtk_parse_json(bytes)
  let ldtk_root_path = context.path().with_label(None)
  let asset_server = context.asset_server()
  let level_map : @hashmap.HashMap[String, LevelMetadata] = @hashmap.HashMap::new()
  let tileset_map : @hashmap.HashMap[Int, @asset.Handle[@asset.Image]] = @hashmap.HashMap::new()
  let external_level_blob_handles : @hashmap.HashMap[
    String,
    @asset.Handle[@asset.Blob],
  ] = @hashmap.HashMap::new()

  for level_index, level in data.levels {
    ldtk_level_map_insert(
      level_map,
      level,
      LevelIndices::in_root(level_index),
      ldtk_root_path,
      asset_server,
    )
    if data.external_levels && level.external_rel_path is Some(rel_path) {
      let resolved = ldtk_resolve_relative_asset_path(ldtk_root_path, rel_path)
      external_level_blob_handles.set(
        level.iid,
        asset_server.load_bytes(@asset.asset_format_path(resolved)),
      )
    }
  }

  for world_index, world in data.worlds {
    for level_index, level in world.levels {
      ldtk_level_map_insert(
        level_map,
        level,
        LevelIndices::in_world(world_index, level_index),
        ldtk_root_path,
        asset_server,
      )
      if data.external_levels && level.external_rel_path is Some(rel_path) {
        let resolved = ldtk_resolve_relative_asset_path(
          ldtk_root_path, rel_path,
        )
        external_level_blob_handles.set(
          level.iid,
          asset_server.load_bytes(@asset.asset_format_path(resolved)),
        )
      }
    }
  }

  for tileset in data.defs.tilesets {
    if tileset.rel_path is Some(rel_path) {
      let resolved = ldtk_resolve_relative_asset_path(ldtk_root_path, rel_path)
      let image_handle : @asset.Handle[@asset.Image] = asset_server.load(
        resolved,
      )
      tileset_map.set(tileset.uid, image_handle)
    }
  }

  let int_grid_image_handle = match data.defs.create_int_grid_image() {
    Some(image) => Some(context.add_labeled_asset("int_grid_image", image))
    None => None
  }

  LdtkProject::new(
    data, level_map, tileset_map, int_grid_image_handle, external_level_blob_handles,
  )
}

///|
fn ldtk_project_asset_default() -> LdtkProject {
  LdtkProject::new(
    LdtkJson::{
      iid: "",
      bg_color: @sprite.Color::black(),
      default_level_bg_color: @sprite.Color::black(),
      external_levels: false,
      world_layout: None,
      world_grid_width: None,
      world_grid_height: None,
      levels: [],
      worlds: [],
      defs: Definitions::{ entities: [], layers: [], tilesets: [] },
    },
    @hashmap.HashMap::new(),
    @hashmap.HashMap::new(),
    None,
    @hashmap.HashMap::new(),
  )
}

///|
fn ldtk_project_ready(
  world : @ecs.World,
  handle : @asset.Handle[LdtkProject],
) -> Bool {
  let key : @ecs.ResourceKey[@asset.Assets[LdtkProject]] = @asset.assets_resource_key()
  let image_key : @ecs.ResourceKey[@asset.Assets[@asset.Image]] = @asset.assets_resource_key()
  let blob_key : @ecs.ResourceKey[@asset.Assets[@asset.Blob]] = @asset.assets_resource_key()
  guard (try! world.get_resource(key)) is Some(project_assets) else {
    return false
  }
  guard (try! world.get_resource(image_key)) is Some(image_assets) else {
    return false
  }
  guard project_assets.get(handle) is Some(project) else { return false }

  for entry in project.tileset_map.iter() {
    let (_, image_handle) = entry
    if !image_assets.contains(image_handle) {
      return false
    }
  }

  if project.external_level_blob_handles.length() == 0 {
    return true
  }
  guard (try! world.get_resource(blob_key)) is Some(blob_assets) else {
    return false
  }
  for entry in project.external_level_blob_handles.iter() {
    let (_, blob_handle) = entry
    if blob_assets.get(blob_handle) is None {
      return false
    }
  }
  true
}

///|
pub fn ldtk_init_assets(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  @asset.asset_with_world(app.world(), fn() {
    @asset.asset_register_ready_checker(ldtk_project_ready)
  })
  @asset.init_asset_loader(
    @asset.init_asset(app, ldtk_project_asset_default),
    @asset.AssetLoader::new_with_context(["ldtk"], ldtk_load_project_asset),
  )
}
