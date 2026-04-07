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
pub(open) trait LevelMetadataAccessor {
  get_level_metadata_by_iid(Self, String) -> LevelMetadata?
}

///|
pub impl LevelMetadataAccessor for LdtkProject with get_level_metadata_by_iid(
  value,
  iid,
) {
  value.level_map.get(iid)
}

///|
pub fn[A : LevelMetadataAccessor + RawLevelAccessor] get_raw_level_by_iid(
  accessor : A,
  iid : String,
) -> Level? {
  guard accessor.get_level_metadata_by_iid(iid) is Some(metadata) else {
    return None
  }
  get_raw_level_at_indices(accessor, metadata.indices)
}

///|
pub fn[A : LevelMetadataAccessor + RawLevelAccessor] find_raw_level_by_level_selection(
  accessor : A,
  selection : LevelSelection,
) -> Level? {
  match selection {
    Identifier(identifier) => {
      for level in iter_raw_levels(accessor) {
        if level.identifier == identifier {
          return Some(level)
        }
      }
      None
    }
    Indices(indices) => get_raw_level_at_indices(accessor, indices)
    Iid(level_iid) => get_raw_level_by_iid(accessor, level_iid.get())
    Uid(uid) => {
      for level in iter_raw_levels(accessor) {
        if level.uid == uid {
          return Some(level)
        }
      }
      None
    }
  }
}
