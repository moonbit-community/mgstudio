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
pub struct DrawFunctionId {
  id : UInt
} derive(Eq)

///|
pub fn DrawFunctionId::new(id : UInt) -> DrawFunctionId {
  DrawFunctionId::{ id, }
}

///|
pub fn DrawFunctionId::id(self : DrawFunctionId) -> UInt {
  self.id
}
