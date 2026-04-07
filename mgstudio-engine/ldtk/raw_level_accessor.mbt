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
pub(open) trait RawLevelAccessor {
  root_levels(Self) -> Array[Level]
  worlds(Self) -> Array[World]
}

///|
pub impl RawLevelAccessor for LdtkJson with root_levels(value) {
  value.levels
}

///|
pub impl RawLevelAccessor for LdtkJson with worlds(value) {
  value.worlds
}

///|
pub impl RawLevelAccessor for LdtkProject with root_levels(value) {
  value.json_data().levels
}

///|
pub impl RawLevelAccessor for LdtkProject with worlds(value) {
  value.json_data().worlds
}

///|
pub fn[A : RawLevelAccessor] iter_root_levels(accessor : A) -> Array[Level] {
  accessor.root_levels()
}

///|
pub fn[A : RawLevelAccessor] iter_world_levels(accessor : A) -> Array[Level] {
  let levels : Array[Level] = []
  for world in accessor.worlds() {
    for level in world.levels {
      levels.push(level)
    }
  }
  levels
}

///|
pub fn[A : RawLevelAccessor] iter_raw_levels(accessor : A) -> Array[Level] {
  let levels : Array[Level] = []
  for level in accessor.root_levels() {
    levels.push(level)
  }
  for world in accessor.worlds() {
    for level in world.levels {
      levels.push(level)
    }
  }
  levels
}

///|
pub fn[A : RawLevelAccessor] iter_root_levels_with_indices(
  accessor : A,
) -> Array[(LevelIndices, Level)] {
  let out : Array[(LevelIndices, Level)] = []
  for index, level in accessor.root_levels() {
    out.push((LevelIndices::in_root(index), level))
  }
  out
}

///|
pub fn[A : RawLevelAccessor] iter_world_levels_with_indices(
  accessor : A,
) -> Array[(LevelIndices, Level)] {
  let out : Array[(LevelIndices, Level)] = []
  for world_index, world in accessor.worlds() {
    for level_index, level in world.levels {
      out.push((LevelIndices::in_world(world_index, level_index), level))
    }
  }
  out
}

///|
pub fn[A : RawLevelAccessor] iter_raw_levels_with_indices(
  accessor : A,
) -> Array[(LevelIndices, Level)] {
  let out : Array[(LevelIndices, Level)] = []
  for value in iter_root_levels_with_indices(accessor) {
    out.push(value)
  }
  for value in iter_world_levels_with_indices(accessor) {
    out.push(value)
  }
  out
}

///|
pub fn[A : RawLevelAccessor] get_raw_level_at_indices(
  accessor : A,
  indices : LevelIndices,
) -> Level? {
  match indices.world {
    Some(world_index) => {
      guard world_index >= 0 && world_index < accessor.worlds().length() else {
        return None
      }
      let world = accessor.worlds()[world_index]
      if indices.level >= 0 && indices.level < world.levels.length() {
        Some(world.levels[indices.level])
      } else {
        None
      }
    }
    None =>
      if indices.level >= 0 && indices.level < accessor.root_levels().length() {
        Some(accessor.root_levels()[indices.level])
      } else {
        None
      }
  }
}
