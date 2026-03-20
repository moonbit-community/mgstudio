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
pub fn polygon_signed_area(vertices : Array[Vec2]) -> Float {
  if vertices.length() < 3 {
    return 0.0F
  }
  let mut twice_area = 0.0F
  for index in 0..<vertices.length() {
    let current = vertices[index]
    let next = vertices[(index + 1) % vertices.length()]
    twice_area = twice_area + current.x * next.y - next.x * current.y
  }
  twice_area * 0.5F
}

///|
pub fn polygon_winding_order(vertices : Array[Vec2]) -> WindingOrder {
  let area = polygon_signed_area(vertices)
  if polygon_absf(area) <= 1.0e-6F {
    WindingOrder::Invalid
  } else if area < 0.0F {
    WindingOrder::Clockwise
  } else {
    WindingOrder::CounterClockwise
  }
}

///|
pub fn is_polygon_simple(vertices : Array[Vec2]) -> Bool {
  if vertices.length() < 3 {
    return false
  }
  for i in 0..<vertices.length() {
    let a0 = vertices[i]
    let a1 = vertices[(i + 1) % vertices.length()]
    for j in (i + 1)..<vertices.length() {
      if j == i ||
        j == (i + 1) % vertices.length() ||
        (j + 1) % vertices.length() == i {
        continue
      }
      let b0 = vertices[j]
      let b1 = vertices[(j + 1) % vertices.length()]
      if polygon_segments_intersect(a0, a1, b0, b1) {
        return false
      }
    }
  }
  true
}

///|
fn polygon_segments_intersect(
  a0 : Vec2,
  a1 : Vec2,
  b0 : Vec2,
  b1 : Vec2,
) -> Bool {
  let d1 = polygon_point_side(a0, a1, b0)
  let d2 = polygon_point_side(a0, a1, b1)
  if d1 * d2 > 0.0F {
    return false
  }
  let d3 = polygon_point_side(b0, b1, a0)
  let d4 = polygon_point_side(b0, b1, a1)
  d3 * d4 <= 0.0F
}

///|
fn polygon_point_side(a : Vec2, b : Vec2, point : Vec2) -> Float {
  let ab = b.sub(a)
  let ap = point.sub(a)
  ab.x * ap.y - ab.y * ap.x
}

///|
fn polygon_absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}
