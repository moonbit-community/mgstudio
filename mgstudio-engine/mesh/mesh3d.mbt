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
  topology : Mesh3dPrimitiveTopology
}

///|
pub(all) enum Mesh3dPrimitiveTopology {
  TriangleList
  LineList
  LineStrip
} derive(Eq, Show)

///|
pub fn Mesh3dPrimitiveTopology::to_int(self : Mesh3dPrimitiveTopology) -> Int {
  match self {
    TriangleList => 0
    LineList => 1
    LineStrip => 2
  }
}

///|
pub(all) enum Mesh3dValidationError {
  EmptyGeometry
  AttributeLengthMismatch(Int, Int)
  ColorLengthMismatch(Int, Int)
  NonTriangleVertexCount(Int)
  NonTriangleIndexCount(Int)
  NonLineListVertexCount(Int)
  NonLineListIndexCount(Int)
  NonLineStripVertexCount(Int)
  NonLineStripIndexCount(Int)
  IndexOutOfBounds(Int, Int)
} derive(Eq, Show)

///|
pub fn Mesh3dGeometry::new(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions,
    uvs,
    colors: None,
    indices,
    topology: Mesh3dPrimitiveTopology::TriangleList,
  }
}

///|
pub fn Mesh3dGeometry::new_with_colors(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  colors : Array[@math.Vec4],
  indices : Array[Int]?,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions,
    uvs,
    colors: Some(colors),
    indices,
    topology: Mesh3dPrimitiveTopology::TriangleList,
  }
}

///|
pub fn Mesh3dGeometry::new_with_topology(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  indices : Array[Int]?,
  topology : Mesh3dPrimitiveTopology,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{ positions, uvs, colors: None, indices, topology }
}

///|
pub fn Mesh3dGeometry::new_with_colors_and_topology(
  positions : Array[@math.Vec3],
  uvs : Array[@math.Vec2],
  colors : Array[@math.Vec4],
  indices : Array[Int]?,
  topology : Mesh3dPrimitiveTopology,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{ positions, uvs, colors: Some(colors), indices, topology }
}

///|
pub fn Mesh3dGeometry::with_topology(
  self : Mesh3dGeometry,
  topology : Mesh3dPrimitiveTopology,
) -> Mesh3dGeometry {
  Mesh3dGeometry::{
    positions: self.positions,
    uvs: self.uvs,
    colors: self.colors,
    indices: self.indices,
    topology,
  }
}

///|
pub fn Mesh3dGeometry::primitive_topology(
  self : Mesh3dGeometry,
) -> Mesh3dPrimitiveTopology {
  self.topology
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
  let primitive_count = match self.indices {
    Some(indices) => {
      let index_count = indices.length()
      for i in 0..<index_count {
        let idx = indices[i]
        if idx < 0 || idx >= vertex_count {
          return Some(
            Mesh3dValidationError::IndexOutOfBounds(idx, vertex_count),
          )
        }
      }
      index_count
    }
    None => vertex_count
  }

  match self.topology {
    Mesh3dPrimitiveTopology::TriangleList =>
      if self.indices is Some(_) {
        if primitive_count == 0 || primitive_count % 3 != 0 {
          Some(Mesh3dValidationError::NonTriangleIndexCount(primitive_count))
        } else {
          None
        }
      } else if primitive_count % 3 != 0 {
        Some(Mesh3dValidationError::NonTriangleVertexCount(primitive_count))
      } else {
        None
      }
    Mesh3dPrimitiveTopology::LineList =>
      if self.indices is Some(_) {
        if primitive_count == 0 || primitive_count % 2 != 0 {
          Some(Mesh3dValidationError::NonLineListIndexCount(primitive_count))
        } else {
          None
        }
      } else if primitive_count % 2 != 0 {
        Some(Mesh3dValidationError::NonLineListVertexCount(primitive_count))
      } else {
        None
      }
    Mesh3dPrimitiveTopology::LineStrip =>
      if self.indices is Some(_) {
        if primitive_count < 2 {
          Some(Mesh3dValidationError::NonLineStripIndexCount(primitive_count))
        } else {
          None
        }
      } else if primitive_count < 2 {
        Some(Mesh3dValidationError::NonLineStripVertexCount(primitive_count))
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
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
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
fn mesh3d_wireframe_push_vertex(
  src_positions : Array[@math.Vec3],
  src_uvs : Array[@math.Vec2],
  src_colors : Array[@math.Vec4]?,
  dst_positions : Array[@math.Vec3],
  dst_uvs : Array[@math.Vec2],
  dst_colors : Array[@math.Vec4]?,
  src_index : Int,
) -> Unit {
  dst_positions.push(src_positions[src_index])
  dst_uvs.push(src_uvs[src_index])
  if src_colors is Some(colors) {
    guard dst_colors is Some(out_colors) else { return }
    out_colors.push(colors[src_index])
  }
}

///|
fn mesh3d_wireframe_append_edge(
  src_positions : Array[@math.Vec3],
  src_uvs : Array[@math.Vec2],
  src_colors : Array[@math.Vec4]?,
  dst_positions : Array[@math.Vec3],
  dst_uvs : Array[@math.Vec2],
  dst_colors : Array[@math.Vec4]?,
  a : Int,
  b : Int,
) -> Unit {
  mesh3d_wireframe_push_vertex(
    src_positions, src_uvs, src_colors, dst_positions, dst_uvs, dst_colors, a,
  )
  mesh3d_wireframe_push_vertex(
    src_positions, src_uvs, src_colors, dst_positions, dst_uvs, dst_colors, b,
  )
}

///|
pub fn Mesh3dGeometry::to_wireframe_line_list(
  self : Mesh3dGeometry,
) -> Mesh3dGeometry? {
  if self.validate() is Some(_) {
    return None
  }
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
  let out_positions : Array[@math.Vec3] = []
  let out_uvs : Array[@math.Vec2] = []
  let out_colors : Array[@math.Vec4]? = if self.colors is Some(_) {
    Some([])
  } else {
    None
  }
  match self.indices {
    Some(indices) => {
      let tri_count = indices.length() / 3
      for tri_index in 0..<tri_count {
        let i0 = indices[tri_index * 3]
        let i1 = indices[tri_index * 3 + 1]
        let i2 = indices[tri_index * 3 + 2]
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i0,
          i1,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i1,
          i2,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i2,
          i0,
        )
      }
    }
    None => {
      let tri_count = self.positions.length() / 3
      for tri_index in 0..<tri_count {
        let i0 = tri_index * 3
        let i1 = tri_index * 3 + 1
        let i2 = tri_index * 3 + 2
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i0,
          i1,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i1,
          i2,
        )
        mesh3d_wireframe_append_edge(
          self.positions,
          self.uvs,
          self.colors,
          out_positions,
          out_uvs,
          out_colors,
          i2,
          i0,
        )
      }
    }
  }
  match out_colors {
    Some(colors) =>
      Some(
        Mesh3dGeometry::new_with_colors_and_topology(
          out_positions,
          out_uvs,
          colors,
          None,
          Mesh3dPrimitiveTopology::LineList,
        ),
      )
    None =>
      Some(
        Mesh3dGeometry::new_with_topology(
          out_positions,
          out_uvs,
          None,
          Mesh3dPrimitiveTopology::LineList,
        ),
      )
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
pub fn Mesh3dGeometry::flatten_interleaved_xyz_uv_rgba(
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
pub fn Mesh3dGeometry::encode_interleaved_xyz_uv_rgba_csv(
  self : Mesh3dGeometry,
) -> String? {
  match self.flatten_interleaved_xyz_uv_rgba() {
    None => None
    Some(values) => Some(values.map(fn(v) { v.to_string() }).join(","))
  }
}

///|
pub fn Mesh3dGeometry::flatten_triangle_interleaved_xyz_uv_rgba(
  self : Mesh3dGeometry,
) -> Array[Double]? {
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
  self.flatten_interleaved_xyz_uv_rgba()
}

///|
pub fn Mesh3dGeometry::encode_triangle_interleaved_xyz_uv_rgba_csv(
  self : Mesh3dGeometry,
) -> String? {
  if self.topology != Mesh3dPrimitiveTopology::TriangleList {
    return None
  }
  self.encode_interleaved_xyz_uv_rgba_csv()
}
