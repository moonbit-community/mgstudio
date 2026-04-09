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
// Bevy source: `bevy/crates/bevy_math/src/primitives/half_space.rs`.
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub using @math {type HalfSpace}

///|
pub fn half_space(normal_d : @math.Vec4) -> @math.HalfSpace {
  @math.HalfSpace::new(normal_d)
}

///|
pub fn half_space_normal(shape : @math.HalfSpace) -> @math.Vec3 {
  shape.normal()
}

///|
pub fn half_space_d(shape : @math.HalfSpace) -> Float {
  shape.d()
}

///|
pub fn half_space_normal_d(shape : @math.HalfSpace) -> @math.Vec4 {
  shape.normal_d()
}

///|
pub fn half_space_intersection_point(
  a : @math.HalfSpace,
  b : @math.HalfSpace,
  c : @math.HalfSpace,
) -> @math.Vec3? {
  @math.HalfSpace::intersection_point(a, b, c)
}
