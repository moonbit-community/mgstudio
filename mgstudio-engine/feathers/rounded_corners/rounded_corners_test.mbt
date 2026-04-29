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
fn val_px_eq(value : @ui.Val, expected : Float) -> Bool {
  match value {
    @ui.Val::Px(actual) => actual == expected
    _ => false
  }
}

///|
fn radius_matches(
  radius : @ui.BorderRadius,
  top_left : Float,
  top_right : Float,
  bottom_right : Float,
  bottom_left : Float,
) -> Bool {
  val_px_eq(radius.top_left, top_left) &&
  val_px_eq(radius.top_right, top_right) &&
  val_px_eq(radius.bottom_right, bottom_right) &&
  val_px_eq(radius.bottom_left, bottom_left)
}

///|
test "feathers rounded corners: default mirrors Bevy All" {
  debug_inspect(
    RoundedCorners::default() is RoundedCorners::All,
    content="true",
  )
}

///|
test "feathers rounded corners: converts each supported Bevy shape" {
  debug_inspect(
    radius_matches(
      RoundedCorners::None.to_border_radius(4.0F),
      0.0F,
      0.0F,
      0.0F,
      0.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::All.to_border_radius(4.0F),
      4.0F,
      4.0F,
      4.0F,
      4.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::TopLeft.to_border_radius(4.0F),
      4.0F,
      0.0F,
      0.0F,
      0.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::TopRight.to_border_radius(4.0F),
      0.0F,
      4.0F,
      0.0F,
      0.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::BottomRight.to_border_radius(4.0F),
      0.0F,
      0.0F,
      4.0F,
      0.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::BottomLeft.to_border_radius(4.0F),
      0.0F,
      0.0F,
      0.0F,
      4.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::Top.to_border_radius(4.0F),
      4.0F,
      4.0F,
      0.0F,
      0.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::Right.to_border_radius(4.0F),
      0.0F,
      4.0F,
      4.0F,
      0.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::Bottom.to_border_radius(4.0F),
      0.0F,
      0.0F,
      4.0F,
      4.0F,
    ),
    content="true",
  )
  debug_inspect(
    radius_matches(
      RoundedCorners::Left.to_border_radius(4.0F),
      4.0F,
      0.0F,
      0.0F,
      4.0F,
    ),
    content="true",
  )
}
