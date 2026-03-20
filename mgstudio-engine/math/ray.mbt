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
pub struct Ray2d {
  origin : Vec2
  direction : Dir2
}

///|
pub struct Ray3d {
  origin : Vec3
  direction : Dir3
}

///|
pub fn Ray2d::new(origin : Vec2, direction : Dir2) -> Ray2d {
  Ray2d::{ origin, direction }
}

///|
pub fn Ray2d::get_point(self : Ray2d, distance : Float) -> Vec2 {
  self.origin.add(self.direction.as_vec2().mul_scalar(distance))
}

///|
pub fn Ray3d::new(origin : Vec3, direction : Dir3) -> Ray3d {
  Ray3d::{ origin, direction }
}

///|
pub fn Ray3d::get_point(self : Ray3d, distance : Float) -> Vec3 {
  self.origin.add(self.direction.as_vec3().mul_scalar(distance))
}
