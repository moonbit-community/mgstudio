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
fn mesh3d_test_rectangle() -> Mesh3dGeometry {
  Mesh3dGeometry::new(
    [
      @math.Vec3::new(-1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, 2.0F, 0.0F),
      @math.Vec3::new(-1.0F, -2.0F, 0.0F),
      @math.Vec3::new(1.0F, 2.0F, 0.0F),
      @math.Vec3::new(-1.0F, 2.0F, 0.0F),
    ],
    [
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 1.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 1.0F),
      @math.Vec2::new(1.0F, 0.0F),
      @math.Vec2::new(0.0F, 0.0F),
    ],
    None,
  )
}

///|
fn mesh3d_test_line_strip() -> Mesh3dGeometry {
  Mesh3dGeometry::new_with_topology(
    [
      @math.Vec3::new(2.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 2.0F, 0.0F),
      @math.Vec3::new(-2.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, -2.0F, 0.0F),
      @math.Vec3::new(2.0F, 0.0F, 0.0F),
    ],
    [
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
      @math.Vec2::zero(),
    ],
    None,
    Mesh3dPrimitiveTopology::LineStrip,
  )
}

///|
test "mesh: Mesh3dGeometry::flatten_interleaved_xyz_normal_uv_rgba emits flat triangle normals" {
  let geometry = mesh3d_test_rectangle()
  match geometry.flatten_interleaved_xyz_normal_uv_rgba() {
    Some(values) => {
      debug_inspect(values.length(), content="72")
      debug_inspect(
        (values[3], values[4], values[5], values[15], values[16], values[17]),
        content="(0, 0, 1, 0, 0, 1)",
      )
    }
    None => abort("expected normal-aware flatten data")
  }
}

///|
test "mesh: Mesh3dGeometry::flatten_interleaved_xyz_normal_uv_rgba gives default line normal" {
  let geometry = mesh3d_test_line_strip()
  match geometry.flatten_interleaved_xyz_normal_uv_rgba() {
    Some(values) => {
      debug_inspect(values.length() % 12, content="0")
      debug_inspect((values[3], values[4], values[5]), content="(0, 0, 1)")
    }
    None => abort("expected line-strip normal-aware flatten data")
  }
}

///|
test "mesh: Mesh3dGeometry standard attributes use vertex attribute ids" {
  let geometry = Mesh3dGeometry::new_with_positions(
    [@math.Vec3::new(1.0F, 2.0F, 3.0F)],
    None,
  )
  geometry.insert_indices(Some([0]))
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::normal(),
      VertexAttributeValues::Float32x3([@math.Vec3::new(0.0F, 1.0F, 0.0F)]),
    ),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::uv_0(),
      VertexAttributeValues::Float32x2([@math.Vec2::new(0.25F, 0.75F)]),
    ),
  )
  debug_inspect(
    geometry.contains_attribute(MeshVertexAttribute::position().id()),
    content="true",
  )
  debug_inspect(
    geometry.contains_attribute(MeshVertexAttribute::normal().id()),
    content="true",
  )
  debug_inspect(
    geometry.contains_attribute(MeshVertexAttribute::uv_0().id()),
    content="true",
  )
  guard geometry.attribute(MeshVertexAttribute::normal().id())
    is Some(VertexAttributeValues::Float32x3(normals)) else {
    abort("missing normal attribute")
  }
  debug_inspect(normals[0].y.to_double(), content="1")
  debug_inspect(geometry.has_indices(), content="true")
}

///|
fn mesh3d_test_read_u32_le(bytes : Bytes, offset : Int) -> UInt {
  let b0 = bytes.get(offset).unwrap().to_int() & 0xFF
  let b1 = bytes.get(offset + 1).unwrap().to_int() & 0xFF
  let b2 = bytes.get(offset + 2).unwrap().to_int() & 0xFF
  let b3 = bytes.get(offset + 3).unwrap().to_int() & 0xFF
  (b0 & 0xFF).reinterpret_as_uint() |
  ((b1 & 0xFF).reinterpret_as_uint() << 8) |
  ((b2 & 0xFF).reinterpret_as_uint() << 16) |
  ((b3 & 0xFF).reinterpret_as_uint() << 24)
}

///|
fn mesh3d_test_read_f32_le(bytes : Bytes, offset : Int) -> Float {
  Float::reinterpret_from_uint(mesh3d_test_read_u32_le(bytes, offset))
}

///|
test "mesh: attributes and packed vertex buffer follow Bevy attribute id order" {
  let geometry = Mesh3dGeometry::new_with_positions(
    [@math.Vec3::new(1.0F, 2.0F, 3.0F), @math.Vec3::new(4.0F, 5.0F, 6.0F)],
    Some([0, 1]),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::uv_0(),
      VertexAttributeValues::Float32x2([
        @math.Vec2::new(0.25F, 0.5F),
        @math.Vec2::new(0.75F, 1.0F),
      ]),
    ),
  )
  ignore(
    geometry.insert_attribute(
      MeshVertexAttribute::normal(),
      VertexAttributeValues::Float32x3([
        @math.Vec3::new(0.0F, 0.0F, 1.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ]),
    ),
  )
  let mesh = Mesh::from_3d_geometry(geometry)
  let attributes = mesh.attributes()
  debug_inspect(attributes.length(), content="3")
  debug_inspect(attributes[0].attribute().name(), content="\"Vertex_Position\"")
  debug_inspect(attributes[1].attribute().name(), content="\"Vertex_Normal\"")
  debug_inspect(attributes[2].attribute().name(), content="\"Vertex_Uv\"")
  debug_inspect(mesh.count_vertices(), content="2")
  debug_inspect(mesh.get_vertex_size(), content="32")
  debug_inspect(mesh.get_vertex_buffer_size(), content="64")
  let packed = mesh.create_packed_vertex_buffer_data()
  debug_inspect(packed.length(), content="64")
  debug_inspect(mesh3d_test_read_f32_le(packed, 0).to_double(), content="1")
  debug_inspect(mesh3d_test_read_f32_le(packed, 12).to_double(), content="0")
  debug_inspect(mesh3d_test_read_f32_le(packed, 20).to_double(), content="1")
  debug_inspect(mesh3d_test_read_f32_le(packed, 24).to_double(), content="0.25")
  debug_inspect(mesh3d_test_read_f32_le(packed, 32).to_double(), content="4")
  debug_inspect(mesh3d_test_read_f32_le(packed, 60).to_double(), content="1")
}
