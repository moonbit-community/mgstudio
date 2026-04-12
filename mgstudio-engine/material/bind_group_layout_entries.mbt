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
// Bevy source: `bevy/crates/bevy_material/src/bind_group_layout_entries.rs`.

///|
pub type MaterialBindGroupLayoutEntry = @render_resource.BindGroupLayoutEntry

///|
pub struct BindGroupLayoutEntryBuilder {
  kind : @render_resource.BindingType
  visibility : UInt?
  count : UInt?
}

///|
pub fn bind_group_layout_entry_builder(
  kind : @render_resource.BindingType,
) -> BindGroupLayoutEntryBuilder {
  BindGroupLayoutEntryBuilder::{ kind, visibility: None, count: None }
}

///|
pub fn BindGroupLayoutEntryBuilder::visibility(
  self : BindGroupLayoutEntryBuilder,
  visibility : UInt,
) -> BindGroupLayoutEntryBuilder {
  BindGroupLayoutEntryBuilder::{ ..self, visibility: Some(visibility) }
}

///|
pub fn BindGroupLayoutEntryBuilder::count(
  self : BindGroupLayoutEntryBuilder,
  count : UInt,
) -> BindGroupLayoutEntryBuilder {
  BindGroupLayoutEntryBuilder::{
    ..self,
    count: if count == 0U {
      None
    } else {
      Some(count)
    },
  }
}

///|
pub fn BindGroupLayoutEntryBuilder::build(
  self : BindGroupLayoutEntryBuilder,
  binding : Int,
  default_visibility : UInt,
) -> MaterialBindGroupLayoutEntry {
  ignore(self.count)
  @render_resource.BindGroupLayoutEntry::new(
    binding,
    self.visibility.unwrap_or(default_visibility),
    self.kind,
  )
}

///|
pub struct BindGroupLayoutEntries {
  entries : Array[MaterialBindGroupLayoutEntry]
}

///|
pub fn bind_group_layout_entries_sequential(
  default_visibility : UInt,
  entries : Array[BindGroupLayoutEntryBuilder],
) -> BindGroupLayoutEntries {
  let output : Array[MaterialBindGroupLayoutEntry] = []
  let mut binding = 0
  for entry in entries {
    output.push(entry.build(binding, default_visibility))
    binding = binding + 1
  }
  BindGroupLayoutEntries::{ entries: output }
}

///|
pub fn bind_group_layout_entries_with_indices(
  default_visibility : UInt,
  entries : Array[(Int, BindGroupLayoutEntryBuilder)],
) -> BindGroupLayoutEntries {
  let output : Array[MaterialBindGroupLayoutEntry] = []
  for entry in entries {
    output.push(entry.1.build(entry.0, default_visibility))
  }
  BindGroupLayoutEntries::{ entries: output }
}

///|
pub fn bind_group_layout_entries_single(
  visibility : UInt,
  entry : BindGroupLayoutEntryBuilder,
) -> Array[MaterialBindGroupLayoutEntry] {
  [entry.build(0, visibility)]
}

///|
pub fn BindGroupLayoutEntries::entries(
  self : BindGroupLayoutEntries,
) -> Array[MaterialBindGroupLayoutEntry] {
  self.entries
}
