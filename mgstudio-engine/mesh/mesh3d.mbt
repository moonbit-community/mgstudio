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
pub struct Mesh3dGeometry {
  positions : Array[@math.Vec3]
  uvs : Array[@math.Vec2]
  colors : Array[@math.Vec4]?
  indices : Array[Int]?
}

///|
pub(all) enum Mesh3dValidationError {
  EmptyGeometry
  AttributeLengthMismatch(Int, Int)
  ColorLengthMismatch(Int, Int)
  NonTriangleVertexCount(Int)
  NonTriangleIndexCount(Int)
  IndexOutOfBounds(Int, Int)
} derive(Eq, Show)

///|
pub fn Mesh3dGeometry::new(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{ positions, uvs, colors: None, indices }
}

///|
pub fn Mesh3dGeometry::new_with_colors(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  colors : Array[@math.Vec4],
  indices : Array[Int]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{ positions, uvs, colors: Some(colors), indices }
}

///|
pub fn Mesh3dGeometry::validate(
  self : Mesh3dGeometry,
) -> Mesh3dValidationError? {
  let vertex_count = self.positions.length()
  if vertex_count == 0 {
    return Some(Mesh3dValidationError::EmptyGeometry)
  }
  let uv_count = self.uvs.length()
  if uv_count != vertex_count {
    return Some(
      Mesh3dValidationError::AttributeLengthMismatch(vertex_count, uv_count),
    )
  }
  if self.colors is Some(colors) {
    let color_count = colors.length()
    if color_count != vertex_count {
      return Some(
        Mesh3dValidationError::ColorLengthMismatch(vertex_count, color_count),
      )
    }
  }
  match self.indices {
    Some(indices) => {
      let index_count = indices.length()
      if index_count == 0 || index_count % 3 != 0 {
        return Some(Mesh3dValidationError::NonTriangleIndexCount(index_count))
      }
      for i in 0..<index_count {
        let idx = indices[i]
        if idx < 0 || idx >= vertex_count {
          return Some(
            Mesh3dValidationError::IndexOutOfBounds(idx, vertex_count),
          )
        }
      }
      None
    }
    None =>
      if vertex_count % 3 != 0 {
        Some(Mesh3dValidationError::NonTriangleVertexCount(vertex_count))
      } else {
        None
      }
  }
}

///|
pub fn Mesh3dGeometry::vertex_count(self : Mesh3dGeometry) -> Int {
  self.positions.length()
}

///|
pub fn Mesh3dGeometry::triangle_count(self : Mesh3dGeometry) -> Int? {
  match self.validate() {
    Some(_) => None
    None =>
      match self.indices {
        Some(indices) => Some(indices.length() / 3)
        None => Some(self.positions.length() / 3)
      }
  }
}

///|
fn mesh3d_vertex_color_or_white(
  colors : Array[@math.Vec4]?,
  index : Int,
) -> @math.Vec4 {
  match colors {
    Some(cs) => cs[index]
    None => @math.Vec4::new(1.0F, 1.0F, 1.0F, 1.0F)
  }
}

///|
pub fn Mesh3dGeometry::flatten_triangle_interleaved_xyz_uv_rgba(
  self : Mesh3dGeometry,
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
        let c = mesh3d_vertex_color_or_white(self.colors, i)
        out.push(p.x.to_double())
        out.push(p.y.to_double())
        out.push(p.z.to_double())
        out.push(uv.x.to_double())
        out.push(uv.y.to_double())
        out.push(c.x.to_double())
        out.push(c.y.to_double())
        out.push(c.z.to_double())
        out.push(c.w.to_double())
      }
    }
    Some(indices) =>
      for i in 0..<indices.length() {
        let idx = indices[i]
        let p = self.positions[idx]
        let uv = self.uvs[idx]
        let c = mesh3d_vertex_color_or_white(self.colors, idx)
        out.push(p.x.to_double())
        out.push(p.y.to_double())
        out.push(p.z.to_double())
        out.push(uv.x.to_double())
        out.push(uv.y.to_double())
        out.push(c.x.to_double())
        out.push(c.y.to_double())
        out.push(c.z.to_double())
        out.push(c.w.to_double())
      }
  }
  Some(out)
}

///|
pub fn Mesh3dGeometry::encode_triangle_interleaved_xyz_uv_rgba_csv(
  self : Mesh3dGeometry,
) -> String? {
  match self.flatten_triangle_interleaved_xyz_uv_rgba() {
    None => None
    Some(values) => Some(values.map(fn(v) { v.to_string() }).join(","))
  }
}
