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
fn affine3_test_approx_eq(a : Float, b : Float) -> Bool {
  let diff = a - b
  let abs = if diff < 0.0F { -diff } else { diff }
  abs < 0.0001F
}

///|
test "math: affine decomposition preserves negative determinant scale" {
  let affine = Affine3::from_mat3_translation(
    Mat3::from_cols(
      Vec3::new(1.0F, 0.0F, 0.0F),
      Vec3::new(0.0F, 1.0F, 0.0F),
      Vec3::new(0.0F, 0.0F, -1.0F),
    ),
    Vec3::new(2.0F, 3.0F, 4.0F),
  )
  let (scale, _rotation, translation) = affine.to_scale_rotation_translation()
  inspect(
    affine3_test_approx_eq(scale.x, -1.0F) &&
    affine3_test_approx_eq(scale.y, -1.0F) &&
    affine3_test_approx_eq(scale.z, -1.0F) &&
    affine3_test_approx_eq(translation.x, 2.0F) &&
    affine3_test_approx_eq(translation.y, 3.0F) &&
    affine3_test_approx_eq(translation.z, 4.0F),
    content="true",
  )
}
