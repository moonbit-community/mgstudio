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
/// Bounds, origin and placement.
///
/// Ported from upstream `zeno/src/geometry.rs` (Apache-2.0 OR MIT).

pub(all) enum Origin {
  TopLeft
  BottomLeft
}

pub struct Bounds {
  mut min : Point
  mut max : Point
  mut empty : Bool
}

pub fn Bounds::new(min : Point, max : Point) -> Bounds {
  Bounds::{ min, max, empty: false }
}

pub fn Bounds::from_points(points : Array[Point]) -> Bounds {
  let b = Bounds::{ min: Vector::new(0.0, 0.0), max: Vector::new(0.0, 0.0), empty: true }
  for p in points {
    b.add_point(p)
  }
  b
}

pub fn Bounds::add_point(self : Bounds, p : Point) -> Unit {
  if self.empty {
    self.min = p
    self.max = p
    self.empty = false
    return
  }
  let x = p.x()
  let y = p.y()
  self.min = Vector::new(
    if self.min.x() < x { self.min.x() } else { x },
    if self.min.y() < y { self.min.y() } else { y },
  )
  self.max = Vector::new(
    if self.max.x() > x { self.max.x() } else { x },
    if self.max.y() > y { self.max.y() } else { y },
  )
}

pub fn Bounds::width(self : Bounds) -> Double {
  if self.empty { 0.0 } else { self.max.x() - self.min.x() }
}

pub fn Bounds::height(self : Bounds) -> Double {
  if self.empty { 0.0 } else { self.max.y() - self.min.y() }
}

pub fn Bounds::is_empty(self : Bounds) -> Bool {
  self.empty
}

pub struct Placement {
  left : Int
  top : Int
  width : UInt
  height : UInt
}

pub fn Placement::compute(origin : Origin, offset : Vector, bounds : Bounds) -> (Vector, Placement) {
  let b = bounds
  // Copy semantics: ensure we don't mutate the original bounds reference.
  // We emulate zeno by snapping to pixel boundaries after applying offset.
  if !b.empty {
    b.min = (b.min + offset).floor()
    b.max = (b.max + offset).ceil()
  }
  let off = Vector::new(-b.min.x(), -b.min.y())
  let width = b.width().to_int().reinterpret_as_uint()
  let height = b.height().to_int().reinterpret_as_uint()
  let left = (-off.x()).to_int()
  let top = match origin {
    Origin::BottomLeft => ((-off.y()).floor() + height.reinterpret_as_int().to_double()).to_int()
    Origin::TopLeft => (-off.y()).to_int()
  }
  (off, Placement::{ left, top, width, height })
}

pub impl Add for Vector with add(self, other) {
  Vector::new(self.x() + other.x(), self.y() + other.y())
}
