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
/// Path traversal algorithms.
///
/// Ported from upstream `zeno/src/traversal.rs` (Apache-2.0 OR MIT).

///|
/// A vertex of a path.
pub enum Vertex {
  /// The start point and direction of a subpath.
  Start(Point, Vector)
  /// The incoming direction, location, and outgoing direction of an intermediate vertex.
  Middle(Vector, Point, Vector)
  /// The incoming direction and location of the final vertex in a subpath.
  /// The boolean is true if the subpath is closed.
  End(Vector, Point, Bool)
}

///|
/// Iterator over the vertices of a path.
pub struct Vertices {
  segments : Segments
  mut prev_point : Point
  mut prev_dir : Vector
  mut is_first : Bool
}

///|
pub fn Vertices::new(data : &PathData) -> Vertices {
  Vertices::{
    segments: segments(data.commands(), false),
    prev_point: Vector::zero(),
    prev_dir: Vector::new(1.0, 0.0),
    is_first: true,
  }
}

///|
pub fn Vertices::with_transform(
  data : &PathData,
  transform : Transform,
) -> Vertices {
  let cmds = data.commands()
  let it = cmds
  let mapped = Iter::new(fn() {
    match it.next() {
      Some(cmd) => Some(cmd.transform(transform))
      None => None
    }
  })
  Vertices::{
    segments: segments(mapped, false),
    prev_point: Vector::zero(),
    prev_dir: Vector::new(1.0, 0.0),
    is_first: true,
  }
}

///|
pub fn Vertices::next(self : Vertices) -> Vertex? {
  if self.is_first {
    self.is_first = false
    match self.segments.next() {
      Some(seg) =>
        match seg {
          Segment::End(closed) => {
            self.is_first = true
            Some(Vertex::End(self.prev_dir, self.prev_point, closed))
          }
          _ => {
            let (start, in_dir, out_dir, end) = get_components(seg)
            self.prev_dir = out_dir
            self.prev_point = end
            Some(Vertex::Start(start, in_dir))
          }
        }
      None => None
    }
  } else {
    match self.segments.next() {
      Some(seg) =>
        match seg {
          Segment::End(closed) => {
            self.is_first = true
            Some(Vertex::End(self.prev_dir, self.prev_point, closed))
          }
          _ => {
            let (start, in_dir, out_dir, end) = get_components(seg)
            let prev_dir0 = self.prev_dir
            self.prev_dir = out_dir
            self.prev_point = end
            Some(Vertex::Middle(prev_dir0, start, in_dir))
          }
        }
      None => None
    }
  }
}

///|
fn get_components(segment : Segment) -> (Point, Vector, Vector, Point) {
  match segment {
    Segment::Curve(_, curve) => {
      let a = curve.evaluate(0.05)
      let b = curve.evaluate(0.95)
      let a_dir = (a - curve.a).normalize()
      let b_dir = (curve.d - b).normalize()
      (curve.a, a_dir, b_dir, curve.d)
    }
    Segment::Line(_, line) => {
      let dir = (line.b - line.a).normalize()
      (line.a, dir, dir, line.b)
    }
    Segment::End(_) =>
      (Vector::zero(), Vector::zero(), Vector::zero(), Vector::zero())
  }
}

///|
/// Iterator-like type that walks along a path by arbitrary steps.
pub struct Walk {
  commands : Array[Command]
  iter : Segments
  mut segment : Segment
  mut segment_offset : Double
  mut first : Bool
  mut length : Double?
  mut walked : Double
}

///|
pub fn Walk::new(data : &PathData) -> Walk {
  let cmds : Array[Command] = []
  let it = data.commands()
  while it.next() is Some(cmd) {
    cmds.push(cmd)
  }
  Walk::{
    commands: cmds,
    iter: Segments::new(false, cmds),
    segment: Segment::default(),
    segment_offset: 0.0,
    first: true,
    length: None,
    walked: 0.0,
  }
}

///|
pub fn Walk::with_transform(data : &PathData, transform : Transform) -> Walk {
  let cmds : Array[Command] = []
  let it = data.commands()
  while it.next() is Some(cmd) {
    cmds.push(cmd.transform(transform))
  }
  Walk::{
    commands: cmds,
    iter: Segments::new(false, cmds),
    segment: Segment::default(),
    segment_offset: 0.0,
    first: true,
    length: None,
    walked: 0.0,
  }
}

///|
/// Steps by the specified distance.
pub fn Walk::step(self : Walk, distance : Double) -> (Point, Vector)? {
  if self.first {
    match self.next_segment() {
      Some(seg) => {
        self.segment = seg
        self.segment_offset = 0.0
        self.first = false
      }
      None => return None
    }
  }
  let mut t = 0.0
  let mut offset = self.segment_offset
  let mut segment = self.segment
  let mut remaining = distance
  while true {
    let dt = segment.time(offset + remaining, 1.0)
    remaining = remaining - (dt.distance - offset)
    t = dt.time
    offset = dt.distance
    if remaining <= 0.0 {
      break
    }
    match self.next_segment() {
      Some(seg) => {
        segment = seg
        offset = 0.0
      }
      None => return None
    }
  } else {
    ()
  }
  self.segment = segment
  self.segment_offset = offset
  self.walked = self.walked + distance
  let (p, n) = segment.point_normal(t)
  Some((p, n))
}

///|
pub fn Walk::remaining(self : Walk) -> Double {
  let len = match self.length {
    Some(v) => v
    None => {
      let mut sum = 0.0
      let segs = Segments::new(false, self.commands)
      let it = segs
      while it.next() is Some(s) {
        sum = sum + s.length()
      }
      self.length = Some(sum)
      sum
    }
  }
  len - self.walked
}

///|
fn Walk::next_segment(self : Walk) -> Segment? {
  while self.iter.next() is Some(s) {
    match s {
      Segment::End(_) => continue
      _ => return Some(s)
    }
  }
  None
}
