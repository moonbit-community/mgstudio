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
/// Instance-related types.
///
/// Ported from `fontations/skrifa` (Apache-2.0 OR MIT).
pub type NormalizedCoord = Int

///|
pub struct Size {
  value : Double
}

///|
pub fn Size::new(size : Double) -> Size {
  Size::{ value: size }
}

///|
pub fn Size::unscaled() -> Size {
  Size::{ value: 0.0 }
}

///|
pub fn Size::value(self : Size) -> Double {
  self.value
}
