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
  colors : Array[@math.Vec4]?
  indices : Array[Int]?
}

///|
pub(all) enum Mesh2dValidationError {
  EmptyVertices
  AttributeLengthMismatch(Int, Int)
  ColorAttributeLengthMismatch(Int, Int)
  NonIndexedVertexCountNotMultipleOf3(Int)
  IndicesEmpty
  IndicesCountNotMultipleOf3(Int)
  IndexOutOfBounds(Int, Int)
} derive(Eq, Show)

///|
pub fn Mesh2dGeometry::new(
  positions : Array[@math.Vec2],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
) -> Mesh2dGeometry {
  Mesh2dGeometry::{ positions, uvs, colors: None, indices }
}

///|
pub fn Mesh2dGeometry::new_with_colors(
  positions : Array[@math.Vec2],
  uvs : Array[@math.Vec2],
  colors : Array[@math.Vec4],
  indices : Array[Int]?,
) -> Mesh2dGeometry {
  Mesh2dGeometry::{ positions, uvs, colors: Some(colors), indices }
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
  if self.colors is Some(colors) {
    let color_count = colors.length()
    if color_count != vertex_count {
      return Some(
        Mesh2dValidationError::ColorAttributeLengthMismatch(
          vertex_count, color_count,
        ),
      )
    }
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
fn mesh2d_vertex_color_or_white(
  colors : Array[@math.Vec4]?,
  index : Int,
) -> @math.Vec4 {
  if colors is Some(values) {
    values[index]
  } else {
    @math.Vec4::splat(1.0F)
  }
}

///|
pub fn Mesh2dGeometry::flatten_triangle_interleaved_xy_uv_rgba(
  self : Mesh2dGeometry,
) -> Array[Double]? {
  if self.validate() is Some(_) {
    return None
  }
  let out : Array[Double] = []
  match self.indices {
    None => {
      let n = self.positions.length()
      for i in 0..<n {
        let p = self.positions[i]
        let uv = self.uvs[i]
        let color = mesh2d_vertex_color_or_white(self.colors, i)
        out.push(p.x.to_double())
        out.push(p.y.to_double())
        out.push(uv.x.to_double())
        out.push(uv.y.to_double())
        out.push(color.x.to_double())
        out.push(color.y.to_double())
        out.push(color.z.to_double())
        out.push(color.w.to_double())
      }
    }
    Some(indices) =>
      for idx in indices {
        let p = self.positions[idx]
        let uv = self.uvs[idx]
        let color = mesh2d_vertex_color_or_white(self.colors, idx)
        out.push(p.x.to_double())
        out.push(p.y.to_double())
        out.push(uv.x.to_double())
        out.push(uv.y.to_double())
        out.push(color.x.to_double())
        out.push(color.y.to_double())
        out.push(color.z.to_double())
        out.push(color.w.to_double())
      }
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

///|
pub fn Mesh2dGeometry::wireframe_segments(
  self : Mesh2dGeometry,
) -> Array[(@math.Vec2, @math.Vec2)]? {
  if self.validate() is Some(_) {
    return None
  }
  let out : Array[(@math.Vec2, @math.Vec2)] = []
  match self.indices {
    None => {
      let n = self.positions.length()
      for i in 0..<(n / 3) {
        let a = self.positions[i * 3]
        let b = self.positions[i * 3 + 1]
        let c = self.positions[i * 3 + 2]
        out.push((a, b))
        out.push((b, c))
        out.push((c, a))
      }
    }
    Some(indices) => {
      let n = indices.length()
      for i in 0..<(n / 3) {
        let a = self.positions[indices[i * 3]]
        let b = self.positions[indices[i * 3 + 1]]
        let c = self.positions[indices[i * 3 + 2]]
        out.push((a, b))
        out.push((b, c))
        out.push((c, a))
      }
    }
  }
  Some(out)
}

///|
/// Encodes non-indexed triangle list positions as a comma-separated string:
/// `x0,y0,x1,y1,...`.
pub fn Mesh2dGeometry::encode_triangle_positions_csv(
  self : Mesh2dGeometry,
) -> String? {
  match self.flatten_triangle_positions_xy() {
    None => None
    Some(values) => {
      let mut out = ""
      let n = values.length()
      for i in 0..<n {
        if i > 0 {
          out = "\{out},"
        }
        out = out + values[i].to_string()
      }
      Some(out)
    }
  }
}

///|
pub fn Mesh2dGeometry::encode_triangle_interleaved_xy_uv_rgba_csv(
  self : Mesh2dGeometry,
) -> String? {
  match self.flatten_triangle_interleaved_xy_uv_rgba() {
    None => None
    Some(values) => {
      let mut out = ""
      let n = values.length()
      for i in 0..<n {
        if i > 0 {
          out = "\{out},"
        }
        out = out + values[i].to_string()
      }
      Some(out)
    }
  }
}
