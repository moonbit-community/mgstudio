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
/// Path rasterizer (alpha fill subset).
///
/// Ported from upstream `zeno/src/raster.rs` (Apache-2.0 OR MIT).
const PIXEL_BITS : Int = 8

///|
const ONE_PIXEL : Int = 1 << PIXEL_BITS

///|
fn trunc(x : Int) -> Int {
  x >> PIXEL_BITS
}

///|
fn fract(x : Int) -> Int {
  x & (ONE_PIXEL - 1)
}

///|
fn to_fixed(v : Double) -> Int {
  // Upstream uses `to_int_unchecked` on f32; we keep the same scaling (256x).
  (v * 256.0).to_int()
}

///|
pub struct FixedPoint {
  mut x : Int
  mut y : Int
}

///|
pub fn FixedPoint::new(x : Int, y : Int) -> FixedPoint {
  FixedPoint::{ x, y }
}

///|
pub fn FixedPoint::default() -> FixedPoint {
  FixedPoint::{ x: 0, y: 0 }
}

///|
pub fn FixedPoint::from_point(p : Point) -> FixedPoint {
  FixedPoint::{ x: to_fixed(p.x()), y: to_fixed(p.y()) }
}

///|
pub struct Cell {
  x : Int
  mut cover : Int
  mut area : Int
  mut next : Int
}

///|
pub struct HeapStorage {
  mut min : FixedPoint
  mut max : FixedPoint
  cells : Array[Cell]
  indices : Array[Int]
}

///|
pub fn HeapStorage::new() -> HeapStorage {
  HeapStorage::{
    min: FixedPoint::default(),
    max: FixedPoint::default(),
    cells: [],
    indices: [],
  }
}

///|
fn HeapStorage::reset(
  self : HeapStorage,
  min : FixedPoint,
  max : FixedPoint,
) -> Unit {
  self.min = min
  self.max = max
  self.cells.clear()
  self.indices.clear()
  let height = max.y - min.y
  for _i in 0..<height {
    self.indices.push(-1)
  }
}

///|
fn HeapStorage::cells(self : HeapStorage) -> Array[Cell] {
  self.cells
}

///|
fn HeapStorage::indices(self : HeapStorage) -> Array[Int] {
  self.indices
}

///|
fn HeapStorage::set(
  self : HeapStorage,
  x : Int,
  y : Int,
  area : Int,
  cover : Int,
) -> Unit {
  let yindex = y - self.min.y
  if yindex < 0 || yindex >= self.indices.length() {
    return
  }
  let mut cell_index = self.indices[yindex]
  let mut last_index = -1
  while cell_index != -1 {
    let cell = self.cells[cell_index]
    if cell.x > x {
      break
    } else if cell.x == x {
      self.cells[cell_index].area = self.cells[cell_index].area + area
      self.cells[cell_index].cover = self.cells[cell_index].cover + cover
      return
    }
    last_index = cell_index
    cell_index = cell.next
  }
  let new_index = self.cells.length()
  let new_cell = Cell::{ x, area, cover, next: cell_index }
  if last_index != -1 {
    self.cells[last_index].next = new_index
  } else {
    self.indices[yindex] = new_index
  }
  self.cells.push(new_cell)
}

///|
fn coverage(fill : Fill, coverage0 : Int) -> Byte {
  let mut coverage = coverage0 >> (PIXEL_BITS * 2 + 1 - 8)
  match fill {
    Fill::EvenOdd => {
      coverage = coverage & 511
      if coverage >= 256 {
        coverage = 511 - coverage
      }
    }
    _ => {
      if coverage < 0 {
        coverage = coverage ^ -1
      }
      if coverage >= 256 {
        coverage = 255
      }
    }
  }
  coverage.to_byte()
}

///|
pub struct Rasterizer {
  storage : HeapStorage
  mut xmin : Int
  mut xmax : Int
  mut ymin : Int
  mut ymax : Int
  mut height : Int
  mut shift : Vector
  mut start : FixedPoint
  mut closed : Bool
  mut current : Point
  mut x : Int
  mut y : Int
  mut px : Int
  mut py : Int
  mut cover : Int
  mut area : Int
  mut invalid : Bool
}

///|
pub fn Rasterizer::new(storage : HeapStorage) -> Rasterizer {
  Rasterizer::{
    storage,
    xmin: 0,
    xmax: 0,
    ymin: 0,
    ymax: 0,
    height: 0,
    shift: Vector::new(0.0, 0.0),
    start: FixedPoint::default(),
    closed: false,
    current: Vector::new(0.0, 0.0),
    x: 0,
    y: 0,
    px: 0,
    py: 0,
    cover: 0,
    area: 0,
    invalid: false,
  }
}

///|
pub fn Rasterizer::storage(self : Rasterizer) -> HeapStorage {
  self.storage
}

///|
fn Rasterizer::set_cell(self : Rasterizer, x : Int, y : Int) -> Unit {
  if !self.invalid && (self.area != 0 || self.cover != 0) {
    self.storage.set(self.x, self.y, self.area, self.cover)
  }
  self.area = 0
  self.cover = 0
  self.x = if x > self.xmin - 1 { x } else { self.xmin - 1 }
  self.y = y
  self.invalid = y >= self.ymax || y < self.ymin || x >= self.xmax
}

///|
fn Rasterizer::move_to_fixed(self : Rasterizer, to : FixedPoint) -> Unit {
  self.set_cell(trunc(to.x), trunc(to.y))
  self.px = to.x
  self.py = to.y
}

// Port of zeno's `line_to` exactly; integer math in 8.8 fixed point.

///|
fn Rasterizer::line_to_fixed(self : Rasterizer, to : FixedPoint) -> Unit {
  let to_x = to.x
  let to_y = to.y
  let mut ey1 = trunc(self.py)
  let ey2 = trunc(to_y)
  if (ey1 >= self.ymax && ey2 >= self.ymax) ||
    (ey1 < self.ymin && ey2 < self.ymin) {
    self.px = to_x
    self.py = to_y
    return
  }
  let mut ex1 = trunc(self.px)
  let ex2 = trunc(to_x)
  let mut fx1 = fract(self.px)
  let mut fy1 = fract(self.py)
  let dx = to_x - self.px
  let dy = to_y - self.py
  if ex1 == ex2 && ey1 == ey2 {
    // empty
  } else if dy == 0 {
    self.set_cell(ex2, ey2)
    self.px = to_x
    self.py = to_y
    return
  } else if dx == 0 {
    if dy > 0 {
      while true {
        let fy2 = ONE_PIXEL
        self.cover = self.cover + (fy2 - fy1)
        self.area = self.area + (fy2 - fy1) * fx1 * 2
        fy1 = 0
        ey1 = ey1 + 1
        self.set_cell(ex1, ey1)
        if ey1 == ey2 {
          break
        }
      }
    } else {
      while true {
        let fy2 = 0
        self.cover = self.cover + (fy2 - fy1)
        self.area = self.area + (fy2 - fy1) * fx1 * 2
        fy1 = ONE_PIXEL
        ey1 = ey1 - 1
        self.set_cell(ex1, ey1)
        if ey1 == ey2 {
          break
        }
      }
    }
  } else {
    let mut prod = dx * fy1 - dy * fx1
    let dx_r = if ex1 != ex2 { 0x00FFFFFF / dx } else { 0 }
    let dy_r = if ey1 != ey2 { 0x00FFFFFF / dy } else { 0 }
    fn udiv(a : Int, b : Int) -> Int {
      // ((a as u64 * b as u64) >> (4 * 8 - PIXEL_BITS)) as i32
      // Upstream uses unsigned 64-bit. Here `a` and `b` are always non-negative
      // at call sites, so signed 64-bit math matches the intent.
      ((a.to_int64() * b.to_int64()) >> (32 - PIXEL_BITS)).to_int()
    }

    while true {
      if prod <= 0 && prod - dx * ONE_PIXEL > 0 {
        let fx2 = 0
        let fy2 = udiv(-prod, -dx_r)
        prod = prod - dy * ONE_PIXEL
        self.cover = self.cover + (fy2 - fy1)
        self.area = self.area + (fy2 - fy1) * (fx1 + fx2)
        fx1 = ONE_PIXEL
        fy1 = fy2
        ex1 = ex1 - 1
      } else if prod - dx * ONE_PIXEL <= 0 &&
        prod - dx * ONE_PIXEL + dy * ONE_PIXEL > 0 {
        prod = prod - dx * ONE_PIXEL
        let fx2 = udiv(-prod, dy_r)
        let fy2 = ONE_PIXEL
        self.cover = self.cover + (fy2 - fy1)
        self.area = self.area + (fy2 - fy1) * (fx1 + fx2)
        fx1 = fx2
        fy1 = 0
        ey1 = ey1 + 1
      } else if prod - dx * ONE_PIXEL + dy * ONE_PIXEL <= 0 &&
        prod + dy * ONE_PIXEL >= 0 {
        prod = prod + dy * ONE_PIXEL
        let fx2 = ONE_PIXEL
        let fy2 = udiv(prod, dx_r)
        self.cover = self.cover + (fy2 - fy1)
        self.area = self.area + (fy2 - fy1) * (fx1 + fx2)
        fx1 = 0
        fy1 = fy2
        ex1 = ex1 + 1
      } else {
        let fx2 = udiv(prod, -dy_r)
        let fy2 = 0
        prod = prod + dx * ONE_PIXEL
        self.cover = self.cover + (fy2 - fy1)
        self.area = self.area + (fy2 - fy1) * (fx1 + fx2)
        fx1 = fx2
        fy1 = ONE_PIXEL
        ey1 = ey1 - 1
      }
      self.set_cell(ex1, ey1)
      if ex1 == ex2 && ey1 == ey2 {
        break
      }
    }
  }
  let fx2 = fract(to_x)
  let fy2 = fract(to_y)
  self.cover = self.cover + (fy2 - fy1)
  self.area = self.area + (fy2 - fy1) * (fx1 + fx2)
  self.px = to_x
  self.py = to_y
}

///|
fn split_quad(base : Array[FixedPoint], offset : Int) -> Unit {
  let mut a = 0
  let mut b = 0
  base[offset + 4].x = base[offset + 2].x
  a = base[offset + 0].x + base[offset + 1].x
  b = base[offset + 1].x + base[offset + 2].x
  base[offset + 3].x = b >> 1
  base[offset + 2].x = (a + b) >> 2
  base[offset + 1].x = a >> 1
  base[offset + 4].y = base[offset + 2].y
  a = base[offset + 0].y + base[offset + 1].y
  b = base[offset + 1].y + base[offset + 2].y
  base[offset + 3].y = b >> 1
  base[offset + 2].y = (a + b) >> 2
  base[offset + 1].y = a >> 1
}

///|
fn split_cubic(base : Array[FixedPoint], offset : Int) -> Unit {
  let mut a = 0
  let mut b = 0
  let mut c = 0
  base[offset + 6].x = base[offset + 3].x
  a = base[offset + 0].x + base[offset + 1].x
  b = base[offset + 1].x + base[offset + 2].x
  c = base[offset + 2].x + base[offset + 3].x
  base[offset + 5].x = c >> 1
  c = c + b
  base[offset + 4].x = c >> 2
  base[offset + 1].x = a >> 1
  a = a + b
  base[offset + 2].x = a >> 2
  base[offset + 3].x = (a + c) >> 3
  base[offset + 6].y = base[offset + 3].y
  a = base[offset + 0].y + base[offset + 1].y
  b = base[offset + 1].y + base[offset + 2].y
  c = base[offset + 2].y + base[offset + 3].y
  base[offset + 5].y = c >> 1
  c = c + b
  base[offset + 4].y = c >> 2
  base[offset + 1].y = a >> 1
  a = a + b
  base[offset + 2].y = a >> 2
  base[offset + 3].y = (a + c) >> 3
}

///|
fn Rasterizer::quad_to_fixed(
  self : Rasterizer,
  control : FixedPoint,
  to : FixedPoint,
) -> Unit {
  let arc : Array[FixedPoint] = []
  for _i in 0..<(16 * 2 + 1) {
    arc.push(FixedPoint::default())
  }
  arc[0].x = to.x
  arc[0].y = to.y
  arc[1].x = control.x
  arc[1].y = control.y
  arc[2].x = self.px
  arc[2].y = self.py
  if (
      trunc(arc[0].y) >= self.ymax &&
      trunc(arc[1].y) >= self.ymax &&
      trunc(arc[2].y) >= self.ymax
    ) ||
    (
      trunc(arc[0].y) < self.ymin &&
      trunc(arc[1].y) < self.ymin &&
      trunc(arc[2].y) < self.ymin
    ) {
    self.px = arc[0].x
    self.py = arc[0].y
    return
  }
  let mut dx = (arc[2].x + arc[0].x - 2 * arc[1].x).abs()
  let dy = (arc[2].y + arc[0].y - 2 * arc[1].y).abs()
  if dx < dy {
    dx = dy
  }
  let mut draw = 1
  while dx > ONE_PIXEL / 4 {
    dx = dx >> 2
    draw = draw << 1
  }
  let mut a = 0
  while true {
    let mut split = draw & -draw
    while true {
      split = split >> 1
      if split == 0 {
        break
      }
      split_quad(arc, a)
      a = a + 2
    }
    let p = arc[a]
    self.line_to_fixed(p)
    draw = draw - 1
    if draw == 0 {
      break
    }
    a = a - 2
  }
}

///|
fn Rasterizer::curve_to_fixed(
  self : Rasterizer,
  control1 : FixedPoint,
  control2 : FixedPoint,
  to : FixedPoint,
) -> Unit {
  let arc : Array[FixedPoint] = []
  for _i in 0..<(16 * 8 + 1) {
    arc.push(FixedPoint::default())
  }
  arc[0].x = to.x
  arc[0].y = to.y
  arc[1].x = control2.x
  arc[1].y = control2.y
  arc[2].x = control1.x
  arc[2].y = control1.y
  arc[3].x = self.px
  arc[3].y = self.py
  if (
      trunc(arc[0].y) >= self.ymax &&
      trunc(arc[1].y) >= self.ymax &&
      trunc(arc[2].y) >= self.ymax &&
      trunc(arc[3].y) >= self.ymax
    ) ||
    (
      trunc(arc[0].y) < self.ymin &&
      trunc(arc[1].y) < self.ymin &&
      trunc(arc[2].y) < self.ymin &&
      trunc(arc[3].y) < self.ymin
    ) {
    self.px = arc[0].x
    self.py = arc[0].y
    return
  }
  let mut a = 0
  while true {
    if (2 * arc[a].x - 3 * arc[a + 1].x + arc[a + 3].x).abs() > ONE_PIXEL / 2 ||
      (2 * arc[a].y - 3 * arc[a + 1].y + arc[a + 3].y).abs() > ONE_PIXEL / 2 ||
      (arc[a].x - 3 * arc[a + 2].x + 2 * arc[a + 3].x).abs() > ONE_PIXEL / 2 ||
      (arc[a].y - 3 * arc[a + 2].y + 2 * arc[a + 3].y).abs() > ONE_PIXEL / 2 {
      if a + 7 <= arc.length() {
        split_cubic(arc, a)
        a = a + 3
        continue
      } else {
        self.line_to_fixed(to)
        return
      }
    }
    let p = arc[a]
    self.line_to_fixed(p)
    if a == 0 {
      return
    }
    a = a - 3
  }
}

///|
pub fn Rasterizer::rasterize(
  self : Rasterizer,
  shift : Vector,
  width : UInt,
  height : UInt,
  apply : (Rasterizer) -> Unit,
  fill : Fill,
  buffer : Array[Byte],
  pitch : Int,
  y_up : Bool,
) -> Unit {
  let w = width.reinterpret_as_int()
  let h = height.reinterpret_as_int()
  self.storage.reset(FixedPoint::{ x: 0, y: 0 }, FixedPoint::{ x: w, y: h })
  self.shift = shift
  self.start = FixedPoint::default()
  self.closed = true
  self.current = Vector::new(0.0, 0.0)
  self.xmin = 0
  self.ymin = 0
  self.xmax = w
  self.ymax = h
  self.height = h
  self.x = 0
  self.y = 0
  self.px = 0
  self.py = 0
  self.invalid = true
  apply(self)
  if !self.closed {
    self.line_to_fixed(self.start)
  }
  if !self.invalid {
    self.storage.set(self.x, self.y, self.area, self.cover)
  }
  let indices = self.storage.indices()
  let cells = self.storage.cells()
  let min = FixedPoint::new(self.xmin, self.ymin)
  let max = FixedPoint::new(self.xmax, self.ymax)
  let height_usize = h
  for i in 0..<indices.length() {
    let index0 = indices[i]
    if index0 != -1 {
      let y = i - min.y
      let row_offset = if y_up {
        pitch * (height_usize - 1 - y)
      } else {
        pitch * y
      }
      let mut x = min.x
      let mut cover = 0
      let mut index = index0
      while true {
        let cell = cells[index]
        if cover != 0 && cell.x > x {
          let count = cell.x - x
          let c = coverage(fill, cover)
          let xi = x
          for j in 0..<count {
            buffer[row_offset + xi + j] = c
          }
        }
        cover = cover + cell.cover * (ONE_PIXEL * 2)
        let area = cover - cell.area
        if area != 0 && cell.x >= min.x {
          let c = coverage(fill, area)
          let xi = cell.x
          buffer[row_offset + xi] = c
        }
        x = cell.x + 1
        index = cell.next
        if index == -1 {
          break
        }
      }
      if cover != 0 {
        let count = max.x - x
        let c = coverage(fill, cover)
        let xi = x
        for j in 0..<count {
          buffer[row_offset + xi + j] = c
        }
      }
    }
  }
}

///|
/// Like `rasterize`, but delegates span writes to a callback.
///
/// This matches upstream `Rasterizer::rasterize_write` usage in `mask.rs` for
/// subpixel formats (writing R/G/B channels separately).
pub fn Rasterizer::rasterize_write(
  self : Rasterizer,
  shift : Vector,
  width : UInt,
  height : UInt,
  apply : (Rasterizer) -> Unit,
  fill : Fill,
  pitch : Int,
  y_up : Bool,
  write : (Int, Int, Int, Byte) -> Unit,
) -> Unit {
  let w = width.reinterpret_as_int()
  let h = height.reinterpret_as_int()
  self.storage.reset(FixedPoint::{ x: 0, y: 0 }, FixedPoint::{ x: w, y: h })
  self.shift = shift
  self.start = FixedPoint::default()
  self.closed = true
  self.current = Vector::new(0.0, 0.0)
  self.xmin = 0
  self.ymin = 0
  self.xmax = w
  self.ymax = h
  self.height = h
  self.x = 0
  self.y = 0
  self.px = 0
  self.py = 0
  self.invalid = true
  apply(self)
  if !self.closed {
    self.line_to_fixed(self.start)
  }
  if !self.invalid {
    self.storage.set(self.x, self.y, self.area, self.cover)
  }
  let indices = self.storage.indices()
  let cells = self.storage.cells()
  let min = FixedPoint::new(self.xmin, self.ymin)
  let max = FixedPoint::new(self.xmax, self.ymax)
  let height_usize = h
  for i in 0..<indices.length() {
    let index0 = indices[i]
    if index0 != -1 {
      let y = i - min.y
      let row_offset = if y_up {
        pitch * (height_usize - 1 - y)
      } else {
        pitch * y
      }
      let mut x = min.x
      let mut cover = 0
      let mut index = index0
      while true {
        let cell = cells[index]
        if cover != 0 && cell.x > x {
          let count = cell.x - x
          let c = coverage(fill, cover)
          write(row_offset, x, count, c)
        }
        cover = cover + cell.cover * (ONE_PIXEL * 2)
        let area = cover - cell.area
        if area != 0 && cell.x >= min.x {
          let c = coverage(fill, area)
          write(row_offset, cell.x, 1, c)
        }
        x = cell.x + 1
        index = cell.next
        if index == -1 {
          break
        }
      }
      if cover != 0 {
        let count = max.x - x
        let c = coverage(fill, cover)
        write(row_offset, x, count, c)
      }
    }
  }
}

///|
pub impl PathBuilder for Rasterizer with move_to(self, p) {
  if !self.closed {
    self.line_to_fixed(self.start)
  }
  let fp = FixedPoint::from_point(p + self.shift)
  self.move_to_fixed(fp)
  self.closed = false
  self.start = fp
  self.current = p
}

///|
pub impl PathBuilder for Rasterizer with line_to(self, p) {
  self.current = p
  self.closed = false
  self.line_to_fixed(FixedPoint::from_point(p + self.shift))
}

///|
pub impl PathBuilder for Rasterizer with quad_to(self, control, p) {
  self.current = p
  self.closed = false
  self.quad_to_fixed(
    FixedPoint::from_point(control + self.shift),
    FixedPoint::from_point(p + self.shift),
  )
}

///|
pub impl PathBuilder for Rasterizer with curve_to(self, c1, c2, p) {
  self.current = p
  self.closed = false
  self.curve_to_fixed(
    FixedPoint::from_point(c1 + self.shift),
    FixedPoint::from_point(c2 + self.shift),
    FixedPoint::from_point(p + self.shift),
  )
}

///|
pub impl PathBuilder for Rasterizer with close(self) {
  self.line_to_fixed(self.start)
  self.closed = true
}
