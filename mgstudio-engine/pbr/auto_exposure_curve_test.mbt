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
test "render3d: auto exposure compensation curve matches Bevy linear spline defaults" {
  let value = AutoExposureCompensationCurve::from_curve(
    @math.LinearSpline::new([
      @math.Vec2::new(-4.0F, -2.0F),
      @math.Vec2::new(0.0F, 0.0F),
      @math.Vec2::new(2.0F, 0.0F),
      @math.Vec2::new(4.0F, 2.0F),
    ]),
  ) catch {
    _ => abort("expected valid compensation curve")
  }
  inspect(value.min_log_lum, content="-4")
  inspect(value.max_log_lum, content="4")
  inspect(value.min_compensation, content="-2")
  inspect(value.max_compensation, content="2")
  inspect(value.lut.length(), content="256")
}

///|
test "render3d: auto exposure compensation curve rejects non-monotonic points" {
  ignore(
    AutoExposureCompensationCurve::from_curve(
      @math.LinearSpline::new([
        @math.Vec2::new(0.0F, 0.0F),
        @math.Vec2::new(-1.0F, 1.0F),
      ]),
    ) catch {
      NotMonotonic => return inspect(true, content="true")
      _ => return inspect(false, content="true")
    },
  )
  inspect(false, content="true")
}
