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
fn frustum_test_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d: HalfSpace::intersection_point matches Bevy plane intersection" {
  let xy_at_z_3 = HalfSpace::new(@math.Vec4::new(0.0F, 0.0F, -1.0F, 3.0F))
  let xz_at_y_2 = HalfSpace::new(@math.Vec4::new(0.0F, 1.0F, 0.0F, -2.0F))
  let yz_at_x_1 = HalfSpace::new(@math.Vec4::new(1.0F, 0.0F, 0.0F, -1.0F))
  inspect(
    HalfSpace::intersection_point(xy_at_z_3, xz_at_y_2, yz_at_x_1).map(fn(
      point,
    ) {
      frustum_test_approx_eq(point.x, 1.0F) &&
      frustum_test_approx_eq(point.y, 2.0F) &&
      frustum_test_approx_eq(point.z, 3.0F)
    }),
    content="Some(true)",
  )

  let xz_at_y_3 = HalfSpace::new(@math.Vec4::new(0.0F, 1.0F, 0.0F, -3.0F))
  inspect(
    HalfSpace::intersection_point(xy_at_z_3, xz_at_y_2, xz_at_y_3) is None,
    content="true",
  )
}

///|
test "render3d: ViewFrustum::corners matches Bevy cuboid ordering" {
  let cuboid_frustum = ViewFrustum::new([
    HalfSpace::new(@math.Vec4::new(1.0F, 0.0F, 0.0F, 5.0F)),
    HalfSpace::new(@math.Vec4::new(-1.0F, 0.0F, 0.0F, 4.0F)),
    HalfSpace::new(@math.Vec4::new(0.0F, 0.0F, -1.0F, 3.0F)),
    HalfSpace::new(@math.Vec4::new(0.0F, 0.0F, 1.0F, 2.0F)),
    HalfSpace::new(@math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F)),
    HalfSpace::new(@math.Vec4::new(0.0F, -1.0F, 0.0F, 6.0F)),
  ])
  inspect(
    cuboid_frustum
    .corners()
    .map(fn(corners) {
      corners.length() == 8 &&
      frustum_test_approx_eq(corners[0].x, -5.0F) &&
      frustum_test_approx_eq(corners[0].y, 0.0F) &&
      frustum_test_approx_eq(corners[0].z, 3.0F) &&
      frustum_test_approx_eq(corners[2].x, 4.0F) &&
      frustum_test_approx_eq(corners[2].y, 0.0F) &&
      frustum_test_approx_eq(corners[2].z, -2.0F) &&
      frustum_test_approx_eq(corners[7].x, -5.0F) &&
      frustum_test_approx_eq(corners[7].y, 6.0F) &&
      frustum_test_approx_eq(corners[7].z, -2.0F)
    }),
    content="Some(true)",
  )
}
