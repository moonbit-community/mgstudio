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
// Bevy source: `bevy/crates/bevy_material/src/labels.rs`.

///|
pub type ShaderLabel = String

///|
pub type InternedShaderLabel = String

///|
pub type DrawFunctionLabel = String

///|
pub type InternedDrawFunctionLabel = String

///|
pub fn shader_label(value : String) -> ShaderLabel {
  value
}

///|
pub fn draw_function_label(value : String) -> DrawFunctionLabel {
  value
}

///|
pub struct DrawFunctions {
  entries : Array[(InternedDrawFunctionLabel, DrawFunctionId)]
  mut next_id : UInt
}

///|
pub fn DrawFunctions::DrawFunctions() -> DrawFunctions {
  { entries: [], next_id: 0U }
}

///|
pub impl Default for DrawFunctions with fn default() {
  DrawFunctions()
}

///|
pub fn DrawFunctions::new() -> DrawFunctions {
  DrawFunctions()
}

///|
pub struct DrawFunctionId {
  id : UInt
} derive(Eq)

///|
pub fn DrawFunctionId::new(id : UInt) -> DrawFunctionId {
  { id, }
}

///|
pub fn DrawFunctionId::id(self : DrawFunctionId) -> UInt {
  self.id
}

///|
pub fn DrawFunctions::len(self : DrawFunctions) -> Int {
  self.entries.length()
}

///|
pub fn DrawFunctions::id(
  self : DrawFunctions,
  label : DrawFunctionLabel,
) -> DrawFunctionId? {
  for entry in self.entries {
    let (entry_label, entry_id) = entry
    if entry_label == label {
      return Some(entry_id)
    }
  }
  None
}

///|
pub fn DrawFunctions::register(
  self : DrawFunctions,
  label : DrawFunctionLabel,
) -> DrawFunctionId {
  match self.id(label) {
    Some(id) => id
    None => {
      let id = DrawFunctionId::new(self.next_id)
      self.entries.push((label, id))
      self.next_id = self.next_id + 1U
      id
    }
  }
}

///|
pub fn DrawFunctions::labels(self : DrawFunctions) -> Array[DrawFunctionLabel] {
  let labels : Array[DrawFunctionLabel] = []
  for entry in self.entries {
    let (label, _) = entry
    labels.push(label)
  }
  labels
}
