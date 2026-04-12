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
// Bevy source: `bevy/crates/bevy_math/src/cubic_splines/mod.rs`.

///|
pub(all) suberror InsufficientDataError {
  InsufficientData(Int, Int)
}

///|
pub struct CubicSegment[P] {
  inner : @math.CubicSegment[P]
}

///|
pub fn[P] CubicSegment::from_math(
  segment : @math.CubicSegment[P],
) -> CubicSegment[P] {
  CubicSegment::{ inner: segment }
}

///|
pub fn[P] CubicSegment::to_math(
  self : CubicSegment[P],
) -> @math.CubicSegment[P] {
  self.inner
}

///|
pub fn[P : @math.SplinePoint] CubicSegment::new_bezier(
  p0 : P,
  p1 : P,
  p2 : P,
  p3 : P,
) -> CubicSegment[P] {
  CubicSegment::{ inner: @math.CubicSegment::new_bezier(p0, p1, p2, p3) }
}

///|
pub fn[P : @math.SplinePoint] CubicSegment::position(
  self : CubicSegment[P],
  t : Float,
) -> P {
  self.inner.position(t)
}

///|
pub fn[P : @math.SplinePoint] CubicSegment::velocity(
  self : CubicSegment[P],
  t : Float,
) -> P {
  self.inner.velocity(t)
}

///|
pub fn[P : @math.SplinePoint] CubicSegment::acceleration(
  self : CubicSegment[P],
  t : Float,
) -> P {
  self.inner.acceleration(t)
}

///|
pub fn[P : @math.SplinePoint] CubicSegment::iter_positions(
  self : CubicSegment[P],
  subdivisions : Int,
) -> Array[P] {
  self.inner.iter_positions(subdivisions)
}

///|
pub fn[P : @math.SplinePoint] CubicSegment::iter_velocities(
  self : CubicSegment[P],
  subdivisions : Int,
) -> Array[P] {
  self.inner.iter_velocities(subdivisions)
}

///|
pub fn[P : @math.SplinePoint] CubicSegment::iter_accelerations(
  self : CubicSegment[P],
  subdivisions : Int,
) -> Array[P] {
  self.inner.iter_accelerations(subdivisions)
}

///|
pub struct CubicCurve[P] {
  inner : @math.CubicCurve[P]
}

///|
pub fn[P] CubicCurve::from_math(curve : @math.CubicCurve[P]) -> CubicCurve[P] {
  CubicCurve::{ inner: curve }
}

///|
pub fn[P] CubicCurve::to_math(self : CubicCurve[P]) -> @math.CubicCurve[P] {
  self.inner
}

///|
pub fn[P] CubicCurve::from_segments(
  segments : Array[CubicSegment[P]],
) -> CubicCurve[P]? {
  let raw : Array[@math.CubicSegment[P]] = []
  for segment in segments {
    raw.push(segment.to_math())
  }
  match @math.CubicCurve::from_segments(raw) {
    Some(curve) => Some(CubicCurve::{ inner: curve })
    None => None
  }
}

///|
pub fn[P] CubicCurve::segments(self : CubicCurve[P]) -> Array[CubicSegment[P]] {
  let values : Array[CubicSegment[P]] = []
  for segment in self.inner.segments() {
    values.push(CubicSegment::{ inner: segment })
  }
  values
}

///|
pub fn[P] CubicCurve::push_segment(
  self : CubicCurve[P],
  segment : CubicSegment[P],
) -> Unit {
  self.inner.push_segment(segment.to_math())
}

///|
pub fn[P : @math.SplinePoint] CubicCurve::position(
  self : CubicCurve[P],
  t : Float,
) -> P {
  self.inner.position(t)
}

///|
pub fn[P : @math.SplinePoint] CubicCurve::velocity(
  self : CubicCurve[P],
  t : Float,
) -> P {
  self.inner.velocity(t)
}

///|
pub fn[P : @math.SplinePoint] CubicCurve::acceleration(
  self : CubicCurve[P],
  t : Float,
) -> P {
  self.inner.acceleration(t)
}

///|
pub fn[P : @math.SplinePoint] CubicCurve::iter_positions(
  self : CubicCurve[P],
  subdivisions : Int,
) -> Array[P] {
  self.inner.iter_positions(subdivisions)
}

///|
pub fn[P : @math.SplinePoint] CubicCurve::iter_velocities(
  self : CubicCurve[P],
  subdivisions : Int,
) -> Array[P] {
  self.inner.iter_velocities(subdivisions)
}

///|
pub fn[P : @math.SplinePoint] CubicCurve::iter_accelerations(
  self : CubicCurve[P],
  subdivisions : Int,
) -> Array[P] {
  self.inner.iter_accelerations(subdivisions)
}

///|
pub struct LinearSpline[P] {
  inner : @math.LinearSpline[P]
}

///|
pub fn[P] LinearSpline::new(control_points : Array[P]) -> LinearSpline[P] {
  LinearSpline::{ inner: @math.LinearSpline::new(control_points) }
}

///|
pub fn[P : @math.SplinePoint] LinearSpline::to_curve(
  self : LinearSpline[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}

///|
pub fn[P : @math.SplinePoint] LinearSpline::to_curve_cyclic(
  self : LinearSpline[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve_cyclic() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}

///|
pub struct CubicHermite[P] {
  inner : @math.CubicHermite[P]
}

///|
pub fn[P] CubicHermite::new(
  control_points : Array[P],
  tangents : Array[P],
) -> CubicHermite[P] {
  CubicHermite::{ inner: @math.CubicHermite::new(control_points, tangents) }
}

///|
pub fn[P : @math.SplinePoint] CubicHermite::to_curve(
  self : CubicHermite[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}

///|
pub fn[P : @math.SplinePoint] CubicHermite::to_curve_cyclic(
  self : CubicHermite[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve_cyclic() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}

///|
pub struct CubicCardinalSpline[P] {
  inner : @math.CubicCardinalSpline[P]
}

///|
pub fn[P] CubicCardinalSpline::new(
  tension : Float,
  control_points : Array[P],
) -> CubicCardinalSpline[P] {
  CubicCardinalSpline::{
    inner: @math.CubicCardinalSpline::new(tension, control_points),
  }
}

///|
pub fn[P] CubicCardinalSpline::new_catmull_rom(
  control_points : Array[P],
) -> CubicCardinalSpline[P] {
  CubicCardinalSpline::{
    inner: @math.CubicCardinalSpline::new_catmull_rom(control_points),
  }
}

///|
pub fn[P : @math.SplinePoint] CubicCardinalSpline::to_curve(
  self : CubicCardinalSpline[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}

///|
pub fn[P : @math.SplinePoint] CubicCardinalSpline::to_curve_cyclic(
  self : CubicCardinalSpline[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve_cyclic() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}

///|
pub struct CubicBSpline[P] {
  inner : @math.CubicBSpline[P]
}

///|
pub fn[P] CubicBSpline::new(control_points : Array[P]) -> CubicBSpline[P] {
  CubicBSpline::{ inner: @math.CubicBSpline::new(control_points) }
}

///|
pub fn[P : @math.SplinePoint] CubicBSpline::to_curve(
  self : CubicBSpline[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}

///|
pub fn[P : @math.SplinePoint] CubicBSpline::to_curve_cyclic(
  self : CubicBSpline[P],
) -> CubicCurve[P] raise InsufficientDataError {
  let curve = self.inner.to_curve_cyclic() catch {
    @math.InsufficientData(required, actual) =>
      raise InsufficientData(required, actual)
  }
  CubicCurve::{ inner: curve }
}
