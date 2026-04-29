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
// Bevy source: `bevy/crates/bevy_feathers/src/rounded_corners.rs`.

///|
pub(all) enum RoundedCorners {
  None
  All
  TopLeft
  TopRight
  BottomRight
  BottomLeft
  Top
  Right
  Bottom
  Left
} derive(Eq, Debug)

///|
pub fn RoundedCorners::default() -> RoundedCorners {
  All
}

///|
pub fn RoundedCorners::to_border_radius(
  self : RoundedCorners,
  radius : Float,
) -> @ui.BorderRadius {
  let radius = @ui.Val::Px(radius)
  let zero = @ui.Val::zero()
  match self {
    None => @ui.BorderRadius::all(zero)
    All => @ui.BorderRadius::all(radius)
    TopLeft => @ui.BorderRadius::new(radius, zero, zero, zero)
    TopRight => @ui.BorderRadius::new(zero, radius, zero, zero)
    BottomRight => @ui.BorderRadius::new(zero, zero, radius, zero)
    BottomLeft => @ui.BorderRadius::new(zero, zero, zero, radius)
    Top => @ui.BorderRadius::new(radius, radius, zero, zero)
    Right => @ui.BorderRadius::new(zero, radius, radius, zero)
    Bottom => @ui.BorderRadius::new(zero, zero, radius, radius)
    Left => @ui.BorderRadius::new(radius, zero, zero, radius)
  }
}
