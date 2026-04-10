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
// Bevy source: `bevy/crates/bevy_pbr/src/material_bind_groups.rs`.

///|
///|
pub struct MaterialBindGroupEntry {
  material_id : Int
  bind_group_id : Int
}

///|
pub fn MaterialBindGroupEntry::new(
  material_id : Int,
  bind_group_id : Int,
) -> MaterialBindGroupEntry {
  MaterialBindGroupEntry::{ material_id, bind_group_id }
}

///|
pub struct MaterialBindGroups {
  entries : Array[MaterialBindGroupEntry]
}

///|
pub fn MaterialBindGroups::default() -> MaterialBindGroups {
  MaterialBindGroups::{ entries: [] }
}

///|
pub fn MaterialBindGroups::push(
  self : MaterialBindGroups,
  entry : MaterialBindGroupEntry,
) -> Unit {
  self.entries.push(entry)
}

///|
pub fn MaterialBindGroups::entry_count(self : MaterialBindGroups) -> Int {
  self.entries.length()
}
