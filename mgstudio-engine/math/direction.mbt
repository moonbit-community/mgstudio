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
pub(all) suberror InvalidDirectionError {
  Zero
  Infinite
  NaN
}

///|
pub struct Dir2 {
  value : Vec2
}

///|
pub struct Dir3 {
  value : Vec3
}

///|
pub fn InvalidDirectionError::from_length(
  length : Float,
) -> InvalidDirectionError {
  if length.is_nan() {
    InvalidDirectionError::NaN
  } else if length.is_inf() {
    InvalidDirectionError::Infinite
  } else {
    InvalidDirectionError::Zero
  }
}

///|
pub fn Dir2::new(value : Vec2) -> Result[Dir2, InvalidDirectionError] {
  match Dir2::new_and_length(value) {
    Ok((dir, _)) => Ok(dir)
    Err(error) => Err(error)
  }
}

///|
pub fn Dir2::new_unchecked(value : Vec2) -> Dir2 {
  Dir2::{ value, }
}

///|
pub fn Dir2::new_and_length(
  value : Vec2,
) -> Result[(Dir2, Float), InvalidDirectionError] {
  let length = value.length()
  if length.is_inf() || length <= 0.0F {
    return Err(InvalidDirectionError::from_length(length))
  }
  Ok((Dir2::{ value: value.mul_scalar(1.0F / length) }, length))
}

///|
pub fn Dir2::from_xy(
  x : Float,
  y : Float,
) -> Result[Dir2, InvalidDirectionError] {
  Dir2::new(Vec2::new(x, y))
}

///|
pub fn Dir2::from_xy_unchecked(x : Float, y : Float) -> Dir2 {
  Dir2::new_unchecked(Vec2::new(x, y))
}

///|
pub fn Dir2::from_angle(angle : Float) -> Dir2 {
  Dir2::{ value: Vec2::from_angle(angle) }
}

///|
pub fn Dir2::as_vec2(self : Dir2) -> Vec2 {
  self.value
}

///|
pub fn Dir2::dot(self : Dir2, other : Dir2) -> Float {
  self.value.dot(other.value)
}

///|
pub fn Dir2::x() -> Dir2 {
  Dir2::{ value: Vec2::new(1.0F, 0.0F) }
}

///|
pub fn Dir2::y() -> Dir2 {
  Dir2::{ value: Vec2::new(0.0F, 1.0F) }
}

///|
pub fn Dir3::new(value : Vec3) -> Result[Dir3, InvalidDirectionError] {
  match Dir3::new_and_length(value) {
    Ok((dir, _)) => Ok(dir)
    Err(error) => Err(error)
  }
}

///|
pub fn Dir3::new_unchecked(value : Vec3) -> Dir3 {
  Dir3::{ value, }
}

///|
pub fn Dir3::new_and_length(
  value : Vec3,
) -> Result[(Dir3, Float), InvalidDirectionError] {
  let length = value.length()
  if length.is_inf() || length <= 0.0F {
    return Err(InvalidDirectionError::from_length(length))
  }
  Ok((Dir3::{ value: value.mul_scalar(1.0F / length) }, length))
}

///|
pub fn Dir3::from_xyz(
  x : Float,
  y : Float,
  z : Float,
) -> Result[Dir3, InvalidDirectionError] {
  Dir3::new(Vec3::new(x, y, z))
}

///|
pub fn Dir3::from_xyz_unchecked(x : Float, y : Float, z : Float) -> Dir3 {
  Dir3::new_unchecked(Vec3::new(x, y, z))
}

///|
pub fn Dir3::as_vec3(self : Dir3) -> Vec3 {
  self.value
}

///|
pub fn Dir3::dot(self : Dir3, other : Dir3) -> Float {
  self.value.dot(other.value)
}

///|
pub fn Dir3::x() -> Dir3 {
  Dir3::{ value: Vec3::new(1.0F, 0.0F, 0.0F) }
}

///|
pub fn Dir3::y() -> Dir3 {
  Dir3::{ value: Vec3::new(0.0F, 1.0F, 0.0F) }
}

///|
pub fn Dir3::z() -> Dir3 {
  Dir3::{ value: Vec3::new(0.0F, 0.0F, 1.0F) }
}
