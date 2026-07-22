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
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::Viewport`.

///|
pub struct Viewport {
  physical_position : @math.IVec2
  physical_size : @math.IVec2
  depth_min : Float
  depth_max : Float
}

///|
pub fn Viewport::new(
  physical_position : @math.IVec2,
  physical_size : @math.IVec2,
) -> Viewport {
  { physical_position, physical_size, depth_min: 0.0F, depth_max: 1.0F }
}

///|
pub fn Viewport::new_with_depth(
  physical_position : @math.IVec2,
  physical_size : @math.IVec2,
  depth_min : Float,
  depth_max : Float,
) -> Viewport {
  let mut min_depth = depth_min
  let mut max_depth = depth_max
  if min_depth < 0.0F {
    min_depth = 0.0F
  }
  if min_depth > 1.0F {
    min_depth = 1.0F
  }
  if max_depth < min_depth {
    max_depth = min_depth
  }
  if max_depth > 1.0F {
    max_depth = 1.0F
  }
  {
    physical_position,
    physical_size,
    depth_min: min_depth,
    depth_max: max_depth,
  }
}

///|
pub fn Viewport::with_depth(
  self : Viewport,
  depth_min : Float,
  depth_max : Float,
) -> Viewport {
  Viewport::new_with_depth(
    self.physical_position,
    self.physical_size,
    depth_min,
    depth_max,
  )
}

///|
pub fn Viewport::physical_position(self : Viewport) -> @math.IVec2 {
  self.physical_position
}

///|
pub fn Viewport::physical_size(self : Viewport) -> @math.IVec2 {
  self.physical_size
}

///|
pub fn Viewport::depth_min(self : Viewport) -> Float {
  self.depth_min
}

///|
pub fn Viewport::depth_max(self : Viewport) -> Float {
  self.depth_max
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::Viewport::clamp_to_size`.
// Keep viewport rectangle inside `size` while preserving edge semantics:
// if origin is outside but target axis is non-empty, clamp origin to `size-1`
// and keep a 1px span.
pub fn Viewport::clamp_to_size(self : Viewport, size : @math.IVec2) -> Viewport {
  let mut position_x = self.physical_position.x
  let mut position_y = self.physical_position.y
  let mut size_x = self.physical_size.x
  let mut size_y = self.physical_size.y
  let target_x = if size.x < 0 { 0 } else { size.x }
  let target_y = if size.y < 0 { 0 } else { size.y }
  if position_x < 0 {
    position_x = 0
  }
  if position_y < 0 {
    position_y = 0
  }
  if size_x < 0 {
    size_x = 0
  }
  if size_y < 0 {
    size_y = 0
  }
  if size_x + position_x > target_x {
    if position_x < target_x {
      size_x = target_x - position_x
    } else if target_x > 0 {
      position_x = target_x - 1
      size_x = 1
    } else {
      position_x = 0
      size_x = 0
    }
  }
  if size_y + position_y > target_y {
    if position_y < target_y {
      size_y = target_y - position_y
    } else if target_y > 0 {
      position_y = target_y - 1
      size_y = 1
    } else {
      position_y = 0
      size_y = 0
    }
  }
  Viewport::new(
    @math.IVec2::new(position_x, position_y),
    @math.IVec2::new(size_x, size_y),
  ).with_depth(self.depth_min, self.depth_max)
}

///|
pub fn Viewport::Viewport() -> Viewport {
  Viewport::new(@math.IVec2::new(0, 0), @math.IVec2::new(1, 1))
}

///|
pub fn encode_viewport(viewport : Viewport) -> Json {
  (
    encode_ivec2(viewport.physical_position),
    encode_ivec2(viewport.physical_size),
    viewport.depth_min,
    viewport.depth_max,
  ).to_json()
}

///|
pub fn decode_viewport(json : Json) -> Viewport {
  let (position, size, depth_min, depth_max) : (Json, Json, Float, Float) = try! @json.from_json(
    json,
  )
  Viewport::new(decode_ivec2(position), decode_ivec2(size)).with_depth(
    depth_min, depth_max,
  )
}

///|
fn encode_ivec2(value : @math.IVec2) -> Json {
  (value.x, value.y).to_json()
}

///|
fn decode_ivec2(json : Json) -> @math.IVec2 {
  let (x, y) : (Int, Int) = try! @json.from_json(json)
  @math.IVec2::new(x, y)
}

///|
pub impl ToJson for Viewport with fn to_json(self) {
  encode_viewport(self)
}

///|
pub impl @json.FromJson for Viewport with fn from_json(json, _path) {
  decode_viewport(json)
}
