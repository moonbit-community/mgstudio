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
test "vec2 basics" {
  let v = Vec2::new(1.0F, 2.0F)
  let w = Vec2::new(3.0F, 4.0F)
  let sum = v.add(w)
  inspect(sum.x.to_int(), content="4")
  inspect(sum.y.to_int(), content="6")
  inspect(v.dot(w).to_int(), content="11")
}

///|
test "vec2 normalize" {
  let v = Vec2::new(3.0F, 4.0F).normalize()
  inspect(v.length().to_int(), content="1")
  let zero = Vec2::zero().normalize()
  inspect(zero.length().to_int(), content="0")
}

///|
test "aabb contains" {
  let aabb = Aabb::from_points(Vec2::new(-1.0F, -1.0F), Vec2::new(1.0F, 1.0F))
  inspect(aabb.contains_point(Vec2::new(0.5F, 0.5F)), content="true")
  inspect(aabb.contains_point(Vec2::new(2.0F, 0.0F)), content="false")
}

///|
test "isometry identity" {
  let iso = Isometry2::identity()
  let point = Vec2::new(2.0F, -3.0F)
  let transformed = iso.transform_point(point)
  inspect(transformed.x.to_int(), content="2")
  inspect(transformed.y.to_int(), content="-3")
}
