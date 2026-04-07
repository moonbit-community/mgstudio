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
pub struct LdtkJsonWithMetadata {
  json_data : LdtkJson
  level_map : @hashmap.HashMap[String, LevelMetadata]
}

///|
pub fn LdtkJsonWithMetadata::new(
  json_data : LdtkJson,
  level_map : @hashmap.HashMap[String, LevelMetadata],
) -> LdtkJsonWithMetadata {
  LdtkJsonWithMetadata::{ json_data, level_map }
}

///|
pub fn LdtkJsonWithMetadata::from_project(
  project : LdtkProject,
) -> LdtkJsonWithMetadata {
  LdtkJsonWithMetadata::new(project.data, project.level_map)
}

///|
pub fn LdtkJsonWithMetadata::json_data(self : LdtkJsonWithMetadata) -> LdtkJson {
  self.json_data
}

///|
pub fn LdtkJsonWithMetadata::level_map(
  self : LdtkJsonWithMetadata,
) -> @hashmap.HashMap[String, LevelMetadata] {
  self.level_map
}

///|
pub impl RawLevelAccessor for LdtkJsonWithMetadata with root_levels(value) {
  value.json_data.levels
}

///|
pub impl RawLevelAccessor for LdtkJsonWithMetadata with worlds(value) {
  value.json_data.worlds
}

///|
pub impl LevelMetadataAccessor for LdtkJsonWithMetadata with get_level_metadata_by_iid(
  value,
  iid,
) {
  value.level_map.get(iid)
}

///|
pub fn LdtkJsonWithMetadata::iter_loaded_levels(
  self : LdtkJsonWithMetadata,
) -> Array[LoadedLevel] {
  let out : Array[LoadedLevel] = []
  for level in iter_raw_levels(self) {
    out.push(LoadedLevel::try_from(level)) catch {
      _ => ()
    }
  }
  out
}

///|
pub fn LdtkJsonWithMetadata::get_loaded_level_at_indices(
  self : LdtkJsonWithMetadata,
  indices : LevelIndices,
) -> LoadedLevel? {
  guard get_raw_level_at_indices(self, indices) is Some(level) else {
    return None
  }
  Some(LoadedLevel::try_from(level)) catch {
    _ => None
  }
}

///|
pub fn LdtkJsonWithMetadata::get_loaded_level_by_iid(
  self : LdtkJsonWithMetadata,
  iid : String,
) -> LoadedLevel? {
  guard get_raw_level_by_iid(self, iid) is Some(level) else { return None }
  Some(LoadedLevel::try_from(level)) catch {
    _ => None
  }
}

///|
pub fn LdtkJsonWithMetadata::find_loaded_level_by_level_selection(
  self : LdtkJsonWithMetadata,
  level_selection : LevelSelection,
) -> LoadedLevel? {
  guard find_raw_level_by_level_selection(self, level_selection) is Some(level) else {
    return None
  }
  Some(LoadedLevel::try_from(level)) catch {
    _ => None
  }
}
