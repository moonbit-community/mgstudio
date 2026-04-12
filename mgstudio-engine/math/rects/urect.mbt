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
// Bevy source: `bevy/crates/bevy_math/src/rects/urect.rs`.

///|
pub struct URect {
  min : @math.UVec2
  max : @math.UVec2
}

///|
pub fn URect::new(min : @math.UVec2, max : @math.UVec2) -> URect {
  URect::{ min, max }
}

///|
pub fn URect::size(self : URect) -> @math.UVec2 {
  @math.UVec2::new(self.max.x - self.min.x, self.max.y - self.min.y)
}

///|
pub fn URect::as_rect(self : URect) -> Rect {
  Rect::new(self.min.to_vec2(), self.max.to_vec2())
}

///|
pub impl ToJson for URect with to_json(self) {
  (self.min, self.max).to_json()
}

///|
pub impl @json.FromJson for URect with from_json(json, path) {
  let (min, max) : (@math.UVec2, @math.UVec2) = @json.from_json(json, path~)
  URect::new(min, max)
}
