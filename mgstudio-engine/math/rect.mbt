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
pub struct Rect {
  min : Vec2
  max : Vec2
}

///|
pub fn Rect::new(min : Vec2, max : Vec2) -> Rect {
  Rect::{ min, max }
}

///|
pub fn Rect::size(self : Rect) -> Vec2 {
  Vec2::new(self.max.x - self.min.x, self.max.y - self.min.y)
}

///|
pub fn Rect::min(self : Rect) -> Vec2 {
  self.min
}

///|
pub fn Rect::max(self : Rect) -> Vec2 {
  self.max
}

///|
pub fn Rect::translate(self : Rect, offset : Vec2) -> Rect {
  Rect::new(self.min.add(offset), self.max.add(offset))
}

///|
pub fn Rect::center(self : Rect) -> Vec2 {
  Vec2::new((self.min.x + self.max.x) / 2.0F, (self.min.y + self.max.y) / 2.0F)
}

///|
pub fn Rect::contains(self : Rect, value : Vec2) -> Bool {
  value.x >= self.min.x &&
  value.y >= self.min.y &&
  value.x <= self.max.x &&
  value.y <= self.max.y
}

///|
pub impl ToJson for Rect with to_json(self) {
  (self.min, self.max).to_json()
}

///|
pub impl @json.FromJson for Rect with from_json(json, path) {
  let (min, max) : (Vec2, Vec2) = @json.from_json(json, path~)
  Rect::new(min, max)
}
