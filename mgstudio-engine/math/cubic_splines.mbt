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
/// Bevy-aligned cubic spline generators and sampled curve helpers.

///|
pub(all) suberror CubicBezierError {
  MissingControlPointSet
}

///|
pub(all) suberror InsufficientDataError {
  InsufficientData(Int, Int)
}

///|
pub(open) trait SplinePoint {
  zero() -> Self
  add(self : Self, other : Self) -> Self
  sub(self : Self, other : Self) -> Self
  mul_scalar(self : Self, scalar : Float) -> Self
}

///|
pub impl SplinePoint for Float with zero() {
  0.0F
}

///|
pub impl SplinePoint for Float with add(self, other) {
  self + other
}

///|
pub impl SplinePoint for Float with sub(self, other) {
  self - other
}

///|
pub impl SplinePoint for Float with mul_scalar(self, scalar) {
  self * scalar
}

///|
pub impl SplinePoint for Vec2 with zero() {
  Vec2::zero()
}

///|
pub impl SplinePoint for Vec2 with add(self, other) {
  self.add(other)
}

///|
pub impl SplinePoint for Vec2 with sub(self, other) {
  self.sub(other)
}

///|
pub impl SplinePoint for Vec2 with mul_scalar(self, scalar) {
  self.mul_scalar(scalar)
}

///|
pub impl SplinePoint for Vec3 with zero() {
  Vec3::zero()
}

///|
pub impl SplinePoint for Vec3 with add(self, other) {
  self.add(other)
}

///|
pub impl SplinePoint for Vec3 with sub(self, other) {
  self.sub(other)
}

///|
pub impl SplinePoint for Vec3 with mul_scalar(self, scalar) {
  self.mul_scalar(scalar)
}

///|
pub impl SplinePoint for Vec4 with zero() {
  Vec4::new(0.0F, 0.0F, 0.0F, 0.0F)
}

///|
pub impl SplinePoint for Vec4 with add(self, other) {
  Vec4::new(
    self.x + other.x,
    self.y + other.y,
    self.z + other.z,
    self.w + other.w,
  )
}

///|
pub impl SplinePoint for Vec4 with sub(self, other) {
  Vec4::new(
    self.x - other.x,
    self.y - other.y,
    self.z - other.z,
    self.w - other.w,
  )
}

///|
pub impl SplinePoint for Vec4 with mul_scalar(self, scalar) {
  Vec4::new(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar)
}

///|
pub struct LinearSpline[P] {
  control_points : Array[P]
}

///|
pub fn[P] LinearSpline::new(control_points : Array[P]) -> LinearSpline[P] {
  LinearSpline::{ control_points, }
}

///|
pub fn[P : SplinePoint] LinearSpline::to_curve(
  self : LinearSpline[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  if self.control_points.length() < 2 {
    return Err(InsufficientData(2, self.control_points.length()))
  }
  let segment_count = self.control_points.length() - 1
  let segments : Array[CubicSegment[P]] = []
  for index in 0..<segment_count {
    let start = self.control_points[index]
    let end_ = self.control_points[index + 1]
    segments.push(CubicSegment::{
      coeff0: start,
      coeff1: end_.sub(start),
      coeff2: P::zero(),
      coeff3: P::zero(),
    })
  }
  Ok(CubicCurve::{ segments, })
}

///|
pub fn[P : SplinePoint] LinearSpline::to_curve_cyclic(
  self : LinearSpline[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  if self.control_points.length() < 2 {
    return Err(InsufficientData(2, self.control_points.length()))
  }
  let segments : Array[CubicSegment[P]] = []
  for index in 0..<self.control_points.length() {
    let start = self.control_points[index]
    let end_ = self.control_points[(index + 1) % self.control_points.length()]
    segments.push(CubicSegment::{
      coeff0: start,
      coeff1: end_.sub(start),
      coeff2: P::zero(),
      coeff3: P::zero(),
    })
  }
  Ok(CubicCurve::{ segments, })
}

///|
pub struct CubicHermite[P] {
  control_points : Array[(P, P)]
}

///|
pub fn[P] CubicHermite::new(
  control_points : Array[P],
  tangents : Array[P],
) -> CubicHermite[P] {
  let points_and_tangents : Array[(P, P)] = []
  let count = if control_points.length() < tangents.length() {
    control_points.length()
  } else {
    tangents.length()
  }
  for i in 0..<count {
    points_and_tangents.push((control_points[i], tangents[i]))
  }
  CubicHermite::{ control_points: points_and_tangents }
}

///|
pub struct CubicCardinalSpline[P] {
  tension : Float
  control_points : Array[P]
}

///|
pub fn[P] CubicCardinalSpline::new(
  tension : Float,
  control_points : Array[P],
) -> CubicCardinalSpline[P] {
  CubicCardinalSpline::{ tension, control_points }
}

///|
pub fn[P] CubicCardinalSpline::new_catmull_rom(
  control_points : Array[P],
) -> CubicCardinalSpline[P] {
  CubicCardinalSpline::{ tension: 0.5F, control_points }
}

///|
pub struct CubicBSpline[P] {
  control_points : Array[P]
}

///|
pub fn[P] CubicBSpline::new(control_points : Array[P]) -> CubicBSpline[P] {
  CubicBSpline::{ control_points, }
}

///|
pub struct CubicSegment[P] {
  coeff0 : P
  coeff1 : P
  coeff2 : P
  coeff3 : P
}

///|
pub fn[P : SplinePoint] CubicSegment::position(
  self : CubicSegment[P],
  t : Float,
) -> P {
  self.coeff0.add(
    self.coeff1
    .add(self.coeff2.add(self.coeff3.mul_scalar(t)).mul_scalar(t))
    .mul_scalar(t),
  )
}

///|
pub fn[P : SplinePoint] CubicSegment::velocity(
  self : CubicSegment[P],
  t : Float,
) -> P {
  self.coeff1.add(
    self.coeff2
    .mul_scalar(2.0F)
    .add(self.coeff3.mul_scalar(3.0F).mul_scalar(t))
    .mul_scalar(t),
  )
}

///|
pub fn[P : SplinePoint] CubicSegment::acceleration(
  self : CubicSegment[P],
  t : Float,
) -> P {
  self.coeff2.mul_scalar(2.0F).add(self.coeff3.mul_scalar(6.0F * t))
}

///|
pub fn[P : SplinePoint] CubicSegment::new_bezier(
  p0 : P,
  p1 : P,
  p2 : P,
  p3 : P,
) -> CubicSegment[P] {
  cubic_segment_coefficients(
    p0,
    p1,
    p2,
    p3,
    (1.0F, 0.0F, 0.0F, 0.0F),
    (-3.0F, 3.0F, 0.0F, 0.0F),
    (3.0F, -6.0F, 3.0F, 0.0F),
    (-1.0F, 3.0F, -3.0F, 1.0F),
  )
}

///|
pub fn[P] CubicSegment::iter_samples(
  self : CubicSegment[P],
  subdivisions : Int,
  sample : (CubicSegment[P], Float) -> P,
) -> Array[P] {
  let safe_subdivisions = cubic_safe_subdivisions(subdivisions)
  let samples : Array[P] = []
  let denom = cubic_float_from_int(safe_subdivisions)
  for i in 0..<(safe_subdivisions + 1) {
    let t = cubic_float_from_int(i) / denom
    samples.push(sample(self, t))
  }
  samples
}

///|
pub fn[P : SplinePoint] CubicSegment::iter_positions(
  self : CubicSegment[P],
  subdivisions : Int,
) -> Array[P] {
  self.iter_samples(subdivisions, fn(segment, t) { segment.position(t) })
}

///|
pub fn[P : SplinePoint] CubicSegment::iter_velocities(
  self : CubicSegment[P],
  subdivisions : Int,
) -> Array[P] {
  self.iter_samples(subdivisions, fn(segment, t) { segment.velocity(t) })
}

///|
pub fn[P : SplinePoint] CubicSegment::iter_accelerations(
  self : CubicSegment[P],
  subdivisions : Int,
) -> Array[P] {
  self.iter_samples(subdivisions, fn(segment, t) { segment.acceleration(t) })
}

///|
pub struct CubicCurve[P] {
  segments : Array[CubicSegment[P]]
}

///|
pub fn[P] CubicCurve::from_segments(
  segments : Array[CubicSegment[P]],
) -> CubicCurve[P]? {
  if segments.is_empty() {
    None
  } else {
    Some(CubicCurve::{ segments, })
  }
}

///|
pub fn[P] CubicCurve::segments(self : CubicCurve[P]) -> Array[CubicSegment[P]] {
  self.segments
}

///|
pub fn[P] CubicCurve::push_segment(
  self : CubicCurve[P],
  segment : CubicSegment[P],
) -> Unit {
  self.segments.push(segment)
}

///|
pub fn[P : SplinePoint] CubicCurve::position(
  self : CubicCurve[P],
  t : Float,
) -> P {
  let entry = cubic_curve_segment(self, t)
  entry.0.position(entry.1)
}

///|
pub fn[P : SplinePoint] CubicCurve::velocity(
  self : CubicCurve[P],
  t : Float,
) -> P {
  let entry = cubic_curve_segment(self, t)
  entry.0.velocity(entry.1)
}

///|
pub fn[P : SplinePoint] CubicCurve::acceleration(
  self : CubicCurve[P],
  t : Float,
) -> P {
  let entry = cubic_curve_segment(self, t)
  entry.0.acceleration(entry.1)
}

///|
pub fn[P] CubicCurve::iter_samples(
  self : CubicCurve[P],
  subdivisions : Int,
  sample : (CubicCurve[P], Float) -> P,
) -> Array[P] {
  let safe_subdivisions = cubic_safe_subdivisions(subdivisions)
  let samples : Array[P] = []
  let denom = cubic_float_from_int(safe_subdivisions)
  let span = cubic_float_from_int(self.segments.length())
  for i in 0..<(safe_subdivisions + 1) {
    let t = span * cubic_float_from_int(i) / denom
    samples.push(sample(self, t))
  }
  samples
}

///|
pub fn[P : SplinePoint] CubicCurve::iter_positions(
  self : CubicCurve[P],
  subdivisions : Int,
) -> Array[P] {
  self.iter_samples(subdivisions, fn(curve, t) { curve.position(t) })
}

///|
pub fn[P : SplinePoint] CubicCurve::iter_velocities(
  self : CubicCurve[P],
  subdivisions : Int,
) -> Array[P] {
  self.iter_samples(subdivisions, fn(curve, t) { curve.velocity(t) })
}

///|
pub fn[P : SplinePoint] CubicCurve::iter_accelerations(
  self : CubicCurve[P],
  subdivisions : Int,
) -> Array[P] {
  self.iter_samples(subdivisions, fn(curve, t) { curve.acceleration(t) })
}

///|
pub fn[P : SplinePoint] CubicHermite::to_curve(
  self : CubicHermite[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  let count = self.control_points.length()
  if count < 2 {
    return Err(InsufficientData(2, count))
  }
  let segments : Array[CubicSegment[P]] = []
  let row0 = (1.0F, 0.0F, 0.0F, 0.0F)
  let row1 = (0.0F, 1.0F, 0.0F, 0.0F)
  let row2 = (-3.0F, -2.0F, 3.0F, -1.0F)
  let row3 = (2.0F, 1.0F, -2.0F, 1.0F)
  for i in 0..<(count - 1) {
    let pair0 = self.control_points[i]
    let pair1 = self.control_points[i + 1]
    segments.push(
      cubic_segment_coefficients(
        pair0.0,
        pair0.1,
        pair1.0,
        pair1.1,
        row0,
        row1,
        row2,
        row3,
      ),
    )
  }
  Ok(CubicCurve::{ segments, })
}

///|
pub fn[P : SplinePoint] CubicHermite::to_curve_cyclic(
  self : CubicHermite[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  let count = self.control_points.length()
  if count < 2 {
    return Err(InsufficientData(2, count))
  }
  let segments : Array[CubicSegment[P]] = []
  let row0 = (1.0F, 0.0F, 0.0F, 0.0F)
  let row1 = (0.0F, 1.0F, 0.0F, 0.0F)
  let row2 = (-3.0F, -2.0F, 3.0F, -1.0F)
  let row3 = (2.0F, 1.0F, -2.0F, 1.0F)
  for i in 0..<count {
    let pair0 = self.control_points[i]
    let pair1 = self.control_points[(i + 1) % count]
    segments.push(
      cubic_segment_coefficients(
        pair0.0,
        pair0.1,
        pair1.0,
        pair1.1,
        row0,
        row1,
        row2,
        row3,
      ),
    )
  }
  Ok(CubicCurve::{ segments, })
}

///|
pub fn[P : SplinePoint] CubicCardinalSpline::to_curve(
  self : CubicCardinalSpline[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  let count = self.control_points.length()
  if count < 2 {
    return Err(InsufficientData(2, count))
  }
  let p0 = self.control_points[0]
  let p1 = self.control_points[1]
  let last = self.control_points[count - 1]
  let before_last = self.control_points[count - 2]
  let mirrored_first = p0.mul_scalar(2.0F).sub(p1)
  let mirrored_last = last.mul_scalar(2.0F).sub(before_last)
  let row0 = (0.0F, 1.0F, 0.0F, 0.0F)
  let row1 = (-self.tension, 0.0F, self.tension, 0.0F)
  let row2 = (
    2.0F * self.tension,
    self.tension - 3.0F,
    3.0F - 2.0F * self.tension,
    -self.tension,
  )
  let row3 = (
    -self.tension,
    2.0F - self.tension,
    self.tension - 2.0F,
    self.tension,
  )
  let segments : Array[CubicSegment[P]] = []
  for i in 0..<(count - 1) {
    let a = if i == 0 { mirrored_first } else { self.control_points[i - 1] }
    let b = self.control_points[i]
    let c = self.control_points[i + 1]
    let d = if i + 2 < count {
      self.control_points[i + 2]
    } else {
      mirrored_last
    }
    segments.push(
      cubic_segment_coefficients(a, b, c, d, row0, row1, row2, row3),
    )
  }
  Ok(CubicCurve::{ segments, })
}

///|
pub fn[P : SplinePoint] CubicCardinalSpline::to_curve_cyclic(
  self : CubicCardinalSpline[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  let count = self.control_points.length()
  if count < 2 {
    return Err(InsufficientData(2, count))
  }
  let row0 = (0.0F, 1.0F, 0.0F, 0.0F)
  let row1 = (-self.tension, 0.0F, self.tension, 0.0F)
  let row2 = (
    2.0F * self.tension,
    self.tension - 3.0F,
    3.0F - 2.0F * self.tension,
    -self.tension,
  )
  let row3 = (
    -self.tension,
    2.0F - self.tension,
    self.tension - 2.0F,
    self.tension,
  )
  let segments : Array[CubicSegment[P]] = []
  segments.push(
    cubic_segment_coefficients(
      self.control_points[count - 1],
      self.control_points[0],
      self.control_points[1 % count],
      self.control_points[2 % count],
      row0,
      row1,
      row2,
      row3,
    ),
  )
  for i in 0..<(count - 1) {
    segments.push(
      cubic_segment_coefficients(
        self.control_points[i],
        self.control_points[(i + 1) % count],
        self.control_points[(i + 2) % count],
        self.control_points[(i + 3) % count],
        row0,
        row1,
        row2,
        row3,
      ),
    )
  }
  Ok(CubicCurve::{ segments, })
}

///|
pub fn[P : SplinePoint] CubicBSpline::to_curve(
  self : CubicBSpline[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  let count = self.control_points.length()
  if count < 4 {
    return Err(InsufficientData(4, count))
  }
  let row0 = (1.0F / 6.0F, 4.0F / 6.0F, 1.0F / 6.0F, 0.0F)
  let row1 = (-3.0F / 6.0F, 0.0F, 3.0F / 6.0F, 0.0F)
  let row2 = (3.0F / 6.0F, -6.0F / 6.0F, 3.0F / 6.0F, 0.0F)
  let row3 = (-1.0F / 6.0F, 3.0F / 6.0F, -3.0F / 6.0F, 1.0F / 6.0F)
  let segments : Array[CubicSegment[P]] = []
  for i in 0..<(count - 3) {
    segments.push(
      cubic_segment_coefficients(
        self.control_points[i],
        self.control_points[i + 1],
        self.control_points[i + 2],
        self.control_points[i + 3],
        row0,
        row1,
        row2,
        row3,
      ),
    )
  }
  Ok(CubicCurve::{ segments, })
}

///|
pub fn[P : SplinePoint] CubicBSpline::to_curve_cyclic(
  self : CubicBSpline[P],
) -> Result[CubicCurve[P], InsufficientDataError] {
  let count = self.control_points.length()
  if count < 2 {
    return Err(InsufficientData(2, count))
  }
  let row0 = (1.0F / 6.0F, 4.0F / 6.0F, 1.0F / 6.0F, 0.0F)
  let row1 = (-3.0F / 6.0F, 0.0F, 3.0F / 6.0F, 0.0F)
  let row2 = (3.0F / 6.0F, -6.0F / 6.0F, 3.0F / 6.0F, 0.0F)
  let row3 = (-1.0F / 6.0F, 3.0F / 6.0F, -3.0F / 6.0F, 1.0F / 6.0F)
  let segments : Array[CubicSegment[P]] = []
  for i in 0..<count {
    segments.push(
      cubic_segment_coefficients(
        self.control_points[i],
        self.control_points[(i + 1) % count],
        self.control_points[(i + 2) % count],
        self.control_points[(i + 3) % count],
        row0,
        row1,
        row2,
        row3,
      ),
    )
  }
  Ok(CubicCurve::{ segments, })
}

///|
fn[P : SplinePoint] cubic_segment_coefficients(
  p0 : P,
  p1 : P,
  p2 : P,
  p3 : P,
  row0 : (Float, Float, Float, Float),
  row1 : (Float, Float, Float, Float),
  row2 : (Float, Float, Float, Float),
  row3 : (Float, Float, Float, Float),
) -> CubicSegment[P] {
  CubicSegment::{
    coeff0: cubic_matrix_row_value(p0, p1, p2, p3, row0),
    coeff1: cubic_matrix_row_value(p0, p1, p2, p3, row1),
    coeff2: cubic_matrix_row_value(p0, p1, p2, p3, row2),
    coeff3: cubic_matrix_row_value(p0, p1, p2, p3, row3),
  }
}

///|
fn[P : SplinePoint] cubic_matrix_row_value(
  p0 : P,
  p1 : P,
  p2 : P,
  p3 : P,
  row : (Float, Float, Float, Float),
) -> P {
  p0
  .mul_scalar(row.0)
  .add(p1.mul_scalar(row.1))
  .add(p2.mul_scalar(row.2))
  .add(p3.mul_scalar(row.3))
}

///|
fn cubic_safe_subdivisions(subdivisions : Int) -> Int {
  if subdivisions <= 0 {
    1
  } else {
    subdivisions
  }
}

///|
fn cubic_float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn[P] cubic_curve_segment(
  curve : CubicCurve[P],
  t : Float,
) -> (CubicSegment[P], Float) {
  if curve.segments.length() == 1 {
    (curve.segments[0], t)
  } else {
    let floor_index = @coremath.floor(t.to_double()).to_int()
    let clamped_index = cubic_clamp_int(
      floor_index,
      0,
      curve.segments.length() - 1,
    )
    (curve.segments[clamped_index], t - cubic_float_from_int(clamped_index))
  }
}

///|
fn cubic_clamp_int(value : Int, min_value : Int, max_value : Int) -> Int {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}
