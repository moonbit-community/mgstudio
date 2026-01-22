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
/// Context for reusing dynamic memory allocations.
///
/// Ported from upstream `zeno/src/scratch.rs` (Apache-2.0 OR MIT).
///
/// NOTE: This is currently a minimal skeleton. Rasterization/storage will be
/// ported as we bring over `segment`, `stroke`, and `raster`.
pub struct Scratch {
  // Placeholder for future heap storage.
  scratch0 : Array[Byte]
}

///|
pub fn Scratch::new() -> Scratch {
  Scratch::{ scratch0: [] }
}

///|
pub fn Scratch::default() -> Scratch {
  Scratch::new()
}

///|
pub fn Scratch::clear(self : Scratch) -> Unit {
  self.scratch0.clear()
}
