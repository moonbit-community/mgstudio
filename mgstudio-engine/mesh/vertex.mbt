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
// Bevy source: `bevy/crates/bevy_mesh/src/vertex.rs`.
// Runtime owner split across `mesh/mesh2d.mbt`, `mesh/mesh3d.mbt`, and
// `mesh/skinning.mbt`.

///|
fn mesh_vertex_color_at(
  colors : Array[@math.Vec4]?,
  index : Int,
) -> @math.Vec4? {
  match colors {
    Some(values) =>
      if index < 0 || index >= values.length() {
        None
      } else {
        Some(values[index])
      }
    None => None
  }
}

///|
pub fn Mesh2dGeometry::vertex_position(
  self : Mesh2dGeometry,
  index : Int,
) -> @math.Vec2? {
  if index < 0 || index >= self.positions.length() {
    None
  } else {
    Some(self.positions[index])
  }
}

///|
pub fn Mesh2dGeometry::vertex_uv(
  self : Mesh2dGeometry,
  index : Int,
) -> @math.Vec2? {
  if index < 0 || index >= self.uvs.length() {
    None
  } else {
    Some(self.uvs[index])
  }
}

///|
pub fn Mesh2dGeometry::vertex_color(
  self : Mesh2dGeometry,
  index : Int,
) -> @math.Vec4? {
  mesh_vertex_color_at(self.colors, index)
}

///|
pub fn Mesh3dGeometry::vertex_position(
  self : Mesh3dGeometry,
  index : Int,
) -> @math.Vec3? {
  if index < 0 || index >= self.positions.length() {
    None
  } else {
    Some(self.positions[index])
  }
}

///|
pub fn Mesh3dGeometry::vertex_uv(
  self : Mesh3dGeometry,
  index : Int,
) -> @math.Vec2? {
  self.uv(index)
}

///|
pub fn Mesh3dGeometry::vertex_color(
  self : Mesh3dGeometry,
  index : Int,
) -> @math.Vec4? {
  mesh_vertex_color_at(self.colors, index)
}
