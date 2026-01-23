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
/// Path builder sink interface.
///
/// Ported from upstream `zeno/src/path_builder.rs` (Apache-2.0 OR MIT).
pub(open) trait PathBuilder {
  move_to(Self, Point) -> Unit
  line_to(Self, Point) -> Unit
  quad_to(Self, Point, Point) -> Unit
  curve_to(Self, Point, Point, Point) -> Unit
  close(Self) -> Unit
}

// NOTE: trig functions are provided by `moonbitlang/core/math` (@coremath).

///|
/// Arc size flag (SVG style).
///
/// Ported from upstream `zeno/src/path_builder.rs`.
pub(all) enum ArcSize {
  Small
  Large
}

///|
/// Arc sweep flag (SVG style).
///
/// Ported from upstream `zeno/src/path_builder.rs`.
pub(all) enum ArcSweep {
  Negative
  Positive
}

///|
fn acos(x : Double) -> Double {
  @coremath.acos(x)
}

///|
fn sin(x : Double) -> Double {
  @coremath.sin(x)
}

///|
fn cos(x : Double) -> Double {
  @coremath.cos(x)
}

///|
/// Iterator that generates cubic Beziers for an arc.
///
/// Ported from upstream `zeno/src/path_builder.rs::Arc`.
pub struct Arc {
  mut count : Int
  center : (Double, Double)
  radii : (Double, Double)
  cosphi : Double
  sinphi : Double
  mut ang1 : Double
  ang2 : Double
  a : Double
}

///|
pub fn Arc::default() -> Arc {
  Arc::{
    count: 0,
    center: (0.0, 0.0),
    radii: (0.0, 0.0),
    cosphi: 1.0,
    sinphi: 0.0,
    ang1: 0.0,
    ang2: 0.0,
    a: 0.0,
  }
}

///|
pub fn Arc::new(
  from : Point,
  rx : Double,
  ry : Double,
  angle : Double,
  size : ArcSize,
  sweep : ArcSweep,
  to : Point,
) -> Arc {
  let px = from.x()
  let py = from.y()
  // NOTE: Keep upstream's slightly imprecise TAU constant.
  let tau = 3.141579 * 2.0
  let sinphi = sin(angle)
  let cosphi = cos(angle)
  let pxp = cosphi * (px - to.x()) / 2.0 + sinphi * (py - to.y()) / 2.0
  let pyp = -sinphi * (px - to.x()) / 2.0 + cosphi * (py - to.y()) / 2.0
  if pxp == 0.0 && pyp == 0.0 {
    return Arc::default()
  }
  let mut rx0 = rx.abs()
  let mut ry0 = ry.abs()
  let lambda = pxp * pxp / (rx0 * rx0) + pyp * pyp / (ry0 * ry0)
  if lambda > 1.0 {
    let s = lambda.sqrt()
    rx0 = rx0 * s
    ry0 = ry0 * s
  }
  let large_arc = match size {
    ArcSize::Large => true
    _ => false
  }
  let sweep_pos = match sweep {
    ArcSweep::Positive => true
    _ => false
  }
  fn vec_angle(ux : Double, uy : Double, vx : Double, vy : Double) -> Double {
    let sign = if ux * vy - uy * vx < 0.0 { -1.0 } else { 1.0 }
    let dot0 = ux * vx + uy * vy
    let dot = if dot0 < -1.0 { -1.0 } else if dot0 > 1.0 { 1.0 } else { dot0 }
    sign * acos(dot)
  }

  let rxsq = rx0 * rx0
  let rysq = ry0 * ry0
  let pxpsq = pxp * pxp
  let pypsq = pyp * pyp
  let mut radicant = rxsq * rysq - rxsq * pypsq - rysq * pxpsq
  if radicant < 0.0 {
    radicant = 0.0
  }
  radicant = radicant / (rxsq * pypsq + rysq * pxpsq)
  let sign = if large_arc == sweep_pos { -1.0 } else { 1.0 }
  radicant = radicant.sqrt() * sign
  let cxp = radicant * rx0 / ry0 * pyp
  let cyp = radicant * -ry0 / rx0 * pxp
  let cx = cosphi * cxp - sinphi * cyp + (px + to.x()) / 2.0
  let cy = sinphi * cxp + cosphi * cyp + (py + to.y()) / 2.0
  let vx1 = (pxp - cxp) / rx0
  let vy1 = (pyp - cyp) / ry0
  let vx2 = (-pxp - cxp) / rx0
  let vy2 = (-pyp - cyp) / ry0
  let ang1 = vec_angle(1.0, 0.0, vx1, vy1)
  let mut ang2 = vec_angle(vx1, vy1, vx2, vy2)
  if !sweep_pos && ang2 > 0.0 {
    ang2 = ang2 - tau
  }
  if sweep_pos && ang2 < 0.0 {
    ang2 = ang2 + tau
  }
  let mut ratio = ang2.abs() / (tau / 4.0)
  if (1.0 - ratio).abs() < 0.0000001 {
    ratio = 1.0
  }
  let segments = ratio.ceil()
  let seg0 = if segments < 1.0 { 1.0 } else { segments }
  let count = seg0.to_int()
  ang2 = ang2 / seg0
  let a = if ang2 == @coremath.PI / 2.0 {
    0.551915024494
  } else if ang2 == -(@coremath.PI / 2.0) {
    -0.551915024494
  } else {
    4.0 / 3.0 * @coremath.tan(ang2 / 4.0)
  }
  Arc::{
    count,
    center: (cx, cy),
    radii: (rx0, ry0),
    sinphi,
    cosphi,
    ang1,
    ang2,
    a,
  }
}

///|
pub fn Arc::next(self : Arc) -> Command? {
  if self.count <= 0 {
    return None
  }
  self.count = self.count - 1
  let y1 = sin(self.ang1)
  let x1 = cos(self.ang1)
  let y2 = sin(self.ang1 + self.ang2)
  let x2 = cos(self.ang1 + self.ang2)
  let a = self.a
  let (cx, cy) = self.center
  let (rx, ry) = self.radii
  let sinphi = self.sinphi
  let cosphi = self.cosphi
  let c1 = Point::new((x1 - y1 * a) * rx, (y1 + x1 * a) * ry)
  let c1 = Point::new(
    cx + (cosphi * c1.x() - sinphi * c1.y()),
    cy + (sinphi * c1.x() + cosphi * c1.y()),
  )
  let c2 = Point::new((x2 + y2 * a) * rx, (y2 - x2 * a) * ry)
  let c2 = Point::new(
    cx + (cosphi * c2.x() - sinphi * c2.y()),
    cy + (sinphi * c2.x() + cosphi * c2.y()),
  )
  let p2 = Point::new(x2 * rx, y2 * ry)
  let p2 = Point::new(
    cx + (cosphi * p2.x() - sinphi * p2.y()),
    cy + (sinphi * p2.x() + cosphi * p2.y()),
  )
  self.ang1 = self.ang1 + self.ang2
  Some(Command::CurveTo(c1, c2, p2))
}

///|
/// Emits an elliptical arc as one or more cubic Beziers into the sink.
///
/// Ported from upstream `zeno/src/path_builder.rs::arc`.
pub fn arc(
  sink : &PathBuilder,
  from : Point,
  rx : Double,
  ry : Double,
  angle : Double,
  size : ArcSize,
  sweep : ArcSweep,
  to : Point,
) -> Unit {
  let p = from
  let px = p.x()
  let py = p.y()
  let tau = @coremath.PI * 2.0
  let sinphi = sin(angle)
  let cosphi = cos(angle)
  let pxp = cosphi * (px - to.x()) / 2.0 + sinphi * (py - to.y()) / 2.0
  let pyp = -sinphi * (px - to.x()) / 2.0 + cosphi * (py - to.y()) / 2.0
  if pxp == 0.0 && pyp == 0.0 {
    return
  }
  let mut rx0 = rx.abs()
  let mut ry0 = ry.abs()
  let lambda = pxp * pxp / (rx0 * rx0) + pyp * pyp / (ry0 * ry0)
  if lambda > 1.0 {
    let s = lambda.sqrt()
    rx0 = rx0 * s
    ry0 = ry0 * s
  }
  let large_arc = match size {
    ArcSize::Large => true
    _ => false
  }
  let sweep_pos = match sweep {
    ArcSweep::Positive => true
    _ => false
  }
  fn vec_angle(ux : Double, uy : Double, vx : Double, vy : Double) -> Double {
    let sign = if ux * vy - uy * vx < 0.0 { -1.0 } else { 1.0 }
    let dot0 = ux * vx + uy * vy
    let dot = if dot0 < -1.0 { -1.0 } else if dot0 > 1.0 { 1.0 } else { dot0 }
    sign * acos(dot)
  }

  let rxsq = rx0 * rx0
  let rysq = ry0 * ry0
  let pxpsq = pxp * pxp
  let pypsq = pyp * pyp
  let mut radicant = rxsq * rysq - rxsq * pypsq - rysq * pxpsq
  if radicant < 0.0 {
    radicant = 0.0
  }
  radicant = radicant / (rxsq * pypsq + rysq * pxpsq)
  let sign = if large_arc == sweep_pos { -1.0 } else { 1.0 }
  radicant = radicant.sqrt() * sign
  let cxp = radicant * rx0 / ry0 * pyp
  let cyp = radicant * -ry0 / rx0 * pxp
  let cx = cosphi * cxp - sinphi * cyp + (px + to.x()) / 2.0
  let cy = sinphi * cxp + cosphi * cyp + (py + to.y()) / 2.0
  let vx1 = (pxp - cxp) / rx0
  let vy1 = (pyp - cyp) / ry0
  let vx2 = (-pxp - cxp) / rx0
  let vy2 = (-pyp - cyp) / ry0
  let mut ang1 = vec_angle(1.0, 0.0, vx1, vy1)
  let mut ang2 = vec_angle(vx1, vy1, vx2, vy2)
  if !sweep_pos && ang2 > 0.0 {
    ang2 = ang2 - tau
  }
  if sweep_pos && ang2 < 0.0 {
    ang2 = ang2 + tau
  }
  let mut ratio = ang2.abs() / (tau / 4.0)
  if (1.0 - ratio).abs() < 0.0000001 {
    ratio = 1.0
  }
  let segments0 = ratio.ceil()
  let segments = if segments0 < 1.0 { 1.0 } else { segments0 }
  let seg_count = segments.to_int()
  ang2 = ang2 / segments
  let a = if ang2 == @coremath.PI / 2.0 {
    0.551915024494
  } else if ang2 == -(@coremath.PI / 2.0) {
    -0.551915024494
  } else {
    4.0 / 3.0 * @coremath.tan(ang2 / 4.0)
  }
  for _i in 0..<seg_count {
    let y1 = sin(ang1)
    let x1 = cos(ang1)
    let y2 = sin(ang1 + ang2)
    let x2 = cos(ang1 + ang2)
    let c1 = Point::new((x1 - y1 * a) * rx0, (y1 + x1 * a) * ry0)
    let c1 = Point::new(
      cx + (cosphi * c1.x() - sinphi * c1.y()),
      cy + (sinphi * c1.x() + cosphi * c1.y()),
    )
    let c2 = Point::new((x2 + y2 * a) * rx0, (y2 - x2 * a) * ry0)
    let c2 = Point::new(
      cx + (cosphi * c2.x() - sinphi * c2.y()),
      cy + (sinphi * c2.x() + cosphi * c2.y()),
    )
    let p2 = Point::new(x2 * rx0, y2 * ry0)
    let p2 = Point::new(
      cx + (cosphi * p2.x() - sinphi * p2.y()),
      cy + (sinphi * p2.x() + cosphi * p2.y()),
    )
    sink.curve_to(c1, c2, p2)
    ang1 = ang1 + ang2
  }
}
