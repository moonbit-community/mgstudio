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
pub struct IRect {
  min : IVec2
  max : IVec2
}

///|
pub fn IRect::new(min : IVec2, max : IVec2) -> IRect {
  IRect::{ min, max }
}

///|
pub fn IRect::size(self : IRect) -> IVec2 {
  IVec2::new(self.max.x - self.min.x, self.max.y - self.min.y)
}

///|
pub fn IRect::as_rect(self : IRect) -> Rect {
  Rect::new(self.min.to_vec2(), self.max.to_vec2())
}

///|
pub impl ToJson for IRect with to_json(self) {
  (self.min, self.max).to_json()
}

///|
pub impl @json.FromJson for IRect with from_json(json, path) {
  let (min, max) : (IVec2, IVec2) = @json.from_json(json, path~)
  IRect::new(min, max)
}
