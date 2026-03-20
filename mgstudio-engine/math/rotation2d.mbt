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
pub struct Rot2 {
  sin : Float
  cos : Float
}

///|
pub fn Rot2::identity() -> Rot2 {
  Rot2::{ sin: 0.0F, cos: 1.0F }
}

///|
pub fn Rot2::radians(angle : Float) -> Rot2 {
  Rot2::{ sin: sin(angle), cos: cos(angle) }
}

///|
pub fn Rot2::degrees(angle : Float) -> Rot2 {
  Rot2::radians(angle * pi() / 180.0F)
}

///|
pub fn Rot2::as_radians(self : Rot2) -> Float {
  atan2(self.sin, self.cos)
}

///|
pub fn Rot2::inverse(self : Rot2) -> Rot2 {
  Rot2::{ sin: -self.sin, cos: self.cos }
}

///|
pub fn Rot2::mul_vec2(self : Rot2, value : Vec2) -> Vec2 {
  Vec2::new(
    self.cos * value.x - self.sin * value.y,
    self.sin * value.x + self.cos * value.y,
  )
}

///|
pub fn Rot2::mul(self : Rot2, other : Rot2) -> Rot2 {
  Rot2::{
    sin: self.sin * other.cos + self.cos * other.sin,
    cos: self.cos * other.cos - self.sin * other.sin,
  }
}

///|
pub fn Vec2::from_angle(angle : Float) -> Vec2 {
  Vec2::new(cos(angle), sin(angle))
}
