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
test "mesh2d: validate indexed triangle list" {
  let positions = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(1.0F, 1.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let indices = [0, 1, 2, 0, 2, 3]
  let mesh = Mesh2dGeometry::new(positions, uvs, Some(indices))
  inspect(mesh.validate() is None, content="true")
  inspect(mesh.triangle_count().unwrap(), content="2")
  inspect(mesh.flatten_triangle_positions_xy().unwrap().length(), content="12")
  inspect(mesh.encode_triangle_positions_csv() is Some(_), content="true")
}

///|
test "mesh2d: validate attribute length mismatch" {
  let positions = [@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 0.0F)]
  let uvs = [@math.Vec2::new(0.0F, 0.0F)]
  let mesh = Mesh2dGeometry::new(positions, uvs, None)
  match mesh.validate() {
    Some(Mesh2dValidationError::AttributeLengthMismatch(_, _)) =>
      inspect(true, content="true")
    _ => inspect(false, content="false")
  }
}

///|
test "mesh2d: validate non-indexed vertex count multiple of 3" {
  let positions = [@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 0.0F)]
  let uvs = [@math.Vec2::new(0.0F, 0.0F), @math.Vec2::new(1.0F, 0.0F)]
  let mesh = Mesh2dGeometry::new(positions, uvs, None)
  match mesh.validate() {
    Some(Mesh2dValidationError::NonIndexedVertexCountNotMultipleOf3(_)) =>
      inspect(true, content="true")
    _ => inspect(false, content="false")
  }
}

///|
test "mesh2d: validate index bounds" {
  let positions = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let indices = [0, 1, 3]
  let mesh = Mesh2dGeometry::new(positions, uvs, Some(indices))
  match mesh.validate() {
    Some(Mesh2dValidationError::IndexOutOfBounds(_, _)) =>
      inspect(true, content="true")
    _ => inspect(false, content="false")
  }
}

///|
test "mesh2d: validate indices multiple of 3" {
  let positions = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let uvs = [
    @math.Vec2::new(0.0F, 0.0F),
    @math.Vec2::new(1.0F, 0.0F),
    @math.Vec2::new(0.0F, 1.0F),
  ]
  let indices = [0, 1]
  let mesh = Mesh2dGeometry::new(positions, uvs, Some(indices))
  match mesh.validate() {
    Some(Mesh2dValidationError::IndicesCountNotMultipleOf3(_)) =>
      inspect(true, content="true")
    _ => inspect(false, content="false")
  }
}
