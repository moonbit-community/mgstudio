// Copyright 2025 International Digital Economy Academy
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
// Bevy source: `bevy/crates/bevy_utils/src/map.rs`.
// The current runtime relies on MoonBit's built-in `Map` instead of a dedicated Bevy map wrapper.

///|
pub type HashMap[K, V] = Map[K, V]

///|
pub fn[K, V] map_new() -> HashMap[K, V] {
  Map::new()
}

///|
pub fn[K : Hash + Eq, V] map_from_entries(
  entries : Array[(K, V)],
) -> HashMap[K, V] {
  let map : HashMap[K, V] = Map::new()
  for entry in entries {
    map[entry.0] = entry.1
  }
  map
}
