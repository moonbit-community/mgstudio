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
fn approx_float(actual : Float, expected : Float) -> Unit {
  let delta = actual - expected
  let abs_delta = if delta < 0.0F { -delta } else { delta }
  if abs_delta >= 0.0001F {
    abort("expected \{expected}, got \{actual}")
  }
}

///|
fn approx_vec2(actual : Vec2, expected : Vec2) -> Unit {
  approx_float(actual.x, expected.x)
  approx_float(actual.y, expected.y)
}

///|
test "math: cubic hermite passes through endpoints" {
  let spline = CubicHermite::new(
    [Vec2::new(0.0F, 0.0F), Vec2::new(2.0F, 1.0F)],
    [Vec2::new(1.0F, 0.0F), Vec2::new(1.0F, 0.0F)],
  )
  let curve = spline.to_curve() catch { _ => abort("expected hermite curve") }
  inspect(curve.segments().length(), content="1")
  approx_vec2(curve.position(0.0F), Vec2::new(0.0F, 0.0F))
  approx_vec2(curve.position(1.0F), Vec2::new(2.0F, 1.0F))
}

///|
test "math: catmull-rom cardinal spline interpolates every control point" {
  let spline = CubicCardinalSpline::new_catmull_rom([
    Vec2::new(0.0F, 0.0F),
    Vec2::new(1.0F, 0.0F),
    Vec2::new(2.0F, 0.0F),
    Vec2::new(3.0F, 0.0F),
  ])
  let curve = spline.to_curve() catch { _ => abort("expected cardinal curve") }
  inspect(curve.segments().length(), content="3")
  approx_vec2(curve.position(0.0F), Vec2::new(0.0F, 0.0F))
  approx_vec2(curve.position(1.0F), Vec2::new(1.0F, 0.0F))
  approx_vec2(curve.position(2.0F), Vec2::new(2.0F, 0.0F))
  approx_vec2(curve.position(3.0F), Vec2::new(3.0F, 0.0F))
}

///|
test "math: cyclic catmull-rom keeps first segment on first control edge" {
  let spline = CubicCardinalSpline::new_catmull_rom([
    Vec2::new(0.0F, 0.0F),
    Vec2::new(1.0F, 0.0F),
    Vec2::new(2.0F, 0.0F),
    Vec2::new(3.0F, 0.0F),
  ])
  let curve = spline.to_curve_cyclic() catch {
    _ => abort("expected cyclic cardinal curve")
  }
  inspect(curve.segments().length(), content="4")
  approx_vec2(curve.position(0.0F), Vec2::new(0.0F, 0.0F))
  approx_vec2(curve.position(1.0F), Vec2::new(1.0F, 0.0F))
}

///|
test "math: cubic b-spline uses Bevy-aligned uniform endpoint positions" {
  let spline = CubicBSpline::new([
    Vec2::new(0.0F, 0.0F),
    Vec2::new(1.0F, 0.0F),
    Vec2::new(2.0F, 0.0F),
    Vec2::new(3.0F, 0.0F),
  ])
  let curve = spline.to_curve() catch { _ => abort("expected b-spline curve") }
  inspect(curve.segments().length(), content="1")
  approx_vec2(curve.position(0.0F), Vec2::new(1.0F, 0.0F))
  approx_vec2(curve.position(1.0F), Vec2::new(2.0F, 0.0F))
}

///|
test "math: cubic curve iter_positions includes both endpoints" {
  let spline = CubicHermite::new(
    [Vec2::new(0.0F, 0.0F), Vec2::new(1.0F, 0.0F)],
    [Vec2::new(1.0F, 0.0F), Vec2::new(1.0F, 0.0F)],
  )
  let curve = spline.to_curve() catch { _ => abort("expected hermite curve") }
  let samples = curve.iter_positions(4)
  inspect(samples.length(), content="5")
  approx_vec2(samples[0], Vec2::new(0.0F, 0.0F))
  approx_vec2(samples[samples.length() - 1], Vec2::new(1.0F, 0.0F))
}

///|
test "math: cubic b-spline reports insufficient data for fewer than four points" {
  let spline = CubicBSpline::new([
    Vec2::new(0.0F, 0.0F),
    Vec2::new(1.0F, 0.0F),
    Vec2::new(2.0F, 0.0F),
  ])
  ignore(
    spline.to_curve() catch {
      InsufficientData(expected, given) => {
        inspect(expected, content="4")
        inspect(given, content="3")
        return
      }
    },
  )
  abort("expected insufficient data")
}
