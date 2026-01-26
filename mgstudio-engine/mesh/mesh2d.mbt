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
/// A minimal, Bevy-aligned 2D mesh geometry container.
///
/// Notes:
/// - Only triangle list is supported for now.
/// - `indices=None` means the vertex arrays are already laid out as triangles.
/// - UVs are required (matching Bevy mesh conventions) even if a pipeline does
///   not use them yet.
pub struct Mesh2dGeometry {
  positions : Array[@math.Vec2]
  uvs : Array[@math.Vec2]
  indices : Array[Int]?
}

///|
pub(all) enum Mesh2dValidationError {
  EmptyVertices
  AttributeLengthMismatch(Int, Int)
  NonIndexedVertexCountNotMultipleOf3(Int)
  IndicesEmpty
  IndicesCountNotMultipleOf3(Int)
  IndexOutOfBounds(Int, Int)
}

///|
pub fn Mesh2dGeometry::new(
  positions : Array[@math.Vec2],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
) -> Mesh2dGeometry {
  Mesh2dGeometry::{ positions, uvs, indices }
}

///|
pub fn Mesh2dGeometry::validate(
  self : Mesh2dGeometry,
) -> Mesh2dValidationError? {
  let vertex_count = self.positions.length()
  if vertex_count <= 0 {
    return Some(Mesh2dValidationError::EmptyVertices)
  }
  let uv_count = self.uvs.length()
  if uv_count != vertex_count {
    return Some(
      Mesh2dValidationError::AttributeLengthMismatch(vertex_count, uv_count),
    )
  }
  match self.indices {
    None => {
      if vertex_count % 3 != 0 {
        return Some(
          Mesh2dValidationError::NonIndexedVertexCountNotMultipleOf3(
            vertex_count,
          ),
        )
      }
      None
    }
    Some(indices) => {
      let index_count = indices.length()
      if index_count <= 0 {
        return Some(Mesh2dValidationError::IndicesEmpty)
      }
      if index_count % 3 != 0 {
        return Some(
          Mesh2dValidationError::IndicesCountNotMultipleOf3(index_count),
        )
      }
      for idx in indices {
        if idx < 0 || idx >= vertex_count {
          return Some(
            Mesh2dValidationError::IndexOutOfBounds(idx, vertex_count),
          )
        }
      }
      None
    }
  }
}

///|
pub fn Mesh2dGeometry::vertex_count(self : Mesh2dGeometry) -> Int {
  self.positions.length()
}

///|
pub fn Mesh2dGeometry::triangle_count(self : Mesh2dGeometry) -> Int? {
  if self.validate() is Some(_) {
    return None
  }
  match self.indices {
    None => Some(self.positions.length() / 3)
    Some(indices) => Some(indices.length() / 3)
  }
}

///|
pub fn Mesh2dGeometry::flatten_positions_xy(
  self : Mesh2dGeometry,
) -> Array[Double]? {
  if self.validate() is Some(_) {
    return None
  }
  let out : Array[Double] = []
  for v in self.positions {
    out.push(v.x.to_double())
    out.push(v.y.to_double())
  }
  Some(out)
}

///|
pub fn Mesh2dGeometry::flatten_interleaved_xy_uv(
  self : Mesh2dGeometry,
) -> Array[Double]? {
  if self.validate() is Some(_) {
    return None
  }
  let out : Array[Double] = []
  let n = self.positions.length()
  for i in 0..<n {
    let p = self.positions[i]
    let uv = self.uvs[i]
    out.push(p.x.to_double())
    out.push(p.y.to_double())
    out.push(uv.x.to_double())
    out.push(uv.y.to_double())
  }
  Some(out)
}

///|
/// Returns a non-indexed triangle-list position buffer (xy per vertex).
/// If the mesh is indexed, this expands indices on the CPU.
pub fn Mesh2dGeometry::flatten_triangle_positions_xy(
  self : Mesh2dGeometry,
) -> Array[Double]? {
  if self.validate() is Some(_) {
    return None
  }
  match self.indices {
    None => self.flatten_positions_xy()
    Some(indices) => {
      let out : Array[Double] = []
      for idx in indices {
        let p = self.positions[idx]
        out.push(p.x.to_double())
        out.push(p.y.to_double())
      }
      Some(out)
    }
  }
}
