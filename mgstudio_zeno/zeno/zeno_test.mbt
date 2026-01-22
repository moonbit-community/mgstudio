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
