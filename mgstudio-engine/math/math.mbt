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
pub struct Vec2 {
  x : Float
  y : Float
}

///|
pub fn Vec2::new(x : Float, y : Float) -> Vec2 {
  Vec2::{ x, y }
}

///|
pub struct Transform {
  translation : Vec2
  rotation : Float
  scale : Vec2
}

///|
pub fn Transform::new(
  translation : Vec2,
  rotation : Float,
  scale : Vec2,
) -> Transform {
  Transform::{ translation, rotation, scale }
}

///|
pub fn Transform::identity() -> Transform {
  Transform::{
    translation: Vec2::new(0.0F, 0.0F),
    rotation: 0.0F,
    scale: Vec2::new(1.0F, 1.0F),
  }
}
