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
// Bevy source: `bevy/crates/bevy_feathers/src/rounded_corners.rs`.

///|
pub(all) enum RoundedCorners {
  None
  All
  Top
  Bottom
  Left
  Right
} derive(Eq, Debug)

///|
pub fn RoundedCorners::to_radius4(
  self : RoundedCorners,
  radius : Float,
) -> (Float, Float, Float, Float) {
  match self {
    None => (0.0, 0.0, 0.0, 0.0)
    All => (radius, radius, radius, radius)
    Top => (radius, radius, 0.0, 0.0)
    Bottom => (0.0, 0.0, radius, radius)
    Left => (radius, 0.0, 0.0, radius)
    Right => (0.0, radius, radius, 0.0)
  }
}
