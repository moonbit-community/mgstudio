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
/// Outline module (skeleton).
///
/// Ported from `fontations/skrifa/src/outline/*` (Apache-2.0 OR MIT).
pub struct OutlineGlyphCollection {
  // Placeholder; upstream holds references to font tables.
  dummy : Int
}

///|
pub fn OutlineGlyphCollection::new() -> OutlineGlyphCollection {
  OutlineGlyphCollection::{ dummy: 0 }
}

///|
pub fn OutlineGlyphCollection::format(self : OutlineGlyphCollection) -> UInt? {
  // TODO: detect outline format.
  self.dummy |> ignore
  None
}

///|
pub struct HintingInstance {
  dummy : Int
}

///|
pub fn HintingInstance::new() -> HintingInstance {
  HintingInstance::{ dummy: 0 }
}
