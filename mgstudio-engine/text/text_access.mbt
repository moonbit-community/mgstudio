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
// Bevy source: `bevy/crates/bevy_text/src/text_access.rs`.
// Runtime wrappers live in this file while the broader text implementation stays split across the package.

///|
pub struct TextHandle {
  id : Int
}

///|
pub fn TextHandle::new(id : Int) -> TextHandle {
  TextHandle::{ id, }
}

///|
pub fn TextHandle::id(self : TextHandle) -> Int {
  self.id
}

///|
pub struct TextSpanHandle {
  id : Int
}

///|
pub fn TextSpanHandle::new(id : Int) -> TextSpanHandle {
  TextSpanHandle::{ id, }
}

///|
pub fn text_content(handle : TextHandle) -> String? {
  text_get_content(handle)
}

///|
pub fn text_layout_size(handle : TextHandle) -> @math.Vec2? {
  text_get_layout_size(handle)
}

///|
pub fn text_visual_bounds(handle : TextHandle) -> @math.Rect? {
  text_get_visual_bounds(handle)
}
