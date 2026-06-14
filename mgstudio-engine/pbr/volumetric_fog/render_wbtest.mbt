// Copyright 2026 International Digital Economy Academy
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
fn volumetric_fog_wbtest_abs(value : Float) -> Float {
  if value < 0.0F {
    0.0F - value
  } else {
    value
  }
}

///|
fn volumetric_fog_wbtest_approx_eq(lhs : Float, rhs : Float) -> Bool {
  volumetric_fog_wbtest_abs(lhs - rhs) < 0.0001F
}

///|
test "pbr volumetric fog: camera inside volume follows Bevy local cube test" {
  inspect(
    volumetric_fog_camera_is_inside(@math.Affine3::identity()),
    content="true",
  )
  inspect(
    volumetric_fog_camera_is_inside(
      @math.Affine3::from_translation(@math.Vec3::new(0.6F, 0.0F, 0.0F)),
    ),
    content="false",
  )
}

///|
test "pbr volumetric fog: far planes keep only view-facing cube faces" {
  let far_planes = volumetric_fog_far_planes(@math.Affine3::identity())
  inspect(far_planes.length(), content="3")
  inspect(
    volumetric_fog_wbtest_approx_eq(far_planes[0].x, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[0].y, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[0].z, 1.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[0].w, 0.5F),
    content="true",
  )
  inspect(
    volumetric_fog_wbtest_approx_eq(far_planes[1].x, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[1].y, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[1].z, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[1].w, 0.0F),
    content="true",
  )
  inspect(
    volumetric_fog_wbtest_approx_eq(far_planes[2].x, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[2].y, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[2].z, 0.0F) &&
    volumetric_fog_wbtest_approx_eq(far_planes[2].w, 0.0F),
    content="true",
  )
}
