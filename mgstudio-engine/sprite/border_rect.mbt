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
pub struct BorderRect {
  left : Float
  right : Float
  top : Float
  bottom : Float
}

///|
pub fn BorderRect::new(
  left : Float,
  right : Float,
  top : Float,
  bottom : Float,
) -> BorderRect {
  BorderRect::{ left, right, top, bottom }
}

///|
pub fn BorderRect::square(value : Float) -> BorderRect {
  BorderRect::{ left: value, right: value, top: value, bottom: value }
}

///|
pub fn BorderRect::default() -> BorderRect {
  BorderRect::square(0.0F)
}
