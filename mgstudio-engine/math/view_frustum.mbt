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
// Bevy source: `bevy/crates/bevy_math/src/primitives/view_frustum.rs`.
// Runtime owner for frustum primitives.

///|
pub struct ViewFrustum {
  half_spaces : Array[HalfSpace]
} derive(Eq, ToJson, FromJson)

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = 4

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = 5

///|
pub fn ViewFrustum::new(half_spaces : Array[HalfSpace]) -> ViewFrustum {
  view_frustum_assert_half_spaces(half_spaces)
  ViewFrustum::{ half_spaces, }
}

///|
pub fn ViewFrustum::corners(self : ViewFrustum) -> Array[Vec3]? {
  view_frustum_assert_half_spaces(self.half_spaces)
  let left = self.half_spaces[0]
  let right = self.half_spaces[1]
  let top = self.half_spaces[2]
  let bottom = self.half_spaces[3]
  let near = self.half_spaces[4]
  let far = self.half_spaces[5]
  guard HalfSpace::intersection_point(top, left, near) is Some(near_top_left) else {
    return None
  }
  guard HalfSpace::intersection_point(top, right, near) is Some(near_top_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, right, near)
    is Some(near_bottom_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, left, near)
    is Some(near_bottom_left) else {
    return None
  }
  guard HalfSpace::intersection_point(top, left, far) is Some(far_top_left) else {
    return None
  }
  guard HalfSpace::intersection_point(top, right, far) is Some(far_top_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, right, far)
    is Some(far_bottom_right) else {
    return None
  }
  guard HalfSpace::intersection_point(bottom, left, far)
    is Some(far_bottom_left) else {
    return None
  }
  Some([
    near_top_left, near_top_right, near_bottom_right, near_bottom_left, far_top_left,
    far_top_right, far_bottom_right, far_bottom_left,
  ])
}

///|
fn view_frustum_assert_half_spaces(half_spaces : Array[HalfSpace]) -> Unit {
  if half_spaces.length() != 6 {
    abort("ViewFrustum requires exactly 6 half spaces")
  }
}
