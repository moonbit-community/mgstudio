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
// Bridge surface to current `Milky2018/mgstudio/math` runtime owner.

///|
pub using @math {type ViewFrustum}

///|
pub const VIEW_FRUSTUM_NEAR_PLANE_IDX : Int = @math.VIEW_FRUSTUM_NEAR_PLANE_IDX

///|
pub const VIEW_FRUSTUM_FAR_PLANE_IDX : Int = @math.VIEW_FRUSTUM_FAR_PLANE_IDX

///|
pub fn view_frustum(half_spaces : Array[@math.HalfSpace]) -> @math.ViewFrustum {
  @math.ViewFrustum::new(half_spaces)
}

///|
pub fn view_frustum_corners(frustum : @math.ViewFrustum) -> Array[@math.Vec3]? {
  frustum.corners()
}
