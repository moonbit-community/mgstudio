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
/// Mask generator (subset).
///
/// Ported from upstream `zeno/src/mask.rs` (Apache-2.0 OR MIT).

pub(all) enum Format {
  Alpha
  Subpixel
  CustomSubpixel(Array[Double])
}

pub fn Format::subpixel_bgra() -> Format {
  Format::CustomSubpixel([0.3, 0.0, -0.3])
}

pub fn Format::buffer_size(self : Format, width : UInt, height : UInt) -> Int {
  let pixel_size = match self {
    Format::Alpha => 1
    _ => 4
  }
  (width.reinterpret_as_int() * height.reinterpret_as_int() * pixel_size)
}

