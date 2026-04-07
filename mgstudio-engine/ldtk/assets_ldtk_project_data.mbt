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
pub(all) enum LdtkProjectData {
  Standalone(LdtkJsonWithMetadata)
  Parent(LdtkJsonWithMetadata)
}

///|
pub fn LdtkProjectData::from_project(project : LdtkProject) -> LdtkProjectData {
  let json_with_metadata = LdtkJsonWithMetadata::from_project(project)
  if project.data.external_levels {
    Parent(json_with_metadata)
  } else {
    Standalone(json_with_metadata)
  }
}

///|
pub fn LdtkProjectData::json_data(self : LdtkProjectData) -> LdtkJson {
  match self {
    Standalone(data) => data.json_data()
    Parent(data) => data.json_data()
  }
}

///|
pub fn LdtkProjectData::as_standalone(
  self : LdtkProjectData,
) -> LdtkJsonWithMetadata {
  match self {
    Standalone(data) => data
    Parent(_) =>
      abort("LdtkProjectData::as_standalone expected standalone data")
  }
}

///|
pub fn LdtkProjectData::as_parent(
  self : LdtkProjectData,
) -> LdtkJsonWithMetadata {
  match self {
    Parent(data) => data
    Standalone(_) => abort("LdtkProjectData::as_parent expected parent data")
  }
}

///|
pub impl RawLevelAccessor for LdtkProjectData with root_levels(value) {
  value.json_data().levels
}

///|
pub impl RawLevelAccessor for LdtkProjectData with worlds(value) {
  value.json_data().worlds
}

///|
pub impl LevelMetadataAccessor for LdtkProjectData with get_level_metadata_by_iid(
  value,
  iid,
) {
  match value {
    Standalone(data) => data.get_level_metadata_by_iid(iid)
    Parent(data) => data.get_level_metadata_by_iid(iid)
  }
}
