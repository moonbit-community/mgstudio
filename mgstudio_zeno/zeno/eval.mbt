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
/// Style/transform evaluation utilities (subset).
///
/// Ported from `zeno/src/path_data.rs` + `zeno/src/geometry.rs` eval helpers
/// (Apache-2.0 OR MIT).
pub struct BoundsBuilder {
  mut count : Int
  mut min : Point
  mut max : Point
}

///|
pub fn BoundsBuilder::new() -> BoundsBuilder {
  BoundsBuilder::{
    count: 0,
    min: Vector::new(1.0e308, 1.0e308),
    max: Vector::new(-1.0e308, -1.0e308),
  }
}

///|
fn BoundsBuilder::add(self : BoundsBuilder, p : Point) -> Unit {
  let x = p.x()
  let y = p.y()
  if x < self.min.x() {
    self.min = Vector::new(x, self.min.y())
  }
  if x > self.max.x() {
    self.max = Vector::new(x, self.max.y())
  }
  if y < self.min.y() {
    self.min = Vector::new(self.min.x(), y)
  }
  if y > self.max.y() {
    self.max = Vector::new(self.max.x(), y)
  }
  self.count = self.count + 1
}

///|
fn BoundsBuilder::build(self : BoundsBuilder) -> Bounds {
  if self.count != 0 {
    Bounds::{ min: self.min, max: self.max, empty: false }
  } else {
    Bounds::{
      min: Vector::new(0.0, 0.0),
      max: Vector::new(0.0, 0.0),
      empty: true,
    }
  }
}

///|
pub impl PathBuilder for BoundsBuilder with move_to(self, p) {
  self.add(p)
}

///|
pub impl PathBuilder for BoundsBuilder with line_to(self, p) {
  self.add(p)
}

///|
pub impl PathBuilder for BoundsBuilder with quad_to(self, c, p) {
  self.add(c)
  self.add(p)
}

///|
pub impl PathBuilder for BoundsBuilder with curve_to(self, c1, c2, p) {
  self.add(c1)
  self.add(c2)
  self.add(p)
}

///|
pub impl PathBuilder for BoundsBuilder with close(_self) {
  ()
}

///|
pub struct TransformSink {
  sink : &PathBuilder
  transform : Transform
}

///|
pub impl PathBuilder for TransformSink with move_to(self, p) {
  self.sink.move_to(self.transform.transform_point(p))
}

///|
pub impl PathBuilder for TransformSink with line_to(self, p) {
  self.sink.line_to(self.transform.transform_point(p))
}

///|
pub impl PathBuilder for TransformSink with quad_to(self, c, p) {
  self.sink.quad_to(
    self.transform.transform_point(c),
    self.transform.transform_point(p),
  )
}

///|
pub impl PathBuilder for TransformSink with curve_to(self, c1, c2, p) {
  self.sink.curve_to(
    self.transform.transform_point(c1),
    self.transform.transform_point(c2),
    self.transform.transform_point(p),
  )
}

///|
pub impl PathBuilder for TransformSink with close(self) {
  self.sink.close()
}

///|
/// Applies the style and transform to the path and emits the result to the sink.
pub fn apply(
  data : &PathData,
  style : Style,
  transform : Transform?,
  sink : &PathBuilder,
) -> Fill {
  match style {
    Style::Fill(fill) => {
      if transform is Some(t) {
        let ts = TransformSink::{ sink, transform: t }
        // `&Trait` in MoonBit is a trait constraint, not a borrow operator.
        // So we pass the value directly.
        data.copy_to(ts)
      } else {
        data.copy_to(sink)
      }
      fill
    }
    Style::Stroke(_stroke) => {
      // TODO(zeno): port stroke.rs (join/cap/dash) and apply here.
      if transform is Some(t) {
        let ts = TransformSink::{ sink, transform: t }
        data.copy_to(ts)
      } else {
        data.copy_to(sink)
      }
      Fill::NonZero
    }
  }
}

///|
/// Computes the bounding box of the path (style/transform aware; fill-only accurate for now).
pub fn bounds(
  data : &PathData,
  style : Style,
  transform : Transform?,
) -> Bounds {
  let b = BoundsBuilder::new()
  apply(data, style, transform, b) |> ignore
  b.build()
}
