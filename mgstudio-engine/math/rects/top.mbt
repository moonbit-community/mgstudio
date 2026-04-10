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
// Bevy source: `bevy/crates/bevy_math/src/rects/mod.rs`.

///|
pub fn rect(min : @math.Vec2, max : @math.Vec2) -> @math.Rect {
  @math.rect(min, max)
}

///|
pub fn irect(min : @math.IVec2, max : @math.IVec2) -> @math.IRect {
  @math.irect(min, max)
}

///|
pub fn urect(min : @math.UVec2, max : @math.UVec2) -> @math.URect {
  @math.urect(min, max)
}
