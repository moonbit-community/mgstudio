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
pub struct IVec2 {
  x : Int
  y : Int
}

///|
pub fn IVec2::new(x : Int, y : Int) -> IVec2 {
  IVec2::{ x, y }
}

///|
pub struct UVec2 {
  x : Int
  y : Int
}

///|
pub fn UVec2::new(x : Int, y : Int) -> UVec2 {
  UVec2::{ x, y }
}

///|
pub fn UVec2::splat(value : Int) -> UVec2 {
  UVec2::new(value, value)
}

///|
pub fn UVec2::zero() -> UVec2 {
  UVec2::splat(0)
}

///|
pub fn UVec2::to_vec2(self : UVec2) -> Vec2 {
  Vec2::new(
    Float::from_double(self.x.to_double()),
    Float::from_double(self.y.to_double()),
  )
}

///|
pub fn UVec2::add(self : UVec2, other : UVec2) -> UVec2 {
  UVec2::new(self.x + other.x, self.y + other.y)
}

///|
pub fn UVec2::saturating_sub(self : UVec2, other : UVec2) -> UVec2 {
  let x = if self.x - other.x < 0 { 0 } else { self.x - other.x }
  let y = if self.y - other.y < 0 { 0 } else { self.y - other.y }
  UVec2::new(x, y)
}

///|
pub struct URect {
  min : UVec2
  max : UVec2
}

///|
pub fn URect::new(min : UVec2, max : UVec2) -> URect {
  URect::{ min, max }
}

///|
pub fn URect::size(self : URect) -> UVec2 {
  UVec2::new(self.max.x - self.min.x, self.max.y - self.min.y)
}

///|
pub fn URect::as_rect(self : URect) -> Rect {
  Rect::new(self.min.to_vec2(), self.max.to_vec2())
}

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
pub fn IVec2::add(self : IVec2, other : IVec2) -> IVec2 {
  IVec2::new(self.x + other.x, self.y + other.y)
}

///|
pub fn IVec2::min(self : IVec2, other : IVec2) -> IVec2 {
  let x = if self.x < other.x { self.x } else { other.x }
  let y = if self.y < other.y { self.y } else { other.y }
  IVec2::new(x, y)
}

///|
pub fn IVec2::max(self : IVec2, other : IVec2) -> IVec2 {
  let x = if self.x > other.x { self.x } else { other.x }
  let y = if self.y > other.y { self.y } else { other.y }
  IVec2::new(x, y)
}

///|
pub fn IVec2::saturating_sub(self : IVec2, other : IVec2) -> IVec2 {
  let x = if self.x - other.x < 0 { 0 } else { self.x - other.x }
  let y = if self.y - other.y < 0 { 0 } else { self.y - other.y }
  IVec2::new(x, y)
}

///|
pub fn IVec2::to_vec2(self : IVec2) -> Vec2 {
  Vec2::new(
    Float::from_double(self.x.to_double()),
    Float::from_double(self.y.to_double()),
  )
}

///|
pub fn Vec2::sub(self : Vec2, other : Vec2) -> Vec2 {
  Vec2::new(self.x - other.x, self.y - other.y)
}

///|
pub fn Vec2::to_angle(self : Vec2) -> Float {
  atan2(self.y, self.x)
}

///|
pub fn atan2(y : Float, x : Float) -> Float {
  Float::from_double(@coremath.atan2(y.to_double(), x.to_double()))
}

///|
pub fn cos(value : Float) -> Float {
  Float::from_double(@coremath.cos(value.to_double()))
}

///|
pub fn sin(value : Float) -> Float {
  Float::from_double(@coremath.sin(value.to_double()))
}

///|
pub fn sqrt(value : Float) -> Float {
  @coremath.powf(value, 0.5F)
}

///|
pub fn pow(base : Float, exponent : Float) -> Float {
  Float::from_double(@coremath.pow(base.to_double(), exponent.to_double()))
}

///|
pub fn pi_half() -> Float {
  Float::from_double(@coremath.PI / 2.0)
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
