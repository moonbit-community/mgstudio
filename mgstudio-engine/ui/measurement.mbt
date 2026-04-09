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
// Bevy source: `bevy/crates/bevy_ui/src/measurement.rs`.
pub struct ScrollPosition {
  offset_x : Float
  offset_y : Float
} derive(ToJson, FromJson)

///|
pub fn ScrollPosition::default() -> ScrollPosition {
  ScrollPosition::{ offset_x: 0.0F, offset_y: 0.0F }
}

///|
pub fn ScrollPosition::new(
  offset_x : Float,
  offset_y : Float,
) -> ScrollPosition {
  ScrollPosition::{ offset_x, offset_y }
}

///|
pub fn ScrollPosition::with_delta(
  self : ScrollPosition,
  dx : Float,
  dy : Float,
) -> ScrollPosition {
  ScrollPosition::{ offset_x: self.offset_x + dx, offset_y: self.offset_y + dy }
}

///|
pub struct CalculatedClip {
  clip : @math.Rect
} derive(ToJson, FromJson)

///|
pub fn CalculatedClip::new(clip : @math.Rect) -> CalculatedClip {
  CalculatedClip::{ clip, }
}

///|
pub struct ContentSize {
  size : @math.Vec2
} derive(ToJson, FromJson)

///|
pub fn ContentSize::new(size : @math.Vec2) -> ContentSize {
  ContentSize::{ size, }
}

///|
pub struct ImageNodeSize {
  size : @math.UVec2
} derive(ToJson, FromJson)

///|
pub fn ImageNodeSize::default() -> ImageNodeSize {
  ImageNodeSize::{ size: @math.UVec2::zero() }
}

///|
pub fn ImageNodeSize::size(self : ImageNodeSize) -> @math.UVec2 {
  self.size
}
