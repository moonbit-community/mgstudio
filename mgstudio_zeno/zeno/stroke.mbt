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
/// Stroking and dashing of paths.
///
/// Ported from upstream `zeno/src/stroke.rs` (Apache-2.0 OR MIT).

///|
pub fn stroke_into(
  commands : Iter[Command],
  style : Stroke,
  sink : &PathBuilder,
) -> Unit {
  let stroker = Stroker::new(segments(commands, true), sink, style)
  let (dashes, dash_offset, empty_gaps) = validate_dashes(
    style.dashes,
    style.offset,
  )
  let segment_buf : Array[Segment] = []
  if dashes.length() > 0 {
    stroker.dash(segment_buf, dashes, dash_offset, empty_gaps)
  } else {
    stroker.stroke(segment_buf)
  }
}

///|
pub fn stroke_with_storage(
  commands : Iter[Command],
  style : Stroke,
  sink : &PathBuilder,
  storage : Array[Segment],
) -> Unit {
  let stroker = Stroker::new(segments(commands, true), sink, style)
  let (dashes, dash_offset, empty_gaps) = validate_dashes(
    style.dashes,
    style.offset,
  )
  if dashes.length() > 0 {
    stroker.dash(storage, dashes, dash_offset, empty_gaps)
  } else {
    stroker.stroke(storage)
  }
}

///|
priv struct Stroker {
  source : Segments
  sink : &PathBuilder
  radius : Double
  radius_abs : Double
  join : Join
  inv_miter_limit : Double
  start_cap : Cap
  end_cap : Cap
}

///|
fn Stroker::new(
  source : Segments,
  sink : &PathBuilder,
  style : Stroke,
) -> Stroker {
  let w = style.width
  let radius = (if w > 0.01 { w } else { 0.01 }) * 0.5
  Stroker::{
    source,
    sink,
    radius,
    radius_abs: radius.abs(),
    join: style.join,
    inv_miter_limit: if style.miter_limit >= 1.0 {
      1.0 / style.miter_limit
    } else {
      1.0
    },
    start_cap: style.start_cap,
    end_cap: style.end_cap,
  }
}

///|
fn is_butt(cap : Cap) -> Bool {
  match cap {
    Cap::Butt => true
    _ => false
  }
}

///|
fn collect(storage : Array[Segment], it : Segments) -> (Bool, Bool) {
  storage.clear()
  let mut is_closed = false
  let mut done = false
  while true {
    match it.next() {
      Some(seg) =>
        match seg {
          Segment::End(closed) => {
            is_closed = closed
            break
          }
          _ => storage.push(seg)
        }
      None => {
        done = true
        break
      }
    }
  }
  (is_closed, done)
}

///|
fn Stroker::stroke(self : Stroker, segment_buf : Array[Segment]) -> Unit {
  while true {
    let (closed, done) = collect(segment_buf, self.source)
    self.stroke_segments(segment_buf, closed)
    if done {
      break
    }
  }
}

///|
fn Stroker::stroke_segments(
  self : Stroker,
  segments0 : Array[Segment],
  is_closed : Bool,
) -> Unit {
  let len = segments0.length()
  if len == 0 {
    return
  }
  if len == 1 &&
    segments0[0].length() == 0.0 &&
    (!is_butt(self.start_cap) || !is_butt(self.end_cap)) {
    let seg = segments0[0]
    let from = match seg {
      Segment::Line(_, l) => l.a
      Segment::Curve(_, c) => c.a
      Segment::End(_) => Vector::zero()
    }
    let n = Vector::new(0.0, 1.0)
    let nr = n.scale(self.radius)
    let start = from + nr
    let rstart = from - nr
    self.sink.move_to(start)
    self.add_end_cap(start, rstart, n)
    self.add_start_cap(rstart, start, -n)
    return
  }
  let radius = self.radius
  let mut last_dir = Vector::zero()
  let mut first_point = Vector::zero()
  let mut last_point = Vector::zero()
  let mut pivot = Vector::zero()
  let mut last_id = 0xFF
  if is_closed {
    let segment = segments0[len - 1].offset(radius)
    pivot = segment.end_pivot
    last_dir = segment.end_normal
    last_point = segment.end
    first_point = last_point
    self.sink.move_to(last_point)
  }
  let mut is_first = !is_closed
  for seg0 in segments0 {
    let segment = seg0.offset(radius)
    let id = segment.id
    let start = segment.start
    if is_first {
      self.sink.move_to(start)
      first_point = start
      is_first = false
    } else {
      self.add_join(last_point, start, pivot, last_dir, segment.start_normal)
      |> ignore
    }
    last_id = id
    last_dir = segment.end_normal
    pivot = segment.end_pivot
    last_point = self.emit(segment.segment)
  }
  is_first = true
  for i in 0..<len {
    let seg0 = segments0[len - 1 - i]
    let segment = seg0.reverse().offset(radius)
    let id = segment.id
    let start = segment.start
    if is_first {
      if is_closed {
        let init = segments0[0].reverse().offset(radius)
        last_point = init.end
        last_dir = init.end_normal
        pivot = init.end_pivot
        self.sink.line_to(init.end)
        self.add_join(last_point, start, pivot, last_dir, segment.start_normal)
        |> ignore
      } else {
        self.add_end_cap(last_point, start, last_dir)
      }
      is_first = false
    } else if id != last_id {
      self.add_join(last_point, start, pivot, last_dir, segment.start_normal)
      |> ignore
    } else {
      self.add_split_join(
        last_point,
        start,
        pivot,
        last_dir,
        segment.start_normal,
      )
      |> ignore
    }
    last_id = id
    last_dir = segment.end_normal
    pivot = segment.end_pivot
    last_point = self.emit(segment.segment)
  }
  if !is_closed {
    self.add_start_cap(last_point, first_point, last_dir)
  }
  self.sink.close()
}

///|
fn Stroker::dash(
  self : Stroker,
  segment_buf : Array[Segment],
  dashes : Array[Double],
  offset : Double,
  empty_gaps : Bool,
) -> Unit {
  let dasher = Dasher::default()
  dasher.empty_gaps = empty_gaps
  let mut done = false
  while !done {
    let (is_closed, is_done) = collect(segment_buf, self.source)
    done = is_done
    if segment_buf.length() == 0 {
      continue
    }
    dasher.init(is_closed, dashes, offset)
    while true {
      match dasher.next(segment_buf, dashes) {
        DashOp::Done => break
        DashOp::Continue => ()
        DashOp::Emit => {
          let (start, end) = dasher.range
          let (t0, t1) = dasher.trange
          self.dash_segments(segment_buf, start, end, t0, t1)
        }
        DashOp::Stroke => {
          self.stroke_segments(segment_buf, true)
          break
        }
      }
    }
  }
}

///|
fn Stroker::dash_segments(
  self : Stroker,
  segments0 : Array[Segment],
  start : Int,
  end : Int,
  t0 : Double,
  t1 : Double,
) -> Unit {
  let radius = self.radius
  if t0 == t1 && start == end {
    if is_butt(self.start_cap) && is_butt(self.end_cap) {
      return
    }
    let (t0a, t1a) = if t0 >= 1.0 { (t0 - 0.001, t0) } else { (t0, t0 + 0.001) }
    let segment = get_signed(segments0, start).slice(t0a, t1a).offset(radius)
    let startp = segment.start
    let rstart = segment.start - segment.start_normal.scale(2.0 * radius)
    self.sink.move_to(startp)
    self.add_end_cap(startp, rstart, segment.start_normal)
    self.add_start_cap(rstart, startp, -segment.start_normal)
    self.sink.close()
    return
  }
  let mut last_dir = Vector::zero()
  let mut first_point = Vector::zero()
  let mut last_point = Vector::zero()
  let mut pivot = Vector::zero()
  let mut is_first = true
  let mut last_id = 0xFF
  let mut i = start
  while i <= end {
    let t0i = if i == start { t0 } else { 0.0 }
    let t1i = if i == end { t1 } else { 1.0 }
    if t0i >= 1.0 {
      i = i + 1
      continue
    }
    let segment = get_signed(segments0, i).slice(t0i, t1i).offset(radius)
    let id = segment.id
    let startp = segment.start
    if is_first {
      self.sink.move_to(startp)
      first_point = startp
      is_first = false
    } else if id != last_id {
      self.add_join(last_point, startp, pivot, last_dir, segment.start_normal)
      |> ignore
    } else {
      self.add_split_join(
        last_point,
        startp,
        pivot,
        last_dir,
        segment.start_normal,
      )
      |> ignore
    }
    last_id = id
    pivot = segment.end_pivot
    last_dir = segment.end_normal
    last_point = self.emit(segment.segment)
    i = i + 1
  }
  is_first = true
  last_id = 0xFF
  i = end
  while i >= start {
    let t0i = if i == start { t0 } else { 0.0 }
    let t1i = if i == end { t1 } else { 1.0 }
    if t0i >= 1.0 {
      i = i - 1
      continue
    }
    let segment = get_signed(segments0, i)
      .slice(t0i, t1i)
      .reverse()
      .offset(radius)
    let id = segment.id
    let startp = segment.start
    if is_first {
      self.add_end_cap(last_point, startp, last_dir)
      is_first = false
    } else if id != last_id {
      self.add_join(last_point, startp, pivot, last_dir, segment.start_normal)
      |> ignore
    } else {
      self.add_split_join(
        last_point,
        startp,
        pivot,
        last_dir,
        segment.start_normal,
      )
      |> ignore
    }
    last_id = id
    pivot = segment.end_pivot
    last_dir = segment.end_normal
    last_point = self.emit(segment.segment)
    i = i - 1
  }
  self.add_start_cap(last_point, first_point, last_dir)
  self.sink.close()
}

///|
fn Stroker::emit(self : Stroker, segment : Segment) -> Point {
  match segment {
    Segment::Line(_, line) => {
      self.sink.line_to(line.b)
      line.b
    }
    Segment::Curve(_, curve) => {
      self.sink.curve_to(curve.b, curve.c, curve.d)
      curve.d
    }
    Segment::End(_) => Vector::zero()
  }
}

///|
fn is_clockwise(a : Vector, b : Vector) -> Bool {
  a.x() * b.y() > a.y() * b.x()
}

///|
fn Stroker::add_join(
  self : Stroker,
  from : Point,
  to : Point,
  pivot : Point,
  from_normal : Vector,
  to_normal : Vector,
) -> Point {
  if from.nearly_eq(to) {
    return from
  }
  if !is_clockwise(from_normal, to_normal) {
    self.sink.line_to(pivot)
    self.sink.line_to(to)
    return to
  }
  match self.join {
    Join::Bevel => {
      self.sink.line_to(to)
      to
    }
    Join::Round => {
      let r = self.radius_abs
      arc(self.sink, from, r, r, 0.0, ArcSize::Small, ArcSweep::Positive, to)
      to
    }
    Join::Miter => {
      let dot = from_normal.dot(to_normal)
      let sin_half = ((1.0 + dot) * 0.5).sqrt()
      if dot < 0.0 || sin_half < self.inv_miter_limit {
        self.sink.line_to(to)
        to
      } else {
        let mid = (from_normal + to_normal)
          .normalize()
          .scale(self.radius / sin_half)
        let p = pivot + mid
        self.sink.line_to(p)
        self.sink.line_to(to)
        to
      }
    }
  }
}

///|
fn Stroker::add_split_join(
  self : Stroker,
  from : Point,
  to : Point,
  pivot : Point,
  from_normal : Vector,
  to_normal : Vector,
) -> Point {
  if from.nearly_eq(to) {
    return from
  }
  if !is_clockwise(from_normal, to_normal) {
    self.sink.line_to(pivot)
    self.sink.line_to(to)
    return to
  }
  let r = self.radius_abs
  arc(self.sink, from, r, r, 0.0, ArcSize::Small, ArcSweep::Positive, to)
  to
}

///|
fn Stroker::add_cap(
  self : Stroker,
  from : Point,
  to : Point,
  dir : Vector,
  cap : Cap,
) -> Unit {
  match cap {
    Cap::Butt => self.sink.line_to(to)
    Cap::Square => {
      let d = Vector::new(-dir.y(), dir.x())
      self.sink.line_to(from + d.scale(self.radius_abs))
      self.sink.line_to(to + d.scale(self.radius_abs))
    }
    Cap::Round => {
      let r = self.radius_abs
      arc(self.sink, from, r, r, 0.0, ArcSize::Small, ArcSweep::Positive, to)
    }
  }
}

///|
fn Stroker::add_start_cap(
  self : Stroker,
  from : Point,
  to : Point,
  dir : Vector,
) -> Unit {
  self.add_cap(from, to, dir, self.start_cap)
}

///|
fn Stroker::add_end_cap(
  self : Stroker,
  from : Point,
  to : Point,
  dir : Vector,
) -> Unit {
  self.add_cap(from, to, dir, self.end_cap)
}

///|
priv enum DashOp {
  Done
  Continue
  Emit
  Stroke
}

///|
priv struct Dasher {
  mut done : Bool
  mut is_closed : Bool
  mut empty_gaps : Bool
  mut on : Bool
  mut cur : Int
  mut t0 : Double
  mut t0_offset : Double
  mut index : Int
  mut is_first : Bool
  mut first_on : Bool
  mut first_dash : Double
  mut range : (Int, Int)
  mut trange : (Double, Double)
}

///|
fn Dasher::default() -> Dasher {
  Dasher::{
    done: false,
    is_closed: false,
    empty_gaps: false,
    on: true,
    cur: 0,
    t0: 0.0,
    t0_offset: 0.0,
    index: 0,
    is_first: true,
    first_on: true,
    first_dash: 0.0,
    range: (0, 0),
    trange: (0.0, 0.0),
  }
}

///|
fn Dasher::init(
  self : Dasher,
  is_closed : Bool,
  dashes : Array[Double],
  offset : Double,
) -> Unit {
  self.done = false
  self.is_closed = is_closed
  self.on = true
  self.cur = 0
  self.t0 = 0.0
  self.t0_offset = 0.0
  self.index = 0
  self.is_first = true
  self.first_on = true
  let mut first_dash = self.next_dash(dashes)
  if offset > 0.0 {
    let mut accum = first_dash
    while accum < offset {
      self.on = !self.on
      accum = accum + self.next_dash(dashes)
    }
    self.first_on = self.on
    first_dash = accum - offset
  }
  self.first_dash = first_dash
}

///|
fn Dasher::next_dash(self : Dasher, dashes : Array[Double]) -> Double {
  let len = dashes.length()
  let mut dash = dashes[self.index % len]
  if self.on && self.empty_gaps {
    while true {
      let next_dash = dashes[(self.index + 1) % len]
      if next_dash != 0.0 {
        break
      }
      self.index = self.index + 2
      dash = dash + dashes[self.index % len]
    }
  }
  self.index = self.index + 1
  dash
}

///|
fn Dasher::next_segments(
  dash : Double,
  segments0 : Array[Segment],
  limit : Int,
  start : Int,
  start_offset : Double,
) -> (Bool, Int, Double, Double) {
  let mut cur = start
  let mut goal = dash + start_offset
  let mut segment = get_signed(segments0, cur)
  while true {
    let td = segment.time(goal, 1.0)
    let dist = td.distance
    let t2 = td.time
    goal = goal - dist
    if goal <= 0.0 {
      return (true, cur, dist, t2)
    }
    if cur + 1 >= limit {
      return (false, cur, dist, t2)
    }
    cur = cur + 1
    segment = get_signed(segments0, cur)
  }
  (false, start, 0.0, 0.0)
}

///|
fn Dasher::next(
  self : Dasher,
  segments0 : Array[Segment],
  dashes : Array[Double],
) -> DashOp {
  if self.done {
    return DashOp::Done
  }
  let first = self.is_first
  let first_and_closed = first && self.is_closed
  let mut dash = if first { self.first_dash } else { self.next_dash(dashes) }
  let mut on = self.on
  let mut start = self.cur
  let limit = segments0.length()
  if self.t0 == 1.0 && start < limit - 1 {
    start = start + 1
    self.t0 = 0.0
    self.t0_offset = 0.0
    self.cur = start
  }
  let (cont, end0, t1_offset0, t10) = if dash == 0.0 {
    (true, start, self.t0_offset, self.t0)
  } else {
    Dasher::next_segments(dash, segments0, limit, start, self.t0_offset)
  }
  let mut end = end0
  let mut t1_offset = t1_offset0
  let mut t1 = t10
  if !cont {
    self.done = true
  }
  if self.done && self.is_closed {
    if on {
      if first_and_closed {
        return DashOp::Stroke
      }
      if self.first_on {
        self.cur = start - limit
        start = self.cur
        let (_, end2, end_offset, end_t) = Dasher::next_segments(
          self.first_dash,
          segments0,
          limit,
          0,
          0.0,
        )
        end = end2
        t1_offset = end_offset
        t1 = end_t
      }
    } else {
      if !self.first_on {
        return DashOp::Done
      }
      dash = self.first_dash
      self.cur = 0
      self.t0 = 0.0
      self.t0_offset = 0.0
      self.on = true
      on = true
      start = self.cur
      let (_, end2, end_offset, end_t) = Dasher::next_segments(
        self.first_dash,
        segments0,
        limit,
        0,
        0.0,
      )
      end = end2
      t1_offset = end_offset
      t1 = end_t
    }
  } else if self.done && !on {
    return DashOp::Done
  }
  let t0 = self.t0
  self.is_first = false
  self.cur = end
  self.t0 = t1
  self.t0_offset = t1_offset
  self.on = !self.on
  if on && !first_and_closed {
    self.range = (start, end)
    self.trange = (t0, t1)
    return DashOp::Emit
  }
  DashOp::Continue
}

///|
fn validate_dashes(
  dashes : Array[Double],
  offset : Double,
) -> (Array[Double], Double, Bool) {
  let len = dashes.length()
  if len > 0 {
    let mut small_count = 0
    let mut gap_sum = 0.0
    let mut empty_gaps = false
    let is_odd = (len & 1) != 0
    for i in 0..<len {
      let dash = dashes[i]
      let is_gap = (i & 1) == 1
      if dash < 1.0 {
        small_count = small_count + 1
        if dash < 0.0 {
          return ([], 0.0, false)
        } else if dash == 0.0 && (is_gap || is_odd) {
          empty_gaps = true
        }
      } else if is_gap {
        gap_sum = gap_sum + dash
      }
    }
    if len == 1 {
      gap_sum = 1.0
    }
    if small_count < len && gap_sum > 0.0 {
      let offset2 = if offset != 0.0 {
        let mut s = 0.0
        for i in 0..<len {
          s = s + dashes[i]
        }
        if is_odd {
          s = s * 2.0
        }
        if offset < 0.0 {
          s - offset.abs() % s
        } else {
          offset % s
        }
      } else {
        0.0
      }
      return (dashes, offset2, empty_gaps)
    }
  }
  ([], 0.0, false)
}

///|
fn get_signed(segments0 : Array[Segment], index : Int) -> Segment {
  let idx = if index < 0 { segments0.length() - -index } else { index }
  segments0[idx]
}

///|
fn Segment::offset(self : Segment, radius : Double) -> OffsetSegment {
  OffsetSegment::new(self, radius)
}

///|
priv struct OffsetSegment {
  segment : Segment
  id : SegmentId
  start : Point
  end : Point
  start_normal : Vector
  end_normal : Vector
  end_pivot : Point
}

///|
fn OffsetSegment::new(segment : Segment, radius : Double) -> OffsetSegment {
  match segment {
    Segment::Line(id, line) => {
      let n = normal(line.a, line.b)
      let nr = n.scale(radius)
      let start = line.a + nr
      let end = line.b + nr
      OffsetSegment::{
        segment: Segment::Line(id, Line::new(start, end)),
        id,
        start,
        end,
        start_normal: n,
        end_normal: n,
        end_pivot: line.b,
      }
    }
    Segment::Curve(id, c) => {
      let eps = 0.5
      let normal_ab = if c.a.nearly_eq_by(c.b, eps) {
        if c.a.nearly_eq_by(c.c, eps) {
          normal(c.a, c.d)
        } else {
          normal(c.a, c.c)
        }
      } else {
        normal(c.a, c.b)
      }
      let normal_bc = if c.b.nearly_eq_by(c.c, eps) {
        if c.b.nearly_eq_by(c.d, eps) {
          normal(c.a, c.d)
        } else {
          normal(c.b, c.d)
        }
      } else {
        normal(c.b, c.c)
      }
      let normal_cd = if c.c.nearly_eq_by(c.d, eps) {
        if c.b.nearly_eq_by(c.d, eps) {
          normal(c.a, c.d)
        } else {
          normal(c.b, c.d)
        }
      } else {
        normal(c.c, c.d)
      }
      let mut normal_b = normal_ab + normal_bc
      let mut normal_c = normal_cd + normal_bc
      let dot0 = normal_ab.dot(normal_bc)
      normal_b = normal_b
        .normalize()
        .scale(radius / ((1.0 + dot0) * 0.5).sqrt())
      let dot1 = normal_cd.dot(normal_bc)
      normal_c = normal_c
        .normalize()
        .scale(radius / ((1.0 + dot1) * 0.5).sqrt())
      let start = c.a + normal_ab.scale(radius)
      let end = c.d + normal_cd.scale(radius)
      OffsetSegment::{
        segment: Segment::Curve(
          id,
          Curve::new(start, c.b + normal_b, c.c + normal_c, end),
        ),
        id,
        start,
        end,
        start_normal: normal_ab,
        end_normal: normal_cd,
        end_pivot: c.d,
      }
    }
    Segment::End(closed) =>
      OffsetSegment::{
        segment: Segment::End(closed),
        id: 0,
        start: Vector::zero(),
        end: Vector::zero(),
        start_normal: Vector::zero(),
        end_normal: Vector::zero(),
        end_pivot: Vector::zero(),
      }
  }
}
