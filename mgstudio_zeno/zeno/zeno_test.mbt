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
test "Transform::identity transforms points" {
  let p = Point::new(1.0, 2.0)
  let t = Transform::identity()
  let q = t.transform_point(p)
  inspect(q.x(), content="1")
  inspect(q.y(), content="2")
}

///|
test "Bounds::from_points covers all points" {
  let b = Bounds::from_points([
    Point::new(0.0, 0.0),
    Point::new(2.0, 3.0),
    Point::new(-1.0, 1.0),
  ])
  inspect(b.is_empty(), content="false")
}

///|
test "Mask::render_into draws a filled triangle (alpha)" {
  let data = PointsVerbsPathData::new(
    [Point::new(1.0, 1.0), Point::new(6.0, 1.0), Point::new(3.5, 6.0)],
    [Verb::MoveTo, Verb::LineTo, Verb::LineTo, Verb::Close],
  )
  let buffer : Array[Byte] = []
  for _ in 0..<(8 * 8) {
    buffer.push(0)
  }
  let placement = Mask::new(data)
    .style(Style::Fill(Fill::NonZero))
    .size(8U, 8U)
    .render_into(buffer)
  inspect(placement.width, content="8")
  inspect(placement.height, content="8")
  inspect(buffer[0].to_int(), content="0")
  inspect(buffer[3 + 3 * 8].to_int() > 0, content="true")
}

///|
test "Mask::render_into draws a filled triangle (subpixel rgb)" {
  let data = PointsVerbsPathData::new(
    [Point::new(1.0, 1.0), Point::new(6.0, 1.0), Point::new(3.5, 6.0)],
    [Verb::MoveTo, Verb::LineTo, Verb::LineTo, Verb::Close],
  )
  let buffer : Array[Byte] = []
  for _ in 0..<(8 * 8 * 4) {
    buffer.push(0)
  }
  let _placement = Mask::new(data)
    .style(Style::Fill(Fill::NonZero))
    .format(Format::Subpixel)
    .size(8U, 8U)
    .render_into(buffer)
  let i = (3 + 3 * 8) * 4
  let r = buffer[i + 0].to_int()
  let g = buffer[i + 1].to_int()
  let b = buffer[i + 2].to_int()
  inspect(r + g + b > 0, content="true")
}

///|
test "Mask::render allocates correct buffer size" {
  let data = PointsVerbsPathData::new(
    [Point::new(1.0, 1.0), Point::new(6.0, 1.0), Point::new(3.5, 6.0)],
    [Verb::MoveTo, Verb::LineTo, Verb::LineTo, Verb::Close],
  )
  let (buf_a, placement_a) = Mask::new(data)
    .format(Format::Alpha)
    .size(8U, 8U)
    .render()
  inspect(placement_a.width, content="8")
  inspect(buf_a.length(), content="64")
  let (buf_s, placement_s) = Mask::new(data)
    .format(Format::Subpixel)
    .size(8U, 8U)
    .render()
  inspect(placement_s.height, content="8")
  inspect(buf_s.length(), content="256")
}

///|
test "Stroke: dashed triangle matches upstream sample points" {
  let data = PointsVerbsPathData::new(
    [Point::new(8.0, 56.0), Point::new(32.0, 8.0), Point::new(56.0, 56.0)],
    [Verb::MoveTo, Verb::LineTo, Verb::LineTo, Verb::Close],
  )
  let buf : Array[Byte] = []
  for _i in 0..<(64 * 64) {
    buf.push(0)
  }
  let stroke = Stroke::new(4.0)
    .join(Join::Round)
    .cap(Cap::Round)
    .dash([10.0, 12.0, 0.0], 0.0)
  let placement = Mask::new(data)
    .style(Style::Stroke(stroke))
    .size(64U, 64U)
    .render_into(buf)
  inspect(placement.left, content="0")
  inspect(placement.top, content="0")
  inspect(placement.width, content="64")
  inspect(placement.height, content="64")
  fn at(buf : Array[Byte], x : Int, y : Int) -> Int {
    buf[y * 64 + x].to_int()
  }

  inspect(at(buf, 32, 8), content="255")
  inspect(at(buf, 32, 32), content="0")
  inspect(at(buf, 8, 56), content="255")
  inspect(at(buf, 56, 56), content="0")
  inspect(at(buf, 20, 40), content="0")
  inspect(at(buf, 44, 40), content="0")
  let mut sum = 0
  for b in buf {
    sum = sum + b.to_int()
  }
  // NOTE: Upstream uses f32 math; MoonBit uses Double, which can cause tiny AA
  // differences in aggregate sums. We still pin the output to keep this port
  // deterministic.
  inspect(sum, content="100052")
}
