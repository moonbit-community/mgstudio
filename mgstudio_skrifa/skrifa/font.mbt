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
/// FontRef (skeleton).
///
/// Ported from `fontations/skrifa/src/font.rs` (Apache-2.0 OR MIT).
pub type GlyphId = UInt

///|
pub struct FontRef {
  data : Bytes
  index : UInt
}

///|
pub fn FontRef::new(data : Bytes) -> FontRef? {
  // TODO: validate SFNT/collection.
  Some(FontRef::{ data, index: 0 })
}

///|
pub fn FontRef::from_index(data : Bytes, index : UInt) -> FontRef? {
  // TODO: validate collection offsets.
  Some(FontRef::{ data, index })
}

///|
pub fn FontRef::data(self : FontRef) -> Bytes {
  self.data
}

///|
pub fn FontRef::index(self : FontRef) -> UInt {
  self.index
}
