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
fn render3d_float_approx_eq(lhs : Float, rhs : Float) -> Bool {
  let delta = lhs - rhs
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
test "render3d: camera color controls apply default physical exposure" {
  let expected = Exposure::default().exposure()
  let (r, g, b) = render3d_apply_camera_color_controls(
    1.0F,
    0.5F,
    0.25F,
    None,
    None,
  )
  inspect(render3d_float_approx_eq(r, expected), content="true")
  inspect(render3d_float_approx_eq(g, expected * 0.5F), content="true")
  inspect(render3d_float_approx_eq(b, expected * 0.25F), content="true")
}

///|
test "render3d: camera color controls use absolute exposure value" {
  let exposure = Exposure::sunlight()
  let expected = exposure.exposure()
  let (r, _g, _b) = render3d_apply_camera_color_controls(
    1.0F,
    0.0F,
    0.0F,
    Some(exposure),
    None,
  )
  inspect(render3d_float_approx_eq(r, expected), content="true")
}
